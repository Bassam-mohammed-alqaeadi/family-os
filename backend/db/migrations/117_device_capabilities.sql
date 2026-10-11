-- Safety slice S0 (spine) — the device-capability ledger.
--
-- Principle 2 ("capability is data"): every control in the UI is evaluated against a
-- stored, current capability record, never guessed from the screen. A handset tells the
-- server what it can honestly do right now; the server never infers capability from a
-- toggle state or a permission dialog that may have been dismissed.
--
-- The CHECK constraint lists the universe of capability keys that may ever be reported
-- (one row per key per device). S0 seeds only the keys the next two slices consume
-- (background_location, instant_lock, push_delivery); other keys are added by their slice
-- when the handset actually starts reporting them.
--
-- `evidence` is free-text the device supplies (its own words); it MUST NOT contain
-- coordinates or message content. That rule is enforced by the surface, not by a length
-- check here — the column is sized for short honest statements like "permission_denied",
-- "vpn_not_prepared", "usage_stats_not_granted".

CREATE TABLE family_device_capabilities (
  device_id UUID NOT NULL
    REFERENCES family_child_devices(id) ON DELETE CASCADE,
  family_id UUID NOT NULL,
  capability_key TEXT NOT NULL CHECK (capability_key IN (
    'usage_metering',
    'app_inventory',
    'app_block_overlay',
    'accessibility_enforcement',
    'instant_lock',
    'web_filter_vpn',
    'background_location',
    'boot_persistence',
    'push_delivery',
    'battery_reporting',
    'tamper_signals'
  )),
  state TEXT NOT NULL CHECK (state IN (
    'confirmed',
    'awaiting_setup',
    'permission_needed',
    'unsupported',
    'revoked',
    'unknown'
  )),
  evidence TEXT NULL
    CHECK (evidence IS NULL OR char_length(btrim(evidence)) BETWEEN 1 AND 512),
  app_version TEXT NULL
    CHECK (app_version IS NULL OR char_length(btrim(app_version)) BETWEEN 1 AND 64),
  os_version TEXT NULL
    CHECK (os_version IS NULL OR char_length(btrim(os_version)) BETWEEN 1 AND 64),
  confirmed_at TIMESTAMPTZ NULL,
  reported_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (device_id, capability_key),
  CONSTRAINT family_device_capabilities_family_scope
    FOREIGN KEY (family_id, device_id)
    REFERENCES family_child_devices (family_id, id)
    ON DELETE CASCADE,
  -- Confirmed capabilities carry a confirmation timestamp; everything else does not.
  -- Writing confirmed_at on an 'unsupported' row would be a lie.
  CONSTRAINT family_device_capabilities_confirmed_pair
    CHECK (
      (state = 'confirmed' AND confirmed_at IS NOT NULL)
      OR (state <> 'confirmed' AND confirmed_at IS NULL)
    )
);

-- Family + child lookups (the guardian reads by family/child in the capabilities view).
CREATE INDEX family_device_capabilities_family_child_idx
  ON family_device_capabilities (family_id, device_id, capability_key);
