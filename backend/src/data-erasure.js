// Safety slice 3 — the data-erasure surface: deletion that actually deletes.
//
// Retention (location-telemetry.js) bounds the trail by time. This module bounds it by
// right: a primary guardian may demand that what was collected about a child is gone,
// and removing a child from the family must not leave their position history behind as
// an orphan nobody can see but everybody still stores.
//
// Two operations, one rule each:
//
//   eraseChildLocationData  the guardian's request. The child stays in the family; the
//                           trail, the crossings derived from it, and the device
//                           snapshots of "where the child last was" are really deleted.
//                           Consent is NOT touched — stopping collection is withdrawal
//                           (slice 2), erasing what was collected is this. Conflating
//                           the two would let one button silently do the other.
//   removeFamilyChild       the child leaves the family. The profile is archived with
//                           provenance (migration 116), every location fact is erased as
//                           above, the consent ledger is frozen by withdrawal, and every
//                           paired handset is cut off — all in one transaction, because a
//                           removal that half-happens leaves a child the family believes
//                           is gone while a handset keeps reporting.
//
// What erasure deletes, and what it deliberately does not:
//
//   deleted   family_child_location_fixes rows for the child (or device), the geofence
//             crossings derived from them (they ARE location data — an arrival alert is
//             a statement about where the child was), and the devices.location_*
//             snapshot columns.
//   kept      family_sos_alerts rows — an emergency the family lived through is a safety
//             record, not a trail sample — but their `fix_id` reference is set to NULL:
//             the incident stays, the measurement it pointed at is honestly gone rather
//             than secretly retained. The retention prune protects a referenced sample
//             because an event must be checkable; erasure is the family's explicit
//             demand that it NOT be kept, and the ledger records that demand instead.
//   kept      the consent ledger (withdrawn, frozen, never erased): who agreed to what
//             and when is compliance evidence about the family's own acts, not location
//             data about the child.
//
// Every deletion is audited as a fact — event type and subject only. The audit row says
// "deleted", never "deleted what": coordinates and counts in an audit trail would rebuild
// the very picture the family asked to erase (the same reason coordinates never reach
// server logs).
import { HttpError } from './http-error.js';

/// The same shape the store requires of an internal trace context.
const CORRELATION_ID_PATTERN =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

const eraseScope = (familyId, childId) =>
  `child-data-erasure:erase:${familyId}:${childId}`;

const removeScope = (familyId, childId) =>
  `family-child:remove:${familyId}:${childId}`;

/**
 * Builds the erasure operations over a data port.
 *
 * Port shape, all of it data access and none of it rules:
 *
 *   idempotent(scope, key, requestHash, work)
 *   withTransaction(run)
 *   authorize(tx, { familyId, subject })                 -> { id } membership
 *       Primary guardian only; the adapter's SQL decides, as in every destructive
 *       operation this codebase ships.
 *   readChildIncludingArchived(tx, { familyId, childId }) -> raw row | null
 *       Erasure must still reach a child the roster no longer shows: a removal is
 *       replay-safe, and an erase over an already-archived child answers honestly
 *       with zeros instead of pretending the child never existed.
 *   eraseChildLocationData(tx, { familyId, childId })    -> counts
 *   withdrawActiveConsents(tx, { childId, actorMembershipId }) -> count
 *   revokeChildDevices(tx, { familyId, childId, actorMembershipId }) -> count
 *   archiveChild(tx, { familyId, childId, actorMembershipId }) -> raw row | null
 *       null means the profile was already archived when the guarded UPDATE ran.
 *   audit(tx, { familyId, actorMembershipId, correlationId, subjectId, subjectType, eventType })
 *   announce(tx, { familyId, actorMembershipId, correlationId, subjectId, subjectType, eventType })
 *       Audit PLUS outbox — reserved for the removal, which changes the family itself.
 */
