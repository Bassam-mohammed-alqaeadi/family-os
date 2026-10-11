// Safety slice S0 — capability-ledger surface laws.
//
// These run against a fake in-memory port so the rules are explicit: the handset
// decides facts, heartbeat duplicates do not produce events, a state change writes
// exactly one event/outbox row per fact (R6), and guardians read only their own family.
import assert from 'node:assert/strict';
import test from 'node:test';

import { createDeviceCapabilitySurface, CAPABILITY_KEYS, CAPABILITY_STATES } from '../src/device-capabilities.js';

const FAMILY = '00000000-0000-4000-8000-000000000001';
const CHILD = '00000000-0000-4000-8000-000000000002';
const DEVICE = '00000000-0000-4000-8000-000000000003';
const DEVICE_CREDENTIAL = 'goodcredential';

function fakePort() {
  const rows = new Map();
  const events = [];
  const devices = new Map([
    [DEVICE, { id: DEVICE, family_id: FAMILY, child_id: CHILD, credential_hash: `hash-${DEVICE_CREDENTIAL}`, credential_revoked_at: null }],
  ]);
  const members = new Map([['primary-subject', { id: 'mem-1', role: 'primary_guardian' }]]);
  const families = new Map([['primary-subject', FAMILY]]);
  return {
    events,
    credentialMatches: (hash, cred) => hash === `hash-${cred}`,
    withTransaction: async (run) => run({}),
    idempotent: async (_scope, _key, _hash, work) => work({}),
    authorize: async (_tx, { familyId, subject, primaryGuardianOnly }) => {
      const m = members.get(subject);
      if (!m) throw new Error('denied');
      if (families.get(subject) !== familyId) throw new Error('denied');
      if (primaryGuardianOnly && m.role !== 'primary_guardian') throw new Error('denied');
      return m;
    },
    readDeviceIdentity: async (_tx, { deviceId }) => devices.get(deviceId) ?? null,
    verifyChildInFamily: async (_tx, { familyId, childId }) => {
      if (familyId !== FAMILY || childId !== CHILD) {
        const err = new Error('not found');
        err.statusCode = 404;
        throw err;
      }
    },
    readCapability: async (_tx, { deviceId, capabilityKey }) => rows.get(`${deviceId}:${capabilityKey}`) ?? null,
    readCapabilitiesForChild: async (_tx, { familyId, childId }) => {
      assert.equal(familyId, FAMILY);
      assert.equal(childId, CHILD);
      return [...rows.values()].filter((r) => r.family_id === familyId);
    },
    upsertCapability: async (_tx, row) => {
      const key = `${row.deviceId}:${row.capabilityKey}`;
      const stored = {
        device_id: row.deviceId,
        family_id: row.familyId,
        capability_key: row.capabilityKey,
        state: row.state,
        evidence: row.evidence,
        app_version: row.appVersion,
        os_version: row.osVersion,
        confirmed_at: row.confirmedAt,
        reported_at: row.reportedAt,
      };
      rows.set(key, stored);
      return stored;
    },
    appendCapabilityChangedEvent: async (_tx, evt) => {
      events.push(evt);
    },
  };
}

test('CAPABILITY_KEYS and CAPABILITY_STATES contain the S0 vocabulary', () => {
  assert.ok(CAPABILITY_KEYS.has('instant_lock'));
  assert.ok(CAPABILITY_KEYS.has('background_location'));
  assert.ok(CAPABILITY_KEYS.has('push_delivery'));
  assert.ok(CAPABILITY_STATES.has('confirmed'));
  assert.ok(CAPABILITY_STATES.has('unsupported'));
});

test('a handset reporting capabilities for the first time returns all entries as changed and emits events', async () => {
  const port = fakePort();
  const surface = createDeviceCapabilitySurface({ port });
  const result = await surface.reportSnapshot({
    deviceCredential: DEVICE_CREDENTIAL,
    deviceId: DEVICE,
    entries: [
      { capabilityKey: 'instant_lock', state: 'confirmed', confirmedAt: new Date() },
      { capabilityKey: 'background_location', state: 'permission_needed', evidence: 'ACCESS_BACKGROUND_LOCATION denied' },
    ],
    idempotencyKey: 'k1',
    requestHash: 'h1',
  });
  assert.equal(result.deviceId, DEVICE);
  assert.equal(result.capabilities.length, 2, 'two new capabilities both changed');
  assert.equal(port.events.length, 2, 'R6: one outbox row per state change');
});

test('heartbeat replay (same state) returns no changes and emits no events', async () => {
  const port = fakePort();
  const surface = createDeviceCapabilitySurface({ port });
  await surface.reportSnapshot({
    deviceCredential: DEVICE_CREDENTIAL, deviceId: DEVICE,
    entries: [{ capabilityKey: 'instant_lock', state: 'confirmed', confirmedAt: new Date() }],
    idempotencyKey: 'k1', requestHash: 'h1',
  });
  port.events.length = 0;
  const again = await surface.reportSnapshot({
    deviceCredential: DEVICE_CREDENTIAL, deviceId: DEVICE,
    entries: [{ capabilityKey: 'instant_lock', state: 'confirmed', confirmedAt: new Date() }],
    idempotencyKey: 'k2', requestHash: 'h2',
  });
  assert.equal(again.capabilities.length, 0, 'no state change → not echoed');
  assert.equal(port.events.length, 0, 'no event emitted for same-state replay');
});

test('unsupported capability does not carry confirmedAt', async () => {
  const port = fakePort();
  const surface = createDeviceCapabilitySurface({ port });
  await assert.rejects(
    () => surface.reportSnapshot({
      deviceCredential: DEVICE_CREDENTIAL, deviceId: DEVICE,
      entries: [{ capabilityKey: 'web_filter_vpn', state: 'unsupported', confirmedAt: new Date() }],
      idempotencyKey: 'k', requestHash: 'h',
    }),
    /confirmedAt/,
  );
});

test('a revoked device credential is refused', async () => {
  const port = fakePort();
  const surface = createDeviceCapabilitySurface({ port });
  await assert.rejects(
    async () => {
      try {
        await surface.reportSnapshot({
          deviceCredential: 'wrong', deviceId: DEVICE,
          entries: [{ capabilityKey: 'push_delivery', state: 'unknown' }],
          idempotencyKey: 'k', requestHash: 'h',
        });
      } catch (err) {
        assert.equal(err.status, 401);
        assert.equal(err.code, 'invalid_device_credential');
        throw err;
      }
    },
  );
});

test('guardian reads capabilities grouped by device', async () => {
  const port = fakePort();
  const surface = createDeviceCapabilitySurface({ port });
  await surface.reportSnapshot({
    deviceCredential: DEVICE_CREDENTIAL, deviceId: DEVICE,
    entries: [
      { capabilityKey: 'instant_lock', state: 'confirmed', confirmedAt: new Date() },
      { capabilityKey: 'background_location', state: 'confirmed', confirmedAt: new Date() },
    ],
    idempotencyKey: 'k1', requestHash: 'h1',
  });
  const view = await surface.readForChild({
    principal: { subject: 'primary-subject' },
    familyId: FAMILY, childId: CHILD,
  });
  assert.equal(view.familyId, FAMILY);
  assert.equal(view.devices.length, 1);
  assert.equal(Object.keys(view.devices[0].capabilities).length, 2);
});
