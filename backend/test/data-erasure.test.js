// Safety slice 3 — the data-erasure surface, end to end through the real HTTP routes.
//
// The rules under test live in src/data-erasure.js and are the same code the production
// server runs. What changes here is only the data adapter: the port below reads and
// writes the in-memory foundation store instead of PostgreSQL, and it holds no rules of
// its own. The laws that only a real database can prove — the retention window at 90
// days under an injected clock, the foreign-key order of deletion, the guarded archival
// UPDATE against real concurrency — live in postgres-data-erasure.test.js.
import assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';
import test from 'node:test';
import { createApp } from '../src/app.js';
import { createDataErasureSurface } from '../src/data-erasure.js';
import { createDeviceRevocation } from '../src/device-revocation.js';
import { MemoryFoundationStore, TestAuthVerifier } from './memory-foundation-store.js';
import { memoryDataErasurePort } from './memory-data-erasure-port.js';
import { memoryDeviceRevocationPort } from './memory-device-revocation-port.js';

const PRIMARY = 'test-primary';
const CO_GUARDIAN = 'test-co-guardian';
const OUTSIDER = 'test-outsider';

async function withServer(app, run) {
  const server = app.listen(0, '127.0.0.1');
  await new Promise((resolve) => server.once('listening', resolve));
  const { port } = server.address();
  try {
    await run(`http://127.0.0.1:${port}`);
  } finally {
    await new Promise((resolve, reject) => server.close((error) => (error ? reject(error) : resolve())));
  }
}

function request(baseUrl, path, { method = 'GET', authorization, idempotencyKey, body } = {}) {
  const headers = { Accept: 'application/json' };
  if (authorization) headers.Authorization = authorization;
  if (idempotencyKey) headers['Idempotency-Key'] = idempotencyKey;
  if (body !== undefined) headers['Content-Type'] = 'application/json';
  return fetch(`${baseUrl}${path}`, {
    method,
    headers,
    body: body === undefined ? undefined : JSON.stringify(body),
  });
}

const token = (subject) => `Bearer ${subject}`;

function erasureApp(store = new MemoryFoundationStore()) {
  return {
    store,
    app: createApp({
      store,
      authVerifier: new TestAuthVerifier(),
      readiness: () => ({ ready: true, missing: [] }),
      dataErasure: createDataErasureSurface({ port: memoryDataErasurePort(store) }),
      deviceRevocation: createDeviceRevocation({ port: memoryDeviceRevocationPort(store) }),
    }),
  };
}

async function makeFamilyChild(baseUrl) {
  const familyResponse = await request(baseUrl, '/v1/families', {
    method: 'POST',
    authorization: token(PRIMARY),
    idempotencyKey: 'erasure-family',
    body: { displayName: 'Erasure family' },
  });
  assert.equal(familyResponse.status, 201);
  const family = (await familyResponse.json()).family;

  const childResponse = await request(baseUrl, `/v1/families/${family.id}/children`, {
    method: 'POST',
    authorization: token(PRIMARY),
    idempotencyKey: 'erasure-child',
    body: { displayName: 'Amani', ageYears: 9, avatarEmoji: '🧒', themeColor: 'teal' },
  });
  assert.equal(childResponse.status, 201);
  return { family, child: (await childResponse.json()).child };
}

/** A family, a child, and one device that really claimed a pairing. */
async function seedPairedDevice(baseUrl) {
  const { family, child } = await makeFamilyChild(baseUrl);

  const pairing = await request(baseUrl, `/v1/families/${family.id}/children/${child.id}/device-pairings`, {
    method: 'POST',
    authorization: token(PRIMARY),
    idempotencyKey: 'erasure-pairing',
    body: { deviceLabel: 'Amani Android' },
  });
  assert.equal(pairing.status, 201);
  const pairingCode = (await pairing.json()).pairing.pairingCode;

  const claim = await request(baseUrl, '/v1/device-pairings/claim', {
    method: 'POST',
    body: { pairingCode },
  });
  assert.equal(claim.status, 201);
  const claimed = await claim.json();

  return { family, child, device: claimed.device, deviceCredential: claimed.deviceCredential };
}

/** The location facts an erasure must really delete: a trail, a crossing derived from
 * it, an incident pointing at it, and the device's last-known-position snapshot. */
function seedLocationFacts(store, { familyId, childId, deviceId }) {
  const trailFix = { id: randomUUID(), familyId, childId, deviceId, recordedAt: '2026-10-01T08:00:00.000Z' };
  const evidenceFix = { id: randomUUID(), familyId, childId, deviceId, recordedAt: '2026-10-02T08:00:00.000Z' };
  store.locationFixes.push(trailFix, evidenceFix);
  store.geofenceEvents.push({ id: randomUUID(), familyId, childId, deviceId, fixId: trailFix.id });
  store.sosAlerts.push({ id: randomUUID(), familyId, childId, fixId: evidenceFix.id, status: 'resolved' });
  const device = store.devices.get(deviceId);
  device.locationLat = 15.35;
  device.locationLng = 44.2;
  device.locationLabel = 'GPS 15.35, 44.2';
  return { trailFix, evidenceFix };
}

