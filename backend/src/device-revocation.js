import { HttpError } from './http-error.js';
import { toGuardianDeviceView } from './device-lifecycle.js';

/**
 * Cutting a child's device off, as one operation with two data adapters.
 *
 * The rules of revocation live here and only here: who may do it, which device may
 * be cut off, what a second attempt means, and what gets recorded. The adapters
 * supply data access and nothing else, so the rule the server enforces in
 * production is the rule the test suite exercises rather than a second copy of it.
 *
 * Why this shape: the Foundation store is shared with a parallel session that is
 * working on exactly this device write path. Rather than add a method to a file two
 * authors would then edit, this module reaches the database through the store's own
 * published transaction helpers - the same ones every mutation in it already uses.
 *
 * Revocation is the one operation in M1 that can leave a child unprotected if it
 * half-happens, so it is written to commit or vanish as a unit: the revocation, the
 * membership it is attributed to, its audit record, its outbox event, its recorded
 * fact and its idempotency slot all live inside one transaction.
 */

/** The closed vocabulary migration 101 enforces. Held here too so a bad value fails
 * as an intentional 400 rather than as a driver constraint error. */
export const DEVICE_REVOCATION_REASON_CODES = Object.freeze([
  'lost',
  'stolen',
  'replaced',
  'no_longer_used',
  'other',
]);

const revocationScope = (familyId, childId, deviceId) =>
  `family-child-device:revoke:${familyId}:${childId}:${deviceId}`;

/**
 * Builds the revocation operation over a data port.
 *
 * Port shape, all of it data access and none of it rules:
 *
 *   idempotent(scope, key, requestHash, work)
 *       Runs `work(tx)` once for a given key and replays the stored result on a
 *       retry, so a guardian whose connection drops cannot revoke twice.
 *   authorize(tx, { familyId, subject })                   -> { id } membership
 *   readDevice(tx, { familyId, childId, deviceId })        -> raw row | null
 *   markRevoked(tx, { deviceId, actorMembershipId, reasonCode }) -> raw row | null
 *       null means the device was already revoked when the update ran.
 *   audit(tx, { familyId, actorMembershipId, correlationId, subjectId })
 *   fact(tx, { familyId, childId, deviceId, correlationId })
 *
 * `tx` is whatever the adapter passes to `work`; the operation never inspects it.
 */
export function createDeviceRevocation({ port }) {
  return async function revokeFamilyChildDevice({
    principal,
    familyId,
    childId,
    deviceId,
    reasonCode = null,
    idempotencyKey,
    requestHash,
    correlationId,
  }) {
    const reason = normalizeReasonCode(reasonCode);

    return port.idempotent(
      revocationScope(familyId, childId, deviceId),
      idempotencyKey,
      requestHash,
      async (tx) => {
        // Only a primary guardian can cut a device off. Both guardians can see the
        // device; the destructive act is deliberately narrower than the read.
        const actor = await port.authorize(tx, { familyId, subject: principal.subject });

        const device = await port.readDevice(tx, { familyId, childId, deviceId });
        if (device === null) {
          throw new HttpError(404, 'device_not_found', 'Device was not found in this family.');
        }

        const refusal = refusalFor(device);
        if (refusal !== null) {
          throw new HttpError(refusal.status, refusal.code, refusal.message);
        }

        const revoked = await port.markRevoked(tx, {
          deviceId,
          actorMembershipId: actor.id,
          reasonCode: reason,
        });
        if (revoked === null) {
          // The guard lives in the update itself, so this means the device was
          // already revoked by the time our update ran. The first record is the
          // true one: overwriting who cut the device off, and when, would destroy
          // the very provenance migration 101 exists to keep.
          throw new HttpError(
            409,
            'device_already_revoked',
            'Device was already revoked. The original revocation stands.',
          );
        }

        // Slice 3: cutting a device off really deletes what it reported. The trail it
        // stored, the crossings derived from that trail, and (in the revocation
        // statement itself) the device's own location snapshot. What an incident points
        // at keeps the incident and loses the reference: the emergency the family lived
        // through is a safety record, the sample it named is location data.
        const erased = await port.eraseDeviceLocation(tx, { familyId, deviceId });
        erased.deviceSnapshots =
          device.location_lat !== null || device.location_lng !== null || device.location_label !== null
            ? 1
            : 0;

        await port.audit(tx, {
          familyId,
          actorMembershipId: actor.id,
          correlationId,
          subjectId: deviceId,
        });
        await port.auditErasure(tx, {
          familyId,
          actorMembershipId: actor.id,
          correlationId,
          subjectId: deviceId,
        });
        await port.fact(tx, { familyId, childId, deviceId, correlationId });

        // The response carries the device's new condition — with its location snapshot
        // already empty, because the revocation statement itself emptied it — so a
        // guardian's screen needs no second request to show that the device is now cut
        // off, and cannot keep drawing a last-known position that no longer exists.
        return { device: toGuardianDeviceView(revoked, { now: Date.now() }), erased };
      },
    );
  };
}

function normalizeReasonCode(value) {
  if (value === null || value === undefined) {
    // Optional on purpose: cutting off a stolen handset is urgent, and a guardian
    // forced to classify the loss first is a guardian who hesitates.
    return null;
  }
  if (typeof value !== 'string' || !DEVICE_REVOCATION_REASON_CODES.includes(value)) {
    throw new HttpError(
      400,
      'invalid_revocation_reason',
      `reasonCode must be one of: ${DEVICE_REVOCATION_REASON_CODES.join(', ')}.`,
    );
  }
  return value;
}

