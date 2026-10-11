// Safety slice S0 — command lifecycle laws.
//
// Fake port, explicit rules: idempotency, expiry refusal on late receipts,
// unsupported capability blocks lock_now, and receipts advance state honestly.
import assert from 'node:assert/strict';
import test from 'node:test';

import { createCommandSurface } from '../src/command-lifecycle.js';

const FAMILY = '00000000-0000-4000-8000-000000000001';
const CHILD = '00000000-0000-4000-8000-000000000002';
const DEVICE = '00000000-0000-4000-8000-000000000003';
const DEVICE_CREDENTIAL = 'goodcredential';

function fakePort({ now } = {}) {
  const commands = new Map();
  const receipts = new Map();
  const events = [];
  const capabilities = new Map(); // key -> row
  const devices = new Map([
    [DEVICE, { id: DEVICE, family_id: FAMILY, child_id: CHILD, credential_hash: `hash-${DEVICE_CREDENTIAL}`, credential_revoked_at: null }],
  ]);
  const members = new Map([['primary-subject', { id: 'mem-1', role: 'primary_guardian' }]]);
  const families = new Map([['primary-subject', FAMILY]]);
  let seq = 0;
  const clock = now ?? { t: 0 };
  function time() { return new Date(clock.t); }
  return {
    commands, receipts, events, clock, capabilities,
    credentialMatches: (hash, cred) => hash === `hash-${cred}`,
    withTransaction: async (run) => run({}),
    idempotent: async (_scope, _key, _hash, work) => work({}),
    authorize: async (_tx, { familyId, subject, primaryGuardianOnly }) => {
      const m = members.get(subject);
      if (!m || families.get(subject) !== familyId) throw new Error('denied');
      if (primaryGuardianOnly && m.role !== 'primary_guardian') throw new Error('denied');
      return m;
    },
    activeActorMembershipId: async () => 'mem-1',
    readDeviceIdentity: async (_tx, { deviceId }) => devices.get(deviceId) ?? null,
    readDeviceForChild: async (_tx, { familyId, childId, deviceId }) => {
      const d = devices.get(deviceId);
      if (!d || d.family_id !== familyId || d.child_id !== childId) return null;
      return d;
    },
    readCapability: async (_tx, { deviceId, capabilityKey }) => capabilities.get(`${deviceId}:${capabilityKey}`) ?? null,
    readCommandForDevice: async (_tx, { commandId, deviceId }) => {
      const c = commands.get(commandId);
      if (!c || c.device_id !== deviceId) return null;
      return c;
    },
    readReceipt: async (_tx, { commandId }) => receipts.get(commandId) ?? null,
    insertCommand: async (_tx, row) => {
      seq += 1;
      const id = `cmd-${seq}`;
      const stored = {
        id, family_id: row.familyId, child_id: row.childId, device_id: row.deviceId,
        command_type: row.commandType, policy_id: row.policyId, policy_version: row.policyVersion,
        payload: row.payload, actor_membership_id: row.actorMembershipId,
        idempotency_key: row.idempotencyKey, priority: row.priority,
        expires_at: row.expiresAt, state: 'accepted',
        created_at: row.createdAt, dispatched_at: null, received_at: null, applied_at: null,
        failure_reason: null,
      };
      commands.set(id, stored);
      return stored;
    },
    transitionCommand: async (_tx, { commandId, state, appliedAt, failureReason, setReceivedAt }) => {
      const c = commands.get(commandId);
      c.state = state;
      if (appliedAt) c.applied_at = appliedAt;
      if (failureReason !== undefined) c.failure_reason = failureReason;
      if (setReceivedAt) c.received_at = time();
      return c;
    },
    upsertReceipt: async (_tx, r) => {
      const stored = {
        command_id: r.commandId,
        receipt_kind: r.receiptKind,
        effective_state: r.effectiveState,
        observed_at_device: r.observedAtDevice,
        received_at_server: r.receivedAtServer,
        failure_reason: r.failureReason,
      };
      receipts.set(r.commandId, stored);
      return stored;
    },
    expireStaleCommands: async () => {},
    pullPendingCommands: async (_tx, { deviceId, limit, now: now_ }) => {
      return [...commands.values()]
        .filter((c) => c.device_id === deviceId && c.state === 'accepted' && c.expires_at.getTime() > now_.getTime())
        .slice(0, limit);
    },
    markDispatched: async () => {},
    listFamilyCommands: async (_tx, { familyId, limit }) => {
      return [...commands.values()].filter((c) => c.family_id === familyId).slice(0, limit);
    },
    appendCommandEvent: async (_tx, evt) => { events.push(evt); },
  };
}

