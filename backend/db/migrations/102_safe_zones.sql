-- W3 Safe Zones — the definitions a family draws around places that matter.
--
-- Two facts this migration deliberately keeps apart:
--
--   1. A ZONE is a definition: a name, a shape, the children it is assigned to, and
--      which transitions are worth telling anyone about. It has a version because a
--      geofence is evaluated against the shape as it stood at that moment: if a family
--      widens a zone, an arrived-child should not be reported as having just arrived.
--
--   2. An ASSIGNMENT is a decision about a person, and it is stored as its own row
--      rather than as an array inside the zone. "Which zones is Amani in?" and "who is
--      in this zone?" are both real questions, and only one of them is cheap when the
--      children live in a JSON column.
--
-- Shape is CIRCLE or POLYGON, both first-class, matching the client's own geometry
-- model (LOC-OD-11). Coordinates are stored as plain DOUBLE PRECISION in a
-- non-spatial schema: the product needs "is this point inside this shape", which
-- ray-casting and a Haversine comparison answer exactly for the zone sizes a family
-- actually draws. PostGIS is not required for that, and a spatial extension would be
-- a deployment dependency this wave does not need to buy.
--
-- Coordinate RANGES are validated by the server and by the client before they reach
-- this table; the constraints here enforce what a CHECK can see without a subquery,
-- which is the shape's completeness and the vertex count. A latitude of 500 is
-- refused by the operation and by the client's own parser, and the column comment
-- says so rather than implying the database caught it.
--
-- Nothing in this table is child-located. A zone is where a place is, not where a
-- person is, and it is readable by every active member of the family: a child living
-- inside a boundary is entitled to know the boundary exists.

CREATE TABLE family_safe_zones (
  id UUID PRIMARY KEY,
  family_id UUID NOT NULL REFERENCES families(id) ON DELETE RESTRICT,
  name TEXT NOT NULL,
  emoji TEXT NOT NULL DEFAULT '📍',
  geometry_kind TEXT NOT NULL CHECK (geometry_kind IN ('CIRCLE', 'POLYGON')),
  center_lat DOUBLE PRECISION NULL,
  center_lng DOUBLE PRECISION NULL,
  radius_meters DOUBLE PRECISION NULL,
  vertices JSONB NULL,
  alert_enter BOOLEAN NOT NULL DEFAULT TRUE,
  alert_exit BOOLEAN NOT NULL DEFAULT TRUE,
  version INTEGER NOT NULL DEFAULT 1 CHECK (version >= 1),
  created_by_membership_id UUID NOT NULL REFERENCES family_memberships(id) ON DELETE RESTRICT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  archived_at TIMESTAMPTZ NULL,
  CONSTRAINT family_safe_zones_name_valid
    CHECK (char_length(btrim(name)) BETWEEN 1 AND 80),
  CONSTRAINT family_safe_zones_emoji_valid
    CHECK (char_length(emoji) BETWEEN 1 AND 16),
  CONSTRAINT family_safe_zones_geometry_complete
    CHECK (
      (geometry_kind = 'CIRCLE'
        AND center_lat IS NOT NULL
        AND center_lng IS NOT NULL
        AND radius_meters IS NOT NULL
        AND vertices IS NULL)
      OR
      (geometry_kind = 'POLYGON'
        AND vertices IS NOT NULL
        AND jsonb_typeof(vertices) = 'array'
        AND jsonb_array_length(vertices) BETWEEN 3 AND 64
        AND center_lat IS NULL
        AND center_lng IS NULL
        AND radius_meters IS NULL)
    ),
  CONSTRAINT family_safe_zones_circle_values_valid
    CHECK (
      center_lat IS NULL
      OR (center_lat BETWEEN -90 AND 90
        AND center_lng BETWEEN -180 AND 180
        AND radius_meters > 0
        AND radius_meters <= 50000)
    ),
  -- Archiving is the only way a zone leaves service. A zone that is archived is not
  -- evaluated any more, and a zone that is edited after archiving is a zone that was
  -- resurrected by accident rather than by decision.
  CONSTRAINT family_safe_zones_archived_is_final
    CHECK (archived_at IS NULL OR updated_at >= created_at),
  -- The composite key exists so an assignment cannot pair this zone with a DIFFERENT
  -- family's child. With only the child-side foreign key, a row here could name the
  -- right child under the wrong family and every constraint would still be happy.
  CONSTRAINT family_safe_zones_family_id_id_unique UNIQUE (family_id, id)
);

CREATE INDEX family_safe_zones_family_active
  ON family_safe_zones (family_id, created_at ASC, id ASC)
  WHERE archived_at IS NULL;

-- Which children a zone is for. Explicit, and never empty on save: a zone assigned to
-- nobody reads like protection and evaluates like nothing at all.
CREATE TABLE family_safe_zone_children (
  zone_id UUID NOT NULL REFERENCES family_safe_zones(id) ON DELETE CASCADE,
  family_id UUID NOT NULL REFERENCES families(id) ON DELETE RESTRICT,
  child_id UUID NOT NULL,
  assigned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (zone_id, child_id),
  CONSTRAINT family_safe_zone_children_child_in_family
    FOREIGN KEY (family_id, child_id)
    REFERENCES family_children (family_id, id)
    ON DELETE RESTRICT,
  CONSTRAINT family_safe_zone_children_zone_in_family
    FOREIGN KEY (family_id, zone_id)
    REFERENCES family_safe_zones (family_id, id)
    ON DELETE CASCADE
);

CREATE INDEX family_safe_zone_children_child
  ON family_safe_zone_children (family_id, child_id);
