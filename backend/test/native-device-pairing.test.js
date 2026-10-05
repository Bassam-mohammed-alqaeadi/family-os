import assert from 'node:assert/strict';
import test from 'node:test';

import { createApp } from '../src/app.js';
import { MemoryFoundationStore, TestAuthVerifier } from './memory-foundation-store.js';

async function withServer(app, run) {
  const server = await new Promise((resolve) => {
    const value = app.listen(0, '127.0.0.1', () => resolve(value));
  });
  try {
    await run(`http://127.0.0.1:${server.address().port}`);
  } finally {
    await new Promise((resolve, reject) => server.close((error) => error ? reject(error) : resolve()));
  }
}

async function request(baseUrl, path, { method = 'GET', authorization, idempotencyKey, body } = {}) {
  return fetch(`${baseUrl}${path}`, {
    method,
    headers: {
      ...(authorization ? { authorization } : {}),
      ...(idempotencyKey ? { 'idempotency-key': idempotencyKey } : {}),
      ...(body === undefined ? {} : { 'content-type': 'application/json' }),
    },
    ...(body === undefined ? {} : { body: JSON.stringify(body) }),
  });
}

async function makeFamilyChild(baseUrl) {
  const familyResponse = await request(baseUrl, '/v1/families', {
    method: 'POST', authorization: 'Bearer test-primary', idempotencyKey: 'phase2-family',
    body: { displayName: 'Native pairing family' },
  });
  const family = (await familyResponse.json()).family;
  const childResponse = await request(baseUrl, `/v1/families/${family.id}/children`, {
    method: 'POST', authorization: 'Bearer test-primary', idempotencyKey: 'phase2-child',
    body: { displayName: 'Amani', ageYears: 9, avatarEmoji: '🧒', themeColor: 'teal' },
  });
  return { family, child: (await childResponse.json()).child };
}

test('one-time pairing returns a device-only credential and it can submit real-shaped telemetry without a guardian bearer token', async () => {
  const store = new MemoryFoundationStore({ now: () => new Date('2026-10-04T13:00:00.000Z') });
  const app = createApp({ store, authVerifier: new TestAuthVerifier(), readiness: () => ({ ready: true }) });
  await withServer(app, async (baseUrl) => {
    const { family, child } = await makeFamilyChild(baseUrl);
    const pairing = await request(baseUrl, `/v1/families/${family.id}/children/${child.id}/device-pairings`, {
      method: 'POST', authorization: 'Bearer test-primary', idempotencyKey: 'native-pair-one',
      body: { deviceLabel: 'Amani Android' },
    });
    assert.equal(pairing.status, 201);
    const pairingBody = await pairing.json();
    assert.match(pairingBody.pairing.pairingCode, /^[A-Za-z0-9_-]{32,128}$/);
    assert.equal(pairingBody.pairing.deviceLabel, 'Amani Android');
    // Server/test persistence retains hashes and a non-sensitive issuance
    // marker, never the raw pairing capability that was returned once.
    assert.equal(JSON.stringify([...store.devicePairings.values(), ...store.idempotency.values()]).includes(pairingBody.pairing.pairingCode), false);

    const retryIssue = await request(baseUrl, `/v1/families/${family.id}/children/${child.id}/device-pairings`, {
      method: 'POST', authorization: 'Bearer test-primary', idempotencyKey: 'native-pair-one',
      body: { deviceLabel: 'Amani Android' },
    });
    assert.equal(retryIssue.status, 409);
    assert.equal((await retryIssue.json()).error.code, 'pairing_code_not_replayable');

    const claim = await request(baseUrl, '/v1/device-pairings/claim', {
      method: 'POST', body: { pairingCode: pairingBody.pairing.pairingCode },
    });
    assert.equal(claim.status, 201);
    const claimed = await claim.json();
    assert.match(claimed.deviceCredential, /^[A-Za-z0-9_-]{32,128}$/);
    assert.equal(claimed.device.deviceLabel, 'Amani Android');

    const telemetry = await request(baseUrl, `/v1/devices/${claimed.device.id}/telemetry`, {
      method: 'POST', authorization: `Device ${claimed.deviceCredential}`,
      body: {
        batteryLevel: 62, batteryStatus: 'charging',
        locationLat: 38.8646, locationLng: -77.2749,
        locationLabel: 'GPS 38.8646, -77.2749',
      },
    });
    assert.equal(telemetry.status, 200);
    assert.equal((await telemetry.json()).device.batteryLevel, 62);

    const replay = await request(baseUrl, '/v1/device-pairings/claim', {
      method: 'POST', body: { pairingCode: pairingBody.pairing.pairingCode },
    });
    assert.equal(replay.status, 400);
    assert.equal((await replay.json()).error.code, 'pairing_not_claimable');

    const invalidCredential = await request(baseUrl, `/v1/devices/${claimed.device.id}/telemetry`, {
      method: 'POST', authorization: `Device ${'x'.repeat(32)}`,
      body: {
        batteryLevel: 62, batteryStatus: 'charging',
        locationLat: 38.8646, locationLng: -77.2749,
        locationLabel: 'GPS 38.8646, -77.2749',
      },
    });
    assert.equal(invalidCredential.status, 401);
    assert.equal((await invalidCredential.json()).error.code, 'invalid_device_credential');

    const telemetryEvent = store.audit.at(-1);
    assert.equal(telemetryEvent.eventType, 'family.device_telemetry_received');
    assert.equal(telemetryEvent.actorMembershipId, null);
  });
});

test('an unverified guardian e-mail can create a family and a child but cannot mint a pairing code (Owner C1)', async () => {
  const store = new MemoryFoundationStore({ now: () => new Date('2026-10-06T09:00:00.000Z') });
  const app = createApp({ store, authVerifier: new TestAuthVerifier(), readiness: () => ({ ready: true }) });
  await withServer(app, async (baseUrl) => {
    const familyResponse = await request(baseUrl, '/v1/families', {
      method: 'POST', authorization: 'Bearer test-primary-unverified', idempotencyKey: 'c1-family',
      body: { displayName: 'Unverified family' },
    });
    assert.equal(familyResponse.status, 201);
    const family = (await familyResponse.json()).family;
    const childResponse = await request(baseUrl, `/v1/families/${family.id}/children`, {
      method: 'POST', authorization: 'Bearer test-primary-unverified', idempotencyKey: 'c1-child',
      body: { displayName: 'Sami', ageYears: 7, avatarEmoji: '🧒', themeColor: 'sky' },
    });
    assert.equal(childResponse.status, 201);
    const child = (await childResponse.json()).child;

    const pairing = await request(baseUrl, `/v1/families/${family.id}/children/${child.id}/device-pairings`, {
      method: 'POST', authorization: 'Bearer test-primary-unverified', idempotencyKey: 'c1-pair',
      body: { deviceLabel: 'Sami phone' },
    });
    assert.equal(pairing.status, 403);
    const body = await pairing.json();
    assert.equal(body.error.code, 'email_verification_required');
    // No capability row, no audit event, nothing claimable was created.
    assert.equal(store.devicePairings.size, 0);
  });
});
