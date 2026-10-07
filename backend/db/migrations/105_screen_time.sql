-- W5 SCREEN TIME — the minutes a child has, the apps those minutes belong to, the
-- requests the family answers, and the one honest answer to "may this phone be used
-- right now".
--
-- Six tables, and one decision that shapes all of them: **the state is computed, never
-- stored.** Bedtime, school mode and the daily cap are all derived from the policy, the
-- usage rows and the clock at the moment someone asks. Storing "blocked because bedtime"
-- as a column would create a second version of the truth that goes stale the moment the
-- clock moves past the window - the same defect migration 103 avoided by deriving
-- "inside" from the last crossing instead of keeping an `inside` flag.
--
-- What is stored is what somebody stated, never what the server concluded: the family's
-- policy, their rules about apps, the inventory the handset reported, the minutes it
-- measured, and the two things that are decisions rather than measurements:
--
--   * family_child_lock_state is an instant lock: a guardian said "this phone is off
--     now", and that is an event with an author, a reason and a release. One live lock
--     per child, enforced by a partial unique index rather than by a check that races.
--
--   * family_child_time_requests is a question and its answer: the child asked for more
--     minutes, a guardian decided, and the granted minutes belong to a stated day. A
--     request nobody answers EXPIRES - `expires_at` is NOT NULL, because a screen that
--     shows "waiting for a parent" three days later is a screen that lies.
--
-- family_child_app_usage_daily stores a cumulative daily figure per app, and the write
-- keeps the GREATEST of what is stored and what arrived: a retry, a replay or a handset
-- that reconnects after a day underground can never reduce or inflate the number a family
-- is looking at. Minutes are minutes; there is no "estimated".
--
-- App rules are the family's own vocabulary, and the schema refuses the combinations that
-- would make a screen say something nobody meant:
--
--   allowed   counted against the entertainment cap; may carry a per-app limit
--   free      not counted at all (a limit on it would be meaningless, so it is refused)
--   blocked   not usable, whatever the cap says
--   pending   seen on the handset, no decision yet - which is why the child sees a
--             question instead of a silent block
--
-- Education is a CATEGORY, not a status: the handset reports it, and migration and server
-- agree that an `edu` app is not entertainment - so it costs no minutes under the cap, and
-- a bedtime or a school morning leaves it working while it stops the games. The one thing
-- that stops it is the instant lock, because that is what a lock is. An app the family
-- marked `free` behaves the same way for the same reason: neither one is entertainment.

