import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';

import 'mode_overlay.dart';

/// Canonical built-in Mode catalog (MODE-OD-03).
///
/// `exams` is not a separate built-in — use [study].
/// `famtime` normalizes to [familyTime].
enum ModeCatalogId {
  sleep,
  school,
  study,
  ramadan,
  vacation,
  familyTime,
  custom,
}

extension ModeCatalogIdWire on ModeCatalogId {
  String get wireName => name;

  static ModeCatalogId parse(String raw) {
    final n = raw.trim().toLowerCase();
    return switch (n) {
      'sleep' => ModeCatalogId.sleep,
      'school' => ModeCatalogId.school,
      'study' || 'exams' => ModeCatalogId.study,
      'ramadan' => ModeCatalogId.ramadan,
      'vacation' => ModeCatalogId.vacation,
      'familytime' || 'famtime' || 'family_time' => ModeCatalogId.familyTime,
      'custom' => ModeCatalogId.custom,
      _ => ModeCatalogId.custom,
    };
  }
}

/// How a Mode targets children (MODE-OD-01).
enum ModeChildScopeKind {
  /// Explicitly all children in the family (not silent expansion).
  allChildren,

  /// Explicit selected child ids only.
  selectedChildren,
}

/// Clock window for lifestyle schedule (same-day minutes from midnight).
@immutable
final class ModeClockWindow {
  const ModeClockWindow({
    required this.startMinutes,
    required this.endMinutes,
    this.enabled = true,
  });

  final int startMinutes;
  final int endMinutes;
  final bool enabled;

  bool get isValid => enabled && endMinutes > startMinutes;

  bool containsMinutes(int minutesOfDay) {
    if (!isValid) return false;
    return minutesOfDay >= startMinutes && minutesOfDay < endMinutes;
  }

  Map<String, Object?> toJson() => {
    'startMinutes': startMinutes,
    'endMinutes': endMinutes,
    'enabled': enabled,
  };

  factory ModeClockWindow.fromJson(Map<String, Object?> json) {
    return ModeClockWindow(
      startMinutes: (json['startMinutes'] as num?)?.toInt() ?? 0,
      endMinutes: (json['endMinutes'] as num?)?.toInt() ?? 0,
      enabled: json['enabled'] as bool? ?? true,
    );
  }
}

/// Seasonal / date-range channel (MODE-OD-09).
@immutable
final class ModeSeasonRange {
  const ModeSeasonRange({required this.startUtc, required this.endUtc});

  final DateTime startUtc;
  final DateTime endUtc;

  bool contains(DateTime utc) {
    final t = utc.toUtc();
    return !t.isBefore(startUtc.toUtc()) && t.isBefore(endUtc.toUtc());
  }

  Map<String, Object?> toJson() => {
    'startUtc': startUtc.toUtc().millisecondsSinceEpoch,
    'endUtc': endUtc.toUtc().millisecondsSinceEpoch,
  };

  factory ModeSeasonRange.fromJson(Map<String, Object?> json) {
    return ModeSeasonRange(
      startUtc: DateTime.fromMillisecondsSinceEpoch(
        (json['startUtc'] as num?)?.toInt() ?? 0,
        isUtc: true,
      ),
      endUtc: DateTime.fromMillisecondsSinceEpoch(
        (json['endUtc'] as num?)?.toInt() ?? 0,
        isUtc: true,
      ),
    );
  }
}

