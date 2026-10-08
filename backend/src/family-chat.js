// W9 — the family chat: the one place in this product where a family writes things down.
//
// The master plan calls this wave the biggest security risk in the domain and orders it built
// last and carefully, and the risk is not the text. A calendar invents an event; a chat
// invents *a record of what people said to each other*. So the laws come before the feature:
//
//   * THE ROOM IS THE PERMISSION. Reading a thread means "a member row for this caller exists
//     in that thread". There is no guardian override, no role that reads everything - doc 40
//     states the product law this module implements: controlling who a child may contact is
//     not the same as reading every conversation the child is in. A caller who is not a
//     participant gets `chat_thread_not_found` for the thread, because the existence of a room
//     someone is not in is itself information they were not given.
//   * A MESSAGE HAS AN AUTHOR, AND THE AUTHOR IS DECIDED BY HOW THE REQUEST ARRIVED. A paired
//     handset writes as its own child; an authenticated person writes as their membership. No
//     field in a request body names an author, so no request can speak as somebody else.
//   * ORDERING IS THE SERVER'S. The sequence number is allocated from the thread's own counter
//     inside the sending transaction (`UPDATE ... RETURNING`), never from a client clock, so
//     two phones sending at once cannot share a number and a phone with a wrong time cannot
//     reorder a family's conversation.
//   * A RESEND IS THE SAME MESSAGE. `client_message_id` makes the retry of a send idempotent
//     in storage, not only in a table of request keys: the second attempt returns the message
//     that already exists, with the sequence it already has.
//   * AN EDIT IS SHOWN, NOT HIDDEN. Editing states the revision it read, keeps the previous
//     body in the revisions table, and moves `revision` and `edited_at` together - a reader can
//     always see that a message changed and when.
//   * DELETION IS A RIGHT, AND THE TRACE OUTLIVES IT. Only the author may delete their own
//     words - a guardian deleting a child's message would be rewriting the child, which is the
//     exact abuse this product exists to be unlike. Deletion clears the body and the stored
//     revisions and keeps the row, the sequence and who deleted when: the thread keeps its
//     shape, and the family keeps the knowledge that something was said and removed.
//   * A RECEIPT IS AGGREGATE, AND HONEST. There is no delivery table in this wave because
//     there is no push transport to prove a delivery, and there is no per-person "seen" list
//     because that turns a family room into a surveillance log. The one receipt stated here is
//     `readCount`: how many OTHER participants have marked themselves read up to this message.
//     A participant's own read mark is their own statement and only ever moves forward.
//   * THE TEXT IS STORED AS TEXT, AND NOTHING HERE CLAIMS OTHERWISE. Doc 46 forbids any claim
//     of end-to-end encryption, permanent reachability or delivery until the protocol that
//     would make it true is implemented and verified. This module stores the body in the row,
//     says so in its contract, and the client must not draw a lock it cannot prove.
//
// Everything below is either a pure function (testable without a socket) or a thin translation
// of one into SQL. No decision is duplicated in the route layer, and no fact is stored twice.

import { randomUUID } from 'node:crypto';

import { HttpError } from './http-error.js';
import {
  collaborationRoleAllowed,
  readCollaborationPolicy as readServerCollaborationPolicy,
} from './collaboration-policy.js';

export const CHAT_THREAD_KINDS = Object.freeze(['family', 'child', 'direct', 'group']);
export const CHAT_CREATABLE_THREAD_KINDS = Object.freeze(['direct', 'group']);
export const CHAT_PARTICIPANT_KINDS = Object.freeze(['membership', 'child']);

export const CHAT_TITLE_MAX = 120;
export const CHAT_BODY_MAX = 2000;
export const CHAT_CLIENT_MESSAGE_ID_MIN = 8;
export const CHAT_CLIENT_MESSAGE_ID_MAX = 64;
export const CHAT_PARTICIPANTS_MAX = 24;
export const CHAT_PAGE_MAX = 200;
export const CHAT_PAGE_DEFAULT = 50;

export const CHAT_CURRENT_CAPABILITIES = Object.freeze({
  transport: 'polling',
  listPollSeconds: 30,
  threadPollSeconds: 15,
  contentTypes: Object.freeze(['text/plain']),
  serverSentEvents: false,
  webSockets: false,
  attachments: false,
  audio: false,
  presence: false,
  richReactions: false,
});

const GUARDIAN_ROLES = new Set(['primary_guardian', 'co_guardian']);

export class ChatError extends HttpError {
  constructor(status, code, message) {
    super(status, code, message);
    this.name = 'ChatError';
  }
}

function instant(value) {
  const parsed = value instanceof Date ? value : new Date(value);
  return parsed.toISOString();
}

function optionalInstant(value) {
  return value == null ? null : instant(value);
}

/// The participant the caller speaks as. Exactly one of the two shapes is given: a membership
/// for an authenticated person, a child for a paired handset. This function is the ONLY place
/// an author is decided, which is why no request body can contain one.
function participantOf({ actor, device }) {
  if (device != null) {
    return { kind: 'child', id: device.child_id, membershipId: null, childId: device.child_id };
  }
  return { kind: 'membership', id: actor.id, membershipId: actor.id, childId: null };
}

// ── pure shapes ───────────────────────────────────────────────────────────────────────────

/// A participant as a screen may see them. Deliberately absent: the OIDC subject of a
/// membership. The roster module already decided that a guardian does not need a durable
/// identifier for a person to run a family, and a chat list has even less use for one.
export function participantView(row, { selfParticipant = null, selfMembershipId = null } = {}) {
  const self = selfParticipant == null
    ? row.participant_kind === 'membership' && row.participant_id === selfMembershipId
    : row.participant_kind === selfParticipant.kind && row.participant_id === selfParticipant.id;
  return {
    kind: row.participant_kind,
    id: row.participant_id,
    role: row.membership_role ?? null,
    displayName: row.child_display_name ?? null,
    isSelf: self,
  };
}

/// One message. A deleted message is returned with `body: null` and the trace intact - it is
/// part of the conversation's shape, and pretending the sequence number never existed is how a
/// reader stops trusting the numbering. `readCount` counts OTHER participants, never the
/// author: a person has trivially read what they just wrote.
export function messageView(row, { readCount = 0 } = {}) {
  const deleted = row.deleted_at != null;
  return {
    id: row.id,
    seq: Number(row.seq),
    authorKind: row.author_kind,
    authorId: row.author_id,
    body: deleted ? null : row.body,
    revision: row.revision,
    editedAt: optionalInstant(row.edited_at),
    deleted: deleted,
    deletedAt: optionalInstant(row.deleted_at),
    deletedByKind: row.deleted_by_kind ?? null,
    deletedById: row.deleted_by_id ?? null,
    createdAt: instant(row.created_at),
    readCount,
  };
}

/// The newest message of a thread list row. The columns there are prefixed (`last_body`) because
/// the row is a thread row with a lateral message attached, so the mapping is stated once here
/// rather than passed to `messageView` as if it were a message row - which would have read the
/// thread's own `id` and produced a preview of nothing.
export function threadLastMessage(row) {
  if (row.last_id == null) return null;
  return messageView(
    {
      id: row.last_id,
      seq: row.last_seq,
      author_kind: row.last_author_kind,
      author_id: row.last_author_id,
      body: row.last_body,
      revision: row.last_revision,
      edited_at: row.last_edited_at,
      deleted_at: row.last_deleted_at,
      deleted_by_kind: row.last_deleted_by_kind,
      deleted_by_id: row.last_deleted_by_id,
      created_at: row.last_created_at,
    },
    { readCount: Number(row.last_read_count ?? 0) },
  );
}