function seedCoGuardian(store, familyId) {
  store.memberships.set('co-guardian-membership', {
    id: 'co-guardian-membership',
    familyId,
    targetSubject: CO_GUARDIAN,
    role: 'co_guardian',
    status: 'active',
    statusReasonCode: null,
    version: 1,
    joinedAt: null,
    statusChangedAt: new Date().toISOString(),
    createdAt: new Date().toISOString(),
  });
}

const erase = (baseUrl, { familyId, childId }, { subject = PRIMARY, key = 'erase-1' } = {}) =>
  request(baseUrl, `/v1/families/${familyId}/children/${childId}/data-erasure`, {
    method: 'POST',
    authorization: token(subject),
    idempotencyKey: key,
  });

const remove = (baseUrl, { familyId, childId }, { subject = PRIMARY, key = 'remove-1' } = {}) =>
  request(baseUrl, `/v1/families/${familyId}/children/${childId}`, {
    method: 'DELETE',
    authorization: token(subject),
    idempotencyKey: key,
  });

// ── The guardian's erasure demand ─────────────────────────────────────────────────────

test('the erasure demand really deletes, and answers with what it deleted', async () => {
  const { app, store } = erasureApp();
  await withServer(app, async (baseUrl) => {
    const { family, child, device } = await seedPairedDevice(baseUrl);
    seedLocationFacts(store, { familyId: family.id, childId: child.id, deviceId: device.id });

    const response = await erase(baseUrl, { familyId: family.id, childId: child.id });

    assert.equal(response.status, 200);
    const body = await response.json();
    assert.equal(body.childId, child.id);
    assert.deepEqual(body.erased, {
      locationFixes: 2,
      geofenceEvents: 1,
      deviceSnapshots: 1,
      sosFixReferences: 1,
    });
    assert.equal(store.locationFixes.length, 0);
    assert.equal(store.geofenceEvents.length, 0);
    const cleared = store.devices.get(device.id);
    assert.equal(cleared.locationLat, null);
    assert.equal(cleared.locationLng, null);
    assert.equal(cleared.locationLabel, null);
  });
});

test('the incident survives the erasure; only the measurement it pointed at is gone', async () => {
  const { app, store } = erasureApp();
  await withServer(app, async (baseUrl) => {
    const { family, child, device } = await seedPairedDevice(baseUrl);
    seedLocationFacts(store, { familyId: family.id, childId: child.id, deviceId: device.id });

    assert.equal((await erase(baseUrl, { familyId: family.id, childId: child.id })).status, 200);

    assert.equal(store.sosAlerts.length, 1, 'the emergency the family lived through is a safety record');
    assert.equal(store.sosAlerts[0].fixId, null, 'its sample is honestly gone, not secretly kept');
  });
});

test('the audit trail says deleted, never what was deleted, and is not an announcement', async () => {
  const { app, store } = erasureApp();
  await withServer(app, async (baseUrl) => {
    const { family, child, device } = await seedPairedDevice(baseUrl);
    seedLocationFacts(store, { familyId: family.id, childId: child.id, deviceId: device.id });

    assert.equal((await erase(baseUrl, { familyId: family.id, childId: child.id })).status, 200);

    const audits = store.audit.filter((entry) => entry.eventType === 'family.child_location_erased');
    assert.equal(audits.length, 1);
    assert.equal(audits[0].subjectId, child.id);
    // No coordinates, no counts, no content: an audit trail carrying the erased picture
    // would rebuild exactly what the family demanded be gone.
    assert.deepEqual(Object.keys(audits[0]).sort(), [
      'actorMembershipId',
      'correlationId',
      'eventType',
      'familyId',
      'subjectId',
      'subjectType',
    ]);
    // The erasure is a fact about data, not a family announcement: no outbox row.
    assert.equal(store.outbox.filter((entry) => entry.eventType === 'family.child_location_erased').length, 0);
  });
});

