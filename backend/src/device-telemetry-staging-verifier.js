import { randomUUID } from 'node:crypto';

import { stagingBaseUrl } from './staging-foundation-verifier.js';

function requiredToken(value, label) {
  if (typeof value !== 'string' || !value.trim()) {
    throw new Error(`${label} token is required.`);
  }
  return value.trim();
}

function subjectFromToken(token, label) {
  const parts = token.split('.');
  if (parts.length !== 3) throw new Error(`${label} token is not a JWT.`);
  try {
    const payload = JSON.parse(Buffer.from(parts[1], 'base64url').toString('utf8'));
    if (typeof payload.sub !== 'string' || !payload.sub || payload.sub.length > 255 || /[\u0000-\u001F\u007F]/.test(payload.sub)) {
      throw new Error('invalid subject');
    }
    return payload.sub;
  } catch {
    throw new Error(`${label} token does not contain a valid subject.`);
  }
}

function requireDistinctSubjects(subjects) {
  if (new Set(Object.values(subjects)).size !== Object.keys(subjects).length) {
    throw new Error('Device telemetry verification requires four distinct synthetic principals.');
  }
}

async function jsonResponse(response) {
  try {
    return await response.json();
  } catch {
    return undefined;
  }
}

function requireResponse({ response, body }, { status, errorCode }) {
  if (response.status !== status) {
    throw new Error(`Expected HTTP ${status}, received ${response.status}.`);
  }
  if (errorCode && body?.error?.code !== errorCode) {
    throw new Error(`Expected API error code ${errorCode}.`);
  }
}

function requireId(value, label) {
  if (typeof value !== 'string' || !value) throw new Error(`${label} was missing from the API response.`);
  return value;
}

function responseCorrelation(response) {
  const correlationId = response.headers.get('x-correlation-id');
  if (!correlationId) throw new Error('Expected a server-generated correlation ID.');
  return correlationId;
}

function requireDevice(body, expected) {
  const device = body?.device;
  if (
    typeof device?.id !== 'string' ||
    device.childId !== expected.childId ||
    device.deviceLabel !== expected.deviceLabel ||
    device.batteryLevel !== expected.batteryLevel ||
    device.batteryStatus !== expected.batteryStatus ||
    device.locationLabel !== expected.locationLabel ||
    (expected.lastSeen && typeof device.lastSeenAt !== 'string') ||
    (!expected.lastSeen && device.lastSeenAt !== null)
  ) {
    throw new Error('Device response did not contain the expected latest telemetry fact.');
  }
  return device;
}

