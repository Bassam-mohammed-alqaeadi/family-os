// PermissionSnapshot v1 contract tests.
//
// The load-bearing test in this file is the drift gate: every capability the
// server *explains* through the snapshot is bound to the real endpoint and
// probed for each family role. If enforcement and explanation ever disagree —
// a route becomes more permissive, a role check moves, a capability is renamed
// without its route — CI fails instead of the client lying to a guardian.
import assert from 'node:assert/strict';
import test from 'node:test';
import { createApp } from '../src/app.js';
import {
  PERMISSION_CAPABILITIES,
  PERMISSION_POLICY_VERSION,
  PERMISSION_SNAPSHOT_TTL_SECONDS,
} from '../src/permission-policy.js';
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
  return fetch(`${baseUrl}${path}`, {
    method,
    headers,
    body: body ? JSON.stringify(body) : undefined,
  });
}

const PRIMARY = 'test-parent-a';
const CO_GUARDIAN = 'test-co-guardian-a';
const CHILD = 'test-child-a';

function foundationApp() {
  return createApp({
    store: new MemoryFoundationStore(),
    authVerifier: new TestAuthVerifier(),
    readiness: () => ({ ready: true, missing: [] }),
  });
}

async function seedFamily(baseUrl) {
  const created = await request(baseUrl, '/v1/families', {
    method: 'POST',
    token: PRIMARY,
    idempotencyKey: 'permission-policy-family',
    body: { displayName: 'Synthetic family' },
  });
  assert.equal(created.status, 201);
  const family = (await created.json()).family;

  const children = await request(baseUrl, `/v1/families/${family.id}/children`, {
    method: 'POST',
    token: PRIMARY,
    idempotencyKey: 'permission-policy-child',
    body: {
      displayName: 'Synthetic child',
      ageYears: 8,
      avatarEmoji: '🧒',
      themeColor: 'purple',
    },
  });
  assert.equal(children.status, 201);
  const child = (await children.json()).child;

  const coGuardianMembership = await inviteAndAccept(baseUrl, family.id, {
    role: 'co_guardian',
    targetSubject: CO_GUARDIAN,
    token: CO_GUARDIAN,
    idempotencyKey: 'permission-policy-co-guardian',
  });
  await inviteAndAccept(baseUrl, family.id, {
    role: 'child',
    targetSubject: CHILD,
    token: CHILD,
    idempotencyKey: 'permission-policy-child-member',
  });

  return { family, child, coGuardianMembership };
}

async function inviteAndAccept(baseUrl, familyId, { role, targetSubject, token, idempotencyKey }) {
  const invited = await request(baseUrl, `/v1/families/${familyId}/memberships`, {
    method: 'POST',
    token: PRIMARY,
    idempotencyKey,
    body: { role, targetSubject },
  });
  assert.equal(invited.status, 201, `inviting ${role} failed`);
  const membership = (await invited.json()).membership;
  const accepted = await request(
    baseUrl,
    `/v1/families/${familyId}/memberships/${membership.id}/accept`,
    { method: 'POST', token, idempotencyKey: `${idempotencyKey}-accept` },
  );
  assert.ok(
    accepted.status === 200 || accepted.status === 201,
    `accepting ${role} failed with ${accepted.status}`,
  );
  return membership;
}

// One probe per declared capability. A probe returns the HTTP status the real
// endpoint gave this role, so "explained as allowed" can be compared with
// "actually authorized". `baseUrl` is supplied by the running test server.
function capabilityProbes(baseUrl, familyId, { childId, coGuardianMembershipId }) {
  return {
    'family.read': (token) => request(baseUrl, `/v1/families/${familyId}`, { token }),
    'family.permission_snapshot.read': (token) =>
      request(baseUrl, `/v1/families/${familyId}/permission-snapshot`, { token }),
    'family.roster.read': (token) =>
      request(baseUrl, `/v1/families/${familyId}/children`, { token }),
    'family.device.read': (token) =>
      request(baseUrl, `/v1/families/${familyId}/devices`, { token }),
    'family.audit.read': (token) =>
      request(baseUrl, `/v1/families/${familyId}/audit-events`, { token }),
    'family.ai_events.read': (token) =>
      request(baseUrl, `/v1/families/${familyId}/ai-events`, { token }),
    'family.child.create': (token) =>
      request(baseUrl, `/v1/families/${familyId}/children`, {
        method: 'POST',
        token,
        idempotencyKey: `probe-child-create-${token}`,
        body: { displayName: 'Probe child', ageYears: 8, avatarEmoji: '🧒', themeColor: 'purple' },
      }),
    'family.device.register': (token) =>
      request(baseUrl, `/v1/families/${familyId}/children/${childId}/devices`, {
        method: 'POST',
        token,
        idempotencyKey: `probe-device-register-${token}`,
        body: { deviceLabel: 'Probe device' },
      }),
    'family.device_pairing.create': (token) =>
      request(baseUrl, `/v1/families/${familyId}/children/${childId}/device-pairings`, {
        method: 'POST',
        token,
        idempotencyKey: `probe-pairing-${token}`,
        body: { deviceLabel: 'Probe device' },
      }),
    'family.membership.invite': (token) =>
      request(baseUrl, `/v1/families/${familyId}/memberships`, {
        method: 'POST',
        token,
        idempotencyKey: `probe-invite-${token}`,
        body: { role: 'child', targetSubject: `probe-subject-${token}` },
      }),
    'family.membership.revoke': (token) =>
      request(baseUrl, `/v1/families/${familyId}/memberships/${coGuardianMembershipId}/revoke`, {
        method: 'POST',
        token,
        idempotencyKey: `probe-revoke-${token}`,
        body: { reasonCode: 'probe_reason' },
      }),
    'family.guardian_transfer.create': (token) =>
      request(baseUrl, `/v1/families/${familyId}/guardian-transfers`, {
        method: 'POST',
        token,
        idempotencyKey: `probe-transfer-${token}`,
        body: { candidateMembershipId: coGuardianMembershipId },
      }),
  };
}

