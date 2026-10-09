// W8 — the laws of the family calendar, as pure functions and as factories over a
// recording port.
//
// No database and no socket, on purpose, for the same reason as W7: a rule that can only be
// checked through a network round trip is a rule nobody checks before pushing. This wave has
// one more reason to keep the laws cheap to run, because it is the first one whose subject is
// people rather than devices, and the cheapest place to keep a product honest about people is
// in a function with no escape hatch. What is being defended, in one line each:
//
//   * an event is cancelled, never deleted - the author, the reason and the moment survive;
//   * an edit states the version it read, so two guardians collide loudly instead of silently;
//   * the audience is written in the same transaction as the event, so nobody can ever read a
//     plan that nobody was invited to;
//   * an answer has exactly one author: a handset answers for its own child, a guardian
//     answers for a child they name, and neither can pretend to be the other;
//   * a handset cannot answer for a sibling - the child comes from the device row;
//   * a "no" is stored as completely as a "yes", and answering ends when the event starts;
//   * attendance is a fact recorded by a person after the fact, never inferred and never
//     pre-written;
//   * a reminder is a preference that was recorded, not a delivery that happened.
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import test from 'node:test';

import { capabilityMatches } from '../src/store/postgres-foundation-store.js';
import {
  CalendarError,
  attendanceView,
  childEventView,
  createAttendanceRecord,
  createDeviceEventRead,
  createEventCancel,
  createEventCreate,
  createEventList,
  createEventResponseRecord,
  createEventUpdate,
  eventView,
  expectedVersion,
  normalizeRange,
  postgresCalendarPort,
  requireRecordableAt,
  responseView,
} from '../src/calendar.js';

const FAMILY = '11111111-1111-4111-8111-111111111111';
const CHILD = '22222222-2222-4222-8222-222222222222';
const SIBLING = '33333333-3333-4333-8333-333333333333';
const EVENT = '44444444-4444-4444-8444-444444444444';
const CHAT_THREAD = '55555555-5555-4555-8555-555555555555';
const SCOPED_EVENT = '99999999-9999-4999-8999-999999999999';
const GUARDIAN_MEMBERSHIP = '66666666-6666-4666-8666-666666666666';
const CO_GUARDIAN_MEMBERSHIP = '77777777-7777-4777-8777-777777777777';
const DEVICE = '88888888-8888-4888-8888-888888888888';

const NOW = new Date('2026-10-08T09:00:00.000Z');
const STARTS = '2026-10-09T15:00:00.000Z';
const ENDS = '2026-10-09T17:00:00.000Z';

const guardianActor = { id: GUARDIAN_MEMBERSHIP, role: 'primary_guardian' };
const coGuardianActor = { id: CO_GUARDIAN_MEMBERSHIP, role: 'co_guardian' };
const childActor = { id: '99999999-9999-4999-8999-999999999999', role: 'child' };

function eventRow(overrides = {}) {
  return {
    id: EVENT,
    family_id: FAMILY,
    audience_thread_id: null,
    title: 'زيارة الجدّ',
    note: 'نأخذ الكيك',
    location: 'بيت الجدّ',
    starts_at: new Date(STARTS),
    ends_at: new Date(ENDS),
    all_day: false,
    reminder_minutes: 60,
    status: 'scheduled',
    version: 1,
    created_by_membership_id: GUARDIAN_MEMBERSHIP,
    cancelled_by_membership_id: null,
    cancelled_at: null,
    cancel_reason: null,
    created_at: new Date('2026-10-08T08:00:00.000Z'),
    updated_at: new Date('2026-10-08T08:00:00.000Z'),
    ...overrides,
  };
}

function responseRow(overrides = {}) {
  return {
    id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    family_id: FAMILY,
    event_id: EVENT,
    child_id: CHILD,
    response: 'accepted',
    note: '',
    responded_by_device_id: DEVICE,
    responded_by_membership_id: null,
    created_at: new Date('2026-10-08T10:00:00.000Z'),
    updated_at: new Date('2026-10-08T10:00:00.000Z'),
    ...overrides,
  };
}

function attendanceRow(overrides = {}) {
  return {
    id: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
    family_id: FAMILY,
    event_id: EVENT,
    child_id: CHILD,
    attended: true,
    note: '',
    recorded_by_membership_id: GUARDIAN_MEMBERSHIP,
    recorded_at: new Date('2026-10-09T18:00:00.000Z'),
    ...overrides,
  };
}

const DEVICE_CREDENTIAL = 'device-credential-value';
const credentialHash = (value) => createHash('sha256').update(value).digest('hex');

/// The handset of the child in every test unless the test is about the credential itself.
const pairedDevice = () => ({
  id: DEVICE,
  family_id: FAMILY,
  child_id: CHILD,
  credential_hash: credentialHash(DEVICE_CREDENTIAL),
  credential_revoked_at: null,
});

