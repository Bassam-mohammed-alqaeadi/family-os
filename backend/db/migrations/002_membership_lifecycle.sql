-- Membership lifecycle evidence for explicit invitation revocation and active-member removal.
-- Primary-guardian continuity is intentionally excluded: it requires its own recovery/continuity model.

ALTER TABLE family_memberships
  ADD COLUMN version INTEGER NOT NULL DEFAULT 1 CHECK (version >= 1),
  ADD COLUMN status_changed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  ADD COLUMN status_reason_code TEXT;

ALTER TABLE family_memberships
  ADD CONSTRAINT family_memberships_status_reason_code_length
  CHECK (status_reason_code IS NULL OR char_length(status_reason_code) BETWEEN 3 AND 64);
