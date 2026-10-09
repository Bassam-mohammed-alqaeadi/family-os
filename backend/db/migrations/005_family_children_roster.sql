-- First durable, server-authorized roster record for Children Control Centre.
-- Device telemetry, location, policy enforcement and child account recovery are
-- intentionally outside this migration and must not be inferred from a child
-- profile row.

CREATE TABLE family_children (
  id UUID PRIMARY KEY,
  family_id UUID NOT NULL REFERENCES families(id) ON DELETE RESTRICT,
  display_name TEXT NOT NULL,
  age_years SMALLINT NOT NULL,
  version INTEGER NOT NULL DEFAULT 1 CHECK (version >= 1),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (char_length(btrim(display_name)) BETWEEN 1 AND 120),
  CHECK (age_years BETWEEN 0 AND 25),
  UNIQUE (family_id, id)
);

CREATE INDEX family_children_family_created_at
  ON family_children (family_id, created_at ASC, id ASC);
