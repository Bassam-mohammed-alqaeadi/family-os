-- Safety slice S0 (spine) — extend ai_events with the security-event envelope.
--
-- Principle 4 / item C19: today only `device.*` events are written and there is no
-- shared envelope for security-observable facts, so each vertical invents its own
-- audit/event table (C9 violation). We extend the existing ai_events table rather than
-- create a parallel `security_events` table — one event stream, one outbox, one feed.
--
-- The new columns describe how trustworthy the fact is, how fresh the data is, who is
-- allowed to see it, how long to retain it, and which command/policy/capability produced
-- it. Existing rows are back-filled to `source_trust='unknown'` and
-- `data_quality='unavailable'` so historical data reads honestly.

ALTER TABLE ai_events
  ADD COLUMN source_trust TEXT NOT NULL DEFAULT 'unknown'
    CHECK (source_trust IN ('reported', 'verified', 'inferred', 'unknown')),
  ADD COLUMN data_quality TEXT NOT NULL DEFAULT 'unavailable'
    CHECK (data_quality IN ('fresh', 'stale', 'partial', 'unavailable')),
  ADD COLUMN visibility_class TEXT NULL
    CHECK (visibility_class IS NULL OR visibility_class IN (
      'guardian', 'family', 'child_visible', 'audit_only'
    )),
  ADD COLUMN retention_class TEXT NULL
    CHECK (retention_class IS NULL OR retention_class IN (
      'realtime', 'activity_30d', 'history_90d', 'audit_1y', 'legal_hold'
    )),
  ADD COLUMN capability_key TEXT NULL
    CHECK (
      capability_key IS NULL OR capability_key IN (
        'usage_metering','app_inventory','app_block_overlay','accessibility_enforcement',
        'instant_lock','web_filter_vpn','background_location','boot_persistence',
        'push_delivery','battery_reporting','tamper_signals'
      )
    ),
  ADD COLUMN command_id UUID NULL
    REFERENCES family_commands(id) ON DELETE SET NULL,
  ADD COLUMN causality_id UUID NULL,
  ADD COLUMN severity TEXT NULL
    CHECK (severity IS NULL OR severity IN ('info', 'notice', 'warning', 'critical')),
  -- A link to the originating policy, when the event was produced by policy evaluation.
  ADD COLUMN policy_id UUID NULL;

-- Backfill existing server-originated facts conservatively: they were reported from the
-- device path and are server facts, so mark them `reported`/`fresh`. Old rows with
-- confidence < 1 (none today, but allowed for forward-compat) stay `inferred`/`unknown`.
-- We do this by statement rather than leaving the default 'unknown' so the historical
-- record reads honestly against the new vocabulary.
UPDATE ai_events
   SET source_trust = CASE WHEN confidence >= 1 THEN 'reported' ELSE 'inferred' END,
       data_quality = CASE WHEN confidence >= 1 THEN 'fresh' ELSE 'partial' END
 WHERE source_trust = 'unknown' OR data_quality = 'unavailable';

-- Every alert-worthy fact is joined to its command/capability quickly, and guardians
-- list events by family and occurred_at (already indexed). This adds the slice columns
-- that appear in WHERE clauses.
CREATE INDEX ai_events_command_idx ON ai_events (command_id) WHERE command_id IS NOT NULL;
CREATE INDEX ai_events_capability_idx ON ai_events (family_id, capability_key, occurred_at DESC)
  WHERE capability_key IS NOT NULL;
CREATE INDEX ai_events_severity_idx ON ai_events (family_id, severity, occurred_at DESC)
  WHERE severity IS NOT NULL;