test('a snapshot is a versioned, expiring explanation and never grants authority', async () => {
  await withServer(foundationApp(), async (baseUrl) => {
    const { family } = await seedFamily(baseUrl);

    const response = await request(baseUrl, `/v1/families/${family.id}/permission-snapshot`, {
      token: PRIMARY,
    });
    assert.equal(response.status, 200);
    const { permissionSnapshot } = await response.json();

    assert.equal(permissionSnapshot.policyVersion, PERMISSION_POLICY_VERSION);
    assert.equal(permissionSnapshot.familyId, family.id);
    assert.equal(permissionSnapshot.role, 'primary_guardian');
    assert.equal(permissionSnapshot.freshness, 'live');

    const issuedAt = Date.parse(permissionSnapshot.issuedAt);
    const expiresAt = Date.parse(permissionSnapshot.expiresAt);
    assert.ok(Number.isFinite(issuedAt), 'issuedAt must be a timestamp');
    assert.equal(expiresAt - issuedAt, PERMISSION_SNAPSHOT_TTL_SECONDS * 1000);

    assert.deepEqual(
      permissionSnapshot.scopes.map((scope) => scope.capability),
      PERMISSION_CAPABILITIES,
    );
    assert.ok(
      permissionSnapshot.scopes.every((scope) => scope.allowed === true),
      'a primary guardian is allowed every declared capability in this release',
    );
    assert.ok(
      permissionSnapshot.scopes.every((scope) => typeof scope.reason === 'string' && scope.reason.length > 0),
      'every scope carries a reason the client can explain',
    );
  });
});

test('a non-member receives no snapshot and therefore no role explanation', async () => {
  await withServer(foundationApp(), async (baseUrl) => {
    const { family } = await seedFamily(baseUrl);

    const response = await request(baseUrl, `/v1/families/${family.id}/permission-snapshot`, {
      token: 'test-stranger-a',
    });
    assert.equal(response.status, 403);
    const body = await response.json();
    assert.equal(body.role, undefined);
    assert.equal(body.scopes, undefined);
  });
});

test('the snapshot rejects unexpected query parameters instead of silently varying', async () => {
  await withServer(foundationApp(), async (baseUrl) => {
    const { family } = await seedFamily(baseUrl);

    const response = await request(
      baseUrl,
      `/v1/families/${family.id}/permission-snapshot?role=primary_guardian`,
      { token: CHILD },
    );
    assert.equal(response.status, 400);
  });
});

// Each role is probed against a freshly seeded family: some probes legitimately
// mutate state (revoking a membership, creating a child), and a later role must
// not inherit that mutation as if it were an authorization fact.
for (const [token, expectedRole] of [
  [PRIMARY, 'primary_guardian'],
  [CO_GUARDIAN, 'co_guardian'],
  [CHILD, 'child'],
]) {
  test(`every explained capability matches the authorization really enforced for ${expectedRole}`, async () => {
    await withServer(foundationApp(), async (baseUrl) => {
      const { family, child, coGuardianMembership } = await seedFamily(baseUrl);
      const probes = capabilityProbes(baseUrl, family.id, {
        childId: child.id,
        coGuardianMembershipId: coGuardianMembership.id,
      });

      const snapshotResponse = await request(
        baseUrl,
        `/v1/families/${family.id}/permission-snapshot`,
        { token },
      );
      assert.equal(snapshotResponse.status, 200);
      const { permissionSnapshot } = await snapshotResponse.json();
      assert.equal(permissionSnapshot.role, expectedRole);

      for (const scope of permissionSnapshot.scopes) {
        const probe = probes[scope.capability];
        assert.ok(probe, `capability ${scope.capability} has no enforcement probe`);
        const response = await probe(token);
        const enforced = response.status !== 403;
        assert.equal(
          scope.allowed,
          enforced,
          `${expectedRole} + ${scope.capability}: explained allowed=${scope.allowed} but the endpoint returned ${response.status}`,
        );
      }
    });
  });
}
