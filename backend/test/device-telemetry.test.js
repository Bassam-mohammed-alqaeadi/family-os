import assert from 'node:assert/strict';
import test from 'node:test';

import { createApp } from '../src/app.js';
import { MemoryFoundationStore, TestAuthVerifier } from './memory-foundation-store.js';

function foundationApp({ store }) {
  return createApp({
    store,
    authVerifier: new TestAuthVerifier(),
    readiness: () => ({ ready: true }),
  });
}

async function withServer(app, run) {
  const server = await new Promise((resolve) => {
    const value = app.listen(0, '127.0.0.1', () => resolve(value));
  });
  try {
    await run(`http://127.0.0.1:${server.address().port}`);
  } finally {
    await new Promise((resolve, reject) => server.close((error) => (error ? reject(error) : resolve())));
  }
}

async function request(baseUrl, path, { method = 'GET', token, idempotencyKey, body } = {}) {
  return fetch(`${baseUrl}${path}`, {
    method,
    headers: {
      ...(token ? { authorization: `Bearer ${token}` } : {}),
      ...(idempotencyKey ? { 'idempotency-key': idempotencyKey } : {}),
      ...(body === undefined ? {} : { 'content-type': 'application/json' }),
    },
    ...(body === undefined ? {} : { body: JSON.stringify(body) }),
  });
}

async function createFamilyAndChild(baseUrl) {
  const familyResponse = await request(baseUrl, '/v1/families', {
    method: 'POST',
    token: 'test-primary',
    idempotencyKey: 'telemetry-family',
    body: { displayName: 'Telemetry family' },
  });
  assert.equal(familyResponse.status, 201);
  const family = (await familyResponse.json()).family;
  const childResponse = await request(baseUrl, `/v1/families/${family.id}/children`, {
    method: 'POST',
    token: 'test-primary',
    idempotencyKey: 'telemetry-child',
    body: { displayName: 'Amani', ageYears: 9, avatarEmoji: '🧒', themeColor: 'teal' },
  });
  assert.equal(childResponse.status, 201);
  return { family, child: (await childResponse.json()).child };
}

test('primary guardian can link a device, ingest current telemetry, and guardians can read it', async () => {
  const store = new MemoryFoundationStore({ now: () => new Date('2026-10-04T12:00:00.000Z') });
  await withServer(foundationApp({ store }), async (baseUrl) => {
    const { family, child } = await createFamilyAndChild(baseUrl);
    const linked = await request(baseUrl, `/v1/families/${family.id}/children/${child.id}/devices`, {
      method: 'POST',
      token: 'test-primary',
      idempotencyKey: 'telemetry-device-link',
      body: { deviceLabel: 'Developer test phone' },
    });
    assert.equal(linked.status, 201);
    const device = (await linked.json()).device;
    assert.equal(device.childId, child.id);
    assert.equal(device.batteryLevel, null);
    assert.equal(device.lastSeenAt, null);

    const telemetry = await request(baseUrl, `/v1/devices/${device.id}/telemetry`, {
      method: 'POST',
      token: 'test-primary',
      body: {
        batteryLevel: 78,
        batteryStatus: 'unplugged',
        locationLat: 38.8646,
        locationLng: -77.2749,
        locationLabel: 'Soccer Practice',
      },
    });
    assert.equal(telemetry.status, 200);
    const updated = (await telemetry.json()).device;
    assert.equal(updated.batteryLevel, 78);
    assert.equal(updated.batteryStatus, 'unplugged');
    assert.equal(updated.locationLabel, 'Soccer Practice');
    assert.equal(updated.lastSeenAt, '2026-10-04T12:00:00.000Z');

    const listed = await request(baseUrl, `/v1/families/${family.id}/devices`, { token: 'test-primary' });
    assert.equal(listed.status, 200);
    assert.deepEqual((await listed.json()).devices, [updated]);
    assert.equal(store.audit.at(-1).eventType, 'family.device_telemetry_received');
    assert.equal(store.outbox.at(-1).eventType, 'family.device_telemetry_received');
  });
});

test('device telemetry routes reject malformed input and preserve guardian-only write authority', async () => {
  const store = new MemoryFoundationStore();
  await withServer(foundationApp({ store }), async (baseUrl) => {
    const { family, child } = await createFamilyAndChild(baseUrl);
    const link = await request(baseUrl, `/v1/families/${family.id}/children/${child.id}/devices`, {
      method: 'POST',
      token: 'test-primary',
      idempotencyKey: 'device-for-denial',
      body: { deviceLabel: 'Test phone' },
    });
    const device = (await link.json()).device;

    const invalid = await request(baseUrl, `/v1/devices/${device.id}/telemetry`, {
      method: 'POST',
      token: 'test-primary',
      body: {
        batteryLevel: 101,
        batteryStatus: 'charging',
        locationLat: 38,
        locationLng: -77,
        locationLabel: 'School',
      },
    });
    assert.equal(invalid.status, 400);

    const membership = await request(baseUrl, `/v1/families/${family.id}/memberships`, {
      method: 'POST',
      token: 'test-primary',
      idempotencyKey: 'telemetry-co-guardian',
      body: { role: 'co_guardian', targetSubject: 'test-co-guardian' },
    });
    const membershipId = (await membership.json()).membership.id;
    await request(baseUrl, `/v1/families/${family.id}/memberships/${membershipId}/accept`, {
      method: 'POST',
      token: 'test-co-guardian',
      idempotencyKey: 'telemetry-co-guardian-accept',
      body: {},
    });

    const guardianRead = await request(baseUrl, `/v1/families/${family.id}/devices`, { token: 'test-co-guardian' });
    assert.equal(guardianRead.status, 200);
    const guardianWrite = await request(baseUrl, `/v1/devices/${device.id}/telemetry`, {
      method: 'POST',
      token: 'test-co-guardian',
      body: {
        batteryLevel: 78,
        batteryStatus: 'charging',
        locationLat: 38,
        locationLng: -77,
        locationLabel: 'School',
      },
    });
    assert.equal(guardianWrite.status, 403);
  });
});
