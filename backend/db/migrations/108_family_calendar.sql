-- W8 FAMILY CALENDAR — what the family agreed to do together, who was told, who answered,
-- and what actually happened.
--
-- The master plan's reason for this wave is blunt: a calendar is what keeps a family inside
-- the app without force. That makes it the first wave whose subject is not protection at all
-- but attendance - and attendance is exactly where a family product starts inventing facts.
-- So this schema holds four things and refuses a fifth:
--
--   family_events            an instant, a title, and who stated it. An event is never deleted:
--                            when a plan changes it is CANCELLED with an author, a reason and
--                            a moment, because "the match was cancelled" is information a child
--                            needs, while a row that vanished teaches a family not to trust the
--                            calendar. `version` is optimistic concurrency: two guardians
--                            editing the same event must collide loudly (409) rather than
--                            silently overwrite each other's plan.
--
--   family_event_audience    who the event is FOR, one row per child. An event with nobody in
--                            its audience is not a family event, it is a note, and the module
--                            refuses it. Audience rows are the invitation; they are not a
--                            delivery claim, and nothing here says a phone was notified.
--
--   family_event_responses   the child's answer, with its author: the child's own paired handset
--                            or the guardian who recorded what the child said. One row per
--                            (event, child) - a second answer is a change of mind and updates
--                            the row, keeping the author who is answering now. Saying no is a
--                            first-class answer: a calendar that only counts yes is a
--                            scoreboard, and a family is not a scoreboard.
--
--   family_event_attendance  WHAT HAPPENED, recorded after the fact by a person. The database
--                            cannot express "now" in a CHECK (it would not be immutable), so the
--                            rule that attendance may not be recorded before an event starts
--                            lives in the module AND is anchored here by the shape of the data:
--                            an attendance row carries who said it and when they said it, so a
--                            claim about the past always has an author and a moment.
--
-- What this migration deliberately does NOT create: no table of reminders sent, no notification
-- log, no "seen" receipts. A reminder in this product is a PREFERENCE a family recorded
-- (`reminder_minutes`), not a promise that a device buzzed - the wave that can honestly claim
-- delivery is the wave that will store delivery, and it will do so with a provider's receipt
-- rather than with this row's good intentions.

CREATE TABLE family_events (
  id UUID PRIMARY KEY,
  family_id UUID NOT NULL REFERENCES families(id) ON DELETE RESTRICT,
  title TEXT NOT NULL,
  note TEXT NOT NULL DEFAULT '',
  location TEXT NOT NULL DEFAULT '',
  starts_at TIMESTAMPTZ NOT NULL,
  ends_at TIMESTAMPTZ NOT NULL,
  all_day BOOLEAN NOT NULL DEFAULT FALSE,
  -- A recorded preference, deliberately nullable: "remind us 30 minutes before" is a fact a
  -- family stated, while NULL means they stated nothing - which is not the same as zero.
  reminder_minutes INTEGER NULL CHECK (reminder_minutes BETWEEN 0 AND 10080),
  status TEXT NOT NULL DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'cancelled')),
  version INTEGER NOT NULL DEFAULT 1 CHECK (version >= 1),
  created_by_membership_id UUID NOT NULL REFERENCES family_memberships(id) ON DELETE RESTRICT,
  cancelled_by_membership_id UUID NULL REFERENCES family_memberships(id) ON DELETE RESTRICT,
  cancelled_at TIMESTAMPTZ NULL,
  cancel_reason TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT family_events_family_id_id_unique UNIQUE (family_id, id),
  -- An event that ends before it starts is a typo wearing a schedule's clothes.
  CONSTRAINT family_events_instant_ordered CHECK (ends_at > starts_at),
  CONSTRAINT family_events_title_present CHECK (title ~ '\S'),
  CONSTRAINT family_events_title_bounded CHECK (char_length(title) <= 120),
  CONSTRAINT family_events_note_bounded CHECK (char_length(note) <= 300),
  CONSTRAINT family_events_location_bounded CHECK (char_length(location) <= 160),
  -- A cancellation is a complete fact or it is not a cancellation: author, moment and status
  -- arrive together, and a scheduled event carries none of them.
  CONSTRAINT family_events_cancellation_complete CHECK (
    (status = 'cancelled'
      AND cancelled_by_membership_id IS NOT NULL
      AND cancelled_at IS NOT NULL
      AND cancel_reason ~ '\S')
    OR (status = 'scheduled'
      AND cancelled_by_membership_id IS NULL
      AND cancelled_at IS NULL
      AND cancel_reason = '')
  )
);

