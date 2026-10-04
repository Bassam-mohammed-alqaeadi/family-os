-- Phase 1 Device Telemetry & Nervous System.
-- A linked device is a durable family-scoped record. This migration stores only
-- its latest authorized telemetry; it does not claim background GPS collection,
-- device attestation, or a historical location trail.

CREATE TABLE family_child_devices (
  id UUID PRIMARY KEY,
  family_id UUID NOT NULL REFERENCES families(id) ON DELETE RESTRICT,
  child_id UUID NOT NULL,
  device_label TEXT NOT NULL,
  battery_level SMALLINT NULL,
  battery_status TEXT NULL,
  location_lat DOUBLE PRECISION NULL,
  location_lng DOUBLE PRECISION NULL,
  location_label TEXT NULL,
  last_seen_at TIMESTAMPTZ NULL,
  version INTEGER NOT NULL DEFAULT 1 CHECK (version >= 1),
  linked_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT family_child_devices_child_scope
    FOREIGN KEY (family_id, child_id)
    REFERENCES family_children (family_id, id)
    ON DELETE RESTRICT,
  CONSTRAINT family_child_devices_label_valid
    CHECK (char_length(btrim(device_label)) BETWEEN 1 AND 80),
  CONSTRAINT family_child_devices_battery_level_valid
    CHECK (battery_level IS NULL OR battery_level BETWEEN 0 AND 100),
  CONSTRAINT family_child_devices_battery_status_valid
    CHECK (battery_status IS NULL OR battery_status IN ('charging', 'unplugged')),
  CONSTRAINT family_child_devices_battery_pair_valid
    CHECK ((battery_level IS NULL) = (battery_status IS NULL)),
  CONSTRAINT family_child_devices_location_coordinates_valid
    CHECK (
      (location_lat IS NULL AND location_lng IS NULL)
      OR (location_lat BETWEEN -90 AND 90 AND location_lng BETWEEN -180 AND 180)
    ),
  CONSTRAINT family_child_devices_location_label_valid
    CHECK (location_label IS NULL OR char_length(btrim(location_label)) BETWEEN 1 AND 160),
  CONSTRAINT family_child_devices_latest_telemetry_complete
    CHECK (
      (last_seen_at IS NULL
        AND battery_level IS NULL
        AND battery_status IS NULL
        AND location_lat IS NULL
        AND location_lng IS NULL
        AND location_label IS NULL)
      OR
      (last_seen_at IS NOT NULL
        AND battery_level IS NOT NULL
        AND battery_status IS NOT NULL
        AND location_lat IS NOT NULL
        AND location_lng IS NOT NULL
        AND location_label IS NOT NULL)
    )
);

CREATE INDEX family_child_devices_family_last_seen
  ON family_child_devices (family_id, last_seen_at DESC NULLS LAST, id ASC);

CREATE INDEX family_child_devices_child_last_seen
  ON family_child_devices (family_id, child_id, last_seen_at DESC NULLS LAST, id ASC);
