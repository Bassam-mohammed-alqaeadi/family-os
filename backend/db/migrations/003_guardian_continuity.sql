-- Primary-guardian handover is governed by an explicit continuity case, never a direct role-edit endpoint.
-- Lost-account recovery and support-mediated disputes require a later, separately authorized recovery process.

CREATE TABLE guardian_continuity_cases (
  id UUID PRIMARY KEY,
  family_id UUID NOT NULL REFERENCES families(id) ON DELETE RESTRICT,
  initiator_membership_id UUID NOT NULL,
  candidate_membership_id UUID NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('pending_acceptance', 'completed', 'cancelled', 'expired')),
  expires_at TIMESTAMPTZ NOT NULL,
  completed_at TIMESTAMPTZ,
  cancelled_at TIMESTAMPTZ,
  version INTEGER NOT NULL DEFAULT 1 CHECK (version >= 1),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  FOREIGN KEY (family_id, initiator_membership_id)
    REFERENCES family_memberships (family_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (family_id, candidate_membership_id)
    REFERENCES family_memberships (family_id, id) ON DELETE RESTRICT,
  CHECK (initiator_membership_id <> candidate_membership_id),
  CHECK ((status = 'completed') = (completed_at IS NOT NULL)),
  CHECK ((status = 'cancelled') = (cancelled_at IS NOT NULL))
);

CREATE UNIQUE INDEX guardian_continuity_one_pending_transfer_per_family
  ON guardian_continuity_cases (family_id)
  WHERE status = 'pending_acceptance';

CREATE INDEX guardian_continuity_candidate_pending_lookup
  ON guardian_continuity_cases (candidate_membership_id, expires_at)
  WHERE status = 'pending_acceptance';