/// A port that records what it was asked to do, so a test can assert on the CALL and not only
/// on a value. That is the only way to prove, for instance, that cancelling never deletes the
/// audience - which is a claim about which statements were issued, not about what came back.
function recordingPort({
  event = eventRow(),
  events = null,
  audience = [{ family_id: FAMILY, event_id: EVENT, child_id: CHILD }],
  responses = [],
  attendance = [],
  actor = guardianActor,
  device = pairedDevice(),
  answeredChildren = new Set(),
  childExists = true,
  chatThread = null,
  chatMembers = [],
} = {}) {
  const calls = {
    events: [],
    audiences: [],
    deletedAudiences: 0,
    responses: [],
    attendance: [],
    cancellations: [],
    audits: [],
    idempotency: [],
    eventListQueries: [],
  };
  // The audience in the fake behaves the way the table does: an edit replaces it, a deletion
  // empties it. A mock that kept returning the old rows would let a broken update pass.
  let currentAudience = audience;
  return {
    calls,
    port: {
      // Deliberately asymmetric, because the real comparison is: the stored digest is
      // checked against the digest of what the handset presented. A symmetric fake would
      // accept a reversed call order, which is precisely the bug this gate exists to catch.
      credentialMatches: (hash, credential) =>
        typeof credential === 'string' &&
        typeof hash === 'string' &&
        hash === credentialHash(credential),
      async read(run) {
        return run({});
      },
      async withTransaction(run) {
        return run({});
      },
      async idempotent(scope, key, hash, work) {
        calls.idempotency.push({ scope, key, hash });
        return work({});
      },
      async authorize() {
        return actor;
      },
      async readChild() {
        return childExists ? { id: CHILD } : null;
      },
      async requireDevice(_client, { deviceCredential }) {
        if (
          device == null ||
          device.credential_revoked_at != null ||
          !this.credentialMatches(device.credential_hash, deviceCredential)
        ) {
          throw new CalendarError(403, 'device_credential_rejected', 'This device credential is not accepted.');
        }
        return device;
      },
      async insertEvent(_client, input) {
        calls.events.push(input);
        return eventRow({
          ...input,
          id: EVENT,
          audience_thread_id: input.audienceThreadId ?? null,
          version: 1,
        });
      },
      async readChatThread(_client, { familyId, threadId }) {
        return chatThread?.family_id === familyId && chatThread?.id === threadId
          ? chatThread
          : null;
      },
      async listChatThreadMembers() {
        return chatMembers;
      },
      async readEvent() {
        return event;
      },
      async listEvents(_client, input) {
        calls.eventListQueries.push(input);
        return (events ?? [event]).filter((row) =>
          row.audience_thread_id == null || (
            chatThread?.id === row.audience_thread_id
            && chatMembers.some(
              (member) => member.participant_kind === 'membership'
                && member.participant_id === input.viewerMembershipId,
            )
            && currentAudience.some((entry) =>
              entry.event_id === row.id && chatMembers.some(
                (member) => member.participant_kind === 'child'
                  && member.participant_id === entry.child_id,
              ),
            )
          ),
        );
      },
      async updateEvent(_client, input) {
        calls.events.push(input);
        return eventRow({
          ...input,
          audience_thread_id: input.audienceThreadId ?? null,
          version: Number(event.version) + 1,
        });
      },
      async cancelEvent(_client, input) {
        calls.cancellations.push(input);
        return eventRow({
          status: 'cancelled',
          cancelled_by_membership_id: input.cancelledByMembershipId,
          cancelled_at: new Date('2026-10-08T11:00:00.000Z'),
          cancel_reason: input.cancelReason,
          version: Number(event.version) + 1,
        });
      },
      async insertAudience(_client, input) {
        calls.audiences.push(input);
        const rows = input.childIds.map((childId) => ({ family_id: FAMILY, event_id: input.eventId, child_id: childId }));
        currentAudience = event == null ? currentAudience : [...currentAudience.filter((entry) => entry.event_id !== input.eventId), ...rows];
        return rows;
      },
      async listAudience(_client, { viewerMembershipId = null } = {}) {
        if (viewerMembershipId == null) return currentAudience;
        return currentAudience.filter((entry) => {
          const row = (events ?? [event]).find((candidate) => candidate.id === entry.event_id);
          if (row?.audience_thread_id == null) return true;
          return chatThread?.id === row.audience_thread_id
            && chatMembers.some((member) =>
              member.participant_kind === 'membership'
              && member.participant_id === viewerMembershipId,
            )
            && chatMembers.some((member) =>
              member.participant_kind === 'child'
              && member.participant_id === entry.child_id,
            );
        });
      },
      async readAudience(_client, { eventId, childId }) {
        return currentAudience.some((entry) => entry.event_id === eventId && entry.child_id === childId)
          ? { family_id: FAMILY, event_id: eventId, child_id: childId }
          : null;
      },
      async deleteAudience() {
        calls.deletedAudiences += 1;
        currentAudience = [];
      },
      async audienceAnswerCount(_client, { childId }) {
        return answeredChildren.has(childId) ? 1 : 0;
      },
      async listResponses() {
        return responses;
      },
      async listResponsesForChild() {
        return responses.filter((row) => row.child_id === device.child_id);
      },
      async upsertResponse(_client, input) {
        calls.responses.push(input);
        return responseRow({
          child_id: input.childId,
          response: input.response,
          note: input.note,
          responded_by_device_id: input.respondedByDeviceId,
          responded_by_membership_id: input.respondedByMembershipId,
        });
      },
      async listAttendance() {
        return attendance;
      },
      async listAttendanceForChild() {
        return attendance.filter((row) => row.child_id === device.child_id);
      },
      async upsertAttendance(_client, input) {
        calls.attendance.push(input);
        return attendanceRow({
          child_id: input.childId,
          attended: input.attended,
          note: input.note,
          recorded_by_membership_id: input.recordedByMembershipId,
        });
      },
      async listEventsForChild(_client, { childId }) {
        return (events ?? [event]).filter((row) =>
          currentAudience.some((entry) => entry.event_id === row.id && entry.child_id === childId)
          && (
            row.audience_thread_id == null || (
              chatThread?.id === row.audience_thread_id
              && chatMembers.some(
                (member) => member.participant_kind === 'child'
                  && member.participant_id === childId,
              )
            )
          ),
        );
      },
      async audit(_client, input) {
        calls.audits.push(input);
      },
    },
  };
}

