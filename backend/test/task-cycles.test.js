// W7 — the laws of family tasks and points, as pure functions and as factories over a
// recording port.
//
// No database and no socket, on purpose: a rule that can only be checked through a network
// round trip is a rule nobody checks before pushing. What is being defended, in one line
// each:
//
//   * a claim is not an achievement - only a guardian's confirmation writes a ledger entry;
//   * the number of points comes from the stored task and is never read from a request;
//   * a decline awards nothing at all: not less, and not a negative;
//   * one confirmation, one award - a second insert for the same claim is refused;
//   * one pending claim per task, and no claim at all on a withdrawn task;
//   * a balance is a sum over the ledger, never a stored number.
import assert from 'node:assert/strict';
import test from 'node:test';

import {
  MAX_OPEN_TASKS_PER_CHILD,
  TaskError,
  claimView,
  createTaskClaim,
  createTaskCreate,
  createTaskDecision,
  normalizeTaskPoints,
  normalizeTaskTitle,
  pointEntryView,
  pointsFromEntries,
  pointsView,
  taskView,
} from '../src/tasks.js';

const FAMILY = '11111111-1111-4111-8111-111111111111';
const CHILD = '22222222-2222-4222-8222-222222222222';
const OTHER_CHILD = '33333333-3333-4333-8333-333333333333';
const TASK = '44444444-4444-4444-8444-444444444444';
const CLAIM = '55555555-5555-4555-8555-555555555555';
const GUARDIAN_MEMBERSHIP = '66666666-6666-4666-8666-666666666666';
const DEVICE = '77777777-7777-4777-8777-777777777777';
const CO_GUARDIAN = '88888888-8888-4888-8888-888888888888';

const guardianActor = { id: GUARDIAN_MEMBERSHIP, role: 'primary_guardian' };
const childActor = { id: CO_GUARDIAN, role: 'child' };

function taskRow(overrides = {}) {
  return {
    id: TASK,
    family_id: FAMILY,
    child_id: CHILD,
    title: 'ترتيب الغرفة',
    note: 'الملابس في الخزانة',
    points: 15,
    status: 'open',
    created_by_membership_id: GUARDIAN_MEMBERSHIP,
    created_at: new Date('2026-10-08T06:00:00.000Z'),
    updated_at: new Date('2026-10-08T06:00:00.000Z'),
    ...overrides,
  };
}

function claimRow(overrides = {}) {
  return {
    id: CLAIM,
    family_id: FAMILY,
    task_id: TASK,
    child_id: CHILD,
    status: 'pending',
    note: 'خلصت',
    claimed_by_device_id: DEVICE,
    claimed_by_membership_id: null,
    decided_by_membership_id: null,
    decided_at: null,
    decision_note: '',
    points_awarded: null,
    created_at: new Date('2026-10-08T07:00:00.000Z'),
    ...overrides,
  };
}

/// A port that records what it was asked to do, so a test can assert on the CALL rather than
/// on a value - which is the only way to prove that, for instance, a decline never writes to
/// the ledger at all.
/// The device every test uses unless it is testing the credential itself: a handset that
/// was paired to this child and whose credential has not been revoked.
const pairedDevice = () => ({
  id: DEVICE,
  family_id: FAMILY,
  child_id: CHILD,
  credential_hash: 'device-credential-value',
  credential_revoked_at: null,
});

function recordingPort({ task = taskRow(), pendingClaim = null, actor = guardianActor, device = pairedDevice(), ledger = [] } = {}) {
  const calls = { ledger: [], audit: [], decided: [], claims: [] };
  return {
    calls,
    port: {
      credentialMatches: (hash, credential) => hash === credential && hash != null,
      async read(run) {
        return run({});
      },
      async withTransaction(run) {
        return run({});
      },
      async idempotent(_scope, _key, _hash, work) {
        return work({});
      },
      async authorize() {
        return actor;
      },
      async readChild() {
        return { id: CHILD };
      },
      async readDevice() {
        return device;
      },
      async countOpenTasks() {
        return 0;
      },
      async insertTask(_client, input) {
        return taskRow({ ...input, id: TASK });
      },
      async readTask() {
        return task;
      },
      async listTasks() {
        return [task];
      },
      async listClaims() {
        return pendingClaim == null ? [] : [pendingClaim];
      },
      async readPendingClaim() {
        return pendingClaim;
      },
      async insertClaim(_client, input) {
        calls.claims.push(input);
        return claimRow({ ...input, id: CLAIM, status: 'pending' });
      },
      async decideClaim(_client, input) {
        calls.decided.push(input);
        return claimRow({
          status: input.status,
          decided_by_membership_id: input.decidedByMembershipId,
          decided_at: new Date('2026-10-08T08:00:00.000Z'),
          decision_note: input.decisionNote,
          points_awarded: input.pointsAwarded,
        });
      },
      async insertLedgerEntry(_client, input) {
        calls.ledger.push(input);
        return {
          id: '99999999-9999-4999-8999-999999999999',
          family_id: input.familyId,
          child_id: input.childId,
          points: input.points,
          reason: input.reason,
          claim_id: input.claimId,
          awarded_by_membership_id: input.awardedByMembershipId,
          created_at: new Date('2026-10-08T08:00:00.000Z'),
        };
      },
      async readLedger() {
        return ledger;
      },
      async audit(_client, input) {
        calls.audit.push(input);
      },
    },
  };
}

