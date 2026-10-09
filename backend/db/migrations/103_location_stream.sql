-- W3 Location stream — the trail a child's device reports, and the boundary
-- crossings a family is told about.
--
-- Two append-only tables, and the reasons each is shaped the way it is.
--
-- family_child_location_fixes is a TRAIL, not a latest value. Migration 007 already
-- holds one latest telemetry snapshot per device, and that row answers "where is the
-- handset now" cheaply. It cannot answer "when did she leave school", which is the
-- question geofencing and any honest arrival alert are built on. So a fix is
-- append-only: nothing updates it, nothing rewrites history, and the reader decides
-- how far back to look.
--
-- The honesty constraint is the important one. A fix claims one of four acquisition
-- states, and three of them must not carry coordinates:
--
--   located, stale_last_known -> coordinates required, in range
--   acquiring, unavailable    -> coordinates forbidden
--
-- That mirrors the client's own LocationFix.isHonest invariant exactly, and it is
-- enforced HERE as well, because the client is not the only thing that can write a
-- row and a dishonest fix is worse than no fix: it would place a child somewhere they
-- are not. `accuracy_meters` is stored because a fix without an accuracy is a claim
-- without a margin, and `integrity_soft_warning` is a soft signal for a guardian -
-- never a score, never a verdict, and never shown as proof of tampering.
--
-- Both clocks are kept. `recorded_at` is what the device says, `received_at` is what
-- the server saw. A device with a wrong clock is a real operational fact, and a schema
-- that stored only one of them would either trust the device or silently rewrite it.
--
-- family_geofence_events is what the family is told. One row per boundary crossing,
-- carrying the version of the zone shape as it stood at that moment: if the zone is
-- later widened, the arrival that already happened stays a fact about the old shape.
-- It references the exact fix that produced it, so a crossing can always be traced
-- back to the measurement rather than to a summary of one.
--
-- Neither table holds a policy decision. Whether to notify is decided by the zone's
-- own alert flags, in the same transaction, and the delivery itself travels through
-- the existing outbox rather than through a second queue invented here.

-- The device must belong to the child it reports for. With only the child-side
-- foreign key below, a fix could name the right child and the wrong family's device.
CREATE UNIQUE INDEX family_child_devices_family_child_id_unique
  ON family_child_devices (family_id, child_id, id);

CREATE TABLE family_child_location_fixes (
  id UUID PRIMARY KEY,
  family_id UUID NOT NULL REFERENCES families(id) ON DELETE RESTRICT,
  child_id UUID NOT NULL,
  device_id UUID NOT NULL,
  acquisition TEXT NOT NULL
    CHECK (acquisition IN ('located', 'stale_last_known', 'acquiring', 'unavailable')),
  location_lat DOUBLE PRECISION NULL,
  location_lng DOUBLE PRECISION NULL,
  accuracy_meters DOUBLE PRECISION NULL,
  integrity_soft_warning BOOLEAN NOT NULL DEFAULT FALSE,
  recorded_at TIMESTAMPTZ NOT NULL,
  received_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT family_child_location_fixes_device_in_family_child
    FOREIGN KEY (family_id, child_id, device_id)
    REFERENCES family_child_devices (family_id, child_id, id)
    ON DELETE RESTRICT,
  CONSTRAINT family_child_location_fixes_honest
    CHECK (
      (acquisition IN ('located', 'stale_last_known')
        AND location_lat IS NOT NULL
        AND location_lng IS NOT NULL
        AND location_lat BETWEEN -90 AND 90
        AND location_lng BETWEEN -180 AND 180)
      OR
      (acquisition IN ('acquiring', 'unavailable')
        AND location_lat IS NULL
        AND location_lng IS NULL)
    ),
  CONSTRAINT family_child_location_fixes_accuracy_valid
    CHECK (accuracy_meters IS NULL OR (accuracy_meters > 0 AND accuracy_meters <= 100000)),
  -- The server never claims to have received a fix before the device recorded it,
  -- beyond a clock allowance. A device reporting from the future is refused here.
  CONSTRAINT family_child_location_fixes_recorded_not_future
    CHECK (recorded_at <= received_at + INTERVAL '5 minutes'),
  -- The crossing is looked up by (family, zone, fix) and the trail by (family, child,
  -- time). Both are indexed; the retention prune walks (family, recorded_at).
  CONSTRAINT family_child_location_fixes_family_child_device_id_unique
    UNIQUE (family_id, child_id, device_id, id)
);

CREATE INDEX family_child_location_fixes_trail
  ON family_child_location_fixes (family_id, child_id, recorded_at DESC, id ASC);

CREATE INDEX family_child_location_fixes_device_recent
  ON family_child_location_fixes (family_id, device_id, recorded_at DESC);

CREATE TABLE family_geofence_events (
  id UUID PRIMARY KEY,
  family_id UUID NOT NULL REFERENCES families(id) ON DELETE RESTRICT,
  zone_id UUID NOT NULL,
  child_id UUID NOT NULL,
  device_id UUID NOT NULL,
  fix_id UUID NOT NULL,
  kind TEXT NOT NULL CHECK (kind IN ('ENTER', 'EXIT')),
  -- A BASELINE crossing is the first time this child was ever observed relative to this
  -- zone. It is kept because it is what makes the next EXIT a real crossing rather than a
  -- first sighting, and it is marked because no arrival may be announced for a movement
  -- nobody saw: "we have never looked before" is not "she just arrived".
  baseline BOOLEAN NOT NULL DEFAULT FALSE,
  zone_version INTEGER NOT NULL CHECK (zone_version >= 1),
  occurred_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT family_geofence_events_zone_in_family
    FOREIGN KEY (family_id, zone_id)
    REFERENCES family_safe_zones (family_id, id)
    ON DELETE RESTRICT,
  CONSTRAINT family_geofence_events_fix_is_real
    FOREIGN KEY (family_id, child_id, device_id, fix_id)
    REFERENCES family_child_location_fixes (family_id, child_id, device_id, id)
    ON DELETE RESTRICT,
  -- One crossing per zone per fix. This is what makes a replayed fix a no-op rather
  -- than a second arrival alert: the duplicate insert cannot even be attempted.
  CONSTRAINT family_geofence_events_one_per_fix UNIQUE (zone_id, fix_id)
);

CREATE INDEX family_geofence_events_family_recent
  ON family_geofence_events (family_id, occurred_at DESC, id ASC);

CREATE INDEX family_geofence_events_child_recent
  ON family_geofence_events (family_id, child_id, occurred_at DESC, id ASC);
