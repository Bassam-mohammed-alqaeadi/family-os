-- Family OS Foundation Wave: Render-owned durable account, family, membership, audit and outbox state.
-- This migration intentionally contains no Firebase tables, device pairing, notification transport,
-- billing, chat, location, Native-control or AI provider state.

CREATE TABLE accounts (
  id UUID PRIMARY KEY,
  oidc_subject TEXT NOT NULL UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (char_length(oidc_subject) BETWEEN 1 AND 255)
);

CREATE TABLE families (
  id UUID PRIMARY KEY,
  display_name TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'suspended', 'archived')),
  primary_membership_id UUID,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (char_length(btrim(display_name)) BETWEEN 1 AND 120)
);

CREATE TABLE family_memberships (
  id UUID PRIMARY KEY,
  family_id UUID NOT NULL REFERENCES families(id) ON DELETE RESTRICT,
  account_id UUID REFERENCES accounts(id) ON DELETE RESTRICT,
  target_subject TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('primary_guardian', 'co_guardian', 'child')),
  status TEXT NOT NULL CHECK (status IN ('invited', 'active', 'revoked', 'removed')),
  invited_by_membership_id UUID REFERENCES family_memberships(id) ON DELETE RESTRICT,
  joined_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (char_length(target_subject) BETWEEN 1 AND 255),
  CHECK (
    (status = 'invited' AND account_id IS NULL AND joined_at IS NULL)
    OR (status = 'active' AND account_id IS NOT NULL AND joined_at IS NOT NULL)
    OR status IN ('revoked', 'removed')
  )
);

ALTER TABLE family_memberships
  ADD CONSTRAINT family_memberships_family_id_id_unique UNIQUE (family_id, id);

-- A family primary membership must belong to that exact family, not merely any membership row.
ALTER TABLE families
  ADD CONSTRAINT families_primary_membership_same_family_fk
  FOREIGN KEY (id, primary_membership_id)
  REFERENCES family_memberships (family_id, id)
  ON DELETE RESTRICT;

CREATE UNIQUE INDEX family_one_active_primary_guardian
  ON family_memberships (family_id)
  WHERE role = 'primary_guardian' AND status = 'active';

CREATE UNIQUE INDEX family_one_current_membership_per_subject
  ON family_memberships (family_id, target_subject)
  WHERE status IN ('invited', 'active');

CREATE UNIQUE INDEX family_one_active_membership_per_account
  ON family_memberships (family_id, account_id)
  WHERE status = 'active';

CREATE INDEX family_memberships_active_account_lookup
  ON family_memberships (family_id, account_id)
  WHERE status = 'active';

CREATE TABLE family_audit_events (
  id UUID PRIMARY KEY,
  family_id UUID NOT NULL REFERENCES families(id) ON DELETE RESTRICT,
  actor_membership_id UUID REFERENCES family_memberships(id) ON DELETE RESTRICT,
  event_type TEXT NOT NULL,
  subject_type TEXT NOT NULL,
  subject_id UUID NOT NULL,
  occurred_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (char_length(event_type) BETWEEN 1 AND 120),
  CHECK (char_length(subject_type) BETWEEN 1 AND 80)
);

CREATE INDEX family_audit_events_family_occurred_at
  ON family_audit_events (family_id, occurred_at DESC);

CREATE TABLE outbox_events (
  id UUID PRIMARY KEY,
  aggregate_type TEXT NOT NULL,
  aggregate_id UUID NOT NULL,
  event_type TEXT NOT NULL,
  payload JSONB NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'published', 'failed')),
  available_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  attempts INTEGER NOT NULL DEFAULT 0 CHECK (attempts >= 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  published_at TIMESTAMPTZ,
  CHECK (char_length(aggregate_type) BETWEEN 1 AND 80),
  CHECK (char_length(event_type) BETWEEN 1 AND 120)
);

CREATE INDEX outbox_events_pending_delivery
  ON outbox_events (available_at, created_at)
  WHERE status = 'pending';

CREATE TABLE idempotency_records (
  operation_scope TEXT NOT NULL,
  idempotency_key TEXT NOT NULL,
  request_hash TEXT NOT NULL,
  response_body JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  PRIMARY KEY (operation_scope, idempotency_key),
  CHECK (char_length(operation_scope) BETWEEN 1 AND 255),
  CHECK (char_length(idempotency_key) BETWEEN 1 AND 128),
  CHECK (char_length(request_hash) = 64),
  CHECK ((response_body IS NULL AND completed_at IS NULL) OR (response_body IS NOT NULL AND completed_at IS NOT NULL))
);
