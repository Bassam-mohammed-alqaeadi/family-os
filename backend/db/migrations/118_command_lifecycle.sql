-- Safety slice S0 (spine) — command lifecycle and delivery receipts.
--
-- Principle 3 (asynchronous commands): every intent from guardian or policy is a row
-- with an id, an idempotency key, an expiry, and a lifecycle:
--     accepted -> dispatched -> received -> applied | limited | rejected | expired | failed
--
-- A late handset never applies an expired command without re-evaluation. A retry with the
-- same idempotency key replays the first answer — it never creates a second row. The
-- cancel of a command is itself a NEW command (auditable, versioned), never a deletion.
--
-- S0 deliberately ships only THREE command types: `lock_now`, `release_lock`, `refresh_policy`.
-- Every other command type is added in its own slice against this same spine. The CHECK
-- constraint is narrow on purpose so that a misrouted command fails loudly.

CREATE TABLE family_commands (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id UUID NOT NULL REFERENCES families(id) ON DELETE RESTRICT,
  child_id UUID NOT NULL,
  device_id UUID NOT NULL,
  command_type TEXT NOT NULL CHECK (command_type IN (
    'lock_now',
    'release_lock',
    'refresh_policy'
  )),
  policy_id UUID NULL,
  policy_version INTEGER NULL,
  payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  actor_membership_id UUID NULL,
  idempotency_key TEXT NOT NULL,
  priority INTEGER NOT NULL DEFAULT 100 CHECK (priority BETWEEN 0 AND 1000),
  expires_at TIMESTAMPTZ NOT NULL,
  state TEXT NOT NULL DEFAULT 'accepted' CHECK (state IN (
    'accepted',
    'dispatched',
    'received',
    'applied',
    'limited',
    'rejected',
    'expired',
    'failed'
  )),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  dispatched_at TIMESTAMPTZ NULL,
  received_at TIMESTAMPTZ NULL,
  applied_at TIMESTAMPTZ NULL,
  failure_reason TEXT NULL
    CHECK (failure_reason IS NULL OR char_length(btrim(failure_reason)) BETWEEN 1 AND 256),
  CONSTRAINT family_commands_child_scope
    FOREIGN KEY (family_id, child_id)
    REFERENCES family_children (family_id, id)
    ON DELETE RESTRICT,
  CONSTRAINT family_commands_device_scope
    FOREIGN KEY (family_id, device_id)
    REFERENCES family_child_devices (family_id, id)
    ON DELETE RESTRICT,
  -- Either a guardian acts (membership) or the system/policy issues the command.
  CONSTRAINT family_commands_actor_fk
    FOREIGN KEY (family_id, actor_membership_id)
    REFERENCES family_memberships (family_id, id)
    ON DELETE RESTRICT,
  -- One command per idempotency key per family/device. Retries are replays, not duplicates.
  CONSTRAINT family_commands_idempotency_unique
    UNIQUE (family_id, device_id, idempotency_key),
  -- Payload is always an object (never array/scalar/null after normalisation).
  CONSTRAINT family_commands_payload_object
    CHECK (jsonb_typeof(payload) = 'object'),
  -- Terminal timestamps pair honestly with their state, the same way consents pair their
  -- withdrawal: applied_at exists exactly for 'applied', failure_reason for failure states.
  CONSTRAINT family_commands_appied_pair
    CHECK (
      (state = 'applied' AND applied_at IS NOT NULL)
      OR (state <> 'applied' AND applied_at IS NULL)
    ),
  CONSTRAINT family_commands_failure_pair
    CHECK (
      ((state IN ('failed','rejected','limited','expired')) AND failure_reason IS NOT NULL)
      OR (state NOT IN ('failed','rejected','limited','expired')) AND failure_reason IS NULL
    )
);

-- A handset polls/dispatches by device and state (oldest accepted first).
CREATE INDEX family_commands_pending_for_device_idx
  ON family_commands (device_id, created_at ASC, id ASC)
  WHERE state IN ('accepted', 'dispatched');

CREATE INDEX family_commands_family_created_idx
  ON family_commands (family_id, created_at DESC, id DESC);

-- The delivery receipt: what the handset actually DID when it processed a command.
--
-- A command can be (a) applied cleanly, (b) applied in a limited way (e.g. another lock
-- already held), or (c) failed. Re-sent receipts with the same (command_id, kind) update
-- in place — the latest honest answer wins.
CREATE TABLE family_command_receipts (
  command_id UUID NOT NULL PRIMARY KEY
    REFERENCES family_commands(id) ON DELETE CASCADE,
  receipt_kind TEXT NOT NULL CHECK (receipt_kind IN ('applied', 'limited', 'failed')),
  effective_state JSONB NOT NULL DEFAULT '{}'::jsonb
    CHECK (jsonb_typeof(effective_state) = 'object'),
  observed_at_device TIMESTAMPTZ NOT NULL,
  received_at_server TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  failure_reason TEXT NULL
    CHECK (failure_reason IS NULL OR char_length(btrim(failure_reason)) BETWEEN 1 AND 256),
  CONSTRAINT family_command_receipts_failure_pair
    CHECK (
      ((receipt_kind = 'failed') AND failure_reason IS NOT NULL)
      OR (receipt_kind <> 'failed' AND failure_reason IS NULL)
    )
);
