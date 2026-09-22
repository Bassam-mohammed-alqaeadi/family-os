import 'package:flutter/foundation.dart';

/// Assignment path on SCR-FAT-049 (prototype FAT-049 three tracks).
enum CreateAssignmentPath { homework, skillGap, familyChallenge }

@immutable
final class CreateAssignmentChild {
  const CreateAssignmentChild({
    required this.id,
    required this.nameKey,
  });

  final String id;

  /// ARB discriminator — screen maps to localized generic label (Rule 23).
  final String nameKey;
}

@immutable
final class CreateAssignmentSkillGap {
  const CreateAssignmentSkillGap({
    required this.id,
    required this.titleKey,
    required this.missed,
    required this.total,
    required this.quizQuestions,
    required this.rewardMinutes,
  });

  final String id;

  /// ARB discriminator for skill title (no planted names).
  final String titleKey;
  final int missed;
  final int total;
  final int quizQuestions;

  /// Minutes only (ع-١) — never points/XP.
  final int rewardMinutes;
}

@immutable
final class CreateAssignmentSnapshot {
  const CreateAssignmentSnapshot({
    this.child,
    this.homeworkTitle = '',
    this.homeworkRewardMinutes = 30,
    this.skillGap,
    this.familyQuestion = '',
    this.familyRewardMinutes = 30,
    this.lastAssignedPath,
  });

  final CreateAssignmentChild? child;
  final String homeworkTitle;
  final int homeworkRewardMinutes;
  final CreateAssignmentSkillGap? skillGap;
  final String familyQuestion;
  final int familyRewardMinutes;
  final CreateAssignmentPath? lastAssignedPath;

  bool get isEmpty => child == null;

  bool get hasSkillGap => skillGap != null;

  CreateAssignmentSnapshot copyWith({
    CreateAssignmentChild? child,
    String? homeworkTitle,
    int? homeworkRewardMinutes,
    CreateAssignmentSkillGap? skillGap,
    bool clearSkillGap = false,
    String? familyQuestion,
    int? familyRewardMinutes,
    CreateAssignmentPath? lastAssignedPath,
  }) {
    return CreateAssignmentSnapshot(
      child: child ?? this.child,
      homeworkTitle: homeworkTitle ?? this.homeworkTitle,
      homeworkRewardMinutes:
          homeworkRewardMinutes ?? this.homeworkRewardMinutes,
      skillGap: clearSkillGap ? null : (skillGap ?? this.skillGap),
      familyQuestion: familyQuestion ?? this.familyQuestion,
      familyRewardMinutes: familyRewardMinutes ?? this.familyRewardMinutes,
      lastAssignedPath: lastAssignedPath ?? this.lastAssignedPath,
    );
  }
}
