-- W7 FAMILY TASKS AND POINTS — what a family asked a child to do, what the child says they
-- did, and the moment a guardian's word turns that claim into points.
--
-- The master plan puts this wave at the junction of protection and upbringing: the safety
-- waves answer "what may this phone do", and this one answers "what did this child earn".
-- That junction is exactly where a product can start flattering instead of recording, so
-- three things are true here by construction rather than by convention:
--
--   family_tasks          what a guardian stated: a title, what "done" means, and the
--                         number of points this task is worth. The number lives on the
--                         TASK, never in the request that confirms it - otherwise the
--                         party being rewarded could name their own price.
--
--   family_task_claims    a cycle: the child says "I did it", a guardian answers. A claim
--                         is claimed by exactly one author - the child's paired handset, or
--                         a guardian speaking for a child who talked rather than tapped - and
--                         is answered exactly once. One claim may be open at a time, so two
--                         presses do not become two rewards.
--
--   family_point_ledger   append-only. A row is written only when a guardian confirms, and
--                         UNIQUE (claim_id) is what makes "the same confirmation rewarded
--                         twice" impossible at the storage layer rather than in a code path
--                         someone might later reorder. There is no balance column anywhere in
--                         this schema: a balance is SUM(entries), so it cannot drift away from
--                         the record that produced it.
--
-- THE LAW: a claim is not an achievement. Between them stands a person. A decline awards
-- nothing at all - not a smaller number, and not a negative one - because "you did not do
-- it" is a fact, while "you owe me" is a different product with a different clientele.
-- Declining is therefore a decision with an author and a reason, and the task goes back to
-- open so a child can try again tomorrow; it does not close the door behind them.
--
-- What this migration deliberately does NOT do: it does not store a completion photo, a
-- location, or a streak. The proof of a chore is a person's word, and a system that
-- collected evidence for a household would be a surveillance product with a chore chart
-- drawn on top of it. Nor does it store points spent: spending arrives with the minutes
-- loop (W12), and when it does it will be a new named entry in this same append-only ledger
-- rather than an edit to what was earned.

CREATE TABLE family_tasks (
  id UUID PRIMARY KEY,
  family_id UUID NOT NULL REFERENCES families(id) ON DELETE RESTRICT,
  child_id UUID NOT NULL,
  title TEXT NOT NULL,
  note TEXT NOT NULL DEFAULT '',
  points INTEGER NOT NULL CHECK (points BETWEEN 1 AND 200),
  status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'archived')),
  -- Archived, not deleted: the ledger entries this task produced must keep pointing at the
  -- statement that produced them, or an earned point becomes an orphan number.
  created_by_membership_id UUID NOT NULL REFERENCES family_memberships(id) ON DELETE RESTRICT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT family_tasks_family_id_id_unique UNIQUE (family_id, id),
  CONSTRAINT family_tasks_child_fk FOREIGN KEY (family_id, child_id)
    REFERENCES family_children (family_id, id) ON DELETE RESTRICT,
  -- A title of only whitespace is not a task; it is an empty row wearing a task's clothes.
  CONSTRAINT family_tasks_title_present CHECK (title ~ '\S'),
  CONSTRAINT family_tasks_title_bounded CHECK (char_length(title) <= 120),
  CONSTRAINT family_tasks_note_bounded CHECK (char_length(note) <= 300)
);

CREATE INDEX family_tasks_child_created
  ON family_tasks (family_id, child_id, created_at DESC);

