import 'package:flutter/foundation.dart';

@immutable
final class ChildMemBadge {
  const ChildMemBadge({
    required this.id,
    required this.labelKey,
    this.earned = false,
  });
  final String id;
  final String labelKey;
  final bool earned;
}

@immutable
final class ChildMemSurah {
  const ChildMemSurah({
    required this.id,
    required this.nameKey,
    this.progress = 1.0,
  });
  final String id;
  final String nameKey;
  final double progress;
}

@immutable
final class ChildMemReview {
  const ChildMemReview({
    required this.id,
    required this.titleKey,
    required this.metaKey,
    this.dueToday = true,
  });
  final String id;
  final String titleKey;
  final String metaKey;
  final bool dueToday;
}

@immutable
final class ChildMemorizationSnapshot {
  const ChildMemorizationSnapshot({
    this.hasProgress = false,
    this.surahCount = 0,
    this.extraAyahs = 0,
    this.surahs = const [],
    this.badges = const [],
    this.reviews = const [],
  });

  final bool hasProgress;
  final int surahCount;
  final int extraAyahs;
  final List<ChildMemSurah> surahs;
  final List<ChildMemBadge> badges;
  final List<ChildMemReview> reviews;

  bool get isEmpty => !hasProgress;
}
