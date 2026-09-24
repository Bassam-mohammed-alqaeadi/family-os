import 'package:flutter/foundation.dart';

/// Subject row on SCR-CHD-012 materials list.
enum ChildLearnSubjectKind { math, quran, english }

/// Trailing chip style on a material row.
enum ChildLearnMaterialTag {
  /// Prototype «جديد».
  neu,

  /// Progress percent chip (prototype «٧٠٪»).
  progress,

  /// Chevron-only (prototype end arrow).
  chevron,
}

@immutable
final class ChildLearnMaterialRow {
  const ChildLearnMaterialRow({
    required this.id,
    required this.kind,
    required this.titleKey,
    required this.subtitleKey,
    required this.tag,
    this.progressPercent,
    this.ctaScreenId,
  });

  final String id;
  final ChildLearnSubjectKind kind;
  final String titleKey;
  final String subtitleKey;
  final ChildLearnMaterialTag tag;

  /// Used when [tag] is [ChildLearnMaterialTag.progress].
  final int? progressPercent;

  /// Optional navigation target (e.g. SCR-CHD-013 for math).
  final String? ctaScreenId;
}

@immutable
final class ChildLearnChallenge {
  const ChildLearnChallenge({
    required this.titleKey,
    required this.rewardMinutes,
    required this.ctaScreenId,
  });

  final String titleKey;

  /// Minutes-only reward (ع-١) — never points/XP coins.
  final int rewardMinutes;
  final String ctaScreenId;
}

@immutable
final class ChildLearnHomeSnapshot {
  const ChildLearnHomeSnapshot({
    this.level = 0,
    this.levelTitleKey,
    this.minutesEarnedThisMonth = 0,
    this.levelProgressPercent = 0,
    this.streakDays = 0,
    this.freeTime = false,
    this.challenge,
    this.materials = const [],
  });

  final int level;

  /// ARB discriminator — e.g. `explorer`.
  final String? levelTitleKey;
  final int minutesEarnedThisMonth;
  final int levelProgressPercent;
  final int streakDays;

  /// Prototype «وقته مجاني» chip.
  final bool freeTime;
  final ChildLearnChallenge? challenge;
  final List<ChildLearnMaterialRow> materials;

  bool get isEmpty =>
      levelTitleKey == null && materials.isEmpty && challenge == null;
}
