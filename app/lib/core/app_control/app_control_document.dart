import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';

import 'app_control_disposition.dart';
import 'app_control_protected.dart';
import 'package_id.dart';

/// Scope of an App Control policy document (APP-OD-01).
enum AppControlScopeKind { familyBaseline, childOverride }

/// Authoritative App Control document — package dispositions only (APP-OD-12).
///
/// Screen Time owns Limit / Unlimited / Countable / Temporary Grant.
@immutable
final class AppControlDocument {
  factory AppControlDocument({
    required FamilyId familyId,
    required AppControlScopeKind scopeKind,
    ChildId? childId,
    Map<String, AppPackageDisposition>? dispositions,
    int policyVersion = 1,
    DateTime? updatedAt,
  }) {
    if (scopeKind == AppControlScopeKind.childOverride && childId == null) {
      throw ArgumentError('childOverride requires childId');
    }
    if (scopeKind == AppControlScopeKind.familyBaseline && childId != null) {
      throw ArgumentError('familyBaseline must not set childId');
    }
    final cleaned = <String, AppPackageDisposition>{};
    for (final e in (dispositions ?? const {}).entries) {
      final id = PackageId.normalize(e.key);
      if (id.isEmpty) continue;
      // Protected packages cannot hold Permanent Block in policy.
      if (ProtectedPackageIds.isProtected(id) &&
          e.value == AppPackageDisposition.block) {
        cleaned[id] = AppPackageDisposition.allow;
      } else {
        cleaned[id] = e.value;
      }
    }
    return AppControlDocument._(
      familyId: familyId,
      scopeKind: scopeKind,
      childId: childId,
      dispositions: Map<String, AppPackageDisposition>.unmodifiable(cleaned),
      policyVersion: policyVersion < 1 ? 1 : policyVersion,
      updatedAt:
          updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  const AppControlDocument._({
    required this.familyId,
    required this.scopeKind,
    required this.childId,
    required this.dispositions,
    required this.policyVersion,
    required this.updatedAt,
  });

  String get scopeKey => switch (scopeKind) {
    AppControlScopeKind.familyBaseline => 'family',
    AppControlScopeKind.childOverride => 'child:${childId!.value}',
  };

  final FamilyId familyId;
  final AppControlScopeKind scopeKind;
  final ChildId? childId;
  final Map<String, AppPackageDisposition> dispositions;
  final int policyVersion;
  final DateTime updatedAt;

  static AppControlDocument familyDefaults(FamilyId familyId) {
    return AppControlDocument(
      familyId: familyId,
      scopeKind: AppControlScopeKind.familyBaseline,
      dispositions: {
        for (final id in ProtectedPackageIds.core)
          id: AppPackageDisposition.allow,
      },
    );
  }

  AppPackageDisposition? dispositionOf(String packageId) {
    final n = PackageId.normalize(packageId);
    return dispositions[n];
  }

  AppControlDocument upsertDisposition(
    String packageId,
    AppPackageDisposition disposition,
  ) {
    final n = PackageId.normalize(packageId);
    final next = Map<String, AppPackageDisposition>.from(dispositions);
    next[n] = disposition;
    return copyWith(dispositions: next, policyVersion: policyVersion + 1);
  }

  AppControlDocument copyWith({
    Map<String, AppPackageDisposition>? dispositions,
    int? policyVersion,
    DateTime? updatedAt,
  }) {
    return AppControlDocument(
      familyId: familyId,
      scopeKind: scopeKind,
      childId: childId,
      dispositions: dispositions ?? this.dispositions,
      policyVersion: policyVersion ?? this.policyVersion,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toRow() {
    final jsonMap = <String, String>{
      for (final e in dispositions.entries) e.key: e.value.wire,
    };
    return {
      'scope_key': scopeKey,
      'family_id': familyId.value,
      'child_id': childId?.value,
      'dispositions_json': jsonEncode(jsonMap),
      'policy_version': policyVersion,
      'updated_at': updatedAt.toUtc().millisecondsSinceEpoch,
    };
  }

  factory AppControlDocument.fromRow(Map<String, Object?> row) {
    final childRaw = row['child_id'] as String?;
    final scopeKey = row['scope_key'] as String? ?? 'family';
    final kind = scopeKey.startsWith('child:')
        ? AppControlScopeKind.childOverride
        : AppControlScopeKind.familyBaseline;
    final map = <String, AppPackageDisposition>{};
    final rawJson = row['dispositions_json'] as String? ?? '{}';
    final decoded = jsonDecode(rawJson);
    if (decoded is Map) {
      for (final e in decoded.entries) {
        map[e.key.toString()] = AppPackageDispositionCodec.parse(
          e.value?.toString(),
        );
      }
    }
    return AppControlDocument(
      familyId: FamilyId(row['family_id'] as String? ?? 'fam'),
      scopeKind: kind,
      childId: childRaw == null || childRaw.isEmpty ? null : ChildId(childRaw),
      dispositions: map,
      policyVersion: (row['policy_version'] as num?)?.toInt() ?? 1,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        (row['updated_at'] as num?)?.toInt() ?? 0,
        isUtc: true,
      ),
    );
  }
}
