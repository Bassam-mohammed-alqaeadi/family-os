import 'package:flutter/foundation.dart';

/// Skill gap remediation state on SCR-FAT-050 (prototype FAT-050).
enum ResultsFollowupSkillGapStatus { pending, mastered }

/// Activity log row kind on SCR-FAT-050.
enum ResultsFollowupActivityKind { homework, familyChallenge }

@immutable
final class ResultsFollowupChild {
  const ResultsFollowupChild({
    required this.id,
    required this.nameKey,
  });

  final String id;

  /// ARB discriminator — screen maps to localized generic label (Rule 23).
  final String nameKey;
}

@immutable
final class ResultsFollowupMastery {
  const ResultsFollowupMastery({
    required this.subjectKey,
    required this.percent,
    this.previousPercent,
  });

  /// ARB discriminator for subject title (no planted names).
  final String subjectKey;
  final int percent;

  /// When set and [percent] is higher — show improved tag (prototype ↗).
  final int? previousPercent;

  bool get hasImprovement =>
      previousPercent != null && percent > previousPercent!;
}

@immutable
final class ResultsFollowupSkillGap {
  const ResultsFollowupSkillGap({
    required this.id,
    required this.titleKey,
    required this.status,
    this.missed = 0,
    this.total = 0,
    this.masteryPercent,
  });

  final String id;

  /// ARB discriminator for skill title (no planted names).
  final String titleKey;
  final ResultsFollowupSkillGapStatus status;
  final int missed;
  final int total;

  /// Shown when [status] is mastered (minutes-only screen — no XP).
  final int? masteryPercent;

  bool get isPending => status == ResultsFollowupSkillGapStatus.pending;

  bool get isMastered => status == ResultsFollowupSkillGapStatus.mastered;
}

@immutable
final class ResultsFollowupActivity {
  const ResultsFollowupActivity({
    required this.id,
    required this.kind,
    required this.titleKey,
    required this.subtitleKey,
    required this.statusKey,
    this.minutes,
  });

  final String id;
  final ResultsFollowupActivityKind kind;

  /// ARB discriminators for title / subtitle / status (Rule 23).
  final String titleKey;
  final String subtitleKey;
  final String statusKey;

  /// Minutes only (ع-١) — family challenge reward row.
  final int? minutes;
}

@immutable
final class ResultsFollowupSnapshot {
  const ResultsFollowupSnapshot({
    this.child,
    this.mastery,
    this.skillGap,
    this.activities = const [],
  });

  final ResultsFollowupChild? child;
  final ResultsFollowupMastery? mastery;
  final ResultsFollowupSkillGap? skillGap;
  final List<ResultsFollowupActivity> activities;

  bool get isEmpty => child == null;
}
