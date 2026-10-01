import 'package:flutter/foundation.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/fs_foundation/capability_registry.dart';
import 'package:family_os/core/fs_foundation/capability_status.dart';
import 'package:family_os/core/fs_foundation/fs_session_kernel.dart';
import 'package:family_os/core/fs_foundation/local_database.dart';
import 'package:family_os/core/identity/identity_runtime.dart';
import 'package:family_os/core/identity/roster_children.dart';
import 'package:family_os/core/location/geo_point.dart';
import 'package:family_os/core/location/geofence_event.dart';
import 'package:family_os/core/location/location_fix.dart';
import 'package:family_os/core/location/location_repository.dart';
import 'package:family_os/core/location/location_store.dart';
import 'package:family_os/core/location/modes_location_fact_feed.dart';
import 'package:family_os/core/location/safe_zone_definition.dart';
import 'package:family_os/core/modes/modes_runtime.dart';
import 'package:family_os/features/n02_day/children_list_repository.dart';
import 'package:family_os/features/n02_day/location_history_repository.dart';
import 'package:family_os/features/n02_day/location_map_repository.dart';
import 'package:family_os/features/n02_day/location_real_local_seed_mock.dart';
import 'package:family_os/features/n02_day/safe_zones_repository.dart';

/// Stage-1 composition root for FS-001 UX (shared [FsSessionKernel] DB).
final class Stage1LocationRuntime {
  Stage1LocationRuntime._();

  static FamilyLocalDatabase get db => FsSessionKernel.db;
  static LocalLocationStore? _store;
  static ModesLocationFactFeed? _modesFeed;
  static CapabilityRegistry? _capabilities;
  static var _opened = false;

  static Future<void> ensureOpen() async {
    if (_opened) return;
    await FsSessionKernel.ensureOpen();
    // Modes feed must share the same DB so ENTER/EXIT facts are visible.
    await Stage1ModesRuntime.ensureOpen();
    _store = LocalLocationStore(db);
    _modesFeed = Stage1ModesRuntime.locationFacts;
    _capabilities = CapabilityRegistry(db);
    await _capabilities!.applyFs001XsysCapabilities();
    _opened = true;
  }

  static LocationDomainRepository get store {
    final s = _store;
    if (s == null) {
      throw StateError('Call Stage1LocationRuntime.ensureOpen() first');
    }
    return s;
  }

  static ModesLocationFactFeed get modesFactFeed {
    final f = _modesFeed;
    if (f == null) {
      throw StateError('Call Stage1LocationRuntime.ensureOpen() first');
    }
    return f;
  }

  static CapabilityRegistry get capabilities {
    final c = _capabilities;
    if (c == null) {
      throw StateError('Call Stage1LocationRuntime.ensureOpen() first');
    }
    return c;
  }

  /// Evaluate [fix] against active assigned zones; publish Modes facts.
  static Future<List<GeofenceEvent>> evaluateFixAcrossZones({
    required LocationFix fix,
  }) async {
    await ensureOpen();
    final zones = await _store!.listZones(fix.familyId);
    final events = <GeofenceEvent>[];
    var i = 0;
    for (final zone in zones) {
      if (!zone.active || zone.archived) continue;
      if (!zone.assignedChildIds.contains(fix.childId)) continue;
      final event = await _store!.evaluateAndRecord(
        zone: zone,
        fix: fix,
        eventId: 'eval_${fix.recordedAt.toUtc().millisecondsSinceEpoch}_$i',
        modesFeed: _modesFeed,
      );
      i += 1;
      if (event != null) events.add(event);
    }
    return events;
  }

  /// Clears this runtime only — does not close [FsSessionKernel].
  static void resetForTest() {
    _opened = false;
    _store = null;
    _modesFeed = null;
    _capabilities = null;
  }
}

/// Child option for zone assignment UI (Q-LOC-12=B).
@immutable
final class AssignableChild {
  const AssignableChild({required this.id, required this.label});

  final String id;

  /// Display label from parent roster — not planted in widgets beyond this DTO.
  final String label;
}

/// Projects [LocationDomainRepository] zones into Stage-1 [SafeZonesRepository].
final class DomainSafeZonesRepository implements SafeZonesRepository {
  DomainSafeZonesRepository({
    required this.domain,
    required this.familyId,
    this.listRepo,
  });