test('erasing is repeat-safe: a replay returns the first answer, a fresh demand answers zeros', async () => {
  const { app, store } = erasureApp();
  await withServer(app, async (baseUrl) => {
    const { family, child, device } = await seedPairedDevice(baseUrl);
    seedLocationFacts(store, { familyId: family.id, childId: child.id, deviceId: device.id });

    const first = await erase(baseUrl, { familyId: family.id, childId: child.id });
    assert.equal(first.status, 200);
    const firstBody = await first.json();

    const replay = await erase(baseUrl, { familyId: family.id, childId: child.id });
    assert.equal(replay.status, 200);
    assert.deepEqual(await replay.json(), firstBody, 'a dropped connection is one instruction, not two');

    const fresh = await erase(baseUrl, { familyId: family.id, childId: child.id }, { key: 'erase-2' });
    assert.equal(fresh.status, 200);
    assert.deepEqual((await fresh.json()).erased, {
      locationFixes: 0,
      geofenceEvents: 0,
      deviceSnapshots: 0,
      sosFixReferences: 0,
    }, '"it is already gone" is the truest answer to "delete it"');
  });
});

test('erasure does not stop collection: consent and pairing are withdrawal and revocation, not this', async () => {
  const { app, store } = erasureApp();
  await withServer(app, async (baseUrl) => {
    const { family, child, device, deviceCredential } = await seedPairedDevice(baseUrl);
    seedLocationFacts(store, { familyId: family.id, childId: child.id, deviceId: device.id });

    assert.equal((await erase(baseUrl, { familyId: family.id, childId: child.id })).status, 200);

    // One button must not silently do the other's job: the handset is still paired and
    // still trusted — the guardian erased what WAS collected, not the collection.
    assert.equal(store.devices.get(device.id).credentialRevokedAt, null);
    const telemetry = await request(baseUrl, `/v1/devices/${device.id}/telemetry`, {
      method: 'POST',
      authorization: `Device ${deviceCredential}`,
      body: { batteryLevel: 80, batteryStatus: 'charging', locationLat: 15.4, locationLng: 44.3, locationLabel: 'GPS 15.4, 44.3' },
    });
    assert.equal(telemetry.status, 200);
  });
});

test('a co-guardian cannot erase: the destructive act is narrower than the read', async () => {
  const { app, store } = erasureApp();
  await withServer(app, async (baseUrl) => {
    const { family, child, device } = await seedPairedDevice(baseUrl);
    seedCoGuardian(store, family.id);
    seedLocationFacts(store, { familyId: family.id, childId: child.id, deviceId: device.id });

    const response = await erase(baseUrl, { familyId: family.id, childId: child.id }, { subject: CO_GUARDIAN });

    assert.equal(response.status, 403);
    assert.equal(store.locationFixes.length, 2, 'nothing was deleted by a refused demand');
  });
});

test('a guardian of another family reaches nothing', async () => {
  const { app, store } = erasureApp();
  await withServer(app, async (baseUrl) => {
    const { family, child, device } = await seedPairedDevice(baseUrl);
    seedLocationFacts(store, { familyId: family.id, childId: child.id, deviceId: device.id });

    const response = await erase(baseUrl, { familyId: family.id, childId: child.id }, { subject: OUTSIDER });

    assert.equal(response.status, 403);
    assert.equal(store.locationFixes.length, 2);
  });
});

test('erasure of a child who was never in the family is not found, not refused', async () => {
  const { app } = erasureApp();
  await withServer(app, async (baseUrl) => {
    const { family } = await makeFamilyChild(baseUrl);

    const response = await erase(baseUrl, { familyId: family.id, childId: randomUUID() });

    assert.equal(response.status, 404);
    assert.equal((await response.json()).error.code, 'family_child_not_found');
  });
});

test('erasure requires an idempotency key, like every other mutation', async () => {
  const { app } = erasureApp();
  await withServer(app, async (baseUrl) => {
    const { family, child } = await seedPairedDevice(baseUrl);

    const response = await request(baseUrl, `/v1/families/${family.id}/children/${child.id}/data-erasure`, {
      method: 'POST',
      authorization: token(PRIMARY),
    });

    assert.equal(response.status, 400);
  });
});

// ── Removing a child from the family ──────────────────────────────────────────────────

