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

export const CHAT_THREAD_KINDS = Object.freeze(['family', 'child']);
export const CHAT_PARTICIPANT_KINDS = Object.freeze(['membership', 'child']);

export const CHAT_TITLE_MAX = 120;
export const CHAT_BODY_MAX = 2000;
export const CHAT_CLIENT_MESSAGE_ID_MIN = 8;
export const CHAT_CLIENT_MESSAGE_ID_MAX = 64;
export const CHAT_PARTICIPANTS_MAX = 24;
export const CHAT_PAGE_MAX = 200;
export const CHAT_PAGE_DEFAULT = 50;

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

function requireGuardian(actor, code, message) {
  if (!GUARDIAN_ROLES.has(actor?.role)) {
    throw new ChatError(403, code, message);
  }
  return actor;
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
export function participantView(row, { selfMembershipId = null } = {}) {
  return {
    kind: row.participant_kind,
    id: row.participant_id,
    role: row.membership_role ?? null,
    displayName: row.child_display_name ?? null,
    isSelf: row.participant_kind === 'membership' && row.participant_id === selfMembershipId,
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

export function threadView(row, { participants = [], lastMessage = null, unreadCount = 0, selfMembershipId = null } = {}) {
  return {
    id: row.id,
    kind: row.kind,
    title: row.title,
    createdAt: instant(row.created_at),
    lastReadSeq: Number(row.last_read_seq ?? 0),
    unreadCount,
    participants: participants.map((entry) => participantView(entry, { selfMembershipId })),
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
export function requireReadableSeq({ readSeq, highestSeq }) {
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

/// A guardian opens a room. The participants are written in the same transaction as the room,
/// so no reader can ever observe a thread that exists with nobody in it.
///
/// Two shapes are allowed, and only two: `family` is the household room and holds guardians;
/// `child` holds exactly one child of this family plus at least one guardian. A child is never
/// a member of a room that does not name them, which is what makes "who can reach this child"
/// a question storage can answer rather than a question a reviewer has to hope about.
export function createThreadCreate({ port }) {
  return async function createChatThread({
    principal,
    familyId,
    kind,
    title = '',
    participantMembershipIds = [],
    childIds = [],
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
        requireGuardian(actor, 'chat_forbidden', 'Only a guardian may open a family conversation.');

        if (kind === 'child') {
          if (childIds.length !== 1) {
            throw new ChatError(
              422,
              'chat_child_thread_needs_one_child',
              'A child conversation is about one child, and names exactly them.',
            );
          }
        } else if (childIds.length !== 0) {
          throw new ChatError(
            422,
            'chat_family_thread_is_guardians',
            'The household conversation is between guardians; a child has their own conversation.',
          );
        }

        const membershipRows = [];
        const seen = new Set();
        for (const membershipId of participantMembershipIds) {
          if (seen.has(membershipId)) continue;
          seen.add(membershipId);
          const membership = await port.readMembership(tx, { familyId, membershipId });
          if (membership == null) {
            throw new ChatError(
              404,
              'chat_membership_not_found',
              'One of these guardians is not part of the family.',
            );
          }
          // Only a guardian is ever a participant: a child participates as a child, through
          // the child foreign key, so that every room naming a child can be listed for them.
          requireGuardian(membership, 'chat_participant_not_guardian', 'Only a guardian joins a room here.');
          membershipRows.push(membershipId);
        }
        if (!membershipRows.includes(actor.id)) membershipRows.push(actor.id);

        for (const childId of childIds) {
          const child = await port.readChild(tx, { familyId, childId });
          if (child == null) {
            throw new ChatError(404, 'chat_child_not_found', 'One of these children is not part of the family.');
          }
        }

        const row = await port.insertThread(tx, {
          familyId,
          kind,
          title,
          createdByMembershipId: actor.id,
        });
        const participants = await port.insertThreadMembers(tx, {
          familyId,
          threadId: row.id,
          membershipIds: membershipRows,
          childIds,
        });
        await port.audit(tx, {
          familyId,
          actorMembershipId: actor.id,
          correlationId,
          subjectId: row.id,
          subjectType: 'family_chat_thread',
          eventType: 'family.chat_thread_created',
        });
        return {
          thread: threadView(row, { participants, selfMembershipId: actor.id }),
        };
      },
    );
  };
}

/// A guardian adds a participant. Two laws meet here: a child conversation is the place its one
/// child is named - so a second child is refused and a child cannot join the household room -
/// while guardians may join a room they are being invited into, one at a time, which is how a
/// co-guardian ends up in the room about the child they co-parent. Nothing here can add a person
/// who is not in this family, and the guardian making the change must already be in the room.
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
        requireGuardian(actor, 'chat_forbidden', 'Only a guardian may change who is in a conversation.');
        const thread = await port.readThread(tx, { familyId, threadId }, { forUpdate: true });
        if (thread == null) {
          throw new ChatError(404, 'chat_thread_not_found', 'This conversation is not part of the family.');
        }
        // The guardian changing the room must be in it: an outsider rearranging somebody else's
        // conversation is the exact shape of the abuse this wave is built around.
        const asMember = await port.readThreadMember(tx, {
          threadId,
          participantKind: 'membership',
          participantId: actor.id,
        });
        if (asMember == null) {
          throw new ChatError(404, 'chat_thread_not_found', 'This conversation is not part of the family.');
        }

        if (participantKind === 'membership') {
          const membership = await port.readMembership(tx, { familyId, membershipId: participantId });
          if (membership == null) {
            throw new ChatError(404, 'chat_membership_not_found', 'This guardian is not part of the family.');
          }
          requireGuardian(membership, 'chat_participant_not_guardian', 'Only a guardian joins a room here.');
        } else {
          const child = await port.readChild(tx, { familyId, childId: participantId });
          if (child == null) {
            throw new ChatError(404, 'chat_child_not_found', 'This child is not part of the family.');
          }
          const existingChildren = await port.listThreadChildren(tx, { threadId });
          if (thread.kind !== 'child' || existingChildren.length > 0) {
            throw new ChatError(
              422,
              'chat_child_belongs_to_one_thread',
              'A child conversation names one child, and a child is named by their own conversation.',
            );
          }
        }

        const existing = await port.readThreadMember(tx, {
          threadId,
          participantKind,
          participantId,
        });
        if (existing != null) {
          throw new ChatError(409, 'chat_member_already_present', 'They are already in this conversation.');
        }
        const participants = await port.insertThreadMembers(tx, {
          familyId,
          threadId,
          membershipIds: participantKind === 'membership' ? [participantId] : [],
          childIds: participantKind === 'child' ? [participantId] : [],
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
          thread: threadView(thread, { participants, selfMembershipId: actor.id }),
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
        threads: rows.map((row) =>
          threadView(row, {
            participants: participants.filter((entry) => entry.thread_id === row.id),
            unreadCount: Number(row.unread_count ?? 0),
            lastMessage: row.last_id == null ? null : messageView(row, { readCount: Number(row.last_read_count ?? 0) }),
            selfMembershipId: actor.id,
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
        threads: rows.map((row) =>
          threadView(row, {
            participants: participants.filter((entry) => entry.thread_id === row.id),
            unreadCount: Number(row.unread_count ?? 0),
            lastMessage: row.last_id == null ? null : messageView(row, { readCount: Number(row.last_read_count ?? 0) }),
          }),
        ),
      };
    });
  };
}

/// Reading a thread's messages, from either surface, through one law: a participant row must
/// exist for the caller. Everything else - the child's own room, the household room, the
/// co-guardian's room - is the same read with a different caller.
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
      const { afterSeq: from, limit: size } = normalizeMessageQuery({ afterSeq, limit });
      const rows = await port.listMessages(tx, { threadId, afterSeq: from, limit: size });
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
          // that lost the answer must be able to ask again and get the sequence it was given.
          return {
            message: messageView(replay, { readCount: 0 }),
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
        requireReadableSeq({ readSeq, highestSeq });
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
    addThreadMember: createThreadMemberAdd({ port }),
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

const THREAD_COLUMNS = 'id, family_id, kind, title, next_seq, created_by_membership_id, created_at';

const THREAD_MEMBER_COLUMNS = `thread_id, family_id, participant_kind, participant_id,
                               membership_id, child_id, last_read_seq, joined_at`;

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
              memb.role AS membership_role, child.display_name AS child_display_name
         FROM family_chat_thread_members mem
         LEFT JOIN family_memberships memb ON memb.id = mem.membership_id
         LEFT JOIN family_children child ON child.id = mem.child_id
        WHERE mem.thread_id = ANY($1::uuid[])
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

    async insertThread(client, { familyId, kind, title, createdByMembershipId }) {
      const { rows } = await client.query(
        `INSERT INTO family_chat_threads (id, family_id, kind, title, created_by_membership_id)
         VALUES ($1, $2, $3, $4, $5)
         RETURNING ${THREAD_COLUMNS}`,
        [randomUUID(), familyId, kind, title, createdByMembershipId],
      );
      return rows[0];
    },

    async insertThreadMembers(client, { familyId, threadId, membershipIds, childIds }) {
      for (const membershipId of membershipIds) {
        await client.query(
          `INSERT INTO family_chat_thread_members
             (thread_id, family_id, participant_kind, participant_id, membership_id)
           VALUES ($1, $2, 'membership', $3, $3)
           ON CONFLICT (thread_id, participant_kind, participant_id) DO NOTHING`,
          [threadId, familyId, membershipId],
        );
      }
      for (const childId of childIds) {
        await client.query(
          `INSERT INTO family_chat_thread_members
             (thread_id, family_id, participant_kind, participant_id, child_id)
           VALUES ($1, $2, 'child', $3, $3)
           ON CONFLICT (thread_id, participant_kind, participant_id) DO NOTHING`,
          [threadId, familyId, childId],
        );
      }
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
          WHERE thread_id = $1 AND participant_kind = $2 AND participant_id = $3`,
        [threadId, participantKind, participantId],
      );
      return rows[0] ?? null;
    },


    async listThreadChildren(client, { threadId }) {
      const { rows } = await client.query(
        `SELECT child_id FROM family_chat_thread_members
          WHERE thread_id = $1 AND participant_kind = 'child'`,
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
           LEFT JOIN LATERAL (
             SELECT ${MESSAGES_PREFIXED} FROM family_chat_messages m
              WHERE m.thread_id = t.id
              ORDER BY m.seq DESC
              LIMIT 1
           ) last ON TRUE
           LEFT JOIN LATERAL (
             SELECT COUNT(*)::int AS unread_count FROM family_chat_messages m
              WHERE m.thread_id = t.id
                AND m.seq > me.last_read_seq
                AND NOT (m.author_kind = me.participant_kind AND m.author_id = me.participant_id)
           ) unread ON TRUE
           LEFT JOIN LATERAL (
             SELECT COUNT(*)::int AS reader_count FROM family_chat_thread_members other
              WHERE other.thread_id = t.id
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

    async listMessages(client, { threadId, afterSeq, limit }) {
      const { rows } = await client.query(
        `SELECT ${MESSAGE_COLUMNS} FROM family_chat_messages
          WHERE thread_id = $1 AND seq > $2
          ORDER BY seq ASC
          LIMIT $3`,
        [threadId, afterSeq, limit],
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