export function threadView(row, {
  participants = [],
  lastMessage = null,
  unreadCount = 0,
  selfMembershipId = null,
  selfParticipant = null,
} = {}) {
  return {
    id: row.id,
    kind: row.kind,
    title: row.title,
    createdAt: instant(row.created_at),
    lastReadSeq: Number(row.last_read_seq ?? 0),
    unreadCount,
    participants: participants.map((entry) => participantView(entry, { selfMembershipId, selfParticipant })),
    lastMessage,
  };
}

export function readStateView(row) {
  return {
    threadId: row.thread_id,
    participantKind: row.participant_kind,
    participantId: row.participant_id,
    lastReadSeq: Number(row.last_read_seq),
  };
}

/// The page a screen asks for. A read without a bound would ask the server for a family's whole
/// history to draw one screen, and `afterSeq` is what makes an incremental read possible
/// without a push transport: the client asks for what it has not seen.
export function normalizeMessageQuery({ afterSeq, limit }) {
  const from = afterSeq === undefined || afterSeq === null ? 0 : Number(afterSeq);
  if (!Number.isInteger(from) || from < 0) {
    throw new ChatError(400, 'chat_after_seq_invalid', 'afterSeq must be a whole number starting at 0.');
  }
  const size = limit === undefined || limit === null ? CHAT_PAGE_DEFAULT : Number(limit);
  if (!Number.isInteger(size) || size < 1 || size > CHAT_PAGE_MAX) {
    throw new ChatError(
      400,
      'chat_limit_invalid',
      `limit must be between 1 and ${CHAT_PAGE_MAX}.`,
    );
  }
  return { afterSeq: from, limit: size };
}

/// A read mark is a statement about what THIS participant has seen, so it may not run ahead of
/// the thread: a client that claims to have read sequence 900 of a thread that ends at 12 is
/// either confused or trying to make somebody else's receipt meaningless.
export function requireReadableSeq({ readSeq, highestSeq, minimumSeq = 0 }) {
  if (readSeq < minimumSeq) {
    throw new ChatError(
      409,
      'chat_read_before_join',
      'A new participant cannot mark conversation history from before they joined as read.',
    );
  }
  if (readSeq > highestSeq) {
    throw new ChatError(
      409,
      'chat_read_ahead',
      'A read mark cannot pass the newest message in the thread.',
    );
  }
  return readSeq;
}

/// An edit states the revision it read. Same law as W8's event version and for the same reason:
/// two writers must collide loudly rather than overwrite each other's words.
export function expectedRevision(value) {
  if (!Number.isInteger(value) || value < 1) {
    throw new ChatError(
      400,
      'chat_revision_required',
      'An edit must state the revision it read, as a whole number starting at 1.',
    );
  }
  return value;
}

// ── operations ────────────────────────────────────────────────────────────────────────────

function participantKey(participant) {
  return `${participant.kind}:${participant.id}`;
}

function directPairKey(left, right) {
  return [participantKey(left), participantKey(right)].sort().join('|');
}

async function createThreadInTransaction({
  port,
  tx,
  familyId,
  actor,
  creator,
  kind,
  title,
  requestedParticipants,
  correlationId,
}) {
  if (!CHAT_CREATABLE_THREAD_KINDS.includes(kind)) {
    throw new ChatError(
      422,
      'chat_legacy_thread_kind_retired',
      'New conversations must be direct or user-created groups; existing legacy rooms remain readable.',
    );
  }
  if (!Array.isArray(requestedParticipants)) {
    throw new ChatError(422, 'chat_participants_required', 'Name the other participants explicitly.');
  }

  const policy = await port.readCollaborationPolicy(tx, { familyId });
  if (creator.kind === 'child') {
    const allowed = kind === 'direct' ? policy.childDirectEnabled : policy.childGroupsEnabled;
    if (!allowed) {
      throw new ChatError(403, 'chat_child_creation_disabled', 'The family safety policy does not allow this child to start this conversation.');
    }
  } else if (!collaborationRoleAllowed(actor, policy, 'chatCreate')) {
    throw new ChatError(403, 'chat_forbidden', 'This guardian role cannot open a conversation under the family policy.');
  }

  const expectedTargets = kind === 'direct' ? 1 : null;
  if ((expectedTargets != null && requestedParticipants.length !== expectedTargets) ||
      (kind === 'group' && requestedParticipants.length < 2)) {
    throw new ChatError(
      422,
      'chat_participant_count_invalid',
      kind === 'direct'
        ? 'A direct conversation needs exactly one other family member.'
        : 'A user-created group needs at least two other family members.',
    );
  }

  const baseParticipants = [creator];
  const seen = new Set([participantKey(creator)]);
  for (const requested of requestedParticipants) {
    const kind_ = requested?.kind;
    const id = requested?.id;
    if (!CHAT_PARTICIPANT_KINDS.includes(kind_) || typeof id !== 'string' || id.length === 0) {
      throw new ChatError(422, 'chat_participant_invalid', 'Each participant must be a family membership or child.');
    }
    const key = participantKey({ kind: kind_, id });
    if (seen.has(key)) {
      throw new ChatError(422, 'chat_participant_repeated', 'A person may appear only once in a conversation.');
    }
    seen.add(key);
    if (kind_ === 'membership') {
      const membership = await port.readMembership(tx, { familyId, membershipId: id });
      if (membership == null || membership.status !== 'active' || !GUARDIAN_ROLES.has(membership.role)) {
        throw new ChatError(404, 'chat_participant_not_found', 'One of these active family participants is not available.');
      }
    } else {
      const child = await port.readChild(tx, { familyId, childId: id });
      if (child == null) {
        throw new ChatError(404, 'chat_participant_not_found', 'One of these active family participants is not available.');
      }
    }
    baseParticipants.push({ kind: kind_, id });
  }

  if (kind === 'group' && baseParticipants.length < 3) {
    throw new ChatError(422, 'chat_participant_count_invalid', 'A group needs at least three participants including its creator.');
  }

  const childCount = baseParticipants.filter((entry) => entry.kind === 'child').length;
  const guardianInclusionRequired = childCount > 0 && (
    policy.guardianInclusionMode === 'all_child_chats' ||
    (policy.guardianInclusionMode === 'child_to_child' && childCount > 1)
  );
  const participants = [...baseParticipants];
  if (guardianInclusionRequired) {
    const guardians = await port.listActiveGuardianMemberships(tx, { familyId });
    for (const membership of guardians) {
      if (membership.status !== 'active' || !GUARDIAN_ROLES.has(membership.role)) continue;
      const candidate = { kind: 'membership', id: membership.id };
      if (!seen.has(participantKey(candidate))) {
        seen.add(participantKey(candidate));
        participants.push(candidate);
      }
    }
  }

  const maximum = policy.maximumGroupSize;
  if (participants.length > maximum) {
    throw new ChatError(422, 'chat_group_too_large', `This conversation exceeds the family policy limit of ${maximum} participants.`);
  }
  const membershipIds = participants.filter((entry) => entry.kind === 'membership').map((entry) => entry.id).sort();
  const childIds = participants.filter((entry) => entry.kind === 'child').map((entry) => entry.id).sort();
  const pairKey = kind === 'direct' ? directPairKey(baseParticipants[0], baseParticipants[1]) : null;
  const row = await port.insertThread(tx, {
    familyId,
    kind,
    title,
    directPairKey: pairKey,
    createdByMembershipId: creator.kind === 'membership' ? creator.id : null,
    createdByChildId: creator.kind === 'child' ? creator.id : null,
    createdByKind: creator.kind,
    createdById: creator.id,
  });
  const inserted = await port.insertThreadMembers(tx, {
    familyId,
    threadId: row.id,
    membershipIds,
    childIds,
    joinedSeq: 1,
  });
  await port.audit(tx, {
    familyId,
    actorMembershipId: actor?.id ?? null,
    correlationId,
    subjectId: row.id,
    subjectType: 'family_chat_thread',
    eventType: 'family.chat_thread_created',
  });
  return {
    thread: threadView(row, { participants: inserted, selfParticipant: creator }),
  };
}