test('removal archives with provenance, really deletes, and cuts the handset off — one act', async () => {
  const { app, store } = erasureApp();
  await withServer(app, async (baseUrl) => {
    const { family, child, device, deviceCredential } = await seedPairedDevice(baseUrl);
    seedLocationFacts(store, { familyId: family.id, childId: child.id, deviceId: device.id });

    const response = await remove(baseUrl, { familyId: family.id, childId: child.id });

    assert.equal(response.status, 200);
    const body = await response.json();
    assert.equal(body.child.id, child.id);
    assert.notEqual(body.child.archivedAt, null);
    assert.deepEqual(body.erased, {
      locationFixes: 2,
      geofenceEvents: 1,
      deviceSnapshots: 1,
      sosFixReferences: 1,
    });
    assert.equal(body.devicesRevoked, 1);
    assert.equal(body.consentsWithdrawn, 0); // the memory double keeps no consent ledger

    // The roster no longer shows the child.
    const roster = await request(baseUrl, `/v1/families/${family.id}/children`, { authorization: token(PRIMARY) });
    assert.deepEqual((await roster.json()).children, []);

    // The handset of a child who is gone cannot keep reporting.
    const telemetry = await request(baseUrl, `/v1/devices/${device.id}/telemetry`, {
      method: 'POST',
      authorization: `Device ${deviceCredential}`,
      body: { batteryLevel: 80, batteryStatus: 'charging', locationLat: 15.4, locationLng: 44.3, locationLabel: 'x' },
    });
    assert.equal(telemetry.status, 401);

    // The archival kept its provenance: who removed the child, and when.
    const archived = store.children.get(child.id);
    assert.notEqual(archived.archivedAt, null);
    assert.notEqual(archived.archivedByMembershipId, null);

    // The removal is a family event (announced); the erasure inside it is a fact (not).
    assert.equal(store.audit.filter((entry) => entry.eventType === 'family.child_archived').length, 1);
    assert.equal(store.outbox.filter((entry) => entry.eventType === 'family.child_archived').length, 1);
    assert.equal(store.audit.filter((entry) => entry.eventType === 'family.child_location_erased').length, 1);
    assert.equal(store.outbox.filter((entry) => entry.eventType === 'family.child_location_erased').length, 0);
  });
});

test('removing twice does not rewrite who removed the child, or when', async () => {
  const { app, store } = erasureApp();
  await withServer(app, async (baseUrl) => {
    const { family, child } = await seedPairedDevice(baseUrl);

    const first = await remove(baseUrl, { familyId: family.id, childId: child.id });
    assert.equal(first.status, 200);
    const firstArchivedAt = store.children.get(child.id).archivedAt;

    const second = await remove(baseUrl, { familyId: family.id, childId: child.id }, { key: 'remove-2' });
    assert.equal(second.status, 409);
    assert.equal((await second.json()).error.code, 'child_already_archived');
    assert.equal(store.children.get(child.id).archivedAt, firstArchivedAt, 'the first removal is the true one');
  });
});

test('a removal retry with the same key replays the first answer and records nothing twice', async () => {
  const { app, store } = erasureApp();
  await withServer(app, async (baseUrl) => {
    const { family, child } = await seedPairedDevice(baseUrl);

    const first = await remove(baseUrl, { familyId: family.id, childId: child.id });
    assert.equal(first.status, 200);
    const replay = await remove(baseUrl, { familyId: family.id, childId: child.id });
    assert.equal(replay.status, 200);
    assert.deepEqual(await replay.json(), await first.json());
    assert.equal(store.audit.filter((entry) => entry.eventType === 'family.child_archived').length, 1);
  });
});

test('a co-guardian cannot remove a child from the family', async () => {
  const { app, store } = erasureApp();
  await withServer(app, async (baseUrl) => {
    const { family, child } = await seedPairedDevice(baseUrl);
    seedCoGuardian(store, family.id);

    const response = await remove(baseUrl, { familyId: family.id, childId: child.id }, { subject: CO_GUARDIAN });

    assert.equal(response.status, 403);
    assert.equal(store.children.get(child.id).archivedAt, null);
  });
});

test('an archived child refuses new writes: no pairing is issued for a child who is gone', async () => {
  const { app } = erasureApp();
  await withServer(app, async (baseUrl) => {
    const { family, child } = await seedPairedDevice(baseUrl);
    assert.equal((await remove(baseUrl, { familyId: family.id, childId: child.id })).status, 200);

    const pairing = await request(baseUrl, `/v1/families/${family.id}/children/${child.id}/device-pairings`, {
      method: 'POST',
      authorization: token(PRIMARY),
      idempotencyKey: 'erasure-pairing-after-removal',
      body: { deviceLabel: 'Another handset' },
    });

    assert.equal(pairing.status, 404);
    assert.equal((await pairing.json()).error.code, 'family_child_not_found');
  });
});

test('erasure still reaches an archived child, and answers with honest zeros', async () => {
  const { app } = erasureApp();
  await withServer(app, async (baseUrl) => {
    const { family, child } = await seedPairedDevice(baseUrl);
    assert.equal((await remove(baseUrl, { familyId: family.id, childId: child.id })).status, 200);

    const response = await erase(baseUrl, { familyId: family.id, childId: child.id }, { key: 'erase-after-removal' });

    assert.equal(response.status, 200, 'a removed child is not "never existed" to their own family\'s erasure demand');
    assert.deepEqual((await response.json()).erased, {
      locationFixes: 0,
      geofenceEvents: 0,
      deviceSnapshots: 0,
      sosFixReferences: 0,
    });
  });
});
