import assert from 'node:assert/strict';
import test from 'node:test';
import { verifyAuthenticatedStaging } from '../src/authenticated-staging-verifier.js';

function jsonResponse(status, body, correlationId) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'content-type': 'application/json', 'x-correlation-id': correlationId },
  });
}

test('authenticated staging verifier proves primary access, tenant isolation and idempotency without exposing tokens', async () => {
  const requests = [];
  const familyId = '11111111-1111-4111-8111-111111111111';
  const responses = [
    jsonResponse(201, {
      family: {
        id: familyId,
        members: [{ role: 'primary_guardian', status: 'active' }],
      },
    }, '11111111-1111-4111-8111-111111111112'),
    jsonResponse(200, { family: { id: familyId } }, '11111111-1111-4111-8111-111111111113'),
    jsonResponse(403, { error: { code: 'family_access_denied' } }, '11111111-1111-4111-8111-111111111114'),
    jsonResponse(201, { family: { id: familyId } }, '11111111-1111-4111-8111-111111111115'),
    jsonResponse(409, { error: { code: 'idempotency_key_reused' } }, '11111111-1111-4111-8111-111111111116'),
  ];

  const generatedIds = [
    '22222222-2222-4222-8222-222222222222',
    '33333333-3333-4333-8333-333333333333',
  ];
  const result = await verifyAuthenticatedStaging({
    baseUrl: 'https://family-os-staging.example.com',
    guardianAToken: 'guardian-a-token',
    principalXToken: 'principal-x-token',
    idFactory: () => generatedIds.shift(),
    fetchImpl: async (url, options) => {
      requests.push({ url: String(url), ...options });
      return responses.shift();
    },
  });

  assert.deepEqual(result.checks, [
    'guardian_a_authenticated',
    'family_created_with_one_primary_guardian',
    'primary_guardian_read_allowed',
    'unrelated_principal_denied',
    'idempotent_replay_preserved',
    'conflicting_idempotency_key_denied',
  ]);
  assert.equal(result.familyId, familyId);
  assert.equal(result.correlationIds.length, 5);
  assert.deepEqual(requests.map((request) => request.method), ['POST', 'GET', 'GET', 'POST', 'POST']);
  assert.equal(requests[0].headers.Authorization, 'Bearer guardian-a-token');
  assert.equal(requests[2].headers.Authorization, 'Bearer principal-x-token');
  assert.equal(requests[0].headers['Idempotency-Key'], requests[3].headers['Idempotency-Key']);
  assert.equal(requests[0].headers['Idempotency-Key'], requests[4].headers['Idempotency-Key']);
  assert.equal(JSON.parse(requests[0].body).displayName, JSON.parse(requests[3].body).displayName);
  assert.notEqual(JSON.parse(requests[0].body).displayName, JSON.parse(requests[4].body).displayName);
});

test('authenticated staging verifier refuses blank identities before sending requests', async () => {
  let requested = false;
  await assert.rejects(
    verifyAuthenticatedStaging({
      baseUrl: 'https://family-os-staging.example.com',
      guardianAToken: '',
      principalXToken: 'principal-x-token',
      fetchImpl: async () => {
        requested = true;
      },
    }),
    /Guardian A token is required/,
  );
  assert.equal(requested, false);
});
