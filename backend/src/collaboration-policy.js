// Family collaboration policy v1.
//
// This policy is enforcement data, not a client hint. The old household-wide/child-only chat
// contract is superseded for new conversations. A missing row means the explicit safe default:
// family-local direct/group conversations are allowed, guardian inclusion is `none`, and the
// existing guardian role set keeps its product capabilities. A guardian is included in a new
// child conversation only when a persisted, active policy selects that mode.
//
// Built-in roles remain immutable safety principals. Families can delegate chat, task and
// calendar capabilities among guardian roles; the primary guardian always retains policy
// control. No collaboration policy can turn a child into a guardian or grant device-management,
// identity, membership, location, or emergency capabilities.

import { HttpError } from './http-error.js';

export const GUARDIAN_ROLE_KEYS = Object.freeze(['primary_guardian', 'co_guardian']);

export const COLLABORATION_POLICY_DEFAULTS = Object.freeze({
  version: 0,
  chatCreateRoles: GUARDIAN_ROLE_KEYS,
  chatManageRoles: GUARDIAN_ROLE_KEYS,
  taskRoles: GUARDIAN_ROLE_KEYS,
  calendarRoles: GUARDIAN_ROLE_KEYS,
  childDirectEnabled: true,
  childGroupsEnabled: true,
  childGroupMemberManagementEnabled: true,
  guardianInclusionMode: 'none',
  maximumGroupSize: 24,
  updatedAt: null,
  updatedByMembershipId: null,
  source: 'default',
});

const ROLE_FIELD_BY_CAPABILITY = Object.freeze({
  chatCreate: 'chat_create_roles',
  chatManage: 'chat_manage_roles',
  task: 'task_roles',
  calendar: 'calendar_roles',
});

export class CollaborationPolicyError extends HttpError {
  constructor(status, code, message) {
    super(status, code, message);
    this.name = 'CollaborationPolicyError';
  }
}

function roleArray(value, fallback) {
  if (!Array.isArray(value)) return [...fallback];
  return [...new Set(value.filter((role) => GUARDIAN_ROLE_KEYS.includes(role)))];
}

export function collaborationPolicyView(row) {
  if (row == null) {
    return {
      ...COLLABORATION_POLICY_DEFAULTS,
      chatCreateRoles: [...GUARDIAN_ROLE_KEYS],
      chatManageRoles: [...GUARDIAN_ROLE_KEYS],
      taskRoles: [...GUARDIAN_ROLE_KEYS],
      calendarRoles: [...GUARDIAN_ROLE_KEYS],
    };
  }
  return {
    version: Number(row.version),
    chatCreateRoles: roleArray(row.chat_create_roles, GUARDIAN_ROLE_KEYS),
    chatManageRoles: roleArray(row.chat_manage_roles, GUARDIAN_ROLE_KEYS),
    taskRoles: roleArray(row.task_roles, GUARDIAN_ROLE_KEYS),
    calendarRoles: roleArray(row.calendar_roles, GUARDIAN_ROLE_KEYS),
    childDirectEnabled: row.child_direct_enabled === true,
    childGroupsEnabled: row.child_groups_enabled === true,
    childGroupMemberManagementEnabled: row.child_group_member_management_enabled === true,
    guardianInclusionMode: row.guardian_inclusion_mode ?? 'none',
    maximumGroupSize: Number(row.maximum_group_size ?? 24),
    updatedAt: row.updated_at == null ? null : new Date(row.updated_at).toISOString(),
    updatedByMembershipId: row.updated_by_membership_id ?? null,
    source: 'family',
  };
}

export function collaborationRoleAllowed(actor, policy, capability) {
  if (actor?.role === 'primary_guardian') return true;
  const field = ROLE_FIELD_BY_CAPABILITY[capability];
  if (field == null) return false;
  const allowed = policy?.[
    capability === 'chatCreate' ? 'chatCreateRoles'
      : capability === 'chatManage' ? 'chatManageRoles'
        : capability === 'task' ? 'taskRoles'
          : 'calendarRoles'
  ];
  return Array.isArray(allowed) && allowed.includes(actor?.role);
}

/** Read server-owned policy in the caller's existing transaction. */
export async function readCollaborationPolicy(client, { familyId, forUpdate = false }) {
  const { rows } = await client.query(
    `SELECT family_id, chat_create_roles, chat_manage_roles, task_roles, calendar_roles,
            child_direct_enabled, child_groups_enabled,
            child_group_member_management_enabled, guardian_inclusion_mode,
            maximum_group_size, version, updated_by_membership_id, updated_at
       FROM family_collaboration_policies
      WHERE family_id = $1
      ${forUpdate ? 'FOR UPDATE' : ''}`,
    [familyId],
  );
  return collaborationPolicyView(rows[0] ?? null);
}