CREATE TABLE family_child_screen_time_policies (
  child_id UUID PRIMARY KEY,
  family_id UUID NOT NULL REFERENCES families(id) ON DELETE RESTRICT,
  -- 0 means the family set no daily cap. It is a number rather than NULL so a screen never
  -- has to distinguish "unset" from "unlimited": the product's answer to both is the same,
  -- and two ways to say one thing is how a client ends up disagreeing with a server.
  daily_limit_minutes INTEGER NOT NULL DEFAULT 0
    CHECK (daily_limit_minutes BETWEEN 0 AND 1440),
  school_mode_enabled BOOLEAN NOT NULL DEFAULT FALSE,
  -- ISO-8601 weekday numbers, 1 = Monday ... 7 = Sunday. The Yemeni school week is the
  -- default, and a family elsewhere changes data rather than code.
  school_days SMALLINT[] NOT NULL DEFAULT ARRAY[7, 1, 2, 3, 4]::SMALLINT[],
  school_start_minute SMALLINT NOT NULL DEFAULT 420 CHECK (school_start_minute BETWEEN 0 AND 1439),
  school_end_minute SMALLINT NOT NULL DEFAULT 840 CHECK (school_end_minute BETWEEN 0 AND 1439),
  bedtime_start_minute SMALLINT NOT NULL DEFAULT 1260
    CHECK (bedtime_start_minute BETWEEN 0 AND 1439),
  bedtime_end_minute SMALLINT NOT NULL DEFAULT 360
    CHECK (bedtime_end_minute BETWEEN 0 AND 1439),
  -- The family's own clock, in minutes east of UTC. Sanaa is +180, and it is stored rather
  -- than assumed because a window evaluated in the server's timezone would lock a child's
  -- phone at the wrong hour of their day - which is the only thing a parent would notice.
  timezone_offset_minutes SMALLINT NOT NULL DEFAULT 180
    CHECK (timezone_offset_minutes BETWEEN -720 AND 840),
  version INTEGER NOT NULL DEFAULT 1 CHECK (version >= 1),
  updated_by_membership_id UUID NULL REFERENCES family_memberships(id) ON DELETE RESTRICT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT family_child_screen_time_policies_child_in_family
    FOREIGN KEY (family_id, child_id)
    REFERENCES family_children (family_id, id)
    ON DELETE RESTRICT,
  -- A window whose ends are the same minute is not a window. Either the mode is off or it
  -- spans real time; a zero-length window would silently mean "never" while looking like
  -- "always" to whoever wrote it.
  CONSTRAINT family_child_screen_time_policies_school_window_real
    CHECK (NOT school_mode_enabled OR school_start_minute <> school_end_minute),
  CONSTRAINT family_child_screen_time_policies_bedtime_window_real
    CHECK (bedtime_start_minute <> bedtime_end_minute),
  CONSTRAINT family_child_screen_time_policies_school_days_valid
    CHECK (school_days <@ ARRAY[1, 2, 3, 4, 5, 6, 7]::SMALLINT[]),
  CONSTRAINT family_child_screen_time_policies_school_days_present
    CHECK (NOT school_mode_enabled OR array_length(school_days, 1) IS NOT NULL)
);

CREATE TABLE family_child_app_rules (
  id UUID PRIMARY KEY,
  family_id UUID NOT NULL REFERENCES families(id) ON DELETE RESTRICT,
  child_id UUID NOT NULL,
  app_id TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('allowed', 'free', 'blocked', 'pending')),
  limit_minutes INTEGER NULL CHECK (limit_minutes BETWEEN 1 AND 1440),
  unlimited BOOLEAN NOT NULL DEFAULT FALSE,
  version INTEGER NOT NULL DEFAULT 1 CHECK (version >= 1),
  updated_by_membership_id UUID NOT NULL REFERENCES family_memberships(id) ON DELETE RESTRICT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT family_child_app_rules_child_in_family
    FOREIGN KEY (family_id, child_id)
    REFERENCES family_children (family_id, id)
    ON DELETE RESTRICT,
  CONSTRAINT family_child_app_rules_family_id_id_unique UNIQUE (family_id, id),
  CONSTRAINT family_child_app_rules_one_per_app UNIQUE (child_id, app_id),
  CONSTRAINT family_child_app_rules_app_id_valid
    CHECK (char_length(btrim(app_id)) BETWEEN 1 AND 120),
  -- A limit belongs to a countable app. On `free` it would never be read, on `blocked` it
  -- would be read and ignored: both are screens that promise something the server does not
  -- do, so the row cannot exist.
  CONSTRAINT family_child_app_rules_limit_only_when_countable
    CHECK (status = 'allowed' OR limit_minutes IS NULL),
  CONSTRAINT family_child_app_rules_unlimited_only_when_countable
    CHECK (status = 'allowed' OR unlimited = FALSE)
);

CREATE INDEX family_child_app_rules_family_child
  ON family_child_app_rules (child_id, status, app_id);

