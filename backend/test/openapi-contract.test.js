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
  '/v1/me/families': ['get'],
  '/v1/families': ['post'],
  '/v1/families/{familyId}': ['get'],
  '/v1/families/{familyId}/children': ['get', 'post'],
  '/v1/families/{familyId}/devices': ['get'],
  '/v1/families/{familyId}/children/{childId}/devices': ['post'],
  '/v1/families/{familyId}/children/{childId}/device-pairings': ['post'],
  '/v1/device-pairings/claim': ['post'],
  '/v1/devices/{deviceId}': ['get'],
  '/v1/devices/{deviceId}/telemetry': ['post'],
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

test('every protected Foundation API operation declares exact authentication and mutation idempotency', async () => {
  const specification = JSON.parse(await readFile(specificationPath, 'utf8'));
  for (const [path, methods] of Object.entries(expectedOperations)) {
    if (path.startsWith('/health/') || path === '/v1/device-pairings/claim') {
      continue;
    }
    for (const method of methods) {
      const operation = specification.paths[path][method];
      const expectedSecurity = path === '/v1/devices/{deviceId}/telemetry'
        ? [{ oidcBearer: [] }, { deviceCredential: [] }]
        : path === '/v1/devices/{deviceId}'
          ? [{ deviceCredential: [] }]
          : [{ oidcBearer: [] }];
      assert.deepEqual(operation.security, expectedSecurity, `${method.toUpperCase()} ${path}`);
      assert.equal(
        operation.responses['429']?.$ref,
        '#/components/responses/RateLimited',
        `${method.toUpperCase()} ${path} must declare protected rate limiting`,
      );
      if (method === 'post' && path !== '/v1/devices/{deviceId}/telemetry') {
        assert.ok(
          operation.parameters.some((parameter) => parameter.$ref === '#/components/parameters/IdempotencyKey'),
          `${method.toUpperCase()} ${path} must require Idempotency-Key`,
        );
      }
    }
  }
});

test('family discovery contract is protected, minimal and bounded', async () => {
  const specification = JSON.parse(await readFile(specificationPath, 'utf8'));
  const operation = specification.paths['/v1/me/families'].get;
  const response = specification.components.schemas.FamilyDiscoveryResponse;
  const item = specification.components.schemas.FamilyDiscoveryItem;

  assert.deepEqual(operation.security, [{ oidcBearer: [] }]);
  assert.deepEqual(operation.parameters, undefined);
  assert.equal(response.properties.families.maxItems, 20);
  assert.deepEqual(Object.keys(item.properties).sort(), ['displayName', 'id', 'role']);
  assert.equal(operation.responses['409'].$ref, '#/components/responses/Conflict');
});

test('audit contract exposes nullable server-generated correlation evidence for new records', async () => {
  const specification = JSON.parse(await readFile(specificationPath, 'utf8'));
  const correlationId = specification.components.schemas.AuditEvent.properties.correlationId;
  assert.deepEqual(correlationId.type, ['string', 'null']);
  assert.equal(correlationId.format, 'uuid');
});

test('children roster contract is guardian-scoped, explicit about its narrow truth, and idempotent on create', async () => {
  const specification = JSON.parse(await readFile(specificationPath, 'utf8'));
  const operation = specification.paths['/v1/families/{familyId}/children'];

  assert.deepEqual(operation.get.security, [{ oidcBearer: [] }]);
  assert.match(operation.get.description, /Device, location and policy state/);
  assert.deepEqual(operation.post.security, [{ oidcBearer: [] }]);
  assert.ok(operation.post.parameters.some((parameter) => parameter.$ref === '#/components/parameters/IdempotencyKey'));
  assert.deepEqual(
    specification.components.schemas.CreateFamilyChildRequest.required,
    ['displayName', 'ageYears', 'avatarEmoji', 'themeColor'],
  );
  assert.equal(specification.components.schemas.CreateFamilyChildRequest.additionalProperties, false);
  assert.equal(specification.components.schemas.FamilyChild.properties.ageYears.minimum, 0);
  assert.equal(specification.components.schemas.FamilyChild.properties.ageYears.maximum, 25);
  assert.deepEqual(
    specification.components.schemas.CreateFamilyChildRequest.properties.themeColor.enum,
    ['purple', 'sky', 'amber', 'coral', 'mint', 'teal'],
  );
  assert.equal(specification.components.schemas.FamilyChild.properties.avatarEmoji.maxLength, 32);
});


test('device telemetry contract is guardian-scoped and distinguishes temporary ingestion from device credentials', async () => {
  const specification = JSON.parse(await readFile(specificationPath, 'utf8'));
  const register = specification.paths['/v1/families/{familyId}/children/{childId}/devices'].post;
  const ingest = specification.paths['/v1/devices/{deviceId}/telemetry'].post;
  const device = specification.components.schemas.FamilyDevice;

  assert.match(register.description, /guardian-authorized/);
  assert.match(ingest.description, /primary guardian/);
  assert.deepEqual(specification.components.schemas.DeviceTelemetryRequest.required, [
    'batteryLevel', 'batteryStatus', 'locationLat', 'locationLng', 'locationLabel',
  ]);
  assert.equal(specification.components.schemas.DeviceTelemetryRequest.additionalProperties, false);
  assert.equal(device.properties.batteryLevel.maximum, 100);
  assert.deepEqual(device.properties.batteryStatus.enum, ['charging', 'unplugged', null]);
  assert.equal(device.properties.lastSeenAt.format, 'date-time');
});


test('native child pairing contract returns only an expiring one-time capability and accepts device credentials for telemetry', async () => {
  const specification = JSON.parse(await readFile(specificationPath, 'utf8'));
  const create = specification.paths['/v1/families/{familyId}/children/{childId}/device-pairings'].post;
  const claim = specification.paths['/v1/device-pairings/claim'].post;
  const selfStatus = specification.paths['/v1/devices/{deviceId}'].get;
  const telemetry = specification.paths['/v1/devices/{deviceId}/telemetry'].post;

  assert.deepEqual(create.security, [{ oidcBearer: [] }]);
  assert.equal(claim.security, undefined);
  assert.equal(claim.parameters, undefined);
  assert.deepEqual(selfStatus.security, [{ deviceCredential: [] }]);
  assert.match(selfStatus.description, /cannot be enumerated/);
  assert.deepEqual(
    Object.keys(specification.components.schemas.PairedDeviceSelfStatus.properties).sort(),
    ['batteryLevel', 'batteryStatus', 'deviceLabel', 'id', 'lastSeenAt'],
  );
  assert.deepEqual(telemetry.security, [{ oidcBearer: [] }, { deviceCredential: [] }]);
  assert.deepEqual(specification.components.schemas.DevicePairing.required, [
    'id', 'childId', 'deviceLabel', 'pairingCode', 'expiresAt',
  ]);
  assert.deepEqual(specification.components.schemas.ClaimDevicePairingResponse.required, ['device', 'deviceCredential']);
  assert.equal(specification.components.securitySchemes.deviceCredential.name, 'Authorization');
});
