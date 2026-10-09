-- W6 WEB FILTERING AND TAMPER RESISTANCE — what a family decided the internet should
-- look like for a child, which door it opened and until when, and the difference between
-- "protection is on" and "nobody has told us otherwise lately".
--
-- The master plan calls this the hardest of the safety waves, and it is hardest for one
-- reason: it is the feature where a product can look effective while doing nothing. A
-- shield icon on a parent's phone is not protection; it is a picture. So this schema is
-- built so that the thing a parent reads as "protected" can only be produced by evidence.
--
-- Three tables, and one law that shapes all three:
--
--   family_web_filter_policies       what the family stated: the level, the categories
--                                    they turned on, the two lists a family actually
--                                    keeps (allow, block), and the keyword dictionary.
--                                    Nothing derived is stored.
--
--   family_web_filter_temp_allows    a door a guardian opened for a stated time: the
--                                    host, who asked, who answered, and the minute it
--                                    closes by itself. `expires_at` is NOT NULL on an
--                                    approval - a temporary allow with no end is not a
--                                    temporary allow, it is a permanent hole with a
--                                    temporary label.
--
--   family_device_protection_reports the handset's own testimony, append-only: what it
--                                    observed, and when it observed it. A report is
--                                    never edited and never deleted, because the moment
--                                    a report can be replaced, "the protection was on
--                                    all along" becomes sayable.
--
-- THE LAW: protection health is computed from the last report and the clock, never
-- stored. A device that stopped reporting is `unverified` - not `protected`, and not
-- `broken`. That single decision is the difference between a product that tells the
-- truth and one that draws a green dot because nobody complained.
--
-- And the anchor for "how long ago": the SERVER's receipt time, not the device's claim
-- of when it looked. A device's clock is exactly the thing a child who wants a shield off
-- would move first, so freshness is measured against the clock nobody on the handset can
-- reach. (Policy windows are the opposite case and are measured in the FAMILY's offset -
-- migration 105's sixth law - because there the question is what time it is for this
-- family, and here the question is how long since this device spoke.)
--
-- What this migration deliberately does NOT do: it does not store a `blocked_count`, a
-- `last_blocked_url`, or any per-site browsing history. A filter that keeps a log of what
-- a child tried to open is a surveillance product wearing a filter's clothes, and the
-- family has a right to filtering without that.

-- Two list predicates the constraints below need. They are functions rather than inline
-- expressions because a CHECK constraint may not contain a subquery or a set-returning
-- function, and "every element of this array is a hostname" is exactly that - so the
-- honesty rule moves into an IMMUTABLE function instead of being dropped.
CREATE FUNCTION fs_list_is_hostnames(hosts TEXT[]) RETURNS BOOLEAN
  LANGUAGE sql IMMUTABLE AS $$
    SELECT COALESCE(bool_and(host ~ '^[a-z0-9.-]+$' AND char_length(host) BETWEEN 4 AND 253), TRUE)
    FROM unnest(hosts) AS host
  $$;

CREATE FUNCTION fs_list_has_duplicates(items TEXT[]) RETURNS BOOLEAN
  LANGUAGE sql IMMUTABLE AS $$
    SELECT COALESCE(cardinality(items) <> cardinality(ARRAY(SELECT DISTINCT value FROM unnest(items) AS value)), FALSE)
  $$;

