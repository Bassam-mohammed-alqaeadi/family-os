-- Migration 134: Allow usage_consumption rows to have NULL credit_ref.
-- Phone usage consumption against the daily limit draws from the daily allowance,
-- not from an earned credit, preserving earned balances until spent in the economy.
ALTER TABLE family_minutes_ledger
  DROP CONSTRAINT family_minutes_ledger_credit_ref_shape;

ALTER TABLE family_minutes_ledger
  ADD CONSTRAINT family_minutes_ledger_credit_ref_shape
  CHECK ((entry_kind = 'credit' OR channel = 'usage_consumption') = (credit_ref IS NULL));

