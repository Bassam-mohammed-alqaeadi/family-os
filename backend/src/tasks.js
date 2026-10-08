// W7 — family tasks and points: the junction of protection and upbringing.
//
// The safety waves answer "what may this phone do". This one answers a harder question,
// because it is about a person rather than a device: what did this child earn, and who says
// so. A product that answers it carelessly does not merely look wrong - it teaches a child
// that claims are achievements and that an app decides what they are worth.
//
// So the laws are short, and each one exists because the opposite is how these products
// usually fail:
//
//   * A CLAIM IS NOT AN ACHIEVEMENT. The child's word makes a claim; only a guardian's
//     confirmation makes points. No function in this file can award points without an actor,
//     a moment and a confirmation.
//   * THE TASK NAMES THE NUMBER. `points` is read from the stored task and copied onto the
//     confirmation; it is never taken from the request body. A reward whose size the
//     rewarded party can choose is not a reward.
//   * ONE CONFIRMATION, ONE AWARD. The database holds UNIQUE (claim_id) on the ledger, and
//     this module turns its violation into a refusal rather than a second credit.
//   * A DECLINE AWARDS NOTHING - not less, not a negative. It is a decision with an author
//     and a reason, and the task stays open so tomorrow is possible.
//   * A BALANCE IS A SUM. Nothing here stores or caches a balance; it is computed from the
//     append-only ledger every time it is asked for, which is the only way it cannot drift.
//   * THE HANDSET IS THE PROOF OF WHICH CHILD. The device routes take no child id, because a
//     parameter a client supplies proves nothing.
//
// Everything below is either a pure function (testable without a socket) or a thin
// translation of one into SQL. No decision is duplicated in the route layer.

import { randomUUID } from 'node:crypto';

import { HttpError } from './http-error.js';
import {
  COLLABORATION_POLICY_DEFAULTS,
  collaborationRoleAllowed,
  readCollaborationPolicy as readServerCollaborationPolicy,
} from './collaboration-policy.js';

export const TASK_STATUSES = Object.freeze(['open', 'archived']);
export const CLAIM_STATUSES = Object.freeze(['pending', 'confirmed', 'declined']);

/// The only reasons this wave can write. Spending arrives with the minutes loop (W12) as a
/// new named reason - and with its own law - rather than by widening this list blindly.
export const POINT_ENTRY_REASONS = Object.freeze(['task_confirmed']);

export const TASK_POINTS_MIN = 1;
export const TASK_POINTS_MAX = 200;
export const TASK_TITLE_MAX = 120;
export const TASK_NOTE_MAX = 300;
export const CHILD_POINTS_CEILING = 100000;

/// A bound, not a target: a family with more open tasks than this for one child is far more
/// likely to be a bug in a loop than a household with that many chores.
export const MAX_OPEN_TASKS_PER_CHILD = 50;

export class TaskError extends HttpError {
  constructor(status, code, message) {
    super(status, code, message);
    this.name = 'TaskError';
  }
}

function requireGuardian(actor, code, message) {
  const policy = actor?.collaborationPolicy ?? COLLABORATION_POLICY_DEFAULTS;
  if (actor == null || !collaborationRoleAllowed(actor, policy, 'task')) {
    throw new TaskError(403, code, message);
  }
}

/// A title with the shape of a title: no leading or trailing whitespace, no runs of spaces,
/// and never empty. Two tasks that look identical on a screen but differ by an invisible
/// space are a bug a family would experience as "the app ignored what I typed".
export function normalizeTaskTitle(raw) {
  if (typeof raw !== 'string') {
    throw new TaskError(422, 'task_title_invalid', 'A task needs a title.');
  }
  const collapsed = raw.trim().replace(/\s+/g, ' ');
  if (collapsed.length === 0 || collapsed.length > TASK_TITLE_MAX) {
    throw new TaskError(422, 'task_title_invalid', 'A task needs a title.');
  }
  return collapsed;
}

export function normalizeTaskNote(raw) {
  if (raw == null) return '';
  if (typeof raw !== 'string') {
    throw new TaskError(422, 'task_note_invalid', 'A note is text.');
  }
  const trimmed = raw.trim();
  if (trimmed.length > TASK_NOTE_MAX) {
    throw new TaskError(422, 'task_note_invalid', 'A note is text.');
  }
  return trimmed;
}