/// A new conversation names its participants explicitly. No guardian is added unless the
/// family's persisted collaboration policy activates a guardian-inclusion rule.
export function createThreadCreate({ port }) {
  return async function createChatThread({
    principal,
    familyId,
    kind,
    title = '',
    participants = [],
    idempotencyKey,
    requestHash,
    correlationId,
  }) {
    return port.idempotent(
      `chat:thread:${familyId}`,
      idempotencyKey,
      requestHash,
      async (tx) => {
        const actor = await port.authorize(tx, { familyId, subject: principal.subject });
        return createThreadInTransaction({
          port,
          tx,
          familyId,
          actor,
          creator: { kind: 'membership', id: actor.id },
          kind,
          title,
          requestedParticipants: participants,
          correlationId,
        });
      },
    );
  };
}

/// The paired child's own handset may start a direct channel or user-created group. Its own
/// identity is derived only from the verified device credential, and all selected participants
/// are checked against the same family's live server roster.
export function createDeviceThreadCreate({ port }) {
  return async function createChatThreadForDevice({
    deviceId,
    deviceCredential,
    kind,
    title = '',
    participants = [],
    idempotencyKey,
    requestHash,
    correlationId,
  }) {
    return port.idempotent(
      `chat:device-thread:${deviceId}`,
      idempotencyKey,
      requestHash,
      async (tx) => {
        const device = await port.requireDevice(tx, { deviceId, deviceCredential });
        return createThreadInTransaction({
          port,
          tx,
          familyId: device.family_id,
          actor: null,
          creator: { kind: 'child', id: device.child_id },
          kind,
          title,
          requestedParticipants: participants,
          correlationId,
        });
      },
    );
  };
}

/// A guardian may add a participant to a user-created group. Direct channels remain exactly two
/// peers (unless a safety policy explicitly added guardians at creation); use a new group when
/// the audience needs to grow. A join starts at the current sequence, never at old history.
export function createThreadMemberAdd({ port }) {
  return async function addChatThreadMember({
    principal,
    familyId,
    threadId,
    participantKind,
    participantId,
    idempotencyKey,
    requestHash,
    correlationId,
  }) {
    return port.idempotent(
      `chat:member:${familyId}:${threadId}`,
      idempotencyKey,
      requestHash,
      async (tx) => {
        const actor = await port.authorize(tx, { familyId, subject: principal.subject });
        const policy = await port.readCollaborationPolicy(tx, { familyId });
        if (!collaborationRoleAllowed(actor, policy, 'chatManage')) {
          throw new ChatError(403, 'chat_forbidden', 'This guardian role cannot manage conversation membership under the family policy.');
        }
        const thread = await port.readThread(tx, { familyId, threadId }, { forUpdate: true });
        if (thread == null) {
          throw new ChatError(404, 'chat_thread_not_found', 'This conversation is not part of the family.');
        }
        const asMember = await port.readThreadMember(tx, {
          threadId,
          participantKind: 'membership',
          participantId: actor.id,
        });
        if (asMember == null) {
          throw new ChatError(404, 'chat_thread_not_found', 'This conversation is not part of the family.');
        }
        if (thread.kind === 'direct') {
          throw new ChatError(409, 'chat_direct_is_pair', 'A direct conversation stays a pair; create a group to expand the audience.');
        }

        if (participantKind === 'membership') {
          const membership = await port.readMembership(tx, { familyId, membershipId: participantId });
          if (membership == null || membership.status !== 'active' || !GUARDIAN_ROLES.has(membership.role)) {
            throw new ChatError(404, 'chat_participant_not_found', 'This active guardian is not part of the family.');
          }
        } else if (participantKind === 'child') {
          const child = await port.readChild(tx, { familyId, childId: participantId });
          if (child == null) {
            throw new ChatError(404, 'chat_participant_not_found', 'This child is not part of the family.');
          }
          if (thread.kind !== 'group' && thread.kind !== 'child') {
            throw new ChatError(422, 'chat_legacy_room_shape', 'This legacy room cannot be expanded to include a child.');
          }
          const existingChildren = await port.listThreadChildren(tx, { threadId });
          if (thread.kind === 'child' && existingChildren.length > 0) {
            throw new ChatError(409, 'chat_legacy_child_room_full', 'This legacy child conversation already has its named child.');
          }
        } else {
          throw new ChatError(400, 'chat_participant_invalid', 'participantKind must be membership or child.');
        }

        const existing = await port.readThreadMember(tx, { threadId, participantKind, participantId });
        if (existing != null) {
          throw new ChatError(409, 'chat_member_already_present', 'They are already in this conversation.');
        }

        const currentMembers = await port.listThreadMembers(tx, { threadIds: [threadId] });
        const membershipIds = participantKind === 'membership' ? [participantId] : [];
        const childIds = participantKind === 'child' ? [participantId] : [];
        if (participantKind === 'child' && thread.kind === 'group') {
          const currentChildCount = currentMembers.filter((entry) => entry.participant_kind === 'child').length;
          const inclusionRequired = policy.guardianInclusionMode === 'all_child_chats' ||
            (policy.guardianInclusionMode === 'child_to_child' && currentChildCount > 0);
          if (inclusionRequired) {
            const guardians = await port.listActiveGuardianMemberships(tx, { familyId });
            const currentIds = new Set(currentMembers
              .filter((entry) => entry.participant_kind === 'membership')
              .map((entry) => entry.participant_id));
            for (const guardian of guardians) {
              if (guardian.status === 'active' && GUARDIAN_ROLES.has(guardian.role) && !currentIds.has(guardian.id)) {
                membershipIds.push(guardian.id);
              }
            }
          }
        }
        if (thread.kind === 'group' && currentMembers.length + membershipIds.length + childIds.length > policy.maximumGroupSize) {
          throw new ChatError(422, 'chat_group_too_large', `This conversation exceeds the family policy limit of ${policy.maximumGroupSize} participants.`);
        }
        const participants = await port.insertThreadMembers(tx, {
          familyId,
          threadId,
          membershipIds,
          childIds,
          joinedSeq: Number(thread.next_seq),
        });
        await port.audit(tx, {
          familyId,
          actorMembershipId: actor.id,
          correlationId,
          subjectId: threadId,
          subjectType: 'family_chat_thread',
          eventType: 'family.chat_member_added',
        });
        return {
          thread: threadView(thread, {
            participants,
            selfParticipant: { kind: 'membership', id: actor.id },
          }),
        };
      },
    );
  };
}

