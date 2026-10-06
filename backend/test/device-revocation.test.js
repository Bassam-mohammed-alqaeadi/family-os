// Device revocation, end to end through the real HTTP surface.
//
// The rules under test live in src/device-revocation.js and are the same code the
// production server runs. What changes here is only the data adapter: the port
// below reads and writes the in-memory foundation store instead of PostgreSQL, and
// it holds no rules of its own - no authorization rule, no already-revoked rule, no
// idempotency rule. A test that reimplemented those would prove nothing about the
// server.
//
// The PostgreSQL adapter is the other half of the same port. It is exercised in
// device-revocation-sql.test.js against a recording pool, because a statement that
// is never run is not evidence.
import assert from 'node:assert/strict';
import test from 'node:test';
import { createApp } from '../src/app.js';
import { createDeviceRevocation } from '../src/device-revocation.js';
import { HttpError } from '../src/http-error.js';
import { UnconfiguredFoundationStore } from '../src/store/unconfigured-foundation-store.js';
import { MemoryFoundationStore, TestAuthVerifier } from './memory-foundation-store.js';

const PRIMARY = 'test-primary';
const CO_GUARDIAN = 'test-co-guardian';

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

/**
 * A revocation port over the in-memory store.
 *
 * Deliberately thin: every method is one store call plus the mapping between the
 * store's camelCase objects and the database's snake_case rows, which is confined
 * to asRow().
 */
