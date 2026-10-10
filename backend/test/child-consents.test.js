// Safety slice 2 — the child-consent surface laws.
//
// These run against a fake port so the laws are fast and explicit: who may record a grant,
// what withdrawal does to the row, and what the child phone is told about itself. The
// real database journey lives in `postgres-child-consents.test.js`.
import assert from 'node:assert/strict';
import test from 'node:test';

import { createChildConsentSurface } from '../src/child-consents.js';

function fakePort(overrides = {}) {
  const consents = [];
  const memberships = new Map([['test-primary', { id: 'mem-primary', role: 'primary_guardian' }]]);
  const devices = new Map([
    [
      '11111111-1111-4111-8111-111111111111',
      {
        id: '11111111-1111-4111-8111-111111111111',
        family_id: 'fam-1',
        child_id: 'child-1',
        credential_hash: 'hash-good',
        credential_revoked_at: null,
      },
    ],
    [
      '22222222-2222-4222-8222-222222222222',
      {
        id: '22222222-2222-4222-8222-222222222222',
        family_id: 'fam-2',
        child_id: 'child-2',
        credential_hash: 'hash-other',
        credential_revoked_at: null,
      },
    ],
  ]);
  return {
    consents,
    credentialMatches: (hash, credential) => hash === `hash-${credential}`,
    withTransaction: (run) => run({}),
    idempotent: async (_scope, _key, _hash, work) => work({}),
    authorize: async (_tx, { familyId, subject, primaryGuardianOnly }) => {
      const membership = memberships.get(subject);
      if (membership === undefined) {
        const error = new Error('denied');
        error.status = 403;
        error.code = 'family_access_denied';
        throw error;
      }
      // One guardian per family in this fake: a member of fam-1 reaches nothing in fam-2.
      const familyOf = { 'test-primary': 'fam-1', 'test-other': 'fam-2' };
      if (familyOf[subject] !== familyId) {
        const error = new Error('denied');
        error.status = 403;
        error.code = 'family_access_denied';
        throw error;
      }
      if (primaryGuardianOnly && membership.role !== 'primary_guardian') {
        const error = new Error('denied');
        error.status = 403;
        error.code = 'family_access_denied';
        throw error;
      }
      return membership;
    },
    activeActorMembershipId: async (_tx, { subject }) => memberships.get(subject).id,
    readConsentDevice: async (_tx, { deviceId }) => devices.get(deviceId) ?? null,
    readActiveConsent: async (_tx, { childId, capability }) =>
      consents.find(
        (row) => row.child_id === childId && row.capability === capability && row.withdrawn_at === null,
      ) ?? null,
    readLatestConsent: async (_tx, { childId, capability }) =>
      consents
        .filter((row) => row.child_id === childId && row.capability === capability)
        .at(-1) ?? null,
    readConsentStates: async (_tx, { childId }) => {
      const latest = new Map();
      for (const row of consents) {
        if (row.child_id === childId) latest.set(row.capability, row);
      }
      return latest;
    },
    insertConsent: async (_tx, row) => {
      const stored = {
        family_id: row.familyId,
        child_id: row.childId,
        capability: row.capability,
        text_version: row.textVersion,
        granted_at: row.grantedAt,
        granted_by_membership_id: row.grantedByMembershipId,
        granted_by_device_id: row.grantedByDeviceId,
        withdrawn_at: null,
        withdrawn_by_membership_id: null,
      };
      consents.push(stored);
      return stored;
    },
    withdrawActiveConsent: async (_tx, { childId, capability, withdrawnByMembershipId, withdrawnAt }) => {
      const active = consents.find(
        (row) => row.child_id === childId && row.capability === capability && row.withdrawn_at === null,
      );
      if (active === undefined) return null;
      active.withdrawn_at = withdrawnAt;
      active.withdrawn_by_membership_id = withdrawnByMembershipId;
      return active;
    },
    ...overrides,
  };
}

const deviceId = '11111111-1111-4111-8111-111111111111';

function surface(port = fakePort()) {
  return { port, surface: createChildConsentSurface({ port, now: () => new Date('2026-10-10T12:00:00.000Z') }) };
}

test('the handset records its own setup agreement, and the row names the device as granter', async () => {
  const { surface: consents, port } = surface();
  const answer = await consents.recordConsent({
    deviceCredential: 'good',
    deviceId,
    capability: 'location',
    textVersion: '2026-10-10',
    idempotencyKey: 'consent-key-0000000000000001',
    requestHash: 'hash-1',
  });
  assert.equal(answer.consent.state, 'granted');
  assert.equal(answer.consent.grantedByDeviceId, deviceId);
  assert.equal(answer.consent.grantedByMembershipId, null);
  assert.equal(answer.consent.textVersion, '2026-10-10');
  assert.equal(port.consents.length, 1);
});

