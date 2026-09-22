import 'package:family_os/features/n02_day/safe_zones_repository.dart';

/// Test / demo fixtures for SCR-FAT-016 — Rule 12 allowlisted (`*mock*.dart`).
///
/// Generic place labels only. Never the screen default (Rule 23).
abstract final class SafeZonesMock {
  const SafeZonesMock._();

  static const List<SafeZone> familyZones = [
    SafeZone(
      id: 'z1',
      emoji: '🏫',
      name: 'المدرسة',
      description: 'ثانوية النور',
    ),
    SafeZone(
      id: 'z2',
      emoji: '🏡',
      name: 'المنزل',
      description: 'حي النرجس',
    ),
    SafeZone(
      id: 'z3',
      emoji: '👴',
      name: 'بيت الجد',
      description: 'حي الروضة',
    ),
    SafeZone(
      id: 'z4',
      emoji: '⚽',
      name: 'نادي الحي',
      description: 'الملعب الرياضي',
    ),
  ];

  static List<SafeZone> get seeded => List.of(familyZones);
}
