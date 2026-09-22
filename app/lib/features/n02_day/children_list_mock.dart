import 'package:family_os/features/n02_day/children_list_repository.dart';
import 'package:family_os/features/n02_day/day_child_mock.dart';

/// Test / demo fixtures for SCR-FAT-012 — Rule 12 allowlisted (`*mock*.dart`).
///
/// Generic labels only (ابن ١/٢/٣). Never the screen default (Rule 23).
abstract final class ChildrenListMock {
  const ChildrenListMock._();

  static const List<ChildrenListEntry> manyFixture = [
    ChildrenListEntry(
      id: 'child_a',
      displayName: 'ابن ١',
      emoji: '🦁',
      swatch: DayChildSwatch.purple,
      ageYears: 14,
      locationLabel: 'المدرسة',
      lastSeenLabel: 'قبل ٣ د',
      batteryLabel: '٨٤٪',
      timeLeftLabel: '١ س ٤٦ د',
      health: ChildListHealth.excellent,
    ),
    ChildrenListEntry(
      id: 'child_b',
      displayName: 'ابن ٢',
      emoji: '🐱',
      swatch: DayChildSwatch.sky,
      ageYears: 11,
      locationLabel: 'المنزل',
      lastSeenLabel: 'قبل ٩ د',
      batteryLabel: '٣٢٪',
      timeLeftLabel: '٤٥ د',
      health: ChildListHealth.atRisk,
      warnRing: true,
    ),
    ChildrenListEntry(
      id: 'child_c',
      displayName: 'ابن ٣',
      emoji: '🐼',
      swatch: DayChildSwatch.amber,
      ageYears: 8,
      locationLabel: 'بيت الجد',
      lastSeenLabel: 'قبل دقيقة',
      batteryLabel: '٦٧٪',
      timeLeftLabel: '٢ س ١٠ د',
      health: ChildListHealth.excellent,
    ),
  ];

  /// Demo shared-policies seed (Family Link / Qustodio-style sheet).
  static const SharedChildrenPolicies defaultPolicies = SharedChildrenPolicies(
    bedtimeLabel: '٩:٣٠ م',
  );
}