-- The inventory the handset reported: what is actually installed, as opposed to what the
-- family has an opinion about. Keeping the two apart is what lets the child see a new game
-- as `pending` - present, not yet decided - instead of it appearing allowed by default.
CREATE TABLE family_child_apps (
  id UUID PRIMARY KEY,
  family_id UUID NOT NULL REFERENCES families(id) ON DELETE RESTRICT,
  child_id UUID NOT NULL,
  app_id TEXT NOT NULL,
  display_name TEXT NOT NULL,
  category TEXT NOT NULL CHECK (category IN ('games', 'social', 'edu', 'tools')),
  age_rating TEXT NOT NULL DEFAULT '',
  first_seen_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_seen_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  reported_by_device_id UUID NULL REFERENCES family_child_devices(id) ON DELETE RESTRICT,
  CONSTRAINT family_child_apps_child_in_family
    FOREIGN KEY (family_id, child_id)
    REFERENCES family_children (family_id, id)
    ON DELETE RESTRICT,
  CONSTRAINT family_child_apps_one_per_app UNIQUE (child_id, app_id),
  CONSTRAINT family_child_apps_family_id_id_unique UNIQUE (family_id, id),
  CONSTRAINT family_child_apps_app_id_valid
    CHECK (char_length(btrim(app_id)) BETWEEN 1 AND 120),
  CONSTRAINT family_child_apps_name_valid
    CHECK (char_length(btrim(display_name)) BETWEEN 1 AND 120),
  CONSTRAINT family_child_apps_age_rating_valid
    CHECK (char_length(age_rating) <= 16)
);

CREATE INDEX family_child_apps_inventory
  ON family_child_apps (child_id, category, app_id);

-- Minutes used today, per app. Cumulative for the day, monotonic on write, and never more
-- than a day can hold: a report of 2000 minutes is a handset bug, not a busy afternoon.
CREATE TABLE family_child_app_usage_daily (
  id UUID PRIMARY KEY,
  family_id UUID NOT NULL REFERENCES families(id) ON DELETE RESTRICT,
  child_id UUID NOT NULL,
  app_id TEXT NOT NULL,
  usage_date DATE NOT NULL,
  used_minutes INTEGER NOT NULL CHECK (used_minutes BETWEEN 0 AND 1440),
  reported_by_device_id UUID NULL REFERENCES family_child_devices(id) ON DELETE RESTRICT,
  first_reported_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  reported_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT family_child_app_usage_daily_child_in_family
    FOREIGN KEY (family_id, child_id)
    REFERENCES family_children (family_id, id)
    ON DELETE RESTRICT,
  CONSTRAINT family_child_app_usage_daily_one_per_app_per_day
    UNIQUE (child_id, app_id, usage_date),
  CONSTRAINT family_child_app_usage_daily_app_id_valid
    CHECK (char_length(btrim(app_id)) BETWEEN 1 AND 120)
);

CREATE INDEX family_child_app_usage_daily_day
  ON family_child_app_usage_daily (child_id, usage_date, app_id);

-- A lock episode: an instant lock with an author, a reason, and - exactly once - a release.
-- Keeping released episodes is the point: "the phone was off from 21:10 to 07:00" is a
-- fact a family will want next week, and deleting it would make the audit trail the only
-- memory of a decision the child was told about.
CREATE TABLE family_child_lock_state (
  id UUID PRIMARY KEY,
  family_id UUID NOT NULL REFERENCES families(id) ON DELETE RESTRICT,
  child_id UUID NOT NULL,
  reason_code TEXT NOT NULL CHECK (reason_code IN ('parent_lock', 'check_in', 'task_time', 'other')),
  locked_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  locked_by_membership_id UUID NOT NULL REFERENCES family_memberships(id) ON DELETE RESTRICT,
  released_at TIMESTAMPTZ NULL,
  released_by_membership_id UUID NULL REFERENCES family_memberships(id) ON DELETE RESTRICT,
  version INTEGER NOT NULL DEFAULT 1 CHECK (version >= 1),
  CONSTRAINT family_child_lock_state_child_in_family
    FOREIGN KEY (family_id, child_id)
    REFERENCES family_children (family_id, id)
    ON DELETE RESTRICT,
  CONSTRAINT family_child_lock_state_family_id_id_unique UNIQUE (family_id, id),
  CONSTRAINT family_child_lock_state_release_paired
    CHECK ((released_at IS NULL) = (released_by_membership_id IS NULL))
);

