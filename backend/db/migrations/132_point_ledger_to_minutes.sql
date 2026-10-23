-- Safety slice 3 — D2: every confirmed task point becomes a screen minute, once.
--
-- The points a child earned through family tasks were a separate number (family_point_ledger).
-- From now on a confirmed task credits the minutes ledger (channel family_task_child), and the
-- points table is history only: it is read, never written again. This migration carries every
-- historical award across, 1 point = 1 minute (the task's own number, set by the guardian when
-- the task was created), into the FREE wallet — a child-level number has no app to belong to
-- (owner decision recorded as S3 fact 11).
--
-- Each old award becomes one credit whose source is the old row's id. The unique key on
-- (child, source_type, source_id) makes the copy idempotent: running this twice adds nothing.
--
-- The migration proves itself before it commits: the number of awards, their total, and the
-- coverage (no award without exactly one credit) must agree, or the migration fails and nothing
-- is applied. A transfer that lost or invented a minute cannot be recorded as complete.

INSERT INTO family_minutes_ledger (
  id, family_id, child_id, entry_kind, channel, minutes, wallet_scope, app_id, expires_at,
  source_type, source_id, actor_membership_id, awarded_by_device_id, balance_after_minutes,
  created_at, credit_ref
)
SELECT
  gen_random_uuid(),
  p.family_id,
  p.child_id,
  'credit',
  'migration_from_points',
  p.points,
  'free',
  NULL,
  NULL,
  'point_ledger_migration',
  p.id::text,
  p.awarded_by_membership_id,
  NULL,
  -- The running total for the child: whatever the ledger already held, plus the migrated awards
  -- in the order they were earned. Recomputed from rows, never trusted from a previous run.
  COALESCE((
    SELECT SUM(CASE WHEN m.entry_kind = 'credit' THEN m.minutes
                    WHEN m.entry_kind = 'expiry' THEN 0
                    ELSE -m.minutes END)
      FROM family_minutes_ledger m
     WHERE m.child_id = p.child_id
  ), 0) + SUM(p.points) OVER (PARTITION BY p.child_id ORDER BY p.created_at, p.id),
  p.created_at,
  NULL
FROM family_point_ledger p
WHERE p.reason = 'task_confirmed'
ORDER BY p.created_at, p.id
ON CONFLICT (child_id, source_type, source_id) DO NOTHING;

-- The three confirmations (count, sum, coverage). Any mismatch aborts the migration.
DO $$
DECLARE
  old_count BIGINT;
  old_total BIGINT;
  new_count BIGINT;
  new_total BIGINT;
  uncovered BIGINT;
BEGIN
  SELECT COUNT(*), COALESCE(SUM(points), 0) INTO old_count, old_total
    FROM family_point_ledger WHERE reason = 'task_confirmed';
  SELECT COUNT(*), COALESCE(SUM(minutes), 0) INTO new_count, new_total
    FROM family_minutes_ledger WHERE source_type = 'point_ledger_migration';
  SELECT COUNT(*) INTO uncovered
    FROM family_point_ledger p
   WHERE p.reason = 'task_confirmed'
     AND NOT EXISTS (
       SELECT 1 FROM family_minutes_ledger m
        WHERE m.source_type = 'point_ledger_migration'
          AND m.source_id = p.id::text
          AND m.child_id = p.child_id
          AND m.channel = 'migration_from_points'
          AND m.wallet_scope = 'free'
          AND m.minutes = p.points
     );
  IF old_count <> new_count THEN
    RAISE EXCEPTION 'point migration count mismatch: % awards, % credits', old_count, new_count;
  END IF;
  IF old_total <> new_total THEN
    RAISE EXCEPTION 'point migration sum mismatch: % points, % minutes', old_total, new_total;
  END IF;
  IF uncovered <> 0 THEN
    RAISE EXCEPTION 'point migration coverage: % awards have no matching credit', uncovered;
  END IF;
END $$;
