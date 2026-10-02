import assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';
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

function request(baseUrl, path, { token, idempotencyKey, requestId, correlationId, body, method = 'GET' } = {}) {
  const headers = { Accept: 'application/json' };
  if (token) headers.Authorization = `Bearer ${token}`;
  if (idempotencyKey) headers['Idempotency-Key'] = idempotencyKey;
  if (requestId) headers['X-Request-Id'] = requestId;
  if (correlationId) headers['X-Correlation-Id'] = correlationId;
  if (body) headers['Content-Type'] = 'application/json';
  return fetch(`${baseUrl}${path}`, { method, headers, body: body ? JSON.stringify(body) : undefined });
}

function foundationApp({ store = new MemoryFoundationStore(), readiness = () => ({ ready: true, missing: [] }) } = {}) {
  return createApp({
    store,
    authVerifier: new TestAuthVerifier(),
    readiness,
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

test('family discovery derives only active families from the verified principal without read-side evidence writes', async () => {
  const store = new MemoryFoundationStore();
  await withServer(foundationApp({ store }), async (baseUrl) => {
    const firstFamily = await createFamily(baseUrl, 'Discovery alpha');
    const secondFamily = await createFamily(baseUrl, 'Discovery beta');
    const invitation = await invite(baseUrl, firstFamily.id, {
      role: 'child',
      targetSubject: 'test-child-a',
      idempotencyKey: 'discovery-child-invite',
    });
    const accepted = await request(baseUrl, `/v1/families/${firstFamily.id}/memberships/${invitation.id}/accept`, {
      method: 'POST',
      token: 'test-child-a',
      idempotencyKey: 'discovery-child-accept',
      body: {},
    });
    assert.equal(accepted.status, 200);

    const evidenceCountBeforeRead = { audit: store.audit.length, outbox: store.outbox.length };
    const parentDiscovery = await request(baseUrl, '/v1/me/families', { token: 'test-parent-a' });
    assert.equal(parentDiscovery.status, 200);
    const parentBody = await parentDiscovery.json();
    assert.deepEqual(parentBody.families.map((family) => family.id).sort(), [firstFamily.id, secondFamily.id].sort());
    assert.deepEqual(Object.keys(parentBody.families[0]).sort(), ['displayName', 'id', 'role']);
    assert.equal(parentBody.families.every((family) => family.role === 'primary_guardian'), true);
    assert.deepEqual({ audit: store.audit.length, outbox: store.outbox.length }, evidenceCountBeforeRead);

    const childDiscovery = await request(baseUrl, '/v1/me/families', { token: 'test-child-a' });
    assert.equal(childDiscovery.status, 200);
    assert.deepEqual((await childDiscovery.json()).families, [{
      id: firstFamily.id,
      displayName: firstFamily.displayName,
      role: 'child',
    }]);

    const unrelatedDiscovery = await request(baseUrl, '/v1/me/families', { token: 'test-stranger' });
    assert.equal(unrelatedDiscovery.status, 200);
    assert.deepEqual(await unrelatedDiscovery.json(), { families: [] });

    store.families.get(secondFamily.id).status = 'suspended';
    const activeOnly = await request(baseUrl, '/v1/me/families', { token: 'test-parent-a' });
    assert.equal(activeOnly.status, 200);
    assert.deepEqual((await activeOnly.json()).families, [{
      id: firstFamily.id,
      displayName: firstFamily.displayName,
      role: 'primary_guardian',
    }]);
  });
});

test('family discovery rejects query input and fails closed for missing identity or unavailable runtime', async () => {
  await withServer(foundationApp(), async (baseUrl) => {
    const missingIdentity = await request(baseUrl, '/v1/me/families');
    assert.equal(missingIdentity.status, 401);

    const queryInput = await request(baseUrl, '/v1/me/families?familyId=not-accepted', { token: 'test-parent-a' });
    assert.equal(queryInput.status, 400);
    assert.equal((await queryInput.json()).error.code, 'invalid_request');
  });

  await withServer(foundationApp({ readiness: () => ({ ready: false, missing: ['OIDC_ISSUER'] }) }), async (baseUrl) => {
    const unavailable = await request(baseUrl, '/v1/me/families', { token: 'test-parent-a' });
    assert.equal(unavailable.status, 503);
    assert.equal((await unavailable.json()).error.code, 'service_not_ready');
  });
});

test('family discovery rejects an over-limit result without returning a partial family list', async () => {
  const store = new MemoryFoundationStore();
  for (let index = 0; index < 21; index += 1) {
    await store.createFamily({
      principal: { subject: 'test-parent-a' },
      displayName: `Bounded discovery ${index}`,
      idempotencyKey: `bounded-discovery-${index}`,
      requestHash: `hash-${index}`,
      correlationId: randomUUID(),
    });
  }

  await withServer(foundationApp({ store }), async (baseUrl) => {
    const result = await request(baseUrl, '/v1/me/families', { token: 'test-parent-a' });
    assert.equal(result.status, 409);
    assert.equal((await result.json()).error.code, 'family_discovery_limit_exceeded');
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

test('malformed resource identifiers are rejected before tenant/store evaluation', async () => {
  await withServer(foundationApp(), async (baseUrl) => {
    const response = await request(baseUrl, '/v1/families/not-a-uuid', { token: 'test-parent-a' });
    assert.equal(response.status, 400);
    assert.equal((await response.json()).error.code, 'invalid_request');
  });
});

test('Foundation API applies non-cacheable and defensive headers to health and protected responses', async () => {
  await withServer(foundationApp(), async (baseUrl) => {
    const live = await request(baseUrl, '/health/live');
    assert.equal(live.status, 200);
    assert.equal(live.headers.get('cache-control'), 'no-store');
    assert.equal(live.headers.get('x-content-type-options'), 'nosniff');
    assert.equal(live.headers.get('referrer-policy'), 'no-referrer');
    assert.equal(live.headers.get('x-frame-options'), 'DENY');
    assert.equal(live.headers.get('x-powered-by'), null);

    const denied = await request(baseUrl, '/v1/families/00000000-0000-4000-8000-000000000000');
    assert.equal(denied.status, 401);
    assert.equal(denied.headers.get('cache-control'), 'no-store');
  });
});

test('suspended families fail closed for current members and pending membership acceptance', async () => {
  const store = new MemoryFoundationStore();
  await withServer(foundationApp({ store }), async (baseUrl) => {
    const family = await createFamily(baseUrl, 'Suspended family');
    const pending = await invite(baseUrl, family.id, {
      role: 'child',
      targetSubject: 'test-child-a',
      idempotencyKey: 'suspended-family-child-invitation',
    });
    store.families.get(family.id).status = 'suspended';

    const parentRead = await request(baseUrl, `/v1/families/${family.id}`, { token: 'test-parent-a' });
    assert.equal(parentRead.status, 403);
    assert.equal((await parentRead.json()).error.code, 'family_access_denied');

    const childAcceptance = await request(baseUrl, `/v1/families/${family.id}/memberships/${pending.id}/accept`, {
      method: 'POST',
      token: 'test-child-a',
      idempotencyKey: 'suspended-family-child-acceptance',
      body: {},
    });
    assert.equal(childAcceptance.status, 409);
    assert.equal((await childAcceptance.json()).error.code, 'family_not_active');
  });
});

test('server-generated correlation evidence links a mutation to audit/outbox without trusting client IDs', async () => {
  const store = new MemoryFoundationStore();
  await withServer(foundationApp({ store }), async (baseUrl) => {
    const created = await request(baseUrl, '/v1/families', {
      method: 'POST',
      token: 'test-parent-a',
      requestId: 'client-request-12345',
      correlationId: '00000000-0000-4000-8000-000000000000',
      idempotencyKey: 'correlation-family-create',
      body: { displayName: 'Correlation family' },
    });
    assert.equal(created.status, 201);
    const correlationId = created.headers.get('x-correlation-id');
    assert.match(correlationId, /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i);
    assert.equal(created.headers.get('x-request-id'), 'client-request-12345');
    assert.notEqual(correlationId, 'client-request-12345');
    assert.notEqual(correlationId, '00000000-0000-4000-8000-000000000000');
    const familyId = (await created.json()).family.id;

    const auditResponse = await request(baseUrl, `/v1/families/${familyId}/audit-events`, { token: 'test-parent-a' });
    assert.equal(auditResponse.status, 200);
    const auditEvent = (await auditResponse.json()).events[0];
    assert.equal(auditEvent.correlationId, correlationId);
    assert.equal(store.outbox.length, 1);
    assert.equal(store.outbox[0].correlationId, correlationId);
    assert.equal(store.outbox[0].payload.auditEventId, auditEvent.id);

    const replay = await request(baseUrl, '/v1/families', {
      method: 'POST',
      token: 'test-parent-a',
      idempotencyKey: 'correlation-family-create',
      body: { displayName: 'Correlation family' },
    });
    assert.equal(replay.status, 201);
    assert.notEqual(replay.headers.get('x-correlation-id'), correlationId);
    assert.equal(store.audit.length, 1);
    assert.equal(store.outbox.length, 1);
    assert.equal(store.audit[0].correlationId, correlationId);
    assert.equal(store.outbox[0].correlationId, correlationId);
  });
});

test('children roster is server-authorized, audit-backed and never exposed to a child membership', async () => {
  const store = new MemoryFoundationStore();
  await withServer(foundationApp({ store }), async (baseUrl) => {
    const family = await createFamily(baseUrl, 'Roster family');

    const invalidChild = await request(baseUrl, `/v1/families/${family.id}/children`, {
      method: 'POST',
      token: 'test-parent-a',
      idempotencyKey: 'child-invalid-age',
      body: { displayName: 'Amani', ageYears: 26 },
    });
    assert.equal(invalidChild.status, 400);

    const create = await request(baseUrl, `/v1/families/${family.id}/children`, {
      method: 'POST',
      token: 'test-parent-a',
      idempotencyKey: 'child-create-amani',
      body: { displayName: 'Amani', ageYears: 0 },
    });
    assert.equal(create.status, 201);
    const child = (await create.json()).child;
    assert.equal(child.displayName, 'Amani');
    assert.equal(child.ageYears, 0);
    assert.equal(child.version, 1);

    const replay = await request(baseUrl, `/v1/families/${family.id}/children`, {
      method: 'POST',
      token: 'test-parent-a',
      idempotencyKey: 'child-create-amani',
      body: { displayName: 'Amani', ageYears: 0 },
    });
    assert.equal(replay.status, 201);
    assert.equal((await replay.json()).child.id, child.id);

    const changedReplay = await request(baseUrl, `/v1/families/${family.id}/children`, {
      method: 'POST',
      token: 'test-parent-a',
      idempotencyKey: 'child-create-amani',
      body: { displayName: 'Amani', ageYears: 1 },
    });
    assert.equal(changedReplay.status, 409);
    assert.equal((await changedReplay.json()).error.code, 'idempotency_key_reused');

    const roster = await request(baseUrl, `/v1/families/${family.id}/children`, { token: 'test-parent-a' });
    assert.equal(roster.status, 200);
    assert.deepEqual((await roster.json()).children.map((entry) => entry.id), [child.id]);
    assert.equal(store.audit.at(-1).eventType, 'family.child_created');
    assert.equal(store.outbox.at(-1).eventType, 'family.child_created');

    const childMembership = await invite(baseUrl, family.id, {
      role: 'child',
      targetSubject: 'test-child-a',
      idempotencyKey: 'roster-child-membership',
    });
    const accepted = await request(baseUrl, `/v1/families/${family.id}/memberships/${childMembership.id}/accept`, {
      method: 'POST',
      token: 'test-child-a',
      idempotencyKey: 'roster-child-membership-accept',
      body: {},
    });
    assert.equal(accepted.status, 200);

    const deniedRead = await request(baseUrl, `/v1/families/${family.id}/children`, { token: 'test-child-a' });
    assert.equal(deniedRead.status, 403);
    assert.equal((await deniedRead.json()).error.code, 'children_control_centre_access_denied');

    const deniedWrite = await request(baseUrl, `/v1/families/${family.id}/children`, {
      method: 'POST',
      token: 'test-child-a',
      idempotencyKey: 'roster-child-write-denied',
      body: { displayName: 'Nope', ageYears: 7 },
    });
    assert.equal(deniedWrite.status, 403);
    assert.equal((await deniedWrite.json()).error.code, 'family_access_denied');

    const queryRejected = await request(baseUrl, `/v1/families/${family.id}/children?limit=1`, { token: 'test-parent-a' });
    assert.equal(queryRejected.status, 400);
  });
});