  final LocationDomainRepository domain;
  final FamilyId familyId;

  /// Optional Stage-1 list mirror for legacy UI fields (emoji/description).
  final InMemorySafeZonesRepository? listRepo;

  @override
  Future<SafeZonesSnapshot> load() async {
    final zones = await domain.listZones(familyId);
    final mapped = <SafeZone>[];
    for (final z in zones) {
      if (z.archived) continue;
      final assignCount = z.assignedChildIds.length;
      mapped.add(
        SafeZone(
          id: z.id,
          emoji: z.emoji,
          name: z.name,
          description: 'assigned:$assignCount',
          alertEnter: z.alertEnter,
          alertExit: z.alertExit,
          alertNoShow: z.alertNoShow,
          noShowDeadlineMinutes: z.noShowDeadlineMinutes,
          assignedChildIds: [for (final c in z.assignedChildIds) c.value],
        ),
      );
    }
    // Merge any Stage-1-only zones (tests / transitional).
    if (listRepo != null) {
      final legacy = await listRepo!.load();
      for (final z in legacy.zones) {
        if (mapped.any((m) => m.id == z.id)) continue;
        mapped.add(z);
      }
    }
    return SafeZonesSnapshot(zones: mapped);
  }

  @override
  Future<void> setAlertFlag(
    String zoneId, {
    bool? alertEnter,
    bool? alertExit,
    bool? alertNoShow,
  }) async {
    final current = await domain.getZone(zoneId);
    if (current == null) {
      await listRepo?.setAlertFlag(
        zoneId,
        alertEnter: alertEnter,
        alertExit: alertExit,
        alertNoShow: alertNoShow,
      );
      return;
    }
    final clearDeadline = alertNoShow == false;
    await domain.saveZone(
      current.copyWith(
        alertEnter: alertEnter,
        alertExit: alertExit,
        alertNoShow: alertNoShow,
        clearNoShowDeadline: clearDeadline,
        updatedAt: DateTime.now().toUtc(),
      ),
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
    // Legacy add without geometry — keep listRepo only.
    await listRepo?.add(zone);
  }

  /// Full domain save used by FAT-017 after draw.
  Future<void> saveDefinition(SafeZoneDefinition definition) async {
    await domain.saveZone(definition);
    await listRepo?.add(
      SafeZone(
        id: definition.id,
        emoji: definition.emoji,
        name: definition.name,
        description: 'assigned:${definition.assignedChildIds.length}',
        alertEnter: definition.alertEnter,
        alertExit: definition.alertExit,
        alertNoShow: definition.alertNoShow,
        noShowDeadlineMinutes: definition.noShowDeadlineMinutes,
        assignedChildIds: [
          for (final c in definition.assignedChildIds) c.value,
        ],
      ),
    );
  }
}

/// Trail → history days projection (90d domain trail).
final class DomainLocationHistoryRepository
    implements LocationHistoryRepository {
  DomainLocationHistoryRepository({
    required this.domain,
    required this.familyId,
    this.displayNameFor,
  });

  final LocationDomainRepository domain;
  final FamilyId familyId;
  final String Function(String childId)? displayNameFor;

  @override
  Future<LocationHistorySnapshot?> load(String childId) async {
    final trimmed = childId.trim();
    if (trimmed.isEmpty) return null;
    final child = ChildId(trimmed);
    final fixes = await domain.listTrail(familyId, child, limit: 48);
    if (fixes.isEmpty) {
      return LocationHistorySnapshot(
        childId: trimmed,
        displayName: displayNameFor?.call(trimmed) ?? trimmed,
        days: const [],
      );
    }

    final byDay = <String, List<LocationHistoryStop>>{};
    for (final fix in fixes) {
      final dayKey = fix.recordedAt.toUtc().toIso8601String().substring(0, 10);
      final title = switch (fix.acquisition) {
        LocationAcquisitionStatus.located => _coordLabel(fix.point),
        LocationAcquisitionStatus.staleLastKnown =>
          'STALE · ${_coordLabel(fix.point)}',
        LocationAcquisitionStatus.acquiring => 'ACQUIRING',
        LocationAcquisitionStatus.unavailable => 'UNAVAILABLE',
      };
      final timeLabel =
          '${fix.recordedAt.toUtc().hour.toString().padLeft(2, '0')}:'
          '${fix.recordedAt.toUtc().minute.toString().padLeft(2, '0')}';
      byDay
          .putIfAbsent(dayKey, () => <LocationHistoryStop>[])
          .add(LocationHistoryStop(title: title, timeLabel: timeLabel));
    }

    final days = byDay.entries
        .map(
          (e) => LocationHistoryDay(id: e.key, heading: e.key, stops: e.value),
        )
        .toList();

    return LocationHistorySnapshot(
      childId: trimmed,
      displayName: displayNameFor?.call(trimmed) ?? trimmed,
      days: days,
    );
  }

  static String _coordLabel(GeoPoint? p) {
    if (p == null) return '—';
    return '${p.latitude.toStringAsFixed(4)}, ${p.longitude.toStringAsFixed(4)}';
  }
}

/// LDR-B1 — map UX from roster + `loc_*` zones (no fabricated GPS pins).
final class DomainLocationMapRepository implements LocationMapRepository {
  DomainLocationMapRepository({
    required this.domain,
    FamilyId? familyId,
    ChildrenListRepository? children,
  })  : _familyIdOverride = familyId,
        _children = children;

