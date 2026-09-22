import 'package:flutter/foundation.dart';

/// Weekly goal status on SCR-FAT-051 (prototype goal tag).
enum FocusReportGoalStatus { complete, inProgress }

@immutable
final class FocusReportChild {
  const FocusReportChild({
    required this.id,
    required this.nameKey,
  });

  final String id;

  /// ARB discriminator — screen maps to localized generic label (Rule 23).
  final String nameKey;
}

@immutable
final class FocusWeeklySummary {
  const FocusWeeklySummary({
    required this.sessionsCount,
    required this.totalDurationMinutes,
    required this.longestSessionMinutes,
    required this.goalStatus,
  });

  final int sessionsCount;

  /// Net focus minutes this week (prototype «٣ س ٤٠ د»).
  final int totalDurationMinutes;

  /// Longest single session in minutes (prototype «٥٥ د»).
  final int longestSessionMinutes;
  final FocusReportGoalStatus goalStatus;
}

@immutable
final class FocusAdvisorNote {
  const FocusAdvisorNote({
    required this.id,
    required this.titleKey,
    required this.bodyKey,
    this.praiseSent = false,
    this.praiseQuoteKey,
    this.rewardSent = false,
  });

  final String id;

  /// ARB discriminator for advisor headline.
  final String titleKey;

  /// ARB discriminator for advisor body (Rule 23 — no planted names).
  final String bodyKey;
  final bool praiseSent;

  /// ARB discriminator for sent praise quote shown after send.
  final String? praiseQuoteKey;
  final bool rewardSent;

  FocusAdvisorNote copyWith({
    bool? praiseSent,
    String? praiseQuoteKey,
    bool? rewardSent,
  }) {
    return FocusAdvisorNote(
      id: id,
      titleKey: titleKey,
      bodyKey: bodyKey,
      praiseSent: praiseSent ?? this.praiseSent,
      praiseQuoteKey: praiseQuoteKey ?? this.praiseQuoteKey,
      rewardSent: rewardSent ?? this.rewardSent,
    );
  }
}

@immutable
final class FocusScheduleItem {
  const FocusScheduleItem({
    required this.id,
    required this.nameKey,
    required this.childNameKey,
    required this.timeKey,
    required this.daysKey,
    required this.blockedAppKeys,
    this.enabled = true,
  });

  final String id;

  /// ARB discriminator for schedule title.
  final String nameKey;

  /// ARB discriminator for child label (Rule 23).
  final String childNameKey;

  /// ARB discriminator for time window.
  final String timeKey;

  /// ARB discriminator for recurrence days.
  final String daysKey;

  /// ARB discriminators for blocked apps (joined in screen).
  final List<String> blockedAppKeys;
  final bool enabled;

  FocusScheduleItem copyWith({bool? enabled}) {
    return FocusScheduleItem(
      id: id,
      nameKey: nameKey,
      childNameKey: childNameKey,
      timeKey: timeKey,
      daysKey: daysKey,
      blockedAppKeys: blockedAppKeys,
      enabled: enabled ?? this.enabled,
    );
  }
}

@immutable
final class FocusReportSnapshot {
  const FocusReportSnapshot({
    this.child,
    this.weeklySummary,
    this.advisorNote,
    this.schedules = const [],
    this.rewardMinutes = 15,
  });

  final FocusReportChild? child;
  final FocusWeeklySummary? weeklySummary;
  final FocusAdvisorNote? advisorNote;
  final List<FocusScheduleItem> schedules;

  /// Minutes only (ع-١) — self-discipline reward.
  final int rewardMinutes;

  bool get isEmpty => child == null;

  bool get hasAdvisorNote => advisorNote != null;

  FocusReportSnapshot copyWith({
    FocusReportChild? child,
    FocusWeeklySummary? weeklySummary,
    FocusAdvisorNote? advisorNote,
    List<FocusScheduleItem>? schedules,
    int? rewardMinutes,
  }) {
    return FocusReportSnapshot(
      child: child ?? this.child,
      weeklySummary: weeklySummary ?? this.weeklySummary,
      advisorNote: advisorNote ?? this.advisorNote,
      schedules: schedules ?? this.schedules,
      rewardMinutes: rewardMinutes ?? this.rewardMinutes,
    );
  }

  FocusReportSnapshot withScheduleToggled(String id, bool enabled) {
    return copyWith(
      schedules: schedules
          .map((s) => s.id == id ? s.copyWith(enabled: enabled) : s)
          .toList(growable: false),
    );
  }
}
