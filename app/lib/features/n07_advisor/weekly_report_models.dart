import 'package:flutter/foundation.dart';

@immutable
final class WeeklyReportInclude {
  const WeeklyReportInclude({
    this.screen = true,
    this.places = true,
    this.wins = true,
    this.quran = true,
    this.watch = true,
  });

  final bool screen;
  final bool places;
  final bool wins;
  final bool quran;
  final bool watch;

  WeeklyReportInclude copyWith({
    bool? screen,
    bool? places,
    bool? wins,
    bool? quran,
    bool? watch,
  }) {
    return WeeklyReportInclude(
      screen: screen ?? this.screen,
      places: places ?? this.places,
      wins: wins ?? this.wins,
      quran: quran ?? this.quran,
      watch: watch ?? this.watch,
    );
  }
}

@immutable
final class WeeklyReportSnapshot {
  const WeeklyReportSnapshot({
    this.hasFamily = false,
    this.whenKey = 'fridayMorning',
    this.styleKey = 'detailed',
    this.include = const WeeklyReportInclude(),
    this.recommendationKey = 'sleepShift',
    this.learnDeltaPercent = 12,
    this.sleepDeltaMinutes = -40,
    this.recommendationApplied = false,
    this.recommendationDeferred = false,
  });

  final bool hasFamily;
  final String whenKey;
  final String styleKey;
  final WeeklyReportInclude include;
  final String recommendationKey;
  final int learnDeltaPercent;
  final int sleepDeltaMinutes;
  final bool recommendationApplied;
  final bool recommendationDeferred;

  bool get isEmpty => !hasFamily;

  WeeklyReportSnapshot copyWith({
    String? whenKey,
    String? styleKey,
    WeeklyReportInclude? include,
    bool? recommendationApplied,
    bool? recommendationDeferred,
  }) {
    return WeeklyReportSnapshot(
      hasFamily: hasFamily,
      whenKey: whenKey ?? this.whenKey,
      styleKey: styleKey ?? this.styleKey,
      include: include ?? this.include,
      recommendationKey: recommendationKey,
      learnDeltaPercent: learnDeltaPercent,
      sleepDeltaMinutes: sleepDeltaMinutes,
      recommendationApplied:
          recommendationApplied ?? this.recommendationApplied,
      recommendationDeferred:
          recommendationDeferred ?? this.recommendationDeferred,
    );
  }
}