CREATE TABLE family_web_filter_policies (
  child_id UUID PRIMARY KEY,
  family_id UUID NOT NULL REFERENCES families(id) ON DELETE RESTRICT,
  -- The level is a preset, not a permission: it seeds the categories when a family picks
  -- it, and what the server enforces afterwards is always the category list below. Two
  -- ways to say one thing is how a screen ends up disagreeing with a server.
  level TEXT NOT NULL DEFAULT 'balanced'
    CHECK (level IN ('strict', 'balanced', 'open')),
  -- The keys a father sees as switches. The same six are in the client's
  -- `WebFilterCategories.known`, and a test compares the two lists, because a toggle that
  -- the server does not know is a toggle that silently does nothing.
  enabled_categories TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
  allow_hosts TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
  block_hosts TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
  dictionary_keywords TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
  version INTEGER NOT NULL DEFAULT 1 CHECK (version >= 1),
  updated_by_membership_id UUID NULL REFERENCES family_memberships(id) ON DELETE RESTRICT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT family_web_filter_policies_child_in_family
    FOREIGN KEY (family_id, child_id)
    REFERENCES family_children (family_id, id)
    ON DELETE RESTRICT,
  -- An unknown category key cannot be stored. It would be a switch a parent can flip whose
  -- effect exists only in the app, and the whole point of this wave is that no such switch
  -- ships.
  CONSTRAINT family_web_filter_policies_categories_known
    CHECK (enabled_categories <@ ARRAY['adults', 'gambling', 'violence', 'social', 'games', 'streaming']::TEXT[]),
  -- No duplicates: the same key twice is a client bug that would otherwise be stored.
  CONSTRAINT family_web_filter_policies_categories_distinct
    CHECK (NOT fs_list_has_duplicates(enabled_categories)),
  CONSTRAINT family_web_filter_policies_lists_bounded
    CHECK (array_length(allow_hosts, 1) IS NULL OR array_length(allow_hosts, 1) <= 200),
  CONSTRAINT family_web_filter_policies_blocks_bounded
    CHECK (array_length(block_hosts, 1) IS NULL OR array_length(block_hosts, 1) <= 200),
  CONSTRAINT family_web_filter_policies_keywords_bounded
    CHECK (array_length(dictionary_keywords, 1) IS NULL OR array_length(dictionary_keywords, 1) <= 200),
  -- Hosts are hostnames, not URLs and not patterns. A list that accepts "https://" or "*"
  -- is a list whose matching rules nobody can predict, and the client's engine matches
  -- hosts only; storing anything else would make the server and the app disagree about
  -- what a family allowed.
  CONSTRAINT family_web_filter_policies_hosts_are_hosts
    CHECK (fs_list_is_hostnames(allow_hosts)),
  CONSTRAINT family_web_filter_policies_blocks_are_hosts
    CHECK (fs_list_is_hostnames(block_hosts)),
  -- A host may not be both allowed and blocked: the engine resolves blocklist first, so
  -- storing both would mean the allowlist entry is a line of the screen that does nothing.
  CONSTRAINT family_web_filter_policies_lists_disjoint
    CHECK (NOT (allow_hosts && block_hosts))
);

CREATE TABLE family_web_filter_temp_allows (
  id UUID PRIMARY KEY,
  family_id UUID NOT NULL REFERENCES families(id) ON DELETE RESTRICT,
  child_id UUID NOT NULL,
  host TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('pending', 'approved', 'denied')),
  requested_minutes INTEGER NOT NULL CHECK (requested_minutes BETWEEN 1 AND 240),
  -- How long the door is actually open is the guardian's answer, never the child's ask.
  -- It is bounded above by the request (see the constraint below) and by a ceiling,
  -- because an approval of "1440 minutes" is a permission slip, not a temporary allow.
  granted_minutes INTEGER NULL CHECK (granted_minutes BETWEEN 1 AND 120),
  reason TEXT NOT NULL DEFAULT '',
  requested_by_membership_id UUID NULL REFERENCES family_memberships(id) ON DELETE RESTRICT,
  requested_by_device_id UUID NULL REFERENCES family_child_devices(id) ON DELETE RESTRICT,
  decided_by_membership_id UUID NULL REFERENCES family_memberships(id) ON DELETE RESTRICT,
  decided_at TIMESTAMPTZ NULL,
  expires_at TIMESTAMPTZ NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT family_web_filter_temp_allows_child_in_family
    FOREIGN KEY (family_id, child_id)
    REFERENCES family_children (family_id, id)
    ON DELETE RESTRICT,
  CONSTRAINT family_web_filter_temp_allows_family_id_id_unique UNIQUE (family_id, id),
  CONSTRAINT family_web_filter_temp_allows_host_valid
    CHECK (host ~ '^[a-z0-9.-]+$' AND char_length(host) BETWEEN 4 AND 253),
  CONSTRAINT family_web_filter_temp_allows_reason_bounded
    CHECK (char_length(reason) <= 300),
  -- Every question has an asker, and it is exactly one of the two kinds we can prove:
  -- a guardian's membership, or the child's own handset. A request with neither would be
  -- anonymous, and an anonymous request is one nobody can be asked about.
  CONSTRAINT family_web_filter_temp_allows_requester_present
    CHECK ((requested_by_membership_id IS NOT NULL) <> (requested_by_device_id IS NOT NULL)),
  -- A decided question names the person who decided it. There is no "system" here: a
  -- question about a child's internet is answered by an adult, or it stays open.
  CONSTRAINT family_web_filter_temp_allows_decision_has_author
    CHECK (status = 'pending'
      OR (decided_at IS NOT NULL AND decided_by_membership_id IS NOT NULL)),
  -- An approval carries the minute it closes at and how long it was for.
  CONSTRAINT family_web_filter_temp_allows_approval_has_end
    CHECK (status <> 'approved'
      OR (expires_at IS NOT NULL AND granted_minutes IS NOT NULL)),
  -- A denial opens nothing: no end, no granted minutes. Storing an end on a denial would
  -- leave a row that reads like a door that was open.
  CONSTRAINT family_web_filter_temp_allows_denial_opens_nothing
    CHECK (status <> 'denied' OR (expires_at IS NULL AND granted_minutes IS NULL)),
  -- An open question has nothing decided on it yet.
  CONSTRAINT family_web_filter_temp_allows_pending_is_undecided
    CHECK (status <> 'pending'
      OR (decided_at IS NULL
        AND decided_by_membership_id IS NULL
        AND expires_at IS NULL
        AND granted_minutes IS NULL)),
  -- The guardian cannot grant more than the child asked for. Screen time states the same
  -- law for minutes ("the grant never exceeds the request"), and it holds here too:
  -- quietly widening a request is not answering it.
  CONSTRAINT family_web_filter_temp_allows_grant_within_request
    CHECK (granted_minutes IS NULL OR granted_minutes <= requested_minutes)
);

