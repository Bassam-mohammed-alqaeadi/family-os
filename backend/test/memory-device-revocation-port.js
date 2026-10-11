// A revocation port over the in-memory foundation store, shared by the suites that
// drive the real device write path.
//
// Deliberately thin: every method is one store call plus the mapping between the store's
// camelCase objects and the database's snake_case rows, which is confined to asRow().
// It holds no rules of its own - no authorization rule, no already-revoked rule, no
// idempotency rule - because a test that reimplemented those would prove nothing about
// the server. Extracted from device-revocation.test.js when a second suite needed to
// revoke a device, so the two suites exercise one adapter instead of two copies of it.
import { HttpError } from '../src/http-error.js';

/**
 * A revocation port over the in-memory store.
 *
 * Deliberately thin: every method is one store call plus the mapping between the
 * store's camelCase objects and the database's snake_case rows, which is confined
 * to asRow().
 */
export function memoryDeviceRevocationPort(store) {
  return {
    // The in-memory store's idempotency helper is synchronous, so it would store
    // the promise this port hands it instead of its resolved value. This is the
    // same contract with the await restored: same scope-key, same hash reuse
    // refusal, same replay of the stored response.
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
    async authorize(_tx, { familyId, subject }) {
      return store.activeMembership(familyId, subject, true);
    },
    async readDevice(_tx, { familyId, childId, deviceId }) {
      const device = store.devices.get(deviceId);
      if (!device || device.familyId !== familyId || device.childId !== childId) return null;
      return asRow(device);
    },
    async markRevoked(_tx, { deviceId, actorMembershipId, reasonCode }) {
      const device = store.devices.get(deviceId);
      if (!device || !device.credentialHash || device.credentialRevokedAt) return null;
      device.credentialRevokedAt = store.now().toISOString();
      device.revokedByMembershipId = actorMembershipId;
      device.revocationReason = reasonCode;
      // Slice 3: the revocation statement itself empties the location snapshot, so the
      // double must too — a test adapter that kept a position production deletes would
      // let a suite pass while the guardian screen still drew a last-known place.
      device.locationLat = null;
      device.locationLng = null;
      device.locationLabel = null;
      device.version += 1;
      return asRow(device);
    },
    async eraseDeviceLocation(_tx, { familyId, deviceId }) {
      const inFamily = (row) => row.familyId === familyId && row.deviceId === deviceId;
      const geofenceEvents = store.geofenceEvents.filter(inFamily).length;
      store.geofenceEvents = store.geofenceEvents.filter((row) => !inFamily(row));
      let sosFixReferences = 0;
      for (const alert of store.sosAlerts) {
        if (alert.familyId !== familyId || alert.fixId == null) continue;
        const referenced = store.locationFixes.some((fix) => fix.id === alert.fixId && fix.deviceId === deviceId);
        if (referenced) {
          alert.fixId = null;
          sosFixReferences += 1;
        }
      }
      const locationFixes = store.locationFixes.filter(inFamily).length;
      store.locationFixes = store.locationFixes.filter((row) => !inFamily(row));
      return { locationFixes, geofenceEvents, sosFixReferences };
    },
    async audit(_tx, { familyId, actorMembershipId, correlationId, subjectId }) {
      store.recordAudit(
        familyId,
        actorMembershipId,
        correlationId,
        'family.child_device_revoked',
        'family_child_device',
        subjectId,
      );
    },
    /** Audit only, deliberately NOT store.recordAudit — that helper also writes an
     * outbox row, and the erasure is a fact about data, not an announcement. The
     * revocation itself is the family event; it is the one that gets announced. */
    async auditErasure(_tx, { familyId, actorMembershipId, correlationId, subjectId }) {
      store.audit.push({
        familyId,
        actorMembershipId,
        correlationId,
        eventType: 'family.child_device_location_erased',
        subjectType: 'family_child_device',
        subjectId,
      });
    },
    async fact(_tx, { familyId, childId, deviceId, correlationId }) {
      store.recordAiEvent({
        familyId,
        childId,
        deviceId,
        eventType: 'device.revoked',
        correlationId,
      });
    },
  };
}

export function asRow(device) {
  return {
    ...device,
    credential_hash: device.credentialHash ?? null,
    credential_revoked_at: device.credentialRevokedAt ?? null,
    // Slice 3: the operation reads the location snapshot to count what the revocation
    // emptied, so the double must present it in the same shape the database row has —
    // an `undefined` where production says `null` would count a snapshot that does not
    // exist.
    location_lat: device.locationLat ?? null,
    location_lng: device.locationLng ?? null,
    location_label: device.locationLabel ?? null,
  };
}

