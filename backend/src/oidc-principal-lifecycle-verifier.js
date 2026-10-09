import { stagingBaseUrl } from './staging-foundation-verifier.js';

const PROBE_FAMILY_ID = '00000000-0000-4000-8000-000000000000';
const EXPECTATIONS = {
  valid_unrelated: { status: 403, errorCode: 'family_access_denied' },
  expired_or_invalid: { status: 401, errorCode: 'invalid_token' },
};

function requiredToken(value) {
  if (typeof value !== 'string' || !value.trim()) {
    throw new Error('A synthetic principal ID token is required.');
  }
  return value.trim();
}

function expectedOutcome(value) {
  if (!Object.hasOwn(EXPECTATIONS, value)) {
    throw new Error('STAGING_OIDC_EXPECTATION must be valid_unrelated or expired_or_invalid.');
  }
  return EXPECTATIONS[value];
}

async function jsonResponse(response) {
  try {
    return await response.json();
  } catch {
    return undefined;
  }
}

export async function verifyOidcPrincipalLifecycle({ baseUrl, token, expectation, fetchImpl = fetch }) {
  const origin = stagingBaseUrl(baseUrl);
  const expected = expectedOutcome(expectation);
  const response = await fetchImpl(new URL(`/v1/families/${PROBE_FAMILY_ID}`, origin), {
    redirect: 'error',
    headers: {
      Accept: 'application/json',
      Authorization: `Bearer ${requiredToken(token)}`,
    },
  });
  const body = await jsonResponse(response);
  if (response.status !== expected.status || body?.error?.code !== expected.errorCode) {
    throw new Error(`Expected HTTP ${expected.status} ${expected.errorCode}, received HTTP ${response.status} ${body?.error?.code ?? 'unknown'}.`);
  }
  return expectation === 'valid_unrelated'
    ? ['valid_synthetic_identity_verified', 'unrelated_principal_denied']
    : ['expired_or_invalid_token_denied', 'no_identity_fallback'];
}
