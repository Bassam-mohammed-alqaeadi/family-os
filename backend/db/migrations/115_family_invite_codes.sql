-- Family invites by code (owner decision 2026-10-10: a code, not the invitee's account id).
--
-- The membership invitation that already exists needs the invitee's OIDC subject up front,
-- and nothing in the product can tell a guardian that identifier. An invite code turns it
-- around: a primary guardian issues a short code for one role, shares it however the family
-- talks, and the invitee - signed in with their own account - redeems it. The subject is
-- bound at redemption, by the server, from the verified token.
--
-- Laws held by the database, not by the route:
--   * the raw code is never stored: only its SHA-256 digest, unique across all families;
--   * a code is open, redeemed or revoked - and each state carries exactly its own facts;
--   * a redeemed code names the one membership it produced, in the same family, and no
--     membership is produced by two codes;
--   * a code always expires, after it was issued.

CREATE TABLE family_invite_codes (
  id UUID PRIMARY KEY,
  family_id UUID NOT NULL REFERENCES families(id) ON DELETE RESTRICT,
  role TEXT NOT NULL,
  code_hash TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'open',
  created_by_membership_id UUID NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  redeemed_at TIMESTAMPTZ NULL,
  redeemed_membership_id UUID NULL,
  revoked_at TIMESTAMPTZ NULL,
  revoked_by_membership_id UUID NULL,
  CONSTRAINT family_invite_codes_role_valid
    CHECK (role IN ('co_guardian', 'child')),
  CONSTRAINT family_invite_codes_status_valid
    CHECK (status IN ('open', 'redeemed', 'revoked')),
  CONSTRAINT family_invite_codes_code_hash_valid
    CHECK (code_hash ~ '^[0-9a-f]{64}$'),
  CONSTRAINT family_invite_codes_expiry_valid
    CHECK (expires_at > created_at),
  CONSTRAINT family_invite_codes_lifecycle_valid
    CHECK (
      (status = 'open'
        AND redeemed_at IS NULL AND redeemed_membership_id IS NULL
        AND revoked_at IS NULL AND revoked_by_membership_id IS NULL)
      OR (status = 'redeemed'
        AND redeemed_at IS NOT NULL AND redeemed_membership_id IS NOT NULL
        AND revoked_at IS NULL AND revoked_by_membership_id IS NULL)
      OR (status = 'revoked'
        AND revoked_at IS NOT NULL AND revoked_by_membership_id IS NOT NULL
        AND redeemed_at IS NULL AND redeemed_membership_id IS NULL)
    ),
  CONSTRAINT family_invite_codes_creator_same_family_fk
    FOREIGN KEY (family_id, created_by_membership_id)
    REFERENCES family_memberships (family_id, id) ON DELETE RESTRICT,
  CONSTRAINT family_invite_codes_redeemed_same_family_fk
    FOREIGN KEY (family_id, redeemed_membership_id)
    REFERENCES family_memberships (family_id, id) ON DELETE RESTRICT,
  CONSTRAINT family_invite_codes_revoker_same_family_fk
    FOREIGN KEY (family_id, revoked_by_membership_id)
    REFERENCES family_memberships (family_id, id) ON DELETE RESTRICT
);

CREATE UNIQUE INDEX family_invite_codes_code_hash_unique
  ON family_invite_codes (code_hash);

CREATE UNIQUE INDEX family_invite_codes_one_code_per_membership
  ON family_invite_codes (redeemed_membership_id)
  WHERE redeemed_membership_id IS NOT NULL;

CREATE INDEX family_invite_codes_open_by_family
  ON family_invite_codes (family_id, expires_at)
  WHERE status = 'open';