CREATE INDEX family_web_filter_temp_allows_child_created
  ON family_web_filter_temp_allows (child_id, created_at DESC, id ASC);

-- One open question per child and host at a time. Two identical pending rows would mean
-- the guardians answer the same question twice and the child gets two doors.
CREATE UNIQUE INDEX family_web_filter_temp_allows_one_pending_per_host
  ON family_web_filter_temp_allows (child_id, host)
  WHERE status = 'pending';

-- A handset may only testify about the child it belongs to. `family_child_devices.id` is
-- already a primary key, so this index adds no new uniqueness; what it adds is the ability
-- for the report table to reference the pair, which is how "this device reports for this
-- child" becomes a rule the database holds rather than one the module remembers.
CREATE UNIQUE INDEX family_child_devices_id_child_unique
  ON family_child_devices (id, child_id);

CREATE TABLE family_device_protection_reports (
  id UUID PRIMARY KEY,
  family_id UUID NOT NULL REFERENCES families(id) ON DELETE RESTRICT,
  child_id UUID NOT NULL,
  device_id UUID NOT NULL REFERENCES family_child_devices(id) ON DELETE RESTRICT,
  -- What the handset observed about its own protection plane. `healthy` is a claim like
  -- any other and is stored as the handset's claim, not as a conclusion: the server
  -- decides what a family is told by reading this row with the clock in hand.
  observed_state TEXT NOT NULL
    CHECK (observed_state IN (
      'healthy',
      'vpn_active',
      'profile_removed',
      'permission_revoked',
      'dns_bypassed',
      'device_admin_removed',
      'unsupported'
    )),
  -- The individual things the handset saw, each one a fact it can be asked about later.
  -- Free-form tokens with a known core: a future handset may learn to see something this
  -- server has never heard of, and refusing to store it would lose the evidence rather
  -- than the meaning.
  signals TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
  detail TEXT NOT NULL DEFAULT '',
  -- The handset's own stamp of when it looked. Kept as testimony.
  observed_at TIMESTAMPTZ NOT NULL,
  -- The server's stamp of when it heard. This is what freshness is measured by, because a
  -- device clock is the first thing someone with something to hide would move.
  reported_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT family_device_protection_reports_child_in_family
    FOREIGN KEY (family_id, child_id)
    REFERENCES family_children (family_id, id)
    ON DELETE RESTRICT,
  CONSTRAINT family_device_protection_reports_device_child
    FOREIGN KEY (device_id, child_id)
    REFERENCES family_child_devices (id, child_id)
    ON DELETE RESTRICT,
  CONSTRAINT family_device_protection_reports_signals_bounded
    CHECK (array_length(signals, 1) IS NULL OR array_length(signals, 1) <= 32),
  CONSTRAINT family_device_protection_reports_detail_bounded
    CHECK (char_length(detail) <= 500)
);

-- The read a family makes is always "the newest report per device", so the index leads
-- with the device and orders by the server's receipt time.
CREATE INDEX family_device_protection_reports_device_reported
  ON family_device_protection_reports (device_id, reported_at DESC, id DESC);

CREATE INDEX family_device_protection_reports_family_reported
  ON family_device_protection_reports (family_id, reported_at DESC, id DESC);