export function createDataErasureSurface({ port }) {
  /**
   * The guardian's erasure request. Repeat-safe by nature: a second demand over data
   * that is already gone answers 200 with zero counts rather than an error, because
   * "it is gone" is the truest possible answer to "delete it".
   */
  async function eraseChildLocationData({
    principal,
    familyId,
    childId,
    idempotencyKey,
    requestHash,
    correlationId,
  }) {
    return port.idempotent(
      eraseScope(familyId, childId),
      idempotencyKey,
      requestHash,
      async (tx) => {
        const actor = await port.authorize(tx, { familyId, subject: principal.subject });
        const child = await port.readChildIncludingArchived(tx, { familyId, childId });
        if (child === null) {
          throw new HttpError(404, 'family_child_not_found', 'Child was not found in this family.');
        }

        const erased = await port.eraseChildLocationData(tx, { familyId, childId });
        // The audit row says "deleted" and nothing else. No coordinates, no counts:
        // an audit trail that carried the erased picture would be a second copy of
        // exactly what the family demanded be gone.
        await port.audit(tx, {
          familyId,
          actorMembershipId: actor.id,
          correlationId,
          subjectId: childId,
          subjectType: 'family_child',
          eventType: 'family.child_location_erased',
        });

        return { childId, erased };
      },
    );
  }

  /**
   * Removing a child from the family: archive with provenance, erase every location
   * fact, freeze the consent ledger by withdrawal, and cut off every paired handset —
   * one transaction, or none of it.
   */
  async function removeFamilyChild({
    principal,
    familyId,
    childId,
    idempotencyKey,
    requestHash,
    correlationId,
  }) {
    return port.idempotent(
      removeScope(familyId, childId),
      idempotencyKey,
      requestHash,
      async (tx) => {
        const actor = await port.authorize(tx, { familyId, subject: principal.subject });
        const child = await port.readChildIncludingArchived(tx, { familyId, childId });
        if (child === null) {
          throw new HttpError(404, 'family_child_not_found', 'Child was not found in this family.');
        }
        if (child.archived_at !== null) {
          // The first removal is the true one. Re-running it under a new key must not
          // rewrite who removed the child, or when — the same law revocation enforces.
          throw new HttpError(
            409,
            'child_already_archived',
            'Child was already removed from this family. The original removal stands.',
          );
        }

        const erased = await port.eraseChildLocationData(tx, { familyId, childId });
        const consentsWithdrawn = await port.withdrawActiveConsents(tx, {
          childId,
          actorMembershipId: actor.id,
        });
        const devicesRevoked = await port.revokeChildDevices(tx, {
          familyId,
          childId,
          actorMembershipId: actor.id,
        });

        const archived = await port.archiveChild(tx, {
          familyId,
          childId,
          actorMembershipId: actor.id,
        });
        if (archived === null) {
          // Two guardians removed the same child at the same instant. The guard lives
          // in the UPDATE's WHERE clause, so exactly one of them holds the provenance.
          throw new HttpError(
            409,
            'child_already_archived',
            'Child was already removed from this family. The original removal stands.',
          );
        }

        // The erasure is a fact about data; the removal is a change to the family, and
        // the family is told about those (the same split the location surface draws
        // between its audit row and its outbox row).
        await port.audit(tx, {
          familyId,
          actorMembershipId: actor.id,
          correlationId,
          subjectId: childId,
          subjectType: 'family_child',
          eventType: 'family.child_location_erased',
        });
        await port.announce(tx, {
          familyId,
          actorMembershipId: actor.id,
          correlationId,
          subjectId: childId,
          subjectType: 'family_child',
          eventType: 'family.child_archived',
        });

        return {
          child: {
            id: archived.id,
            displayName: archived.display_name,
            archivedAt: archived.archived_at,
          },
          erased,
          consentsWithdrawn,
          devicesRevoked,
        };
      },
    );
  }

  return { eraseChildLocationData, removeFamilyChild };
}

/**
 * The production port: real SQL through the Foundation store's own published helpers.
 *
 * The order inside `eraseChildLocationData` is forced by the schema, not chosen:
 * crossings reference fixes through a composite RESTRICT key (migration 103) and
 * incidents reference them by primary key (migration 104), so the derived records and
 * the references must go first or the deletion of the trail itself fails.
 */
