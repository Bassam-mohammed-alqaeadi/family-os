-- Safety slice 2 — the child-consent ledger.
--
-- Play's User Data and Background Location rules require a prominent disclosure and an
-- explicit consent action before location is collected, and this table is the server's
-- record of that action: who consented, when, and which disclosure text they saw. A
-- recording here is compliance evidence inside the product, not user-facing chrome.
--
-- One active consent per (child, capability). Withdrawing writes the moment of withdrawal
-- on the active row and freezes it; a later grant is a new row, so the full history of
-- grants and withdrawals stays readable. Exactly one granter per row: either a guardian
-- membership acted, or the child's own handset recorded its setup agreement — the pair
-- is a CHECK, not a convention.
--
-- Enforcement lives outside this file: location fixes are refused with `consent_required`
-- while no active `location` row exists for the child. The table grants nothing by itself.
--
-- Additive only. Existing rows and tables are unchanged.

ALTER TABLE family_child_devices
  ADD CONSTRAINT family_child_devices_family_scope_unique UNIQUE (family_id, id);

CREATE TABLE family_child_consents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id UUID NOT NULL REFERENCES families(id) ON DELETE RESTRICT,
  child_id UUID NOT NULL,
  capability TEXT NOT NULL
    CHECK (capability IN ('location', 'usage_stats', 'web_filtering')),
  -- The version of the disclosure text the consenter saw. A consent recorded against a
  -- text that does not exist is not evidence of anything.
  text_version TEXT NOT NULL,
  granted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  granted_by_membership_id UUID NULL,
  granted_by_device_id UUID NULL,
  withdrawn_at TIMESTAMPTZ NULL,
  withdrawn_by_membership_id UUID NULL,
  CONSTRAINT family_child_consents_child_scope
    FOREIGN KEY (family_id, child_id)
    REFERENCES family_children (family_id, id)
    ON DELETE RESTRICT,
  CONSTRAINT family_child_consents_text_version_valid
    CHECK (char_length(btrim(text_version)) BETWEEN 1 AND 64),
  -- Exactly one granter: a guardian, or the child's handset at setup. Never both,
  -- never neither.
  CONSTRAINT family_child_consents_granter_valid
    CHECK ((granted_by_membership_id IS NOT NULL) <> (granted_by_device_id IS NOT NULL)),
  CONSTRAINT family_child_consents_membership_fk
    FOREIGN KEY (family_id, granted_by_membership_id)
    REFERENCES family_memberships (family_id, id)
    ON DELETE RESTRICT,
  CONSTRAINT family_child_consents_device_fk
    FOREIGN KEY (family_id, granted_by_device_id)
    REFERENCES family_child_devices (family_id, id)
    ON DELETE RESTRICT,
  -- Withdrawal is a guardian act and is timestamped in full or not at all.
  CONSTRAINT family_child_consents_withdrawal_pair
    CHECK ((withdrawn_at IS NULL) = (withdrawn_by_membership_id IS NULL))
);

-- At most one active consent per capability; history stays in the withdrawn rows.
CREATE UNIQUE INDEX family_child_consents_active_unique
  ON family_child_consents (child_id, capability)
  WHERE withdrawn_at IS NULL;

CREATE INDEX family_child_consents_child_capability_idx
  ON family_child_consents (child_id, capability, granted_at DESC);
