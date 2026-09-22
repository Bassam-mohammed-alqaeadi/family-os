import 'package:flutter/material.dart';

import 'package:family_os/core/design/tokens.dart';

/// Avatar swatch resolved from [FamilyColors] (no Color literals here).
enum DayChildSwatch { purple, sky, amber }

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

  Color resolveColor(FamilyColors colors) => switch (swatch) {
        DayChildSwatch.purple => colors.p500,
        DayChildSwatch.sky => colors.sky,
        DayChildSwatch.amber => colors.amber,
      };

  /// Test / demo fixture for the **many** branch — not the screen default.
  ///
  /// Generic labels only (ابن ١/٢/٣). Callers must inject via projection.
  static const List<DayChildMock> manyFixture = [
    DayChildMock(
      id: 'child_a',
      displayName: 'ابن ١',
      emoji: '🦁',
      swatch: DayChildSwatch.purple,
      ageYears: 14,
      locationLabel: 'المدرسة',
      batteryLabel: '٨٤٪',
      timeLeftLabel: '١ س ٢٠ د',
      quranLabel: '٥٠٪',
      walletLabel: '٤٥ د',
    ),
    DayChildMock(
      id: 'child_b',
      displayName: 'ابن ٢',
      emoji: '🐱',
      swatch: DayChildSwatch.sky,
      ageYears: 11,
      locationLabel: 'المنزل',
      batteryLabel: '٦٢٪',
      timeLeftLabel: '٢ س',
      quranLabel: '٣٠٪',
      walletLabel: '٢٠ د',
    ),
    DayChildMock(
      id: 'child_c',
      displayName: 'ابن ٣',
      emoji: '🐼',
      swatch: DayChildSwatch.amber,
      ageYears: 8,
      locationLabel: 'الحديقة',
      batteryLabel: '٩١٪',
      timeLeftLabel: '٤٥ د',
      quranLabel: '١٠٪',
      walletLabel: '١٥ د',
    ),
  ];

  /// Alias for older tests — prefer [manyFixture]; screen defaults empty.
  static const List<DayChildMock> genericDefaults = manyFixture;
}
