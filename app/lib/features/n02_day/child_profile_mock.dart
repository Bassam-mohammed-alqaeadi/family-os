import 'package:family_os/features/n02_day/child_profile_repository.dart';
import 'package:family_os/features/n02_day/children_list_repository.dart';
import 'package:family_os/features/n02_day/day_child_mock.dart';

/// Test / demo fixtures for SCR-FAT-013 — Rule 12 allowlisted (`*mock*.dart`).
///
/// Generic labels only (ابن 1/2/3). Never the screen default (Rule 23).
abstract final class ChildProfileMock {
  const ChildProfileMock._();

  static const ChildProfile childA = ChildProfile(
    id: 'child_a',
    displayName: 'ابن 1',
    emoji: '🦁',
    swatch: DayChildSwatch.purple,
    ageYears: 14,
    locationLabel: 'المدرسة',
    lastSeenLabel: 'قبل 3 د',
    batteryLabel: '84٪',
    walletLabel: '45 د',
    todayUsedLabel: '2 س 14 د',
    todayCapLabel: '4 س',
    lastHeartbeatLabel: 'قبل دقيقتين',
    health: ChildListHealth.excellent,
  );

  static const ChildProfile childB = ChildProfile(
    id: 'child_b',
    displayName: 'ابن 2',
    emoji: '🐱',
    swatch: DayChildSwatch.sky,
    ageYears: 11,
    locationLabel: 'المنزل',
    lastSeenLabel: 'قبل 9 د',
    batteryLabel: '32٪',
    walletLabel: '20 د',
    todayUsedLabel: '3 س 05 د',
    todayCapLabel: '4 س',
    lastHeartbeatLabel: 'قبل 9 د',
    health: ChildListHealth.atRisk,
    warnRing: true,
  );

  static const List<ChildProfile> manyFixture = [childA, childB];
}
