import 'package:flutter/foundation.dart';

/// Pattern row status tag on SCR-FAT-062 (prototype anomaly / ok / watch).
enum FamilyPatternTag {
  /// Sleep delay — outside baseline (prototype «شذوذ»).
  anomaly,

  /// Stable communication (prototype «✓»).
  ok,

  /// Early signal — watch (prototype «راقب»).
  watch,

  /// Positive trend (prototype «📈»).
  improve,
}

/// Domain icon discriminator for a pattern row.
enum FamilyPatternDomain {
  sleep,
  communication,
  education,
  morningActivity,
}

@immutable
final class FamilyPatternRow {
  const FamilyPatternRow({
    required this.id,
    required this.domain,
    required this.titleKey,
    this.subtitleKey,
    required this.tag,
  });

  final String id;
  final FamilyPatternDomain domain;

  /// ARB discriminator for row headline.
  final String titleKey;

  /// Optional ARB discriminator for supporting line.
  final String? subtitleKey;
  final FamilyPatternTag tag;
}

@immutable
final class FamilyPatternChildCard {
  const FamilyPatternChildCard({
    required this.id,
    required this.nameKey,
    required this.confidencePercent,
    required this.patterns,
  });

  final String id;

  /// ARB discriminator — `childOne` / `childTwo` (Rule 23).
  final String nameKey;

  /// Displayed trust percentage (0–100) on the card seal.
  final int confidencePercent;
  final List<FamilyPatternRow> patterns;
}

@immutable
final class FamilyPatternsSnapshot {
  const FamilyPatternsSnapshot({
    this.children = const [],
    this.advisorConfidencePercent = 0,
  });

  final List<FamilyPatternChildCard> children;

  /// Always-visible advisor confidence on the banner (prototype spirit).
  final int advisorConfidencePercent;

  bool get isEmpty => children.isEmpty;
}
