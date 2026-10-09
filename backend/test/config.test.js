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

test('a Firebase-shaped synthetic test issuer remains a provider-neutral OIDC configuration', () => {
  const config = loadConfig({
    DATABASE_URL: 'postgresql://example.invalid/family_os',
    OIDC_ISSUER: 'https://securetoken.google.com/synthetic-family-os',
    OIDC_AUDIENCE: 'synthetic-family-os',
    OIDC_JWKS_URL: 'https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com',
    GUARDIAN_TRANSFER_TTL_HOURS: '1',
  });

  assert.deepEqual(configurationReadiness(config), { ready: true, missing: [] });
  assert.equal(config.oidc.issuer, 'https://securetoken.google.com/synthetic-family-os');
  assert.equal(config.guardianTransferTtlHours, 1);
});

test('OIDC issuer and JWKS endpoints fail closed unless they are credential-free HTTPS URLs', () => {
  assert.throws(
    () => loadConfig({ ...identityConfig, OIDC_ISSUER: 'http://issuer.example.com/', GUARDIAN_TRANSFER_TTL_HOURS: '72' }),
    { code: 'invalid_configuration' },
  );
  assert.throws(
    () => loadConfig({ ...identityConfig, OIDC_JWKS_URL: 'https://token@example.com/jwks.json', GUARDIAN_TRANSFER_TTL_HOURS: '72' }),
    { code: 'invalid_configuration' },
  );
});

const s3Environment = {
  FAMILY_CHAT_MEDIA_S3_BUCKET: 'family-media-bucket',
  FAMILY_CHAT_MEDIA_S3_REGION: 'eu-central-1',
  FAMILY_CHAT_MEDIA_S3_ACCESS_KEY_ID: 'AKIDEXAMPLEKEYID',
  FAMILY_CHAT_MEDIA_S3_SECRET_ACCESS_KEY: 'secret-value-that-must-not-leak-0001',
};

test('the S3 media store is absent unless its bucket is set', () => {
  assert.equal(loadConfig(identityConfig).chatMediaS3, null);
});

test('the S3 media store maps its environment and defaults its prefix', () => {
  const config = loadConfig({ ...identityConfig, ...s3Environment });
  assert.deepEqual(config.chatMediaS3, {
    bucket: 'family-media-bucket',
    region: 'eu-central-1',
    accessKeyId: 'AKIDEXAMPLEKEYID',
    secretAccessKey: 'secret-value-that-must-not-leak-0001',
    endpoint: undefined,
    sessionToken: undefined,
    prefix: 'family-chat-media',
    forcePathStyle: undefined,
  });
});

test('the S3 media store carries an endpoint, token, prefix and path-style choice when given', () => {
  const config = loadConfig({
    ...identityConfig,
    ...s3Environment,
    FAMILY_CHAT_MEDIA_S3_ENDPOINT: 'https://objects.example.com',
    FAMILY_CHAT_MEDIA_S3_SESSION_TOKEN: 'session-token',
    FAMILY_CHAT_MEDIA_S3_PREFIX: 'tenant-a',
    FAMILY_CHAT_MEDIA_S3_FORCE_PATH_STYLE: 'true',
  });
  assert.equal(config.chatMediaS3.endpoint, 'https://objects.example.com');
  assert.equal(config.chatMediaS3.sessionToken, 'session-token');
  assert.equal(config.chatMediaS3.prefix, 'tenant-a');
  assert.equal(config.chatMediaS3.forcePathStyle, true);
});

test('a partial S3 media store is refused, and its error never names a secret', () => {
  for (const missing of ['FAMILY_CHAT_MEDIA_S3_REGION', 'FAMILY_CHAT_MEDIA_S3_ACCESS_KEY_ID', 'FAMILY_CHAT_MEDIA_S3_SECRET_ACCESS_KEY']) {
    const environment = { ...identityConfig, ...s3Environment };
    delete environment[missing];
    assert.throws(
      () => loadConfig(environment),
      (error) => error.code === 'invalid_configuration' && !error.message.includes('secret-value'),
    );
  }
});

test('the S3 path-style flag accepts only true or false', () => {
  assert.throws(
    () => loadConfig({ ...identityConfig, ...s3Environment, FAMILY_CHAT_MEDIA_S3_FORCE_PATH_STYLE: 'yes' }),
    (error) => error.code === 'invalid_configuration',
  );
});

test('push is off unless both FCM settings are present, and a partial setting is refused', () => {
  assert.equal(loadConfig(identityConfig).pushFcm, null);
  assert.throws(
    () => loadConfig({ ...identityConfig, FAMILY_PUSH_FCM_PROJECT_ID: 'family-os-prod' }),
    (error) => error.code === 'invalid_configuration' && !error.message.includes('family-os-prod'),
  );
  assert.throws(
    () => loadConfig({ ...identityConfig, FAMILY_PUSH_FCM_SERVICE_ACCOUNT_JSON: '{}' }),
    (error) => error.code === 'invalid_configuration',
  );
  assert.deepEqual(
    loadConfig({
      ...identityConfig,
      FAMILY_PUSH_FCM_PROJECT_ID: 'family-os-prod',
      FAMILY_PUSH_FCM_SERVICE_ACCOUNT_JSON: '{"client_email":"x"}',
    }).pushFcm,
    { projectId: 'family-os-prod', serviceAccountJson: '{"client_email":"x"}' },
  );
});
