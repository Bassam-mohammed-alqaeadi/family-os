-- Correlate new Foundation mutations across request handling, audit and outbox evidence.
-- Existing evidence remains intact without fabricated historical correlation IDs.

ALTER TABLE family_audit_events
  ADD COLUMN correlation_id UUID;

ALTER TABLE outbox_events
  ADD COLUMN correlation_id UUID;

CREATE INDEX family_audit_events_correlation_id
  ON family_audit_events (correlation_id)
  WHERE correlation_id IS NOT NULL;

CREATE INDEX outbox_events_correlation_id
  ON outbox_events (correlation_id)
  WHERE correlation_id IS NOT NULL;