function refusalFor(device) {
  if (device.credential_revoked_at) {
    return {
      status: 409,
      code: 'device_already_revoked',
      message: 'Device was already revoked. The original revocation stands.',
    };
  }
  if (!device.credential_hash) {
    return {
      status: 409,
      code: 'device_not_claimed',
      message: 'Device has not been paired yet, so there is no credential to revoke.',
    };
  }
  return null;
}

/**
 * The production port: real SQL through the Foundation store's own transaction,
 * membership, idempotency, audit and AiEvent helpers.
 *
 * Nothing here decides anything. The membership rule, the device rule and the
 * meaning of a second attempt are all in the operation above, which is also what
 * the tests exercise.
 */
export function postgresDeviceRevocationPort(store) {
  return {
    async idempotent(scope, key, requestHash, work) {
      return store.withTransaction(async (client) => {
        const replay = await store.acquireIdempotencySlot(client, scope, key, requestHash);
        if (replay) return replay;
        const result = await work(client);
        await store.completeIdempotencySlot(client, scope, key, result);
        return result;
      });
    },

    async authorize(client, { familyId, subject }) {
      return store.activeActorMembership(client, familyId, subject, { primaryGuardianOnly: true });
    },

    async readDevice(client, { familyId, childId, deviceId }) {
      const { rows } = await client.query(
        `SELECT id, family_id, child_id, device_label, credential_hash, credential_revoked_at,
                last_seen_at, location_lat, location_lng, location_label, linked_at, version
           FROM family_child_devices
          WHERE family_id = $1 AND child_id = $2 AND id = $3`,
        [familyId, childId, deviceId],
      );
      return rows[0] ?? null;
    },

    async markRevoked(client, { deviceId, actorMembershipId, reasonCode }) {
      // The guard is in the WHERE clause rather than in a check before it, so two
      // simultaneous revocations cannot both succeed and cannot record two
      // different actors or times. NOW() is the database's clock: this server
      // never invents a revocation time.
      //
      // The same statement empties the device's location snapshot (slice 3): a cut-off
      // handset must not leave "where the child last was" sitting in the device row the
      // guardian screen reads next. last_seen_at stays — a time is not a position.
      const { rows } = await client.query(
        `UPDATE family_child_devices
            SET credential_revoked_at = NOW(),
                revoked_by_membership_id = $2,
                revocation_reason = $3,
                location_lat = NULL,
                location_lng = NULL,
                location_label = NULL,
                version = version + 1
          WHERE id = $1
            AND credential_hash IS NOT NULL
            AND credential_revoked_at IS NULL
        RETURNING id, family_id, child_id, device_label, credential_hash, credential_revoked_at,
                  last_seen_at, location_lat, location_lng, location_label, linked_at, version`,
        [deviceId, actorMembershipId, reasonCode],
      );
      return rows[0] ?? null;
    },

    async eraseDeviceLocation(client, { familyId, deviceId }) {
      // The order is the schema's, not a choice: crossings reference fixes through a
      // composite RESTRICT key and incidents reference them by primary key, so the
      // derived records and the references go first or the trail deletion fails.
      const crossings = await client.query(
        `DELETE FROM family_geofence_events
          WHERE family_id = $1 AND device_id = $2`,
        [familyId, deviceId],
      );
      const sosReferences = await client.query(
        `UPDATE family_sos_alerts
            SET fix_id = NULL
          WHERE family_id = $1
            AND fix_id IS NOT NULL
            AND fix_id IN (
              SELECT id FROM family_child_location_fixes
               WHERE family_id = $1 AND device_id = $2
            )`,
        [familyId, deviceId],
      );
      const fixes = await client.query(
        `DELETE FROM family_child_location_fixes
          WHERE family_id = $1 AND device_id = $2`,
        [familyId, deviceId],
      );
      return {
        locationFixes: fixes.rowCount ?? 0,
        geofenceEvents: crossings.rowCount ?? 0,
        sosFixReferences: sosReferences.rowCount ?? 0,
      };
    },

    async audit(client, { familyId, actorMembershipId, correlationId, subjectId }) {
      await store.appendAuditAndOutbox(client, {
        familyId,
        actorMembershipId,
        correlationId,
        eventType: 'family.child_device_revoked',
        subjectType: 'family_child_device',
        subjectId,
      });
    },

    /**
     * The erasure's own audit row, and deliberately not an outbox row: the revocation
     * is the family event (announced above), the deletion is a fact about data. It says
     * "deleted" and nothing else — no coordinates, no counts — because an audit trail
     * carrying the erased picture would rebuild what the family just removed.
     */
    async auditErasure(client, { familyId, actorMembershipId, correlationId, subjectId }) {
      await client.query(
        `INSERT INTO family_audit_events
           (id, family_id, actor_membership_id, correlation_id, event_type, subject_type, subject_id)
         VALUES (gen_random_uuid(), $1, $2, $3, 'family.child_device_location_erased', 'family_child_device', $4)`,
        [familyId, actorMembershipId, correlationId, subjectId],
      );
    },

    async fact(client, { familyId, childId, deviceId, correlationId }) {
      await store.appendAiEvent(client, {
        familyId,
        childId,
        deviceId,
        eventType: 'device.revoked',
        correlationId,
      });
    },
  };
}

/** Builds the operation for a server that was handed a Foundation store. */
export function deviceRevocationFor(store) {
  return createDeviceRevocation({ port: postgresDeviceRevocationPort(store) });
}
