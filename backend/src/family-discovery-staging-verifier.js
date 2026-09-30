import { stagingBaseUrl } from './staging-foundation-verifier.js';

const FAMILY_ROLES = new Set(['primary_guardian', 'co_guardian', 'child']);

function requiredToken(value, label) {
  if (typeof value !== 'string' || !value.trim()) {
    throw new Error(`A ${label} synthetic ID token is required.`);
  }
  return value.trim();
}

async function jsonResponse(response) {
  try {
    return await response.json();
  } catch {
    return undefined;
  }
}

function hasMinimalDiscoveryShape(body) {
  return Array.isArray(body?.families)
    && body.families.length > 0
    && body.families.every((family) => (
      family
      && typeof family === 'object'
      && Object.keys(family).length === 3
      && typeof family.id === 'string'
      && typeof family.displayName === 'string'
      && FAMILY_ROLES.has(family.role)
    ));
}

async function requestDiscovery({ origin, token, path = '/v1/me/families', fetchImpl }) {
  return fetchImpl(new URL(path, origin), {
    redirect: 'error',
    headers: {
      Accept: 'application/json',
      Authorization: `Bearer ${token}`,
    },
  });
}

export async function verifyFamilyDiscoveryStaging({
  baseUrl,
  guardianToken,
  unrelatedToken,
  fetchImpl = fetch,
}) {
  const origin = stagingBaseUrl(baseUrl);
  const guardian = requiredToken(guardianToken, 'active guardian');
  const unrelated = requiredToken(unrelatedToken, 'unrelated principal');

  const guardianResponse = await requestDiscovery({ origin, token: guardian, fetchImpl });
  const guardianBody = await jsonResponse(guardianResponse);
  if (guardianResponse.status !== 200 || !hasMinimalDiscoveryShape(guardianBody)) {
    throw new Error('Active guardian discovery did not return the expected minimal non-empty family envelope.');
  }

  const queryResponse = await requestDiscovery({
    origin,
    token: guardian,
    path: '/v1/me/families?unexpected=1',
    fetchImpl,
  });
  const queryBody = await jsonResponse(queryResponse);
  if (queryResponse.status !== 400 || queryBody?.error?.code !== 'invalid_request') {
    throw new Error('Family discovery did not reject caller-supplied query input before discovery.');
  }

  const unrelatedResponse = await requestDiscovery({ origin, token: unrelated, fetchImpl });
  const unrelatedBody = await jsonResponse(unrelatedResponse);
  if (unrelatedResponse.status !== 200 || !Array.isArray(unrelatedBody?.families) || unrelatedBody.families.length !== 0) {
    throw new Error('Unrelated principal discovery was not an empty non-enumerating result.');
  }

  return [
    'active_guardian_minimal_family_discovery',
    'caller_query_input_rejected_before_discovery',
    'unrelated_principal_receives_empty_non_enumerating_result',
  ];
}
