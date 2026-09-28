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

  Map<String, Object?> toJson() => {
        'id': id,
        'childId': childId.value,
        'titleKey': titleKey,
        'rewardMinutes': rewardMinutes.inMinutes,
        'source': source.name,
        'assignedAt': assignedAt.toUtc().toIso8601String(),
        'ctaScreenId': ctaScreenId,
        'materialKindKey': materialKindKey,
      };

  factory LearningAssignment.fromJson(Map<String, Object?> json) {
    final sourceName = json['source'] as String? ?? 'homework';
    final source = LearningAssignmentSource.values.firstWhere(
      (s) => s.name == sourceName,
      orElse: () => LearningAssignmentSource.homework,
    );
    return LearningAssignment(
      id: json['id']! as String,
      childId: ChildId(json['childId']! as String),
      titleKey: json['titleKey']! as String,
      rewardMinutes: Minutes((json['rewardMinutes'] as num?)?.toInt() ?? 0),
      source: source,
      assignedAt: DateTime.parse(json['assignedAt']! as String).toUtc(),
      ctaScreenId: json['ctaScreenId'] as String? ?? 'SCR-CHD-015',
      materialKindKey: json['materialKindKey'] as String? ?? 'math',
    );
  }
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