/// The number of points a task states. Refused here rather than clamped: a screen that asked
/// for 500 and got 200 would be a screen that quietly rewrote a guardian's decision.
export function normalizeTaskPoints(raw) {
  const value = typeof raw === 'string' && raw.trim() !== '' ? Number(raw) : raw;
  if (!Number.isInteger(value) || value < TASK_POINTS_MIN || value > TASK_POINTS_MAX) {
    throw new TaskError(422, 'task_points_invalid', `Points must be a whole number between ${TASK_POINTS_MIN} and ${TASK_POINTS_MAX}.`);
  }
  return value;
}

export function taskStatusOf(row) {
  return typeof row?.status === 'string' ? row.status : 'open';
}

/// The task as a family reads it, with the cycle that is open on it.
export function taskView(row, latestClaim = null, { viewerChildId = null } = {}) {
  return {
    id: row.id,
    childId: row.child_id,
    audienceThreadId: row.audience_thread_id ?? null,
    canClaim: viewerChildId == null ? null : row.child_id === viewerChildId,
    title: row.title,
    note: row.note,
    points: row.points,
    status: taskStatusOf(row),
    createdByMembershipId: row.created_by_membership_id,
    createdAt: instant(row.created_at),
    updatedAt: instant(row.updated_at),
    claim: latestClaim == null ? null : claimView(latestClaim),
  };
}

export function claimView(row) {
  return {
    id: row.id,
    taskId: row.task_id,
    status: row.status,
    note: row.note,
    claimedByDeviceId: row.claimed_by_device_id ?? null,
    claimedByMembershipId: row.claimed_by_membership_id ?? null,
    decidedByMembershipId: row.decided_by_membership_id ?? null,
    decidedAt: row.decided_at == null ? null : instant(row.decided_at),
    decisionNote: row.decision_note ?? '',
    pointsAwarded: row.points_awarded ?? null,
    createdAt: instant(row.created_at),
  };
}

/// The balance, computed from entries and nothing else. The entries travel with the number
/// so a guardian reading "40 points" can always see which confirmations produced them.
export function pointsFromEntries(entries) {
  let total = 0;
  for (const entry of entries) total += entry.points;
  if (total > CHILD_POINTS_CEILING) {
    throw new TaskError(422, 'task_points_ceiling', 'This balance is outside what this build can state.');
  }
  return total;
}

export function pointEntryView(row) {
  return {
    id: row.id,
    points: row.points,
    reason: row.reason,
    claimId: row.claim_id ?? null,
    awardedByMembershipId: row.awarded_by_membership_id,
    createdAt: instant(row.created_at),
  };
}

export function pointsView(rows) {
  const entries = rows.map(pointEntryView);
  return { points: pointsFromEntries(entries), entries };
}

async function requireTaskThreadMember(port, tx, {
  familyId,
  task,
  childId,
  viewerKind,
  viewerId,
}) {
  const threadId = task.audience_thread_id;
  if (threadId == null) return;
  const thread = await port.readChatThread(tx, { familyId, threadId });
  if (thread == null || !['direct', 'group'].includes(thread.kind)) {
    throw new TaskError(404, 'task_not_found', 'This task is not available.');
  }
  const members = await port.listChatThreadMembers(tx, { threadId });
  const childIsMember = members.some(
    (member) => member.participant_kind === 'child' && member.participant_id === childId,
  );
  const viewerIsMember = members.some(
    (member) => member.participant_kind === viewerKind && member.participant_id === viewerId,
  );
  if (!childIsMember || !viewerIsMember) {
    throw new TaskError(404, 'task_not_found', 'This task is not available.');
  }
}

function instant(value) {
  return value instanceof Date ? value.toISOString() : value;
}