const create = (options) => createEventCreate(recordingPort(options));
const list = (options) => createEventList(recordingPort(options));
const readDevice = (options) => createDeviceEventRead(recordingPort(options));
const respond = (options) => createEventResponseRecord(recordingPort(options));
const recordAttendance = (options) => createAttendanceRecord(recordingPort(options));
const update = (options) => createEventUpdate(recordingPort(options));
const cancel = (options) => createEventCancel(recordingPort(options));

// ── the window and the version: what a client must state ──────────────────────────────

test('a range read states two instants, and a window that runs backwards is refused', () => {
  const range = normalizeRange({ from: STARTS, to: ENDS });
  assert.deepEqual(range, { from: STARTS, to: ENDS });
  for (const bad of [
    { from: 'yesterday', to: ENDS },
    { from: STARTS, to: 'غداً' },
    { from: ENDS, to: STARTS },
    { from: STARTS, to: STARTS },
  ]) {
    assert.throws(
      () => normalizeRange(bad),
      (error) => error instanceof CalendarError && error.code === 'event_range_invalid',
      `expected ${JSON.stringify(bad)} to be refused`,
    );
  }
});

test('an edit must state the version it read, and 0 is not a version', () => {
  // The refusal matters more than the acceptance: `undefined === undefined` would let a
  // client skip the mechanism entirely and still be told its edit succeeded.
  assert.equal(expectedVersion(1), 1);
  assert.equal(expectedVersion(7), 7);
  for (const bad of [undefined, null, 0, -1, 1.5, '2', NaN]) {
    assert.throws(
      () => expectedVersion(bad),
      (error) => error instanceof CalendarError && error.code === 'event_version_required',
      `expected ${String(bad)} to be refused`,
    );
  }
});

// ── attendance is a fact about the past ───────────────────────────────────────────────

test('attendance cannot exist before the event, and cannot exist for a cancelled one', () => {
  const started = eventRow({ starts_at: new Date('2026-10-08T08:00:00.000Z') });
  assert.equal(requireRecordableAt(started, NOW).status, 'scheduled');
  assert.throws(
    () => requireRecordableAt(eventRow({ starts_at: new Date('2026-10-09T15:00:00.000Z') }), NOW),
    (error) => error.code === 'event_not_started',
    'a plan is not an attendance record',
  );
  assert.throws(
    () => requireRecordableAt(eventRow({ status: 'cancelled' }), new Date('2026-10-09T18:00:00.000Z')),
    (error) => error.code === 'event_cancelled',
    'a cancelled event has nothing to record',
  );
});

// ── what a reader sees ────────────────────────────────────────────────────────────────

test('an event carries its audience, and a child sees their own answer only', () => {
  const row = eventRow();
  const audience = [
    { family_id: FAMILY, event_id: EVENT, child_id: CHILD },
    { family_id: FAMILY, event_id: EVENT, child_id: SIBLING },
  ];
  const responses = [
    responseRow({ child_id: SIBLING, response: 'declined', note: 'عندي تدريب' }),
  ];
  const guardianView = eventView(row, { audience, responses });
  assert.equal(guardianView.audience.length, 2, 'the family sees who was invited');
  const sibling = guardianView.audience.find((entry) => entry.childId === SIBLING);
  assert.equal(sibling.response.response, 'declined', 'the family is told, the sibling is not hidden');
  assert.equal(guardianView.audience.find((entry) => entry.childId === CHILD).response, null);

  // The child's own screen: same event, no sibling, and no sibling's answer anywhere in it.
  const childView = childEventView(row, null, null);
  assert.equal(childView.id, EVENT);
  assert.equal(childView.reminderMinutes, undefined, 'a reminder is not something a child is shown');
  assert.deepEqual(Object.keys(childView).sort(), [
    'allDay', 'attendance', 'cancelReason', 'endsAt', 'id', 'location', 'note', 'response', 'startsAt', 'status', 'title',
  ]);
});

test('a reminder is a recorded preference, and nothing claims it was delivered', () => {
  const view = eventView(eventRow({ reminder_minutes: 30 }), {});
  assert.equal(view.reminderMinutes, 30);
  assert.equal(view.status, 'scheduled');
  const keys = Object.keys(view).concat(Object.keys(view.audience));
  assert.equal(
    keys.some((key) => /notif|deliver|sent|push/i.test(key)),
    false,
    'a field that read like a delivery would be a lie the schema keeps forever',
  );
});

// ── stating an event ──────────────────────────────────────────────────────────────────

