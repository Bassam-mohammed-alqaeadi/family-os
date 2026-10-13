-- Safety slice S1 (notifications) — push registrations grow a device identity.
--
-- Until now a push registration named a guardian's membership only (migration 113): the
-- child's handset — the one whose battery, arrival and SOS a guardian most needs to hear
-- about — could register nothing, because it is a paired device with no membership.
--
-- The decision (master plan §س١, delivery item 1): extend the existing table with a
-- nullable `device_id` rather than fork a second registrations table. One carrier, one
-- token index, one delivery path. A registration names exactly ONE owner: either a
-- guardian membership or a child device — never both, never neither. The token still
-- names the handset: re-registering a token moves it to the owner that presented it
-- last, exactly as before.
--
-- Delete semantics differ by owner on purpose, and both are truthful:
--   * membership-owned rows RESTRICT on membership deletion (existing law, unchanged);
--   * device-owned rows CASCADE when the device row is erased — a registration exists
--     only to reach that handset, and child removal (slice ش٣) erases the device rows,
--     so nothing may outlive the handset it points at. Capability rows (migration 117)
--     already use CASCADE for the same reason.
--
-- Additive except for the NOT NULL relaxation that the XOR law requires.

ALTER TABLE family_push_registrations
  ADD COLUMN device_id UUID NULL;

-- Existing rows are all membership-owned; the XOR check below becomes satisfiable the
-- moment this NOT NULL goes away.
ALTER TABLE family_push_registrations
  ALTER COLUMN membership_id DROP NOT NULL;

ALTER TABLE family_push_registrations
  ADD CONSTRAINT family_push_registrations_owner_xor CHECK (
    (membership_id IS NOT NULL AND device_id IS NULL)
    OR (membership_id IS NULL AND device_id IS NOT NULL)
  );

ALTER TABLE family_push_registrations
  ADD CONSTRAINT family_push_registrations_device_fk
  FOREIGN KEY (family_id, device_id)
  REFERENCES family_child_devices (family_id, id)
  ON DELETE CASCADE;

CREATE INDEX family_push_registrations_device_idx
  ON family_push_registrations (device_id)
  WHERE device_id IS NOT NULL;
