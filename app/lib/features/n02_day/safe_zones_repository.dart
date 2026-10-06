import 'package:flutter/foundation.dart';

import 'package:family_os/core/location/zone_geometry.dart';

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

/// One boundary as the server needs it to draw one: geometry included.
///
/// The list DTO carries no geometry because the list only ever renders names and flags. A
/// write does need it, and a write that carried only a name would be a write that could not
/// tell a circle from a polygon - so the draft is its own type rather than a nullable
/// extension of [SafeZone].
@immutable
final class SafeZoneDraft {
  const SafeZoneDraft({
    required this.name,
    required this.emoji,
    required this.geometry,
    required this.assignedChildIds,
    required this.alertEnter,
    required this.alertExit,
  });

  final String name;
  final String emoji;
  final ZoneGeometry geometry;
  final List<String> assignedChildIds;
  final bool alertEnter;
  final bool alertExit;
}

/// The write half of a zone authority that lives on the server.
///
/// Null in a build with no server configured: the local Stage-1 path stays the authority
/// then, and that is a state the screens can state plainly instead of pretending.
abstract interface class SafeZoneServerWriter {
  Future<void> createZone(SafeZoneDraft draft);

  /// Turns one or both announcement flags over. The boundary and the assignment are not
  /// writable here on purpose: a boundary that moves is a different boundary to anyone an
  /// arrival was already reported about.
  Future<void> updateAlerts(
    String zoneId, {
    bool? alertEnter,
    bool? alertExit,
  });
}

/// Bound by the composition root when - and only when - a server is configured.
SafeZoneServerWriter? activeSafeZoneServerWriter;

/// Rule 25 seam — safe zones for SCR-FAT-016/017 (no Firebase; Drift later).
abstract class SafeZonesRepository {
  Future<SafeZonesSnapshot> load();

  /// Whether this repository can store the missed-deadline flag.
  ///
  /// The server records the two transitions a family actually crosses - entering and
  /// leaving - and a missed-deadline alert is neither of them. A surface bound to a
  /// repository that answers false must not offer the switch: a switch that stores nothing
  /// reads as protection and evaluates as nothing, which is the false safety state this
  /// whole pack exists to refuse.
  bool get storesNoShowAlert => true;

  /// Whether the rows come from the family's server rather than from this handset.
  ///
  /// The distinction is not cosmetic: a screen that can say which authority is answering
  /// can also refuse to present a local list as if it were the family's shared one.
  bool get isRemoteAuthority => false;

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
