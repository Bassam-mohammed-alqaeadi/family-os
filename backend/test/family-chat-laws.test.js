// W9 — the laws of the family chat, as pure functions and as factories over an in-memory port.
//
// No database and no socket, for the same reason as W7 and W8: a rule that can only be checked
// through a network round trip is a rule nobody checks before pushing - and this wave has the
// strongest reason of all to keep its laws cheap to run, because it is the one where the
// product starts writing down what people said to each other. What is defended here, one line
// each:
//
//   * new conversations are direct pairs or user-created groups with explicit same-family peers;
//     legacy family/child rooms remain readable but cannot be created by the current API;
//   * guardians and paired children may create or manage conversations only under server policy,
//     and a child sees only the roster the server authorized for the family;
//   * a message's author comes from HOW the request arrived, never from a field in the body;
//   * only a member of a room can read or write in it, and a caller outside it is answered as
//     if the room did not exist;
//   * a resend of the same client message is the same message, with the sequence it already
//     had, and no second sequence number is ever handed out;
//   * an edit states the revision it read, keeps the body it replaced, and never applies to a
//     deleted message;
//   * only the author deletes their own words - a guardian deleting a child's message is the
//     one refusal that makes this product different from a surveillance tool - and deletion
//     leaves the sequence and the trace while losing the text;
//   * a read mark is a participant's own statement, it only moves forward, and it cannot pass
//     the newest message in the thread;
//   * a receipt counts OTHER participants, never the author, and nothing here claims delivery.
//
// The in-memory port below is deliberately the schema's shadow: it refuses to store a message
// whose author is not a member of the thread, exactly as migration 109's composite foreign key
// does. A module path that tried to write such a row would fail here rather than in production.
import assert from 'node:assert/strict';
import test from 'node:test';

import {
  CHAT_CURRENT_CAPABILITIES,
  ChatError,
  createMessageDelete,
  createMessageEdit,
  createMessageList,
  createMessageSend,
  createReadMark,
  createDeviceThreadCreate,
  createDeviceThreadMemberAdd,
  createThreadCreate,
  createThreadList,
  createThreadMemberAdd,
  expectedRevision,
  messageView,
  normalizeMessageQuery,
  participantView,
  requireReadableSeq,
  threadLastMessage,
  threadView,
} from '../src/family-chat.js';

const FAMILY = '11111111-1111-4111-8111-111111111111';
const OTHER_FAMILY = '12111111-1111-4111-8111-111111111111';
const CHILD = '22222222-2222-4222-8222-222222222222';
const SIBLING = '33333333-3333-4333-8333-333333333333';
const THREAD = '44444444-4444-4444-8444-444444444444';
const CHILD_THREAD = '45444444-4444-4444-8444-444444444444';
const PRIMARY = '66666666-6666-4666-8666-666666666666';
const CO_GUARDIAN = '77777777-7777-4777-8777-777777777777';
const DEVICE = '88888888-8888-4888-8888-888888888888';
const PENDING_GUARDIAN = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';

const principal = { subject: 'test-primary' };
const coPrincipal = { subject: 'test-co' };
const childPrincipal = { subject: 'test-child' };
const DEVICE_CREDENTIAL = 'device-credential-value';
const DEFAULT_CHAT_POLICY = Object.freeze({
  version: 0,
  chatCreateRoles: Object.freeze(['primary_guardian', 'co_guardian']),
  chatManageRoles: Object.freeze(['primary_guardian', 'co_guardian']),
  taskRoles: Object.freeze(['primary_guardian', 'co_guardian']),
  calendarRoles: Object.freeze(['primary_guardian', 'co_guardian']),
  childDirectEnabled: true,
  childGroupsEnabled: true,
  childGroupMemberManagementEnabled: true,
  guardianInclusionMode: 'none',
  maximumGroupSize: 24,
});

function membershipRow(overrides = {}) {
  return {
    id: PRIMARY,
    family_id: FAMILY,
    target_subject: 'test-primary',
    role: 'primary_guardian',
    status: 'active',
    ...overrides,
  };
}

function messageRow(overrides = {}) {
  return {
    id: '99999999-9999-4999-8999-999999999999',
    family_id: FAMILY,
    thread_id: THREAD,
    seq: 1,
    author_kind: 'membership',
    author_id: PRIMARY,
    body: 'السلام عليكم',
    client_message_id: 'client-0001',
    revision: 1,
    edited_at: null,
    deleted_at: null,
    deleted_by_kind: null,
    deleted_by_id: null,
    created_at: new Date('2026-10-08T09:00:00.000Z'),
    ...overrides,
  };
}

