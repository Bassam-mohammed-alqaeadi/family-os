-- Safety slice 3 — retention at the owner's 90 days, and deletion that actually deletes.
--
-- Owner decision (2026-10-10, RESUME.md §3.4): the location trail is kept 90 days.
-- The constant lives in backend/src/location-telemetry.js; what was missing here is the
-- index the prune actually walks. Migration 103 says in its own comment that "the
-- retention prune walks (family, recorded_at)", but shipped only (family, child, time)
-- and (family, device, time) indexes — a per-family prune could not use either without
-- scanning every child's segment. A retention rule whose enforcement path is a sequential
-- scan is a rule that quietly stops being enforced as the trail grows, so the index the
-- comment promised is created here, before the window it serves triples to 90 days.
--
-- The second fact this migration adds is child archival. "Deleting a child" from a family
-- is not a row deletion: the child's id is referenced by the safety record (crossings,
-- incidents), by the consent ledger (compliance evidence that must outlive the profile),
-- and by devices with their own revocation provenance. Hard-deleting the profile would
-- either cascade away records the family is entitled to keep or fail on the first foreign
-- key. So removal ARCHIVES the profile — the same pattern the product already uses for
-- safe zones ("archive + create") and SOS backup contacts ("archived rows keep their
-- history") — while the location data itself is REALLY deleted by the erasure operation
-- in backend/src/data-erasure.js, in one transaction with the archival.
--
-- Archival carries provenance for the same reason revocation does (migration 101):
-- who removed the child, and when, or the removal is not auditable.

-- The index the retention prune promised in migration 103 and never had.
CREATE INDEX family_child_location_fixes_retention
  ON family_child_location_fixes (family_id, recorded_at);

-- Migration 007 required the device's latest-telemetry snapshot to be ALL-or-nothing:
-- battery, location and last_seen either all present or all absent. That law made
-- erasure impossible to express: emptying `location_*` on a device that had reported
-- would violate the constraint unless the erasure also lied about the battery and the
-- last report. Since slice 3, "reported, and its position was erased" is a legitimate
-- state — the lifecycle module already reads a null position honestly ("a device can
-- be reporting right now and still have withheld location"). The law is narrowed to
-- what it was really protecting: no telemetry may exist before the first report.
-- The battery pair (level ⇔ status) and the coordinate pair (both or neither) keep
-- their own constraints from migration 007, unchanged.
ALTER TABLE family_child_devices
  DROP CONSTRAINT family_child_devices_latest_telemetry_complete;

ALTER TABLE family_child_devices
  ADD CONSTRAINT family_child_devices_telemetry_requires_report
    CHECK (
      last_seen_at IS NOT NULL
      OR (
        battery_level IS NULL
        AND battery_status IS NULL
        AND location_lat IS NULL
        AND location_lng IS NULL
        AND location_label IS NULL
      )
    );

ALTER TABLE family_children
  ADD COLUMN archived_at TIMESTAMPTZ NULL,
  ADD COLUMN archived_by_membership_id UUID NULL
    REFERENCES family_memberships(id) ON DELETE RESTRICT;

-- Provenance travels with the archival or not at all — the same law migration 101 wrote
-- for revocation. A child removed without recording which guardian did it is not
-- auditable, and a guardian recorded against an active profile would claim a removal
-- that never happened.
ALTER TABLE family_children
  ADD CONSTRAINT family_children_archival_provenance_valid
    CHECK (
      (archived_at IS NULL AND archived_by_membership_id IS NULL)
      OR
      (archived_at IS NOT NULL AND archived_by_membership_id IS NOT NULL)
    );

-- The roster read is the common path and it never asks for archived children: every
-- surface that lists or checks a child now filters `archived_at IS NULL`. A partial
-- index keeps that read cheap without taxing the archival record it must still allow
-- to exist.
CREATE INDEX family_children_family_active
  ON family_children (family_id, created_at ASC, id ASC)
  WHERE archived_at IS NULL;
