import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';

const specificationPath = join(
  dirname(fileURLToPath(import.meta.url)),
  '..',
  'openapi',
  'foundation.v1.json',
);

const expectedOperations = {
  '/health/live': ['get'],
  '/health/ready': ['get'],
  '/v1/families': ['post'],
  '/v1/families/{familyId}': ['get'],
  '/v1/families/{familyId}/memberships': ['post'],
  '/v1/families/{familyId}/memberships/{membershipId}/accept': ['post'],
  '/v1/families/{familyId}/memberships/{membershipId}/revoke': ['post'],
  '/v1/families/{familyId}/guardian-transfers': ['post'],
  '/v1/families/{familyId}/guardian-transfers/{transferId}/accept': ['post'],
  '/v1/families/{familyId}/guardian-transfers/{transferId}/cancel': ['post'],
  '/v1/families/{familyId}/audit-events': ['get'],
};

test('Foundation OpenAPI contract is valid JSON and enumerates current API operations', async () => {
  const specification = JSON.parse(await readFile(specificationPath, 'utf8'));
  assert.equal(specification.openapi, '3.1.0');
  assert.deepEqual(Object.keys(specification.paths).sort(), Object.keys(expectedOperations).sort());

  for (const [path, methods] of Object.entries(expectedOperations)) {
    assert.deepEqual(Object.keys(specification.paths[path]).sort(), methods);
  }
});

test('every protected Foundation API operation declares OIDC security and mutation idempotency', async () => {
  const specification = JSON.parse(await readFile(specificationPath, 'utf8'));
  for (const [path, methods] of Object.entries(expectedOperations)) {
    if (path.startsWith('/health/')) {
      continue;
    }
    for (const method of methods) {
      const operation = specification.paths[path][method];
      assert.deepEqual(operation.security, [{ oidcBearer: [] }], `${method.toUpperCase()} ${path}`);
      if (method === 'post') {
        assert.ok(
          operation.parameters.some((parameter) => parameter.$ref === '#/components/parameters/IdempotencyKey'),
          `${method.toUpperCase()} ${path} must require Idempotency-Key`,
        );
      }
    }
  }
});