/// A child may add peers to a group only when the primary guardian explicitly enables that
/// server policy. Direct conversations remain pairs, and every new member starts reading at
/// the next sequence so a group invite never exposes old messages.
export function createDeviceThreadMemberAdd({ port }) {
  return async function addChatThreadMemberForDevice({
    deviceId,
    deviceCredential,
    threadId,
    participantKind,
    participantId,
    idempotencyKey,
    requestHash,
    correlationId,
  }) {
    return port.idempotent(
      `chat:device-member:${deviceId}:${threadId}`,
      idempotencyKey,
      requestHash,
      async (tx) => {
        const device = await port.requireDevice(tx, { deviceId, deviceCredential });
        const familyId = device.family_id;
        const policy = await port.readCollaborationPolicy(tx, { familyId });
        if (!policy.childGroupMemberManagementEnabled) {
          throw new ChatError(403, 'chat_group_management_disabled', 'The family safety policy does not allow this child to change group membership.');
        }
        if (!CHAT_PARTICIPANT_KINDS.includes(participantKind) || typeof participantId !== 'string') {
          throw new ChatError(400, 'chat_participant_invalid', 'participantKind and participantId must identify a family participant.');
        }
        const thread = await port.readThread(tx, { familyId, threadId }, { forUpdate: true });
        if (thread == null) {
          throw new ChatError(404, 'chat_thread_not_found', 'This conversation is not part of the family.');
        }
        if (thread.kind !== 'group') {
          throw new ChatError(409, 'chat_direct_is_pair', 'A direct conversation stays a pair; create a group to expand the audience.');
        }
        const actorMember = await port.readThreadMember(tx, {
          threadId,
          participantKind: 'child',
          participantId: device.child_id,
        });
        if (actorMember == null) {
          throw new ChatError(404, 'chat_thread_not_found', 'This conversation is not available to this child.');
        }
        if (participantKind === 'membership') {
          const membership = await port.readMembership(tx, { familyId, membershipId: participantId });
          if (membership == null || membership.status !== 'active' || !GUARDIAN_ROLES.has(membership.role)) {
            throw new ChatError(404, 'chat_participant_not_found', 'This active guardian is not part of the family.');
          }
        } else {
          const child = await port.readChild(tx, { familyId, childId: participantId });
          if (child == null) {
            throw new ChatError(404, 'chat_participant_not_found', 'This child is not part of the family.');
          }
        }
        if (await port.readThreadMember(tx, { threadId, participantKind, participantId }) != null) {
          throw new ChatError(409, 'chat_member_already_present', 'They are already in this conversation.');
        }
        const currentMembers = await port.listThreadMembers(tx, { threadIds: [threadId] });
        const membershipIds = participantKind === 'membership' ? [participantId] : [];
        const childIds = participantKind === 'child' ? [participantId] : [];
        if (participantKind === 'child') {
          const currentChildCount = currentMembers.filter((entry) => entry.participant_kind === 'child').length;
          const inclusionRequired = policy.guardianInclusionMode === 'all_child_chats' ||
            (policy.guardianInclusionMode === 'child_to_child' && currentChildCount > 0);
          if (inclusionRequired) {
            const currentMembershipIds = new Set(currentMembers
              .filter((entry) => entry.participant_kind === 'membership')
              .map((entry) => entry.participant_id));
            const guardians = await port.listActiveGuardianMemberships(tx, { familyId });
            for (const guardian of guardians) {
              if (guardian.status === 'active' && GUARDIAN_ROLES.has(guardian.role) && !currentMembershipIds.has(guardian.id)) {
                membershipIds.push(guardian.id);
              }
            }
          }
        }
        if (currentMembers.length + membershipIds.length + childIds.length > policy.maximumGroupSize) {
          throw new ChatError(422, 'chat_group_too_large', `This conversation exceeds the family policy limit of ${policy.maximumGroupSize} participants.`);
        }
        const participants = await port.insertThreadMembers(tx, {
          familyId,
          threadId,
          membershipIds,
          childIds,
          joinedSeq: Number(thread.next_seq),
        });
        await port.audit(tx, {
          familyId,
          actorMembershipId: null,
          correlationId,
          subjectId: threadId,
          subjectType: 'family_chat_thread',
          eventType: 'family.chat_member_added',
        });
        return {
          thread: threadView(thread, {
            participants,
            selfParticipant: { kind: 'child', id: device.child_id },
          }),
        };
      },
    );
  };
}

/// What the caller may read: every room they are a participant in. A guardian sees the rooms
/// they were added to and no others - not because a filter hides the rest, but because the join
/// to `family_chat_thread_members` is the query.
export function createThreadList({ port }) {
  return async function listChatThreads({ principal, familyId }) {
    return port.read(async (tx) => {
      const actor = await port.authorize(tx, { familyId, subject: principal.subject });
      const rows = await port.listThreadsForParticipant(tx, {
        familyId,
        participantKind: 'membership',
        participantId: actor.id,
      });
      const participants = await port.listThreadMembers(tx, { threadIds: rows.map((row) => row.id) });
      return {
        capabilities: CHAT_CURRENT_CAPABILITIES,
        threads: rows.map((row) =>
          threadView(row, {
            participants: participants.filter((entry) => entry.thread_id === row.id),
            unreadCount: Number(row.unread_count ?? 0),
            lastMessage: threadLastMessage(row),
            selfParticipant: { kind: 'membership', id: actor.id },
          }),
        ),
      };
    });
  };
}

/// The child's own handset: the rooms their child is in. No child id is taken from the request -
/// the credential issued at pairing is what proves which child is asking, which is the same
/// decision W5, W6, W7 and W8 each recorded for their own surface.
export function createDeviceThreadList({ port }) {
  return async function listChatThreadsForDevice({ deviceId, deviceCredential }) {
    return port.read(async (tx) => {
      const device = await port.requireDevice(tx, { deviceId, deviceCredential });
      const rows = await port.listThreadsForParticipant(tx, {
        familyId: device.family_id,
        participantKind: 'child',
        participantId: device.child_id,
      });
      const participants = await port.listThreadMembers(tx, { threadIds: rows.map((row) => row.id) });
      return {
        capabilities: CHAT_CURRENT_CAPABILITIES,
        threads: rows.map((row) =>
          threadView(row, {
            participants: participants.filter((entry) => entry.thread_id === row.id),
            unreadCount: Number(row.unread_count ?? 0),
            lastMessage: threadLastMessage(row),
            selfParticipant: { kind: 'child', id: device.child_id },
          }),
        ),
      };
    });
  };
}

