-- 009: Pairing codes become 6-digit numeric (human readable/typeable).
--
-- A 6-digit space (1,000,000 values) cannot keep a *global* unique hash index:
-- claimed and expired rows would permanently consume values. Uniqueness is now
-- enforced only among unclaimed pairings; createDevicePairing purges expired
-- unclaimed rows and re-draws on an active collision. Claimed rows keep their
-- hash for audit continuity.
DROP INDEX IF EXISTS family_device_pairings_code_hash_unique;

CREATE UNIQUE INDEX family_device_pairings_code_hash_unclaimed_unique
  ON family_device_pairings (pairing_code_hash)
  WHERE claimed_at IS NULL;