// ── the title and the number ──────────────────────────────────────────────────────────

test('a title is read the way a person typed it, and an empty one is not a task', () => {
  assert.equal(normalizeTaskTitle('  ترتيب   الغرفة  '), 'ترتيب الغرفة');
  assert.equal(normalizeTaskTitle('Tidy the room'), 'Tidy the room');
  assert.throws(() => normalizeTaskTitle('   '), (error) => error.code === 'task_title_invalid');
  assert.throws(() => normalizeTaskTitle('x'.repeat(121)), (error) => error.code === 'task_title_invalid');
  assert.throws(() => normalizeTaskTitle(42), (error) => error.code === 'task_title_invalid');
});

test('points are a whole number in range, refused rather than clamped', () => {
  // The refusal is the point. A screen that asked for 500 points and was handed 200 would be
  // a screen that quietly rewrote a guardian's decision.
  assert.equal(normalizeTaskPoints(15), 15);
  assert.equal(normalizeTaskPoints('15'), 15);
  for (const bad of [0, -5, 201, 1.5, 'abc', null, undefined, NaN]) {
    assert.throws(
      () => normalizeTaskPoints(bad),
      (error) => error instanceof TaskError && error.code === 'task_points_invalid',
      `expected ${String(bad)} to be refused`,
    );
  }
});

// ── the balance is a sum, and nothing else ────────────────────────────────────────────

test('a balance is the sum of its entries, and the entries travel with it', () => {
  const entries = [
    pointEntryView({ id: 'a', points: 15, reason: 'task_confirmed', claim_id: CLAIM, awarded_by_membership_id: GUARDIAN_MEMBERSHIP, created_at: new Date('2026-10-08T08:00:00.000Z') }),
    pointEntryView({ id: 'b', points: 5, reason: 'task_confirmed', claim_id: 'cccccccc-cccc-4ccc-8ccc-cccccccccccc', awarded_by_membership_id: GUARDIAN_MEMBERSHIP, created_at: new Date('2026-10-08T09:00:00.000Z') }),
  ];
  assert.equal(pointsFromEntries(entries), 20);
  const view = pointsView([
    { id: 'a', points: 15, reason: 'task_confirmed', claim_id: CLAIM, awarded_by_membership_id: GUARDIAN_MEMBERSHIP, created_at: new Date('2026-10-08T08:00:00.000Z') },
    { id: 'b', points: 5, reason: 'task_confirmed', claim_id: 'cccccccc-cccc-4ccc-8ccc-cccccccccccc', awarded_by_membership_id: GUARDIAN_MEMBERSHIP, created_at: new Date('2026-10-08T09:00:00.000Z') },
  ]);
  assert.equal(view.points, 20);
  assert.equal(view.entries.length, 2, 'the number is answerable: these are the entries behind it');
  assert.equal(pointsFromEntries([]), 0, 'earned nothing is zero, not an error');
});

// ── the task view says "nobody has said anything" differently from "claimed" ──────────

test('a task nobody has touched carries a null claim, not an empty one', () => {
  const view = taskView(taskRow(), null);
  assert.equal(view.claim, null);
  assert.equal(view.points, 15);
  assert.equal(view.status, 'open');
  const claimed = taskView(taskRow(), claimRow());
  assert.equal(claimed.claim.status, 'pending');
  assert.equal(claimed.claim.claimedByDeviceId, DEVICE);
  assert.equal(claimed.claim.pointsAwarded, null, 'a pending claim has awarded nothing yet');
});

