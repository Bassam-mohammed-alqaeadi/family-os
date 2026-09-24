import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';

import 'screen_camera_protected.dart';

/// Scope of a Screen & Camera policy document (SC-OD-12).
enum ScreenCameraScopeKind { familyBaseline, childOverride }

/// Authoritative FS-004 policy — Prevent + Monitor + Protect (SC-OD-01).
///
/// Does **not** own: FS-003 package Allow/Block, ST minutes, WF URLs, mic/SOS audio.
@immutable
final class ScreenCameraDocument {
  factory ScreenCameraDocument({
    required FamilyId familyId,
    required ScreenCameraScopeKind scopeKind,
    ChildId? childId,
    bool preventCameraOs = false,
    bool preventCapture = false,
    bool monitorScreenshots = false,
    Set<String>? monitoredPackageIds,
    bool protectSensitiveSurfaces = true,
    Set<ScreenCameraExceptionClass>? enabledExceptions,
    int policyVersion = 1,
    DateTime? updatedAt,
  }) {
    if (scopeKind == ScreenCameraScopeKind.childOverride && childId == null) {
      throw ArgumentError('childOverride requires childId');
    }
    if (scopeKind == ScreenCameraScopeKind.familyBaseline && childId != null) {
      throw ArgumentError('familyBaseline must not set childId');
    }
    final pkgs = <String>{
      for (final p in monitoredPackageIds ?? const <String>{})
        if (p.trim().isNotEmpty) p.trim().toLowerCase(),
    };
    final ex =
        enabledExceptions ??
        {
          ScreenCameraExceptionClass.sos,
          ScreenCameraExceptionClass.qrEnrollment,
        };
    return ScreenCameraDocument._(
      familyId: familyId,
      scopeKind: scopeKind,
      childId: childId,
      preventCameraOs: preventCameraOs,
      preventCapture: preventCapture,
      monitorScreenshots: monitorScreenshots,
      monitoredPackageIds: Set<String>.unmodifiable(pkgs),
      protectSensitiveSurfaces: protectSensitiveSurfaces,
      enabledExceptions: Set<ScreenCameraExceptionClass>.unmodifiable(ex),
      policyVersion: policyVersion < 1 ? 1 : policyVersion,
      updatedAt:
          updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  const ScreenCameraDocument._({
    required this.familyId,
    required this.scopeKind,
    required this.childId,
    required this.preventCameraOs,
    required this.preventCapture,
    required this.monitorScreenshots,
    required this.monitoredPackageIds,
    required this.protectSensitiveSurfaces,
    required this.enabledExceptions,
    required this.policyVersion,
    required this.updatedAt,
  });

  String get scopeKey => switch (scopeKind) {
    ScreenCameraScopeKind.familyBaseline => 'family',
    ScreenCameraScopeKind.childOverride => 'child:${childId!.value}',
  };

  final FamilyId familyId;
  final ScreenCameraScopeKind scopeKind;
  final ChildId? childId;

  /// OS/device camera restriction **intent** (≠ FS-003 Camera package block).
  final bool preventCameraOs;

  /// Capture prevention intent — claim only with verified plane.
  final bool preventCapture;

  /// Configured screenshot monitoring (P-7) — child transparency mandatory when on.
  final bool monitorScreenshots;

  /// Configured monitor targets (package ids) — not full open-app stream.
  final Set<String> monitoredPackageIds;

  /// Protect Family OS sensitive surfaces against capture where supportable.
  final bool protectSensitiveSurfaces;

  final Set<ScreenCameraExceptionClass> enabledExceptions;
  final int policyVersion;
  final DateTime updatedAt;

  /// Child must see transparency when monitoring is configured active.
  bool get childTransparencyRequired => monitorScreenshots;

  /// Mic never owned here.
  bool get microphoneControlled =>
      ScreenCameraProtectedMatrix.microphoneInScope;

  static ScreenCameraDocument familyDefaults(FamilyId familyId) {
    return ScreenCameraDocument(
      familyId: familyId,
      scopeKind: ScreenCameraScopeKind.familyBaseline,
      protectSensitiveSurfaces: true,
      monitorScreenshots: false,
      preventCameraOs: false,
      preventCapture: false,
    );
  }

  ScreenCameraDocument copyWith({
    bool? preventCameraOs,
    bool? preventCapture,
    bool? monitorScreenshots,
    Set<String>? monitoredPackageIds,
    bool? protectSensitiveSurfaces,
    Set<ScreenCameraExceptionClass>? enabledExceptions,
    int? policyVersion,
    DateTime? updatedAt,
  }) {
    return ScreenCameraDocument(
      familyId: familyId,
      scopeKind: scopeKind,
      childId: childId,
      preventCameraOs: preventCameraOs ?? this.preventCameraOs,
      preventCapture: preventCapture ?? this.preventCapture,
      monitorScreenshots: monitorScreenshots ?? this.monitorScreenshots,
      monitoredPackageIds: monitoredPackageIds ?? this.monitoredPackageIds,
      protectSensitiveSurfaces:
          protectSensitiveSurfaces ?? this.protectSensitiveSurfaces,
      enabledExceptions: enabledExceptions ?? this.enabledExceptions,
      policyVersion: policyVersion ?? this.policyVersion,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toRow() => {
    'scope_key': scopeKey,
    'family_id': familyId.value,
    'child_id': childId?.value,
    'prevent_camera_os': preventCameraOs ? 1 : 0,
    'prevent_capture': preventCapture ? 1 : 0,
    'monitor_screenshots': monitorScreenshots ? 1 : 0,
    'monitored_packages_json': jsonEncode(monitoredPackageIds.toList()..sort()),
    'protect_sensitive': protectSensitiveSurfaces ? 1 : 0,
    'exceptions_json': jsonEncode(
      [for (final e in enabledExceptions) e.name]..sort(),
    ),
    'policy_version': policyVersion,
    'updated_at': updatedAt.toUtc().millisecondsSinceEpoch,
  };

  factory ScreenCameraDocument.fromRow(Map<String, Object?> row) {
    final childRaw = row['child_id'] as String?;
    final scopeKey = row['scope_key'] as String? ?? 'family';
    final kind = scopeKey.startsWith('child:')
        ? ScreenCameraScopeKind.childOverride
        : ScreenCameraScopeKind.familyBaseline;
    final pkgs = <String>{};
    final pkgJson = row['monitored_packages_json'] as String? ?? '[]';
    final pkgDecoded = jsonDecode(pkgJson);
    if (pkgDecoded is List) {
      for (final p in pkgDecoded) {
        pkgs.add(p.toString());
      }
    }
    final ex = <ScreenCameraExceptionClass>{};
    final exJson = row['exceptions_json'] as String? ?? '[]';
    final exDecoded = jsonDecode(exJson);
    if (exDecoded is List) {
      for (final raw in exDecoded) {
        final name = raw.toString();
        for (final v in ScreenCameraExceptionClass.values) {
          if (v.name == name) ex.add(v);
        }
      }
    }
    return ScreenCameraDocument(
      familyId: FamilyId(row['family_id'] as String? ?? 'fam'),
      scopeKind: kind,
      childId: childRaw == null || childRaw.isEmpty ? null : ChildId(childRaw),
      preventCameraOs: (row['prevent_camera_os'] as num?)?.toInt() == 1,
      preventCapture: (row['prevent_capture'] as num?)?.toInt() == 1,
      monitorScreenshots: (row['monitor_screenshots'] as num?)?.toInt() == 1,
      monitoredPackageIds: pkgs,
      protectSensitiveSurfaces:
          (row['protect_sensitive'] as num?)?.toInt() != 0,
      enabledExceptions: ex.isEmpty
          ? {
              ScreenCameraExceptionClass.sos,
              ScreenCameraExceptionClass.qrEnrollment,
            }
          : ex,
      policyVersion: (row['policy_version'] as num?)?.toInt() ?? 1,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        (row['updated_at'] as num?)?.toInt() ?? 0,
        isUtc: true,
      ),
    );
  }
}
