// The HTTP-facing face of the minutes economy (S3, D3).
//
// The economy (minutes-economy.js) owns every rule: the ceilings, the draw order, the reversal
// limits, the duplicate guard. This module owns only what the economy cannot know: who is
// asking, whether they are a guardian of this family, and which device a handset is.
//
// Every operation runs in one store transaction. A mutation also takes an Idempotency-Key slot
// in that same transaction, so a retried request replays the original answer instead of
// writing a second row.
import { createHash, randomUUID } from 'node:crypto';
import { HttpError } from './http-error.js';
import {
  adjust,
  allocate,
  consume,
  earn,
  grant,
  joinMinutesTransaction,
  readBalance,
  readLedger,
} from './minutes-economy.js';

const GUARDIAN_ROLES = new Set(['primary_guardian', 'co_guardian']);

async function guardianOf(tx, store, familyId, subject) {
  const actor = await store.activeActorMembership(tx, familyId, subject);
  if (!GUARDIAN_ROLES.has(actor.role)) {
    throw new HttpError(403, 'minutes_forbidden', 'Only a guardian may use the minutes ledger.');
  }
  return actor;
}

/** The device that is speaking must be a live device of this child, proven by its credential. */
async function deviceOfChild(tx, store, { familyId, childId, deviceCredential, credentialMatches }) {
  if (typeof deviceCredential !== 'string') {
    throw new HttpError(403, 'device_credential_rejected', 'The device credential is not accepted.');
  }
  const { rows } = await tx.query(
    `SELECT id, family_id, child_id, credential_hash
       FROM family_child_devices
      WHERE family_id = $1 AND child_id = $2 AND credential_revoked_at IS NULL`,
    [familyId, childId],
  );
  const device = rows.find((row) => credentialMatches(row.credential_hash, deviceCredential));
  if (device == null) {
    throw new HttpError(403, 'device_credential_rejected', 'The device credential is not accepted.');
  }
  return device;
}

async function deviceById(tx, { deviceId, deviceCredential, credentialMatches }) {
  const { rows } = await tx.query(
    `SELECT id, family_id, child_id, credential_hash, credential_revoked_at
       FROM family_child_devices WHERE id = $1`,
    [deviceId],
  );
  const device = rows[0];
  if (
    device == null
    || device.credential_revoked_at != null
    || typeof deviceCredential !== 'string'
    || !credentialMatches(device.credential_hash, deviceCredential)
  ) {
    throw new HttpError(403, 'device_credential_rejected', 'The device credential is not accepted.');
  }
  return device;
}

/** A mutation: idempotent by its key, and atomic with the economy's own writes. */
async function mutate(store, { scope, idempotencyKey, requestHash, work }) {
  return store.withTransaction(async (tx) => {
    const replay = await store.acquireIdempotencySlot(tx, scope, idempotencyKey, requestHash);
    if (replay) return replay;
    const result = await joinMinutesTransaction(tx, () => work(tx));
    await store.completeIdempotencySlot(tx, scope, idempotencyKey, result);
    return result;
  });
}

/** A read: one snapshot, and the economy's own rules applied inside it. */
async function read(store, work) {
  return store.withTransaction((tx) => joinMinutesTransaction(tx, () => work(tx)));
}

function instantOrNull(value) {
  return value == null ? null : new Date(value);
}

export function minutesFor(store, { credentialMatches }) {
  return {
    async earn({ principal, familyId, childId, body, idempotencyKey, requestHash }) {
      return mutate(store, {
        scope: `minutes:earn:${familyId}:${childId}`,
        idempotencyKey,
        requestHash,
        work: async (tx) => {
          const actor = await guardianOf(tx, store, familyId, principal.subject);
          return earn(tx, { familyId, childId, actorMembershipId: actor.id, ...body });
        },
      });
    },

    async consume({ deviceCredential, familyId, childId, body, idempotencyKey, requestHash }) {
      return mutate(store, {
        scope: `minutes:consume:${familyId}:${childId}`,
        idempotencyKey,
        requestHash,
        work: async (tx) => {
          const device = await deviceOfChild(tx, store, {
            familyId, childId, deviceCredential, credentialMatches,
          });
          return consume(tx, {
            familyId,
            childId,
            appId: body.appId,
            minutes: body.minutes,
            source: { type: 'session', id: body.sessionId },
            deviceId: device.id,
          });
        },
      });
    },

    async grant({ principal, familyId, childId, body, idempotencyKey, requestHash }) {
      return mutate(store, {
        scope: `minutes:grant:${familyId}:${childId}`,
        idempotencyKey,
        requestHash,
        work: async (tx) => {
          const actor = await guardianOf(tx, store, familyId, principal.subject);
          return grant(tx, {
            familyId,
            childId,
            actorMembershipId: actor.id,
            minutes: body.minutes,
            scope: body.scope,
            appId: body.appId,
            expiresAt: instantOrNull(body.expiresAt),
            reason: body.reason,
            // A grant has no caller-side reference, so the idempotency key is its source: the
            // same key cannot write two grants, even across a lost response.
            source: { type: 'guardian_grant', id: idempotencyKey },
          });
        },
      });
    },

    async allocate({ principal, familyId, childId, body, idempotencyKey, requestHash }) {
      return mutate(store, {
        scope: `minutes:allocate:${familyId}:${childId}`,
        idempotencyKey,
        requestHash,
        work: async (tx) => {
          const actor = await guardianOf(tx, store, familyId, principal.subject);
          return allocate(tx, {
            familyId,
            childId,
            actorMembershipId: actor.id,
            from: body.from,
            to: body.to,
            minutes: body.minutes,
            reason: body.reason,
            transferId: randomUUID(),
          });
        },
      });
    },

    async reverse({ principal, familyId, childId, body, idempotencyKey, requestHash }) {
      return mutate(store, {
        scope: `minutes:reverse:${familyId}:${childId}`,
        idempotencyKey,
        requestHash,
        work: async (tx) => {
          const actor = await guardianOf(tx, store, familyId, principal.subject);
          // The economy refuses anyone but the primary guardian (403 minutes_forbidden).
          return adjust(tx, {
            familyId,
            childId,
            actorMembershipId: actor.id,
            targetEntryId: body.targetEntryId,
            minutes: body.minutes,
            reason: body.reason,
          });
        },
      });
    },

    async ledger({ principal, familyId, childId, query }) {
      return read(store, async (tx) => {
        await guardianOf(tx, store, familyId, principal.subject);
        return readLedger(tx, { familyId, childId, limit: query.limit, cursor: query.cursor });
      });
    },

    async balance({ principal, familyId, childId }) {
      return read(store, async (tx) => {
        await guardianOf(tx, store, familyId, principal.subject);
        return readBalance(tx, { familyId, childId });
      });
    },

    /** The child's own handset: the full shape, per-app detail included (for the wallet view). */
    async deviceBalance({ deviceId, deviceCredential }) {
      return read(store, async (tx) => {
        const device = await deviceById(tx, { deviceId, deviceCredential, credentialMatches });
        return readBalance(tx, { familyId: device.family_id, childId: device.child_id });
      });
    },
  };
}

/** A stable subject for a device, for fingerprints: the credential itself is never stored. */
export function deviceFingerprintSubject(deviceCredential) {
  return `device:${createHash('sha256').update(deviceCredential).digest('hex')}`;
}
