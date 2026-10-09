// Device lifecycle contract tests.
//
// These defend the properties the M1 Devices system promises a guardian, at the
// layer where the promise is actually decided:
//
//   * a device that was cut off can never be described as working;
//   * a device that has gone quiet is named as offline rather than shown as
//     current, because a stale reading presented as live is worse than no reading;
//   * silence is reserved for devices that are fine, so the guardian's attention
//     keeps its value;
//   * revocation cannot be triggered on a device that never held a credential, and
//     cannot be repeated in a way that rewrites who cut it off or when.
import assert from 'node:assert/strict';
import test from 'node:test';
import {
  DEVICE_CAPABILITY_IDS,
  DEVICE_FRESH_WINDOW_MS,
  DEVICE_LIFECYCLE_VERSION,
  DEVICE_REASON_CODES,
  DEVICE_STALE_WINDOW_MS,
  deriveDeviceCapabilities,
  deriveDeviceHealth,
  deviceCredentialState,
  toGuardianDeviceView,
  validateDeviceRevocation,
} from '../src/device-lifecycle.js';

const NOW = Date.parse('2026-10-06T12:00:00.000Z');
const CREDENTIAL = 'a'.repeat(64);

function device(overrides = {}) {
  return {
    id: '11111111-1111-4111-8111-111111111111',
    childId: '22222222-2222-4222-8222-222222222222',
    deviceLabel: 'Synthetic phone',
    credentialHash: CREDENTIAL,
    credentialRevokedAt: null,
    lastSeenAt: new Date(NOW - 60_000).toISOString(),
    locationLat: 15.35,
    locationLng: 44.2,
    linkedAt: '2026-10-01T00:00:00.000Z',
    ...overrides,
  };
}

function minutesAgo(minutes) {
  return new Date(NOW - minutes * 60 * 1000).toISOString();
}

test('a never-claimed device is awaiting pairing, not working', () => {
  const target = device({ credentialHash: null, lastSeenAt: null });

  assert.equal(deviceCredentialState(target), 'unclaimed');

  const health = deriveDeviceHealth(target, { now: NOW });
  assert.equal(health.state, 'awaiting_pairing');
  assert.equal(health.reasonCode, DEVICE_REASON_CODES.awaitingPairing);
  // A guardian who just created the pairing code has done nothing wrong, so this
  // must not become a nag on the Today surface.
  assert.equal(health.needsAttention, false);
});

test('a fresh device is active, silent, and reports every capability available', () => {
  const health = deriveDeviceHealth(device(), { now: NOW });
  assert.equal(health.state, 'active');
  assert.equal(health.reasonCode, DEVICE_REASON_CODES.reportingNow);
  assert.equal(health.needsAttention, false);

  const capabilities = deriveDeviceCapabilities(device(), { now: NOW });
  assert.deepEqual(capabilities.map((entry) => entry.id), [...DEVICE_CAPABILITY_IDS]);
  for (const entry of capabilities) {
    assert.equal(entry.state, 'available', `${entry.id} should be available`);
  }
});

test('the freshness windows are the boundary, not an approximation of it', () => {
  const exactlyFresh = deriveDeviceHealth(
    device({ lastSeenAt: minutesAgo(DEVICE_FRESH_WINDOW_MS / 60_000) }),
    { now: NOW },
  );
  assert.equal(exactlyFresh.state, 'active');

  const oneMinuteLate = deriveDeviceHealth(
    device({ lastSeenAt: minutesAgo(DEVICE_FRESH_WINDOW_MS / 60_000 + 1) }),
    { now: NOW },
  );
  assert.equal(oneMinuteLate.state, 'stale');
  assert.equal(oneMinuteLate.needsAttention, true);

  const exactlyStale = deriveDeviceHealth(
    device({ lastSeenAt: minutesAgo(DEVICE_STALE_WINDOW_MS / 60_000) }),
    { now: NOW },
  );
  assert.equal(exactlyStale.state, 'stale');

  const beyondStale = deriveDeviceHealth(
    device({ lastSeenAt: minutesAgo(DEVICE_STALE_WINDOW_MS / 60_000 + 1) }),
    { now: NOW },
  );
  assert.equal(beyondStale.state, 'offline');
  assert.equal(beyondStale.reasonCode, DEVICE_REASON_CODES.stoppedReporting);
});

test('a quiet device loses every capability rather than keeping a stale one', () => {
  const quiet = device({ lastSeenAt: minutesAgo(DEVICE_STALE_WINDOW_MS / 60_000 + 5) });

  for (const entry of deriveDeviceCapabilities(quiet, { now: NOW })) {
    assert.equal(entry.state, 'unavailable', `${entry.id} must not look available`);
    assert.equal(entry.reasonCode, DEVICE_REASON_CODES.stoppedReporting);
  }
});

