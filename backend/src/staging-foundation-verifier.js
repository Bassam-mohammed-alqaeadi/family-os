const PROBE_FAMILY_ID = '00000000-0000-4000-8000-000000000000';

export function stagingBaseUrl(value) {
  if (typeof value !== 'string' || !value.trim()) {
    throw new Error('STAGING_API_BASE_URL is required.');
  }

  const url = new URL(value.trim());
  if (url.protocol !== 'https:' || url.username || url.password || url.search || url.hash || url.pathname !== '/') {
    throw new Error('STAGING_API_BASE_URL must be a clean HTTPS origin without credentials, path, query, or fragment.');
  }
  if (['localhost', '127.0.0.1', '[::1]'].includes(url.hostname)) {
    throw new Error('The staging verifier refuses localhost targets.');
  }
  return url;
}

async function jsonResponse(response) {
  try {
    return await response.json();
  } catch {
    return undefined;
  }
}

function expected(response, body, { status, state, errorCode }) {
  if (response.status !== status) {
    throw new Error(`Expected HTTP ${status}, received ${response.status}.`);
  }
  if (state && body?.status !== state) {
    throw new Error(`Expected service state ${state}.`);
  }
  if (errorCode && body?.error?.code !== errorCode) {
    throw new Error(`Expected API error code ${errorCode}.`);
  }
}

export async function verifyStagingFoundation({ baseUrl, fetchImpl = fetch }) {
  const origin = stagingBaseUrl(baseUrl);
  const request = async (path, options = {}) => {
    const response = await fetchImpl(new URL(path, origin), {
      redirect: 'error',
      ...options,
      headers: { Accept: 'application/json', ...options.headers },
    });
    return { response, body: await jsonResponse(response) };
  };

  const checks = [];
  const live = await request('/health/live');
  expected(live.response, live.body, { status: 200, state: 'live' });
  checks.push('liveness');

  const ready = await request('/health/ready');
  expected(ready.response, ready.body, { status: 200, state: 'ready' });
  checks.push('readiness');

  const unauthenticated = await request(`/v1/families/${PROBE_FAMILY_ID}`);
  expected(unauthenticated.response, unauthenticated.body, {
    status: 401,
    errorCode: 'authentication_required',
  });
  checks.push('missing_token_denied');

  const invalidToken = await request(`/v1/families/${PROBE_FAMILY_ID}`, {
    headers: { Authorization: 'Bearer deliberately-invalid-staging-token' },
  });
  expected(invalidToken.response, invalidToken.body, { status: 401, errorCode: 'invalid_token' });
  checks.push('invalid_token_denied');

  return checks;
}
