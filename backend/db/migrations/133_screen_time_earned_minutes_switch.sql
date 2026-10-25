-- Migration 133: add earned_minutes_extend_limit switch to family_child_screen_time_policies
-- Allows a guardian to enable earned minutes (Quran, tasks, learning) extending the daily phone limit.
-- Default is FALSE (OFF).
ALTER TABLE family_child_screen_time_policies
  ADD COLUMN earned_minutes_extend_limit BOOLEAN NOT NULL DEFAULT FALSE;

