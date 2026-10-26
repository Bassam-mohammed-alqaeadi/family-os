-- Programme «family character» (08_FAMILY_CUSTOMIZATION_PROGRAMME.md), slice 1 of 7.
--
-- The owner's standing instruction (2026-10-26): every family bends the app to its own culture and
-- vision, and finds those choices on the screens it actually uses. Today three cross-cutting facts
-- are written into code rather than into the family: which day a week grid begins, which days the
-- family rests, and what the app calls the people in it. This migration makes all three data.
--
-- Design laws, in the database rather than in prose:
--
-- * One row per family, and the row is the whole truth for these fields. Per-system capabilities
--   (screen-time budgets, web-filter categories, task decisions, chat policy) keep their own tables
--   and endpoints - this table does not copy them, so no capability ends up with two answers.
--
-- * A rest day is a boolean column, not an array. A CHECK can then refuse a family profile with no
--   rest day at all (which would make "school days" undefined and silently flip every weekday rule),
--   while an array cannot assert the absence of duplicates inside a CHECK at all.
--
-- * The addressing words are a JSONB object whose only legal keys are the four this product speaks
--   with. `guardian_labels - ARRAY[…] = '{}'` is the law: an invented key cannot reach a child's
--   screen, and every value must be a short non-blank string, so a label can neither smuggle markup
--   nor occupy a line forever.
--
-- * `version` is optimistic concurrency, exactly as in the collaboration policy (110): two guardians
--   reading the same profile and both saving must not lose one change in silence.
--
-- * The writer is recorded and constrained to a membership of THIS family by a composite foreign key,
--   so an audit row can never name an editor from another household.
--
-- Defaults preserve the behaviour the app has today - a Monday-first grid - so applying this
-- migration changes nothing for any existing family until a guardian chooses otherwise.

CREATE TABLE family_customization_profiles (
  family_id UUID PRIMARY KEY REFERENCES families(id) ON DELETE RESTRICT,

  -- Which day the family's week grid opens with. Names, not integers: an ordinal on the wire is a
  -- bug waiting to be renumbered, and seven CHECKed strings read themselves.
  week_start_day TEXT NOT NULL DEFAULT 'mon'
    CHECK (week_start_day IN ('sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat')),

  rest_sunday BOOLEAN NOT NULL DEFAULT FALSE,
  rest_monday BOOLEAN NOT NULL DEFAULT FALSE,
  rest_tuesday BOOLEAN NOT NULL DEFAULT FALSE,
  rest_wednesday BOOLEAN NOT NULL DEFAULT FALSE,
  rest_thursday BOOLEAN NOT NULL DEFAULT FALSE,
  rest_friday BOOLEAN NOT NULL DEFAULT TRUE,
  rest_saturday BOOLEAN NOT NULL DEFAULT TRUE,

  guardian_labels JSONB NOT NULL DEFAULT '{}'::jsonb,

  -- How this family wants its digits written. 'western' is what every screen drew before this
  -- column existed and stays the default; 'eastern' is open because the owner reversed his own
  -- OD-05 decision on 2026-10-26 when asked whether a family may choose its numerals.
  -- It is not a hint a client may ignore: every number in the app already passes through
  -- core/i18n/numeral_format.dart, and that reader is what this value is written for.
  numerals TEXT NOT NULL DEFAULT 'western'
    CHECK (numerals IN ('western', 'eastern')),

  version INTEGER NOT NULL DEFAULT 1 CHECK (version >= 1),
  updated_by_membership_id UUID NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT family_customization_rest_day_exists
    CHECK (
      rest_sunday OR rest_monday OR rest_tuesday OR rest_wednesday
      OR rest_thursday OR rest_friday OR rest_saturday
    ),
  CONSTRAINT family_customization_labels_are_object
    CHECK (jsonb_typeof(guardian_labels) = 'object'),
  CONSTRAINT family_customization_labels_known_keys
    CHECK (guardian_labels - ARRAY['father', 'mother', 'guardian', 'child'] = '{}'::jsonb),
  CONSTRAINT family_customization_labels_are_short_words
    CHECK (
      (guardian_labels->'father' IS NULL
        OR (jsonb_typeof(guardian_labels->'father') = 'string'
            AND char_length(btrim(guardian_labels->>'father')) BETWEEN 1 AND 24))
      AND (guardian_labels->'mother' IS NULL
        OR (jsonb_typeof(guardian_labels->'mother') = 'string'
            AND char_length(btrim(guardian_labels->>'mother')) BETWEEN 1 AND 24))
      AND (guardian_labels->'guardian' IS NULL
        OR (jsonb_typeof(guardian_labels->'guardian') = 'string'
            AND char_length(btrim(guardian_labels->>'guardian')) BETWEEN 1 AND 24))
      AND (guardian_labels->'child' IS NULL
        OR (jsonb_typeof(guardian_labels->'child') = 'string'
            AND char_length(btrim(guardian_labels->>'child')) BETWEEN 1 AND 24))
    ),
  -- No size bound is declared here on purpose: four known keys of at most 24 characters each is the
  -- bound, and a fifth law that no earlier law can violate would be decoration.
  CONSTRAINT family_customization_editor_membership_fk
    FOREIGN KEY (family_id, updated_by_membership_id)
    REFERENCES family_memberships (family_id, id)
    ON DELETE RESTRICT
);

-- Every screen that bends to the family reads it by family id, which the primary key already serves.
-- This index is for the other direction the product will need: "how many families rest on Friday",
-- so a culture question is answerable from the data instead of from a guess.
CREATE INDEX family_customization_profiles_friday_rest_idx
  ON family_customization_profiles (family_id)
  WHERE rest_friday;
