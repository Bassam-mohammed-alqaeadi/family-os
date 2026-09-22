import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;

import 'package:family_os/core/design/tokens.dart';

/// Schedule choices on SCR-FAT-045 (prototype FAT-045 select).
enum AttributionSchedule {
  tomorrowAfterSchool,
  today,
  weekend,
}

/// Avatar swatch from [FamilyColors] — no Color literals in fixtures.
enum AttributionChildSwatch { purple, sky, amber }

/// Reward kind — minutes only (owner ع-١ · zero points/XP).
enum AttributionRewardKind { wallet, play }

@immutable
final class AttributionChild {
  const AttributionChild({
    required this.id,
    required this.nameKey,
    required this.emoji,
    required this.swatch,
  });

  final String id;

  /// ARB discriminator — screen maps to localized generic label (Rule 23).
  final String nameKey;
  final String emoji;
  final AttributionChildSwatch swatch;

  Color resolveColor(FamilyColors colors) => switch (swatch) {
        AttributionChildSwatch.purple => colors.p500,
        AttributionChildSwatch.sky => colors.sky,
        AttributionChildSwatch.amber => colors.amber,
      };
}

@immutable
final class AttributionRewardToggle {
  const AttributionRewardToggle({
    required this.id,
    required this.kind,
    required this.minutes,
    required this.enabled,
    this.autoAdded = false,
  });

  final String id;
  final AttributionRewardKind kind;
  final int minutes;
  final bool enabled;

  /// Prototype: play minutes «تُضاف تلقائيًا».
  final bool autoAdded;

  AttributionRewardToggle copyWith({bool? enabled}) {
    return AttributionRewardToggle(
      id: id,
      kind: kind,
      minutes: minutes,
      enabled: enabled ?? this.enabled,
      autoAdded: autoAdded,
    );
  }
}

@immutable
final class AttributionRewardSnapshot {
  const AttributionRewardSnapshot({
    this.children = const [],
    this.selectedChildId,
    this.schedule = AttributionSchedule.tomorrowAfterSchool,
    this.rewards = const [],
    this.masteryPercent = 80,
    this.assigned = false,
  });

  final List<AttributionChild> children;
  final String? selectedChildId;
  final AttributionSchedule schedule;
  final List<AttributionRewardToggle> rewards;
  final int masteryPercent;
  final bool assigned;

  bool get isEmpty => children.isEmpty;

  AttributionChild? get selectedChild {
    final id = selectedChildId;
    if (id == null) return null;
    for (final c in children) {
      if (c.id == id) return c;
    }
    return null;
  }

  int get totalEnabledMinutes {
    var sum = 0;
    for (final r in rewards) {
      if (r.enabled) sum += r.minutes;
    }
    return sum;
  }

  bool get canAssign =>
      !assigned && selectedChild != null && totalEnabledMinutes > 0;

  AttributionRewardSnapshot withSelectedChild(String childId) {
    return AttributionRewardSnapshot(
      children: children,
      selectedChildId: childId,
      schedule: schedule,
      rewards: rewards,
      masteryPercent: masteryPercent,
      assigned: assigned,
    );
  }

  AttributionRewardSnapshot withSchedule(AttributionSchedule next) {
    return AttributionRewardSnapshot(
      children: children,
      selectedChildId: selectedChildId,
      schedule: next,
      rewards: rewards,
      masteryPercent: masteryPercent,
      assigned: assigned,
    );
  }

  AttributionRewardSnapshot withRewardEnabled(String rewardId, bool enabled) {
    return AttributionRewardSnapshot(
      children: children,
      selectedChildId: selectedChildId,
      schedule: schedule,
      rewards: [
        for (final r in rewards)
          if (r.id == rewardId) r.copyWith(enabled: enabled) else r,
      ],
      masteryPercent: masteryPercent,
      assigned: assigned,
    );
  }

  AttributionRewardSnapshot withAssigned() {
    return AttributionRewardSnapshot(
      children: children,
      selectedChildId: selectedChildId,
      schedule: schedule,
      rewards: rewards,
      masteryPercent: masteryPercent,
      assigned: true,
    );
  }
}
