-- M1 Device lifecycle — revocation provenance.
--
-- Migration 008 made a device credential revocable, and the telemetry path already
-- refuses a revoked credential with 401 invalid_device_credential. What was
-- missing was any way to SET that revocation: a lost or stolen handset stayed
-- trusted forever, because no operation could cut it off. The lock existed; the
-- key did not. This migration supplies the record that operation needs.
--
-- Capability and health are deliberately NOT stored here. They are derived from
-- the credential state and the latest telemetry by backend/src/device-lifecycle.js,
-- because a stored copy of a derived fact is a second version of the truth waiting
-- to disagree with the first.

ALTER TABLE family_child_devices
  ADD COLUMN revoked_by_membership_id UUID NULL
    REFERENCES family_memberships(id) ON DELETE RESTRICT,
  ADD COLUMN revocation_reason TEXT NULL;

-- Provenance travels with the revocation or not at all. A credential that was cut
-- off without recording which guardian did it is not auditable, and a guardian
-- recorded against a live credential would claim an action that never happened.
ALTER TABLE family_child_devices
  ADD CONSTRAINT family_child_devices_revocation_provenance_valid
    CHECK (
      (credential_revoked_at IS NULL
        AND revoked_by_membership_id IS NULL
        AND revocation_reason IS NULL)
      OR
      (credential_revoked_at IS NOT NULL
        AND revoked_by_membership_id IS NOT NULL)
    );

-- The reason is a closed vocabulary rather than free text: it stays reportable,
-- translatable and safe to render. It is also OPTIONAL on purpose. Cutting off a
-- stolen handset is urgent, and a guardian who must first classify the loss is a
-- guardian who hesitates; the audit minimum is who and when, both of which are
-- already required above.
--
-- The set is chosen for the repair journey: 'replaced' and 'no_longer_used' mean a
-- new pairing is the natural next step, while 'lost' and 'stolen' mean the family
-- should be told the device may still be in someone else's hands.
ALTER TABLE family_child_devices
  ADD CONSTRAINT family_child_devices_revocation_reason_valid
    CHECK (
      revocation_reason IS NULL
      OR revocation_reason IN (
        'lost',
        'stolen',
        'replaced',
        'no_longer_used',
        'other'
      )
    );

-- Revoked devices are the exception, not the rule, and they are read by family
-- when a guardian reviews what has been cut off. A partial index keeps that read
-- cheap without taxing the common path, which never asks about revocation.
CREATE INDEX family_child_devices_revoked_family
  ON family_child_devices (family_id, credential_revoked_at DESC)
  WHERE credential_revoked_at IS NOT NULL;
