-- 136: the three truths the delivery gate was missing.
--
-- Migration 122 stored a guardian's quiet hours as a pair of clock faces with no idea whose
-- clock they belonged to, so a window could only ever be judged against UTC. It pinned the
-- copy-key vocabulary to the four safety events, which are exactly the events that must never be
-- silenced — so `delivery_mode`, `push_allowed` and `disabled_copy_keys` had nothing to act on.
-- And a notification that was deliberately muted simply never appeared, leaving no answer to
-- "why did I not hear about it".
--
-- This migration gives the window a clock, opens the vocabulary to the first ordinary alert, and
-- gives silence a ledger. Every relaxation ships in the same slice as the code that satisfies it:
-- `appendAuditAndOutbox` stamps the copy key from `NOTIFY_TYPES`, so a promoted event carries its
-- key automatically and the rows stored before promotion are backfilled here.

ALTER TABLE family_notification_preferences
  ADD COLUMN IF NOT EXISTS quiet_hours_offset_minutes SMALLINT NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS child_requests_enabled BOOLEAN NOT NULL DEFAULT TRUE;

-- Fourteen hours either side covers every inhabited zone, and 840 is the largest real offset.
ALTER TABLE family_notification_preferences
  ADD CONSTRAINT family_notification_preferences_offset_bounded
    CHECK (quiet_hours_offset_minutes BETWEEN -840 AND 840);

-- The promoted ordinary alert. Existing claim rows carry no key because no writer was allowed to
-- set one; they are the same event the gate must now be able to speak about.
UPDATE outbox_events
   SET copy_key = 'task.claimed'
 WHERE event_type = 'family.task_claimed' AND copy_key IS NULL;

ALTER TABLE outbox_events
  DROP CONSTRAINT outbox_events_copy_key_pair;

ALTER TABLE outbox_events
  ADD CONSTRAINT outbox_events_copy_key_pair
  CHECK (
    (copy_key IS NOT NULL AND (
      (event_type = 'family.sos_alert_raised' AND copy_key = 'sos.raised')
      OR (event_type = 'family.geofence_entered' AND copy_key = 'geofence.entered')
      OR (event_type = 'family.geofence_exited' AND copy_key = 'geofence.exited')
      OR (event_type = 'family.device_protection_reported' AND copy_key = 'protection.reported')
      OR (event_type = 'family.task_claimed' AND copy_key = 'task.claimed')
    ))
    OR (event_type NOT IN (
      'family.sos_alert_raised',
      'family.geofence_entered',
      'family.geofence_exited',
      'family.device_protection_reported',
      'family.task_claimed'
    ) AND copy_key IS NULL)
  );

ALTER TABLE outbox_delivery_attempts
  DROP CONSTRAINT outbox_delivery_attempts_copy_key_check;

ALTER TABLE outbox_delivery_attempts
  ADD CONSTRAINT outbox_delivery_attempts_copy_key_check
  CHECK (copy_key IN (
    'sos.raised', 'geofence.entered', 'geofence.exited', 'protection.reported', 'task.claimed'
  ));

-- The ledger of silence: one row per recipient who was deliberately not told, or who was told
-- only because a safety alert outranks the family's wish. A clean delivery leaves no row here —
-- `outbox_delivery_attempts` is that evidence, and duplicating it would be a second truth.
--
-- A suppression is never written as a delivery, and it is never written as
-- `outbox_events.status = 'skipped'` either: that status is one verdict for the whole event,
-- while a single family can hold one guardian inside quiet hours and another who asked to be told.
CREATE TABLE outbox_delivery_decisions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,
  membership_id UUID NOT NULL,
  outbox_id UUID NOT NULL REFERENCES outbox_events(id) ON DELETE CASCADE,
  -- A snapshot rather than a foreign key, exactly as the attempts table does it: a token that
  -- unregisters is deleted at once, and the reason that handset was silenced must survive it.
  registration_id UUID NOT NULL,
  copy_key TEXT NOT NULL CHECK (copy_key IN (
    'sos.raised', 'geofence.entered', 'geofence.exited', 'protection.reported', 'task.claimed'
  )),
  decision TEXT NOT NULL CHECK (decision IN ('delivered', 'suppressed', 'digest_queued')),
  reason TEXT NOT NULL CHECK (reason IN (
    'safety_bypass', 'push_disabled', 'copy_muted', 'child_requests_disabled',
    'history_only', 'digest_mode', 'quiet_hours'
  )),
  blocked_by TEXT NULL,
  decided_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT outbox_delivery_decisions_membership_fk
    FOREIGN KEY (family_id, membership_id)
    REFERENCES family_memberships (family_id, id)
    ON DELETE CASCADE,
  -- Written as equivalences rather than implications on purpose. An `AND blocked_by IN (...)` arm
  -- would evaluate to NULL for a missing note, and Postgres accepts a NULL CHECK — so a bypass
  -- could be stored without naming what it overrode, which is the one thing this table is for.
  CONSTRAINT outbox_delivery_decisions_reason_pair
    CHECK (
      (decision = 'delivered') = (reason = 'safety_bypass')
      AND (decision = 'delivered') = (blocked_by IS NOT NULL)
      AND (decision = 'digest_queued') = (reason = 'digest_mode')
      AND (decision = 'suppressed')
        = (reason <> 'safety_bypass' AND reason <> 'digest_mode')
    ),
  -- One verdict per recipient of one event: a retry or an expired lease may not rewrite the
  -- explanation the handset first met, and it may not add a second copy of it.
  CONSTRAINT outbox_delivery_decisions_one_per_target
    UNIQUE (outbox_id, registration_id)
);

CREATE INDEX outbox_delivery_decisions_by_recipient
  ON outbox_delivery_decisions (family_id, membership_id, decided_at DESC, id DESC);