/// Roster candidates are server-owned and family-bound. Only safe display fields leave this
/// read: no OIDC subject, contact detail, device identifier, or credential is returned.
export function createParticipantList({ port }) {
  return async function listChatParticipants({ principal, familyId }) {
    return port.read(async (tx) => {
      const actor = await port.authorize(tx, { familyId, subject: principal.subject });
      const selfParticipant = { kind: 'membership', id: actor.id };
      const rows = await port.listFamilyChatParticipants(tx, { familyId });
      return { participants: rows.map((row) => participantView(row, { selfParticipant })) };
    });
  };
}

/// A paired handset sees only the addressable participant roster of its own family.
export function createDeviceParticipantList({ port }) {
  return async function listChatParticipantsForDevice({ deviceId, deviceCredential }) {
    return port.read(async (tx) => {
      const device = await port.requireDevice(tx, { deviceId, deviceCredential });
      const selfParticipant = { kind: 'child', id: device.child_id };
      const rows = await port.listFamilyChatParticipants(tx, { familyId: device.family_id });
      return { participants: rows.map((row) => participantView(row, { selfParticipant })) };
    });
  };
}

/// Reading a thread's messages, from either surface, through one law: an active participant row
/// must exist for the caller. The lower bound is that row's joined sequence, so a newly-added
/// member cannot page backwards into conversation history from before they joined.
export function createMessageList({ port }) {
  return async function listChatMessages({
    principal,
    deviceId,
    deviceCredential,
    familyId,
    threadId,
    afterSeq,
    limit,
  }) {
    return port.read(async (tx) => {
      const { participant } = await port.resolveParticipant(tx, {
        principal,
        deviceId,
        deviceCredential,
        familyId,
      });
      const thread = await port.readThread(tx, { familyId: participant.familyId, threadId });
      if (thread == null) {
        throw new ChatError(404, 'chat_thread_not_found', 'This conversation is not part of the family.');
      }
      const member = await port.readThreadMember(tx, {
        threadId,
        participantKind: participant.kind,
        participantId: participant.id,
      });
      if (member == null) {
        // Not a member: for this caller the thread does not exist. A 403 here would confirm a
        // room they were never told about, which is a fact leaking through an error code.
        throw new ChatError(404, 'chat_thread_not_found', 'This conversation is not part of the family.');
      }
      const { afterSeq: requestedAfter, limit: size } = normalizeMessageQuery({ afterSeq, limit });
      const joinedSeq = Number(member.joined_seq ?? 1);
      const from = Math.max(requestedAfter, joinedSeq - 1);
      const rows = await port.listMessages(tx, { threadId, afterSeq: from, minimumSeq: joinedSeq, limit: size });
      const readCounts = await port.readCountsForMessages(tx, { threadId, messageIds: rows.map((row) => row.id) });
      const byId = new Map(readCounts.map((entry) => [entry.message_id, Number(entry.read_count)]));
      return {
        messages: rows.map((row) => messageView(row, { readCount: byId.get(row.id) ?? 0 })),
        readState: readStateView(member),
        hasMore: rows.length === size,
      };
    });
  };
}

/// Sending. The sequence is taken from the thread's counter inside this transaction, the author
/// comes from how the request arrived, and a repeated `clientMessageId` returns the message that
/// already exists rather than a second copy of it.
export function createMessageSend({ port }) {
  return async function sendChatMessage({
    principal,
    deviceId,
    deviceCredential,
    familyId,
    threadId,
    body,
    clientMessageId,
    idempotencyKey,
    requestHash,
    correlationId,
  }) {
    return port.idempotent(
      `chat:message:${familyId ?? deviceId}:${threadId}`,
      idempotencyKey,
      requestHash,
      async (tx) => {
        const { actor, device, participant } = await port.resolveParticipant(tx, {
          principal,
          deviceId,
          deviceCredential,
          familyId,
        });
        const thread = await port.readThread(tx, { familyId: participant.familyId, threadId }, { forUpdate: true });
        if (thread == null) {
          throw new ChatError(404, 'chat_thread_not_found', 'This conversation is not part of the family.');
        }
        const member = await port.readThreadMember(tx, {
          threadId,
          participantKind: participant.kind,
          participantId: participant.id,
        });
        if (member == null) {
          throw new ChatError(404, 'chat_thread_not_found', 'This conversation is not part of the family.');
        }

        const author = participantOf({ actor, device });
        const replay = await port.readMessageByClientId(tx, {
          threadId,
          authorKind: author.kind,
          authorId: author.id,
          clientMessageId,
        });
        if (replay != null) {
          // The same client message arriving twice is one message. It is NOT an error: a phone
          // that lost the answer must be able to ask again and get the sequence it was given -
          // and the receipt it is answered with is the receipt that is true NOW, not a zero
          // that would quietly un-tell a reader somebody had already read it.
          const counts = await port.readCountsForMessages(tx, { threadId, messageIds: [replay.id] });
          return {
            message: messageView(replay, { readCount: Number(counts[0]?.read_count ?? 0) }),
            replayed: true,
          };
        }
        const seq = await port.allocateSeq(tx, { familyId: participant.familyId, threadId });
        const row = await port.insertMessage(tx, {
          familyId: participant.familyId,
          threadId,
          seq,
          authorKind: author.kind,
          authorId: author.id,
          body,
          clientMessageId,
        });
        await port.audit(tx, {
          familyId: participant.familyId,
          actorMembershipId: author.membershipId,
          correlationId,
          subjectId: row.id,
          subjectType: 'family_chat_message',
          eventType: 'family.chat_message_sent',
        });
        return { message: messageView(row, { readCount: 0 }), replayed: false };
      },
    );
  };
}

/// Editing states the revision it read and keeps the body it replaced, so an edit is visible
/// rather than a silent rewrite. Only the author edits their own message: a guardian rewriting
/// a child's words is the abuse this product is built to be the opposite of.
export function createMessageEdit({ port }) {
  return async function editChatMessage({
    principal,
    deviceId,
    deviceCredential,
    familyId,
    threadId,
    messageId,
    body,
    revision,
    correlationId,
  }) {
    return port.read(async (tx) => {
      const { actor, device, participant } = await port.resolveParticipant(tx, {
        principal,
        deviceId,
        deviceCredential,
        familyId,
      });
      const message = await port.readMessage(tx, { familyId: participant.familyId, threadId, messageId }, { forUpdate: true });
      if (message == null) {
        throw new ChatError(404, 'chat_message_not_found', 'This message is not part of the conversation.');
      }
      const author = participantOf({ actor, device });
      if (message.author_kind !== author.kind || message.author_id !== author.id) {
        throw new ChatError(403, 'chat_not_author', 'Only the person who wrote a message can change it.');
      }
      if (message.deleted_at != null) {
        throw new ChatError(409, 'chat_message_deleted', 'A deleted message is not edited.');
      }
      if (message.revision !== expectedRevision(revision)) {
        throw new ChatError(
          409,
          'chat_message_stale_revision',
          'Somebody else changed this message since you read it.',
        );
      }
      const row = await port.updateMessageBody(tx, { messageId, body });
      await port.audit(tx, {
        familyId: participant.familyId,
        actorMembershipId: author.membershipId,
        correlationId,
        subjectId: messageId,
        subjectType: 'family_chat_message',
        eventType: 'family.chat_message_edited',
      });
      return { message: messageView(row, { readCount: 0 }) };
    });
  };
}