/// A guardian states a task for one child.
export function createTaskCreate({ port }) {
  return async function createFamilyTask({
    principal,
    familyId,
    childId,
    title,
    note = '',
    points,
    audienceThreadId = null,
    idempotencyKey,
    requestHash,
    correlationId,
  }) {
    return port.idempotent(
      `tasks:create:${familyId}:${childId}`,
      idempotencyKey,
      requestHash,
      async (tx) => {
        const actor = await port.authorize(tx, { familyId, subject: principal.subject });
        requireGuardian(actor, 'task_forbidden', 'Only a guardian may state a task.');
        const child = await port.readChild(tx, { familyId, childId });
        if (child == null) {
          throw new TaskError(404, 'child_not_found', 'This child is not part of the family.');
        }
        if (audienceThreadId != null) {
          const targetThread = await port.readChatThread(tx, { familyId, threadId: audienceThreadId });
          if (targetThread == null || !['direct', 'group'].includes(targetThread.kind)) {
            throw new TaskError(404, 'task_audience_not_found', 'This collaboration group is not available.');
          }
          const threadMembers = await port.listChatThreadMembers(tx, { threadId: audienceThreadId });
          const isCreatorMember = threadMembers.some(
            (member) => member.participant_kind === 'membership' && member.participant_id === actor.id,
          );
          const beneficiaryIncluded = threadMembers.some(
            (member) => member.participant_kind === 'child' && member.participant_id === childId,
          );
          if (!isCreatorMember || !beneficiaryIncluded) {
            throw new TaskError(404, 'task_audience_not_found', 'This collaboration group is not available.');
          }
        }
        const openCount = await port.countOpenTasks(tx, { familyId, childId });
        if (openCount >= MAX_OPEN_TASKS_PER_CHILD) {
          throw new TaskError(422, 'task_too_many_open', 'This child has more open tasks than a family can keep track of.');
        }
        const row = await port.insertTask(tx, {
          familyId,
          childId,
          title: normalizeTaskTitle(title),
          note: normalizeTaskNote(note),
          points: normalizeTaskPoints(points),
          audienceThreadId,
          createdByMembershipId: actor.id,
        });
        await port.audit(tx, {
          familyId,
          actorMembershipId: actor.id,
          correlationId,
          subjectId: childId,
          subjectType: 'family_task',
          eventType: 'family.task_created',
          payload: { childId, audienceThreadId: row.audience_thread_id ?? null },
        });
        return { task: taskView(row, null) };
      },
    );
  };
}

/// Everything this child has to do, newest first, each with the cycle that is open on it.
async function readTasksFor(port, tx, {
  familyId,
  childId,
  viewerKind,
  viewerId,
}) {
  const tasks = await port.listTasks(tx, {
    familyId,
    childId,
    viewerKind,
    viewerId,
  });
  const claims = await port.listClaims(tx, { familyId, childId });
  const latestByTask = new Map();
  // listClaims returns newest first, so the first claim seen for a task is its current cycle.
  for (const claim of claims) {
    if (!latestByTask.has(claim.task_id)) latestByTask.set(claim.task_id, claim);
  }
  return tasks.map((task) => taskView(task, latestByTask.get(task.id) ?? null, {
    viewerChildId: viewerKind === 'child' ? viewerId : null,
  }));
}

export function createTaskList({ port }) {
  return async function listFamilyTasks({ principal, familyId, childId }) {
    return port.read(async (tx) => {
      const actor = await port.authorize(tx, { familyId, subject: principal.subject });
      requireGuardian(actor, 'task_forbidden', 'Only a guardian may read these tasks.');
      const child = await port.readChild(tx, { familyId, childId });
      if (child == null) {
        throw new TaskError(404, 'child_not_found', 'This child is not part of the family.');
      }
      return {
        tasks: await readTasksFor(port, tx, {
          familyId,
          childId,
          viewerKind: 'membership',
          viewerId: actor.id,
        }),
      };
    });
  };
}

/// The child's own handset: its tasks, its balance, and the cycles on them. One read, because
/// on that phone it is one screen.
export function createDeviceTaskRead({ port }) {
  return async function readTasksForDevice({ deviceId, deviceCredential }) {
    return port.read(async (tx) => {
      const device = await requireDevice(port, tx, { deviceId, deviceCredential });
      const tasks = await readTasksFor(port, tx, {
        familyId: device.family_id,
        childId: device.child_id,
        viewerKind: 'child',
        viewerId: device.child_id,
      });
      const ledger = await port.readLedger(tx, { familyId: device.family_id, childId: device.child_id });
      return { tasks, ...pointsView(ledger) };
    });
  };
}

