import 'package:flutter/foundation.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/minutes.dart';

/// Where the father published from (Studio hosts).
enum LearningAssignmentSource {
  attribution,
  homework,
  skillGap,
  familyChallenge,
}

/// One father→child learning assignment (P15-EDU-002 · P12 seam).
@immutable
final class LearningAssignment {
  const LearningAssignment({
    required this.id,
    required this.childId,
    required this.titleKey,
    required this.rewardMinutes,
    required this.source,
    required this.assignedAt,
    this.ctaScreenId = 'SCR-CHD-015',
    this.materialKindKey = 'math',
  });

  final String id;
  final ChildId childId;

  /// ARB discriminator for challenge / material title (Rule 23).
  final String titleKey;

  /// Minutes-only reward (ع-١) — never points/XP.
  final Minutes rewardMinutes;

  final LearningAssignmentSource source;
  final DateTime assignedAt;
  final String ctaScreenId;

  /// Maps to child material subject kind key (`math` / `quran` / `english`).
  final String materialKindKey;
}

@immutable
final class LearningAssignmentPublishRequest {
  const LearningAssignmentPublishRequest({
    required this.childId,
    required this.titleKey,
    required this.rewardMinutes,
    required this.source,
    this.ctaScreenId = 'SCR-CHD-015',
    this.materialKindKey = 'math',
  });

  final ChildId childId;
  final String titleKey;
  final Minutes rewardMinutes;
  final LearningAssignmentSource source;
  final String ctaScreenId;
  final String materialKindKey;
}
