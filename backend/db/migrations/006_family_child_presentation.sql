-- Presentation attributes are durable child-profile facts, not device telemetry.
-- Existing roster records receive neutral onboarding defaults so a deployed
-- database remains readable while guardians may create richer new profiles.

ALTER TABLE family_children
  ADD COLUMN avatar_emoji TEXT NOT NULL DEFAULT '🧒',
  ADD COLUMN theme_color TEXT NOT NULL DEFAULT 'purple';

ALTER TABLE family_children
  ADD CONSTRAINT family_children_avatar_emoji_valid
    CHECK (char_length(btrim(avatar_emoji)) BETWEEN 1 AND 32),
  ADD CONSTRAINT family_children_theme_color_valid
    CHECK (theme_color IN ('purple', 'sky', 'amber', 'coral', 'mint', 'teal'));