CREATE INDEX family_events_family_starts
  ON family_events (family_id, starts_at);

CREATE TABLE family_event_audience (
  family_id UUID NOT NULL REFERENCES families(id) ON DELETE RESTRICT,
  event_id UUID NOT NULL,
  child_id UUID NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  -- The primary key carries the family as well, because both answers about this row are asked
  -- per family: "who is invited to this event" and "what is this child invited to". It is also
  -- the uniqueness the responses and attendance tables reference, so a response to an event the
  -- child was never invited to is refused by the storage layer, not merely by a code path.
  PRIMARY KEY (family_id, event_id, child_id),
  CONSTRAINT family_event_audience_event_fk FOREIGN KEY (family_id, event_id)
    REFERENCES family_events (family_id, id) ON DELETE RESTRICT,
  CONSTRAINT family_event_audience_child_fk FOREIGN KEY (family_id, child_id)
    REFERENCES family_children (family_id, id) ON DELETE RESTRICT
);

CREATE INDEX family_event_audience_child
  ON family_event_audience (family_id, child_id);

CREATE TABLE family_event_responses (
  id UUID PRIMARY KEY,
  family_id UUID NOT NULL REFERENCES families(id) ON DELETE RESTRICT,
  event_id UUID NOT NULL,
  child_id UUID NOT NULL,
  response TEXT NOT NULL CHECK (response IN ('accepted', 'declined')),
  note TEXT NOT NULL DEFAULT '',
  -- Exactly one author, the same law as a task claim: a handset cannot answer for a family
  -- member, and a guardian cannot hide behind a handset.
  responded_by_device_id UUID NULL REFERENCES family_child_devices(id) ON DELETE RESTRICT,
  responded_by_membership_id UUID NULL REFERENCES family_memberships(id) ON DELETE RESTRICT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT family_event_responses_invited_fk FOREIGN KEY (family_id, event_id, child_id)
    REFERENCES family_event_audience (family_id, event_id, child_id) ON DELETE RESTRICT,
  CONSTRAINT family_event_responses_one_author CHECK (
    (responded_by_device_id IS NOT NULL) <> (responded_by_membership_id IS NOT NULL)
  ),
  CONSTRAINT family_event_responses_note_bounded CHECK (char_length(note) <= 300),
  CONSTRAINT family_event_responses_one_per_child UNIQUE (event_id, child_id)
);

CREATE INDEX family_event_responses_child
  ON family_event_responses (family_id, child_id);

CREATE TABLE family_event_attendance (
  id UUID PRIMARY KEY,
  family_id UUID NOT NULL REFERENCES families(id) ON DELETE RESTRICT,
  event_id UUID NOT NULL,
  child_id UUID NOT NULL,
  attended BOOLEAN NOT NULL,
  note TEXT NOT NULL DEFAULT '',
  -- A person records what happened. Nothing in this table is derived from a phone's presence:
  -- being at a place is not an attendance record this product makes on a child's behalf.
  recorded_by_membership_id UUID NOT NULL REFERENCES family_memberships(id) ON DELETE RESTRICT,
  recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT family_event_attendance_invited_fk FOREIGN KEY (family_id, event_id, child_id)
    REFERENCES family_event_audience (family_id, event_id, child_id) ON DELETE RESTRICT,
  CONSTRAINT family_event_attendance_note_bounded CHECK (char_length(note) <= 300),
  CONSTRAINT family_event_attendance_one_per_child UNIQUE (event_id, child_id)
);

-- Only guardians record attendance, and the module additionally refuses to record it before
-- the event has started or on a cancelled event. This index is the read side: "who was there"
-- for one event, in the order the families ask.
CREATE INDEX family_event_attendance_event
  ON family_event_attendance (family_id, event_id);
