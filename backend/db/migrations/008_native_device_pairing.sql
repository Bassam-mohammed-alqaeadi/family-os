-- Phase 2 Native Child Telemetry & Background GPS.
-- Pairing codes and device credentials are server-side capabilities. Raw values
-- are never persisted: only SHA-256 digests can be retained after issuance.

ALTER TABLE family_child_devices
  ADD COLUMN credential_hash TEXT NULL,
  ADD COLUMN credential_issued_at TIMESTAMPTZ NULL,
  ADD COLUMN credential_revoked_at TIMESTAMPTZ NULL,
  ADD CONSTRAINT family_child_devices_credential_hash_valid
    CHECK (credential_hash IS NULL OR credential_hash ~ '^[0-9a-f]{64}$'),
  ADD CONSTRAINT family_child_devices_credential_lifecycle_valid
    CHECK (
      (credential_hash IS NULL AND credential_issued_at IS NULL AND credential_revoked_at IS NULL)
      OR (credential_hash IS NOT NULL AND credential_issued_at IS NOT NULL)
    );

CREATE UNIQUE INDEX family_child_devices_credential_hash_unique
  ON family_child_devices (credential_hash)
  WHERE credential_hash IS NOT NULL;

CREATE TABLE family_device_pairings (
  id UUID PRIMARY KEY,
  family_id UUID NOT NULL REFERENCES families(id) ON DELETE RESTRICT,
  child_id UUID NOT NULL,
  pairing_code_hash TEXT NOT NULL,
  device_label TEXT NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  claimed_at TIMESTAMPTZ NULL,
  claimed_device_id UUID NULL REFERENCES family_child_devices(id) ON DELETE RESTRICT,
  created_by_membership_id UUID NOT NULL REFERENCES family_memberships(id) ON DELETE RESTRICT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT family_device_pairings_child_scope
    FOREIGN KEY (family_id, child_id)
    REFERENCES family_children (family_id, id)
    ON DELETE RESTRICT,
  CONSTRAINT family_device_pairings_code_hash_valid
    CHECK (pairing_code_hash ~ '^[0-9a-f]{64}$'),
  CONSTRAINT family_device_pairings_label_valid
    CHECK (char_length(btrim(device_label)) BETWEEN 1 AND 80),
  CONSTRAINT family_device_pairings_expiry_valid
    CHECK (expires_at > created_at),
  CONSTRAINT family_device_pairings_claim_valid
    CHECK (
      (claimed_at IS NULL AND claimed_device_id IS NULL)
      OR (claimed_at IS NOT NULL AND claimed_device_id IS NOT NULL)
    )
);

CREATE UNIQUE INDEX family_device_pairings_code_hash_unique
  ON family_device_pairings (pairing_code_hash);

CREATE INDEX family_device_pairings_active_child
  ON family_device_pairings (family_id, child_id, expires_at ASC)
  WHERE claimed_at IS NULL;