// ── a claim is not an achievement ─────────────────────────────────────────────────────

test('claiming a task writes no points at all', async () => {
  const { port, calls } = recordingPort({ pendingClaim: null });
  const claim = createTaskClaim({ port });
  const result = await claim({
    deviceId: DEVICE,
    deviceCredential: 'device-credential-value',
    taskId: TASK,
    note: 'خلصت',
    idempotencyKey: 'k1',
    requestHash: 'h1',
  });
  assert.equal(result.claim.status, 'pending');
  assert.equal(calls.ledger.length, 0, 'the child\'s word never reaches the ledger');
  assert.equal(calls.claims[0].claimedByDeviceId, DEVICE);
  assert.equal(calls.claims[0].claimedByMembershipId, null);
  assert.equal(calls.audit.at(-1).eventType, 'family.task_claimed');
});

test('the child\'s handset proves which child, so a body cannot name another', async () => {
  const { port, calls } = recordingPort({
    pendingClaim: null,
  });
  const claim = createTaskClaim({ port });
  await claim({
    deviceId: DEVICE,
    deviceCredential: 'device-credential-value',
    // The route for a device carries no child id; even if a caller invents one, the device
    // decides whose task this is.
    childId: OTHER_CHILD,
    taskId: TASK,
    idempotencyKey: 'k2',
    requestHash: 'h2',
  });
  assert.equal(calls.claims[0].childId, CHILD);
});

test('a second claim on the same task is refused, not queued', async () => {
  const { port, calls } = recordingPort({ pendingClaim: claimRow() });
  const claim = createTaskClaim({ port });
  await assert.rejects(
    () => claim({ deviceId: DEVICE, deviceCredential: 'device-credential-value', taskId: TASK, idempotencyKey: 'k3', requestHash: 'h3' }),
    (error) => error instanceof TaskError && error.code === 'task_claim_pending',
  );
  assert.equal(calls.claims.length, 0);
});

test('a withdrawn task cannot be claimed', async () => {
  const { port } = recordingPort({ task: taskRow({ status: 'archived' }) });
  const claim = createTaskClaim({ port });
  await assert.rejects(
    () => claim({ deviceId: DEVICE, deviceCredential: 'device-credential-value', taskId: TASK, idempotencyKey: 'k4', requestHash: 'h4' }),
    (error) => error.code === 'task_archived',
  );
});

// ── the guardian's word decides, and the task names the number ────────────────────────

test('confirming copies the number from the task, whatever the caller might have sent', async () => {
  const { port, calls } = recordingPort({ pendingClaim: claimRow() });
  const decide = createTaskDecision({ port });
  const result = await decide({
    principal: { subject: 'test-primary' },
    familyId: FAMILY,
    childId: CHILD,
    taskId: TASK,
    decision: 'confirm',
    note: '',
    idempotencyKey: 'k5',
    requestHash: 'h5',
  });
  assert.equal(calls.ledger.length, 1);
  assert.equal(calls.ledger[0].points, 15, 'the task says fifteen; nothing else was consulted');
  assert.equal(calls.ledger[0].reason, 'task_confirmed');
  assert.equal(calls.ledger[0].claimId, CLAIM);
  assert.equal(result.awarded.points, 15);
  assert.equal(result.task.claim.status, 'confirmed');
  assert.equal(calls.audit.at(-1).eventType, 'family.task_confirmed');
});

test('a decline awards nothing at all - no entry, no negative, and the task stays open', async () => {
  const { port, calls } = recordingPort({ pendingClaim: claimRow() });
  const decide = createTaskDecision({ port });
  const result = await decide({
    principal: { subject: 'test-primary' },
    familyId: FAMILY,
    childId: CHILD,
    taskId: TASK,
    decision: 'decline',
    note: 'الملابس ما زالت على الأرض',
    idempotencyKey: 'k6',
    requestHash: 'h6',
  });
  assert.equal(calls.ledger.length, 0, 'a refusal writes nothing anywhere');
  assert.equal(calls.decided[0].pointsAwarded, null);
  assert.equal(result.awarded, null);
  assert.equal(result.task.claim.status, 'declined');
  assert.equal(result.task.claim.pointsAwarded, null);
  assert.equal(calls.audit.at(-1).eventType, 'family.task_declined');
});

