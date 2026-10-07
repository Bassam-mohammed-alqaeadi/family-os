// The contract drift gate.
//
// Rewritten on 2026-10-06. The previous version of this file compared the OpenAPI
// specification against a list of expected operations written by hand inside the file
// itself. That test could not fail for the reason it existed: when device revocation was
// added to app.js and omitted from the contract, both hand-maintained lists agreed with
// each other and the suite stayed green. A guard protecting two lists from drifting
// apart, not the code from the contract.
//
// This version reads the routes out of the running application and compares them with the
// published document, in both directions, with nothing hand-written in between. A route
// that exists and is undeclared fails. A declared route that no longer exists also fails,
// because a contract that promises something the server does not do is the same defect
// seen from the other side.
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';
import {
  declaredRouteKeys,
  liveRouteKeys,
  toOpenApiPath,
} from '../src/route-inventory.js';

const specificationPath = join(
  dirname(fileURLToPath(import.meta.url)),
  '..',
  'openapi',
  'foundation.v1.json',
);

async function readSpecification() {
  return JSON.parse(await readFile(specificationPath, 'utf8'));
}

test('the published contract is valid OpenAPI 3.1 and declares no empty operation', async () => {
  const specification = await readSpecification();
  assert.equal(specification.openapi, '3.1.0');
  assert.ok(specification.info?.title);
  assert.ok(specification.info?.version);
  assert.ok(Object.keys(specification.paths ?? {}).length > 0);

  for (const [path, operations] of Object.entries(specification.paths)) {
    assert.ok(path.startsWith('/'), `${path} must be an absolute path`);
    for (const [method, operation] of Object.entries(operations)) {
      // A declared operation with no description is how a contract rots: the shape stays
      // and the meaning disappears.
      assert.ok(
        operation.operationId,
        `${method.toUpperCase()} ${path} must declare an operationId`,
      );
      assert.ok(
        typeof operation.summary === 'string' && operation.summary.length > 10,
        `${method.toUpperCase()} ${path} must declare a real summary`,
      );
      assert.ok(
        operation.responses && Object.keys(operation.responses).length > 0,
        `${method.toUpperCase()} ${path} must declare responses`,
      );
      // Every reference must resolve, or the contract is a document that cannot be used to
      // generate a client - which is the whole reason it exists.
      for (const reference of collectReferences(operation)) {
        assert.ok(
          resolves(specification, reference),
          `${method.toUpperCase()} ${path} references ${reference}, which does not exist`,
        );
      }
    }
  }
});

test('every declared component reference in the document resolves', async () => {
  const specification = await readSpecification();
  for (const reference of collectReferences(specification)) {
    assert.ok(resolves(specification, reference), `${reference} does not resolve`);
  }
});

test('no route exists in the application without being declared in the contract', async () => {
  const specification = await readSpecification();
  const declared = declaredRouteKeys(specification);
  const live = await liveRouteKeys();

  const undeclared = [...live].filter((key) => !declared.has(key)).sort();
  assert.deepEqual(
    undeclared,
    [],
    'These operations are registered by the server but missing from the published contract. '
      + 'Add them to openapi/foundation.v1.json in the same commit as the route.',
  );
});

test('no route is declared in the contract without existing in the application', async () => {
  const specification = await readSpecification();
  const declared = declaredRouteKeys(specification);
  const live = await liveRouteKeys();

  const phantom = [...declared].filter((key) => !live.has(key)).sort();
  assert.deepEqual(
    phantom,
    [],
    'These operations are promised by the contract but the server does not implement them. '
      + 'A contract that lies is worse than no contract.',
  );
});

test('the route inventory is read from the application, not from a list', async () => {
  const live = await liveRouteKeys();
  // The inventory is the application's own registration. If it ever became a static list,
  // this test would be the only thing standing between the drift gate and uselessness, so
  // it asserts the properties that only a real read can have.
  assert.ok(live.size >= 20, 'the application must register the foundation operations');
  assert.ok(
    live.has('POST /v1/families/{familyId}/children/{childId}/devices/{deviceId}/revocation'),
    'the revocation operation added on 2026-10-06 must be part of the inventory',
  );
  assert.ok(live.has('POST /health/live') || live.has('GET /health/live'));
});

