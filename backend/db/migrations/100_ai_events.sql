-- AiEvent v1 — the append-only fact envelope emitted by product systems from
-- the first vertical slice, so the intelligence systems consume real history
-- instead of reconstructing it. This migration stores observed facts only: it
-- creates no suggestion, no inference, no score and no autonomous action.

CREATE TABLE ai_events (
  id UUID PRIMARY KEY,
  schema_version TEXT NOT NULL,
  event_type TEXT NOT NULL,
  family_id UUID NOT NULL REFERENCES families(id) ON DELETE RESTRICT,
  child_id UUID NULL,
  device_id UUID NULL,
  policy_version TEXT NOT NULL,
  source TEXT NOT NULL,
  confidence NUMERIC(4, 3) NOT NULL,
  explanation TEXT NOT NULL,
  reject_path TEXT NULL,
  correlation_id UUID NOT NULL,
  occurred_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT ai_events_schema_version_known
    CHECK (schema_version = 'ai-event.v1'),
  CONSTRAINT ai_events_event_type_valid
    CHECK (char_length(btrim(event_type)) BETWEEN 1 AND 120),
  CONSTRAINT ai_events_child_scope
    FOREIGN KEY (family_id, child_id)
    REFERENCES family_children (family_id, id)
    ON DELETE RESTRICT,
  CONSTRAINT ai_events_policy_version_valid
    CHECK (char_length(btrim(policy_version)) BETWEEN 1 AND 64),
  CONSTRAINT ai_events_source_valid
    CHECK (source IN ('server')),
  -- An observed fact is certain; an inferred one is not. Suggestions are
  -- admitted later, with their own confidence and a mandatory reject path.
  CONSTRAINT ai_events_confidence_range
    CHECK (confidence >= 0 AND confidence <= 1),
  CONSTRAINT ai_events_explanation_valid
    CHECK (char_length(btrim(explanation)) BETWEEN 1 AND 240),
  CONSTRAINT ai_events_fact_has_no_reject_path
    CHECK (source <> 'server' OR (confidence = 1 AND reject_path IS NULL))
);

CREATE INDEX ai_events_family_occurred_at
  ON ai_events (family_id, occurred_at DESC, id DESC);
