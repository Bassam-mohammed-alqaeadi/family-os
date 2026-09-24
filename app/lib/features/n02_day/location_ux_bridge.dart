import 'package:flutter/foundation.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/fs_foundation/capability_registry.dart';
import 'package:family_os/core/fs_foundation/capability_status.dart';
import 'package:family_os/core/fs_foundation/fs_session_kernel.dart';
import 'package:family_os/core/fs_foundation/local_database.dart';
import 'package:family_os/core/location/geo_point.dart';
import 'package:family_os/core/location/geofence_event.dart';
import 'package:family_os/core/location/location_fix.dart';
import 'package:family_os/core/location/location_repository.dart';
import 'package:family_os/core/location/location_store.dart';
import 'package:family_os/core/location/modes_location_fact_feed.dart';
import 'package:family_os/core/location/safe_zone_definition.dart';
import 'package:family_os/core/modes/modes_runtime.dart';
import 'package:family_os/features/n02_day/location_history_repository.dart';
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
          alertsEnabled: z.alertEnter || z.alertExit || z.alertNoShow,
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
  Future<void> setAlertsEnabled(String zoneId, bool enabled) async {
    final current = await domain.getZone(zoneId);
    if (current == null) {
      await listRepo?.setAlertsEnabled(zoneId, enabled);
      return;
    }
    await domain.saveZone(
      current.copyWith(
        alertEnter: enabled,
        alertExit: enabled,
        // Keep no-show as-is unless disabling all.
        alertNoShow: enabled ? current.alertNoShow : false,
        updatedAt: DateTime.now().toUtc(),
      ),
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
        alertsEnabled:
            definition.alertEnter ||
            definition.alertExit ||
            definition.alertNoShow,
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
