import assert from 'node:assert/strict';
import test from 'node:test';
import { createApp } from '../src/app.js';
import { DisabledAuthVerifier } from '../src/auth/oidc-verifier.js';
import { UnconfiguredFoundationStore } from '../src/store/unconfigured-foundation-store.js';
import { MemoryFoundationStore, TestAuthVerifier } from './memory-foundation-store.js';

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

function request(baseUrl, path, { token, idempotencyKey, body, method = 'GET' } = {}) {
  const headers = { Accept: 'application/json' };
  if (token) headers.Authorization = `Bearer ${token}`;
  if (idempotencyKey) headers['Idempotency-Key'] = idempotencyKey;
  if (body) headers['Content-Type'] = 'application/json';
  return fetch(`${baseUrl}${path}`, { method, headers, body: body ? JSON.stringify(body) : undefined });
}

function foundationApp() {
  return createApp({
    store: new MemoryFoundationStore(),
    authVerifier: new TestAuthVerifier(),
    readiness: () => ({ ready: true, missing: [] }),
  });
}

test('unconfigured runtime is live but never claims readiness or identity capability', async () => {
  const app = createApp({
    store: new UnconfiguredFoundationStore(),
    authVerifier: new DisabledAuthVerifier(),
    readiness: () => ({ ready: false, missing: ['DATABASE_URL', 'OIDC_ISSUER'] }),
  });

  await withServer(app, async (baseUrl) => {
    const live = await request(baseUrl, '/health/live');
    assert.equal(live.status, 200);
    assert.deepEqual(await live.json(), { status: 'live' });

    const ready = await request(baseUrl, '/health/ready');
    assert.equal(ready.status, 503);
    assert.deepEqual((await ready.json()).dependencies.configuration, 'not_configured');

    const protectedResponse = await request(baseUrl, '/v1/families', {
      method: 'POST',
      token: 'anything',
      idempotencyKey: 'foundation-test-key',
      body: { displayName: 'A family' },
    });
    assert.equal(protectedResponse.status, 503);
    assert.equal((await protectedResponse.json()).error.code, 'identity_provider_not_configured');
  });
});

test('family creation is server-authenticated, tenant-scoped and idempotent', async () => {
  await withServer(foundationApp(), async (baseUrl) => {
    const unauthenticated = await request(baseUrl, '/v1/families', {
      method: 'POST',
      idempotencyKey: 'family-create-001',
      body: { displayName: 'Horizon family' },
    });
    assert.equal(unauthenticated.status, 401);

    const create = await request(baseUrl, '/v1/families', {
      method: 'POST',
      token: 'test-parent-a',
      idempotencyKey: 'family-create-001',
      body: { displayName: 'Horizon family' },
    });
    assert.equal(create.status, 201);
    const created = await create.json();
    assert.equal(created.family.displayName, 'Horizon family');
    assert.equal(created.family.members[0].role, 'primary_guardian');
    const familyId = created.family.id;

    const replay = await request(baseUrl, '/v1/families', {
      method: 'POST',
      token: 'test-parent-a',
      idempotencyKey: 'family-create-001',
      body: { displayName: 'Horizon family' },
    });
    assert.equal(replay.status, 201);
    assert.equal((await replay.json()).family.id, familyId);

    const changedReplay = await request(baseUrl, '/v1/families', {
      method: 'POST',
      token: 'test-parent-a',
      idempotencyKey: 'family-create-001',
      body: { displayName: 'Different family' },
    });
    assert.equal(changedReplay.status, 409);
    assert.equal((await changedReplay.json()).error.code, 'idempotency_key_reused');

    const crossFamilyRead = await request(baseUrl, `/v1/families/${familyId}`, { token: 'test-stranger' });
    assert.equal(crossFamilyRead.status, 403);
    assert.equal((await crossFamilyRead.json()).error.code, 'family_access_denied');
  });
});

test('only a primary guardian can create a pending membership and only its subject can accept it', async () => {
  await withServer(foundationApp(), async (baseUrl) => {
    const createFamily = await request(baseUrl, '/v1/families', {
      method: 'POST',
      token: 'test-parent-a',
      idempotencyKey: 'family-create-002',
      body: { displayName: 'North star' },
    });
    const familyId = (await createFamily.json()).family.id;

    const invitation = await request(baseUrl, `/v1/families/${familyId}/memberships`, {
      method: 'POST',
      token: 'test-parent-a',
      idempotencyKey: 'membership-create-001',
      body: { role: 'child', targetSubject: 'test-child-a' },
    });
    assert.equal(invitation.status, 201);
    const membershipId = (await invitation.json()).membership.id;

    const strangerAccept = await request(baseUrl, `/v1/families/${familyId}/memberships/${membershipId}/accept`, {
      method: 'POST',
      token: 'test-stranger',
      idempotencyKey: 'membership-accept-001',
      body: {},
    });
    assert.equal(strangerAccept.status, 403);

    const accepted = await request(baseUrl, `/v1/families/${familyId}/memberships/${membershipId}/accept`, {
      method: 'POST',
      token: 'test-child-a',
      idempotencyKey: 'membership-accept-001',
      body: {},
    });
    assert.equal(accepted.status, 200);
    assert.equal((await accepted.json()).membership.status, 'active');

    const childAudit = await request(baseUrl, `/v1/families/${familyId}/audit-events`, { token: 'test-child-a' });
    assert.equal(childAudit.status, 403);
    assert.equal((await childAudit.json()).error.code, 'audit_access_denied');
  });
});
