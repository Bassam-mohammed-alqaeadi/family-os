-- 137: the preference row gains the one thing that lets a door write it.
--
-- Migration 122 stored a guardian's wishes and migration 136 built the reader that honours them.
-- Neither could be safely *written*: two guardians open the same screen on two handsets, and without
-- a version the later save silently overwrites the earlier one — a family's silence decided by
-- arrival order. `version` makes the write a compare-and-set, so the loser is refused by name and
-- re-reads instead of losing a choice it never saw.
--
-- A row that exists has been written at least once, so it starts at 1. The API's default view for a
-- guardian who never wrote anything reports 0, and that is the number a first PATCH must carry.

ALTER TABLE family_notification_preferences
  ADD COLUMN IF NOT EXISTS version INTEGER NOT NULL DEFAULT 1;

ALTER TABLE family_notification_preferences
  ADD CONSTRAINT family_notification_preferences_version_positive
    CHECK (version >= 1);
