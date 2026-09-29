import assert from 'node:assert/strict';
import test from 'node:test';
import { stagingBaseUrl, verifyStagingFoundation } from '../src/staging-foundation-verifier.js';

function jsonResponse(status, body) {
  return {
    status,
    async json() {
      return body;
    },
  };
}

test('staging verifier performs only liveness, readiness and denied-authentication probes', async () => {
  const requests = [];
  const responses = [
    jsonResponse(200, { status: 'live' }),
    jsonResponse(200, { status: 'ready' }),
    jsonResponse(401, { error: { code: 'authentication_required' } }),
    jsonResponse(401, { error: { code: 'invalid_token' } }),
  ];
  const checks = await verifyStagingFoundation({
    baseUrl: 'https://family-os-staging.example.com',
    fetchImpl: async (url, options) => {
      requests.push({ url: String(url), method: options.method ?? 'GET', headers: options.headers });
      return responses.shift();
    },
  });

  assert.deepEqual(checks, [
    'liveness',
    'readiness',
    'missing_token_denied',
    'invalid_token_denied',
  ]);
  assert.deepEqual(requests.map((request) => request.method), ['GET', 'GET', 'GET', 'GET']);
  assert.ok(requests.every((request) => request.url.startsWith('https://family-os-staging.example.com/')));
  assert.equal(requests[3].headers.Authorization, 'Bearer deliberately-invalid-staging-token');
});

test('staging verifier rejects unsafe target shapes before any network request', () => {
  assert.throws(() => stagingBaseUrl('http://family-os-staging.example.com'), /HTTPS origin/);
  assert.throws(() => stagingBaseUrl('https://user:secret@family-os-staging.example.com'), /HTTPS origin/);
  assert.throws(() => stagingBaseUrl('https://family-os-staging.example.com/api'), /HTTPS origin/);
  assert.throws(() => stagingBaseUrl('https://localhost'), /refuses localhost/);
});

test('staging verifier reports a readiness failure rather than accepting liveness as proof', async () => {
  await assert.rejects(
    verifyStagingFoundation({
      baseUrl: 'https://family-os-staging.example.com',
      fetchImpl: async (url) => {
        if (url.pathname === '/health/live') {
          return jsonResponse(200, { status: 'live' });
        }
        return jsonResponse(503, { status: 'not_ready' });
      },
    }),
    /Expected HTTP 200, received 503/,
  );
});