/// The port the module talks to: the tables, in memory, with the two storage laws migration 109
/// states - a message's author must be a member of its thread, and (thread, author,
/// client_message_id) is unique. Anything the module cannot do through the schema fails here.
function memoryPort({
  memberships = [membershipRow()],
  devices = [{ id: DEVICE, family_id: FAMILY, child_id: CHILD, revoked_at: null }],
  threads = [{ id: THREAD, family_id: FAMILY, kind: 'family', title: 'العائلة', next_seq: 1,
               created_by_membership_id: PRIMARY, created_at: new Date('2026-10-08T08:00:00.000Z') }],
  members = [
    { thread_id: THREAD, family_id: FAMILY, participant_kind: 'membership', participant_id: PRIMARY,
      membership_id: PRIMARY, child_id: null, last_read_seq: 0 },
  ],
  messages = [],
  collaborationPolicy = DEFAULT_CHAT_POLICY,
} = {}) {
  const state = {
    memberships: memberships.map((row) => ({ ...row })),
    collaborationPolicy: {
      ...collaborationPolicy,
      chatCreateRoles: [...collaborationPolicy.chatCreateRoles],
      chatManageRoles: [...collaborationPolicy.chatManageRoles],
      taskRoles: [...collaborationPolicy.taskRoles],
      calendarRoles: [...collaborationPolicy.calendarRoles],
    },
    generatedThreadId: 0,
    devices: devices.map((row) => ({ ...row })),
    threads: threads.map((row) => ({ ...row })),
    members: members.map((row) => ({ ...row })),
    messages: messages.map((row) => ({ ...row })),
    revisions: [],
    audits: [],
    sequencesAllocated: 0,
    replays: new Map(),
  };

  const memberKey = (threadId, kind, id) => `${threadId}|${kind}|${id}`;
  const findMember = (threadId, kind, id) =>
    state.members.find((row) => memberKey(row.thread_id, row.participant_kind, row.participant_id) === memberKey(threadId, kind, id));

  const port = {
    state,

    async read(run) {
      return run(state);
    },

    /// A replay is answered only for the same key AND the same request hash, which is what makes
    /// a retried request idempotent without making a different request with a reused key succeed.
    async idempotent(scope, key, requestHash, work) {
      const slot = `${scope}|${key}|${requestHash}`;
      if (state.replays.has(slot)) return state.replays.get(slot);
      const result = await work(state);
      state.replays.set(slot, result);
      return result;
    },

    async authorize(_tx, { familyId, subject }) {
      const row = state.memberships.find(
        (membership) => membership.family_id === familyId && membership.target_subject === subject && membership.status === 'active',
      );
      if (row == null) throw new ChatError(403, 'family_access_denied', 'Not a member of this family.');
      return row;
    },

    async readCollaborationPolicy() {
      return {
        ...state.collaborationPolicy,
        chatCreateRoles: [...state.collaborationPolicy.chatCreateRoles],
        chatManageRoles: [...state.collaborationPolicy.chatManageRoles],
        taskRoles: [...state.collaborationPolicy.taskRoles],
        calendarRoles: [...state.collaborationPolicy.calendarRoles],
      };
    },

    async resolveParticipant(_tx, { principal: caller, deviceId, deviceCredential, familyId }) {
      if (deviceId != null) {
        const device = await port.requireDevice(_tx, { deviceId, deviceCredential });
        return { actor: null, device, participant: { kind: 'child', id: device.child_id, familyId: device.family_id } };
      }
      const actor = await port.authorize(_tx, { familyId, subject: caller.subject });
      return { actor, device: null, participant: { kind: 'membership', id: actor.id, familyId } };
    },

    async requireDevice(_tx, { deviceId, deviceCredential }) {
      const device = state.devices.find((row) => row.id === deviceId);
      if (device == null || device.revoked_at != null || deviceCredential !== DEVICE_CREDENTIAL) {
        throw new ChatError(403, 'device_credential_rejected', 'This device credential is not accepted.');
      }
      return device;
    },

    async readMembership(_tx, { familyId, membershipId }) {
      const row = state.memberships.find((membership) => membership.family_id === familyId && membership.id === membershipId);
      return row ?? null;
    },

    async listActiveGuardianMemberships(_tx, { familyId }) {
      return state.memberships.filter(
        (membership) =>
          membership.family_id === familyId &&
          membership.status === 'active' &&
          ['primary_guardian', 'co_guardian'].includes(membership.role),
      );
    },

    async readChild(_tx, { familyId, childId }) {
      if (familyId !== FAMILY) return null;
      return [CHILD, SIBLING].includes(childId) ? { id: childId } : null;
    },

    async insertThread(_tx, {
      familyId,
      kind,
      title,
      directPairKey,
      createdByMembershipId,
      createdByChildId,
      createdByKind,
      createdById,
    }) {
      state.generatedThreadId += 1;
      const row = {
        id: `a0000000-0000-4000-8000-${String(state.generatedThreadId).padStart(12, '0')}`,
        family_id: familyId,
        kind,
        title,
        direct_pair_key: directPairKey,
        next_seq: 1,
        created_by_membership_id: createdByMembershipId,
        created_by_child_id: createdByChildId,
        created_by_participant_kind: createdByKind,
        created_by_participant_id: createdById,
        created_at: new Date('2026-10-08T10:00:00.000Z'),
      };
      state.threads.push(row);
      return { ...row };
    },

    async insertThreadMembers(_tx, { familyId, threadId, membershipIds, childIds, joinedSeq = 1 }) {
      for (const membershipId of membershipIds) {
        if (findMember(threadId, 'membership', membershipId) != null) continue;
        state.members.push({ thread_id: threadId, family_id: familyId, participant_kind: 'membership',
                             participant_id: membershipId, membership_id: membershipId, child_id: null,
                             joined_seq: joinedSeq, last_read_seq: 0 });
      }
      for (const childId of childIds) {
        if (findMember(threadId, 'child', childId) != null) continue;
        state.members.push({ thread_id: threadId, family_id: familyId, participant_kind: 'child',
                             participant_id: childId, membership_id: null, child_id: childId,
                             joined_seq: joinedSeq, last_read_seq: 0 });
      }
      return port.listThreadMembers(_tx, { threadIds: [threadId] });
    },

    async listThreadMembers(_tx, { threadIds }) {
      return state.members
        .filter((row) => threadIds.includes(row.thread_id))
        .map((row) => {
          const membership = state.memberships.find((entry) => entry.id === row.membership_id);
          return {
            ...row,
            membership_role: membership?.role ?? null,
            child_display_name: row.child_id == null ? null
              : (row.child_id === CHILD ? 'أماني' : 'بشير'),
          };
        });
    },

    async listThreadChildren(_tx, { threadId }) {
      return state.members.filter((row) => row.thread_id === threadId && row.participant_kind === 'child');
    },

    async readThread(_tx, { familyId, threadId }) {
      const row = state.threads.find((thread) => thread.id === threadId && thread.family_id === familyId);
      return row == null ? null : { ...row };
    },

    async readThreadMember(_tx, { threadId, participantKind, participantId }) {
      const row = findMember(threadId, participantKind, participantId);
      return row == null ? null : { ...row };
    },

    async listThreadsForParticipant(_tx, { familyId, participantKind, participantId }) {
      return state.threads
        .filter((thread) => thread.family_id === familyId
          && findMember(thread.id, participantKind, participantId) != null)
        .map((thread) => {
          const member = findMember(thread.id, participantKind, participantId);
          const last = [...state.messages].filter((message) => message.thread_id === thread.id)
            .sort((left, right) => right.seq - left.seq)[0];
          const unread = state.messages.filter((message) => message.thread_id === thread.id
            && message.seq > member.last_read_seq
            && !(message.author_kind === participantKind && message.author_id === participantId)).length;
          const readers = last == null ? 0 : state.members.filter((entry) => entry.thread_id === thread.id
            && entry.last_read_seq >= last.seq
            && !(entry.participant_kind === last.author_kind && entry.participant_id === last.author_id)).length;
          return {
            id: thread.id, family_id: thread.family_id, kind: thread.kind, title: thread.title,
            created_at: thread.created_at, last_read_seq: member.last_read_seq,
            unread_count: unread, last_read_count: readers,
            last_id: last?.id ?? null, last_seq: last?.seq ?? null,
            last_author_kind: last?.author_kind ?? null, last_author_id: last?.author_id ?? null,
            last_body: last?.body ?? null, last_revision: last?.revision ?? null,
            last_edited_at: last?.edited_at ?? null, last_deleted_at: last?.deleted_at ?? null,
            last_deleted_by_kind: last?.deleted_by_kind ?? null, last_deleted_by_id: last?.deleted_by_id ?? null,
            last_created_at: last?.created_at ?? null,
          };
        });
    },

    async allocateSeq(_tx, { familyId, threadId }) {
      const thread = state.threads.find((row) => row.id === threadId && row.family_id === familyId);
      if (thread == null) throw new ChatError(404, 'chat_thread_not_found', 'no thread');
      const seq = thread.next_seq;
      thread.next_seq += 1;
      state.sequencesAllocated += 1;
      return seq;
    },

    async readHighestSeq(_tx, { threadId }) {
      return state.messages.filter((row) => row.thread_id === threadId).reduce((max, row) => Math.max(max, row.seq), 0);
    },

    async readMessageByClientId(_tx, { threadId, authorKind, authorId, clientMessageId }) {
      const row = state.messages.find((message) => message.thread_id === threadId
        && message.author_kind === authorKind && message.author_id === authorId
        && message.client_message_id === clientMessageId);
      return row == null ? null : { ...row };
    },

    async insertMessage(_tx, { familyId, threadId, seq, authorKind, authorId, body, clientMessageId }) {
      // The schema's composite foreign key, restated: a message whose author is not a member of
      // this thread cannot exist as a row.
      if (findMember(threadId, authorKind, authorId) == null) {
        throw new Error('the schema would refuse a message whose author is not a member');
      }
      const row = {
        id: `message-${seq}-${authorKind}`,
        family_id: familyId,
        thread_id: threadId,
        seq,
        author_kind: authorKind,
        author_id: authorId,
        body,
        client_message_id: clientMessageId,
        revision: 1,
        edited_at: null,
        deleted_at: null,
        deleted_by_kind: null,
        deleted_by_id: null,
        created_at: new Date('2026-10-08T11:00:00.000Z'),
      };
      state.messages.push(row);
      return { ...row };
    },

    async readMessage(_tx, { familyId, threadId, messageId }) {
      const row = state.messages.find((message) => message.id === messageId
        && message.thread_id === threadId && message.family_id === familyId);
      return row == null ? null : { ...row };
    },

    async listMessages(_tx, { threadId, afterSeq, limit }) {
      const rows = state.messages.filter((row) => row.thread_id === threadId && row.seq > afterSeq)
        .sort((left, right) => left.seq - right.seq);
      return rows.slice(0, limit).map((row) => ({ ...row }));
    },

    async readCountsForMessages(_tx, { threadId, messageIds }) {
      return state.messages
        .filter((row) => row.thread_id === threadId && messageIds.includes(row.id))
        .map((row) => ({
          message_id: row.id,
          read_count: state.members.filter((entry) => entry.thread_id === threadId
            && entry.last_read_seq >= row.seq
            && !(entry.participant_kind === row.author_kind && entry.participant_id === row.author_id)).length,
        }));
    },

    async updateMessageBody(_tx, { messageId, body }) {
      const row = state.messages.find((message) => message.id === messageId);
      state.revisions.push({ message_id: messageId, revision: row.revision, body: row.body,
                             edited_by_kind: row.author_kind, edited_by_id: row.author_id });
      row.body = body;
      row.revision += 1;
      row.edited_at = new Date('2026-10-08T12:00:00.000Z');
      return { ...row };
    },

    async markMessageDeleted(_tx, { messageId, deletedByKind, deletedById }) {
      const row = state.messages.find((message) => message.id === messageId);
      state.revisions = state.revisions.filter((revision) => revision.message_id !== messageId);
      row.body = '';
      row.deleted_at = new Date('2026-10-08T13:00:00.000Z');
      row.deleted_by_kind = deletedByKind;
      row.deleted_by_id = deletedById;
      return { ...row };
    },

    async advanceLastReadSeq(_tx, { threadId, participantKind, participantId, readSeq }) {
      const row = findMember(threadId, participantKind, participantId);
      row.last_read_seq = Math.max(row.last_read_seq, readSeq);
      return { ...row };
    },

    async audit(_tx, entry) {
      state.audits.push(entry);
    },
  };

  return port;
}

