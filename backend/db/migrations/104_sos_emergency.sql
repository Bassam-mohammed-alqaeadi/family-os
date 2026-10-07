-- W4 SOS — the child's button, the escalation ladder it climbs, and the record of
-- what each recipient was actually told.
--
-- Three tables, and the honesty rule that shapes all of them.
--
-- family_sos_alerts is an INCIDENT, not a message. It has a raiser (the child's own
-- device, or a guardian pressing for a child), a press time stated by the device and a
-- receipt time stated by the server, and one terminal reason when it closes. The two
-- clocks are kept apart for the same reason migration 103 keeps them apart: a handset
-- with a wrong clock is an operational fact, and a schema that stored only one time would
-- either trust the device or silently rewrite it.
--
-- The picture captured at press time is stored on the incident rather than recomputed
-- later, because the only honest answer to "where was she when she pressed it" is the
-- answer that was true at that moment. It follows the same coordinate law as migration
-- 103: `ready` and `stale_last_known` carry a position and an accuracy; `acquiring` and
-- `unavailable` must not carry coordinates at all. An incident that claims a place it
-- does not have is the one defect an emergency surface cannot survive.
--
-- family_sos_alert_deliveries is what each recipient was told - and, more importantly,
-- what this platform can honestly claim it told them. There is no push transport and no
-- SMS transport in this repository. So a row may say:
--
--   recorded        a durable payload was written for a transport to pick up (in-app)
--   not_configured  there was nothing to send it on, and the row says so
--
-- and there is deliberately no `delivered` state, enforced by a CHECK rather than by a
-- convention. A guardian screen that says "sent" when nobody sent anything is worse than
-- a screen that says "not configured yet": the first one stops a parent from calling.
--
-- family_sos_backup_contacts is rung 2 of the ladder the family itself builds. Only a
-- VERIFIED contact ever escalates - the hard-skip law the client already enforces in
-- SosEscalationResolver - and `verification` is a column so the server can hold the same
-- line the client does instead of trusting the client to have held it.
--
-- Nothing here is child-located by a third party: an active member of the family may read
-- the incident the family is in, including the child it is about. Selective visibility on
-- an emergency is how a platform stops being a family's platform.

CREATE TABLE family_sos_backup_contacts (
  id UUID PRIMARY KEY,
  family_id UUID NOT NULL REFERENCES families(id) ON DELETE RESTRICT,
  name TEXT NOT NULL,
  relation TEXT NOT NULL DEFAULT '',
  phone_e164 TEXT NOT NULL,
  verification TEXT NOT NULL DEFAULT 'unverified'
    CHECK (verification IN ('unverified', 'verified', 'revoked')),
  enabled BOOLEAN NOT NULL DEFAULT TRUE,
  priority INTEGER NOT NULL DEFAULT 1 CHECK (priority BETWEEN 1 AND 20),
  created_by_membership_id UUID NOT NULL REFERENCES family_memberships(id) ON DELETE RESTRICT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  archived_at TIMESTAMPTZ NULL,
  CONSTRAINT family_sos_backup_contacts_name_valid
    CHECK (char_length(btrim(name)) BETWEEN 1 AND 80),
  CONSTRAINT family_sos_backup_contacts_relation_valid
    CHECK (char_length(btrim(relation)) <= 40),
  CONSTRAINT family_sos_backup_contacts_phone_valid
    CHECK (phone_e164 ~ '^\+[1-9][0-9]{7,14}$'),
  CONSTRAINT family_sos_backup_contacts_family_id_id_unique UNIQUE (family_id, id)
);

-- One live row per phone per family. Archived rows keep their history; a phone number
-- that was once on the ladder and was removed is a fact worth keeping, not a duplicate.
CREATE UNIQUE INDEX family_sos_backup_contacts_phone_once
  ON family_sos_backup_contacts (family_id, phone_e164)
  WHERE archived_at IS NULL;

CREATE INDEX family_sos_backup_contacts_ladder
  ON family_sos_backup_contacts (family_id, priority ASC, created_at ASC)
  WHERE archived_at IS NULL;

