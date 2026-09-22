import 'package:family_os/features/n02_day/child_profile_repository.dart';
import 'package:family_os/features/n02_day/children_list_repository.dart';
import 'package:family_os/features/n02_day/day_child_mock.dart';

/// Test / demo fixtures for SCR-FAT-013 — Rule 12 allowlisted (`*mock*.dart`).
///
/// Generic labels only (ابن ١/٢/٣). Never the screen default (Rule 23).
abstract final class ChildProfileMock {
  const ChildProfileMock._();

  static const ChildProfile childA = ChildProfile(
    id: 'child_a',
    displayName: 'ابن ١',
    emoji: '🦁',
    swatch: DayChildSwatch.purple,
    ageYears: 14,
    locationLabel: 'المدرسة',
    lastSeenLabel: 'قبل ٣ د',
    batteryLabel: '٨٤٪',
    walletLabel: '٤٥ د',
    todayUsedLabel: '٢ س ١٤ د',
    todayCapLabel: '٤ س',
    lastHeartbeatLabel: 'قبل دقيقتين',
    health: ChildListHealth.excellent,
  );

  static const ChildProfile childB = ChildProfile(
    id: 'child_b',
    displayName: 'ابن ٢',
    emoji: '🐱',
    swatch: DayChildSwatch.sky,
    ageYears: 11,
    locationLabel: 'المنزل',
    lastSeenLabel: 'قبل ٩ د',
    batteryLabel: '٣٢٪',
    walletLabel: '٢٠ د',
    todayUsedLabel: '٣ س ٠٥ د',
    todayCapLabel: '٤ س',
    lastHeartbeatLabel: 'قبل ٩ د',
    health: ChildListHealth.atRisk,
    warnRing: true,
  );

  static const List<ChildProfile> manyFixture = [childA, childB];
}