// The factories take a port that already exists; a helper that built a fresh port per call
// would hide exactly the bug these tests are for (a resend landing in a different room).
const send = (port) => createMessageSend({ port });
const edit = (port) => createMessageEdit({ port });
const remove = (port) => createMessageDelete({ port });
const markRead = (port) => createReadMark({ port });
const listMessages = (port) => createMessageList({ port });
const listThreads = (port) => createThreadList({ port });

const sendArgs = (port, overrides = {}) => ({
  principal,
  familyId: FAMILY,
  threadId: THREAD,
  body: 'السلام عليكم',
  clientMessageId: 'client-0001',
  idempotencyKey: 'key-1',
  requestHash: 'a'.repeat(64),
  correlationId: '11111111-2222-4333-8444-555555555555',
  ...overrides,
});

// ── the shapes a screen reads ─────────────────────────────────────────────────────────────

test('the current chat advertises polling and text only while reserving future capability flags', () => {
  assert.equal(CHAT_CURRENT_CAPABILITIES.transport, 'polling');
  assert.equal(CHAT_CURRENT_CAPABILITIES.listPollSeconds, 30);
  assert.equal(CHAT_CURRENT_CAPABILITIES.threadPollSeconds, 15);
  assert.deepEqual(CHAT_CURRENT_CAPABILITIES.contentTypes, ['text/plain']);
  for (const feature of [
    'serverSentEvents',
    'webSockets',
    'attachments',
    'audio',
    'presence',
    'richReactions',
  ]) {
    assert.equal(CHAT_CURRENT_CAPABILITIES[feature], false, `${feature} is not implemented yet`);
  }
});