-- One live lock per child. A second press of "lock now" must find the lock that exists
-- rather than stacking a second one - the same one-open-per-child law the emergency
-- incident holds, for the same reason: two answers to one question split the family.
CREATE UNIQUE INDEX family_child_lock_state_one_live_per_child
  ON family_child_lock_state (child_id)
  WHERE released_at IS NULL;

CREATE INDEX family_child_lock_state_history
  ON family_child_lock_state (child_id, locked_at DESC, id DESC);

-- A question the child asked and a guardian answered. `usage_date` is the day the granted
-- minutes belong to, which is why this table needs no wallet: the day's grant is the sum
-- of the approved requests for that day, computed when the state is computed.
CREATE TABLE family_child_time_requests (
  id UUID PRIMARY KEY,
  family_id UUID NOT NULL REFERENCES families(id) ON DELETE RESTRICT,
  child_id UUID NOT NULL,
  usage_date DATE NOT NULL,
  requested_minutes INTEGER NOT NULL CHECK (requested_minutes BETWEEN 1 AND 240),
  requested_by_kind TEXT NOT NULL CHECK (requested_by_kind IN ('child', 'guardian')),
  -- A question from a guardian names the membership that asked. A question from the child's
  -- own handset names nobody: the device credential is what proves which child is asking,
  -- and there is no link from a membership to a child row to point at. The pairing below is
  -- what keeps the two honest - a guardian's question always has an author, a child's never
  -- pretends to have one.
  requested_by_membership_id UUID NULL REFERENCES family_memberships(id) ON DELETE RESTRICT,
  reason_code TEXT NULL,
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'approved', 'denied', 'expired')),
  granted_minutes INTEGER NULL CHECK (granted_minutes BETWEEN 1 AND 240),
  expires_at TIMESTAMPTZ NOT NULL,
  decided_at TIMESTAMPTZ NULL,
  decided_by_membership_id UUID NULL REFERENCES family_memberships(id) ON DELETE RESTRICT,
  version INTEGER NOT NULL DEFAULT 1 CHECK (version >= 1),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT family_child_time_requests_child_in_family
    FOREIGN KEY (family_id, child_id)
    REFERENCES family_children (family_id, id)
    ON DELETE RESTRICT,
  CONSTRAINT family_child_time_requests_family_id_id_unique UNIQUE (family_id, id),
  CONSTRAINT family_child_time_requests_reason_valid
    CHECK (reason_code IS NULL OR char_length(btrim(reason_code)) BETWEEN 1 AND 40),
  -- Decided means decided by someone: an answer without a decider is a screen that says
  -- "approved" and cannot name who approved it. Expiring is NOT deciding - a question whose
  -- time passed has no author and must not be forced to invent one.
  CONSTRAINT family_child_time_requests_decision_complete
    CHECK (
      (status IN ('approved', 'denied'))
        = (decided_at IS NOT NULL AND decided_by_membership_id IS NOT NULL)
    ),
  CONSTRAINT family_child_time_requests_grant_only_when_approved
    CHECK ((status = 'approved') = (granted_minutes IS NOT NULL)),
  CONSTRAINT family_child_time_requests_grant_not_more_than_asked
    CHECK (granted_minutes IS NULL OR granted_minutes <= requested_minutes),
  CONSTRAINT family_child_time_requests_requester_paired
    CHECK ((requested_by_kind = 'guardian') = (requested_by_membership_id IS NOT NULL))
);

-- At most one question per child is open. Three stacked requests is a child guessing at
-- the interface; one is a question a parent can answer.
CREATE UNIQUE INDEX family_child_time_requests_one_pending_per_child
  ON family_child_time_requests (child_id)
  WHERE status = 'pending';

CREATE INDEX family_child_time_requests_feed
  ON family_child_time_requests (child_id, created_at DESC, id DESC);

-- The day's granted minutes are read by (child, day) on every state computation.
CREATE INDEX family_child_time_requests_grants
  ON family_child_time_requests (child_id, usage_date)
  WHERE status = 'approved';
