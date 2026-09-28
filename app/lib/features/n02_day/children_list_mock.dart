import 'package:family_os/features/n02_day/children_list_repository.dart';
import 'package:family_os/features/n02_day/day_child_mock.dart';

/// Test / demo fixtures for SCR-FAT-012 — Rule 12 allowlisted (`*mock*.dart`).
///
/// Generic labels only (ابن 1/2/3). Never the screen default (Rule 23).
abstract final class ChildrenListMock {
  const ChildrenListMock._();

  static const List<ChildrenListEntry> manyFixture = [
    ChildrenListEntry(
      id: 'child_a',
      displayName: 'ابن 1',
      emoji: '🦁',
      swatch: DayChildSwatch.purple,
      ageYears: 14,
      locationLabel: 'المدرسة',
      lastSeenLabel: 'قبل 3 د',
      batteryLabel: '84٪',
      timeLeftLabel: '1 س 46 د',
      health: ChildListHealth.excellent,
    ),
    ChildrenListEntry(
      id: 'child_b',
      displayName: 'ابن 2',
      emoji: '🐱',
      swatch: DayChildSwatch.sky,
      ageYears: 11,
      locationLabel: 'المنزل',
      lastSeenLabel: 'قبل 9 د',
      batteryLabel: '32٪',
      timeLeftLabel: '45 د',
      health: ChildListHealth.atRisk,
      warnRing: true,
    ),
    ChildrenListEntry(
      id: 'child_c',
      displayName: 'ابن 3',
      emoji: '🐼',
      swatch: DayChildSwatch.amber,
      ageYears: 8,
      locationLabel: 'بيت الجد',
      lastSeenLabel: 'قبل دقيقة',
      batteryLabel: '67٪',
      timeLeftLabel: '2 س 10 د',
      health: ChildListHealth.excellent,
    ),
  ];

  /// Demo shared-policies seed (Family Link / Qustodio-style sheet).
  static const SharedChildrenPolicies defaultPolicies = SharedChildrenPolicies(
    bedtimeLabel: '9:30 م',
  );
}
