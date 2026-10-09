// Device lifecycle truth for M1 (system 37, Devices).
//
// Every device the family links is a record that can be paired, can report, can
// go quiet, and can be cut off. Until now the server stored those facts but never
// said what they MEAN, so no client could tell a guardian the one thing that
// matters: is this device's protection working right now, and if not, why.
//
// This module derives that meaning. It is deliberately pure - no database, no
// HTTP, no clock of its own - because the same answer must be produced by the
// server that owns the decision and asserted by tests that do not need Postgres.
//
// Three principles, inherited from the constitution and SPINE-001:
//
//   1. Capability is a server decision. A client may render this and may not
//      recompute it, so the two can never disagree about whether a child is
//      protected.
//   2. No state without a reason. "Attention needed" with no named cause is
//      anxiety without action, so every state carries a machine reason code that
//      the client localizes rather than invents.
//   3. Silence is a decision. A healthy device produces needsAttention false and
//      therefore nothing on the Today surface. Only a device that wants the
//      guardian's hand is allowed to speak.

export const DEVICE_LIFECYCLE_VERSION = 'device-lifecycle.v1';

/**
 * What a device can do, as a closed set. A capability that has no server-side
 * source is not admitted here, because admitting one would mean inventing an
 * answer - the exact failure this module exists to prevent.
 */
export const DEVICE_CAPABILITY_IDS = Object.freeze([
  'telemetry',
  'location',
  'background_service',
]);

export const DEVICE_CAPABILITY_STATES = Object.freeze([
  'available',
  'stale',
  'unavailable',
]);

/**
 * The guardian-facing condition of a device. Exactly one applies.
 *
 * `awaiting_pairing` is deliberately NOT an attention state. A pairing record was
 * just created by the guardian, and whether its code has expired is the pairing
 * record's own business; treating a fresh code as a problem would nag the guardian
 * for doing the right thing.
 */
export const DEVICE_HEALTH_STATES = Object.freeze([
  'revoked',
  'awaiting_pairing',
  'never_reported',
  'active',
  'stale',
  'offline',
]);

/**
 * Freshness windows, declared rather than hidden in an expression.
 *
 * A device that reported within FRESH is working. Within STALE it is late but the
 * data may still be shown as recent with its age stated. Beyond STALE the family
 * should stop treating the last reading as current.
 */
export const DEVICE_FRESH_WINDOW_MS = 15 * 60 * 1000;
export const DEVICE_STALE_WINDOW_MS = 6 * 60 * 60 * 1000;

/**
 * Machine reason codes. The server never returns guardian-facing prose, because
 * that would put copy in the wrong layer and force Arabic onto an English screen.
 * The client turns these into localized sentences.
 */
export const DEVICE_REASON_CODES = Object.freeze({
  deviceRevoked: 'device_revoked',
  awaitingPairing: 'awaiting_pairing',
  neverReported: 'never_reported',
  reportingNow: 'reporting_now',
  reportingLate: 'reporting_late',
  stoppedReporting: 'stopped_reporting',
  locationReported: 'location_reported',
  locationMissing: 'location_missing',
});

/** The states that must reach the guardian. Everything else stays silent. */
const ATTENTION_STATES = Object.freeze(new Set([
  'revoked',
  'never_reported',
  'stale',
  'offline',
]));

function parseTimestamp(value) {
  if (value == null) {
    return null;
  }
  if (value instanceof Date) {
    const time = value.getTime();
    return Number.isNaN(time) ? null : time;
  }
  const parsed = Date.parse(value);
  return Number.isNaN(parsed) ? null : parsed;
}

/**
 * The credential lifecycle of a device, which gates every capability it has.
 *
 * `unclaimed` means a guardian registered the device but no handset has presented
 * the pairing code yet. `revoked` is terminal: the server already refuses
 * telemetry from a revoked credential, so nothing downstream may report it as
 * working.
 */
export function deviceCredentialState(device) {
  if (parseTimestamp(device?.credentialRevokedAt ?? device?.credential_revoked_at) != null) {
    return 'revoked';
  }
  const hash = device?.credentialHash ?? device?.credential_hash;
  return typeof hash === 'string' && hash.length > 0 ? 'active' : 'unclaimed';
}

function capability(id, state, reasonCode, since) {
  return Object.freeze({ id, state, reasonCode, since });
}

function unavailableCapabilities(reasonCode, since) {
  return DEVICE_CAPABILITY_IDS.map((id) => capability(id, 'unavailable', reasonCode, since));
}

/**
 * Derive every capability, its state, and the reason for that state.
 *
 * `background_service` is honest about its limits. The server cannot observe an
 * Android service directly; what it can observe is that telemetry keeps arriving,
 * which is the observable consequence of that service running. So the capability
 * is derived from reporting freshness and is named for what is measured rather
 * than for what is assumed.
 */