/// A guardian reads one child's balance and the ledger that produced it.
export function createPointLedgerRead({ port }) {
  return async function readChildPoints({ principal, familyId, childId }) {
    return port.read(async (tx) => {
      const actor = await port.authorize(tx, { familyId, subject: principal.subject });
      requireGuardian(actor, 'task_forbidden', 'Only a guardian may read these points.');
      const child = await port.readChild(tx, { familyId, childId });
      if (child == null) {
        throw new TaskError(404, 'child_not_found', 'This child is not part of the family.');
      }
      const ledger = await port.readLedger(tx, { familyId, childId });
      return pointsView(ledger);
    });
  };
}

/// "I did it." Said by the child's handset, or by a guardian for a child who spoke instead of
/// tapped - and recorded with its author, because "who said so" is the fact this whole wave
/// turns on.
export function createTaskClaim({ port }) {
  return async function claimFamilyTask({
    principal,
    deviceId,
    deviceCredential,
    familyId,
    childId,
    taskId,
    note = '',
    idempotencyKey,
    requestHash,
    correlationId,
  }) {
    return port.idempotent(
      `tasks:claim:${familyId ?? deviceId}:${taskId}`,
      idempotencyKey,
      requestHash,
      async (tx) => {
        // The device's credential decides the family and the child. A route that carries no
        // child id cannot be told whose task this is by a request; and the family is read
        // from the device row rather than taken from a path a caller could have written.
        let effectiveFamilyId = familyId;
        let effectiveChildId = childId;
        let claimerMembershipId = null;
        let claimerDeviceId = null;
        let claimerParticipantKind;
        let claimerParticipantId;
        if (deviceId != null) {
          const device = await requireDevice(port, tx, { deviceId, deviceCredential });
          effectiveFamilyId = device.family_id;
          effectiveChildId = device.child_id;
          claimerDeviceId = device.id;
          claimerParticipantKind = 'child';
          claimerParticipantId = device.child_id;
        } else {
          const actor = await port.authorize(tx, { familyId, subject: principal.subject });
          requireGuardian(actor, 'task_forbidden', "Only a guardian may claim on a child's behalf.");
          claimerMembershipId = actor.id;
          claimerParticipantKind = 'membership';
          claimerParticipantId = actor.id;
        }
        const task = await port.readTask(tx, { familyId: effectiveFamilyId, taskId }, { forUpdate: true });
        if (task == null || task.child_id !== effectiveChildId) {
          throw new TaskError(404, 'task_not_found', 'This task is not for this child.');
        }
        await requireTaskThreadMember(port, tx, {
          familyId: effectiveFamilyId,
          task,
          childId: effectiveChildId,
          viewerKind: claimerParticipantKind,
          viewerId: claimerParticipantId,
        });
        if (taskStatusOf(task) !== 'open') {
          throw new TaskError(409, 'task_archived', 'This task was withdrawn.');
        }
        const open = await port.readPendingClaim(tx, { taskId });
        if (open != null) {
          // The claim the child already made is the answer. A second press on the same button
          // is not a second claim, and a guardian will not receive a stack of them.
          throw new TaskError(409, 'task_claim_pending', 'This task is already waiting for a guardian.');
        }
        const row = await port.insertClaim(tx, {
          familyId: effectiveFamilyId,
          taskId,
          childId: effectiveChildId,
          note: normalizeTaskNote(note),
          claimedByDeviceId: claimerDeviceId,
          claimedByMembershipId: claimerMembershipId,
        });
        await port.audit(tx, {
          familyId: effectiveFamilyId,
          actorMembershipId: claimerMembershipId,
          correlationId,
          subjectId: effectiveChildId,
          subjectType: 'family_task_claim',
          eventType: 'family.task_claimed',
          payload: { childId: effectiveChildId, audienceThreadId: task.audience_thread_id ?? null }
        });
        return { claim: claimView(row) };
      },
    );
  };
}

