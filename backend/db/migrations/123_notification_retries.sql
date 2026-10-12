-- Bounded, durable notification retries with an explicit acceptance boundary.
--
-- A provider call is preceded by a durable `in_flight` row. If the process dies after
-- FCM may have accepted the request, that row is never blindly resent: stale recovery
-- resolves it as `ambiguous`. Clear transient refusals are recorded separately with a
-- durable retry time; an event may make at most five FCM send attempts per registration.

ALTER TABLE outbox_delivery_attempts
  ADD COLUMN attempt_number INTEGER NOT NULL DEFAULT 1,
  ADD COLUMN retry_after_at TIMESTAMPTZ NULL,
  ADD COLUMN recipient_membership_id UUID NULL;

-- Older generic failures did not distinguish a clear refusal from a lost response.
-- Treat them conservatively as ambiguous instead of replaying a possibly accepted push.
ALTER TABLE outbox_delivery_attempts
  DROP CONSTRAINT IF EXISTS outbox_delivery_attempts_outcome_check,
  DROP CONSTRAINT IF EXISTS outbox_delivery_attempts_outcome_evidence,
  DROP CONSTRAINT IF EXISTS outbox_delivery_attempts_one_per_registration;

UPDATE outbox_delivery_attempts
   SET outcome = 'ambiguous',
       failure_reason = COALESCE(failure_reason, 'legacy_outcome_unknown'),
       retry_after_at = NULL
 WHERE outcome = 'failed';

ALTER TABLE outbox_delivery_attempts
  ADD CONSTRAINT outbox_delivery_attempts_outcome_check
    CHECK (outcome IN (
      'in_flight', 'delivered', 'unregistered', 'retryable_failure',
      'permanent_failure', 'ambiguous'
    )),
  ADD CONSTRAINT outbox_delivery_attempts_attempt_number_bounded
    CHECK (attempt_number BETWEEN 1 AND 5),
  ADD CONSTRAINT outbox_delivery_attempts_outcome_evidence CHECK (
    (outcome = 'in_flight'
      AND provider_message_id IS NULL AND failure_reason IS NULL AND retry_after_at IS NULL)
    OR (outcome = 'delivered'
      AND provider_message_id IS NOT NULL AND failure_reason IS NULL AND retry_after_at IS NULL)
    OR (outcome = 'unregistered'
      AND provider_message_id IS NULL AND failure_reason IS NULL AND retry_after_at IS NULL)
    OR (outcome = 'retryable_failure'
      AND provider_message_id IS NULL AND failure_reason IS NOT NULL AND retry_after_at IS NOT NULL)
    OR (outcome IN ('permanent_failure', 'ambiguous')
      AND provider_message_id IS NULL AND failure_reason IS NOT NULL AND retry_after_at IS NULL)
  ),
  ADD CONSTRAINT outbox_delivery_attempts_one_per_attempt
    UNIQUE (outbox_id, registration_id, attempt_number);

CREATE INDEX outbox_delivery_attempts_latest
  ON outbox_delivery_attempts (outbox_id, registration_id, attempt_number DESC);