export function postgresDataErasurePort(store) {
  return {
    async withTransaction(run) {
      return store.withTransaction(run);
    },

    async idempotent(scope, key, requestHash, work) {
      return store.withTransaction(async (client) => {
        const replay = await store.acquireIdempotencySlot(client, scope, key, requestHash);
        if (replay) return replay;
        const result = await work(client);
        await store.completeIdempotencySlot(client, scope, key, result);
        return result;
      });
    },

    // Destructive and narrower than the read: only a primary guardian may erase or
    // remove. Both guardians can see the trail; one of them may delete it.
    async authorize(client, { familyId, subject }) {
      return store.activeActorMembership(client, familyId, subject, { primaryGuardianOnly: true });
    },

    async readChildIncludingArchived(client, { familyId, childId }) {
      const { rows } = await client.query(
        `SELECT id, display_name, archived_at
           FROM family_children
          WHERE family_id = $1 AND id = $2`,
        [familyId, childId],
      );
      return rows[0] ?? null;
    },

    async eraseChildLocationData(client, { familyId, childId }) {
      const crossings = await client.query(
        `DELETE FROM family_geofence_events
          WHERE family_id = $1 AND child_id = $2`,
        [familyId, childId],
      );
      const sosReferences = await client.query(
        `UPDATE family_sos_alerts
            SET fix_id = NULL
          WHERE family_id = $1 AND child_id = $2 AND fix_id IS NOT NULL`,
        [familyId, childId],
      );
      const fixes = await client.query(
        `DELETE FROM family_child_location_fixes
          WHERE family_id = $1 AND child_id = $2`,
        [familyId, childId],
      );
      // The snapshot is location data too: "where the child last was" must not survive
      // the demand that where-the-child-was is gone. last_seen_at stays — a time is not
      // a position, and the family keeps the honest fact that a device once reported.
      const snapshots = await client.query(
        `UPDATE family_child_devices
            SET location_lat = NULL, location_lng = NULL, location_label = NULL
          WHERE family_id = $1 AND child_id = $2
            AND (location_lat IS NOT NULL OR location_lng IS NOT NULL OR location_label IS NOT NULL)`,
        [familyId, childId],
      );
      return {
        locationFixes: fixes.rowCount ?? 0,
        geofenceEvents: crossings.rowCount ?? 0,
        deviceSnapshots: snapshots.rowCount ?? 0,
        sosFixReferences: sosReferences.rowCount ?? 0,
      };
    },

    async withdrawActiveConsents(client, { childId, actorMembershipId }) {
      // Withdrawal freezes the row; it never erases it (migration 114's own rule).
      // The database clock timestamps the act, as in every other provenance column.
      const { rowCount } = await client.query(
        `UPDATE family_child_consents
            SET withdrawn_at = NOW(), withdrawn_by_membership_id = $2
          WHERE child_id = $1 AND withdrawn_at IS NULL`,
        [childId, actorMembershipId],
      );
      return rowCount ?? 0;
    },

    async revokeChildDevices(client, { familyId, childId, actorMembershipId }) {
      // The same guard shape as revocation: the WHERE clause decides, so two removals
      // racing cannot both claim a device. Unclaimed devices have no credential to cut
      // off and are left exactly as they are; their location data was already erased.
      const { rowCount } = await client.query(
        `UPDATE family_child_devices
            SET credential_revoked_at = NOW(),
                revoked_by_membership_id = $3,
                version = version + 1
          WHERE family_id = $1 AND child_id = $2
            AND credential_hash IS NOT NULL
            AND credential_revoked_at IS NULL`,
        [familyId, childId, actorMembershipId],
      );
      return rowCount ?? 0;
    },

    async archiveChild(client, { familyId, childId, actorMembershipId }) {
      const { rows } = await client.query(
        `UPDATE family_children
            SET archived_at = NOW(),
                archived_by_membership_id = $3,
                version = version + 1,
                updated_at = NOW()
          WHERE family_id = $1 AND id = $2 AND archived_at IS NULL
        RETURNING id, display_name, archived_at`,
        [familyId, childId, actorMembershipId],
      );
      return rows[0] ?? null;
    },

    /** Audit only: a fact about data, not an announcement. */
    async audit(client, { familyId, actorMembershipId, correlationId, subjectId, subjectType, eventType }) {
      requireCorrelation(correlationId);
      await client.query(
        `INSERT INTO family_audit_events
           (id, family_id, actor_membership_id, correlation_id, event_type, subject_type, subject_id)
         VALUES (gen_random_uuid(), $1, $2, $3, $4, $5, $6)`,
        [familyId, actorMembershipId, correlationId, eventType, subjectType, subjectId],
      );
    },

    /** Audit plus outbox, through the store's shared helper: the family is told. */
    async announce(client, args) {
      await store.appendAuditAndOutbox(client, args);
    },
  };
}

function requireCorrelation(correlationId) {
  if (typeof correlationId !== 'string' || !CORRELATION_ID_PATTERN.test(correlationId)) {
    throw new HttpError(
      500,
      'correlation_context_missing',
      'A required internal trace context is unavailable.',
    );
  }
}

/** Builds the surface for a server that was handed a Foundation store. */
export function dataErasureFor(store) {
  return createDataErasureSurface({ port: postgresDataErasurePort(store) });
}
