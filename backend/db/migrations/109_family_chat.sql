-- W9 FAMILY CHAT — who may read a thread, what a message is, and what the server can honestly
-- say about it.
--
-- The master plan names this wave the biggest security risk in the domain, to be built last and
-- carefully. The risk is not the message text; it is the authorization around it. A family
-- chat that lets one guardian read a thread they were not part of, or lets a child be reached
-- by someone the family never approved, or draws "read" when nobody read, is worse than no chat
-- at all - because families will put things in it. So this schema holds four things and refuses
-- a fifth:
--
--   family_chat_threads          a room with a kind ('family' for the household room, 'child'
--                                for a thread with one child) and its own sequence counter.
--                                The counter lives on the thread row on purpose: `next_seq` is
--                                allocated with a single UPDATE ... RETURNING inside the same
--                                transaction that inserts the message, so ordering is the
--                                server's, never a client clock's, and two senders can never
--                                share a sequence number.
--
--   family_chat_thread_members   the authorization itself, as rows. Participation is explicit:
--                                a membership (guardian) or a child, one row each, with the
--                                child foreign key pointing at family_children and the
--                                membership foreign key at family_memberships. Reading a thread
--                                in the module means "a member row for this caller exists",
--                                which is why a guardian cannot read a thread they are not in -
--                                not because a check says so, but because there is nothing to
--                                read with. `last_read_seq` is the participant's own statement
--                                of how far they read; it only ever moves forward.
--
--   family_chat_messages         one message, authored by a participant. Two laws are anchored
--                                in storage rather than in code:
--                                  * the author must be a member of the thread - a composite
--                                    foreign key to family_chat_thread_members, so a message
--                                    from outside the room cannot exist as a row at all;
--                                  * (thread, author, client_message_id) is UNIQUE, so a resend
--                                    of the same client message is the same message, not a
--                                    second one.
--                                A message is never hard-deleted and never silently edited:
--                                `revision` and `edited_at` travel together, and a deleted
--                                message keeps its sequence number as a tombstone - a hole in
--                                the sequence would make the thread itself untrustworthy.
--
--   family_chat_message_revisions  the body a message carried before its last edit. It exists
--                                so an edit is provable rather than a silent rewrite. A DELETE
--                                removes these rows and clears the body: deletion is a right,
--                                and a product that keeps the text anyway has not deleted
--                                anything. What remains after deletion is the trace - who
--                                deleted, and when - which is the same law W8 used for events.
--
-- What this migration deliberately does NOT create: no delivery table and no "seen" per
-- person. There is no push transport in this wave, so a delivery claim would be a guess with a
-- timestamp; and per-person read identities turn a family room into a surveillance log. The one
-- receipt this product will state is the aggregate `readCount` the module computes from
-- `last_read_seq` - "how many participants have read up to here" - which is a fact the server
-- can prove and no one can weaponise.

CREATE TABLE family_chat_threads (
  id UUID PRIMARY KEY,
  family_id UUID NOT NULL REFERENCES families(id) ON DELETE RESTRICT,
  kind TEXT NOT NULL CHECK (kind IN ('family', 'child')),
  title TEXT NOT NULL DEFAULT '',
  -- Allocated by the server inside the sending transaction; never supplied by a client.
  next_seq BIGINT NOT NULL DEFAULT 1 CHECK (next_seq >= 1),
  created_by_membership_id UUID NOT NULL REFERENCES family_memberships(id) ON DELETE RESTRICT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT family_chat_threads_family_id_id_unique UNIQUE (family_id, id),
  CONSTRAINT family_chat_threads_title_bounded CHECK (char_length(title) <= 120)
);