function memoryDeviceRevocationPort(store) {
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

function asRow(device) {
  return {
    ...device,
    credential_hash: device.credentialHash ?? null,
    credential_revoked_at: device.credentialRevokedAt ?? null,
  };
}

function revocationApp(store = new MemoryFoundationStore()) {
  return {
    store,
    app: createApp({
      store,
      authVerifier: new TestAuthVerifier(),
      readiness: () => ({ ready: true, missing: [] }),
      deviceRevocation: createDeviceRevocation({ port: memoryDeviceRevocationPort(store) }),
    }),
  };
}

async function makeFamilyChild(baseUrl) {
  const familyResponse = await request(baseUrl, '/v1/families', {
    method: 'POST',
    authorization: token(PRIMARY),
    idempotencyKey: 'revocation-family',
    body: { displayName: 'Revocation family' },
  });
  assert.equal(familyResponse.status, 201);
  const family = (await familyResponse.json()).family;

  const childResponse = await request(baseUrl, `/v1/families/${family.id}/children`, {
    method: 'POST',
    authorization: token(PRIMARY),
    idempotencyKey: 'revocation-child',
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
    idempotencyKey: 'revocation-pairing',
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

/** A family, a child, and one device record that no handset has claimed. */
async function seedUnpairedDevice(baseUrl) {
  const { family, child } = await makeFamilyChild(baseUrl);
  const registered = await request(baseUrl, `/v1/families/${family.id}/children/${child.id}/devices`, {
    method: 'POST',
    authorization: token(PRIMARY),
    idempotencyKey: 'revocation-register',
    body: { deviceLabel: 'Unclaimed handset' },
  });
  assert.equal(registered.status, 201);
  return { family, child, device: (await registered.json()).device };
}

function revoke(baseUrl, { familyId, childId, deviceId }, { subject = PRIMARY, key = 'revoke-1', body } = {}) {
  return request(baseUrl, `/v1/families/${familyId}/children/${childId}/devices/${deviceId}/revocation`, {
    method: 'POST',
    authorization: token(subject),
    idempotencyKey: key,
    ...(body === undefined ? {} : { body }),
  });
}

test('a primary guardian cuts a paired device off and receives its new condition', async () => {
  const { app } = revocationApp();
  await withServer(app, async (baseUrl) => {
    const { family, child, device } = await seedPairedDevice(baseUrl);

    const response = await revoke(baseUrl, { familyId: family.id, childId: child.id, deviceId: device.id });

    assert.equal(response.status, 200);
    const body = await response.json();
    assert.equal(body.device.id, device.id);
    // The response carries the derived condition, so the guardian's screen can show
    // the device as cut off without asking the server a second time.
    assert.equal(body.device.health.state, 'revoked');
    assert.equal(body.device.health.needsAttention, true);
    assert.equal(body.device.credentialState, 'revoked');
    for (const capability of body.device.capabilities) {
      assert.equal(capability.state, 'unavailable');
      assert.equal(capability.reasonCode, 'device_revoked');
    }
  });
});

test('a revoked credential actually stops the device reporting', async () => {
  const { app } = revocationApp();
  await withServer(app, async (baseUrl) => {
    const { family, child, device, deviceCredential } = await seedPairedDevice(baseUrl);
    const telemetry = {
      batteryLevel: 80,
      batteryStatus: 'charging',
      locationLat: 15.35,
      locationLng: 44.2,
      locationLabel: 'GPS 15.35, 44.2',
    };

    const before = await request(baseUrl, `/v1/devices/${device.id}/telemetry`, {
      method: 'POST',
      authorization: `Device ${deviceCredential}`,
      body: telemetry,
    });
    assert.equal(before.status, 200);

    assert.equal(
      (await revoke(baseUrl, { familyId: family.id, childId: child.id, deviceId: device.id })).status,
      200,
    );

    const after = await request(baseUrl, `/v1/devices/${device.id}/telemetry`, {
      method: 'POST',
      authorization: `Device ${deviceCredential}`,
      body: telemetry,
    });
    assert.equal(after.status, 401);
    assert.equal((await after.json()).error.code, 'invalid_device_credential');
  });
});

test('revoking twice does not rewrite who cut the device off, or when', async () => {
  const { app, store } = revocationApp();
  await withServer(app, async (baseUrl) => {
    const { family, child, device } = await seedPairedDevice(baseUrl);

    const first = await revoke(baseUrl, { familyId: family.id, childId: child.id, deviceId: device.id }, {
      body: { reasonCode: 'stolen' },
    });
    assert.equal(first.status, 200);

    const second = await revoke(baseUrl, { familyId: family.id, childId: child.id, deviceId: device.id }, {
      key: 'revoke-2',
      body: { reasonCode: 'lost' },
    });
    assert.equal(second.status, 409);
    assert.equal((await second.json()).error.code, 'device_already_revoked');

    const record = store.devices.get(device.id);
    assert.equal(record.revocationReason, 'stolen', 'the first reason is the true one');
  });
});

test('a retry with the same idempotency key replays the first answer', async () => {
  const { app, store } = revocationApp();
  await withServer(app, async (baseUrl) => {
    const { family, child, device } = await seedPairedDevice(baseUrl);

    const first = await revoke(baseUrl, { familyId: family.id, childId: child.id, deviceId: device.id });
    assert.equal(first.status, 200);

    // A dropped connection and a repeated request must not read as a conflict: the
    // guardian sent one instruction, and the same key means the same instruction.
    const replay = await revoke(baseUrl, { familyId: family.id, childId: child.id, deviceId: device.id });
    assert.equal(replay.status, 200);
    assert.deepEqual(await replay.json(), await first.json());

    const audits = store.audit.filter((entry) => entry.eventType === 'family.child_device_revoked');
    assert.equal(audits.length, 1, 'a retry must not record a second revocation');
  });
});

test('a device no handset has claimed has no credential to revoke', async () => {
  const { app, store } = revocationApp();
  await withServer(app, async (baseUrl) => {
    const { family, child, device } = await seedUnpairedDevice(baseUrl);

    const response = await revoke(baseUrl, { familyId: family.id, childId: child.id, deviceId: device.id });

    assert.equal(response.status, 409);
    assert.equal((await response.json()).error.code, 'device_not_claimed');
    assert.ok(store.devices.get(device.id).credentialRevokedAt == null);
  });
});

test('a co-guardian cannot cut a device off', async () => {
  const { app, store } = revocationApp();
  await withServer(app, async (baseUrl) => {
    const { family, child, device } = await seedPairedDevice(baseUrl);
    store.memberships.set('co-guardian-membership', {
      id: 'co-guardian-membership',
      familyId: family.id,
      targetSubject: CO_GUARDIAN,
      role: 'co_guardian',
      status: 'active',
      statusReasonCode: null,
      version: 1,
      joinedAt: null,
      statusChangedAt: new Date().toISOString(),
      createdAt: new Date().toISOString(),
    });

    const response = await revoke(baseUrl, { familyId: family.id, childId: child.id, deviceId: device.id }, {
      subject: CO_GUARDIAN,
    });

    assert.equal(response.status, 403);
    assert.equal(store.devices.get(device.id).credentialRevokedAt, null);
  });
});

test('a device cannot be revoked through a sibling child, even in the same family', async () => {
  const { app, store } = revocationApp();
  await withServer(app, async (baseUrl) => {
    const { family, child, device } = await seedPairedDevice(baseUrl);
    const sibling = await request(baseUrl, `/v1/families/${family.id}/children`, {
      method: 'POST',
      authorization: token(PRIMARY),
      idempotencyKey: 'revocation-sibling',
      body: { displayName: 'Sibling', ageYears: 7, avatarEmoji: '🦊', themeColor: 'mint' },
    });
    assert.equal(sibling.status, 201);
    const siblingId = (await sibling.json()).child.id;

    const response = await revoke(baseUrl, { familyId: family.id, childId: siblingId, deviceId: device.id });

    assert.equal(response.status, 404);
    assert.equal((await response.json()).error.code, 'device_not_found');
    assert.equal(store.devices.get(device.id).credentialRevokedAt, null);
  });
});

test('a device that is not in this family is not found rather than refused', async () => {
  const { app } = revocationApp();
  await withServer(app, async (baseUrl) => {
    const { family, child } = await makeFamilyChild(baseUrl);

    const response = await revoke(baseUrl, {
      familyId: family.id,
      childId: child.id,
      deviceId: '99999999-9999-4999-8999-999999999999',
    });

    assert.equal(response.status, 404);
    assert.equal((await response.json()).error.code, 'device_not_found');
  });
});

test('an unknown reason is refused rather than stored', async () => {
  const { app, store } = revocationApp();
  await withServer(app, async (baseUrl) => {
    const { family, child, device } = await seedPairedDevice(baseUrl);

    const response = await revoke(baseUrl, { familyId: family.id, childId: child.id, deviceId: device.id }, {
      body: { reasonCode: 'because_i_said_so' },
    });

    assert.equal(response.status, 400);
    assert.equal(store.devices.get(device.id).credentialRevokedAt, null);
  });
});

test('the reason is optional, because an urgent revocation must not be blocked by a form', async () => {
  const { app, store } = revocationApp();
  await withServer(app, async (baseUrl) => {
    const { family, child, device } = await seedPairedDevice(baseUrl);

    // No reason at all: a guardian cutting off a stolen handset should not have to
    // classify the loss before the device stops being trusted.
    const response = await revoke(baseUrl, { familyId: family.id, childId: child.id, deviceId: device.id });

    assert.equal(response.status, 200);
    assert.equal(store.devices.get(device.id).revocationReason, null);
    assert.notEqual(store.devices.get(device.id).credentialRevokedAt, null);
  });
});

test('revocation requires an idempotency key, like every other mutation', async () => {
  const { app, store } = revocationApp();
  await withServer(app, async (baseUrl) => {
    const { family, child, device } = await seedPairedDevice(baseUrl);

    const response = await request(
      baseUrl,
      `/v1/families/${family.id}/children/${child.id}/devices/${device.id}/revocation`,
      { method: 'POST', authorization: token(PRIMARY) },
    );

    assert.equal(response.status, 400);
    assert.equal(store.devices.get(device.id).credentialRevokedAt, null);
  });
});

test('the recorded fact names the device, so a timeline can show what happened', async () => {
  const { app, store } = revocationApp();
  await withServer(app, async (baseUrl) => {
    const { family, child, device } = await seedPairedDevice(baseUrl);

    assert.equal(
      (await revoke(baseUrl, { familyId: family.id, childId: child.id, deviceId: device.id })).status,
      200,
    );

    const facts = store.aiEvents.filter((event) => event.eventType === 'device.revoked');
    assert.equal(facts.length, 1);
    assert.equal(facts[0].familyId, family.id);
    assert.equal(facts[0].childId, child.id);
    assert.equal(facts[0].deviceId, device.id);
  });
});

test('revocation is refused before the database is ready, not attempted against it', async () => {
  const store = new UnconfiguredFoundationStore();
  const app = createApp({
    store,
    authVerifier: new TestAuthVerifier(),
    readiness: () => ({ ready: true, missing: [] }),
  });

  await withServer(app, async (baseUrl) => {
    const response = await revoke(baseUrl, {
      familyId: '11111111-1111-4111-8111-111111111111',
      childId: '22222222-2222-4222-8222-222222222222',
      deviceId: '33333333-3333-4333-8333-333333333333',
    });

    assert.equal(response.status, 503);
  });
});