test('S0 only enables lock_now / release_lock / refresh_policy', async () => {
  const port = fakePort();
  const surface = createCommandSurface({ port, now: () => new Date(port.clock.t) });
  await assert.rejects(
    () => surface.createCommand({
      principal: { subject: 'primary-subject' },
      familyId: FAMILY, childId: CHILD, deviceId: DEVICE,
      commandType: 'block_app',
      idempotencyKey: 'k',
    }),
    /commandType/,
  );
});

test('lock_now requires confirmed instant_lock capability', async () => {
  const port = fakePort();
  const surface = createCommandSurface({ port, now: () => new Date(port.clock.t) });
  await assert.rejects(
    () => surface.createCommand({
      principal: { subject: 'primary-subject' },
      familyId: FAMILY, childId: CHILD, deviceId: DEVICE,
      commandType: 'lock_now', idempotencyKey: 'k', ttlSeconds: 60,
    }),
    /instant_lock.*not.*confirmed|capability/i,
  );
});

test('a successful lock_now returns an accepted command and emits one event', async () => {
  const port = fakePort();
  port.capabilities.set(`${DEVICE}:instant_lock`, { state: 'confirmed' });
  const surface = createCommandSurface({ port, now: () => new Date(port.clock.t) });
  const { command } = await surface.createCommand({
    principal: { subject: 'primary-subject' },
    familyId: FAMILY, childId: CHILD, deviceId: DEVICE,
    commandType: 'lock_now', idempotencyKey: 'k1', ttlSeconds: 60,
  });
  assert.equal(command.state, 'accepted');
  assert.equal(command.commandType, 'lock_now');
  assert.equal(port.events.length, 1);
  assert.equal(port.events[0].eventType, 'command.dispatched');
});

test('a late receipt on an expired command is refused (410)', async () => {
  const clock = { t: 0 };
  const port = fakePort({ now: clock });
  port.capabilities.set(`${DEVICE}:instant_lock`, { state: 'confirmed' });
  const surface = createCommandSurface({ port, now: () => new Date(clock.t) });
  const { command } = await surface.createCommand({
    principal: { subject: 'primary-subject' },
    familyId: FAMILY, childId: CHILD, deviceId: DEVICE,
    commandType: 'lock_now', idempotencyKey: 'k1', ttlSeconds: 60,
  });
  // Advance clock past expiry
  clock.t = 90_000;
  await assert.rejects(
    async () => {
      try {
        await surface.recordReceipt({
          deviceCredential: DEVICE_CREDENTIAL, deviceId: DEVICE,
          commandId: command.id, receiptKind: 'applied',
          observedAtDevice: new Date(clock.t - 1000),
          idempotencyKey: 'r1', requestHash: 'h',
        });
        throw new Error('expected expiry error');
      } catch (err) {
        assert.equal(err.status, 410, 'late receipt must answer 410 Gone');
        assert.match(err.code, /command_expired/);
        throw err;
      }
    },
    /expired/,
  );
});

test('an applied receipt advances state to applied and records the receipt', async () => {
  const clock = { t: 0 };
  const port = fakePort({ now: clock });
  port.capabilities.set(`${DEVICE}:instant_lock`, { state: 'confirmed' });
  const surface = createCommandSurface({ port, now: () => new Date(clock.t) });
  const { command } = await surface.createCommand({
    principal: { subject: 'primary-subject' },
    familyId: FAMILY, childId: CHILD, deviceId: DEVICE,
    commandType: 'lock_now', idempotencyKey: 'k1', ttlSeconds: 120,
  });
  const result = await surface.recordReceipt({
    deviceCredential: DEVICE_CREDENTIAL, deviceId: DEVICE,
    commandId: command.id, receiptKind: 'applied',
    observedAtDevice: new Date(1000),
    idempotencyKey: 'r1', requestHash: 'h',
    effectiveState: { lockState: 'locked' },
  });
  assert.equal(result.command.state, 'applied');
  assert.equal(result.receipt.receiptKind, 'applied');
  // R6: receipt produces an event
  assert.ok(port.events.some((e) => e.eventType === 'command.applied'));
});

test('a failed receipt requires a failureReason', async () => {
  const port = fakePort();
  const surface = createCommandSurface({ port, now: () => new Date() });
  await assert.rejects(
    () => surface.recordReceipt({
      deviceCredential: DEVICE_CREDENTIAL, deviceId: DEVICE,
      commandId: 'cmd-1', receiptKind: 'failed',
      observedAtDevice: new Date(),
      idempotencyKey: 'r', requestHash: 'h',
    }),
    /failureReason/,
  );
});