/// Authoritative Mode definition (MODE-SF-05).
@immutable
final class ModeDefinition {
  factory ModeDefinition({
    required String id,
    required FamilyId familyId,
    required ModeCatalogId catalogId,
    String? customLabel,
    ModeChildScopeKind childScope = ModeChildScopeKind.allChildren,
    Set<ChildId>? targetChildIds,
    ModeClockWindow? clockWindow,
    String? locationZoneId,
    ModeSeasonRange? season,
    ModeOverlay overlay = const ModeOverlay(),
    int graceMinutes = 2,
    bool enabled = true,
    int policyVersion = 1,
    DateTime? updatedAt,
  }) {
    if (catalogId == ModeCatalogId.custom &&
        (customLabel == null || customLabel.trim().isEmpty)) {
      throw ArgumentError('custom Mode requires customLabel');
    }
    final targets = <ChildId>{...?targetChildIds};
    if (childScope == ModeChildScopeKind.selectedChildren && targets.isEmpty) {
      throw ArgumentError('selectedChildren requires at least one childId');
    }
    if (childScope == ModeChildScopeKind.allChildren && targets.isNotEmpty) {
      throw ArgumentError('allChildren must not set targetChildIds');
    }
    return ModeDefinition._(
      id: id.trim(),
      familyId: familyId,
      catalogId: catalogId,
      customLabel: customLabel?.trim(),
      childScope: childScope,
      targetChildIds: Set<ChildId>.unmodifiable(targets),
      clockWindow: clockWindow,
      locationZoneId: locationZoneId?.trim().isEmpty == true
          ? null
          : locationZoneId?.trim(),
      season: season,
      overlay: overlay.asTightenOnly(),
      graceMinutes: ModeOverlay.clampGrace(graceMinutes),
      enabled: enabled,
      policyVersion: policyVersion < 1 ? 1 : policyVersion,
      updatedAt:
          updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  const ModeDefinition._({
    required this.id,
    required this.familyId,
    required this.catalogId,
    required this.customLabel,
    required this.childScope,
    required this.targetChildIds,
    required this.clockWindow,
    required this.locationZoneId,
    required this.season,
    required this.overlay,
    required this.graceMinutes,
    required this.enabled,
    required this.policyVersion,
    required this.updatedAt,
  });

  final String id;
  final FamilyId familyId;
  final ModeCatalogId catalogId;
  final String? customLabel;
  final ModeChildScopeKind childScope;
  final Set<ChildId> targetChildIds;
  final ModeClockWindow? clockWindow;

  /// FS-001 zone id to consume ENTER facts — never a second geofence engine.
  final String? locationZoneId;
  final ModeSeasonRange? season;
  final ModeOverlay overlay;
  final int graceMinutes;
  final bool enabled;
  final int policyVersion;
  final DateTime updatedAt;

  bool targetsChild(ChildId childId) {
    return switch (childScope) {
      ModeChildScopeKind.allChildren => true,
      ModeChildScopeKind.selectedChildren => targetChildIds.contains(childId),
    };
  }

  ModeDefinition copyWith({
    String? customLabel,
    ModeChildScopeKind? childScope,
    Set<ChildId>? targetChildIds,
    ModeClockWindow? clockWindow,
    String? locationZoneId,
    ModeSeasonRange? season,
    ModeOverlay? overlay,
    int? graceMinutes,
    bool? enabled,
    int? policyVersion,
    DateTime? updatedAt,
    bool clearClock = false,
    bool clearLocationZone = false,
    bool clearSeason = false,
  }) {
    return ModeDefinition(
      id: id,
      familyId: familyId,
      catalogId: catalogId,
      customLabel: customLabel ?? this.customLabel,
      childScope: childScope ?? this.childScope,
      targetChildIds: targetChildIds ?? this.targetChildIds,
      clockWindow: clearClock ? null : (clockWindow ?? this.clockWindow),
      locationZoneId: clearLocationZone
          ? null
          : (locationZoneId ?? this.locationZoneId),
      season: clearSeason ? null : (season ?? this.season),
      overlay: overlay ?? this.overlay,
      graceMinutes: graceMinutes ?? this.graceMinutes,
      enabled: enabled ?? this.enabled,
      policyVersion: policyVersion ?? this.policyVersion,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toRow() => {
    'id': id,
    'family_id': familyId.value,
    'catalog_id': catalogId.wireName,
    'custom_label': customLabel,
    'child_scope': childScope.name,
    'target_children_json': jsonEncode(
      [for (final c in targetChildIds) c.value]..sort(),
    ),
    'clock_json': clockWindow == null
        ? null
        : jsonEncode(clockWindow!.toJson()),
    'location_zone_id': locationZoneId,
    'season_json': season == null ? null : jsonEncode(season!.toJson()),
    'overlay_json': jsonEncode(overlay.toJson()),
    'grace_minutes': graceMinutes,
    'enabled': enabled ? 1 : 0,
    'policy_version': policyVersion,
    'updated_at': updatedAt.toUtc().millisecondsSinceEpoch,
  };

  factory ModeDefinition.fromRow(Map<String, Object?> row) {
    final targets = <ChildId>{};
    final rawTargets = row['target_children_json'] as String? ?? '[]';
    final decoded = jsonDecode(rawTargets);
    if (decoded is List) {
      for (final v in decoded) {
        targets.add(ChildId(v.toString()));
      }
    }
    ModeClockWindow? clock;
    final clockRaw = row['clock_json'] as String?;
    if (clockRaw != null && clockRaw.isNotEmpty) {
      final m = jsonDecode(clockRaw);
      if (m is Map<String, Object?>) {
        clock = ModeClockWindow.fromJson(m);
      } else if (m is Map) {
        clock = ModeClockWindow.fromJson(Map<String, Object?>.from(m));
      }
    }
    ModeSeasonRange? season;
    final seasonRaw = row['season_json'] as String?;
    if (seasonRaw != null && seasonRaw.isNotEmpty) {
      final m = jsonDecode(seasonRaw);
      if (m is Map<String, Object?>) {
        season = ModeSeasonRange.fromJson(m);
      } else if (m is Map) {
        season = ModeSeasonRange.fromJson(Map<String, Object?>.from(m));
      }
    }
    ModeOverlay overlay = const ModeOverlay();
    final overlayRaw = row['overlay_json'] as String? ?? '{}';
    final om = jsonDecode(overlayRaw);
    if (om is Map<String, Object?>) {
      overlay = ModeOverlay.fromJson(om);
    } else if (om is Map) {
      overlay = ModeOverlay.fromJson(Map<String, Object?>.from(om));
    }
    final scopeName = row['child_scope'] as String? ?? 'allChildren';
    final scope = ModeChildScopeKind.values.firstWhere(
      (s) => s.name == scopeName,
      orElse: () => ModeChildScopeKind.allChildren,
    );
    return ModeDefinition(
      id: row['id'] as String? ?? 'mode',
      familyId: FamilyId(row['family_id'] as String? ?? 'fam'),
      catalogId: ModeCatalogIdWire.parse(
        row['catalog_id'] as String? ?? 'custom',
      ),
      customLabel: row['custom_label'] as String?,
      childScope: scope,
      targetChildIds: targets,
      clockWindow: clock,
      locationZoneId: row['location_zone_id'] as String?,
      season: season,
      overlay: overlay,
      graceMinutes: (row['grace_minutes'] as num?)?.toInt() ?? 2,
      enabled: (row['enabled'] as num?)?.toInt() != 0,
      policyVersion: (row['policy_version'] as num?)?.toInt() ?? 1,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        (row['updated_at'] as num?)?.toInt() ?? 0,
        isUtc: true,
      ),
    );
  }
}