test('a guardian states an event and names who it is for in the same transaction', async () => {
  const { calls, port } = recordingPort();
  const createEvent = createEventCreate({ port });
  const result = await createEvent({
    principal: { subject: 'test-primary' },
    familyId: FAMILY,
    title: 'زيارة الجدّ',
    note: 'نأخذ الكيك',
    location: 'بيت الجدّ',
    startsAt: STARTS,
    endsAt: ENDS,
    allDay: false,
    reminderMinutes: 60,
    childIds: [CHILD, SIBLING],
    idempotencyKey: 'w8-unit-create',
    requestHash: 'a'.repeat(64),
    correlationId: 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
    now: () => NOW,
  });
  assert.equal(result.event.id, EVENT);
  assert.equal(result.event.audience.length, 2);
  assert.equal(calls.audiences.length, 1, 'the audience is written once, with the event');
  assert.equal(calls.audits[0].eventType, 'family.event_created');
  assert.equal(calls.audits[0].actorMembershipId, GUARDIAN_MEMBERSHIP);
  assert.equal(calls.idempotency[0].scope, `calendar:create:${FAMILY}`);
});

test('calendar events can target a same-family chat group and carry the selected audience into the outbox', async () => {
  const fixture = recordingPort({
    audience: [],
    chatThread: { id: CHAT_THREAD, family_id: FAMILY, kind: 'group' },
    chatMembers: [
      { participant_kind: 'membership', participant_id: GUARDIAN_MEMBERSHIP },
      { participant_kind: 'child', participant_id: CHILD },
      { participant_kind: 'child', participant_id: SIBLING },
    ],
  });
  const createEvent = createEventCreate({ port: fixture.port });
  const result = await createEvent({
    principal: { subject: 'test-primary' },
    familyId: FAMILY,
    title: 'A shared outing',
    startsAt: STARTS,
    endsAt: ENDS,
    childIds: [CHILD],
    audienceThreadId: CHAT_THREAD,
    idempotencyKey: 'calendar-thread-audience',
    requestHash: 'b'.repeat(64),
    correlationId: 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
    now: () => NOW,
  });
  assert.equal(result.event.audienceThreadId, CHAT_THREAD);
  assert.deepEqual(result.event.audience.map((entry) => entry.childId), [CHILD]);
  assert.equal(fixture.calls.events[0].audienceThreadId, CHAT_THREAD);
  assert.deepEqual(fixture.calls.audits[0].payload, {
    audienceThreadId: CHAT_THREAD,
    childIds: [CHILD],
  });

  const outside = recordingPort({
    audience: [],
    chatThread: { id: CHAT_THREAD, family_id: FAMILY, kind: 'group' },
    chatMembers: [
      { participant_kind: 'membership', participant_id: GUARDIAN_MEMBERSHIP },
      { participant_kind: 'child', participant_id: CHILD },
    ],
  });
  await assert.rejects(
    createEventCreate({ port: outside.port })({
      principal: { subject: 'test-primary' },
      familyId: FAMILY,
      title: 'Outside the selected group',
      startsAt: STARTS,
      endsAt: ENDS,
      childIds: [SIBLING],
      audienceThreadId: CHAT_THREAD,
      idempotencyKey: 'calendar-thread-outside',
      requestHash: 'c'.repeat(64),
      now: () => NOW,
    }),
    (error) => error.status === 422 && error.code === 'event_audience_not_in_group',
  );
  assert.equal(outside.calls.events.length, 0);
});

test('group-scoped event writes also require active thread membership', async () => {
  const scopedEvent = eventRow({ audience_thread_id: CHAT_THREAD });
  const removedChild = recordingPort({
    event: scopedEvent,
    chatThread: { id: CHAT_THREAD, family_id: FAMILY, kind: 'group' },
    chatMembers: [{ participant_kind: 'membership', participant_id: GUARDIAN_MEMBERSHIP }],
  });
  await assert.rejects(
    createEventResponseRecord({ port: removedChild.port })({
      deviceId: DEVICE,
      deviceCredential: DEVICE_CREDENTIAL,
      eventId: EVENT,
      response: 'accepted',
      idempotencyKey: 'scoped-removed-child-response',
      requestHash: 'd'.repeat(64),
      now: () => NOW,
    }),
    (error) => error.status === 404 && error.code === 'event_not_found',
  );
  assert.equal(removedChild.calls.responses.length, 0);

  const outsider = recordingPort({
    event: scopedEvent,
    actor: coGuardianActor,
    chatThread: { id: CHAT_THREAD, family_id: FAMILY, kind: 'group' },
    chatMembers: [
      { participant_kind: 'membership', participant_id: GUARDIAN_MEMBERSHIP },
      { participant_kind: 'child', participant_id: CHILD },
    ],
  });
  const isHidden = (error) => error.status === 404 && error.code === 'event_not_found';
  await assert.rejects(
    createEventUpdate({ port: outsider.port })({
      principal: { subject: 'test-co' },
      familyId: FAMILY,
      eventId: EVENT,
      version: 1,
      changes: { title: 'Should stay private' },
      correlationId: 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
    }),
    isHidden,
  );
  await assert.rejects(
    createEventCancel({ port: outsider.port })({
      principal: { subject: 'test-co' },
      familyId: FAMILY,
      eventId: EVENT,
      reason: 'Should stay private',
      idempotencyKey: 'scoped-outsider-cancel',
      requestHash: 'e'.repeat(64),
      correlationId: 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
    }),
    isHidden,
  );
  await assert.rejects(
    createAttendanceRecord({ port: outsider.port })({
      principal: { subject: 'test-co' },
      familyId: FAMILY,
      eventId: EVENT,
      childId: CHILD,
      attended: true,
      idempotencyKey: 'scoped-outsider-attendance',
      requestHash: 'f'.repeat(64),
      now: () => NOW,
    }),
    isHidden,
  );
  assert.equal(outsider.calls.events.length, 0);
  assert.equal(outsider.calls.cancellations.length, 0);
  assert.equal(outsider.calls.attendance.length, 0);
});

