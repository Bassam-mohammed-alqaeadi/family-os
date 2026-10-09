import assert from 'node:assert/strict';
import test from 'node:test';
import { verifyOidcPrincipalLifecycle } from '../src/oidc-principal-lifecycle-verifier.js';

function jsonResponse(status, body) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'content-type': 'application/json' },
  });
}

test('OIDC lifecycle verifier distinguishes valid unrelated identity from expired or invalid token denial', async () => {
  const validChecks = await verifyOidcPrincipalLifecycle({
    baseUrl: 'https://family-os-staging.example.com',
    token: 'valid-synthetic-token',
    expectation: 'valid_unrelated',
    fetchImpl: async (_url, options) => {
      assert.equal(options.headers.Authorization, 'Bearer valid-synthetic-token');
      return jsonResponse(403, { error: { code: 'family_access_denied' } });
    },
  });
  assert.deepEqual(validChecks, ['valid_synthetic_identity_verified', 'unrelated_principal_denied']);

  const expiredChecks = await verifyOidcPrincipalLifecycle({
    baseUrl: 'https://family-os-staging.example.com',
    token: 'expired-synthetic-token',
    expectation: 'expired_or_invalid',
    fetchImpl: async () => jsonResponse(401, { error: { code: 'invalid_token' } }),
  });
  assert.deepEqual(expiredChecks, ['expired_or_invalid_token_denied', 'no_identity_fallback']);
});

test('OIDC lifecycle verifier rejects unknown expectations before a network request', async () => {
  let requested = false;
  await assert.rejects(
    verifyOidcPrincipalLifecycle({
      baseUrl: 'https://family-os-staging.example.com',
      token: 'unused-token',
      expectation: 'revoked_immediately',
      fetchImpl: async () => {
        requested = true;
      },
    }),
    /STAGING_OIDC_EXPECTATION/,
  );
  assert.equal(requested, false);
});