test('a primary guardian records a grant, and the row names the membership', async () => {
  const { surface: consents } = surface();
  const answer = await consents.recordConsent({
    principal: { subject: 'test-primary' },
    deviceId,
    capability: 'location',
    textVersion: '2026-10-10',
    idempotencyKey: 'consent-key-0000000000000002',
    requestHash: 'hash-2',
  });
  assert.equal(answer.consent.state, 'granted');
  assert.equal(answer.consent.grantedByMembershipId, 'mem-primary');
  assert.equal(answer.consent.grantedByDeviceId, null);
});

test('granting while an active consent exists is refused, not stacked', async () => {
  const { surface: consents } = surface();
  const grant = {
    deviceCredential: 'good',
    deviceId,
    capability: 'location',
    textVersion: '2026-10-10',
    idempotencyKey: 'consent-key-0000000000000003',
    requestHash: 'hash-3',
  };
  await consents.recordConsent(grant);
  await assert.rejects(
    () => consents.recordConsent({ ...grant, idempotencyKey: 'consent-key-0000000000000004' }),
    (error) => error.status === 409 && error.code === 'consent_already_granted',
  );
});

test('withdrawal freezes the grant in place, and a second "no" answers the same "no"', async () => {
  const { surface: consents } = surface();
  await consents.recordConsent({
    deviceCredential: 'good',
    deviceId,
    capability: 'location',
    textVersion: '2026-10-10',
    idempotencyKey: 'consent-key-0000000000000005',
    requestHash: 'hash-5',
  });
  const withdrawn = await consents.withdrawConsent({
    principal: { subject: 'test-primary' },
    deviceId,
    capability: 'location',
  });
  assert.equal(withdrawn.consent.state, 'withdrawn');
  assert.equal(withdrawn.consent.withdrawnByMembershipId, 'mem-primary');

  const again = await consents.withdrawConsent({
    principal: { subject: 'test-primary' },
    deviceId,
    capability: 'location',
  });
  assert.equal(again.consent.state, 'withdrawn');

  // A later grant is a new row; the frozen withdrawal is not overwritten.
  const regranted = await consents.recordConsent({
    deviceCredential: 'good',
    deviceId,
    capability: 'location',
    textVersion: '2026-10-11',
    idempotencyKey: 'consent-key-0000000000000006',
    requestHash: 'hash-6',
  });
  assert.equal(regranted.consent.state, 'granted');
  assert.equal(regranted.consent.textVersion, '2026-10-11');
});

test('the handset is told the ledger state: none, granted, withdrawn — never a guess', async () => {
  const { surface: consents } = surface();
  const before = await consents.locationSharing({ deviceCredential: 'good', deviceId });
  assert.equal(before.capabilities.location.state, 'none');

  await consents.recordConsent({
    deviceCredential: 'good',
    deviceId,
    capability: 'location',
    textVersion: '2026-10-10',
    idempotencyKey: 'consent-key-0000000000000007',
    requestHash: 'hash-7',
  });
  const during = await consents.locationSharing({ deviceCredential: 'good', deviceId });
  assert.equal(during.capabilities.location.state, 'granted');

  await consents.withdrawConsent({
    principal: { subject: 'test-primary' },
    deviceId,
    capability: 'location',
  });
  const after = await consents.locationSharing({ deviceCredential: 'good', deviceId });
  assert.equal(after.capabilities.location.state, 'withdrawn');
  // The future capabilities come back named and ungranted, so the phone never shows
  // a capability the ledger does not hold.
  assert.equal(after.capabilities.usage_stats.state, 'none');
  assert.equal(after.capabilities.web_filtering.state, 'none');
});

test('a credential that is not this handset speaks for nothing', async () => {
  const { surface: consents } = surface();
  await assert.rejects(
    () =>
      consents.recordConsent({
        deviceCredential: 'other',
        deviceId,
        capability: 'location',
        textVersion: '2026-10-10',
        idempotencyKey: 'consent-key-0000000000000008',
        requestHash: 'hash-8',
      }),
    (error) => error.status === 401 && error.code === 'invalid_device_credential',
  );
});

test('a guardian of another family reaches nothing here', async () => {
  const port = fakePort();
  const consents = createChildConsentSurface({ port });
  // test-primary owns fam-1; the second handset belongs to fam-2.
  await assert.rejects(
    () =>
      consents.withdrawConsent({
        principal: { subject: 'test-primary' },
        deviceId: '22222222-2222-4222-8222-222222222222',
        capability: 'location',
      }),
    (error) => error.status === 403,
  );
});

test('withdrawal is a guardian act — a handset may grant and read, never withdraw', async () => {
  const { surface: consents } = surface();
  await assert.rejects(
    () =>
      consents.withdrawConsent({
        deviceCredential: 'good',
        deviceId,
        capability: 'location',
      }),
    (error) => error.status === 401,
  );
});
