import 'package:flutter/foundation.dart';

/// Stop status on SCR-FAT-047 learning path thread (prototype `.tstop`).
enum LearningStopStatus { mastered, current, locked }

/// Stop kind — lesson vs capstone quiz.
enum LearningStopKind { lesson, quiz }

@immutable
final class LearningPathStop {
  const LearningPathStop({
    required this.id,
    required this.titleKey,
    required this.status,
    required this.kind,
    this.masteryPercent,
    this.subtitleKey = 'locked',
    this.rewardMinutes,
  });

  final String id;

  /// ARB discriminator for stop title (Rule 23 — no planted person names).
  final String titleKey;
  final LearningStopStatus status;
  final LearningStopKind kind;

  /// Present when [status] is [LearningStopStatus.mastered].
  final int? masteryPercent;

  /// ARB discriminator for subtitle line.
  final String subtitleKey;

  /// Capstone reward minutes (prototype «مكافأة كبرى»).
  final int? rewardMinutes;
}

@immutable
final class LearningPathSnapshot {
  const LearningPathSnapshot({
    this.childNameKey = 'one',
    this.subjectKey = 'fractions',
    this.progressPercent = 0,
    this.completedLessons = 0,
    this.totalLessons = 0,
    this.stops = const [],
  });

  /// ARB discriminator — generic child label (Rule 23).
  final String childNameKey;

  /// ARB discriminator — subject label (e.g. fractions).
  final String subjectKey;
  final int progressPercent;
  final int completedLessons;
  final int totalLessons;
  final List<LearningPathStop> stops;

  bool get isEmpty => stops.isEmpty;

  LearningPathStop? get currentStop {
    for (final s in stops) {
      if (s.status == LearningStopStatus.current) return s;
    }
    return null;
  }
}
