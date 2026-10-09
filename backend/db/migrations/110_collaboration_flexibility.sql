-- Collaboration flexibility v1.
--
-- New conversations are direct pairs or user-created groups with explicitly named peers.
-- Existing household/one-child rows remain readable with their recorded membership. Guardian
-- inclusion is only applied when the family's active server-owned safety policy requires it.
--
-- This is additive. The old role columns remain the immutable safety principals; the policy
-- delegates collaboration capabilities only among guardian roles, while a primary guardian
-- always retains the ability to manage policy. Child devices never gain guardian capabilities.
-- New group members (added by later migrations) have a sequence boundary so joining a group
-- does not grant access to its earlier conversation history.

ALTER TABLE family_chat_threads
  DROP CONSTRAINT family_chat_threads_kind_check;

ALTER TABLE family_chat_threads
  ADD CONSTRAINT family_chat_threads_kind_check
    CHECK (kind IN ('family', 'child', 'direct', 'group')),
  ADD COLUMN direct_pair_key TEXT NULL,
  ADD COLUMN created_by_child_id UUID NULL REFERENCES family_children(id) ON DELETE RESTRICT,
  ADD COLUMN created_by_participant_kind TEXT NOT NULL DEFAULT 'membership',
  ADD COLUMN created_by_participant_id UUID NULL;

UPDATE family_chat_threads
   SET created_by_participant_id = created_by_membership_id;

ALTER TABLE family_chat_threads
  ALTER COLUMN created_by_membership_id DROP NOT NULL,
  ALTER COLUMN created_by_participant_id SET NOT NULL,
  ADD CONSTRAINT family_chat_threads_creator_complete CHECK (
    (created_by_participant_kind = 'membership'
      AND created_by_membership_id IS NOT NULL
      AND created_by_child_id IS NULL
      AND created_by_participant_id = created_by_membership_id)
    OR (created_by_participant_kind = 'child'
      AND created_by_membership_id IS NULL
      AND created_by_child_id IS NOT NULL
      AND created_by_participant_id = created_by_child_id)
  ),
  ADD CONSTRAINT family_chat_threads_creator_kind_valid
    CHECK (created_by_participant_kind IN ('membership', 'child')),
  ADD CONSTRAINT family_chat_threads_direct_pair_key_bounded
    CHECK (direct_pair_key IS NULL OR char_length(direct_pair_key) BETWEEN 16 AND 100),
  ADD CONSTRAINT family_chat_threads_direct_pair_key_required
    CHECK (kind <> 'direct' OR direct_pair_key IS NOT NULL);

CREATE INDEX family_chat_threads_direct_pair_idx
  ON family_chat_threads (family_id, direct_pair_key)
  WHERE kind = 'direct';

ALTER TABLE family_chat_thread_members
  ADD COLUMN joined_seq BIGINT NOT NULL DEFAULT 1 CHECK (joined_seq >= 1),
  ADD COLUMN left_at TIMESTAMPTZ NULL;

CREATE INDEX family_chat_thread_members_active_participant_idx
  ON family_chat_thread_members (family_id, participant_kind, participant_id, thread_id)
  WHERE left_at IS NULL;

CREATE TABLE family_collaboration_policies (
  family_id UUID PRIMARY KEY REFERENCES families(id) ON DELETE RESTRICT,
  -- Role keys are security principals, not user-editable labels. Families may delegate these
  -- capabilities among guardians; no policy can grant a child a guardian-only capability.
  chat_create_roles TEXT[] NOT NULL DEFAULT ARRAY['primary_guardian', 'co_guardian']::text[],
  chat_manage_roles TEXT[] NOT NULL DEFAULT ARRAY['primary_guardian', 'co_guardian']::text[],
  task_roles TEXT[] NOT NULL DEFAULT ARRAY['primary_guardian', 'co_guardian']::text[],
  calendar_roles TEXT[] NOT NULL DEFAULT ARRAY['primary_guardian', 'co_guardian']::text[],
  child_direct_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  child_groups_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  child_group_member_management_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  -- No hidden guardian addition is the default. The family must explicitly activate one of
  -- these server-enforced rules before a guardian is added to a newly-created child chat.
  guardian_inclusion_mode TEXT NOT NULL DEFAULT 'none'
    CHECK (guardian_inclusion_mode IN ('none', 'all_child_chats', 'child_to_child')),
  maximum_group_size SMALLINT NOT NULL DEFAULT 24 CHECK (maximum_group_size BETWEEN 3 AND 24),
  version INTEGER NOT NULL DEFAULT 1 CHECK (version >= 1),
  updated_by_membership_id UUID NOT NULL REFERENCES family_memberships(id) ON DELETE RESTRICT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT family_collaboration_chat_create_roles_guardian_only
    CHECK (chat_create_roles <@ ARRAY['primary_guardian', 'co_guardian']::text[]),
  CONSTRAINT family_collaboration_chat_manage_roles_guardian_only
    CHECK (chat_manage_roles <@ ARRAY['primary_guardian', 'co_guardian']::text[]),
  CONSTRAINT family_collaboration_task_roles_guardian_only
    CHECK (task_roles <@ ARRAY['primary_guardian', 'co_guardian']::text[]),
  CONSTRAINT family_collaboration_calendar_roles_guardian_only
    CHECK (calendar_roles <@ ARRAY['primary_guardian', 'co_guardian']::text[])
);
