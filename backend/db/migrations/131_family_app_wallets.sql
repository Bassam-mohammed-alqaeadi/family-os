-- Safety slice 3 — per-app and free wallets, as a projection that is NEVER the truth.
--
-- The truth is family_minutes_ledger (migration 130). This table holds the net of each
-- app wallet and of the free wallet so that a reader can ask "what does this app have"
-- without summing the whole history. It is a cache with a rebuild path, and the test suite
-- proves the rebuild: drop the rows, rebuild them from the ledger, and the numbers match.
--
-- Why only app and free: daily and temporary wallets are windows in time (midnight in the
-- family's timezone, an expiry instant). They are computed at read time from the ledger,
-- because a stored "today" would be wrong at 00:01 without a job to reset it, and the
-- product deliberately has no such job.
--
-- A projection row that disagrees with the ledger is a bug in the writer, not a fact to
-- trust. The rebuild is the repair, and it is idempotent.

CREATE TABLE family_app_wallets (
  id UUID PRIMARY KEY,
  family_id UUID NOT NULL REFERENCES families(id) ON DELETE RESTRICT,
  child_id UUID NOT NULL,
  wallet_scope TEXT NOT NULL CHECK (wallet_scope IN ('app', 'free')),
  -- Named the same way as in the ledger: app wallets name their app, the free wallet names
  -- none. NULLS NOT DISTINCT below makes "one free wallet per child" a database fact, which
  -- a plain UNIQUE would not, because NULLs are never equal to each other there.
  app_id TEXT NULL,
  CONSTRAINT family_app_wallets_app_iff_app_scope
    CHECK ((wallet_scope = 'app') = (app_id IS NOT NULL)),
  -- The net of this wallet: credits minus consumption, reversals and expiries. It can never
  -- be negative for the same reason the ledger's balance cannot.
  earned_minutes INTEGER NOT NULL CHECK (earned_minutes >= 0),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT family_app_wallets_child_fk FOREIGN KEY (family_id, child_id)
    REFERENCES family_children (family_id, id) ON DELETE RESTRICT,
  CONSTRAINT family_app_wallets_one_per_wallet
    UNIQUE NULLS NOT DISTINCT (child_id, wallet_scope, app_id)
);

CREATE INDEX family_app_wallets_child
  ON family_app_wallets (child_id, wallet_scope, app_id);