CREATE TABLE family_task_claims (
  id UUID PRIMARY KEY,
  family_id UUID NOT NULL REFERENCES families(id) ON DELETE RESTRICT,
  task_id UUID NOT NULL,
  child_id UUID NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('pending', 'confirmed', 'declined')),
  note TEXT NOT NULL DEFAULT '',
  -- Exactly one author: the child's own paired handset, or a guardian speaking for them.
  claimed_by_device_id UUID NULL REFERENCES family_child_devices(id) ON DELETE RESTRICT,
  claimed_by_membership_id UUID NULL REFERENCES family_memberships(id) ON DELETE RESTRICT,
  decided_by_membership_id UUID NULL REFERENCES family_memberships(id) ON DELETE RESTRICT,
  decided_at TIMESTAMPTZ NULL,
  decision_note TEXT NOT NULL DEFAULT '',
  -- The number copied from the task at the moment of confirmation. It is stored because a
  -- guardian may later edit the task's wording, and the points actually confirmed must keep
  -- saying what they were confirmed as.
  points_awarded INTEGER NULL CHECK (points_awarded BETWEEN 1 AND 200),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT family_task_claims_family_id_id_unique UNIQUE (family_id, id),
  CONSTRAINT family_task_claims_task_fk FOREIGN KEY (family_id, task_id)
    REFERENCES family_tasks (family_id, id) ON DELETE RESTRICT,
  CONSTRAINT family_task_claims_child_fk FOREIGN KEY (family_id, child_id)
    REFERENCES family_children (family_id, id) ON DELETE RESTRICT,
  CONSTRAINT family_task_claims_note_bounded CHECK (char_length(note) <= 300),
  CONSTRAINT family_task_claims_decision_note_bounded CHECK (char_length(decision_note) <= 300),
  CONSTRAINT family_task_claims_one_author CHECK ((claimed_by_device_id IS NOT NULL) <> (claimed_by_membership_id IS NOT NULL)),
  -- An open claim has no decision on it. Half a decision - an author without a time, or a
  -- time without an author - is the shape a bug leaves behind, so the schema refuses it.
  CONSTRAINT family_task_claims_pending_unanswered CHECK (
    status <> 'pending'
    OR (decided_by_membership_id IS NULL AND decided_at IS NULL AND points_awarded IS NULL)
  ),
  -- Confirmed means: a person, a moment, and a number. Nothing less.
  CONSTRAINT family_task_claims_confirmed_complete CHECK (
    status <> 'confirmed'
    OR (decided_by_membership_id IS NOT NULL AND decided_at IS NOT NULL AND points_awarded IS NOT NULL)
  ),
  -- Declined means a person and a moment, and NO number. A refusal that awards something is
  -- not a refusal, and a refusal that awards a negative is a debt this product does not keep.
  CONSTRAINT family_task_claims_declined_awards_nothing CHECK (
    status <> 'declined'
    OR (decided_by_membership_id IS NOT NULL AND decided_at IS NOT NULL AND points_awarded IS NULL)
  )
);

CREATE INDEX family_task_claims_task_created
  ON family_task_claims (family_id, task_id, created_at DESC);

-- One open claim per task, enforced by the database rather than by a read-then-write that
-- two phones can interleave. The second press is refused cleanly instead of becoming a
-- second claim a guardian would have to sort out.
CREATE UNIQUE INDEX family_task_claims_one_pending_per_task
  ON family_task_claims (task_id)
  WHERE status = 'pending';

CREATE TABLE family_point_ledger (
  id UUID PRIMARY KEY,
  family_id UUID NOT NULL REFERENCES families(id) ON DELETE RESTRICT,
  child_id UUID NOT NULL,
  points INTEGER NOT NULL CHECK (points <> 0),
  -- A closed vocabulary. Spending arrives in a later wave as a new named reason with its own
  -- law; it will not arrive by widening this one into "any reason at all".
  reason TEXT NOT NULL CHECK (reason IN ('task_confirmed')),
  claim_id UUID NULL REFERENCES family_task_claims(id) ON DELETE RESTRICT,
  awarded_by_membership_id UUID NOT NULL REFERENCES family_memberships(id) ON DELETE RESTRICT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT family_point_ledger_child_fk FOREIGN KEY (family_id, child_id)
    REFERENCES family_children (family_id, id) ON DELETE RESTRICT,
  -- An award is never negative. The constraint is written per-reason so the day a spending
  -- reason exists, the law for it is written there rather than loosened here.
  CONSTRAINT family_point_ledger_award_positive CHECK (reason <> 'task_confirmed' OR points > 0),
  -- The anti-double-credit index: one confirmation, one award. Many rows may share a NULL
  -- claim_id (a future correction that belongs to no claim), but no two rows may share one.
  CONSTRAINT family_point_ledger_one_entry_per_claim UNIQUE (claim_id)
);

CREATE INDEX family_point_ledger_child_created
  ON family_point_ledger (family_id, child_id, created_at DESC);