export function deriveDeviceCapabilities(device, { now = Date.now() } = {}) {
  const credential = deviceCredentialState(device);

  if (credential === 'revoked') {
    const since = device.credentialRevokedAt ?? device.credential_revoked_at ?? null;
    return unavailableCapabilities(DEVICE_REASON_CODES.deviceRevoked, since);
  }
  if (credential === 'unclaimed') {
    return unavailableCapabilities(
      DEVICE_REASON_CODES.awaitingPairing,
      device.linkedAt ?? device.linked_at ?? null,
    );
  }

  const lastSeen = parseTimestamp(device.lastSeenAt ?? device.last_seen_at);
  if (lastSeen == null) {
    return unavailableCapabilities(
      DEVICE_REASON_CODES.neverReported,
      device.linkedAt ?? device.linked_at ?? null,
    );
  }

  const since = new Date(lastSeen).toISOString();
  const age = now - lastSeen;

  if (age > DEVICE_STALE_WINDOW_MS) {
    return unavailableCapabilities(DEVICE_REASON_CODES.stoppedReporting, since);
  }

  const reporting = age > DEVICE_FRESH_WINDOW_MS ? 'stale' : 'available';
  const reportingReason =
    reporting === 'available'
      ? DEVICE_REASON_CODES.reportingNow
      : DEVICE_REASON_CODES.reportingLate;

  const hasLocation =
    (device.locationLat ?? device.location_lat) != null &&
    (device.locationLng ?? device.location_lng) != null;

  return [
    capability('telemetry', reporting, reportingReason, since),
    // Location lags the device, not the freshness window: a device can be
    // reporting right now and still have withheld location, which is a fact the
    // guardian needs to see rather than a case to smooth over.
    capability(
      'location',
      hasLocation ? 'available' : 'unavailable',
      hasLocation
        ? DEVICE_REASON_CODES.locationReported
        : DEVICE_REASON_CODES.locationMissing,
      since,
    ),
    capability('background_service', reporting, reportingReason, since),
  ];
}

/**
 * Derive the single guardian-facing condition, with its cause and the moment it
 * began. `needsAttention` is the only field the Today surface consults, so a
 * healthy device stays silent by construction rather than by a client's choice.
 */
export function deriveDeviceHealth(device, { now = Date.now() } = {}) {
  const credential = deviceCredentialState(device);
  const linkedAt = device.linkedAt ?? device.linked_at ?? null;

  if (credential === 'revoked') {
    return buildHealth('revoked', DEVICE_REASON_CODES.deviceRevoked,
      device.credentialRevokedAt ?? device.credential_revoked_at ?? null);
  }
  if (credential === 'unclaimed') {
    return buildHealth('awaiting_pairing', DEVICE_REASON_CODES.awaitingPairing, linkedAt);
  }

  const lastSeen = parseTimestamp(device.lastSeenAt ?? device.last_seen_at);
  if (lastSeen == null) {
    return buildHealth('never_reported', DEVICE_REASON_CODES.neverReported, linkedAt);
  }

  const since = new Date(lastSeen).toISOString();
  const age = now - lastSeen;
  if (age > DEVICE_STALE_WINDOW_MS) {
    return buildHealth('offline', DEVICE_REASON_CODES.stoppedReporting, since);
  }
  if (age > DEVICE_FRESH_WINDOW_MS) {
    return buildHealth('stale', DEVICE_REASON_CODES.reportingLate, since);
  }
  return buildHealth('active', DEVICE_REASON_CODES.reportingNow, since);
}

function buildHealth(state, reasonCode, since) {
  return Object.freeze({
    state,
    reasonCode,
    since: since ?? null,
    needsAttention: ATTENTION_STATES.has(state),
  });
}

/**
 * The complete guardian-facing view of one device: what it is, what it can do,
 * and whether it wants the guardian's hand.
 *
 * This is the shape the device read surface is expected to return, and the shape
 * the Flutter mirror renders. Keeping one function authoritative is what makes
 * the two sides describe the same device.
 */
export function toGuardianDeviceView(device, { now = Date.now() } = {}) {
  const health = deriveDeviceHealth(device, { now });
  const capabilities = deriveDeviceCapabilities(device, { now });
  return Object.freeze({
    version: DEVICE_LIFECYCLE_VERSION,
    id: device.id,
    childId: device.childId ?? device.child_id,
    deviceLabel: device.deviceLabel ?? device.device_label,
    credentialState: deviceCredentialState(device),
    batteryLevel: device.batteryLevel ?? device.battery_level ?? null,
    batteryStatus: device.batteryStatus ?? device.battery_status ?? null,
    locationLat: device.locationLat ?? device.location_lat ?? null,
    locationLng: device.locationLng ?? device.location_lng ?? null,
    locationLabel: device.locationLabel ?? device.location_label ?? null,
    lastSeenAt: device.lastSeenAt ?? device.last_seen_at ?? null,
    linkedAt: device.linkedAt ?? device.linked_at ?? null,
    capabilities,
    health,
  });
}

/**
 * Decide whether a guardian may revoke this device, and refuse with a named
 * cause when they may not.
 *
 * This is the missing half of a mechanism that already exists: the server refuses
 * telemetry from a revoked credential, but nothing could set that revocation, so
 * a lost handset stayed trusted forever. Returns null when the revocation is
 * permitted, or `{ status, code, message }` when it is not.
 */
export function validateDeviceRevocation(device) {
  if (device == null) {
    return Object.freeze({
      status: 404,
      code: 'device_not_found',
      message: 'Linked device was not found.',
    });
  }
  if (deviceCredentialState(device) === 'revoked') {
    // Revocation is idempotent by intent: a second attempt is not an error the
    // guardian must understand, and re-revoking must never rewrite which guardian
    // cut the device off or when.
    return Object.freeze({
      status: 409,
      code: 'device_already_revoked',
      message: 'This device is already cut off.',
    });
  }
  const hash = device.credentialHash ?? device.credential_hash;
  if (typeof hash !== 'string' || hash.length === 0) {
    // Nothing to revoke yet. Letting this pass would write a revocation for a
    // device that never held a credential and produce a confusing lifecycle.
    return Object.freeze({
      status: 409,
      code: 'device_not_claimed',
      message: 'This device has not been paired yet.',
    });
  }
  return null;
}