test('a read mark or a page that runs backwards is refused before any query is made', () => {
  assert.deepEqual(normalizeMessageQuery({}), { afterSeq: 0, limit: 50 });
  assert.deepEqual(normalizeMessageQuery({ afterSeq: 7, limit: 200 }), { afterSeq: 7, limit: 200 });
  assert.throws(() => normalizeMessageQuery({ afterSeq: -1 }), (error) => error.code === 'chat_after_seq_invalid');
  assert.throws(() => normalizeMessageQuery({ limit: 0 }), (error) => error.code === 'chat_limit_invalid');
  assert.throws(() => normalizeMessageQuery({ limit: 201 }), (error) => error.code === 'chat_limit_invalid');
  // A read mark cannot pass the newest message: a client claiming otherwise is trying to make
  // somebody else's receipt meaningless, not reporting what it saw.
  assert.equal(requireReadableSeq({ readSeq: 3, highestSeq: 3 }), 3);
  assert.throws(
    () => requireReadableSeq({ readSeq: 4, highestSeq: 3 }),
    (error) => error.code === 'chat_read_ahead' && error.status === 409,
  );
  // An edit must state a revision, and 0 is not one.
  assert.throws(() => expectedRevision(0), (error) => error.code === 'chat_revision_required');
  assert.throws(() => expectedRevision(undefined), (error) => error.code === 'chat_revision_required');
});

test('a deleted message keeps its sequence and its trace, and loses its text', () => {
  const row = messageRow({
    seq: 4,
    body: '',
    deleted_at: new Date('2026-10-08T13:00:00.000Z'),
    deleted_by_kind: 'membership',
    deleted_by_id: PRIMARY,
  });
  const view = messageView(row, { readCount: 2 });
  assert.equal(view.body, null);
  assert.equal(view.deleted, true);
  assert.equal(view.seq, 4);
  assert.equal(view.deletedByKind, 'membership');
  assert.equal(view.deletedById, PRIMARY);
  assert.equal(view.deletedAt, '2026-10-08T13:00:00.000Z');
  assert.equal(view.readCount, 2);
  // A live message states its own moment and carries no deletion trace at all.
  const live = messageView(messageRow());
  assert.equal(live.deleted, false);
  assert.equal(live.deletedAt, null);
  assert.equal(live.editedAt, null);
  assert.equal(live.revision, 1);
});

test('a participant is shown without a durable identifier for a person, and self is decided here', () => {
  const self = participantView(
    { participant_kind: 'membership', participant_id: PRIMARY, membership_role: 'primary_guardian', child_display_name: null },
    { selfMembershipId: PRIMARY },
  );
  assert.deepEqual(self, { kind: 'membership', id: PRIMARY, role: 'primary_guardian', displayName: null, isSelf: true });
  const child = participantView(
    { participant_kind: 'child', participant_id: CHILD, membership_role: null, child_display_name: 'أماني' },
    { selfMembershipId: PRIMARY },
  );
  assert.equal(child.displayName, 'أماني');
  assert.equal(child.isSelf, false);
  assert.equal('target_subject' in self, false);
});

test('a thread carries its participants and the caller\'s own read state', () => {
  const view = threadView(
    { id: THREAD, kind: 'family', title: 'العائلة', created_at: new Date('2026-10-08T08:00:00.000Z'), last_read_seq: 3 },
    {
      participants: [{ thread_id: THREAD, participant_kind: 'membership', participant_id: PRIMARY,
                       membership_role: 'primary_guardian', child_display_name: null }],
      unreadCount: 2,
      selfMembershipId: PRIMARY,
    },
  );
  assert.equal(view.kind, 'family');
  assert.equal(view.lastReadSeq, 3);
  assert.equal(view.unreadCount, 2);
  assert.equal(view.participants.length, 1);
  assert.equal(view.lastMessage, null);
  assert.equal(view.participants[0].isSelf, true);
});

test('the preview of a thread list is the message, not the thread row wearing its name', () => {
  const row = {
    id: THREAD,
    last_id: 'message-7',
    last_seq: 7,
    last_author_kind: 'child',
    last_author_id: CHILD,
    last_body: 'وصلتُ إلى البيت',
    last_revision: 1,
    last_edited_at: null,
    last_deleted_at: null,
    last_deleted_by_kind: null,
    last_deleted_by_id: null,
    last_created_at: new Date('2026-10-08T11:00:00.000Z'),
    last_read_count: 2,
  };
  const preview = threadLastMessage(row);
  assert.equal(preview.id, 'message-7');
  assert.equal(preview.seq, 7);
  assert.equal(preview.authorKind, 'child');
  assert.equal(preview.body, 'وصلتُ إلى البيت');
  assert.equal(preview.readCount, 2);
  assert.notEqual(preview.id, THREAD);
  // An empty room has no preview at all, rather than a thread row pretending to be a message.
  assert.equal(threadLastMessage({ id: THREAD, last_id: null }), null);
});

// ── opening rooms: the laws that decide who can reach a child ─────────────────────────────

test('direct conversations are pairs and groups name at least two other family participants', async () => {
  const port = memoryPort();
  const create = createThreadCreate({ port });
  await assert.rejects(
    create({
      principal, familyId: FAMILY, kind: 'direct', participants: [],
      idempotencyKey: 'direct-none', requestHash: 'h', correlationId: 'c',
    }),
    (error) => error.status === 422 && error.code === 'chat_participant_count_invalid',
  );
  await assert.rejects(
    create({
      principal, familyId: FAMILY, kind: 'direct',
      participants: [{ kind: 'child', id: CHILD }, { kind: 'child', id: SIBLING }],
      idempotencyKey: 'direct-many', requestHash: 'h', correlationId: 'c',
    }),
    (error) => error.status === 422 && error.code === 'chat_participant_count_invalid',
  );
  await assert.rejects(
    create({
      principal, familyId: FAMILY, kind: 'group', participants: [{ kind: 'child', id: CHILD }],
      idempotencyKey: 'group-small', requestHash: 'h', correlationId: 'c',
    }),
    (error) => error.status === 422 && error.code === 'chat_participant_count_invalid',
  );
  assert.equal(port.state.threads.length, 1);
  assert.equal(port.state.audits.length, 0);
});

