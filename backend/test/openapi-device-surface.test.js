// The device read surface, checked against the contract it publishes.
//
// The drift gate compares the routes the server registers with the paths the OpenAPI
// document declares, which catches a route nobody documented. It cannot catch the
// opposite kind of lie: a route that exists and answers with something other than what
// its own schema promises. That gap matters most on this surface, because a guardian
// acting on a device state is acting on a safety claim.
//
// So this file boots the real app, drives the real lifecycle through it - register,
// claim, report, revoke - and validates each response against the schema the OpenAPI
// document declares for that response, resolving $refs out of the same document a client
// generator would read. It then asserts the meaning, not only the shape: a device that
// has been cut off is never answered as working, and a device that has never reported is
// never answered as if it had.
//
// The validator is deliberately small and self-contained. Adding a schema library to
// check the shape of a response would let a library bug decide whether a safety claim is
// honest, and the subset this document uses - refs, types, enums, required, arrays and
// closed objects - is small enough to read in one sitting.
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import test from 'node:test';

import { createApp } from '../src/app.js';
import { createDeviceRevocation } from '../src/device-revocation.js';
import { MemoryFoundationStore, TestAuthVerifier } from './memory-foundation-store.js';
import { memoryDeviceRevocationPort } from './memory-device-revocation-port.js';

const document = JSON.parse(readFileSync(new URL('../openapi/foundation.v1.json', import.meta.url), 'utf8'));

/** Resolve `#/components/schemas/Name` against the published document. */
function resolveRef(ref) {
  const prefix = '#/components/schemas/';
  assert.ok(ref.startsWith(prefix), `unexpected ref ${ref}`);
  const schema = document.components.schemas[ref.slice(prefix.length)];
  assert.ok(schema, `the document references ${ref} but does not define it`);
  return schema;
}

function typeMatches(value, type) {
  switch (type) {
    case 'object':
      return value !== null && typeof value === 'object' && !Array.isArray(value);
    case 'array':
      return Array.isArray(value);
    case 'integer':
      return Number.isInteger(value);
    case 'number':
      return typeof value === 'number' && Number.isFinite(value);
    case 'string':
      return typeof value === 'string';
    case 'boolean':
      return typeof value === 'boolean';
    case 'null':
      return value === null;
    default:
      throw new Error(`unsupported schema type ${type}`);
  }
}

function validate(value, schema, path = '$') {
  if (schema.$ref) {
    return validate(value, resolveRef(schema.$ref), path);
  }

  const types = Array.isArray(schema.type) ? schema.type : schema.type ? [schema.type] : null;
  if (types && !types.some((type) => typeMatches(value, type))) {
    throw new Error(`${path}: expected ${types.join('|')}, received ${JSON.stringify(value)}`);
  }
  if (value === null || typeof value !== 'object') {
    if (schema.enum && !schema.enum.includes(value)) {
      throw new Error(`${path}: ${JSON.stringify(value)} is not one of ${schema.enum.join(', ')}`);
    }
    return;
  }

  if (Array.isArray(value)) {
    if (schema.minItems != null && value.length < schema.minItems) {
      throw new Error(`${path}: expected at least ${schema.minItems} entries, saw ${value.length}`);
    }
    if (schema.items) {
      value.forEach((entry, index) => validate(entry, schema.items, `${path}[${index}]`));
    }
    return;
  }

  for (const name of schema.required ?? []) {
    if (!(name in value)) {
      throw new Error(`${path}: missing declared required property "${name}"`);
    }
  }
  if (schema.additionalProperties === false) {
    const declared = new Set(Object.keys(schema.properties ?? {}));
    const extra = Object.keys(value).filter((name) => !declared.has(name));
    // An answer carrying a field the contract does not declare is how a client ends up
    // depending on something no generator knows about.
    if (extra.length > 0) {
      throw new Error(`${path}: undeclared propert${extra.length === 1 ? 'y' : 'ies'} ${extra.join(', ')}`);
    }
  }
  for (const [name, property] of Object.entries(schema.properties ?? {})) {
    if (name in value) {
      validate(value[name], property, `${path}.${name}`);
    }
  }
}

