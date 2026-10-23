-- Migration 134: Allow usage_consumption rows to have NULL credit_ref.
-- Phone usage consumption against the daily limit draws from the daily allowance,
-- not from an earned credit, preserving earned balances until spent in the economy.
ALTER TABLE family_minutes_ledger
  DROP CONSTRAINT family_minutes_ledger_credit_ref_shape;

ALTER TABLE family_minutes_ledger
  ADD CONSTRAINT family_minutes_ledger_credit_ref_shape
  CHECK (
    CASE
      WHEN entry_kind = 'credit' THEN credit_ref IS NULL
      WHEN channel = 'usage_consumption' THEN TRUE
      ELSE credit_ref IS NOT NULL
    END
  );