CREATE TABLE family_chat_thread_members (
  thread_id UUID NOT NULL REFERENCES family_chat_threads(id) ON DELETE RESTRICT,
  family_id UUID NOT NULL REFERENCES families(id) ON DELETE RESTRICT,
  participant_kind TEXT NOT NULL CHECK (participant_kind IN ('membership', 'child')),
  -- Exactly one of the two identities is present, and it is the one the kind names. The
  -- redundant `participant_id` exists so composite foreign keys can point at this row.
  participant_id UUID NOT NULL,
  membership_id UUID NULL REFERENCES family_memberships(id) ON DELETE RESTRICT,
  child_id UUID NULL REFERENCES family_children(id) ON DELETE RESTRICT,
  last_read_seq BIGINT NOT NULL DEFAULT 0 CHECK (last_read_seq >= 0),
  joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (thread_id, participant_kind, participant_id),
  CONSTRAINT family_chat_thread_members_identity_complete CHECK (
    (participant_kind = 'membership'
      AND membership_id IS NOT NULL
      AND child_id IS NULL
      AND participant_id = membership_id)
    OR (participant_kind = 'child'
      AND child_id IS NOT NULL
      AND membership_id IS NULL
      AND participant_id = child_id)
  )
);

CREATE INDEX family_chat_thread_members_participant_idx
  ON family_chat_thread_members (participant_kind, participant_id);

CREATE TABLE family_chat_messages (
  id UUID PRIMARY KEY,
  family_id UUID NOT NULL REFERENCES families(id) ON DELETE RESTRICT,
  thread_id UUID NOT NULL,
  seq BIGINT NOT NULL CHECK (seq >= 1),
  author_kind TEXT NOT NULL CHECK (author_kind IN ('membership', 'child')),
  author_id UUID NOT NULL,
  body TEXT NOT NULL DEFAULT '',
  client_message_id TEXT NOT NULL,
  revision INTEGER NOT NULL DEFAULT 1 CHECK (revision >= 1),
  edited_at TIMESTAMPTZ NULL,
  deleted_at TIMESTAMPTZ NULL,
  deleted_by_kind TEXT NULL CHECK (deleted_by_kind IN ('membership', 'child')),
  deleted_by_id UUID NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT family_chat_messages_thread_fk FOREIGN KEY (family_id, thread_id)
    REFERENCES family_chat_threads (family_id, id) ON DELETE RESTRICT,
  -- The room is the permission: a message whose author is not a member of this thread cannot
  -- be stored, no matter which code path tried.
  CONSTRAINT family_chat_messages_author_fk FOREIGN KEY (thread_id, author_kind, author_id)
    REFERENCES family_chat_thread_members (thread_id, participant_kind, participant_id)
    ON DELETE RESTRICT,
  CONSTRAINT family_chat_messages_thread_seq_unique UNIQUE (thread_id, seq),
  CONSTRAINT family_chat_messages_client_unique
    UNIQUE (thread_id, author_kind, author_id, client_message_id),
  CONSTRAINT family_chat_messages_client_id_bounded
    CHECK (char_length(client_message_id) BETWEEN 8 AND 64),
  CONSTRAINT family_chat_messages_body_bounded CHECK (char_length(body) <= 2000),
  -- A live message carries a body; a deleted one keeps the trace and loses the text.
  CONSTRAINT family_chat_messages_lifecycle_complete CHECK (
    (deleted_at IS NULL
      AND deleted_by_kind IS NULL
      AND deleted_by_id IS NULL
      AND body ~ '\S')
    OR (deleted_at IS NOT NULL
      AND deleted_by_kind IS NOT NULL
      AND deleted_by_id IS NOT NULL
      AND body = '')
  ),
  -- "Edited" is a claim about the past, so it always carries the moment it happened.
  CONSTRAINT family_chat_messages_edit_complete CHECK (
    (revision = 1 AND edited_at IS NULL)
    OR (revision > 1 AND edited_at IS NOT NULL)
  )
);

CREATE TABLE family_chat_message_revisions (
  message_id UUID NOT NULL REFERENCES family_chat_messages(id) ON DELETE RESTRICT,
  -- The revision this body belonged to before it was replaced.
  revision INTEGER NOT NULL CHECK (revision >= 1),
  body TEXT NOT NULL CHECK (body ~ '\S'),
  edited_by_kind TEXT NOT NULL CHECK (edited_by_kind IN ('membership', 'child')),
  edited_by_id UUID NOT NULL,
  edited_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (message_id, revision)
);
