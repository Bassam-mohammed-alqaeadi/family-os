import 'package:flutter/foundation.dart';

/// One family-approved safe zone (prototype `S.safeZones` row).
@immutable
final class SafeZone {
  const SafeZone({
    required this.id,
    required this.emoji,
    required this.name,
    required this.description,
    this.alertsEnabled = true,
    this.assignedChildIds = const [],
  });

  final String id;
  final String emoji;
  final String name;
  final String description;
  final bool alertsEnabled;

  /// Explicit assignment list (Q-LOC-12=B) — empty on legacy Stage-1 rows.
  final List<String> assignedChildIds;

  SafeZone copyWith({
    String? id,
    String? emoji,
    String? name,
    String? description,
    bool? alertsEnabled,
    List<String>? assignedChildIds,
  }) {
    return SafeZone(
      id: id ?? this.id,
      emoji: emoji ?? this.emoji,
      name: name ?? this.name,
      description: description ?? this.description,
      alertsEnabled: alertsEnabled ?? this.alertsEnabled,
      assignedChildIds: assignedChildIds ?? this.assignedChildIds,
    );
  }
}

/// Family safe-zones list snapshot (SCR-FAT-016).
@immutable
final class SafeZonesSnapshot {
  const SafeZonesSnapshot({required this.zones});

  final List<SafeZone> zones;

  bool get isEmpty => zones.isEmpty;
}

/// Rule 25 seam — safe zones for SCR-FAT-016/017 (no Firebase; Drift later).
abstract class SafeZonesRepository {
  Future<SafeZonesSnapshot> load();

  /// Persist arrival/departure alert toggle for [zoneId]. No-op if unknown.
  Future<void> setAlertsEnabled(String zoneId, bool enabled);

  /// Append a newly drawn zone (SCR-FAT-017 → FAT-016 list).
  Future<void> add(SafeZone zone);
}

/// In-memory mock — empty until tests/repos seed (Rule 23).
final class InMemorySafeZonesRepository implements SafeZonesRepository {
  InMemorySafeZonesRepository({
    List<SafeZone> zones = const [],
    this.failLoad = false,
  }) : _zones = List.of(zones);

  List<SafeZone> _zones;

  /// Test seam — next [load] throws.
  bool failLoad;

  void seed(List<SafeZone> zones) {
    _zones = List.of(zones);
  }

  @override
  Future<SafeZonesSnapshot> load() async {
    if (failLoad) {
      throw StateError('mock safe zones load failure');
    }
    return SafeZonesSnapshot(zones: List.unmodifiable(_zones));
  }

  @override
  Future<void> setAlertsEnabled(String zoneId, bool enabled) async {
    final i = _zones.indexWhere((z) => z.id == zoneId);
    if (i < 0) return;
    _zones[i] = _zones[i].copyWith(alertsEnabled: enabled);
  }

  @override
  Future<void> add(SafeZone zone) async {
    _zones = [..._zones, zone];
  }
}

/// Stage-1 singleton — empty until tests/repos seed (Rule 23).
final stage1SafeZonesRepository = InMemorySafeZonesRepository();
