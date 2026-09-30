import assert from 'node:assert/strict';
import test from 'node:test';
import { validatedOidcSubject } from '../src/auth/oidc-verifier.js';
import { createGuardianTransferInput, requireNoQueryParameters, requireUuid } from '../src/validation.js';

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