/** Validates a response body against the schema the document declares for it. */
function assertMatchesDeclaredSchema(body, schemaName, what) {
  const schema = document.components.schemas[schemaName];
  assert.ok(schema, `the document does not declare ${schemaName}`);
  try {
    validate(body, schema);
  } catch (error) {
    assert.fail(`${what} does not match the declared ${schemaName}: ${error.message}`);
  }
}

function foundationApp({ store }) {
  return createApp({
    store,
    authVerifier: new TestAuthVerifier(),
    readiness: () => ({ ready: true }),
    // The real revocation operation over a data-only adapter, so the write half of the
    // lifecycle is the server's own code rather than a stub that agrees with the test.
    deviceRevocation: createDeviceRevocation({ port: memoryDeviceRevocationPort(store) }),
  });
}

async function withServer(app, run) {
  const server = await new Promise((resolve) => {
    const value = app.listen(0, '127.0.0.1', () => resolve(value));
  });
  try {
    await run(`http://127.0.0.1:${server.address().port}`);
  } finally {
    await new Promise((resolve, reject) => server.close((error) => (error ? reject(error) : resolve())));
  }
}

async function request(
  baseUrl,
  path,
  { method = 'GET', token, deviceCredential, idempotencyKey, body } = {},
) {
  return fetch(`${baseUrl}${path}`, {
    method,
    headers: {
      ...(deviceCredential ? { authorization: `Device ${deviceCredential}` } : {}),
      ...(token ? { authorization: `Bearer ${token}` } : {}),
      ...(idempotencyKey ? { 'idempotency-key': idempotencyKey } : {}),
      ...(body === undefined ? {} : { 'content-type': 'application/json' }),
    },
    ...(body === undefined ? {} : { body: JSON.stringify(body) }),
  });
}

async function createFamilyAndChild(baseUrl) {
  const familyResponse = await request(baseUrl, '/v1/families', {
    method: 'POST',
    token: 'test-primary',
    idempotencyKey: 'device-surface-family',
    body: { displayName: 'Device surface family' },
  });
  assert.equal(familyResponse.status, 201);
  const family = (await familyResponse.json()).family;
  const childResponse = await request(baseUrl, `/v1/families/${family.id}/children`, {
    method: 'POST',
    token: 'test-primary',
    idempotencyKey: 'device-surface-child',
    body: { displayName: 'Amani', ageYears: 9, avatarEmoji: '🧒', themeColor: 'teal' },
  });
  assert.equal(childResponse.status, 201);
  return { family, child: (await childResponse.json()).child };
}

/** The whole read surface for one family, as a guardian receives it. */
async function readDevices(baseUrl, familyId, token = 'test-primary') {
  const response = await request(baseUrl, `/v1/families/${familyId}/devices`, { token });
  assert.equal(response.status, 200);
  const body = await response.json();
  assertMatchesDeclaredSchema(body, 'FamilyDeviceListResponse', 'the device list response');
  return body.devices;
}

/** Register, claim and report, so the lifecycle can be observed moving. */
async function pairAndReport(baseUrl, familyId, childId, { idempotencyKey }) {
  const pairingResponse = await request(
    baseUrl,
    `/v1/families/${familyId}/children/${childId}/device-pairings`,
    {
      method: 'POST',
      token: 'test-primary',
      idempotencyKey: `${idempotencyKey}-pairing`,
      body: { deviceLabel: 'هاتف أمانة' },
    },
  );
  assert.equal(pairingResponse.status, 201);
  const pairing = (await pairingResponse.json()).pairing;

  // The claim is unauthenticated by design: the one-time code IS the authority, and the
  // handset claiming it has no account yet.
  const claimResponse = await request(baseUrl, '/v1/device-pairings/claim', {
    method: 'POST',
    body: { pairingCode: pairing.pairingCode },
  });
  assert.equal(claimResponse.status, 201);
  const claimed = await claimResponse.json();
  assertMatchesDeclaredSchema(claimed, 'ClaimDevicePairingResponse', 'the pairing claim response');
  assert.match(claimed.deviceCredential, /^[A-Za-z0-9_-]{32,128}$/);

  const telemetryResponse = await request(baseUrl, `/v1/devices/${claimed.device.id}/telemetry`, {
    method: 'POST',
    deviceCredential: claimed.deviceCredential,
    body: {
      batteryLevel: 74,
      batteryStatus: 'unplugged',
      locationLat: 15.3694,
      locationLng: 44.191,
      locationLabel: 'البيت',
    },
  });
  assert.equal(telemetryResponse.status, 200);
  return { device: claimed.device, deviceCredential: claimed.deviceCredential };
}

