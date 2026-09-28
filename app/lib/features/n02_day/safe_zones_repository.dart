import 'package:flutter/foundation.dart';

/// One family-approved safe zone (prototype `S.safeZones` row).
@immutable
final class SafeZone {
  const SafeZone({
    required this.id,
    required this.emoji,
    required this.name,
    required this.description,
    this.alertEnter = true,
    this.alertExit = true,
    this.alertNoShow = false,
    this.noShowDeadlineMinutes,
    this.assignedChildIds = const [],
  });

  final String id;
  final String emoji;
  final String name;
  final String description;

  /// Arrive / enter alert (Super-App desk — FAT-016).
  final bool alertEnter;

  /// Leave / exit alert.
  final bool alertExit;

  /// Missed deadline / no-show alert.
  final bool alertNoShow;

  /// Minutes from local midnight when [alertNoShow] is armed (nullable).
  final int? noShowDeadlineMinutes;

  /// Explicit assignment list (Q-LOC-12=B) — empty on legacy Stage-1 rows.
  final List<String> assignedChildIds;

  /// Any alert armed (compat for older call sites).
  bool get alertsEnabled => alertEnter || alertExit || alertNoShow;

  SafeZone copyWith({
    String? id,
    String? emoji,
    String? name,
    String? description,
    bool? alertEnter,
    bool? alertExit,
    bool? alertNoShow,
    int? noShowDeadlineMinutes,
    bool clearNoShowDeadline = false,
    List<String>? assignedChildIds,
  }) {
    return SafeZone(
      id: id ?? this.id,
      emoji: emoji ?? this.emoji,
      name: name ?? this.name,
      description: description ?? this.description,
      alertEnter: alertEnter ?? this.alertEnter,
      alertExit: alertExit ?? this.alertExit,
      alertNoShow: alertNoShow ?? this.alertNoShow,
      noShowDeadlineMinutes: clearNoShowDeadline
          ? null
          : (noShowDeadlineMinutes ?? this.noShowDeadlineMinutes),
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

  /// Persist one alert flag for [zoneId]. No-op if unknown.
  Future<void> setAlertFlag(
    String zoneId, {
    bool? alertEnter,
    bool? alertExit,
    bool? alertNoShow,
  });

  /// Legacy master toggle — sets enter+exit together; clears no-show when off.
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
  Future<void> setAlertFlag(
    String zoneId, {
    bool? alertEnter,
    bool? alertExit,
    bool? alertNoShow,
  }) async {
    final i = _zones.indexWhere((z) => z.id == zoneId);
    if (i < 0) return;
    final clearDeadline = alertNoShow == false;
    _zones[i] = _zones[i].copyWith(
      alertEnter: alertEnter,
      alertExit: alertExit,
      alertNoShow: alertNoShow,
      clearNoShowDeadline: clearDeadline,
    );
  }

  @override
  Future<void> setAlertsEnabled(String zoneId, bool enabled) async {
    await setAlertFlag(
      zoneId,
      alertEnter: enabled,
      alertExit: enabled,
      alertNoShow: enabled ? null : false,
    );
  }

  @override
  Future<void> add(SafeZone zone) async {
    _zones = [..._zones, zone];
  }
}

/// Stage-1 singleton — rebound to Domain at boot (LDR-B2) when SQLite honest.
SafeZonesRepository stage1SafeZonesRepository = InMemorySafeZonesRepository();

void rebindStage1SafeZonesRepository(SafeZonesRepository repository) {
  stage1SafeZonesRepository = repository;
}
