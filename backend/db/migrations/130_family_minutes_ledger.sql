-- Safety slice 3 — minutes economy: the append-only ledger of a child's screen minutes.
--
-- Until now a child's minutes existed only as a number on the phone (WalletLedger), which
-- means a guardian could not see where a minute came from and a child could not spend one
-- that the server had not agreed existed. This table is the single truth: every minute that
-- is earned, granted, spent, reversed or expired is one row here, and a balance is a sum
-- over rows, never a stored number that can drift from the record that produced it.
--
-- THE LAW: rows are appended, never updated and never deleted. A wrong minute is corrected
-- by a NEW reversal row that points at the entry it undoes, so the parent who reads the
-- ledger sees both the mistake and its correction. The trigger below enforces that in the
-- database itself, because an application path someone later adds could otherwise rewrite
-- history quietly.
--
-- Direction is carried by entry_kind, not by the sign of `minutes`: `minutes` is always a
-- positive amount, so a reader cannot misread a reversal as a grant by a sign mistake.
--
-- Wallets (wallet_scope):
--   daily      today's allowance, valid until midnight in the family's own timezone
--   temporary  a grant with an explicit expiry (expires_at), the only kind that expires
--   app        the wallet of one countable app (app_id required)
--   free       the small free wallet spendable across allowed apps (owner decision 2: both)
--
-- Migrations 130-131 are the S3 numbers from §6.1 of the master plan; 125 stays reserved.
-- The earlier 122-124 in the S3 body text are stale and are not used.

CREATE TABLE family_minutes_ledger (
  id UUID PRIMARY KEY,
  family_id UUID NOT NULL REFERENCES families(id) ON DELETE RESTRICT,
  child_id UUID NOT NULL,
  entry_kind TEXT NOT NULL CHECK (entry_kind IN ('credit', 'consumption', 'reversal', 'expiry')),
  -- A closed vocabulary of where minutes come from or go. Adding a channel is a new
  -- migration that widens this list; removing one is never allowed (evolution law, §2.7).
  channel TEXT NOT NULL CHECK (channel IN (
    'quran_portion',
    'athkar',
    'learning_challenge',
    'family_task_child',
    'conditional_app_unlock',
    'guardian_grant',
    'time_request_grant',
    'usage_consumption',
    'guardian_reversal',
    'migration_from_points'
  )),
  -- D20: every row is 1..1440 minutes. No other per-row ceiling exists.
  minutes INTEGER NOT NULL CHECK (minutes > 0 AND minutes <= 1440),
  wallet_scope TEXT NOT NULL CHECK (wallet_scope IN ('daily', 'app', 'free', 'temporary')),
  app_id TEXT NULL,
  -- The wallet an app row belongs to is the app itself; a free or daily row names no app.
  CONSTRAINT family_minutes_ledger_app_iff_app_scope
    CHECK ((wallet_scope = 'app') = (app_id IS NOT NULL)),
  CONSTRAINT family_minutes_ledger_app_id_valid
    CHECK (app_id IS NULL OR char_length(btrim(app_id)) BETWEEN 1 AND 120),
  -- A temporary row carries the expiry of the pool it belongs to. Every other row has none,
  -- so "does this minute expire" is answered by the row, not by the reader's memory.
  expires_at TIMESTAMPTZ NULL,
  CONSTRAINT family_minutes_ledger_expiry_iff_temporary
    CHECK ((wallet_scope = 'temporary') = (expires_at IS NOT NULL)),
  source_type TEXT NOT NULL CHECK (char_length(btrim(source_type)) BETWEEN 1 AND 60),
  source_id TEXT NOT NULL CHECK (char_length(btrim(source_id)) BETWEEN 1 AND 160),
  actor_membership_id UUID NULL REFERENCES family_memberships(id) ON DELETE RESTRICT,
  awarded_by_device_id UUID NULL REFERENCES family_child_devices(id) ON DELETE RESTRICT,
  -- The total the child holds right after this row. Stored as a record of what the family
  -- saw at that moment, and it can never be negative: the server refuses the spend before
  -- it would make the balance negative, so a stored negative would be a bug, not a debt.
  balance_after_minutes INTEGER NOT NULL CHECK (balance_after_minutes >= 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  -- D25: which credit a spend, reversal or expiry draws from. A credit row names none; every
  -- other row names exactly one credit of the same child. This is what makes "how much of this
  -- grant is still unspent" a fact of the ledger, so an expiry records the true remainder.
  credit_ref UUID NULL,
  CONSTRAINT family_minutes_ledger_credit_ref_shape
    CHECK ((entry_kind = 'credit') = (credit_ref IS NULL)),
  CONSTRAINT family_minutes_ledger_child_fk FOREIGN KEY (family_id, child_id)
    REFERENCES family_children (family_id, id) ON DELETE RESTRICT,
  -- The idempotency law (E-5): one source produces one row. Two phones pressing the same
  -- button, or a retried request, cannot credit or spend twice at the storage layer.
  CONSTRAINT family_minutes_ledger_one_row_per_source
    UNIQUE (child_id, source_type, source_id),
  -- Lets a credit reference be checked against the same child (composite key, below).
  CONSTRAINT family_minutes_ledger_id_child_key UNIQUE (id, child_id),
  CONSTRAINT family_minutes_ledger_credit_ref_same_child
    FOREIGN KEY (credit_ref, child_id) REFERENCES family_minutes_ledger (id, child_id) ON DELETE RESTRICT
);

CREATE INDEX family_minutes_ledger_child_created
  ON family_minutes_ledger (child_id, created_at, id);

CREATE INDEX family_minutes_ledger_child_wallet
  ON family_minutes_ledger (child_id, wallet_scope);

CREATE INDEX family_minutes_ledger_credit_ref
  ON family_minutes_ledger (credit_ref) WHERE credit_ref IS NOT NULL;

-- Append-only, enforced where it cannot be bypassed.
CREATE FUNCTION family_minutes_ledger_refuse_mutation() RETURNS trigger
  LANGUAGE plpgsql AS $$
BEGIN
  RAISE EXCEPTION 'family_minutes_ledger is append-only: % refused', TG_OP
    USING ERRCODE = 'restrict_violation';
END;
$$;

CREATE TRIGGER family_minutes_ledger_append_only
  BEFORE UPDATE OR DELETE ON family_minutes_ledger
  FOR EACH ROW EXECUTE FUNCTION family_minutes_ledger_refuse_mutation();