/// Deleting. Only the author, once, and the row survives: the body and the stored revisions are
/// removed, the sequence stays, and who deleted it is recorded. A thread with a hole in its
/// numbering would be a thread nobody can trust, and a product that keeps the text after
/// somebody deleted it has not deleted anything.
export function createMessageDelete({ port }) {
  return async function deleteChatMessage({
    principal,
    deviceId,
    deviceCredential,
    familyId,
    threadId,
    messageId,
    idempotencyKey,
    requestHash,
    correlationId,
  }) {
    return port.idempotent(
      `chat:delete:${familyId ?? deviceId}:${messageId}`,
      idempotencyKey,
      requestHash,
      async (tx) => {
        const { actor, device, participant } = await port.resolveParticipant(tx, {
          principal,
          deviceId,
          deviceCredential,
          familyId,
        });
        const message = await port.readMessage(tx, { familyId: participant.familyId, threadId, messageId }, { forUpdate: true });
        if (message == null) {
          throw new ChatError(404, 'chat_message_not_found', 'This message is not part of the conversation.');
        }
        const author = participantOf({ actor, device });
        if (message.author_kind !== author.kind || message.author_id !== author.id) {
          throw new ChatError(403, 'chat_not_author', 'Only the person who wrote a message can delete it.');
        }
        if (message.deleted_at != null) {
          throw new ChatError(409, 'chat_message_already_deleted', 'This message was already deleted.');
        }
        const row = await port.markMessageDeleted(tx, {
          messageId,
          deletedByKind: author.kind,
          deletedById: author.id,
        });
        await port.audit(tx, {
          familyId: participant.familyId,
          actorMembershipId: author.membershipId,
          correlationId,
          subjectId: messageId,
          subjectType: 'family_chat_message',
          eventType: 'family.chat_message_deleted',
        });
        return { message: messageView(row, { readCount: 0 }) };
      },
    );
  };
}

/// Marking read. `last_read_seq` only moves forward, and it cannot pass the newest message in
/// the thread. There is no endpoint that marks a message read for somebody else, and no read
/// mark is ever inferred from a device being online - the only statement this server accepts
/// about reading is the one a participant's own client makes about itself.
export function createReadMark({ port }) {
  return async function markThreadRead({
    principal,
    deviceId,
    deviceCredential,
    familyId,
    threadId,
    readSeq,
    idempotencyKey,
    requestHash,
    correlationId,
  }) {
    return port.idempotent(
      `chat:read:${familyId ?? deviceId}:${threadId}`,
      idempotencyKey,
      requestHash,
      async (tx) => {
        const { actor, device, participant } = await port.resolveParticipant(tx, {
          principal,
          deviceId,
          deviceCredential,
          familyId,
        });
        const thread = await port.readThread(tx, { familyId: participant.familyId, threadId }, { forUpdate: true });
        if (thread == null) {
          throw new ChatError(404, 'chat_thread_not_found', 'This conversation is not part of the family.');
        }
        const member = await port.readThreadMember(tx, {
          threadId,
          participantKind: participant.kind,
          participantId: participant.id,
        });
        if (member == null) {
          throw new ChatError(404, 'chat_thread_not_found', 'This conversation is not part of the family.');
        }
        const highestSeq = await port.readHighestSeq(tx, { threadId });
        requireReadableSeq({
          readSeq,
          highestSeq,
          minimumSeq: Number(member.joined_seq ?? 1) - 1,
        });
        const row = await port.advanceLastReadSeq(tx, {
          threadId,
          participantKind: participant.kind,
          participantId: participant.id,
          readSeq,
        });
        const author = participantOf({ actor, device });
        await port.audit(tx, {
          familyId: participant.familyId,
          actorMembershipId: author.membershipId,
          correlationId,
          subjectId: threadId,
          subjectType: 'family_chat_thread',
          eventType: 'family.chat_read_marked',
        });
        return { readState: readStateView(row) };
      },
    );
  };
}

export function familyChatFor(store, { credentialMatches }) {
  const port = postgresFamilyChatPort(store, { credentialMatches });
  return {
    listThreads: createThreadList({ port }),
    createThread: createThreadCreate({ port }),
    createThreadForDevice: createDeviceThreadCreate({ port }),
    addThreadMember: createThreadMemberAdd({ port }),
    addThreadMemberForDevice: createDeviceThreadMemberAdd({ port }),
    listParticipants: createParticipantList({ port }),
    listParticipantsForDevice: createDeviceParticipantList({ port }),
    listThreadsForDevice: createDeviceThreadList({ port }),
    listMessages: createMessageList({ port }),
    sendMessage: createMessageSend({ port }),
    editMessage: createMessageEdit({ port }),
    deleteMessage: createMessageDelete({ port }),
    markThreadRead: createReadMark({ port }),
  };
}

// ── the row-to-view column lists ─────────────────────────────────────────────────────────

/// The columns are stated once, as lists, because one read needs them prefixed (`m.seq`) and a
/// template string cannot be both flat and prefixed without becoming a parser's job.
const MESSAGE_COLUMN_LIST = Object.freeze([
  'id', 'family_id', 'thread_id', 'seq', 'author_kind', 'author_id', 'body',
  'client_message_id', 'revision', 'edited_at', 'deleted_at',
  'deleted_by_kind', 'deleted_by_id', 'created_at',
]);
const columns = (list, prefix = '') =>
  list.map((column) => (prefix === '' ? column : `${prefix}.${column}`)).join(', ');
const MESSAGE_COLUMNS = columns(MESSAGE_COLUMN_LIST);
const MESSAGES_PREFIXED = columns(MESSAGE_COLUMN_LIST, 'm');

const THREAD_COLUMNS = `id, family_id, kind, title, next_seq, direct_pair_key,
                        created_by_membership_id, created_by_child_id,
                        created_by_participant_kind, created_by_participant_id, created_at`;

const THREAD_MEMBER_COLUMNS = `thread_id, family_id, participant_kind, participant_id,
                               membership_id, child_id, last_read_seq, joined_seq, left_at, joined_at`;

