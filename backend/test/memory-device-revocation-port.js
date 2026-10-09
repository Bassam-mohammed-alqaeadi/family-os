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
      device.version += 1;
      return asRow(device);
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
  };
}

