import assert from 'node:assert/strict';
import test from 'node:test';
import { validatedOidcSubject } from '../src/auth/oidc-verifier.js';
import {
  chatThreadCreateInput,
  createChildInput,
  createGuardianTransferInput,
  requireNoQueryParameters,
  requireUuid,
} from '../src/validation.js';

const VALID_UUID = '00000000-0000-4000-8000-000000000000';

test('family resource identifiers are strict UUIDs before they reach PostgreSQL', () => {
  assert.equal(requireUuid(VALID_UUID, 'familyId'), VALID_UUID);
  assert.throws(() => requireUuid('not-a-uuid', 'familyId'), {
    code: 'invalid_request',
  });
  assert.throws(
    () => createGuardianTransferInput({ candidateMembershipId: 'not-a-uuid' }),
    { code: 'invalid_request' },
  );
});

test('family discovery refuses every caller-supplied query parameter before store evaluation', () => {
  assert.doesNotThrow(() => requireNoQueryParameters({}));
  assert.throws(() => requireNoQueryParameters({ familyId: VALID_UUID }), { code: 'invalid_request' });
  assert.throws(() => requireNoQueryParameters(['familyId']), { code: 'invalid_request' });
});

test('OIDC subjects are bounded before becoming durable account identifiers', () => {
  assert.equal(validatedOidcSubject('issuer|opaque-subject'), 'issuer|opaque-subject');
  assert.throws(() => validatedOidcSubject(''), { code: 'invalid_token' });
  assert.throws(() => validatedOidcSubject('subject\u0000injection'), { code: 'invalid_token' });
  assert.throws(() => validatedOidcSubject('x'.repeat(256)), { code: 'invalid_token' });
});

test('chat room creation accepts one child identifier but never a client-selected guardian roster', () => {
  const childId = '11111111-1111-4111-8111-111111111111';
  assert.deepEqual(chatThreadCreateInput({ kind: 'family' }), {
    kind: 'family',
    title: '',
    childIds: [],
  });
  assert.deepEqual(chatThreadCreateInput({ kind: 'child', childIds: [childId] }), {
    kind: 'child',
    title: '',
    childIds: [childId],
  });
  assert.throws(
    () => chatThreadCreateInput({
      kind: 'family',
      participantMembershipIds: [childId],
    }),
    { code: 'invalid_request' },
  );
});

test('children roster request rejects fields outside its published contract', () => {
  assert.doesNotThrow(() => createChildInput({ displayName: 'Amani', ageYears: 0, avatarEmoji: '🦁', themeColor: 'purple' }));
  assert.throws(
    () => createChildInput({ displayName: 'Amani', ageYears: 0, avatarEmoji: '🦁', themeColor: 'purple', role: 'primary_guardian' }),
    { code: 'invalid_request' },
  );
  assert.throws(
    () => createChildInput({ displayName: 'Amani', ageYears: 0, avatarEmoji: 'name', themeColor: 'purple' }),
    { code: 'invalid_request' },
  );
  assert.throws(
    () => createChildInput({ displayName: 'Amani', ageYears: 0, avatarEmoji: '🦁', themeColor: 'gradient' }),
    { code: 'invalid_request' },
  );
});
