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

async function createFamily(baseUrl, displayName = 'Horizon family') {
  const response = await request(baseUrl, '/v1/families', {
    method: 'POST',
    token: 'test-parent-a',
    idempotencyKey: `family-${displayName.replace(/\s+/g, '-').toLowerCase()}`,
    body: { displayName },
  });
  assert.equal(response.status, 201);
  return (await response.json()).family;
}

async function invite(baseUrl, familyId, { role, targetSubject, idempotencyKey }) {
  const response = await request(baseUrl, `/v1/families/${familyId}/memberships`, {
    method: 'POST',
    token: 'test-parent-a',
    idempotencyKey,
    body: { role, targetSubject },
  });
  assert.equal(response.status, 201);
  return (await response.json()).membership;
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
    const family = await createFamily(baseUrl, 'North star');
    const membership = await invite(baseUrl, family.id, {
      role: 'child',
      targetSubject: 'test-child-a',
      idempotencyKey: 'membership-create-001',
    });

    const strangerAccept = await request(baseUrl, `/v1/families/${family.id}/memberships/${membership.id}/accept`, {
      method: 'POST',
      token: 'test-stranger',
      idempotencyKey: 'membership-accept-001',
      body: {},
    });
    assert.equal(strangerAccept.status, 403);

    const accepted = await request(baseUrl, `/v1/families/${family.id}/memberships/${membership.id}/accept`, {
      method: 'POST',
      token: 'test-child-a',
      idempotencyKey: 'membership-accept-001',
      body: {},
    });
    assert.equal(accepted.status, 200);
    assert.equal((await accepted.json()).membership.status, 'active');

    const childAudit = await request(baseUrl, `/v1/families/${family.id}/audit-events`, { token: 'test-child-a' });
    assert.equal(childAudit.status, 403);
    assert.equal((await childAudit.json()).error.code, 'audit_access_denied');
  });
});

test('primary guardian can revoke a pending invite or remove an active member without deleting evidence', async () => {
  await withServer(foundationApp(), async (baseUrl) => {
    const family = await createFamily(baseUrl, 'Continuity family');
    const pending = await invite(baseUrl, family.id, {
      role: 'child',
      targetSubject: 'test-child-a',
      idempotencyKey: 'membership-create-pending',
    });

    const revokePending = await request(baseUrl, `/v1/families/${family.id}/memberships/${pending.id}/revoke`, {
      method: 'POST',
      token: 'test-parent-a',
      idempotencyKey: 'membership-revoke-pending',
      body: { reasonCode: 'guardian_withdrew_invitation' },
    });
    assert.equal(revokePending.status, 200);
    const revokedPending = (await revokePending.json()).membership;
    assert.equal(revokedPending.status, 'revoked');
    assert.equal(revokedPending.statusReasonCode, 'guardian_withdrew_invitation');
    assert.equal(revokedPending.version, 2);

    const revokedAccept = await request(baseUrl, `/v1/families/${family.id}/memberships/${pending.id}/accept`, {
      method: 'POST',
      token: 'test-child-a',
      idempotencyKey: 'membership-accept-revoked',
      body: {},
    });
    assert.equal(revokedAccept.status, 409);
    assert.equal((await revokedAccept.json()).error.code, 'membership_not_invitable');

    const activeCandidate = await invite(baseUrl, family.id, {
      role: 'child',
      targetSubject: 'test-child-a',
      idempotencyKey: 'membership-create-active',
    });
    const accepted = await request(baseUrl, `/v1/families/${family.id}/memberships/${activeCandidate.id}/accept`, {
      method: 'POST',
      token: 'test-child-a',
      idempotencyKey: 'membership-accept-active',
      body: {},
    });
    assert.equal(accepted.status, 200);

    const removeActive = await request(baseUrl, `/v1/families/${family.id}/memberships/${activeCandidate.id}/revoke`, {
      method: 'POST',
      token: 'test-parent-a',
      idempotencyKey: 'membership-remove-active',
      body: { reasonCode: 'family_membership_removed' },
    });
    assert.equal(removeActive.status, 200);
    const removed = (await removeActive.json()).membership;
    assert.equal(removed.status, 'removed');
    assert.equal(removed.version, 3);

    const deniedRead = await request(baseUrl, `/v1/families/${family.id}`, { token: 'test-child-a' });
    assert.equal(deniedRead.status, 403);
    assert.equal((await deniedRead.json()).error.code, 'family_access_denied');
  });
});

