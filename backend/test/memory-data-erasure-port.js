// A data-erasure port over the in-memory foundation store, for the HTTP-level laws of
// slice 3 (test/data-erasure.test.js).
//
// Deliberately thin, like the revocation port it sits beside: every method is data
// access over the store's own collections, and the camelCase↔snake_case mapping is
// confined to the child row. It holds no rules of its own — no authorization rule, no
// already-archived rule, no idempotency rule — because those live in
// src/data-erasure.js, which is the code under test. The real SQL half of the same port
// is exercised in test/postgres-data-erasure.test.js against a real database.
import { HttpError } from '../src/http-error.js';

export function memoryDataErasurePort(store) {
  return {
    // The in-memory store's idempotency helper is synchronous, so it would store the
    // promise this port hands it instead of its resolved value. Same contract with the
    // await restored: same scope-key, same hash-reuse refusal, same replay.
    async idempotent(scope, key, requestHash, work) {
      const recordKey = `${scope}:${key}`;
      const cached = store.idempotency.get(recordKey);
      if (cached) {
        if (cached.hash !== requestHash) {
          throw new HttpError(
            409,
            'idempotency_key_reused',
            'Idempotency-Key cannot be reused with a different request.',
          );
        }
        return structuredClone(cached.response);
      }
      const result = await work(null);
      store.idempotency.set(recordKey, { hash: requestHash, response: structuredClone(result) });
      return result;
    },

    async withTransaction(run) {
      return run(null);
    },

    async authorize(_tx, { familyId, subject }) {
      return store.activeMembership(familyId, subject, true);
    },

    async readChildIncludingArchived(_tx, { familyId, childId }) {
      const child = store.children.get(childId);
      if (!child || child.familyId !== familyId) return null;
      return {
        id: child.id,
        display_name: child.displayName,
        archived_at: child.archivedAt ?? null,
      };
    },

    async eraseChildLocationData(_tx, { familyId, childId }) {
      const inScope = (row) => row.familyId === familyId && row.childId === childId;

      const geofenceEvents = store.geofenceEvents.filter(inScope).length;
      store.geofenceEvents = store.geofenceEvents.filter((row) => !inScope(row));

      // The incident stays; the measurement it pointed at is honestly gone.
      let sosFixReferences = 0;
      for (const alert of store.sosAlerts) {
        if (alert.familyId !== familyId || alert.childId !== childId || alert.fixId == null) continue;
        alert.fixId = null;
        sosFixReferences += 1;
      }

      const locationFixes = store.locationFixes.filter(inScope).length;
      store.locationFixes = store.locationFixes.filter((row) => !inScope(row));

      let deviceSnapshots = 0;
      for (const device of store.devices.values()) {
        if (device.familyId !== familyId || device.childId !== childId) continue;
        if (device.locationLat != null || device.locationLng != null || device.locationLabel != null) {
          device.locationLat = null;
          device.locationLng = null;
          device.locationLabel = null;
          deviceSnapshots += 1;
        }
      }

      return { locationFixes, geofenceEvents, deviceSnapshots, sosFixReferences };
    },

    async withdrawActiveConsents() {
      // The in-memory store keeps no consent ledger (slice 2's unit laws keep their own
      // fake), so the honest answer about this double is: nothing to freeze.
      return 0;
    },

    async revokeChildDevices(_tx, { familyId, childId, actorMembershipId }) {
      const now = store.now().toISOString();
      let revoked = 0;
      for (const device of store.devices.values()) {
        if (device.familyId !== familyId || device.childId !== childId) continue;
        if (!device.credentialHash || device.credentialRevokedAt) continue;
        device.credentialRevokedAt = now;
        device.revokedByMembershipId = actorMembershipId;
        device.revocationReason = null;
        device.version += 1;
        revoked += 1;
      }
      return revoked;
    },

    async archiveChild(_tx, { familyId, childId, actorMembershipId }) {
      const child = store.children.get(childId);
      // The guard is in the write, as in the SQL: null means already archived.
      if (!child || child.familyId !== familyId || child.archivedAt != null) return null;
      const now = store.now().toISOString();
      child.archivedAt = now;
      child.archivedByMembershipId = actorMembershipId;
      child.version += 1;
      child.updatedAt = now;
      return { id: child.id, display_name: child.displayName, archived_at: child.archivedAt };
    },

    /** Audit only: a fact about data. Deliberately NOT store.recordAudit, which also
     * writes an outbox row — the erasure is not an announcement. */
    async audit(_tx, { familyId, actorMembershipId, correlationId, subjectId, subjectType, eventType }) {
      store.audit.push({
        familyId,
        actorMembershipId,
        correlationId,
        eventType,
        subjectType,
        subjectId,
      });
    },

    /** Audit plus outbox, the same pair the production announce writes. */
    async announce(_tx, { familyId, actorMembershipId, correlationId, subjectId, subjectType, eventType }) {
      store.recordAudit(familyId, actorMembershipId, correlationId, eventType, subjectType, subjectId);
    },
  };
}