CREATE TABLE family_sos_alerts (
  id UUID PRIMARY KEY,
  family_id UUID NOT NULL REFERENCES families(id) ON DELETE RESTRICT,
  child_id UUID NOT NULL,
  raised_by_kind TEXT NOT NULL CHECK (raised_by_kind IN ('child_device', 'guardian')),
  raised_by_membership_id UUID NULL REFERENCES family_memberships(id) ON DELETE RESTRICT,
  pressed_at TIMESTAMPTZ NOT NULL,
  received_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  status TEXT NOT NULL DEFAULT 'active'
    CHECK (status IN ('active', 'acknowledged', 'escalating', 'resolved')),
  location_class TEXT NOT NULL
    CHECK (location_class IN ('ready', 'acquiring', 'stale_last_known', 'unavailable')),
  latitude DOUBLE PRECISION NULL CHECK (latitude BETWEEN -90 AND 90),
  longitude DOUBLE PRECISION NULL CHECK (longitude BETWEEN -180 AND 180),
  accuracy_meters INTEGER NULL CHECK (accuracy_meters > 0),
  connection_class TEXT NOT NULL
    CHECK (connection_class IN ('online', 'degraded', 'offline')),
  battery_percent INTEGER NULL CHECK (battery_percent BETWEEN 0 AND 100),
  place_label TEXT NULL,
  panic_quiet BOOLEAN NOT NULL DEFAULT FALSE,
  -- The sample that was the child's last known position when the button was pressed.
  -- The reference is by primary key and the operation checks that the fix belongs to this
  -- same child before it is stored; a deliberate narrower FK than the crossing table's,
  -- because an incident is not always raised by a device (a guardian may press for a
  -- child whose handset is in someone else's hand) and a nullable device column would
  -- have implied otherwise.
  fix_id UUID NULL REFERENCES family_child_location_fixes(id) ON DELETE RESTRICT,
  acknowledged_at TIMESTAMPTZ NULL,
  acknowledged_by_membership_id UUID NULL REFERENCES family_memberships(id) ON DELETE RESTRICT,
  escalated_at TIMESTAMPTZ NULL,
  escalated_by_membership_id UUID NULL REFERENCES family_memberships(id) ON DELETE RESTRICT,
  resolved_at TIMESTAMPTZ NULL,
  resolved_by_membership_id UUID NULL REFERENCES family_memberships(id) ON DELETE RESTRICT,
  -- An incident can also be closed by the handset that raised it, and only as a false
  -- alarm. The closer is named as well as witnessed: "closed" without a who is the kind of
  -- record that answers nothing afterwards. Exactly one of the two columns is filled.
  resolved_by_device_id UUID NULL REFERENCES family_child_devices(id) ON DELETE RESTRICT,
  terminal_reason TEXT NULL CHECK (terminal_reason IN ('helped', 'false_alarm', 'other')),
  version INTEGER NOT NULL DEFAULT 1 CHECK (version >= 1),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT family_sos_alerts_child_in_family
    FOREIGN KEY (family_id, child_id)
    REFERENCES family_children (family_id, id)
    ON DELETE RESTRICT,
  CONSTRAINT family_sos_alerts_family_id_id_unique UNIQUE (family_id, id),
  CONSTRAINT family_sos_alerts_raiser_paired
    CHECK ((raised_by_kind = 'guardian') = (raised_by_membership_id IS NOT NULL)),
  CONSTRAINT family_sos_alerts_place_label_valid
    CHECK (place_label IS NULL OR char_length(btrim(place_label)) BETWEEN 1 AND 120),
  -- The position law, stated where a writer cannot argue with it: a press that carries a
  -- place carries an accuracy too, and a press that has no place carries no coordinates.
  CONSTRAINT family_sos_alerts_position_honest
    CHECK (
      (location_class IN ('ready', 'stale_last_known'))
        = (latitude IS NOT NULL AND longitude IS NOT NULL)
    ),
  CONSTRAINT family_sos_alerts_accuracy_with_position
    CHECK (latitude IS NULL OR accuracy_meters IS NOT NULL),
  CONSTRAINT family_sos_alerts_closure_complete
    CHECK ((status = 'resolved') = (resolved_at IS NOT NULL AND terminal_reason IS NOT NULL)),
  CONSTRAINT family_sos_alerts_acknowledgement_paired
    CHECK ((acknowledged_at IS NULL) = (acknowledged_by_membership_id IS NULL)),
  CONSTRAINT family_sos_alerts_escalation_paired
    CHECK ((escalated_at IS NULL) = (escalated_by_membership_id IS NULL)),
  CONSTRAINT family_sos_alerts_resolution_paired
    CHECK (
      (resolved_at IS NULL)
        = (resolved_by_membership_id IS NULL AND resolved_by_device_id IS NULL)
    ),
  CONSTRAINT family_sos_alerts_resolution_single_closer
    CHECK (
      NOT (resolved_by_membership_id IS NOT NULL AND resolved_by_device_id IS NOT NULL)
    ),
  -- A press time the server has not reached yet is a device clock problem, not an
  -- emergency. The allowance covers real skew without letting a device date an incident
  -- to a moment that has not happened.
  CONSTRAINT family_sos_alerts_press_time_sane
    CHECK (pressed_at <= received_at + INTERVAL '5 minutes')
);

-- A child has at most one incident in flight. Two open alerts for the same child would
-- split the family's attention across two screens and two ladders - precisely when
-- undivided attention is the product.
CREATE UNIQUE INDEX family_sos_alerts_one_open_per_child
  ON family_sos_alerts (child_id)
  WHERE status <> 'resolved';

CREATE INDEX family_sos_alerts_family_feed
  ON family_sos_alerts (family_id, pressed_at DESC, id DESC);

CREATE INDEX family_sos_alerts_open
  ON family_sos_alerts (family_id, status, pressed_at ASC)
  WHERE status <> 'resolved';

CREATE TABLE family_sos_alert_deliveries (
  id UUID PRIMARY KEY,
  alert_id UUID NOT NULL,
  family_id UUID NOT NULL REFERENCES families(id) ON DELETE RESTRICT,
  recipient_kind TEXT NOT NULL CHECK (recipient_kind IN ('guardian', 'backup')),
  recipient_membership_id UUID NULL REFERENCES family_memberships(id) ON DELETE RESTRICT,
  recipient_contact_id UUID NULL,
  channel TEXT NOT NULL CHECK (channel IN ('in_app', 'push', 'sms', 'call')),
  delivery_state TEXT NOT NULL CHECK (delivery_state IN ('recorded', 'not_configured')),
  reason_code TEXT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT family_sos_alert_deliveries_alert_in_family
    FOREIGN KEY (family_id, alert_id)
    REFERENCES family_sos_alerts (family_id, id)
    ON DELETE CASCADE,
  CONSTRAINT family_sos_alert_deliveries_contact_in_family
    FOREIGN KEY (family_id, recipient_contact_id)
    REFERENCES family_sos_backup_contacts (family_id, id)
    ON DELETE RESTRICT,
  CONSTRAINT family_sos_alert_deliveries_recipient_exactly_one
    CHECK (
      (recipient_kind = 'guardian'
        AND recipient_membership_id IS NOT NULL
        AND recipient_contact_id IS NULL)
      OR (recipient_kind = 'backup'
        AND recipient_contact_id IS NOT NULL
        AND recipient_membership_id IS NULL)
    ),
  CONSTRAINT family_sos_alert_deliveries_reason_paired
    CHECK ((delivery_state = 'not_configured') = (reason_code IS NOT NULL))
);

-- Escalating twice adds nothing: the second attempt finds the first rows and stops there.
CREATE UNIQUE INDEX family_sos_alert_deliveries_once
  ON family_sos_alert_deliveries (
    alert_id,
    channel,
    COALESCE(recipient_membership_id, recipient_contact_id)
  );

CREATE INDEX family_sos_alert_deliveries_feed
  ON family_sos_alert_deliveries (alert_id, created_at ASC, id ASC);
