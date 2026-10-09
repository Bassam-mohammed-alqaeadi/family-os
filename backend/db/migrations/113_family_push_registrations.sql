-- W9 PUSH — FCM device registrations for guardians.
--
-- A registration is one device token that may receive a content-free nudge when a room its
-- guardian belongs to has a new message. The nudge names the room and the type of change, and
-- nothing else: no text, no sender, no media. The token names the device and the membership
-- names the person, so a device that changes hands is re-registered by its new owner.
--
-- Tokens are unique across the database. A token that registers again moves to the membership
-- that presented it last; the previous owner stops receiving nudges on that device.
--
-- A message is nudged at most once. The nudge's record is written before the send, so a replayed
-- send (same Idempotency-Key or same clientMessageId) and a restarted server never nudge the same
-- message twice. A nudge lost to a crash between the record and the send is not retried: a
-- nudge is a reminder, and the room is always read on the next open.
--
-- Additive only. Existing rows and tables are unchanged.

CREATE TABLE family_push_registrations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id UUID NOT NULL REFERENCES families(id) ON DELETE RESTRICT,
  membership_id UUID NOT NULL,
  token TEXT NOT NULL,
  platform TEXT NOT NULL CHECK (platform IN ('android', 'ios')),
  -- The language of the nudge's words. Only the two languages the app ships.
  locale TEXT NOT NULL CHECK (locale IN ('ar', 'en')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT family_push_registrations_token_unique UNIQUE (token),
  CONSTRAINT family_push_registrations_token_bounded
    CHECK (char_length(token) BETWEEN 32 AND 4096),
  CONSTRAINT family_push_registrations_membership_fk FOREIGN KEY (family_id, membership_id)
    REFERENCES family_memberships (family_id, id) ON DELETE RESTRICT
);

CREATE INDEX family_push_registrations_membership_idx
  ON family_push_registrations (membership_id);

CREATE TABLE family_push_nudges (
  message_id UUID PRIMARY KEY REFERENCES family_chat_messages(id) ON DELETE CASCADE,
  nudged_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