test('calendar reads hide group-scoped events from guardians outside that conversation', async () => {
  const rows = [
    eventRow({ id: EVENT, audience_thread_id: null }),
    eventRow({ id: SCOPED_EVENT, audience_thread_id: CHAT_THREAD }),
  ];
  const audience = [
    { family_id: FAMILY, event_id: EVENT, child_id: CHILD },
    { family_id: FAMILY, event_id: SCOPED_EVENT, child_id: CHILD },
  ];
  const member = recordingPort({
    events: rows,
    audience,
    chatThread: { id: CHAT_THREAD, family_id: FAMILY, kind: 'group' },
    chatMembers: [
      { participant_kind: 'membership', participant_id: GUARDIAN_MEMBERSHIP },
      { participant_kind: 'child', participant_id: CHILD },
    ],
  });
  const visibleToMember = await createEventList({ port: member.port })({
    principal: { subject: 'test-primary' },
    familyId: FAMILY,
    from: '2026-10-01T00:00:00.000Z',
    to: '2026-11-01T00:00:00.000Z',
  });
  assert.deepEqual(visibleToMember.events.map((entry) => entry.id), [EVENT, SCOPED_EVENT]);
  assert.equal(member.calls.eventListQueries[0].viewerMembershipId, GUARDIAN_MEMBERSHIP);

  const outsider = recordingPort({
    events: rows,
    audience,
    actor: coGuardianActor,
    chatThread: { id: CHAT_THREAD, family_id: FAMILY, kind: 'group' },
    chatMembers: [
      { participant_kind: 'membership', participant_id: GUARDIAN_MEMBERSHIP },
      { participant_kind: 'child', participant_id: CHILD },
    ],
  });
  const hiddenFromOutsider = await createEventList({ port: outsider.port })({
    principal: { subject: 'test-co' },
    familyId: FAMILY,
    from: '2026-10-01T00:00:00.000Z',
    to: '2026-11-01T00:00:00.000Z',
  });
  assert.deepEqual(hiddenFromOutsider.events.map((entry) => entry.id), [EVENT]);
  assert.equal(outsider.calls.eventListQueries[0].viewerMembershipId, CO_GUARDIAN_MEMBERSHIP);
});

test('an event in the past, or one that reaches past a month, is refused by name', async () => {
  const createEvent = create({});
  await assert.rejects(
    () => createEvent({
      principal: { subject: 'test-primary' },
      familyId: FAMILY,
      title: 'أمس',
      startsAt: '2026-10-07T15:00:00.000Z',
      endsAt: '2026-10-07T17:00:00.000Z',
      childIds: [CHILD],
      idempotencyKey: 'w8-unit-past',
      requestHash: 'a'.repeat(64),
      now: () => NOW,
    }),
    (error) => error.code === 'event_in_past',
  );
  await assert.rejects(
    () => createEvent({
      principal: { subject: 'test-primary' },
      familyId: FAMILY,
      title: 'رحلة شهرين',
      startsAt: STARTS,
      endsAt: '2026-12-09T17:00:00.000Z',
      childIds: [CHILD],
      idempotencyKey: 'w8-unit-long',
      requestHash: 'a'.repeat(64),
      now: () => NOW,
    }),
    (error) => error.code === 'event_too_long',
  );
});

test('only a guardian states an event, and only for children of this family', async () => {
  await assert.rejects(
    () => create({ actor: childActor })({
      principal: { subject: 'test-child' },
      familyId: FAMILY,
      title: 'خطة',
      startsAt: STARTS,
      endsAt: ENDS,
      childIds: [CHILD],
      idempotencyKey: 'w8-unit-forbidden',
      requestHash: 'a'.repeat(64),
      now: () => NOW,
    }),
    (error) => error.code === 'event_forbidden',
  );
  await assert.rejects(
    () => create({ childExists: false })({
      principal: { subject: 'test-primary' },
      familyId: FAMILY,
      title: 'خطة',
      startsAt: STARTS,
      endsAt: ENDS,
      childIds: [CHILD],
      idempotencyKey: 'w8-unit-unknown-child',
      requestHash: 'a'.repeat(64),
      now: () => NOW,
    }),
    (error) => error.code === 'child_not_found',
  );
});

test('the family calendar shows what was called off, with the reason', async () => {
  const cancelled = eventRow({
    status: 'cancelled',
    cancelled_by_membership_id: GUARDIAN_MEMBERSHIP,
    cancelled_at: new Date('2026-10-08T11:00:00.000Z'),
    cancel_reason: 'الجدّ مريض',
    version: 2,
  });
  const { events } = await list({ events: [cancelled] })({
    principal: { subject: 'test-primary' },
    familyId: FAMILY,
    from: '2026-10-08T00:00:00.000Z',
    to: '2026-10-10T00:00:00.000Z',
  });
  assert.equal(events.length, 1, 'a cancellation is not a disappearance');
  assert.equal(events[0].status, 'cancelled');
  assert.equal(events[0].cancelReason, 'الجدّ مريض');
  assert.equal(events[0].cancelledByMembershipId, GUARDIAN_MEMBERSHIP);
  assert.ok(events[0].cancelledAt, 'a cancellation has a moment');
});