function persistedPolicy(policy) {
  return {
    chatCreateRoles: [...policy.chatCreateRoles],
    chatManageRoles: [...policy.chatManageRoles],
    taskRoles: [...policy.taskRoles],
    calendarRoles: [...policy.calendarRoles],
    childDirectEnabled: policy.childDirectEnabled,
    childGroupsEnabled: policy.childGroupsEnabled,
    childGroupMemberManagementEnabled: policy.childGroupMemberManagementEnabled,
    guardianInclusionMode: policy.guardianInclusionMode,
    maximumGroupSize: policy.maximumGroupSize,
  };
}

export function collaborationPolicyFor(store) {
  return {
    async read({ principal, familyId }) {
      return store.withTransaction(async (client) => {
        await store.activeActorMembership(client, familyId, principal.subject);
        return { policy: await readCollaborationPolicy(client, { familyId }) };
      });
    },

    async update({ principal, familyId, change, expectedVersion, correlationId }) {
      return store.withTransaction(async (client) => {
        const actor = await store.activeActorMembership(client, familyId, principal.subject);
        if (actor.role !== 'primary_guardian') {
          throw new CollaborationPolicyError(
            403,
            'collaboration_policy_forbidden',
            'Only the primary guardian may change family collaboration policy.',
          );
        }

        const current = await readCollaborationPolicy(client, { familyId, forUpdate: true });
        if (current.version !== expectedVersion) {
          throw new CollaborationPolicyError(
            409,
            'collaboration_policy_stale_version',
            'The family collaboration policy changed since it was read.',
          );
        }
        const next = persistedPolicy({ ...current, ...change });
        const nextVersion = current.version + 1;
        const { rows } = await client.query(
          `INSERT INTO family_collaboration_policies
             (family_id, chat_create_roles, chat_manage_roles, task_roles, calendar_roles,
              child_direct_enabled, child_groups_enabled,
              child_group_member_management_enabled, guardian_inclusion_mode,
              maximum_group_size, version, updated_by_membership_id, updated_at)
           VALUES ($1, $2::text[], $3::text[], $4::text[], $5::text[],
                   $6, $7, $8, $9, $10, $11, $12, NOW())
           ON CONFLICT (family_id) DO UPDATE SET
             chat_create_roles = EXCLUDED.chat_create_roles,
             chat_manage_roles = EXCLUDED.chat_manage_roles,
             task_roles = EXCLUDED.task_roles,
             calendar_roles = EXCLUDED.calendar_roles,
             child_direct_enabled = EXCLUDED.child_direct_enabled,
             child_groups_enabled = EXCLUDED.child_groups_enabled,
             child_group_member_management_enabled = EXCLUDED.child_group_member_management_enabled,
             guardian_inclusion_mode = EXCLUDED.guardian_inclusion_mode,
             maximum_group_size = EXCLUDED.maximum_group_size,
             version = EXCLUDED.version,
             updated_by_membership_id = EXCLUDED.updated_by_membership_id,
             updated_at = NOW()
           WHERE family_collaboration_policies.version = $13
           RETURNING family_id, chat_create_roles, chat_manage_roles, task_roles, calendar_roles,
                     child_direct_enabled, child_groups_enabled,
                     child_group_member_management_enabled, guardian_inclusion_mode,
                     maximum_group_size, version, updated_by_membership_id, updated_at`,
          [
            familyId,
            next.chatCreateRoles,
            next.chatManageRoles,
            next.taskRoles,
            next.calendarRoles,
            next.childDirectEnabled,
            next.childGroupsEnabled,
            next.childGroupMemberManagementEnabled,
            next.guardianInclusionMode,
            next.maximumGroupSize,
            nextVersion,
            actor.id,
            expectedVersion,
          ],
        );
        if (rows[0] == null) {
          throw new CollaborationPolicyError(
            409,
            'collaboration_policy_stale_version',
            'The family collaboration policy changed since it was read.',
          );
        }
        await store.appendAuditAndOutbox(client, {
          familyId,
          actorMembershipId: actor.id,
          correlationId,
          subjectId: familyId,
          subjectType: 'family_collaboration_policy',
          eventType: 'family.collaboration_policy_updated',
        });
        return { policy: collaborationPolicyView(rows[0]) };
      });
    },
  };
}