test('a device that reports but withholds location shows the gap, not a blank', () => {
  const capabilities = deriveDeviceCapabilities(
    device({ locationLat: null, locationLng: null }),
    { now: NOW },
  );
  const byId = Object.fromEntries(capabilities.map((entry) => [entry.id, entry]));

  assert.equal(byId.telemetry.state, 'available');
  assert.equal(byId.background_service.state, 'available');
  // Location is tracked separately from freshness: a device can be reporting
  // right now and still not be sending its position, and the guardian is entitled
  // to know which of the two is true.
  assert.equal(byId.location.state, 'unavailable');
  assert.equal(byId.location.reasonCode, DEVICE_REASON_CODES.locationMissing);
});

test('a revoked device can never be described as working', () => {
  const revoked = device({
    credentialRevokedAt: '2026-10-05T09:00:00.000Z',
    lastSeenAt: minutesAgo(1),
  });

  assert.equal(deviceCredentialState(revoked), 'revoked');

  const health = deriveDeviceHealth(revoked, { now: NOW });
  assert.equal(health.state, 'revoked');
  assert.equal(health.needsAttention, true);
  // Even though the last telemetry is one minute old and the coordinates are
  // present, a revoked credential means the server would refuse that device now.
  // Reporting it as current would be the exact lie this module exists to stop.
  for (const entry of deriveDeviceCapabilities(revoked, { now: NOW })) {
    assert.equal(entry.state, 'unavailable');
    assert.equal(entry.reasonCode, DEVICE_REASON_CODES.deviceRevoked);
  }
});

test('a device that never reported is named as such, not as offline', () => {
  const silent = device({ lastSeenAt: null });

  const health = deriveDeviceHealth(silent, { now: NOW });
  assert.equal(health.state, 'never_reported');
  assert.equal(health.needsAttention, true);
  // "never reported" and "stopped reporting" need different words and different
  // repairs, so they must not collapse into one state.
  assert.notEqual(health.reasonCode, DEVICE_REASON_CODES.stoppedReporting);
});

test('the guardian view carries one derived truth and no prose', () => {
  const view = toGuardianDeviceView(device(), { now: NOW });

  assert.equal(view.version, DEVICE_LIFECYCLE_VERSION);
  assert.equal(view.credentialState, 'active');
  assert.equal(view.health.state, 'active');
  assert.equal(view.capabilities.length, DEVICE_CAPABILITY_IDS.length);

  // Reason codes are machine-readable on purpose: guardian-facing sentences are
  // the client's job, so the server never ships English into an Arabic screen.
  for (const value of [view.health.reasonCode, ...view.capabilities.map((c) => c.reasonCode)]) {
    assert.match(value, /^[a-z_]+$/);
  }
});

test('the guardian view accepts snake_case rows as the database returns them', () => {
  const row = {
    id: '33333333-3333-4333-8333-333333333333',
    child_id: '22222222-2222-4222-8222-222222222222',
    device_label: 'Synthetic tablet',
    credential_hash: CREDENTIAL,
    credential_revoked_at: null,
    last_seen_at: minutesAgo(2),
    location_lat: 15.35,
    location_lng: 44.2,
    linked_at: '2026-10-01T00:00:00.000Z',
  };

  const view = toGuardianDeviceView(row, { now: NOW });
  assert.equal(view.deviceLabel, 'Synthetic tablet');
  assert.equal(view.health.state, 'active');
  assert.equal(view.lastSeenAt, row.last_seen_at);
});

test('revocation is refused on a device with nothing to revoke', () => {
  const refusal = validateDeviceRevocation(device({ credentialHash: null }));

  assert.notEqual(refusal, null);
  assert.equal(refusal.status, 409);
  assert.equal(refusal.code, 'device_not_claimed');
});

test('revocation is refused twice so the first record survives intact', () => {
  const refusal = validateDeviceRevocation(
    device({ credentialRevokedAt: '2026-10-05T09:00:00.000Z' }),
  );

  assert.notEqual(refusal, null);
  assert.equal(refusal.status, 409);
  assert.equal(refusal.code, 'device_already_revoked');
});

test('revocation is refused for a device that does not exist', () => {
  const refusal = validateDeviceRevocation(null);

  assert.notEqual(refusal, null);
  assert.equal(refusal.status, 404);
  assert.equal(refusal.code, 'device_not_found');
});

test('revocation is permitted exactly once, on a claimed and live device', () => {
  assert.equal(validateDeviceRevocation(device()), null);
});

test('a device with an unreadable timestamp is treated as never reported', () => {
  // Telemetry timestamps arrive from the database and from tests, so a malformed
  // value must fail towards "we do not know" rather than towards "still working".
  const health = deriveDeviceHealth(device({ lastSeenAt: 'not-a-timestamp' }), { now: NOW });
  assert.equal(health.state, 'never_reported');
});