// ── answering ─────────────────────────────────────────────────────────────────────────

test('a handset answers for its own child, and cannot answer for a sibling', async () => {
  // The device row says which child this is; nothing in the request can say otherwise, which
  // is why the body here carries no child id at all.
  const devicePort = recordingPort({ audience: [{ family_id: FAMILY, event_id: EVENT, child_id: CHILD }] });
  const answerFromDevice = createEventResponseRecord({ port: devicePort.port });
  const answered = await answerFromDevice({
    deviceId: DEVICE,
    deviceCredential: DEVICE_CREDENTIAL,
    eventId: EVENT,
    response: 'accepted',
    idempotencyKey: 'w8-unit-device-answer',
    requestHash: 'a'.repeat(64),
    now: () => NOW,
  });
  assert.equal(answered.response.childId, CHILD, 'the child comes from the device row');
  assert.equal(answered.response.respondedByDeviceId, DEVICE);
  assert.equal(answered.response.respondedByMembershipId, null, 'exactly one author');
  assert.equal(devicePort.calls.idempotency[0].scope, `calendar:response:${DEVICE}:${EVENT}`);

  // The sibling's handset, held by the same family, invited to the same event, answering as
  // itself: the audience row for that child does not exist, so there is nothing to answer to.
  const siblingPort = recordingPort({
    audience: [{ family_id: FAMILY, event_id: EVENT, child_id: CHILD }],
    device: { ...pairedDevice(), child_id: SIBLING },
  });
  await assert.rejects(
    () => createEventResponseRecord({ port: siblingPort.port })({
      deviceId: DEVICE,
      deviceCredential: DEVICE_CREDENTIAL,
      eventId: EVENT,
      response: 'accepted',
      idempotencyKey: 'w8-unit-sibling',
      requestHash: 'a'.repeat(64),
      now: () => NOW,
    }),
    (error) => error.code === 'event_not_invited',
  );
});

test('a guardian answers for a child they name, and the author is the guardian', async () => {
  const { calls, port } = recordingPort();
  const answered = await createEventResponseRecord({ port })({
    principal: { subject: 'test-co' },
    familyId: FAMILY,
    childId: CHILD,
    eventId: EVENT,
    response: 'declined',
    note: 'عندي تدريب',
    idempotencyKey: 'w8-unit-guardian-answer',
    requestHash: 'a'.repeat(64),
    now: () => NOW,
  });
  assert.equal(answered.response.response, 'declined');
  assert.equal(answered.response.respondedByMembershipId, GUARDIAN_MEMBERSHIP);
  assert.equal(answered.response.respondedByDeviceId, null);
  assert.equal(calls.responses.length, 1);
});

test('a "no" is a first-class answer, and answering ends when the event starts', async () => {
  const declined = await respond({})({
    principal: { subject: 'test-primary' },
    familyId: FAMILY,
    childId: CHILD,
    eventId: EVENT,
    response: 'declined',
    note: 'لا أستطيع',
    idempotencyKey: 'w8-unit-declined',
    requestHash: 'a'.repeat(64),
    now: () => NOW,
  });
  assert.equal(declined.response.response, 'declined');
  assert.equal(declined.response.note, 'لا أستطيع', 'the reason travels with the refusal');
  assert.ok(declined.response.respondedAt, 'a refusal has a moment, like an acceptance');

  // After the event starts, "will you come" is over. What happened is asked with attendance.
  const started = eventRow({ starts_at: new Date('2026-10-08T08:00:00.000Z') });
  await assert.rejects(
    () => respond({ event: started })({
      principal: { subject: 'test-primary' },
      familyId: FAMILY,
      childId: CHILD,
      eventId: EVENT,
      response: 'accepted',
      idempotencyKey: 'w8-unit-late',
      requestHash: 'a'.repeat(64),
      now: () => NOW,
    }),
    (error) => error.code === 'event_already_started',
  );
});

test('a cancelled event has nothing to answer', async () => {
  await assert.rejects(
    () => respond({ event: eventRow({ status: 'cancelled' }) })({
      principal: { subject: 'test-primary' },
      familyId: FAMILY,
      childId: CHILD,
      eventId: EVENT,
      response: 'accepted',
      idempotencyKey: 'w8-unit-cancelled-answer',
      requestHash: 'a'.repeat(64),
      now: () => NOW,
    }),
    (error) => error.code === 'event_cancelled',
  );
});

// ── attendance ────────────────────────────────────────────────────────────────────────