test('a claim that already produced an entry cannot produce a second one', async () => {
  // The database index is the last line of defence; this proves the module turns its
  // violation into a refusal rather than into a second credit.
  const { port } = recordingPort({ pendingClaim: claimRow() });
  port.insertLedgerEntry = async () => null;
  const decide = createTaskDecision({ port });
  await assert.rejects(
    () => decide({
      principal: { subject: 'test-primary' },
      familyId: FAMILY,
      childId: CHILD,
      taskId: TASK,
      decision: 'confirm',
      idempotencyKey: 'k7',
      requestHash: 'h7',
    }),
    (error) => error.code === 'task_already_confirmed',
  );
});

test('answering nothing is refused, and so is answering twice', async () => {
  const { port } = recordingPort({ pendingClaim: null });
  const decide = createTaskDecision({ port });
  await assert.rejects(
    () => decide({ principal: { subject: 'test-primary' }, familyId: FAMILY, childId: CHILD, taskId: TASK, decision: 'confirm', idempotencyKey: 'k8', requestHash: 'h8' }),
    (error) => error.code === 'task_claim_not_pending',
  );
});

test('a task that is not this child\'s is not found, not silently answered', async () => {
  const { port } = recordingPort({ task: taskRow({ child_id: OTHER_CHILD }), pendingClaim: claimRow({ child_id: OTHER_CHILD }) });
  const decide = createTaskDecision({ port });
  await assert.rejects(
    () => decide({ principal: { subject: 'test-primary' }, familyId: FAMILY, childId: CHILD, taskId: TASK, decision: 'confirm', idempotencyKey: 'k9', requestHash: 'h9' }),
    (error) => error.code === 'task_not_found',
  );
});

// ── a child cannot reward themselves, and a guardian cannot exceed the bound ──────────

test('a child may not state a task, and may not answer one', async () => {
  const { port } = recordingPort({ actor: childActor });
  const create = createTaskCreate({ port });
  await assert.rejects(
    () => create({ principal: { subject: 'test-child' }, familyId: FAMILY, childId: CHILD, title: 'x', points: 5, idempotencyKey: 'k10', requestHash: 'h10' }),
    (error) => error.code === 'task_forbidden',
  );
  const decide = createTaskDecision({ port });
  await assert.rejects(
    () => decide({ principal: { subject: 'test-child' }, familyId: FAMILY, childId: CHILD, taskId: TASK, decision: 'confirm', idempotencyKey: 'k11', requestHash: 'h11' }),
    (error) => error.code === 'task_forbidden',
  );
});

test('a guardian states a task, and the stored row is exactly what was stated', async () => {
  const { port, calls } = recordingPort();
  const create = createTaskCreate({ port });
  const result = await create({
    principal: { subject: 'test-primary' },
    familyId: FAMILY,
    childId: CHILD,
    title: '  ترتيب    الغرفة ',
    note: ' الملابس في الخزانة ',
    points: 15,
    idempotencyKey: 'k12',
    requestHash: 'h12',
  });
  assert.equal(result.task.title, 'ترتيب الغرفة');
  assert.equal(result.task.note, 'الملابس في الخزانة');
  assert.equal(result.task.points, 15);
  assert.equal(calls.audit.at(-1).eventType, 'family.task_created');
});

test('the bound on open tasks is a refusal, not a silent trim', async () => {
  const { port } = recordingPort();
  port.countOpenTasks = async () => MAX_OPEN_TASKS_PER_CHILD;
  const create = createTaskCreate({ port });
  await assert.rejects(
    () => create({ principal: { subject: 'test-primary' }, familyId: FAMILY, childId: CHILD, title: 'x', points: 5, idempotencyKey: 'k13', requestHash: 'h13' }),
    (error) => error.code === 'task_too_many_open',
  );
});

// ── the claim view never invents a number ─────────────────────────────────────────────

test('a confirmed claim reports the number it was confirmed as, even if the task changed', () => {
  const view = claimView(claimRow({ status: 'confirmed', points_awarded: 15, decided_by_membership_id: GUARDIAN_MEMBERSHIP, decided_at: new Date('2026-10-08T08:00:00.000Z') }));
  assert.equal(view.pointsAwarded, 15);
  assert.equal(view.decidedByMembershipId, GUARDIAN_MEMBERSHIP);
  assert.equal(claimView(claimRow()).decidedAt, null);
});