test('the express-to-OpenAPI path translation is exact', () => {
  assert.equal(toOpenApiPath('/v1/families/:familyId'), '/v1/families/{familyId}');
  assert.equal(
    toOpenApiPath('/v1/families/:familyId/children/:childId/devices/:deviceId/revocation'),
    '/v1/families/{familyId}/children/{childId}/devices/{deviceId}/revocation',
  );
  assert.equal(toOpenApiPath('/health/live'), '/health/live');
  // A parameter-looking segment inside a literal must survive untouched.
  assert.equal(toOpenApiPath('/v1/device-pairings/claim'), '/v1/device-pairings/claim');
});

// ── the quality requirements, restored and strengthened ──
//
// These six tests were in the file this one replaces, and losing them would have been a
// real regression: the drift gate checks that the contract matches the code, while these
// check that the contract still says the things it must. The first of them used the
// hand-written list; it now derives its subject from the live inventory, so it covers every
// protected operation including ones added later.

test('every protected operation declares OIDC security, rate limiting and idempotency on mutation', async () => {
  const specification = await readSpecification();
  const live = await liveRouteKeys();

  // Public or device-authenticated by design; the exemptions are named, not inferred.
  const exempt = new Set(['/health/live', '/health/ready', '/v1/device-pairings/claim']);

  for (const key of live) {
    const [method, path] = key.split(' ');
    if (exempt.has(path)) continue;

    const operation = specification.paths[path]?.[method.toLowerCase()];
    assert.ok(operation, `${key} must be declared`);

    // Every operation that accepts the device's own credential as well as a bearer token:
    // a handset proves itself with what it was issued at pairing. The list is named rather
    // than inferred, so a new one cannot appear by accident - and each addition is a
    // decision that the route really is a device-reporting path. W4 added two: the
    // button's own press, and the false-alarm close from the handset that raised it. W5
    // added two more, and they are the same decision twice: the child's own phone reads
    // its screen-time state and reports the minutes it measured. The credential issued at
    // pairing is what proves which child it is - neither route takes a child id, because a
    // parameter a client supplies is not proof of anything.
    const deviceAuthenticated = new Set([
      '/v1/devices/{deviceId}/telemetry',
      '/v1/devices/{deviceId}/location-fixes',
      '/v1/devices/{deviceId}/sos-alerts',
      '/v1/devices/{deviceId}/sos-alerts/{alertId}/resolve',
      '/v1/devices/{deviceId}/screen-time',
      // W6 adds three, and each one is the same decision the two above record: the
      // credential issued at pairing is what proves which child is speaking. The handset
      // fetches the filter it must apply, asks for one host through its own door, and
      // testifies about its own protection plane - and none of the three carries a child
      // id, because a parameter a client supplies proves nothing.
      '/v1/devices/{deviceId}/web-filter',
      '/v1/devices/{deviceId}/web-filter/temp-allow-requests',
      '/v1/devices/{deviceId}/protection-reports',
    ]);
    const expectedSecurity = deviceAuthenticated.has(path)
      ? [{ oidcBearer: [] }, { deviceCredential: [] }]
      : [{ oidcBearer: [] }];
    assert.deepEqual(operation.security, expectedSecurity, `${key} security`);

    assert.equal(
      operation.responses['429']?.$ref,
      '#/components/responses/RateLimited',
      `${key} must declare protected rate limiting`,
    );

    if (method === 'POST' && !deviceAuthenticated.has(path)) {
      assert.ok(
        operation.parameters?.some(
          (parameter) => parameter.$ref === '#/components/parameters/IdempotencyKey',
        ),
        `${key} must require an Idempotency-Key`,
      );
    }
  }
});

test('family discovery contract is protected, minimal and bounded', async () => {
  const specification = await readSpecification();
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
  const specification = await readSpecification();
  const correlationId = specification.components.schemas.AuditEvent.properties.correlationId;
  assert.deepEqual(correlationId.type, ['string', 'null']);
  assert.equal(correlationId.format, 'uuid');
});

