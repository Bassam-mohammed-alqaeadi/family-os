import assert from 'node:assert/strict';
import test from 'node:test';
import { validatedOidcSubject } from '../src/auth/oidc-verifier.js';
import {
  chatThreadCreateInput,
  collaborationPolicyInput,
  createChildInput,
  createGuardianTransferInput,
  requireNoQueryParameters,
  requireUuid,
} from '../src/validation.js';

const VALID_UUID = '00000000-0000-4000-8000-000000000000';

test('family resource identifiers are strict UUIDs before they reach PostgreSQL', () => {
  assert.equal(requireUuid(VALID_UUID, 'familyId'), VALID_UUID);
  assert.throws(() => requireUuid('not-a-uuid', 'familyId'), {
    code: 'invalid_request',
  });
  assert.throws(
    () => createGuardianTransferInput({ candidateMembershipId: 'not-a-uuid' }),
    { code: 'invalid_request' },
  );
});

test('family discovery refuses every caller-supplied query parameter before store evaluation', () => {
  assert.doesNotThrow(() => requireNoQueryParameters({}));
  assert.throws(() => requireNoQueryParameters({ familyId: VALID_UUID }), { code: 'invalid_request' });
  assert.throws(() => requireNoQueryParameters(['familyId']), { code: 'invalid_request' });
});

test('OIDC subjects are bounded before becoming durable account identifiers', () => {
  assert.equal(validatedOidcSubject('issuer|opaque-subject'), 'issuer|opaque-subject');
  assert.throws(() => validatedOidcSubject(''), { code: 'invalid_token' });
  assert.throws(() => validatedOidcSubject('subject\u0000injection'), { code: 'invalid_token' });
  assert.throws(() => validatedOidcSubject('x'.repeat(256)), { code: 'invalid_token' });
});

test('chat creation accepts explicit direct pairs and groups, not legacy one-child or family-room shapes', () => {
  const childId = '11111111-1111-4111-8111-111111111111';
  const guardianId = '22222222-2222-4222-8222-222222222222';
  assert.deepEqual(chatThreadCreateInput({
    kind: 'direct',
    participants: [{ kind: 'child', id: childId }],
  }), {
    kind: 'direct',
    title: '',
    participants: [{ kind: 'child', id: childId }],
  });
  assert.deepEqual(chatThreadCreateInput({
    kind: 'group',
    title: 'The family group',
    participants: [
      { kind: 'child', id: childId },
      { kind: 'membership', id: guardianId },
    ],
  }), {
    kind: 'group',
    title: 'The family group',
    participants: [
      { kind: 'child', id: childId },
      { kind: 'membership', id: guardianId },
    ],
  });
  assert.throws(
    () => chatThreadCreateInput({ kind: 'family', participants: [] }),
    { code: 'invalid_request' },
  );
  assert.throws(
    () => chatThreadCreateInput({ kind: 'direct', participants: [], childIds: [childId] }),
    { code: 'invalid_request' },
  );
  assert.throws(
    () => chatThreadCreateInput({
      kind: 'direct',
      participants: [
        { kind: 'child', id: childId },
        { kind: 'membership', id: guardianId },
      ],
    }),
    { code: 'invalid_request' },
  );
  assert.throws(
    () => chatThreadCreateInput({
      kind: 'group',
      participants: [{ kind: 'child', id: childId }],
    }),
    { code: 'invalid_request' },
  );
});

test('collaboration policy permits only bounded guardian-role delegation and explicit safety controls', () => {
  assert.deepEqual(collaborationPolicyInput({
    chatCreateRoles: ['primary_guardian'],
    chatManageRoles: ['primary_guardian', 'co_guardian'],
    taskRoles: [],
    calendarRoles: ['co_guardian'],
    childDirectEnabled: true,
    childGroupsEnabled: false,
    childGroupMemberManagementEnabled: false,
    guardianInclusionMode: 'child_to_child',
    maximumGroupSize: 8,
    expectedVersion: 3,
  }), {
    change: {
      chatCreateRoles: ['primary_guardian'],
      chatManageRoles: ['primary_guardian', 'co_guardian'],
      taskRoles: [],
      calendarRoles: ['co_guardian'],
      childDirectEnabled: true,
      childGroupsEnabled: false,
      childGroupMemberManagementEnabled: false,
      guardianInclusionMode: 'child_to_child',
      maximumGroupSize: 8,
    },
    expectedVersion: 3,
  });
  assert.throws(
    () => collaborationPolicyInput({ chatCreateRoles: ['child'], expectedVersion: 3 }),
    { code: 'invalid_request' },
  );
  assert.throws(
    () => collaborationPolicyInput({ taskRoles: ['co_guardian', 'co_guardian'], expectedVersion: 3 }),
    { code: 'invalid_request' },
  );
  assert.throws(
    () => collaborationPolicyInput({ guardianInclusionMode: 'all_family_members', expectedVersion: 3 }),
    { code: 'invalid_request' },
  );
  assert.throws(
    () => collaborationPolicyInput({ maximumGroupSize: 2, expectedVersion: 3 }),
    { code: 'invalid_request' },
  );
  assert.throws(
    () => collaborationPolicyInput({ childDirectEnabled: true, expectedVersion: 3, primaryCanLoseAccess: true }),
    { code: 'invalid_request' },
  );
});

test('children roster request rejects fields outside its published contract', () => {
  assert.doesNotThrow(() => createChildInput({ displayName: 'Amani', ageYears: 0, avatarEmoji: '🦁', themeColor: 'purple' }));
  assert.throws(
    () => createChildInput({ displayName: 'Amani', ageYears: 0, avatarEmoji: '🦁', themeColor: 'purple', role: 'primary_guardian' }),
    { code: 'invalid_request' },
  );
  assert.throws(
    () => createChildInput({ displayName: 'Amani', ageYears: 0, avatarEmoji: 'name', themeColor: 'purple' }),
    { code: 'invalid_request' },
  );
  assert.throws(
    () => createChildInput({ displayName: 'Amani', ageYears: 0, avatarEmoji: '🦁', themeColor: 'gradient' }),
    { code: 'invalid_request' },
  );
});