test('attendance is written by a guardian, about an invited child, after the fact', async () => {
  // The event has started, so there is a fact to record.
  const started = eventRow({ starts_at: new Date('2026-10-08T08:00:00.000Z') });
  const { calls, port } = recordingPort({ event: started });
  const recorded = await createAttendanceRecord({ port })({
    principal: { subject: 'test-primary' },
    familyId: FAMILY,
    eventId: EVENT,
    childId: CHILD,
    attended: true,
    note: '',
    idempotencyKey: 'w8-unit-attendance',
    requestHash: 'a'.repeat(64),
    now: () => NOW,
  });
  assert.equal(recorded.attendance.attended, true);
  assert.equal(recorded.attendance.recordedByMembershipId, GUARDIAN_MEMBERSHIP);
  assert.equal(calls.audits[0].eventType, 'family.event_attendance_recorded');

  // A retry of the same request is the same fact, not a second moment: the write is scoped to
  // the child and the event, so a flaky tap cannot move `recorded_at`.
  assert.equal(calls.idempotency[0].scope, `calendar:attendance:${FAMILY}:${EVENT}:${CHILD}`);
  assert.equal(calls.idempotency[0].key, 'w8-unit-attendance');

  await assert.rejects(
    () => createAttendanceRecord({ port })({
      principal: { subject: 'test-primary' },
      familyId: FAMILY,
      eventId: EVENT,
      childId: SIBLING,
      attended: true,
      idempotencyKey: 'w8-unit-attendance-sibling',
      requestHash: 'a'.repeat(64),
      now: () => NOW,
    }),
    (error) => error.code === 'event_not_invited',
  );
  const asChild = recordingPort({ event: started, actor: childActor });
  await assert.rejects(
    () => createAttendanceRecord({ port: asChild.port })({
      principal: { subject: 'test-child' },
      familyId: FAMILY,
      eventId: EVENT,
      childId: CHILD,
      attended: true,
      idempotencyKey: 'w8-unit-attendance-child',
      requestHash: 'a'.repeat(64),
      now: () => NOW,
    }),
    (error) => error.code === 'event_forbidden',
    'the child reports how it felt; a guardian states what happened',
  );
});

// ── changing a plan ───────────────────────────────────────────────────────────────────

test('two guardians do not silently overwrite one evening', async () => {
  const updated = await update({ event: eventRow({ version: 3 }) })({
    principal: { subject: 'test-co' },
    familyId: FAMILY,
    eventId: EVENT,
    version: 3,
    changes: { location: 'بيت العمّ' },
  });
  assert.equal(updated.event.location, 'بيت العمّ');
  assert.equal(updated.event.version, 4, 'an edit that landed moves the version');

  await assert.rejects(
    () => update({ event: eventRow({ version: 4 }) })({
      principal: { subject: 'test-co' },
      familyId: FAMILY,
      eventId: EVENT,
      version: 3,
      changes: { location: 'مكان آخر' },
    }),
    (error) => error.code === 'event_stale_version',
    'the second guardian is told, and the first plan survives',
  );
});

test('an edit states the end after the start, and a cancelled event is not edited', async () => {
  await assert.rejects(
    () => update({})({
      principal: { subject: 'test-primary' },
      familyId: FAMILY,
      eventId: EVENT,
      version: 1,
      changes: { endsAt: '2026-10-09T14:00:00.000Z' },
    }),
    (error) => error.code === 'event_instant_ordered',
  );
  await assert.rejects(
    () => update({ event: eventRow({ status: 'cancelled' }) })({
      principal: { subject: 'test-primary' },
      familyId: FAMILY,
      eventId: EVENT,
      version: 1,
      changes: { title: 'شيء آخر' },
    }),
    (error) => error.code === 'event_cancelled',
  );
});

test('a name cannot be unticked after that child answered', async () => {
  const rejected = recordingPort({
    audience: [
      { family_id: FAMILY, event_id: EVENT, child_id: CHILD },
      { family_id: FAMILY, event_id: EVENT, child_id: SIBLING },
    ],
    answeredChildren: new Set([SIBLING]),
  });
  await assert.rejects(
    () => createEventUpdate({ port: rejected.port })({
      principal: { subject: 'test-primary' },
      familyId: FAMILY,
      eventId: EVENT,
      version: 1,
      changes: { childIds: [CHILD] },
    }),
    (error) => error.code === 'event_audience_answered',
    'an answer is a fact with an author, and an edit may not delete it by deleting its row',
  );
  assert.equal(rejected.calls.deletedAudiences, 0, 'nothing was deleted before the refusal');

  const accepted = recordingPort({
    audience: [{ family_id: FAMILY, event_id: EVENT, child_id: SIBLING }],
  });
  const updated = await createEventUpdate({ port: accepted.port })({
    principal: { subject: 'test-primary' },
    familyId: FAMILY,
    eventId: EVENT,
    version: 1,
    changes: { childIds: [CHILD] },
  });
  assert.equal(accepted.calls.deletedAudiences, 1, 'the audience is replaced, not merged');
  assert.deepEqual(accepted.calls.audiences[0].childIds, [CHILD]);
  assert.equal(updated.event.audience[0].childId, CHILD);
});

// ── calling it off ────────────────────────────────────────────────────────────────────

test('cancelling is an act with an author, a reason and a moment - and it happens once', async () => {
  const { calls, port } = recordingPort({ actor: coGuardianActor });
  const cancelled = await createEventCancel({ port })({
    principal: { subject: 'test-co' },
    familyId: FAMILY,
    eventId: EVENT,
    reason: 'الجدّ مريض',
    idempotencyKey: 'w8-unit-cancel',
    requestHash: 'a'.repeat(64),
    correlationId: 'dddddddd-dddd-4ddd-8ddd-dddddddddddd',
  });
  assert.equal(cancelled.event.status, 'cancelled');
  assert.equal(cancelled.event.cancelReason, 'الجدّ مريض');
  assert.equal(cancelled.event.cancelledByMembershipId, CO_GUARDIAN_MEMBERSHIP);
  assert.ok(cancelled.event.cancelledAt);
  assert.equal(cancelled.event.audience.length, 1, 'the invitation survives the cancellation');
  assert.equal(calls.cancellations.length, 1);
  assert.equal(calls.idempotency[0].scope, `calendar:cancel:${FAMILY}:${EVENT}`);
  assert.equal(calls.audits[0].eventType, 'family.event_cancelled');

  await assert.rejects(
    () => cancel({ event: eventRow({ status: 'cancelled' }) })({
      principal: { subject: 'test-co' },
      familyId: FAMILY,
      eventId: EVENT,
      reason: 'مرة ثانية',
      idempotencyKey: 'w8-unit-cancel-again',
      requestHash: 'a'.repeat(64),
    }),
    (error) => error.code === 'event_already_cancelled',
    'silence here would let two guardians each believe they were the one who called it off',
  );
});