test('guardian continuity and revocation authority cannot be bypassed', async () => {
  await withServer(foundationApp(), async (baseUrl) => {
    const family = await createFamily(baseUrl, 'Authority family');
    const coGuardian = await invite(baseUrl, family.id, {
      role: 'co_guardian',
      targetSubject: 'test-parent-b',
      idempotencyKey: 'membership-create-co-guardian',
    });
    const child = await invite(baseUrl, family.id, {
      role: 'child',
      targetSubject: 'test-child-a',
      idempotencyKey: 'membership-create-child',
    });

    const coGuardianAccept = await request(baseUrl, `/v1/families/${family.id}/memberships/${coGuardian.id}/accept`, {
      method: 'POST',
      token: 'test-parent-b',
      idempotencyKey: 'membership-accept-co-guardian',
      body: {},
    });
    assert.equal(coGuardianAccept.status, 200);

    const coGuardianRevoke = await request(baseUrl, `/v1/families/${family.id}/memberships/${child.id}/revoke`, {
      method: 'POST',
      token: 'test-parent-b',
      idempotencyKey: 'membership-revoke-by-co-guardian',
      body: { reasonCode: 'family_membership_removed' },
    });
    assert.equal(coGuardianRevoke.status, 403);

    const primaryMembershipId = family.members[0].id;
    const primaryRevoke = await request(baseUrl, `/v1/families/${family.id}/memberships/${primaryMembershipId}/revoke`, {
      method: 'POST',
      token: 'test-parent-a',
      idempotencyKey: 'membership-revoke-primary',
      body: { reasonCode: 'family_membership_removed' },
    });
    assert.equal(primaryRevoke.status, 409);
    assert.equal((await primaryRevoke.json()).error.code, 'primary_guardian_continuity_required');
  });
});

test('primary-guardian handover is a two-party continuity case, not an ordinary role edit', async () => {
  await withServer(foundationApp(), async (baseUrl) => {
    const family = await createFamily(baseUrl, 'Transfer family');
    const coGuardian = await invite(baseUrl, family.id, {
      role: 'co_guardian',
      targetSubject: 'test-parent-b',
      idempotencyKey: 'transfer-create-co-guardian',
    });
    const accepted = await request(baseUrl, `/v1/families/${family.id}/memberships/${coGuardian.id}/accept`, {
      method: 'POST',
      token: 'test-parent-b',
      idempotencyKey: 'transfer-accept-co-guardian',
      body: {},
    });
    assert.equal(accepted.status, 200);

    const requestTransfer = async (idempotencyKey) => request(baseUrl, `/v1/families/${family.id}/guardian-transfers`, {
      method: 'POST',
      token: 'test-parent-a',
      idempotencyKey,
      body: { candidateMembershipId: coGuardian.id },
    });

    const pending = await requestTransfer('guardian-transfer-request-001');
    assert.equal(pending.status, 201);
    const cancelledTransferId = (await pending.json()).transfer.id;

    const cancelled = await request(baseUrl, `/v1/families/${family.id}/guardian-transfers/${cancelledTransferId}/cancel`, {
      method: 'POST',
      token: 'test-parent-a',
      idempotencyKey: 'guardian-transfer-cancel-001',
      body: {},
    });
    assert.equal(cancelled.status, 200);
    assert.equal((await cancelled.json()).transfer.status, 'cancelled');

    const secondPending = await requestTransfer('guardian-transfer-request-002');
    assert.equal(secondPending.status, 201);
    const transfer = (await secondPending.json()).transfer;
    assert.equal(transfer.status, 'pending_acceptance');

    const strangerAccept = await request(baseUrl, `/v1/families/${family.id}/guardian-transfers/${transfer.id}/accept`, {
      method: 'POST',
      token: 'test-stranger',
      idempotencyKey: 'guardian-transfer-stranger-accept',
      body: {},
    });
    assert.equal(strangerAccept.status, 403);

    const completed = await request(baseUrl, `/v1/families/${family.id}/guardian-transfers/${transfer.id}/accept`, {
      method: 'POST',
      token: 'test-parent-b',
      idempotencyKey: 'guardian-transfer-accept-001',
      body: {},
    });
    assert.equal(completed.status, 200);
    assert.equal((await completed.json()).transfer.status, 'completed');

    const familyAfterTransfer = await request(baseUrl, `/v1/families/${family.id}`, { token: 'test-parent-b' });
    assert.equal(familyAfterTransfer.status, 200);
    const roles = (await familyAfterTransfer.json()).family.members.map((member) => member.role).sort();
    assert.deepEqual(roles, ['co_guardian', 'primary_guardian']);

    const formerPrimaryRemoval = await request(baseUrl, `/v1/families/${family.id}/memberships/${coGuardian.id}/revoke`, {
      method: 'POST',
      token: 'test-parent-a',
      idempotencyKey: 'former-primary-remove-new-primary',
      body: { reasonCode: 'family_membership_removed' },
    });
    assert.equal(formerPrimaryRemoval.status, 403);
  });
});

test('protected operations fail closed when runtime readiness is unavailable', async () => {
  const app = createApp({
    store: new UnconfiguredFoundationStore(),
    authVerifier: new TestAuthVerifier(),
    readiness: () => ({ ready: false, missing: ['DATABASE_URL'] }),
  });

  await withServer(app, async (baseUrl) => {
    const response = await request(baseUrl, '/v1/families', {
      method: 'POST',
      token: 'test-parent-a',
      idempotencyKey: 'runtime-not-ready-family',
      body: { displayName: 'Blocked family' },
    });
    assert.equal(response.status, 503);
    assert.equal((await response.json()).error.code, 'service_not_ready');
  });
});