test('children roster contract is guardian-scoped, explicit about its narrow truth, and idempotent on create', async () => {
  const specification = await readSpecification();
  const operation = specification.paths['/v1/families/{familyId}/children'];

  assert.deepEqual(operation.get.security, [{ oidcBearer: [] }]);
  assert.match(operation.get.description, /Device, location and policy state/);
  assert.deepEqual(operation.post.security, [{ oidcBearer: [] }]);
  assert.ok(
    operation.post.parameters.some(
      (parameter) => parameter.$ref === '#/components/parameters/IdempotencyKey',
    ),
  );
  assert.deepEqual(specification.components.schemas.CreateFamilyChildRequest.required, [
    'displayName',
    'ageYears',
    'avatarEmoji',
    'themeColor',
  ]);
  assert.equal(specification.components.schemas.CreateFamilyChildRequest.additionalProperties, false);
  assert.equal(specification.components.schemas.FamilyChild.properties.ageYears.minimum, 0);
  assert.equal(specification.components.schemas.FamilyChild.properties.ageYears.maximum, 25);
  assert.deepEqual(specification.components.schemas.CreateFamilyChildRequest.properties.themeColor.enum, [
    'purple',
    'sky',
    'amber',
    'coral',
    'mint',
    'teal',
  ]);
  assert.equal(specification.components.schemas.FamilyChild.properties.avatarEmoji.maxLength, 32);
});

test('device telemetry contract is guardian-scoped and distinguishes temporary ingestion from device credentials', async () => {
  const specification = await readSpecification();
  const register = specification.paths['/v1/families/{familyId}/children/{childId}/devices'].post;
  const ingest = specification.paths['/v1/devices/{deviceId}/telemetry'].post;
  const device = specification.components.schemas.FamilyDevice;

  assert.match(register.description, /guardian-authorized/);
  assert.match(ingest.description, /primary guardian/);
  assert.deepEqual(specification.components.schemas.DeviceTelemetryRequest.required, [
    'batteryLevel',
    'batteryStatus',
    'locationLat',
    'locationLng',
    'locationLabel',
  ]);
  assert.equal(specification.components.schemas.DeviceTelemetryRequest.additionalProperties, false);
  assert.equal(device.properties.batteryLevel.maximum, 100);
  assert.deepEqual(device.properties.batteryStatus.enum, ['charging', 'unplugged', null]);
  assert.equal(device.properties.lastSeenAt.format, 'date-time');
});

test('the revocation contract declares provenance, the closed vocabulary and the refusals it can give', async () => {
  const specification = await readSpecification();
  const operation = specification.paths[
    '/v1/families/{familyId}/children/{childId}/devices/{deviceId}/revocation'
  ].post;
  const schemas = specification.components.schemas;

  // The reason is optional in the contract for the same reason it is optional in the
  // operation: an urgent revocation must not wait for a classification.
  assert.equal(operation.requestBody.required, false);
  assert.deepEqual(
    schemas.RevokeFamilyChildDeviceRequest.properties.reasonCode.enum,
    ['lost', 'stolen', 'replaced', 'no_longer_used', 'other'],
  );
  assert.equal(schemas.RevokeFamilyChildDeviceRequest.additionalProperties, false);

  // More than one refusal is possible, so 409 must be declared: already revoked, or never
  // claimed. A client cannot offer recovery for a state the contract never mentions.
  assert.equal(operation.responses['409'].$ref, '#/components/responses/Conflict');
  assert.equal(operation.responses['404'].$ref, '#/components/responses/NotFound');
  assert.equal(operation.responses['200'].content['application/json'].schema.$ref,
    '#/components/schemas/DeviceRevocationResponse');

  // The lifecycle vocabulary is closed on both sides, and the attention flag documents the
  // rule that makes a healthy device silent.
  assert.deepEqual(schemas.DeviceHealth.properties.state.enum,
    ['revoked', 'awaiting_pairing', 'never_reported', 'active', 'stale', 'offline']);
  assert.deepEqual(schemas.DeviceCapability.properties.id.enum,
    ['telemetry', 'location', 'background_service']);
  assert.deepEqual(schemas.DeviceCapability.properties.state.enum,
    ['available', 'stale', 'unavailable']);
  assert.match(schemas.DeviceHealth.properties.needsAttention.description, /revoked/);
});

// ── helpers ──

function* walk(value) {
  if (Array.isArray(value)) {
    for (const item of value) yield* walk(item);
    return;
  }
  if (value && typeof value === 'object') {
    yield value;
    for (const item of Object.values(value)) yield* walk(item);
  }
}

function collectReferences(root) {
  const found = new Set();
  for (const node of walk(root)) {
    if (typeof node.$ref === 'string') found.add(node.$ref);
  }
  return found;
}

function resolves(specification, reference) {
  if (!reference.startsWith('#/')) return true;
  let current = specification;
  for (const segment of reference.slice(2).split('/')) {
    const key = segment.replace(/~1/g, '/').replace(/~0/g, '~');
    if (current === null || typeof current !== 'object' || !(key in current)) return false;
    current = current[key];
  }
  return true;
}