/// The guardian's word: confirm it, and the points become real; decline it, and they do not.
///
/// The number of points is not a parameter of this function. It is read from the task, and
/// the confirmation copies it - so there is no code path, and no request body, through which
/// the size of a reward can be chosen by anyone other than the guardian who stated it.
export function createTaskDecision({ port }) {
  return async function decideFamilyTask({
    principal,
    familyId,
    childId,
    taskId,
    decision,
    note = '',
    idempotencyKey,
    requestHash,
    correlationId,
  }) {
    return port.idempotent(
      `tasks:decide:${familyId}:${taskId}`,
      idempotencyKey,
      requestHash,
      async (tx) => {
        const actor = await port.authorize(tx, { familyId, subject: principal.subject });
        requireGuardian(actor, 'task_forbidden', 'Only a guardian may answer a claim.');
        const task = await port.readTask(tx, { familyId, taskId }, { forUpdate: true });
        if (task == null || task.child_id !== childId) {
          throw new TaskError(404, 'task_not_found', 'This task is not for this child.');
        }
        await requireTaskThreadMember(port, tx, {
          familyId,
          task,
          childId,
          viewerKind: 'membership',
          viewerId: actor.id,
        });
        const pending = await port.readPendingClaim(tx, { taskId });
        if (pending == null) {
          throw new TaskError(409, 'task_claim_not_pending', 'There is no claim waiting on this task.');
        }
        const confirmed = decision === 'confirm';
        const decided = await port.decideClaim(tx, {
          claimId: pending.id,
          status: confirmed ? 'confirmed' : 'declined',
          decidedByMembershipId: actor.id,
          decisionNote: normalizeTaskNote(note),
          pointsAwarded: confirmed ? task.points : null,
        });
        let ledgerRow = null;
        if (confirmed) {
          // The unique index on claim_id is the last line of defence: if two confirmations
          // ever raced, one of them writes no entry at all rather than a second award.
          ledgerRow = await port.insertLedgerEntry(tx, {
            familyId,
            childId,
            points: task.points,
            reason: 'task_confirmed',
            claimId: decided.id,
            awardedByMembershipId: actor.id,
          });
          if (ledgerRow == null) {
            throw new TaskError(409, 'task_already_confirmed', 'This claim has already been rewarded.');
          }
        }
        await port.audit(tx, {
          familyId,
          actorMembershipId: actor.id,
          correlationId,
          subjectId: childId,
          subjectType: 'family_task_claim',
          eventType: confirmed ? 'family.task_confirmed' : 'family.task_declined',
          payload: { childId, audienceThreadId: task.audience_thread_id ?? null }
        });
        const ledger = await port.readLedger(tx, { familyId, childId });
        return {
          task: taskView(task, decided),
          points: pointsView(ledger),
          awarded: ledgerRow == null ? null : pointEntryView(ledgerRow),
        };
      },
    );
  };
}

/// The one way a device proves itself, used by every device route here.
async function requireDevice(port, tx, { deviceId, deviceCredential }) {
  const device = await port.readDevice(tx, { deviceId });
  if (
    device == null ||
    device.credential_revoked_at != null ||
    !port.credentialMatches(device.credential_hash, deviceCredential)
  ) {
    throw new TaskError(403, 'device_credential_rejected', 'The device credential is not accepted.');
  }
  return device;
}

export function tasksFor(store, { credentialMatches }) {
  const port = postgresTasksPort(store, { credentialMatches });
  return {
    createTask: createTaskCreate({ port }),
    listTasks: createTaskList({ port }),
    readPoints: createPointLedgerRead({ port }),
    claimTask: createTaskClaim({ port }),
    decideTask: createTaskDecision({ port }),
    readTasksForDevice: createDeviceTaskRead({ port }),
  };
}

const TASK_COLUMNS = `id, family_id, child_id, audience_thread_id, title, note, points, status,
                      created_by_membership_id, created_at, updated_at`;

const CLAIM_COLUMNS = `id, family_id, task_id, child_id, status, note,
                       claimed_by_device_id, claimed_by_membership_id,
                       decided_by_membership_id, decided_at, decision_note,
                       points_awarded, created_at`;

