import 'package:flutter/foundation.dart';

@immutable
final class ChildLessonSnapshot {
  const ChildLessonSnapshot({
    this.titleKey,
    this.hookKey,
    this.bodyKey,
    this.progressPercent = 0,
    this.pizzaFilled = const [],
    this.nextScreenId = 'SCR-CHD-014',
    this.tutorScreenId = 'SCR-CHD-017',
    this.rewardMinutes = 10,
  });

  final String? titleKey;
  final String? hookKey;
  final String? bodyKey;
  final int progressPercent;

  /// True = filled slice (prototype 5 of 7).
  final List<bool> pizzaFilled;
  final String nextScreenId;
  final String tutorScreenId;
  final int rewardMinutes;

  bool get isEmpty => titleKey == null;
}
