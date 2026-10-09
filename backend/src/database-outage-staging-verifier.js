import { stagingBaseUrl } from './staging-foundation-verifier.js';

const PROBE_FAMILY_ID = '00000000-0000-4000-8000-000000000000';

function requiredToken(value) {
  if (typeof value !== 'string' || !value.trim()) {
    throw new Error('A verified synthetic guardian token is required.');
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

function requireResponse({ response, body }, { status, state, errorCode, database }) {
  if (response.status !== status) {
    throw new Error(`Expected HTTP ${status}, received ${response.status}.`);
  }
  if (state && body?.status !== state) {
    throw new Error(`Expected service state ${state}.`);
  }
  if (errorCode && body?.error?.code !== errorCode) {
    throw new Error(`Expected API error code ${errorCode}.`);
  }
  if (database && body?.dependencies?.database !== database) {
    throw new Error(`Expected database dependency state ${database}.`);
  }
}

export async function verifyDatabaseOutageStaging({ baseUrl, guardianToken, fetchImpl = fetch }) {
  const origin = stagingBaseUrl(baseUrl);
  const token = requiredToken(guardianToken);
  const request = async (path, options = {}) => {
    const response = await fetchImpl(new URL(path, origin), {
      redirect: 'error',
      ...options,
      headers: { Accept: 'application/json', ...options.headers },
    });
    return { response, body: await jsonResponse(response) };
  };

  const live = await request('/health/live');
  requireResponse(live, { status: 200, state: 'live' });

  const ready = await request('/health/ready');
  requireResponse(ready, { status: 503, state: 'not_ready', database: 'database_unavailable' });

  const protectedRequest = await request(`/v1/families/${PROBE_FAMILY_ID}`, {
    headers: { Authorization: `Bearer ${token}` },
  });
  requireResponse(protectedRequest, { status: 503, errorCode: 'service_not_ready' });

  return [
    'liveness_remains_available',
    'readiness_reports_database_unavailable',
    'authenticated_protected_operation_fails_closed',
  ];
}
