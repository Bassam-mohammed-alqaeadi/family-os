-- Collaboration audiences v1.
--
-- Tasks retain the existing single-child reward beneficiary: only that child's claim can become
-- points, and a guardian still confirms it. An optional chat thread scopes task visibility to a
-- server-owned direct or group roster; it does not split or multiply rewards.
--
-- Calendar events snapshot their child invitees into the existing response/attendance table and
-- retain the selected thread as the routing scope. Reminders remain preferences only: this
-- schema does not claim to deliver notifications. Both references are family-composite FKs, so
-- an id from a different household can never be used as an audience.

ALTER TABLE family_tasks
  ADD COLUMN audience_thread_id UUID NULL,
  ADD CONSTRAINT family_tasks_audience_thread_fk
    FOREIGN KEY (family_id, audience_thread_id)
    REFERENCES family_chat_threads (family_id, id) ON DELETE RESTRICT;

ALTER TABLE family_events
  ADD COLUMN audience_thread_id UUID NULL,
  ADD CONSTRAINT family_events_audience_thread_fk
    FOREIGN KEY (family_id, audience_thread_id)
    REFERENCES family_chat_threads (family_id, id) ON DELETE RESTRICT;
