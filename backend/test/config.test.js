import assert from 'node:assert/strict';
import test from 'node:test';
import { configurationReadiness, loadConfig } from '../src/config.js';

const identityConfig = {
  DATABASE_URL: 'postgresql://example.invalid/family_os',
  OIDC_ISSUER: 'https://issuer.example.com/',
  OIDC_AUDIENCE: 'family-os-api',
  OIDC_JWKS_URL: 'https://issuer.example.com/jwks.json',
};

test('guardian transfer policy is an explicit deployment readiness requirement', () => {
  const config = loadConfig(identityConfig);
  const readiness = configurationReadiness(config);
  assert.equal(readiness.ready, false);
  assert.deepEqual(readiness.missing, ['GUARDIAN_TRANSFER_TTL_HOURS']);
});

test('guardian transfer policy accepts only a bounded deployment-owned duration', () => {
  const config = loadConfig({ ...identityConfig, GUARDIAN_TRANSFER_TTL_HOURS: '72' });
  assert.equal(config.guardianTransferTtlHours, 72);
  assert.deepEqual(configurationReadiness(config), { ready: true, missing: [] });

  assert.throws(
    () => loadConfig({ ...identityConfig, GUARDIAN_TRANSFER_TTL_HOURS: '0' }),
    { code: 'invalid_configuration' },
  );
});