test('guardians explicitly choose direct pairs and groups from the live roster; default policy adds no guardian', async () => {
  const port = memoryPort({
    memberships: [
      membershipRow(),
      membershipRow({ id: CO_GUARDIAN, target_subject: 'test-co', role: 'co_guardian' }),
      membershipRow({
        id: PENDING_GUARDIAN,
        target_subject: 'invited-co',
        role: 'co_guardian',
        status: 'invited',
      }),
      membershipRow({
        id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        target_subject: 'test-child',
        role: 'child',
      }),
    ],
  });
  const create = createThreadCreate({ port });
  const direct = await create({
    principal,
    familyId: FAMILY,
    kind: 'direct',
    title: 'Amani',
    participants: [{ kind: 'child', id: CHILD }],
    idempotencyKey: 'direct-child',
    requestHash: 'h1',
    correlationId: 'c',
  });
  assert.equal(direct.thread.kind, 'direct');
  assert.deepEqual(
    direct.thread.participants.map((entry) => `${entry.kind}:${entry.id}`).sort(),
    [`child:${CHILD}`, `membership:${PRIMARY}`].sort(),
  );

  const group = await create({
    principal,
    familyId: FAMILY,
    kind: 'group',
    title: 'The children',
    participants: [{ kind: 'child', id: CHILD }, { kind: 'child', id: SIBLING }],
    idempotencyKey: 'group-children',
    requestHash: 'h2',
    correlationId: 'c',
  });
  assert.equal(group.thread.kind, 'group');
  assert.deepEqual(
    group.thread.participants.map((entry) => `${entry.kind}:${entry.id}`).sort(),
    [`child:${CHILD}`, `child:${SIBLING}`, `membership:${PRIMARY}`].sort(),
  );

  await assert.rejects(
    create({
      principal, familyId: FAMILY, kind: 'direct', participants: [{ kind: 'child', id: '00000000-0000-4000-8000-000000000000' }],
      idempotencyKey: 'foreign-child', requestHash: 'h3', correlationId: 'c',
    }),
    (error) => error.status === 404 && error.code === 'chat_participant_not_found',
  );
  assert.equal(port.state.threads.length, 3);
  assert.equal(port.state.audits.length, 2);
});