test('every device the guardian reads carries the declared lifecycle, and it is derived not stored', async () => {
  const store = new MemoryFoundationStore({ now: () => new Date() });
  await withServer(foundationApp({ store }), async (baseUrl) => {
    const { family, child } = await createFamilyAndChild(baseUrl);

    // A registered device that no handset has claimed yet. The honest description is a
    // pairing that has not finished, not a device that is reporting.
    const registeredResponse = await request(baseUrl, `/v1/families/${family.id}/children/${child.id}/devices`, {
      method: 'POST',
      token: 'test-primary',
      idempotencyKey: 'device-surface-register',
      body: { deviceLabel: 'هاتف أمانة' },
    });
    assert.equal(registeredResponse.status, 201);
    const registered = await registeredResponse.json();
    assertMatchesDeclaredSchema(registered, 'FamilyDeviceResponse', 'the device registration response');

    assert.equal(registered.device.credentialState, 'unclaimed');
    assert.equal(registered.device.health.state, 'awaiting_pairing');
    assert.equal(registered.device.health.needsAttention, false);
    // Nothing a device has not proven may be described as available to the guardian.
    assert.ok(
      registered.device.capabilities.every((capability) => capability.state === 'unavailable'),
      'an unclaimed device reported a capability as available',
    );

    // The same device after a real pairing and a real report.
    const { device } = await pairAndReport(baseUrl, family.id, child.id, { idempotencyKey: 'device-surface' });

    const afterPairing = (await readDevices(baseUrl, family.id)).find((entry) => entry.id === device.id);
    assert.ok(afterPairing, 'the paired device is absent from the guardian read surface');
    assert.equal(afterPairing.credentialState, 'active');
    assert.equal(afterPairing.health.state, 'active');
    assert.equal(afterPairing.health.reasonCode, 'reporting_now');
    // Silence is the design: a working device asks for nothing.
    assert.equal(afterPairing.health.needsAttention, false);
    assert.equal(afterPairing.health.state === 'active' && afterPairing.health.needsAttention, false);

    const telemetry = Object.fromEntries(afterPairing.capabilities.map((entry) => [entry.id, entry]));
    assert.equal(telemetry.telemetry.state, 'available');
    assert.equal(telemetry.location.state, 'available');
    // The server measures reporting, and says so, rather than asserting a background
    // service it cannot observe.
    assert.equal(telemetry.background_service.reasonCode, 'reporting_now');
  });
});

test('a device that stopped reporting is never described as current', async () => {
  // The clock steps six hours between the report and the read, which is the failure this
  // surface exists to prevent: a last reading presented as the present.
  let clock = new Date('2026-10-06T08:00:00.000Z');
  const store = new MemoryFoundationStore({ now: () => clock });
  await withServer(foundationApp({ store }), async (baseUrl) => {
    const { family, child } = await createFamilyAndChild(baseUrl);
    const { device } = await pairAndReport(baseUrl, family.id, child.id, { idempotencyKey: 'device-quiet' });

    clock = new Date('2026-10-06T15:00:00.000Z');
    const quiet = (await readDevices(baseUrl, family.id)).find((entry) => entry.id === device.id);
    assert.ok(quiet, 'the device vanished from the read surface instead of being described');
    assert.equal(quiet.health.state, 'offline');
    assert.equal(quiet.health.reasonCode, 'stopped_reporting');
    assert.equal(quiet.health.needsAttention, true, 'a device that went quiet must reach the guardian');

    const telemetry = Object.fromEntries(quiet.capabilities.map((entry) => [entry.id, entry]));
    assert.equal(telemetry.telemetry.state, 'unavailable');
    // Location too, and this is the point of the test. The stored coordinates are still on
    // the record, and a server that answered "location: available" would be telling the
    // guardian it can find the child right now. It cannot: nothing has reported for seven
    // hours. The facts stay available; the capability does not.
    assert.equal(telemetry.location.state, 'unavailable');
    assert.ok(
      quiet.capabilities.every((capability) => capability.reasonCode === 'stopped_reporting'),
      'a silent device gave a reason other than its silence',
    );
    assert.equal(quiet.lastSeenAt, '2026-10-06T08:00:00.000Z');
  });
});