export function postgresFamilyChatPort(store, { credentialMatches }) {
  /// The device credential check, stated once for every read and write in this port.
  const requireDevice = async (client, { deviceId, deviceCredential }) => {
    const { rows } = await client.query(
      `SELECT id, family_id, child_id, credential_hash, credential_revoked_at
         FROM family_child_devices WHERE id = $1`,
      [deviceId],
    );
    const device = rows[0];
    if (
      device == null ||
      device.credential_revoked_at != null ||
      !credentialMatches(device.credential_hash, deviceCredential)
    ) {
      throw new ChatError(403, 'device_credential_rejected', 'This device credential is not accepted.');
    }
    return device;
  };

  const listThreadMembers = async (client, { threadIds }) => {
    if (threadIds.length === 0) return [];
    const { rows } = await client.query(
      `SELECT mem.thread_id, mem.participant_kind, mem.participant_id, mem.membership_id, mem.child_id,
              mem.last_read_seq, mem.joined_seq, mem.left_at,
              memb.role AS membership_role, child.display_name AS child_display_name
         FROM family_chat_thread_members mem
         LEFT JOIN family_memberships memb ON memb.id = mem.membership_id
         LEFT JOIN family_children child ON child.id = mem.child_id
        WHERE mem.thread_id = ANY($1::uuid[])
          AND mem.left_at IS NULL
          AND (mem.participant_kind = 'child' OR memb.status = 'active')
        ORDER BY mem.thread_id, mem.participant_kind, mem.participant_id`,
      [threadIds],
    );
    return rows;
  };

  return {
    credentialMatches,

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
      return store.activeActorMembership(client, familyId, subject);
    },

    /// One place that answers "who is this caller, and which participant row are they". The
    /// device path proves itself with the credential issued at pairing; the person path with
    /// their membership. Exactly one of the two is present on any request.
    async resolveParticipant(client, { principal, deviceId, deviceCredential, familyId }) {
      if (deviceId != null) {
        const device = await requireDevice(client, { deviceId, deviceCredential });
        return {
          actor: null,
          device,
          participant: { kind: 'child', id: device.child_id, familyId: device.family_id },
        };
      }
      const actor = await store.activeActorMembership(client, familyId, principal.subject);
      return {
        actor,
        device: null,
        participant: { kind: 'membership', id: actor.id, familyId },
      };
    },

    requireDevice,

    /// Guardian candidates are read only when an active safety rule requires inclusion or a
    /// group-membership operation needs to verify a guardian. Stable ordering makes the result
    /// deterministic, and the transaction lock prevents revocation between this snapshot and
    /// the member rows being inserted.
    async listActiveGuardianMemberships(client, { familyId }) {
      const { rows } = await client.query(
        `SELECT id, role, status
           FROM family_memberships
          WHERE family_id = $1
            AND status = 'active'
            AND role IN ('primary_guardian', 'co_guardian')
          ORDER BY joined_at ASC, id ASC
          FOR SHARE`,
        [familyId],
      );
      return rows;
    },

    async readChild(client, { familyId, childId }) {
      const { rows } = await client.query(
        `SELECT id FROM family_children WHERE family_id = $1 AND id = $2`,
        [familyId, childId],
      );
      return rows[0] ?? null;
    },

    async readMembership(client, { familyId, membershipId }) {
      const { rows } = await client.query(
        `SELECT id, role, status FROM family_memberships WHERE family_id = $1 AND id = $2`,
        [familyId, membershipId],
      );
      return rows[0] ?? null;
    },

    async readCollaborationPolicy(client, { familyId, forUpdate = false } = {}) {
      return readServerCollaborationPolicy(client, { familyId, forUpdate });
    },

    async listFamilyChatParticipants(client, { familyId }) {
      const { rows } = await client.query(
        `SELECT 'membership'::text AS participant_kind, membership.id AS participant_id,
                membership.role AS membership_role, NULL::text AS child_display_name
           FROM family_memberships membership
          WHERE membership.family_id = $1
            AND membership.status = 'active'
            AND membership.role IN ('primary_guardian', 'co_guardian')
         UNION ALL
         SELECT 'child'::text AS participant_kind, child.id AS participant_id,
                'child'::text AS membership_role, child.display_name AS child_display_name
           FROM family_children child
          WHERE child.family_id = $1
          ORDER BY participant_kind, participant_id`,
        [familyId],
      );
      return rows;
    },

    async insertThread(client, {
      familyId, kind, title, directPairKey,
      createdByMembershipId, createdByChildId, createdByKind, createdById,
    }) {
      const { rows } = await client.query(
        `INSERT INTO family_chat_threads
           (id, family_id, kind, title, direct_pair_key, created_by_membership_id,
            created_by_child_id, created_by_participant_kind, created_by_participant_id)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
         RETURNING ${THREAD_COLUMNS}`,
        [
          randomUUID(), familyId, kind, title, directPairKey ?? null,
          createdByMembershipId ?? null, createdByChildId ?? null, createdByKind, createdById,
        ],
      );
      return rows[0];
    },

    async insertThreadMembers(client, { familyId, threadId, membershipIds, childIds, joinedSeq = 1 }) {
      const insertMember = async (kind, id, identityColumn) => {
        await client.query(
          `INSERT INTO family_chat_thread_members
             (thread_id, family_id, participant_kind, participant_id, ${identityColumn},
              last_read_seq, joined_seq)
           VALUES ($1, $2, $3, $4, $4, $5, $6)
           ON CONFLICT (thread_id, participant_kind, participant_id) DO UPDATE
             SET last_read_seq = EXCLUDED.last_read_seq,
                 joined_seq = EXCLUDED.joined_seq,
                 left_at = NULL,
                 joined_at = NOW()
           WHERE family_chat_thread_members.left_at IS NOT NULL`,
          [threadId, familyId, kind, id, joinedSeq - 1, joinedSeq],
        );
      };
      for (const membershipId of membershipIds) await insertMember('membership', membershipId, 'membership_id');
      for (const childId of childIds) await insertMember('child', childId, 'child_id');
      return listThreadMembers(client, { threadIds: [threadId] });
    },

    listThreadMembers,

    async readThread(client, { familyId, threadId }, { forUpdate = false } = {}) {
      const { rows } = await client.query(
        `SELECT ${THREAD_COLUMNS} FROM family_chat_threads
          WHERE id = $1 AND family_id = $2
          ${forUpdate ? 'FOR UPDATE' : ''}`,
        [threadId, familyId],
      );
      return rows[0] ?? null;
    },

    async readThreadMember(client, { threadId, participantKind, participantId }) {
      const { rows } = await client.query(
        `SELECT ${THREAD_MEMBER_COLUMNS}
           FROM family_chat_thread_members
          WHERE thread_id = $1 AND participant_kind = $2 AND participant_id = $3
            AND left_at IS NULL`,
        [threadId, participantKind, participantId],
      );
      return rows[0] ?? null;
    },


    async listThreadChildren(client, { threadId }) {
      const { rows } = await client.query(
        `SELECT child_id FROM family_chat_thread_members
          WHERE thread_id = $1 AND participant_kind = 'child' AND left_at IS NULL`,
        [threadId],
      );
      return rows;
    },

    /// The rooms this participant is in, with the newest message, the unread count and the
    /// reader count of that newest message in one pass. Ordering is by the last thing that
    /// happened, so an empty room sorts below a room somebody just spoke in.
    async listThreadsForParticipant(client, { familyId, participantKind, participantId }) {
      const { rows } = await client.query(
        `SELECT t.id, t.family_id, t.kind, t.title, t.created_at,
                me.last_read_seq,
                last.id AS last_id, last.seq AS last_seq, last.author_kind AS last_author_kind,
                last.author_id AS last_author_id, last.body AS last_body, last.revision AS last_revision,
                last.edited_at AS last_edited_at, last.deleted_at AS last_deleted_at,
                last.deleted_by_kind AS last_deleted_by_kind, last.deleted_by_id AS last_deleted_by_id,
                last.created_at AS last_created_at,
                COALESCE(unread.unread_count, 0) AS unread_count,
                COALESCE(readers.reader_count, 0) AS last_read_count
           FROM family_chat_threads t
           JOIN family_chat_thread_members me
             ON me.thread_id = t.id
            AND me.participant_kind = $2
            AND me.participant_id = $3
            AND me.left_at IS NULL
           LEFT JOIN LATERAL (
             SELECT ${MESSAGES_PREFIXED} FROM family_chat_messages m
              WHERE m.thread_id = t.id AND m.seq >= me.joined_seq
              ORDER BY m.seq DESC
              LIMIT 1
           ) last ON TRUE
           LEFT JOIN LATERAL (
             SELECT COUNT(*)::int AS unread_count FROM family_chat_messages m
              WHERE m.thread_id = t.id
                AND m.seq > GREATEST(me.last_read_seq, me.joined_seq - 1)
                AND NOT (m.author_kind = me.participant_kind AND m.author_id = me.participant_id)
           ) unread ON TRUE
           LEFT JOIN LATERAL (
             SELECT COUNT(*)::int AS reader_count FROM family_chat_thread_members other
              WHERE other.thread_id = t.id
                AND other.left_at IS NULL
                AND other.joined_seq <= last.seq
                AND other.last_read_seq >= last.seq
                AND NOT (other.participant_kind = last.author_kind AND other.participant_id = last.author_id)
           ) readers ON TRUE
          WHERE t.family_id = $1
          ORDER BY COALESCE(last.created_at, t.created_at) DESC, t.id ASC`,
        [familyId, participantKind, participantId],
      );
      return rows;
    },

    /// The sequence the server hands out. This single statement is why ordering belongs to the
    /// server: the counter is read and advanced under the row lock the sending transaction
    /// already holds, so two senders can never be given the same number.
    async allocateSeq(client, { familyId, threadId }) {
      const { rows } = await client.query(
        `UPDATE family_chat_threads
            SET next_seq = next_seq + 1
          WHERE id = $1 AND family_id = $2
          RETURNING next_seq - 1 AS seq`,
        [threadId, familyId],
      );
      if (rows[0] == null) {
        throw new ChatError(404, 'chat_thread_not_found', 'This conversation is not part of the family.');
      }
      return Number(rows[0].seq);
    },

    async readHighestSeq(client, { threadId }) {
      const { rows } = await client.query(
        `SELECT COALESCE(MAX(seq), 0) AS highest FROM family_chat_messages WHERE thread_id = $1`,
        [threadId],
      );
      return Number(rows[0].highest);
    },

    async readMessageByClientId(client, { threadId, authorKind, authorId, clientMessageId }) {
      const { rows } = await client.query(
        `SELECT ${MESSAGE_COLUMNS} FROM family_chat_messages
          WHERE thread_id = $1 AND author_kind = $2 AND author_id = $3 AND client_message_id = $4`,
        [threadId, authorKind, authorId, clientMessageId],
      );
      return rows[0] ?? null;
    },

    async insertMessage(client, { familyId, threadId, seq, authorKind, authorId, body, clientMessageId }) {
      const { rows } = await client.query(
        `INSERT INTO family_chat_messages
           (id, family_id, thread_id, seq, author_kind, author_id, body, client_message_id)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
         RETURNING ${MESSAGE_COLUMNS}`,
        [randomUUID(), familyId, threadId, seq, authorKind, authorId, body, clientMessageId],
      );
      return rows[0];
    },

    async readMessage(client, { familyId, threadId, messageId }, { forUpdate = false } = {}) {
      const { rows } = await client.query(
        `SELECT ${MESSAGE_COLUMNS} FROM family_chat_messages
          WHERE id = $1 AND thread_id = $2 AND family_id = $3
          ${forUpdate ? 'FOR UPDATE' : ''}`,
        [messageId, threadId, familyId],
      );
      return rows[0] ?? null;
    },

    async listMessages(client, { threadId, afterSeq, minimumSeq = 1, limit }) {
      const { rows } = await client.query(
        `SELECT ${MESSAGE_COLUMNS} FROM family_chat_messages
          WHERE thread_id = $1 AND seq > $2 AND seq >= $3
          ORDER BY seq ASC
          LIMIT $4`,
        [threadId, afterSeq, minimumSeq, limit],
      );
      return rows;
    },

    /// How many OTHER participants have read up to each of these messages. One query for the
    /// page, because a receipt computed per message is a query per message on the read path.
    async readCountsForMessages(client, { threadId, messageIds }) {
      if (messageIds.length === 0) return [];
      const { rows } = await client.query(
        `SELECT m.id AS message_id, COUNT(reader.*)::int AS read_count
           FROM family_chat_messages m
           LEFT JOIN family_chat_thread_members reader
             ON reader.thread_id = m.thread_id
            AND reader.left_at IS NULL
            AND reader.joined_seq <= m.seq
            AND reader.last_read_seq >= m.seq
            AND NOT (reader.participant_kind = m.author_kind AND reader.participant_id = m.author_id)
          WHERE m.thread_id = $1 AND m.id = ANY($2::uuid[])
          GROUP BY m.id`,
        [threadId, messageIds],
      );
      return rows;
    },

    /// The edit: the body it replaced is written to the revisions table first, so the change is
    /// provable. `revision` and `edited_at` move together - migration 109 refuses any row where
    /// they disagree.
    async updateMessageBody(client, { messageId, body }) {
      const current = await client.query(
        `SELECT ${MESSAGE_COLUMNS} FROM family_chat_messages WHERE id = $1 FOR UPDATE`,
        [messageId],
      );
      const previous = current.rows[0];
      await client.query(
        `INSERT INTO family_chat_message_revisions
           (message_id, revision, body, edited_by_kind, edited_by_id)
         VALUES ($1, $2, $3, $4, $5)`,
        [messageId, previous.revision, previous.body, previous.author_kind, previous.author_id],
      );
      const { rows } = await client.query(
        `UPDATE family_chat_messages
            SET body = $2, revision = revision + 1, edited_at = NOW()
          WHERE id = $1
          RETURNING ${MESSAGE_COLUMNS}`,
        [messageId, body],
      );
      return rows[0];
    },

    /// The deletion: the trace stays, the text goes, and the stored earlier versions go with it.
    async markMessageDeleted(client, { messageId, deletedByKind, deletedById }) {
      await client.query(`DELETE FROM family_chat_message_revisions WHERE message_id = $1`, [messageId]);
      const { rows } = await client.query(
        `UPDATE family_chat_messages
            SET body = '', deleted_at = NOW(), deleted_by_kind = $2, deleted_by_id = $3
          WHERE id = $1
          RETURNING ${MESSAGE_COLUMNS}`,
        [messageId, deletedByKind, deletedById],
      );
      return rows[0];
    },

    /// Reading is monotone: `GREATEST` makes a stale client harmless, and there is no statement
    /// in this port that can move a read mark backwards.
    async advanceLastReadSeq(client, { threadId, participantKind, participantId, readSeq }) {
      const { rows } = await client.query(
        `UPDATE family_chat_thread_members
            SET last_read_seq = GREATEST(last_read_seq, $4)
          WHERE thread_id = $1 AND participant_kind = $2 AND participant_id = $3
            AND left_at IS NULL
          RETURNING thread_id, participant_kind, participant_id, last_read_seq`,
        [threadId, participantKind, participantId, readSeq],
      );
      return rows[0];
    },

    async audit(client, {
      familyId,
      actorMembershipId,
      correlationId,
      subjectId,
      subjectType,
      eventType,
    }) {
      await store.appendAuditAndOutbox(client, {
        familyId,
        actorMembershipId,
        correlationId,
        subjectId,
        subjectType,
        eventType,
      });
    },
  };
}