const LEDGER_COLUMNS = `id, family_id, child_id, points, reason, claim_id,
                        awarded_by_membership_id, created_at`;

export function postgresTasksPort(store, { credentialMatches }) {
  return {
    credentialMatches,

    async withTransaction(run) {
      return store.withTransaction(run);
    },

    async read(run) {
      return store.withTransaction(run);
    },

    async idempotent(scope, key, requestHash, work) {
      return store.withTransaction(async (client) => {
        const replay = await store.acquireIdempotencySlot(client, scope, key, requestHash);
        if (replay) return replay;
        const result = await work(client);
        await store.completeIdempotencySlot(client, scope, key, result);
        return result;
      });
    },

    async authorize(client, { familyId, subject }) {
      const actor = await store.activeActorMembership(client, familyId, subject);
      actor.collaborationPolicy = await readServerCollaborationPolicy(client, { familyId });
      return actor;
    },

    async readCollaborationPolicy(client, { familyId, forUpdate = false } = {}) {
      return readServerCollaborationPolicy(client, { familyId, forUpdate });
    },

    async readChild(client, { familyId, childId }) {
      const { rows } = await client.query(
        `SELECT id FROM family_children WHERE family_id = $1 AND id = $2`,
        [familyId, childId],
      );
      return rows[0] ?? null;
    },

    async readChatThread(client, { familyId, threadId }) {
      const { rows } = await client.query(
        `SELECT id, family_id, kind, next_seq FROM family_chat_threads
          WHERE family_id = $1 AND id = $2`,
        [familyId, threadId],
      );
      return rows[0] ?? null;
    },

    async listChatThreadMembers(client, { threadId }) {
      const { rows } = await client.query(
        `SELECT mem.participant_kind, mem.participant_id
           FROM family_chat_thread_members mem
           LEFT JOIN family_memberships membership ON membership.id = mem.membership_id
          WHERE mem.thread_id = $1 AND mem.left_at IS NULL
            AND (mem.participant_kind = 'child' OR membership.status = 'active')`,
        [threadId],
      );
      return rows;
    },

    async readDevice(client, { deviceId }) {
      const { rows } = await client.query(
        `SELECT id, family_id, child_id, device_label, credential_hash, credential_revoked_at
           FROM family_child_devices WHERE id = $1`,
        [deviceId],
      );
      return rows[0] ?? null;
    },

    async countOpenTasks(client, { familyId, childId }) {
      const { rows } = await client.query(
        `SELECT COUNT(*)::int AS open FROM family_tasks
          WHERE family_id = $1 AND child_id = $2 AND status = 'open'`,
        [familyId, childId],
      );
      return rows[0]?.open ?? 0;
    },

    async insertTask(client, { familyId, childId, audienceThreadId, title, note, points, createdByMembershipId }) {
      const { rows } = await client.query(
        `INSERT INTO family_tasks
           (id, family_id, child_id, audience_thread_id, title, note, points, created_by_membership_id)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
         RETURNING ${TASK_COLUMNS}`,
        [randomUUID(), familyId, childId, audienceThreadId, title, note, points, createdByMembershipId],
      );
      return rows[0];
    },

    async readTask(client, { familyId, taskId }, { forUpdate = false } = {}) {
      const { rows } = await client.query(
        `SELECT ${TASK_COLUMNS} FROM family_tasks
          WHERE id = $1 AND family_id = $2
          ${forUpdate ? 'FOR UPDATE' : ''}`,
        [taskId, familyId],
      );
      return rows[0] ?? null;
    },

    async listTasks(client, { familyId, childId, viewerKind, viewerId }) {
      const { rows } = await client.query(
        `SELECT task.* FROM family_tasks task
          WHERE task.family_id = $1
            AND (
              (task.audience_thread_id IS NULL AND task.child_id = $2)
              OR (
                task.audience_thread_id IS NOT NULL
                AND task.child_id = $2
                AND EXISTS (
                  SELECT 1 FROM family_chat_thread_members target_child
                   WHERE target_child.thread_id = task.audience_thread_id
                     AND target_child.family_id = task.family_id
                     AND target_child.participant_kind = 'child'
                     AND target_child.participant_id = $2
                     AND target_child.left_at IS NULL
                )
                AND EXISTS (
                  SELECT 1
                    FROM family_chat_thread_members viewer
                    LEFT JOIN family_memberships viewer_membership
                      ON viewer_membership.id = viewer.membership_id
                   WHERE viewer.thread_id = task.audience_thread_id
                     AND viewer.family_id = task.family_id
                     AND viewer.participant_kind = $3
                     AND viewer.participant_id = $4
                     AND viewer.left_at IS NULL
                     AND (viewer.participant_kind = 'child' OR viewer_membership.status = 'active')
                )
              )
            )
          ORDER BY task.created_at DESC, task.id DESC`,
        [familyId, childId, viewerKind, viewerId],
      );
      return rows;
    },

    async listClaims(client, { familyId, childId }) {
      const { rows } = await client.query(
        `SELECT ${CLAIM_COLUMNS} FROM family_task_claims
          WHERE family_id = $1 AND child_id = $2
          ORDER BY created_at DESC, id DESC`,
        [familyId, childId],
      );
      return rows;
    },

    async readPendingClaim(client, { taskId }) {
      const { rows } = await client.query(
        `SELECT ${CLAIM_COLUMNS} FROM family_task_claims
          WHERE task_id = $1 AND status = 'pending'`,
        [taskId],
      );
      return rows[0] ?? null;
    },

    async insertClaim(client, {
      familyId,
      taskId,
      childId,
      note,
      claimedByDeviceId,
      claimedByMembershipId,
    }) {
      const { rows } = await client.query(
        `INSERT INTO family_task_claims
           (id, family_id, task_id, child_id, status, note,
            claimed_by_device_id, claimed_by_membership_id)
         VALUES ($1, $2, $3, $4, 'pending', $5, $6, $7)
         RETURNING ${CLAIM_COLUMNS}`,
        [randomUUID(), familyId, taskId, childId, note, claimedByDeviceId, claimedByMembershipId],
      );
      return rows[0];
    },

    async decideClaim(client, { claimId, status, decidedByMembershipId, decisionNote, pointsAwarded }) {
      const { rows } = await client.query(
        `UPDATE family_task_claims
            SET status = $2,
                decided_by_membership_id = $3,
                decided_at = NOW(),
                decision_note = $4,
                points_awarded = $5
          WHERE id = $1 AND status = 'pending'
          RETURNING ${CLAIM_COLUMNS}`,
        [claimId, status, decidedByMembershipId, decisionNote, pointsAwarded],
      );
      if (rows[0] == null) {
        throw new TaskError(409, 'task_claim_already_answered', 'This claim has already been answered.');
      }
      return rows[0];
    },

    /// Returns null when the claim already produced an entry. The caller turns that into a
    /// refusal - never into a second credit.
    async insertLedgerEntry(client, { familyId, childId, points, reason, claimId, awardedByMembershipId }) {
      const { rows } = await client.query(
        `INSERT INTO family_point_ledger
           (id, family_id, child_id, points, reason, claim_id, awarded_by_membership_id)
         VALUES ($1, $2, $3, $4, $5, $6, $7)
         ON CONFLICT (claim_id) DO NOTHING
         RETURNING ${LEDGER_COLUMNS}`,
        [randomUUID(), familyId, childId, points, reason, claimId, awardedByMembershipId],
      );
      return rows[0] ?? null;
    },

    async readLedger(client, { familyId, childId }) {
      const { rows } = await client.query(
        `SELECT ${LEDGER_COLUMNS} FROM family_point_ledger
          WHERE family_id = $1 AND child_id = $2
          ORDER BY created_at DESC, id DESC`,
        [familyId, childId],
      );
      return rows;
    },

    async audit(client, {
      familyId,
      actorMembershipId,
      correlationId,
      subjectId,
      subjectType,
      eventType,
      payload = {},
    }) {
      await store.appendAuditAndOutbox(client, {
        familyId,
        actorMembershipId,
        correlationId,
        subjectId,
        subjectType,
        eventType,
        payload,
      });
    },
  };
}
