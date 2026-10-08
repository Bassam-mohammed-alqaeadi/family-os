import assert from 'node:assert/strict';
import test from 'node:test';

import {
  CollaborationPolicyError,
  collaborationPolicyFor,
  collaborationRoleAllowed,
} from '../src/collaboration-policy.js';

const FAMILY = '11111111-1111-4111-8111-111111111111';
const PRIMARY = '22222222-2222-4222-8222-222222222222';
const CO_GUARDIAN = '33333333-3333-4333-8333-333333333333';

function policyHarness() {
  const state = {
    row: null,
    audit: [],
    subjects: new Map([
      ['primary', { id: PRIMARY, role: 'primary_guardian' }],
      ['co-guardian', { id: CO_GUARDIAN, role: 'co_guardian' }],
    ]),
  };

  const client = {
    async query(sql, values = []) {
      if (sql.includes('FROM family_collaboration_policies')) {
        return { rows: state.row == null ? [] : [{ ...state.row }] };
      }
      if (sql.includes('INSERT INTO family_collaboration_policies')) {
        const expectedVersion = values[12];
        const currentVersion = state.row?.version ?? 0;
        if (currentVersion !== expectedVersion) return { rows: [] };
        state.row = {
          family_id: values[0],
          chat_create_roles: [...values[1]],
          chat_manage_roles: [...values[2]],
          task_roles: [...values[3]],
          calendar_roles: [...values[4]],
          child_direct_enabled: values[5],
          child_groups_enabled: values[6],
          child_group_member_management_enabled: values[7],
          guardian_inclusion_mode: values[8],
          maximum_group_size: values[9],
          version: values[10],
          updated_by_membership_id: values[11],
          updated_at: new Date('2026-10-09T00:00:00.000Z'),
        };
        return { rows: [{ ...state.row }] };
      }
      throw new Error(`Unexpected policy SQL: ${sql}`);
    },
  };

  const store = {
    async withTransaction(work) {
      return work(client);
    },
    async activeActorMembership(_client, familyId, subject) {
      if (familyId !== FAMILY || !state.subjects.has(subject)) {
        throw new Error('No active membership');
      }
      return { ...state.subjects.get(subject) };
    },
    async appendAuditAndOutbox(_client, record) {
      state.audit.push(record);
    },
  };

  return { state, policies: collaborationPolicyFor(store) };
}

test('missing policy rows resolve to the safe defaults and do not force guardian inclusion', async () => {
  const { policies } = policyHarness();
  const { policy } = await policies.read({
    principal: { subject: 'primary' },
    familyId: FAMILY,
  });

  assert.equal(policy.version, 0);
  assert.equal(policy.guardianInclusionMode, 'none');
  assert.equal(policy.maximumGroupSize, 24);
  assert.equal(policy.childDirectEnabled, true);
  assert.equal(policy.childGroupsEnabled, true);
  assert.ok(policy.chatCreateRoles.includes('co_guardian'));
});

test('only the primary guardian can change delegation and child-safety policy', async () => {
  const { state, policies } = policyHarness();
  await assert.rejects(
    policies.update({
      principal: { subject: 'co-guardian' },
      familyId: FAMILY,
      change: { childDirectEnabled: false },
      expectedVersion: 0,
      correlationId: 'correlation-co',
    }),
    (error) => error instanceof CollaborationPolicyError
      && error.status === 403
      && error.code === 'collaboration_policy_forbidden',
  );
  assert.equal(state.row, null);
  assert.equal(state.audit.length, 0);

  const { policy } = await policies.update({
    principal: { subject: 'primary' },
    familyId: FAMILY,
    change: {
      chatCreateRoles: ['primary_guardian'],
      chatManageRoles: ['primary_guardian', 'co_guardian'],
      taskRoles: ['co_guardian'],
      calendarRoles: [],
      childDirectEnabled: false,
      childGroupsEnabled: true,
      childGroupMemberManagementEnabled: false,
      guardianInclusionMode: 'child_to_child',
      maximumGroupSize: 8,
    },
    expectedVersion: 0,
    correlationId: 'correlation-primary',
  });

  assert.equal(policy.version, 1);
  assert.equal(policy.updatedByMembershipId, PRIMARY);
  assert.equal(policy.guardianInclusionMode, 'child_to_child');
  assert.equal(policy.childDirectEnabled, false);
  assert.equal(policy.childGroupsEnabled, true);
  assert.equal(policy.childGroupMemberManagementEnabled, false);
  assert.equal(policy.maximumGroupSize, 8);
  assert.equal(state.audit.length, 1);
  assert.equal(state.audit[0].eventType, 'family.collaboration_policy_updated');
  assert.equal(state.audit[0].actorMembershipId, PRIMARY);

  assert.equal(collaborationRoleAllowed({ role: 'primary_guardian' }, policy, 'chatCreate'), true);
  assert.equal(collaborationRoleAllowed({ role: 'co_guardian' }, policy, 'chatCreate'), false);
  assert.equal(collaborationRoleAllowed({ role: 'co_guardian' }, policy, 'task'), true);
  assert.equal(collaborationRoleAllowed({ role: 'co_guardian' }, policy, 'calendar'), false);
  assert.equal(collaborationRoleAllowed({ role: 'child' }, policy, 'task'), false);
});

test('a stale policy version is rejected rather than overwriting the primary guardian\'s update', async () => {
  const { policies } = policyHarness();
  await policies.update({
    principal: { subject: 'primary' },
    familyId: FAMILY,
    change: { maximumGroupSize: 12 },
    expectedVersion: 0,
    correlationId: 'correlation-first',
  });

  await assert.rejects(
    policies.update({
      principal: { subject: 'primary' },
      familyId: FAMILY,
      change: { maximumGroupSize: 18 },
      expectedVersion: 0,
      correlationId: 'correlation-stale',
    }),
    (error) => error instanceof CollaborationPolicyError
      && error.status === 409
      && error.code === 'collaboration_policy_stale_version',
  );
});
