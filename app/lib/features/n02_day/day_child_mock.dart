import 'package:flutter/material.dart';

import 'package:family_os/core/design/tokens.dart';

/// Avatar swatch resolved from [FamilyColors] (no Color literals here).
enum DayChildSwatch { purple, sky, amber }

/// Pulse-ring state projected onto SCR-FAT-010 avatars (never planted by widgets).
enum DayChildPulseStatus { calm, attention, alert }

/// Child row projected onto SCR-FAT-010 — values come from repos, not widgets.
///
/// UI-004 / Rule 23: never plant person names (خالد/عبدالله/نوال) or sample
/// numerals in the screen default. Use [manyFixture] only in tests for the
/// one/many branch.
@immutable
class DayChildMock {
  const DayChildMock({
    required this.id,
    required this.displayName,
    required this.emoji,
    required this.swatch,
    required this.ageYears,
    required this.locationLabel,
    required this.batteryLabel,
    required this.timeLeftLabel,
    required this.quranLabel,
    required this.walletLabel,
    this.pulseStatus = DayChildPulseStatus.calm,
    this.timeLeftRatio,
  });

  final String id;
  final String displayName;
  final String emoji;
  final DayChildSwatch swatch;
  final int ageYears;
  final String locationLabel;
  final String batteryLabel;
  final String timeLeftLabel;
  final String quranLabel;
  final String walletLabel;

  /// Status halo for [StatusPulseAvatar] — default calm when unbound.
  final DayChildPulseStatus pulseStatus;

  /// Optional 0..1 remaining-time ratio for [MintProgressBar]; null = hide bar.
  final double? timeLeftRatio;

  Color resolveColor(FamilyColors colors) => switch (swatch) {
    DayChildSwatch.purple => colors.p500,
    DayChildSwatch.sky => colors.sky,
    DayChildSwatch.amber => colors.amber,
  };

  /// Test / demo fixture for the **many** branch — not the screen default.
  ///
  /// Generic labels only (ابن 1/2/3). Callers must inject via projection.
  static const List<DayChildMock> manyFixture = [
    DayChildMock(
      id: 'child_a',
      displayName: 'ابن 1',
      emoji: '🦁',
      swatch: DayChildSwatch.purple,
      ageYears: 14,
      locationLabel: 'المدرسة',
      batteryLabel: '84٪',
      timeLeftLabel: '1 س 20 د',
      quranLabel: '50٪',
      walletLabel: '45 د',
    ),
    DayChildMock(
      id: 'child_b',
      displayName: 'ابن 2',
      emoji: '🐱',
      swatch: DayChildSwatch.sky,
      ageYears: 11,
      locationLabel: 'المنزل',
      batteryLabel: '62٪',
      timeLeftLabel: '2 س',
      quranLabel: '30٪',
      walletLabel: '20 د',
    ),
    DayChildMock(
      id: 'child_c',
      displayName: 'ابن 3',
      emoji: '🐼',
      swatch: DayChildSwatch.amber,
      ageYears: 8,
      locationLabel: 'الحديقة',
      batteryLabel: '91٪',
      timeLeftLabel: '45 د',
      quranLabel: '10٪',
      walletLabel: '15 د',
    ),
  ];

  /// Alias for older tests — prefer [manyFixture]; screen defaults empty.
  static const List<DayChildMock> genericDefaults = manyFixture;
}
