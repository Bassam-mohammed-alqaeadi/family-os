import assert from 'node:assert/strict';
import test from 'node:test';
import { verifyChildrenRosterStaging } from '../src/children-roster-staging-verifier.js';

function token(subject) {
  return `header.${Buffer.from(JSON.stringify({ sub: subject })).toString('base64url')}.signature`;
}

function jsonResponse(status, body, correlationId = '00000000-0000-4000-8000-000000000001') {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'content-type': 'application/json', 'x-correlation-id': correlationId },
  });
}

test('children roster staging verifier proves role boundaries, idempotency, family isolation and correlated audit truth', async () => {
  const familyA = '11111111-1111-4111-8111-111111111111';
  const familyX = '22222222-2222-4222-8222-222222222222';
  const childA = '33333333-3333-4333-8333-333333333333';
  const childX = '44444444-4444-4444-8444-444444444444';
  const correlations = {
    childCreated: '55555555-5555-4555-8555-555555555555',
  };
  const calls = [];
  const roster = new Map();
  const memberships = new Map([
    ['membership-guardian-b', { role: 'co_guardian', status: 'invited' }],
    ['membership-child-c', { role: 'child', status: 'invited' }],
  ]);
  let familyCreates = 0;
  let firstChildInput;
  let firstChildKey;

  const result = await verifyChildrenRosterStaging({
    baseUrl: 'https://family-os-staging.example.com',
    guardianAToken: token('guardian-a'),
    guardianBToken: token('guardian-b'),
    childCToken: token('child-c'),
    principalXToken: token('principal-x'),
    idFactory: (() => {
      let count = 0;
      return () => `generated-${++count}`;
    })(),
    fetchImpl: async (url, options) => {
      const path = new URL(url).pathname;
      const authorization = options.headers.Authorization;
      const body = options.body ? JSON.parse(options.body) : undefined;
      calls.push({ path, method: options.method, authorization, body, headers: options.headers });

      if (path === '/v1/families' && options.method === 'POST') {
        familyCreates += 1;
        const id = familyCreates === 1 ? familyA : familyX;
        return jsonResponse(201, { family: { id } });
      }
      if (path === `/v1/families/${familyA}/memberships` && options.method === 'POST') {
        const id = body.role === 'co_guardian' ? 'membership-guardian-b' : 'membership-child-c';
        return jsonResponse(201, { membership: { id, role: body.role, status: 'invited' } });
      }
      if (path.includes('/memberships/') && path.endsWith('/accept') && options.method === 'POST') {
        const id = path.split('/').at(-2);
        const membership = memberships.get(id);
        membership.status = 'active';
        return jsonResponse(200, { membership: { id, ...membership } });
      }
      if (path === `/v1/families/${familyA}/children` && options.method === 'POST') {
        if (authorization === `Bearer ${token('guardian-b')}` || authorization === `Bearer ${token('child-c')}`) {
          return jsonResponse(403, { error: { code: 'family_access_denied' } });
        }
        const key = options.headers['Idempotency-Key'];
        if (!firstChildInput) {
          firstChildInput = body;
          firstChildKey = key;
          roster.set(familyA, [{
            id: childA,
            ...body,
            version: 1,
            createdAt: '2026-10-02T00:00:00.000Z',
            updatedAt: '2026-10-02T00:00:00.000Z',
          }]);
          return jsonResponse(201, { child: roster.get(familyA)[0] }, correlations.childCreated);
        }
        if (key !== firstChildKey) throw new Error('Expected a replay of the original idempotency key.');
        if (JSON.stringify(body) === JSON.stringify(firstChildInput)) {
          return jsonResponse(201, { child: roster.get(familyA)[0] });
        }
        return jsonResponse(409, { error: { code: 'idempotency_key_reused' } });
      }
      if (path === `/v1/families/${familyX}/children` && options.method === 'POST') {
        const child = {
          id: childX,
          ...body,
          version: 1,
          createdAt: '2026-10-02T00:00:00.000Z',
          updatedAt: '2026-10-02T00:00:00.000Z',
        };
        roster.set(familyX, [child]);
        return jsonResponse(201, { child });
      }
      if (path === `/v1/families/${familyA}/children` && options.method === 'GET') {
        if (authorization === `Bearer ${token('child-c')}`) {
          return jsonResponse(403, { error: { code: 'children_control_centre_access_denied' } });
        }
        if (authorization === `Bearer ${token('principal-x')}`) {
          return jsonResponse(403, { error: { code: 'family_access_denied' } });
        }
        return jsonResponse(200, { children: roster.get(familyA) });
      }
      if (path === `/v1/families/${familyX}/children` && options.method === 'GET') {
        if (authorization === `Bearer ${token('guardian-a')}`) {
          return jsonResponse(403, { error: { code: 'family_access_denied' } });
        }
        return jsonResponse(200, { children: roster.get(familyX) });
      }
      if (path === `/v1/families/${familyA}/audit-events`) {
        return jsonResponse(200, {
          events: [{
            eventType: 'family.child_created',
            subjectId: childA,
            correlationId: correlations.childCreated,
          }],
        });
      }
      throw new Error(`Unexpected request ${options.method} ${path}`);
    },
  });

  assert.deepEqual(result.checks, [
    'primary_guardian_child_create_allowed',
    'idempotent_child_create_replayed_without_duplicate_audit',
    'conflicting_child_idempotency_key_denied',
    'primary_and_co_guardian_roster_read_allowed',
    'co_guardian_roster_write_denied',
    'child_parent_control_centre_denied',
    'unrelated_principal_denied',
    'family_scoped_roster_isolation_verified',
    'child_created_audit_event_correlated_once',
  ]);
  assert.deepEqual(result.auditEvidence, { familyId: familyA, correlationId: correlations.childCreated });
  assert.equal(familyCreates, 2);
  assert.equal(calls.filter((call) => call.path === `/v1/families/${familyA}/children` && call.method === 'POST').length, 5);
  assert.equal(calls.some((call) => call.authorization === `Bearer ${token('child-c')}` && call.method === 'GET'), true);
  assert.equal(calls.some((call) => call.authorization === `Bearer ${token('guardian-a')}` && call.path === `/v1/families/${familyX}/children`), true);
});

test('children roster staging verifier rejects malformed or duplicate synthetic identities before network activity', async () => {
  let requested = false;
  await assert.rejects(
    verifyChildrenRosterStaging({
      baseUrl: 'https://family-os-staging.example.com',
      guardianAToken: token('same-subject'),
      guardianBToken: token('same-subject'),
      childCToken: token('child-c'),
      principalXToken: token('principal-x'),
      fetchImpl: async () => {
        requested = true;
      },
    }),
    /four distinct synthetic principals/,
  );
  assert.equal(requested, false);
});
