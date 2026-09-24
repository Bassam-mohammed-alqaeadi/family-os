import 'package:flutter/foundation.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';

import 'package_id.dart';

/// Placeholder duration until T-APP freezes Lock Now TTL.
abstract final class AppLockNowDefaults {
  static const Duration placeholderDuration = Duration(hours: 1);
}

enum AppLockNowStatus { active, expired, revoked }

/// Per-app Lock Now temporary deny overlay (APP-OD-13) ≠ Permanent Block.
@immutable
final class AppLockNowOverlay {
  factory AppLockNowOverlay({
    required String id,
    required FamilyId familyId,
    required ChildId childId,
    required String packageId,
    required AppLockNowStatus status,
    required DateTime startsAt,
    required DateTime expiresAt,
  }) {
    return AppLockNowOverlay._(
      id: id,
      familyId: familyId,
      childId: childId,
      packageId: PackageId.normalize(packageId),
      status: status,
      startsAt: startsAt.toUtc(),
      expiresAt: expiresAt.toUtc(),
    );
  }

  const AppLockNowOverlay._({
    required this.id,
    required this.familyId,
    required this.childId,
    required this.packageId,
    required this.status,
    required this.startsAt,
    required this.expiresAt,
  });

  final String id;
  final FamilyId familyId;
  final ChildId childId;
  final String packageId;
  final AppLockNowStatus status;
  final DateTime startsAt;
  final DateTime expiresAt;

  bool isActiveAt(DateTime now) {
    if (status != AppLockNowStatus.active) return false;
    final t = now.toUtc();
    return !t.isBefore(startsAt) && t.isBefore(expiresAt);
  }

  Map<String, Object?> toRow() => {
    'id': id,
    'family_id': familyId.value,
    'child_id': childId.value,
    'package_id': packageId,
    'status': status.name,
    'starts_at': startsAt.millisecondsSinceEpoch,
    'expires_at': expiresAt.millisecondsSinceEpoch,
  };

  factory AppLockNowOverlay.fromRow(Map<String, Object?> row) {
    return AppLockNowOverlay(
      id: row['id'] as String? ?? '',
      familyId: FamilyId(row['family_id'] as String? ?? 'fam'),
      childId: ChildId(row['child_id'] as String? ?? ''),
      packageId: row['package_id'] as String? ?? '',
      status: AppLockNowStatus.values.firstWhere(
        (s) => s.name == row['status'],
        orElse: () => AppLockNowStatus.expired,
      ),
      startsAt: DateTime.fromMillisecondsSinceEpoch(
        (row['starts_at'] as num?)?.toInt() ?? 0,
        isUtc: true,
      ),
      expiresAt: DateTime.fromMillisecondsSinceEpoch(
        (row['expires_at'] as num?)?.toInt() ?? 0,
        isUtc: true,
      ),
    );
  }
}