test('revocation is answered, and afterwards read, as a device that is cut off', async () => {
  const store = new MemoryFoundationStore({ now: () => new Date() });
  await withServer(foundationApp({ store }), async (baseUrl) => {
    const { family, child } = await createFamilyAndChild(baseUrl);
    const { device } = await pairAndReport(baseUrl, family.id, child.id, { idempotencyKey: 'device-revoke' });

    const revocationResponse = await request(
      baseUrl,
      `/v1/families/${family.id}/children/${child.id}/devices/${device.id}/revocation`,
      {
        method: 'POST',
        token: 'test-primary',
        idempotencyKey: 'device-revoke-once',
        body: { reasonCode: 'lost' },
      },
    );
    assert.equal(revocationResponse.status, 200);
    const revoked = await revocationResponse.json();
    assertMatchesDeclaredSchema(revoked, 'DeviceRevocationResponse', 'the revocation response');
    assert.equal(revoked.device.health.state, 'revoked');
    assert.equal(revoked.device.health.needsAttention, true);
    assert.equal(revoked.device.credentialState, 'revoked');

    // The read surface must agree with the write surface. A guardian who revokes a lost
    // handset and then opens the roster may not be told it is still protecting the child.
    const listed = (await readDevices(baseUrl, family.id)).find((entry) => entry.id === device.id);
    assert.ok(listed, 'the revoked device is absent from the read surface');
    assert.equal(listed.health.state, 'revoked');
    assert.equal(listed.health.needsAttention, true);
    assert.ok(
      listed.capabilities.every((capability) => capability.state === 'unavailable'),
      'a revoked device claimed a capability it cannot have',
    );
    assert.ok(
      listed.capabilities.every((capability) => capability.reasonCode === 'device_revoked'),
      'a revoked capability was given a reason other than the revocation',
    );

    // A second revocation is a stated conflict, not a rewrite of who cut it off or when.
    const again = await request(
      baseUrl,
      `/v1/families/${family.id}/children/${child.id}/devices/${device.id}/revocation`,
      {
        method: 'POST',
        token: 'test-primary',
        idempotencyKey: 'device-revoke-twice',
        body: {},
      },
    );
    assert.equal(again.status, 409);
    assert.equal((await again.json()).error.code, 'device_already_revoked');
  });
});

test('the declared device schemas cannot drift from what the server sends', async () => {
  // A canary in the other direction: if the declaration ever stops describing the server,
  // this test says so by name rather than by a mystery failure in a client generator.
  const store = new MemoryFoundationStore({ now: () => new Date() });
  await withServer(foundationApp({ store }), async (baseUrl) => {
    const { family, child } = await createFamilyAndChild(baseUrl);
    await pairAndReport(baseUrl, family.id, child.id, { idempotencyKey: 'device-canary' });

    const annotated = structuredClone(document.components.schemas.FamilyDevice);
    annotated.required = [...annotated.required, 'aFieldTheServerDoesNotSend'];
    try {
      const body = { devices: (await readDevices(baseUrl, family.id)) };
      validate(body, { ...document.components.schemas.FamilyDeviceListResponse });
      // Validate the annotated copy directly through the same path the helper uses.
      validate(body.devices[0], annotated);
      assert.fail('a device missing a declared required property was accepted');
    } catch (error) {
      assert.match(String(error.message), /aFieldTheServerDoesNotSend/);
    }
  });
});