  final LocationDomainRepository domain;
  final FamilyId? _familyIdOverride;
  final ChildrenListRepository? _children;

  FamilyId get _familyId =>
      _familyIdOverride ??
      stage1IdentityRuntime.activeFamilyId;

  ChildrenListRepository get _roster =>
      _children ?? stage1ChildrenListRepository;

  @override
  Future<LocationMapSnapshot?> load({String? focusChildId}) async {
    await Stage1LocationRuntime.ensureOpen();
    final kids = await _roster.listChildren(familyId: _familyId);
    final zones = await domain.listZones(_familyId);

    final pins = <LocationMapPin>[];
    for (var i = 0; i < kids.length; i++) {
      final k = kids[i];
      final row = i ~/ 2;
      final col = i % 2;
      pins.add(
        LocationMapPin(
          id: k.id,
          displayName: k.displayName,
          emoji: k.emoji,
          swatch: k.swatch,
          locationLabel: k.locationLabel,
          lastSeenLabel: k.lastSeenLabel,
          batteryLabel: k.batteryLabel,
          xFraction: 0.28 + col * 0.36,
          yFraction: 0.28 + row * 0.28,
          batteryWarn: false,
          networkClass: LocationNetworkClass.unavailable,
        ),
      );
    }

    final mapZones = <LocationMapZone>[];
    for (var i = 0; i < zones.length; i++) {
      final z = zones[i];
      if (z.archived || !z.active) continue;
      mapZones.add(
        LocationMapZone(
          id: z.id,
          xFraction: 0.22 + (i % 3) * 0.25,
          yFraction: 0.35 + (i ~/ 3) * 0.2,
          diameterFraction: 0.22,
          purpleTint: i.isOdd,
        ),
      );
    }

    final trimmed = focusChildId?.trim();
    final hasFocus = trimmed != null && trimmed.isNotEmpty;
    if (pins.isEmpty) {
      if (hasFocus) return null;
      return LocationMapSnapshot(pins: const [], zones: mapZones);
    }
    if (hasFocus) {
      final match = pins.where((p) => p.id == trimmed).toList();
      if (match.isEmpty) return null;
      final focus = match.first;
      return LocationMapSnapshot(
        pins: List.unmodifiable(pins),
        zones: List.unmodifiable(mapZones),
        focusChildId: focus.id,
        focusDisplayName: focus.displayName,
        threadStops: const [],
      );
    }
    final first = pins.first;
    return LocationMapSnapshot(
      pins: List.unmodifiable(pins),
      zones: List.unmodifiable(mapZones),
      focusChildId: first.id,
      focusDisplayName: first.displayName,
      threadStops: const [],
    );
  }
}

/// Boot-once: rebind FAT-014/015/016 stage1 repos to domain adapters (LDR-B1/B2).
Future<void> tryBindStage1LocationUx() async {
  try {
    await Stage1LocationRuntime.ensureOpen();
    if (FsSessionKernel.sqliteFallbackToMemory) return;
    final domain = Stage1LocationRuntime.store;
    final familyId = stage1IdentityRuntime.activeFamilyId;
    await ensureRealLocalSafeZonesSeeded(domain: domain, familyId: familyId);
    rebindStage1LocationMapRepository(
      DomainLocationMapRepository(domain: domain, familyId: familyId),
    );
    rebindStage1LocationHistoryRepository(
      DomainLocationHistoryRepository(
        domain: domain,
        familyId: familyId,
        displayNameFor: (id) => id,
      ),
    );
    rebindStage1SafeZonesRepository(
      DomainSafeZonesRepository(domain: domain, familyId: familyId),
    );
  } catch (e, st) {
    debugPrint('LDR tryBindStage1LocationUx soft-fail: $e\n$st');
  }
}

/// LDR-B2 — zone definitions only (no trail/GPS samples). Idempotent.
Future<void> ensureRealLocalSafeZonesSeeded({
  required LocationDomainRepository domain,
  required FamilyId familyId,
}) async {
  final existing = await domain.listZones(familyId);
  if (existing.isNotEmpty) return;
  final now = DateTime.now().toUtc();
  final kids = await stage1ChildrenListRepository.listChildren(
    familyId: familyId,
  );
  final childIds = [
    for (final k in kids.take(2)) ChildId(k.id),
  ];
  final assigned = childIds.isNotEmpty
      ? childIds
      : activeFamilyRosterChildren().take(2).map((child) => child.id).toList();

  for (final zone in realLocalSafeZoneSeedMock(
    familyId: familyId,
    assignedChildIds: assigned,
    now: now,
  )) {
    await domain.saveZone(zone);
  }
}

/// Silent Location Request result honesty (LOC-OD-08).
enum SilentLocateResultStatus {
  pending,
  located,
  staleLastKnown,
  unavailable,
  notImplementedGps,
}

@immutable
final class SilentLocateResult {
  const SilentLocateResult({
    required this.childId,
    required this.status,
    this.note,
  });