/// One mutating acceptance check for Phase 1 latest-state telemetry.
///
/// It uses explicitly supplied short-lived synthetic-user tokens and does not
/// log them. It proves API authority and audit truth; the Flutter rendering
/// hand-off is listed separately in the operator acceptance guide because it
/// needs the same Firebase-authenticated emulator/device session.
export async function verifyDeviceTelemetryStaging({
  baseUrl,
  primaryGuardianToken,
  coGuardianToken,
  childToken,
  unrelatedToken,
  fetchImpl = fetch,
  idFactory = randomUUID,
}) {
  const origin = stagingBaseUrl(baseUrl);
  const tokens = {
    primary: requiredToken(primaryGuardianToken, 'Primary guardian'),
    coGuardian: requiredToken(coGuardianToken, 'Co-guardian'),
    child: requiredToken(childToken, 'Child'),
    unrelated: requiredToken(unrelatedToken, 'Unrelated principal'),
  };
  const subjects = Object.fromEntries(
    Object.entries(tokens).map(([label, token]) => [label, subjectFromToken(token, label)]),
  );
  requireDistinctSubjects(subjects);

  const request = async (path, { token, method = 'GET', idempotencyKey, body } = {}) => {
    const headers = { Accept: 'application/json' };
    if (token) headers.Authorization = `Bearer ${token}`;
    if (idempotencyKey) headers['Idempotency-Key'] = idempotencyKey;
    if (body !== undefined) headers['Content-Type'] = 'application/json';
    const response = await fetchImpl(new URL(path, origin), {
      method,
      redirect: 'error',
      headers,
      body: body === undefined ? undefined : JSON.stringify(body),
    });
    return { response, body: await jsonResponse(response) };
  };

  const familyCreated = await request('/v1/families', {
    method: 'POST',
    token: tokens.primary,
    idempotencyKey: idFactory(),
    body: { displayName: `Synthetic telemetry verification ${idFactory()}` },
  });
  requireResponse(familyCreated, { status: 201 });
  const familyId = requireId(familyCreated.body?.family?.id, 'Family ID');

  const childCreated = await request(`/v1/families/${familyId}/children`, {
    method: 'POST',
    token: tokens.primary,
    idempotencyKey: idFactory(),
    body: {
      displayName: `Synthetic telemetry child ${idFactory()}`,
      ageYears: 8,
      avatarEmoji: '🧒',
      themeColor: 'teal',
    },
  });
  requireResponse(childCreated, { status: 201 });
  const childId = requireId(childCreated.body?.child?.id, 'Child ID');

  for (const [role, tokenName] of [['co_guardian', 'coGuardian'], ['child', 'child']]) {
    const invited = await request(`/v1/families/${familyId}/memberships`, {
      method: 'POST',
      token: tokens.primary,
      idempotencyKey: idFactory(),
      body: { role, targetSubject: subjects[tokenName] },
    });
    requireResponse(invited, { status: 201 });
    const membershipId = requireId(invited.body?.membership?.id, 'Membership ID');
    const accepted = await request(`/v1/families/${familyId}/memberships/${membershipId}/accept`, {
      method: 'POST',
      token: tokens[tokenName],
      idempotencyKey: idFactory(),
      body: {},
    });
    requireResponse(accepted, { status: 200 });
  }

  const linkKey = idFactory();
  const linkInput = { deviceLabel: 'Synthetic developer telemetry device' };
  const linked = await request(`/v1/families/${familyId}/children/${childId}/devices`, {
    method: 'POST', token: tokens.primary, idempotencyKey: linkKey, body: linkInput,
  });
  requireResponse(linked, { status: 201 });
  const linkedDevice = requireDevice(linked.body, {
    childId, deviceLabel: linkInput.deviceLabel, batteryLevel: null,
    batteryStatus: null, locationLabel: null, lastSeen: false,
  });
  const linkCorrelationId = responseCorrelation(linked.response);

  const replay = await request(`/v1/families/${familyId}/children/${childId}/devices`, {
    method: 'POST', token: tokens.primary, idempotencyKey: linkKey, body: linkInput,
  });
  requireResponse(replay, { status: 201 });
  if (requireDevice(replay.body, {
    childId, deviceLabel: linkInput.deviceLabel, batteryLevel: null,
    batteryStatus: null, locationLabel: null, lastSeen: false,
  }).id !== linkedDevice.id) {
    throw new Error('Idempotent device registration did not return the original linked device.');
  }
  const conflictingReplay = await request(`/v1/families/${familyId}/children/${childId}/devices`, {
    method: 'POST', token: tokens.primary, idempotencyKey: linkKey, body: { deviceLabel: 'Changed intent' },
  });
  requireResponse(conflictingReplay, { status: 409, errorCode: 'idempotency_key_reused' });

  const telemetryInput = {
    batteryLevel: 78, batteryStatus: 'unplugged',
    locationLat: 38.8646, locationLng: -77.2749, locationLabel: 'Soccer Practice',
  };
  const telemetry = await request(`/v1/devices/${linkedDevice.id}/telemetry`, {
    method: 'POST', token: tokens.primary, body: telemetryInput,
  });
  requireResponse(telemetry, { status: 200 });
  requireDevice(telemetry.body, { childId, deviceLabel: linkInput.deviceLabel, ...telemetryInput, lastSeen: true });
  const telemetryCorrelationId = responseCorrelation(telemetry.response);

  const primaryRead = await request(`/v1/families/${familyId}/devices`, { token: tokens.primary });
  requireResponse(primaryRead, { status: 200 });
  const primaryDevices = primaryRead.body?.devices;
  if (!Array.isArray(primaryDevices) || primaryDevices.length !== 1 || primaryDevices[0]?.id !== linkedDevice.id || primaryDevices[0]?.locationLabel !== 'Soccer Practice') {
    throw new Error('Primary guardian device read did not return the latest scoped telemetry.');
  }
  const coGuardianRead = await request(`/v1/families/${familyId}/devices`, { token: tokens.coGuardian });
  requireResponse(coGuardianRead, { status: 200 });
  if (coGuardianRead.body?.devices?.[0]?.id !== linkedDevice.id) {
    throw new Error('Co-guardian device read did not return the linked device.');
  }

  const coGuardianWrite = await request(`/v1/devices/${linkedDevice.id}/telemetry`, {
    method: 'POST', token: tokens.coGuardian, body: telemetryInput,
  });
  requireResponse(coGuardianWrite, { status: 403, errorCode: 'family_access_denied' });
  const childRead = await request(`/v1/families/${familyId}/devices`, { token: tokens.child });
  requireResponse(childRead, { status: 403, errorCode: 'device_telemetry_access_denied' });
  const unrelatedRead = await request(`/v1/families/${familyId}/devices`, { token: tokens.unrelated });
  requireResponse(unrelatedRead, { status: 403, errorCode: 'family_access_denied' });

  const audit = await request(`/v1/families/${familyId}/audit-events`, { token: tokens.primary });
  requireResponse(audit, { status: 200 });
  const events = audit.body?.events ?? [];
  const linkEvents = events.filter((event) => event?.eventType === 'family.child_device_linked' && event.subjectId === linkedDevice.id);
  const telemetryEvents = events.filter((event) => event?.eventType === 'family.device_telemetry_received' && event.subjectId === linkedDevice.id);
  if (linkEvents.length !== 1 || linkEvents[0]?.correlationId !== linkCorrelationId || telemetryEvents.length !== 1 || telemetryEvents[0]?.correlationId !== telemetryCorrelationId) {
    throw new Error('Expected exactly one correlated audit event for linking and telemetry ingestion.');
  }

  return {
    checks: [
      'primary_guardian_device_link_allowed',
      'device_link_idempotency_replay_and_conflict_protected',
      'latest_battery_and_location_telemetry_persisted',
      'primary_and_co_guardian_device_read_allowed',
      'co_guardian_device_telemetry_write_denied',
      'child_and_unrelated_device_read_denied',
      'device_link_and_telemetry_audit_events_correlated_once',
    ],
    auditEvidence: { familyId, deviceId: linkedDevice.id, linkCorrelationId, telemetryCorrelationId },
  };
}
