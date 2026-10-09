import assert from 'node:assert/strict';
import test from 'node:test';
import { verifyMembershipLifecycleStaging } from '../src/membership-staging-verifier.js';

function token(subject) {
  return `header.${Buffer.from(JSON.stringify({ sub: subject })).toString('base64url')}.signature`;
}

function jsonResponse(status, body, correlationId) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'content-type': 'application/json', 'x-correlation-id': correlationId },
  });
}

function membership(id, role, status) {
  return { membership: { id, role, status } };
}

test('membership staging verifier covers revocation, authority and controlled conflict behavior', async () => {
  const familyId = '11111111-1111-4111-8111-111111111111';
  const primaryId = '11111111-1111-4111-8111-111111111112';
  const guardianMembershipId = '11111111-1111-4111-8111-111111111113';
  const firstChildMembershipId = '11111111-1111-4111-8111-111111111114';
  const activeChildMembershipId = '11111111-1111-4111-8111-111111111115';
  const racedMembershipId = '11111111-1111-4111-8111-111111111116';
  const requests = [];
  const responses = [
    jsonResponse(201, { family: { id: familyId, members: [{ id: primaryId, role: 'primary_guardian', status: 'active' }] } }, '00000000-0000-4000-8000-000000000001'),
    jsonResponse(201, membership(guardianMembershipId, 'co_guardian', 'invited'), '00000000-0000-4000-8000-000000000002'),
    jsonResponse(403, { error: { code: 'membership_acceptance_denied' } }, '00000000-0000-4000-8000-000000000003'),
    jsonResponse(200, membership(guardianMembershipId, 'co_guardian', 'active'), '00000000-0000-4000-8000-000000000004'),
    jsonResponse(201, membership(firstChildMembershipId, 'child', 'invited'), '00000000-0000-4000-8000-000000000005'),
    jsonResponse(403, { error: { code: 'family_access_denied' } }, '00000000-0000-4000-8000-000000000006'),
    jsonResponse(200, membership(firstChildMembershipId, 'child', 'revoked'), '00000000-0000-4000-8000-000000000007'),
    jsonResponse(409, { error: { code: 'membership_not_invitable' } }, '00000000-0000-4000-8000-000000000008'),
    jsonResponse(201, membership(activeChildMembershipId, 'child', 'invited'), '00000000-0000-4000-8000-000000000009'),
    jsonResponse(200, membership(activeChildMembershipId, 'child', 'active'), '00000000-0000-4000-8000-000000000010'),
    jsonResponse(200, membership(activeChildMembershipId, 'child', 'removed'), '00000000-0000-4000-8000-000000000011'),
    jsonResponse(403, { error: { code: 'family_access_denied' } }, '00000000-0000-4000-8000-000000000012'),
    jsonResponse(409, { error: { code: 'primary_guardian_continuity_required' } }, '00000000-0000-4000-8000-000000000013'),
    jsonResponse(201, membership(racedMembershipId, 'child', 'invited'), '00000000-0000-4000-8000-000000000014'),
    jsonResponse(409, { error: { code: 'membership_already_exists' } }, '00000000-0000-4000-8000-000000000015'),
    jsonResponse(200, membership(racedMembershipId, 'child', 'revoked'), '00000000-0000-4000-8000-000000000016'),
  ];
  let id = 0;
  const result = await verifyMembershipLifecycleStaging({
    baseUrl: 'https://family-os-staging.example.com',
    guardianAToken: token('guardian-a-subject'),
    guardianBToken: token('guardian-b-subject'),
    childCToken: token('child-c-subject'),
    principalXToken: token('principal-x-subject'),
    idFactory: () => `id-${++id}`,
    fetchImpl: async (url, options) => {
      requests.push({ url: String(url), ...options });
      return responses.shift();
    },
  });

  assert.deepEqual(result.checks, [
    'co_guardian_invited_pending',
    'unrelated_principal_membership_acceptance_denied',
    'co_guardian_accepted_active',
    'co_guardian_privileged_membership_mutation_denied',
    'pending_child_invitation_revoked',
    'revoked_child_acceptance_denied',
    'child_accepted_active',
    'active_child_removed_and_access_denied',
    'primary_guardian_ordinary_removal_denied',
    'concurrent_conflicting_invitation_controlled',
  ]);
  assert.equal(result.familyId, familyId);
  assert.equal(result.correlationIds.length, 16);
  assert.equal(requests[2].headers.Authorization, `Bearer ${token('principal-x-subject')}`);
  assert.equal(requests[5].headers.Authorization, `Bearer ${token('guardian-b-subject')}`);
  assert.equal(requests[11].headers.Authorization, `Bearer ${token('child-c-subject')}`);
  assert.equal(requests[13].headers.Authorization, `Bearer ${token('guardian-a-subject')}`);
  assert.equal(requests[14].headers.Authorization, `Bearer ${token('guardian-a-subject')}`);
});

test('membership staging verifier refuses malformed token input before network activity', async () => {
  let requested = false;
  await assert.rejects(
    verifyMembershipLifecycleStaging({
      baseUrl: 'https://family-os-staging.example.com',
      guardianAToken: 'not-a-jwt',
      guardianBToken: token('guardian-b-subject'),
      childCToken: token('child-c-subject'),
      principalXToken: token('principal-x-subject'),
      fetchImpl: async () => {
        requested = true;
      },
    }),
    /Guardian A token is not a JWT/,
  );
  assert.equal(requested, false);
});
