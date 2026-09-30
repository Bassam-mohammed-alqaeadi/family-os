import assert from 'node:assert/strict';
import test from 'node:test';
import { verifyDatabaseOutageStaging } from '../src/database-outage-staging-verifier.js';

function jsonResponse(status, body) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'content-type': 'application/json' },
  });
}

test('database outage verifier requires live truth, unavailable readiness and protected-operation fail-closed behavior', async () => {
  const requests = [];
  const responses = [
    jsonResponse(200, { status: 'live' }),
    jsonResponse(503, { status: 'not_ready', dependencies: { configuration: 'ready', database: 'database_unavailable' } }),
    jsonResponse(503, { error: { code: 'service_not_ready' } }),
  ];

  const checks = await verifyDatabaseOutageStaging({
    baseUrl: 'https://family-os-staging.example.com',
    guardianToken: 'fresh-synthetic-guardian-token',
    fetchImpl: async (url, options) => {
      requests.push({ url: String(url), options });
      return responses.shift();
    },
  });

  assert.deepEqual(checks, [
    'liveness_remains_available',
    'readiness_reports_database_unavailable',
    'authenticated_protected_operation_fails_closed',
  ]);
  assert.equal(requests.length, 3);
  assert.equal(requests[2].options.headers.Authorization, 'Bearer fresh-synthetic-guardian-token');
});

test('database outage verifier does not accept readiness false-positive', async () => {
  await assert.rejects(
    verifyDatabaseOutageStaging({
      baseUrl: 'https://family-os-staging.example.com',
      guardianToken: 'fresh-synthetic-guardian-token',
      fetchImpl: async (url) => {
        if (url.pathname === '/health/live') {
          return jsonResponse(200, { status: 'live' });
        }
        return jsonResponse(200, { status: 'ready' });
      },
    }),
    /Expected HTTP 503, received 200/,
  );
});