test('active server safety policy, and only that policy, adds guardians to child conversations', async () => {
  const memberships = [
    membershipRow(),
    membershipRow({ id: CO_GUARDIAN, target_subject: 'test-co', role: 'co_guardian' }),
    membershipRow({ id: PENDING_GUARDIAN, target_subject: 'pending-co', role: 'co_guardian', status: 'invited' }),
    membershipRow({ id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', target_subject: 'test-child', role: 'child' }),
  ];
  const port = memoryPort({
    memberships,
    collaborationPolicy: { ...DEFAULT_CHAT_POLICY, guardianInclusionMode: 'all_child_chats' },
  });
  const result = await createThreadCreate({ port })({
    principal,
    familyId: FAMILY,
    kind: 'direct',
    title: '',
    participants: [{ kind: 'child', id: CHILD }],
    idempotencyKey: 'policy-inclusion',
    requestHash: 'h',
    correlationId: 'c',
  });
  assert.deepEqual(
    result.thread.participants.map((entry) => `${entry.kind}:${entry.id}`).sort(),
    [`child:${CHILD}`, `membership:${PRIMARY}`, `membership:${CO_GUARDIAN}`].sort(),
  );
  assert.equal(port.state.audits[0].eventType, 'family.chat_thread_created');
});

test('a paired child can create direct or group chats only under the server-owned child policy', async () => {
  const createDisabled = createDeviceThreadCreate({
    port: memoryPort({
      collaborationPolicy: {
        ...DEFAULT_CHAT_POLICY,
        childDirectEnabled: false,
        childGroupsEnabled: false,
      },
    }),
  });
  await assert.rejects(
    createDisabled({
      deviceId: DEVICE,
      deviceCredential: DEVICE_CREDENTIAL,
      kind: 'direct',
      participants: [{ kind: 'membership', id: PRIMARY }],
      idempotencyKey: 'child-disabled',
      requestHash: 'h',
      correlationId: 'c',
    }),
    (error) => error.status === 403 && error.code === 'chat_child_creation_disabled',
  );

  const port = memoryPort({
    memberships: [
      membershipRow(),
      membershipRow({ id: CO_GUARDIAN, target_subject: 'test-co', role: 'co_guardian' }),
    ],
  });
  const create = createDeviceThreadCreate({ port });
  const direct = await create({
    deviceId: DEVICE,
    deviceCredential: DEVICE_CREDENTIAL,
    kind: 'direct',
    participants: [{ kind: 'membership', id: PRIMARY }],
    idempotencyKey: 'child-direct',
    requestHash: 'h1',
    correlationId: 'c',
  });
  assert.deepEqual(
    direct.thread.participants.map((entry) => `${entry.kind}:${entry.id}`).sort(),
    [`child:${CHILD}`, `membership:${PRIMARY}`].sort(),
  );
  const group = await create({
    deviceId: DEVICE,
    deviceCredential: DEVICE_CREDENTIAL,
    kind: 'group',
    participants: [{ kind: 'membership', id: CO_GUARDIAN }, { kind: 'child', id: SIBLING }],
    idempotencyKey: 'child-group',
    requestHash: 'h2',
    correlationId: 'c',
  });
  assert.equal(group.thread.kind, 'group');
  assert.deepEqual(
    group.thread.participants.map((entry) => `${entry.kind}:${entry.id}`).sort(),
    [`child:${CHILD}`, `child:${SIBLING}`, `membership:${CO_GUARDIAN}`].sort(),
  );
});

test('a child manages only groups enabled by server policy; new members start at the next sequence', async () => {
  const room = [{
    id: CHILD_THREAD,
    family_id: FAMILY,
    kind: 'group',
    title: 'The children',
    next_seq: 9,
    created_by_membership_id: null,
    created_by_child_id: CHILD,
    created_by_participant_kind: 'child',
    created_by_participant_id: CHILD,
    created_at: new Date('2026-10-08T08:00:00.000Z'),
  }];
  const members = [{
    thread_id: CHILD_THREAD,
    family_id: FAMILY,
    participant_kind: 'child',
    participant_id: CHILD,
    membership_id: null,
    child_id: CHILD,
    joined_seq: 1,
    last_read_seq: 0,
  }];
  const memberships = [
    membershipRow(),
    membershipRow({ id: CO_GUARDIAN, target_subject: 'test-co', role: 'co_guardian' }),
  ];
  const disabled = memoryPort({
    memberships,
    threads: room,
    members,
    collaborationPolicy: { ...DEFAULT_CHAT_POLICY, childGroupMemberManagementEnabled: false },
  });
  await assert.rejects(
    createDeviceThreadMemberAdd({ port: disabled })({
      deviceId: DEVICE,
      deviceCredential: DEVICE_CREDENTIAL,
      threadId: CHILD_THREAD,
      participantKind: 'child',
      participantId: SIBLING,
      idempotencyKey: 'child-manage-disabled',
      requestHash: 'h',
      correlationId: 'c',
    }),
    (error) => error.status === 403 && error.code === 'chat_group_management_disabled',
  );
  assert.equal(disabled.state.members.length, 1);

  const port = memoryPort({
    memberships,
    threads: room,
    members,
    collaborationPolicy: {
      ...DEFAULT_CHAT_POLICY,
      guardianInclusionMode: 'child_to_child',
    },
  });
  const result = await createDeviceThreadMemberAdd({ port })({
    deviceId: DEVICE,
    deviceCredential: DEVICE_CREDENTIAL,
    threadId: CHILD_THREAD,
    participantKind: 'child',
    participantId: SIBLING,
    idempotencyKey: 'child-add-sibling',
    requestHash: 'h',
    correlationId: 'c',
  });
  assert.equal(result.thread.participants.length, 4);
  assert.deepEqual(
    result.thread.participants.map((entry) => `${entry.kind}:${entry.id}`).sort(),
    [`child:${CHILD}`, `child:${SIBLING}`, `membership:${PRIMARY}`, `membership:${CO_GUARDIAN}`].sort(),
  );
  for (const member of port.state.members.filter((entry) => entry.thread_id === CHILD_THREAD && entry.participant_id !== CHILD)) {
    assert.equal(member.joined_seq, 9);
  }
  assert.equal(port.state.audits[0].actorMembershipId, null);
});

test('a child guardian-role membership cannot use the guardian conversation-creation route', async () => {
  const childMembership = membershipRow({
    id: CO_GUARDIAN,
    target_subject: 'test-child',
    role: 'child',
  });
  const port = memoryPort({ memberships: [membershipRow(), childMembership] });
  await assert.rejects(
    createThreadCreate({ port })({
      principal: childPrincipal,
      familyId: FAMILY,
      kind: 'direct',
      participants: [{ kind: 'membership', id: PRIMARY }],
      idempotencyKey: 'child-via-guardian-route',
      requestHash: 'h',
      correlationId: 'c',
    }),
    (error) => error.status === 403 && error.code === 'chat_forbidden',
  );
});

// ── membership is the permission ──────────────────────────────────────────────────────────

test('a guardian who is not in a room is answered as if the room did not exist', async () => {
  const port = memoryPort({
    memberships: [membershipRow(), membershipRow({ id: CO_GUARDIAN, target_subject: 'test-co', role: 'co_guardian' })],
  });
  const read = listMessages(port);
  await assert.rejects(
    read({ principal: coPrincipal, familyId: FAMILY, threadId: THREAD }),
    (error) => error.status === 404 && error.code === 'chat_thread_not_found',
  );
  // The list read agrees: the co-guardian sees no rooms, without an error and without a hint.
  const listed = await listThreads(port)({ principal: coPrincipal, familyId: FAMILY });
  assert.deepEqual(listed.threads, []);
  const ownList = await listThreads(port)({ principal, familyId: FAMILY });
  assert.equal(ownList.threads.length, 1);
});

test('guardian group membership changes require room membership and legacy child rooms remain single-child', async () => {
  const room = [{ id: CHILD_THREAD, family_id: FAMILY, kind: 'child', title: 'أماني', next_seq: 1,
                  created_by_membership_id: PRIMARY, created_at: new Date('2026-10-08T08:00:00.000Z') }];
  const members = [
    { thread_id: CHILD_THREAD, family_id: FAMILY, participant_kind: 'child',
      participant_id: CHILD, membership_id: null, child_id: CHILD, last_read_seq: 0 },
    { thread_id: CHILD_THREAD, family_id: FAMILY, participant_kind: 'membership',
      participant_id: PRIMARY, membership_id: PRIMARY, child_id: null, last_read_seq: 0 },
  ];
  const options = {
    memberships: [
      membershipRow(),
      membershipRow({ id: CO_GUARDIAN, target_subject: 'test-co', role: 'co_guardian' }),
      membershipRow({
        id: PENDING_GUARDIAN,
        target_subject: 'test-pending',
        role: 'co_guardian',
        status: 'invited',
      }),
    ],
    threads: room,
    members,
  };
  const port = memoryPort(options);
  const add = createThreadMemberAdd({ port });

  // An outsider rearranging somebody else's conversation is refused, and told nothing.
  await assert.rejects(
    add({ principal: coPrincipal, familyId: FAMILY, threadId: CHILD_THREAD,
          participantKind: 'membership', participantId: CO_GUARDIAN,
          idempotencyKey: 'k1', requestHash: 'h', correlationId: 'c' }),
    (error) => error.status === 404 && error.code === 'chat_thread_not_found',
  );

  // A pending guardian is not part of the server's active roster and cannot be added yet.
  await assert.rejects(
    add({ principal, familyId: FAMILY, threadId: CHILD_THREAD,
          participantKind: 'membership', participantId: PENDING_GUARDIAN,
          idempotencyKey: 'k-pending', requestHash: 'h', correlationId: 'c' }),
    (error) => error.status === 404 && error.code === 'chat_participant_not_found',
  );

  // The guardian who IS in the room may add a guardian who became active after room creation.
  await add({ principal, familyId: FAMILY, threadId: CHILD_THREAD,
              participantKind: 'membership', participantId: CO_GUARDIAN,
              idempotencyKey: 'k2', requestHash: 'h', correlationId: 'c' });
  assert.equal(port.state.members.length, 3);

  // The same person again is a conflict, not a second row.
  await assert.rejects(
    add({ principal, familyId: FAMILY, threadId: CHILD_THREAD,
          participantKind: 'membership', participantId: CO_GUARDIAN,
          idempotencyKey: 'k3', requestHash: 'h', correlationId: 'c' }),
    (error) => error.status === 409 && error.code === 'chat_member_already_present',
  );

  // Legacy child-only rooms are retained but cannot be expanded into new group conversations.
  await assert.rejects(
    add({ principal, familyId: FAMILY, threadId: CHILD_THREAD,
          participantKind: 'child', participantId: SIBLING,
          idempotencyKey: 'k4', requestHash: 'h', correlationId: 'c' }),
    (error) => error.status === 409 && error.code === 'chat_legacy_child_room_full',
  );
});

// ── saying something ──────────────────────────────────────────────────────────────────────

test('the author of a message is decided by how the request arrived, never by the body', async () => {
  const port = memoryPort({
    members: [
      { thread_id: THREAD, family_id: FAMILY, participant_kind: 'membership', participant_id: PRIMARY,
        membership_id: PRIMARY, child_id: null, last_read_seq: 0 },
      { thread_id: THREAD, family_id: FAMILY, participant_kind: 'child', participant_id: CHILD,
        membership_id: null, child_id: CHILD, last_read_seq: 0 },
    ],
  });
  const guardianSent = await send(port)(sendArgs(port));
  assert.equal(guardianSent.message.authorKind, 'membership');
  assert.equal(guardianSent.message.authorId, PRIMARY);
  assert.equal(guardianSent.replayed, false);

  const handsetSent = await createMessageSend({ port })(sendArgs(port, {
    principal: undefined,
    deviceId: DEVICE,
    deviceCredential: DEVICE_CREDENTIAL,
    clientMessageId: 'client-0002',
    // Its own idempotency key: a distinct request, not a retry of the guardian's.
    idempotencyKey: 'key-device-1',
    requestHash: 'd'.repeat(64),
  }));
  assert.equal(handsetSent.message.authorKind, 'child');
  assert.equal(handsetSent.message.authorId, CHILD);
  assert.deepEqual(port.state.messages.map((row) => row.seq), [1, 2]);
});

test('a resend of the same client message is the same message, with the sequence it already had', async () => {
  const port = memoryPort();
  const first = await send(port)(sendArgs(port));
  const second = await send(port)(sendArgs(port, { idempotencyKey: 'key-2', requestHash: 'b'.repeat(64) }));
  assert.equal(second.replayed, true);
  assert.equal(second.message.id, first.message.id);
  assert.equal(second.message.seq, 1);
  // One sequence number was handed out, one message exists, and one audit line was written.
  assert.equal(port.state.sequencesAllocated, 1);
  assert.equal(port.state.messages.length, 1);
  assert.equal(port.state.audits.length, 1);
});

test('a resend is answered with the receipt that is true now, not a fixed zero', async () => {
  const port = memoryPort({
    members: [
      { thread_id: THREAD, family_id: FAMILY, participant_kind: 'membership', participant_id: PRIMARY,
        membership_id: PRIMARY, child_id: null, last_read_seq: 0 },
      { thread_id: THREAD, family_id: FAMILY, participant_kind: 'membership', participant_id: CO_GUARDIAN,
        membership_id: CO_GUARDIAN, child_id: null, last_read_seq: 0 },
    ],
    memberships: [membershipRow(), membershipRow({ id: CO_GUARDIAN, target_subject: 'test-co', role: 'co_guardian' })],
  });
  const first = await send(port)(sendArgs(port));
  await markRead(port)({ principal: coPrincipal, familyId: FAMILY, threadId: THREAD, readSeq: 1,
                         idempotencyKey: 'r1', requestHash: 'h', correlationId: 'c' });
  const resent = await send(port)(sendArgs(port, { idempotencyKey: 'key-2', requestHash: 'b'.repeat(64) }));
  assert.equal(resent.replayed, true);
  assert.equal(resent.message.id, first.message.id);
  assert.equal(resent.message.readCount, 1);
});

test('a handset with a valid credential still cannot write in a room its child is not in', async () => {
  const port = memoryPort();
  await assert.rejects(
    createMessageSend({ port })(sendArgs(port, {
      principal: undefined, deviceId: DEVICE, deviceCredential: DEVICE_CREDENTIAL,
    })),
    (error) => error.status === 404 && error.code === 'chat_thread_not_found',
  );
  assert.equal(port.state.messages.length, 0);
  // And a revoked credential is refused before any thread is even considered.
  const revoked = memoryPort({ devices: [{ id: DEVICE, family_id: FAMILY, child_id: CHILD, revoked_at: new Date() }] });
  await assert.rejects(
    createMessageSend({ port: revoked })(sendArgs(revoked, {
      principal: undefined, deviceId: DEVICE, deviceCredential: DEVICE_CREDENTIAL,
    })),
    (error) => error.code === 'device_credential_rejected',
  );
});

test('a page of messages is ordered by the server\'s sequence and states who read up to each', async () => {
  const port = memoryPort({
    members: [
      { thread_id: THREAD, family_id: FAMILY, participant_kind: 'membership', participant_id: PRIMARY,
        membership_id: PRIMARY, child_id: null, last_read_seq: 2 },
      { thread_id: THREAD, family_id: FAMILY, participant_kind: 'membership', participant_id: CO_GUARDIAN,
        membership_id: CO_GUARDIAN, child_id: null, last_read_seq: 1 },
    ],
    memberships: [membershipRow(), membershipRow({ id: CO_GUARDIAN, target_subject: 'test-co', role: 'co_guardian' })],
  });
  const send_ = send(port);
  for (const [clientMessageId, body] of [['client-0001', 'أولاً'], ['client-0002', 'ثانياً'], ['client-0003', 'ثالثاً']]) {
    await send_({ principal, familyId: FAMILY, threadId: THREAD, body, clientMessageId,
                  idempotencyKey: `k-${clientMessageId}`, requestHash: 'h', correlationId: 'c' });
  }
  const page = await createMessageList({ port })({ principal, familyId: FAMILY, threadId: THREAD, afterSeq: 0, limit: 2 });
  assert.deepEqual(page.messages.map((row) => row.seq), [1, 2]);
  assert.equal(page.hasMore, true);
  assert.equal(page.readState.lastReadSeq, 2);
  // The author's own mark never counts as a reader of their own message; the co-guardian's
  // mark of 1 counts for the first message and for nothing after it.
  assert.deepEqual(page.messages.map((row) => row.readCount), [1, 0]);

  const next = await createMessageList({ port })({ principal, familyId: FAMILY, threadId: THREAD, afterSeq: 2, limit: 50 });
  assert.deepEqual(next.messages.map((row) => row.seq), [3]);
  assert.equal(next.hasMore, false);
  assert.equal(next.messages[0].readCount, 0);
});

// ── editing and deleting: the two acts that change what was said ──────────────────────────

test('only the author edits their own words, and only against the revision they read', async () => {
  const port = memoryPort({
    memberships: [membershipRow(), membershipRow({ id: CO_GUARDIAN, target_subject: 'test-co', role: 'co_guardian' })],
    members: [
      { thread_id: THREAD, family_id: FAMILY, participant_kind: 'membership', participant_id: PRIMARY,
        membership_id: PRIMARY, child_id: null, last_read_seq: 0 },
      { thread_id: THREAD, family_id: FAMILY, participant_kind: 'membership', participant_id: CO_GUARDIAN,
        membership_id: CO_GUARDIAN, child_id: null, last_read_seq: 0 },
    ],
    messages: [messageRow({ id: 'message-1', seq: 1 })],
  });
  const edit_ = edit(port);

  await assert.rejects(
    edit_({ principal: coPrincipal, familyId: FAMILY, threadId: THREAD, messageId: 'message-1', body: 'غيرتُها', revision: 1 }),
    (error) => error.status === 403 && error.code === 'chat_not_author',
  );
  await assert.rejects(
    edit_({ principal, familyId: FAMILY, threadId: THREAD, messageId: 'message-1', body: 'غيرتُها', revision: 2 }),
    (error) => error.status === 409 && error.code === 'chat_message_stale_revision',
  );

  const edited = await edit_({ principal, familyId: FAMILY, threadId: THREAD, messageId: 'message-1', body: 'السلام عليكم ورحمة الله', revision: 1 });
  assert.equal(edited.message.revision, 2);
  assert.equal(edited.message.body, 'السلام عليكم ورحمة الله');
  assert.equal(edited.message.editedAt, '2026-10-08T12:00:00.000Z');
  // The body it replaced is kept, so the edit is provable rather than a silent rewrite.
  assert.deepEqual(port.state.revisions, [{
    message_id: 'message-1', revision: 1, body: 'السلام عليكم',
    edited_by_kind: 'membership', edited_by_id: PRIMARY,
  }]);
  assert.equal(port.state.audits.at(-1).eventType, 'family.chat_message_edited');
});

test('a guardian cannot delete a child\'s words, and the author\'s own deletion keeps the trace', async () => {
  const port = memoryPort({
    memberships: [membershipRow(), membershipRow({ id: CO_GUARDIAN, target_subject: 'test-co', role: 'co_guardian' })],
    members: [
      { thread_id: THREAD, family_id: FAMILY, participant_kind: 'membership', participant_id: PRIMARY,
        membership_id: PRIMARY, child_id: null, last_read_seq: 0 },
      { thread_id: THREAD, family_id: FAMILY, participant_kind: 'child', participant_id: CHILD,
        membership_id: null, child_id: CHILD, last_read_seq: 0 },
    ],
    threads: [{ id: THREAD, family_id: FAMILY, kind: 'child', title: 'أماني', next_seq: 2,
                created_by_membership_id: PRIMARY, created_at: new Date('2026-10-08T08:00:00.000Z') }],
    messages: [messageRow({ id: 'message-child', seq: 1, author_kind: 'child', author_id: CHILD, body: 'أنا في المدرسة' })],
  });
  const remove_ = remove(port);

  // The guardian is a member of the room - and still cannot delete what the child wrote. This
  // is the refusal that separates a family product from a surveillance tool.
  await assert.rejects(
    remove_({ principal, familyId: FAMILY, threadId: THREAD, messageId: 'message-child',
              idempotencyKey: 'k1', requestHash: 'h', correlationId: 'c' }),
    (error) => error.status === 403 && error.code === 'chat_not_author',
  );
  // The child deletes their own, from the handset that proves which child they are.
  const deleted = await remove_({ deviceId: DEVICE, deviceCredential: DEVICE_CREDENTIAL, threadId: THREAD,
                                  messageId: 'message-child', idempotencyKey: 'k2', requestHash: 'h', correlationId: 'c' });
  assert.equal(deleted.message.body, null);
  assert.equal(deleted.message.seq, 1);
  assert.equal(deleted.message.deletedByKind, 'child');
  assert.equal(deleted.message.deletedById, CHILD);
  assert.equal(port.state.revisions.length, 0);

  // Deleting twice is refused: silence would let two people each believe they removed it.
  await assert.rejects(
    remove_({ deviceId: DEVICE, deviceCredential: DEVICE_CREDENTIAL, threadId: THREAD,
              messageId: 'message-child', idempotencyKey: 'k3', requestHash: 'h', correlationId: 'c' }),
    (error) => error.status === 409 && error.code === 'chat_message_already_deleted',
  );
  // And a deleted message is not edited.
  await assert.rejects(
    createMessageEdit({ port })({ deviceId: DEVICE, deviceCredential: DEVICE_CREDENTIAL, threadId: THREAD,
                                  messageId: 'message-child', body: 'شيء آخر', revision: 1 }),
    (error) => error.status === 409 && error.code === 'chat_message_deleted',
  );
});

// ── receipts: the one honest thing this surface can say about reading ─────────────────────

test('a read mark only moves forward, and cannot pass the newest message', async () => {
  const port = memoryPort({
    members: [
      { thread_id: THREAD, family_id: FAMILY, participant_kind: 'membership', participant_id: PRIMARY,
        membership_id: PRIMARY, child_id: null, last_read_seq: 0 },
      { thread_id: THREAD, family_id: FAMILY, participant_kind: 'membership', participant_id: CO_GUARDIAN,
        membership_id: CO_GUARDIAN, child_id: null, last_read_seq: 0 },
    ],
    memberships: [membershipRow(), membershipRow({ id: CO_GUARDIAN, target_subject: 'test-co', role: 'co_guardian' })],
  });
  await send(port)(sendArgs(port));
  await send(port)(sendArgs(port, { clientMessageId: 'client-0002', idempotencyKey: 'k2' }));

  const mark = markRead(port);
  const first = await mark({ principal, familyId: FAMILY, threadId: THREAD, readSeq: 2,
                             idempotencyKey: 'r1', requestHash: 'h', correlationId: 'c' });
  assert.equal(first.readState.lastReadSeq, 2);
  // A stale client cannot un-read anything.
  const stale = await mark({ principal, familyId: FAMILY, threadId: THREAD, readSeq: 1,
                             idempotencyKey: 'r2', requestHash: 'g', correlationId: 'c' });
  assert.equal(stale.readState.lastReadSeq, 2);
  // And a mark that runs past the newest message is refused rather than clamped silently.
  await assert.rejects(
    mark({ principal, familyId: FAMILY, threadId: THREAD, readSeq: 9,
           idempotencyKey: 'r3', requestHash: 'i', correlationId: 'c' }),
    (error) => error.status === 409 && error.code === 'chat_read_ahead',
  );

  // The reader count now says one: the co-guardian has read up to message two, and the author is
  // never counted as a reader of their own words.
  const page = await createMessageList({ port })({ principal: coPrincipal, familyId: FAMILY, threadId: THREAD });
  assert.equal(page.readState.lastReadSeq, 0);
  const asAuthor = await createMessageList({ port })({ principal, familyId: FAMILY, threadId: THREAD });
  assert.deepEqual(asAuthor.messages.map((row) => row.readCount), [0, 0]);

  await mark({ principal: coPrincipal, familyId: FAMILY, threadId: THREAD, readSeq: 1,
               idempotencyKey: 'r4', requestHash: 'j', correlationId: 'c' });
  const afterCoRead = await createMessageList({ port })({ principal, familyId: FAMILY, threadId: THREAD });
  assert.deepEqual(afterCoRead.messages.map((row) => row.readCount), [1, 0]);
});
