import 'package:family_os/features/n02_day/day_child_mock.dart';
import 'package:family_os/features/n02_day/location_map_repository.dart';

/// Test / demo fixtures for SCR-FAT-014 — Rule 12 allowlisted (`*mock*.dart`).
///
/// Generic labels only (ابن ١/٢/٣). Never the screen default (Rule 23).
abstract final class LocationMapMock {
  const LocationMapMock._();

  static const List<LocationMapZone> zonesFixture = [
    LocationMapZone(
      id: 'zone_school',
      xFraction: 0.68,
      yFraction: 0.28,
      diameterFraction: 0.36,
    ),
    LocationMapZone(
      id: 'zone_home',
      xFraction: 0.22,
      yFraction: 0.72,
      diameterFraction: 0.30,
      purpleTint: true,
    ),
  ];

  static const List<LocationMapPin> manyPins = [
    LocationMapPin(
      id: 'child_a',
      displayName: 'ابن ١',
      emoji: '🦁',
      swatch: DayChildSwatch.purple,
      locationLabel: 'ثانوية النور',
      lastSeenLabel: 'قبل ٣ د',
      batteryLabel: '٨٤٪',
      xFraction: 0.70,
      yFraction: 0.28,
      safeZoneLabel: 'المدرسة',
    ),
    LocationMapPin(
      id: 'child_b',
      displayName: 'ابن ٢',
      emoji: '🐱',
      swatch: DayChildSwatch.sky,
      locationLabel: 'المنزل',
      lastSeenLabel: 'قبل ٩ د',
      batteryLabel: '٣٢٪',
      xFraction: 0.22,
      yFraction: 0.72,
      batteryWarn: true,
    ),
    LocationMapPin(
      id: 'child_c',
      displayName: 'ابن ٣',
      emoji: '🐼',
      swatch: DayChildSwatch.amber,
      locationLabel: 'بيت الجد',
      lastSeenLabel: 'قبل دقيقة',
      batteryLabel: '٦٧٪',
      xFraction: 0.42,
      yFraction: 0.52,
    ),
  ];

  static const Map<String, List<LocationThreadStop>> threadsFixture = {
    'child_a': [
      LocationThreadStop(
        title: '🏫 ثانوية النور',
        timeLabel: '٧:١٢ ص حتى الآن · داخل منطقة آمنة',
        isCurrent: true,
      ),
      LocationThreadStop(
        title: '🚗 الطريق إلى المدرسة',
        timeLabel: '٦:٥٥ – ٧:١٢ ص · ١٧ دقيقة',
      ),
      LocationThreadStop(
        title: '🏠 المنزل',
        timeLabel: 'حتى ٦:٥٥ ص',
      ),
    ],
    'child_b': [
      LocationThreadStop(
        title: '🏠 المنزل',
        timeLabel: 'منذ الصباح · حتى الآن',
        isCurrent: true,
      ),
    ],
    'child_c': [
      LocationThreadStop(
        title: '🏡 بيت الجد',
        timeLabel: 'منذ الظهيرة · حتى الآن',
        isCurrent: true,
      ),
    ],
  };
}