  final String childId;
  final SilentLocateResultStatus status;
  final String? note;
}

/// Parent silent locate — never invents GPS success.
abstract final class SilentLocateService {
  static Future<SilentLocateResult> request({
    required LocationDomainRepository domain,
    required FamilyId familyId,
    required ChildId childId,
    required CapabilityStatus nativeGpsStatus,
  }) async {
    if (nativeGpsStatus == CapabilityStatus.notImplemented ||
        nativeGpsStatus == CapabilityStatus.unsupported) {
      return SilentLocateResult(
        childId: childId.value,
        status: SilentLocateResultStatus.notImplementedGps,
        note: 'native_gps capability is ${nativeGpsStatus.wireName}',
      );
    }

    final latest = await domain.latestFix(familyId, childId);
    if (latest == null) {
      return SilentLocateResult(
        childId: childId.value,
        status: SilentLocateResultStatus.unavailable,
      );
    }
    return SilentLocateResult(
      childId: childId.value,
      status: switch (latest.acquisition) {
        LocationAcquisitionStatus.located => SilentLocateResultStatus.located,
        LocationAcquisitionStatus.staleLastKnown =>
          SilentLocateResultStatus.staleLastKnown,
        LocationAcquisitionStatus.acquiring => SilentLocateResultStatus.pending,
        LocationAcquisitionStatus.unavailable =>
          SilentLocateResultStatus.unavailable,
      },
    );
  }
}

/// Map fractional → approximate lat/lng for Stage-1 decorative canvas.
///
/// Not a GPS claim — used only so drawn zones persist as Domain geometry.
abstract final class DecorativeMapProjection {
  static const GeoPoint origin = GeoPoint(
    latitude: 24.7136,
    longitude: 46.6753,
  );

  /// ~1 fraction ≈ 0.01° (~1.1 km) — decorative scale only.
  static GeoPoint fromFraction(double x, double y) {
    return GeoPoint(
      latitude: origin.latitude + (0.5 - y) * 0.02,
      longitude: origin.longitude + (x - 0.5) * 0.02,
    );
  }
}
