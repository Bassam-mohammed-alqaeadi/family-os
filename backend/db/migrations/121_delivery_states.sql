-- Safety slice S1 (notifications) — delivery states learn to tell the truth.
--
-- Migration 104 recorded SOS deliveries in exactly two states: `recorded` (the attempt
-- was written down) and `not_configured` (no carrier exists to carry it). Master plan
-- §س١ delivery item 2 adds the two states a guardian actually reads:
--
--   * `delivered` — FCM accepted the message for this handset, and the row carries the
--     proof: the provider's message id and the delivery moment. A row may say
--     `delivered` ONLY with that evidence; evidence exists ONLY on a delivered row.
--   * `failed` — the send was attempted and the provider refused or was unreachable.
--     Like `not_configured`, a failed row names its reason; unlike `not_configured`,
--     the attempt really happened.
--
-- Rows still start life as `recorded` or `not_configured`; the outbox worker (slice س١)
-- is the only writer that moves a row to `delivered` or `failed`, and it does so with
-- the evidence in the same statement. No third party may mint a `delivered`.
--
-- The old paired-reason law ((not_configured) = (reason_code NOT NULL)) is replaced,
-- not extended: the new law pairs a reason with BOTH honest-failure states and keeps
-- successful states reason-free.

ALTER TABLE family_sos_alert_deliveries
  ADD COLUMN delivered_at TIMESTAMPTZ NULL;

-- The provider's own message name (FCM HTTP v1 answers `projects/_/messages/<id>`).
-- This is the evidence a `delivered` row must carry; without it the state is a claim,
-- and claims are not stored here.
ALTER TABLE family_sos_alert_deliveries
  ADD COLUMN fcm_message_id TEXT NULL;

ALTER TABLE family_sos_alert_deliveries
  ADD CONSTRAINT family_sos_alert_deliveries_fcm_message_id_bounded
  CHECK (fcm_message_id IS NULL OR char_length(fcm_message_id) BETWEEN 1 AND 512);

-- Replace the inline two-state CHECK. Its auto-generated name is stable per PostgreSQL
-- rules, but resolving it by definition keeps the migration honest even if the table
-- was ever rebuilt by tooling that renamed constraints.
DO $$
DECLARE
  stale_constraint regclass;
BEGIN
  SELECT c.oid INTO stale_constraint
    FROM pg_constraint c
    JOIN pg_class t ON c.conrelid = t.oid
   WHERE t.relname = 'family_sos_alert_deliveries'
     AND c.contype = 'c'
     AND pg_get_constraintdef(c.oid) LIKE '%delivery_state%'
     AND pg_get_constraintdef(c.oid) LIKE '%recorded%not_configured%'
     AND c.conname NOT IN (
       'family_sos_alert_deliveries_reason_paired',
       'family_sos_alert_deliveries_recipient_exactly_one'
     )
   LIMIT 1;

  IF stale_constraint IS NOT NULL THEN
    EXECUTE format('ALTER TABLE family_sos_alert_deliveries DROP CONSTRAINT %I',
                   (SELECT conname FROM pg_constraint WHERE oid = stale_constraint));
  END IF;
END
$$;

ALTER TABLE family_sos_alert_deliveries
  ADD CONSTRAINT family_sos_alert_deliveries_state_known
  CHECK (delivery_state IN ('recorded', 'not_configured', 'delivered', 'failed'));

-- Drop the old pairing law, then install the wider one.
ALTER TABLE family_sos_alert_deliveries
  DROP CONSTRAINT IF EXISTS family_sos_alert_deliveries_reason_paired;

ALTER TABLE family_sos_alert_deliveries
  ADD CONSTRAINT family_sos_alert_deliveries_reason_pair
  CHECK (
    (reason_code IS NOT NULL)
    = (delivery_state IN ('not_configured', 'failed'))
  );

-- Delivered is a claim that must carry its proof, in both directions.
ALTER TABLE family_sos_alert_deliveries
  ADD CONSTRAINT family_sos_alert_deliveries_delivered_evidence
  CHECK (
    (delivery_state <> 'delivered')
    OR (delivered_at IS NOT NULL AND fcm_message_id IS NOT NULL)
  );

ALTER TABLE family_sos_alert_deliveries
  ADD CONSTRAINT family_sos_alert_deliveries_evidence_pair
  CHECK (
    (delivered_at IS NULL AND fcm_message_id IS NULL)
    OR (delivery_state = 'delivered')
  );
