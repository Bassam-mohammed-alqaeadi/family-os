-- Safety slice S1 (notifications) — preferences, typed outbox delivery and outcomes.
--
-- Master plan §س١, delivery item 5: each guardian's quiet hours, push channel and
-- ordinary-event mode belong to the membership, not to the handset. The safety event
-- copy keys in migration 121 are non-silenceable: no preference row may disable SOS,
-- geofence or protection alerts; the dispatcher also bypasses quiet hours and ordinary
-- delivery modes for them.
--
-- S1 keeps the four reviewed messages in code (not as bilingual database seed). The
-- nullable outbox copy_key is mandatory only for those four event types and is paired
-- to the event type by a database CHECK. All other outbox events remain audit-only.

CREATE TABLE family_notification_preferences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id UUID NOT NULL REFERENCES families(id) ON DELETE RESTRICT,
  membership_id UUID NOT NULL,

  quiet_hours_enabled BOOLEAN NOT NULL DEFAULT FALSE,
  quiet_hours_start TIME NULL,
  quiet_hours_end TIME NULL,
  push_allowed BOOLEAN NOT NULL DEFAULT TRUE,
  delivery_mode TEXT NOT NULL DEFAULT 'interrupt'
    CHECK (delivery_mode IN ('interrupt', 'daily_digest', 'history_only')),
  -- Reserved for future ordinary notification types. Safety copy keys are forbidden
  -- here by `family_notification_preferences_never_silence_safety` below.
  disabled_copy_keys TEXT[] NOT NULL DEFAULT '{}'::text[],

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT family_notification_preferences_membership_fk
    FOREIGN KEY (family_id, membership_id)
    REFERENCES family_memberships (family_id, id)
    ON DELETE RESTRICT,
  CONSTRAINT family_notification_preferences_one_per_membership
    UNIQUE (family_id, membership_id),
  CONSTRAINT family_notification_preferences_quiet_pair
    CHECK (
      quiet_hours_enabled
      = (quiet_hours_start IS NOT NULL AND quiet_hours_end IS NOT NULL)
    ),
  CONSTRAINT family_notification_preferences_disabled_keys_bounded
    CHECK (cardinality(disabled_copy_keys) <= 32),
  CONSTRAINT family_notification_preferences_never_silence_safety
    CHECK (NOT (disabled_copy_keys && ARRAY[
      'sos.raised', 'geofence.entered', 'geofence.exited', 'protection.reported'
    ]::text[]))
);

-- These are the four and only four notification types in S1. A key is required for
-- each one; audit-only events may not smuggle user-facing copy into the dispatcher.
ALTER TABLE outbox_events
  ADD COLUMN copy_key TEXT NULL,
  ADD COLUMN failure_reason TEXT NULL,
  ADD COLUMN delivered_at TIMESTAMPTZ NULL,
  ADD COLUMN processing_at TIMESTAMPTZ NULL;

-- Existing geofence and protection events predate copy_key. Backfill only the reviewed
-- S1 notifications; names and other family data remain out of the outbox payload.
UPDATE outbox_events
   SET copy_key = CASE event_type
     WHEN 'family.sos_alert_raised' THEN 'sos.raised'
     WHEN 'family.geofence_entered' THEN 'geofence.entered'
     WHEN 'family.geofence_exited' THEN 'geofence.exited'
     WHEN 'family.device_protection_reported' THEN 'protection.reported'
   END
 WHERE event_type IN (
   'family.sos_alert_raised',
   'family.geofence_entered',
   'family.geofence_exited',
   'family.device_protection_reported'
 );

-- The older outbox used `failed` without a reason and had no worker lease. Preserve
-- its history with a safe reason, and make abandoned in-flight rows eligible again.
UPDATE outbox_events
   SET failure_reason = 'legacy_failure'
 WHERE status = 'failed' AND failure_reason IS NULL;

UPDATE outbox_events
   SET status = 'pending', processing_at = NULL
 WHERE status = 'processing';

ALTER TABLE outbox_events
  DROP CONSTRAINT IF EXISTS outbox_events_status_check;

ALTER TABLE outbox_events
  ADD CONSTRAINT outbox_events_status_check
  CHECK (status IN ('pending', 'processing', 'published', 'delivered', 'failed', 'skipped'));

ALTER TABLE outbox_events
  ADD CONSTRAINT outbox_events_copy_key_pair
  CHECK (
    (copy_key IS NOT NULL AND (
      (event_type = 'family.sos_alert_raised' AND copy_key = 'sos.raised')
      OR (event_type = 'family.geofence_entered' AND copy_key = 'geofence.entered')
      OR (event_type = 'family.geofence_exited' AND copy_key = 'geofence.exited')
      OR (event_type = 'family.device_protection_reported' AND copy_key = 'protection.reported')
    ))
    OR (event_type NOT IN (
      'family.sos_alert_raised',
      'family.geofence_entered',
      'family.geofence_exited',
      'family.device_protection_reported'
    ) AND copy_key IS NULL)
  );

ALTER TABLE outbox_events
  ADD CONSTRAINT outbox_events_failure_reason_pair
  CHECK (
    (status IN ('failed', 'skipped')) = (failure_reason IS NOT NULL)
  );

ALTER TABLE outbox_events
  ADD CONSTRAINT outbox_events_delivered_at_pair
  CHECK ((status = 'delivered') = (delivered_at IS NOT NULL));

ALTER TABLE outbox_events
  ADD CONSTRAINT outbox_events_processing_at_pair
  CHECK ((status = 'processing') = (processing_at IS NOT NULL));

-- One durable result per provider attempt. Registration ids are snapshots rather than
-- foreign keys: an unregistered token is deleted immediately, but its outcome remains
-- auditable without retaining the token itself.
CREATE TABLE outbox_delivery_attempts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  outbox_id UUID NOT NULL REFERENCES outbox_events(id) ON DELETE CASCADE,
  registration_id UUID NOT NULL,
  copy_key TEXT NOT NULL CHECK (copy_key IN (
    'sos.raised', 'geofence.entered', 'geofence.exited', 'protection.reported'
  )),
  outcome TEXT NOT NULL CHECK (outcome IN ('delivered', 'unregistered', 'failed')),
  provider_message_id TEXT NULL,
  failure_reason TEXT NULL,
  attempted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT outbox_delivery_attempts_outcome_evidence CHECK (
    (outcome = 'delivered' AND provider_message_id IS NOT NULL AND failure_reason IS NULL)
    OR (outcome = 'unregistered' AND provider_message_id IS NULL AND failure_reason IS NULL)
    OR (outcome = 'failed' AND provider_message_id IS NULL AND failure_reason IS NOT NULL)
  ),
  CONSTRAINT outbox_delivery_attempts_provider_id_bounded
    CHECK (provider_message_id IS NULL OR char_length(provider_message_id) BETWEEN 1 AND 512),
  CONSTRAINT outbox_delivery_attempts_failure_reason_bounded
    CHECK (failure_reason IS NULL OR char_length(failure_reason) BETWEEN 1 AND 80),
  CONSTRAINT outbox_delivery_attempts_one_per_registration
    UNIQUE (outbox_id, registration_id)
);

CREATE INDEX outbox_delivery_attempts_event
  ON outbox_delivery_attempts (outbox_id, attempted_at ASC, id ASC);