test('the shapes a client reads are stated once, and carry no author the request could fake', () => {
  const response = responseView(responseRow({ responded_by_membership_id: GUARDIAN_MEMBERSHIP, responded_by_device_id: null }));
  assert.equal(response.respondedByMembershipId, GUARDIAN_MEMBERSHIP);
  assert.equal(response.respondedByDeviceId, null);
  const attendance = attendanceView(attendanceRow({ attended: false }));
  assert.equal(attendance.attended, false, 'attendance is a verdict, not a truthiness');
  assert.equal(attendance.recordedByMembershipId, GUARDIAN_MEMBERSHIP);
  assert.ok(attendance.recordedAt);
});

// ── the handset's own view ────────────────────────────────────────────────────────────

test('the port compares the digest it stored against what the handset presented', async () => {
  // This one is deliberately not a factory test, because the rule does not live in the
  // factory: `requireDevice` is a port method, and the direction of the comparison is the
  // whole of it. `capabilityMatches(storedDigest, presentedCredential)` is the same function
  // every other device surface uses, so a caller who swaps the two is caught here - with the
  // production comparison, not a friendlier stand-in.
  const port = postgresCalendarPort({}, { credentialMatches: capabilityMatches });
  const clientWith = (rows) => ({ query: async () => ({ rows }) });
  const stored = pairedDevice();

  const accepted = await port.requireDevice(clientWith([stored]), {
    deviceId: DEVICE,
    deviceCredential: DEVICE_CREDENTIAL,
  });
  assert.equal(accepted.id, DEVICE);
  assert.equal(accepted.child_id, CHILD, 'the device row is what names the child');

  for (const attempt of [
    ['a wrong credential', [stored], 'not-the-credential'],
    ['a revoked device', [{ ...stored, credential_revoked_at: new Date('2026-10-08T07:00:00.000Z') }], DEVICE_CREDENTIAL],
    ['an unknown device', [], DEVICE_CREDENTIAL],
  ]) {
    await assert.rejects(
      () => port.requireDevice(clientWith(attempt[1]), {
        deviceId: DEVICE,
        deviceCredential: attempt[2],
      }),
      (error) => error.code === 'device_credential_rejected',
      `${attempt[0]} must prove nothing`,
    );
  }
});

test('a child calendar hides group-scoped events after the child leaves that conversation', async () => {
  const rows = [
    eventRow({ id: EVENT }),
    eventRow({ id: SCOPED_EVENT, audience_thread_id: CHAT_THREAD }),
  ];
  const audience = [
    { family_id: FAMILY, event_id: EVENT, child_id: CHILD },
    { family_id: FAMILY, event_id: SCOPED_EVENT, child_id: CHILD },
  ];
  const active = recordingPort({
    events: rows,
    audience,
    chatThread: { id: CHAT_THREAD, family_id: FAMILY, kind: 'group' },
    chatMembers: [{ participant_kind: 'child', participant_id: CHILD }],
  });
  const activeEvents = await createDeviceEventRead({ port: active.port })({
    deviceId: DEVICE,
    deviceCredential: DEVICE_CREDENTIAL,
    from: '2026-10-08T00:00:00.000Z',
    to: '2026-10-10T00:00:00.000Z',
  });
  assert.deepEqual(activeEvents.events.map((entry) => entry.id), [EVENT, SCOPED_EVENT]);

  const removed = recordingPort({
    events: rows,
    audience,
    chatThread: { id: CHAT_THREAD, family_id: FAMILY, kind: 'group' },
    chatMembers: [],
  });
  const afterLeaving = await createDeviceEventRead({ port: removed.port })({
    deviceId: DEVICE,
    deviceCredential: DEVICE_CREDENTIAL,
    from: '2026-10-08T00:00:00.000Z',
    to: '2026-10-10T00:00:00.000Z',
  });
  assert.deepEqual(afterLeaving.events.map((entry) => entry.id), [EVENT]);
});

test('a handset reads the events its own child is invited to, and nothing else', async () => {
  const devicePort = recordingPort({
    responses: [responseRow()],
    attendance: [attendanceRow({ child_id: SIBLING, attended: false })],
  });
  const { events } = await createDeviceEventRead({ port: devicePort.port })({
    deviceId: DEVICE,
    deviceCredential: DEVICE_CREDENTIAL,
    from: '2026-10-08T00:00:00.000Z',
    to: '2026-10-10T00:00:00.000Z',
  });
  assert.equal(events.length, 1);
  assert.equal(events[0].response.response, 'accepted', 'the child sees their own answer');
  assert.equal(events[0].attendance, null, "the sibling's attendance record is not this child's");
  assert.equal('audience' in events[0], false, 'and neither is the list of who else was invited');
});
