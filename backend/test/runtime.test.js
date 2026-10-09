import assert from 'node:assert/strict';
import test from 'node:test';
import { createRuntime } from '../src/runtime.js';

async function withServer(app, run) {
  const server = app.listen(0, '127.0.0.1');
  await new Promise((resolve) => server.once('listening', resolve));
  const { port } = server.address();
  try {
    await run(`http://127.0.0.1:${port}`);
  } finally {
    await new Promise((resolve, reject) => server.close((error) => (error ? reject(error) : resolve())));
  }
}

test('invalid non-port configuration keeps liveness available and readiness fail-closed', async () => {
  const runtime = createRuntime({
    PORT: '10000',
    DATABASE_URL: 'postgresql://example.invalid/family_os',
    OIDC_ISSUER: 'http://issuer.example.com/',
    OIDC_AUDIENCE: 'family-os-api',
    OIDC_JWKS_URL: 'https://issuer.example.com/jwks.json',
    GUARDIAN_TRANSFER_TTL_HOURS: '1',
  });

  assert.equal(runtime.configurationError, 'invalid_configuration');
  await withServer(runtime.app, async (baseUrl) => {
    const live = await fetch(`${baseUrl}/health/live`);
    assert.equal(live.status, 200);
    assert.deepEqual(await live.json(), { status: 'live' });

    const ready = await fetch(`${baseUrl}/health/ready`);
    assert.equal(ready.status, 503);
    assert.deepEqual((await ready.json()).dependencies, {
      configuration: 'invalid_configuration',
      database: 'database_not_configured',
    });
  });
  await runtime.store.close();
});
