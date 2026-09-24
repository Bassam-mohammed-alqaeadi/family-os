import 'package:flutter/foundation.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';

import 'package_id.dart';

/// Placeholder duration until T-APP-06 freezes product numbers.
abstract final class AppAccessExceptionDefaults {
  static const Duration placeholderDuration = Duration(hours: 1);
}

enum AppAccessExceptionStatus { pending, active, denied, expired, revoked }

/// Timed App Access Exception — does **not** rewrite Permanent Block (APP-SF-16).
@immutable
final class AppAccessException {
  factory AppAccessException({
    required String id,
    required FamilyId familyId,
    required ChildId childId,
    required String packageId,
    required AppAccessExceptionStatus status,
    required DateTime requestedAt,
    DateTime? startsAt,
    DateTime? expiresAt,
    String? requestNote,
  }) {
    return AppAccessException._(
      id: id,
      familyId: familyId,
      childId: childId,
      packageId: PackageId.normalize(packageId),
      status: status,
      requestedAt: requestedAt.toUtc(),
      startsAt: startsAt?.toUtc(),
      expiresAt: expiresAt?.toUtc(),
      requestNote: requestNote,
    );
  }

  const AppAccessException._({
    required this.id,
    required this.familyId,
    required this.childId,
    required this.packageId,
    required this.status,
    required this.requestedAt,
    required this.startsAt,
    required this.expiresAt,
    required this.requestNote,
  });

  final String id;
  final FamilyId familyId;
  final ChildId childId;
  final String packageId;
  final AppAccessExceptionStatus status;
  final DateTime requestedAt;
  final DateTime? startsAt;
  final DateTime? expiresAt;
  final String? requestNote;

  bool isActiveAt(DateTime now) {
    if (status != AppAccessExceptionStatus.active) return false;
    final start = startsAt;
    final end = expiresAt;
    if (start == null || end == null) return false;
    final t = now.toUtc();
    return !t.isBefore(start) && t.isBefore(end);
  }

  Map<String, Object?> toRow() => {
    'id': id,
    'family_id': familyId.value,
    'child_id': childId.value,
    'package_id': packageId,
    'status': status.name,
    'requested_at': requestedAt.millisecondsSinceEpoch,
    'starts_at': startsAt?.millisecondsSinceEpoch,
    'expires_at': expiresAt?.millisecondsSinceEpoch,
    'request_note': requestNote,
  };

  factory AppAccessException.fromRow(Map<String, Object?> row) {
    return AppAccessException(
      id: row['id'] as String? ?? '',
      familyId: FamilyId(row['family_id'] as String? ?? 'fam'),
      childId: ChildId(row['child_id'] as String? ?? ''),
      packageId: row['package_id'] as String? ?? '',
      status: AppAccessExceptionStatus.values.firstWhere(
        (s) => s.name == row['status'],
        orElse: () => AppAccessExceptionStatus.pending,
      ),
      requestedAt: DateTime.fromMillisecondsSinceEpoch(
        (row['requested_at'] as num?)?.toInt() ?? 0,
        isUtc: true,
      ),
      startsAt: _ms(row['starts_at']),
      expiresAt: _ms(row['expires_at']),
      requestNote: row['request_note'] as String?,
    );
  }

  static DateTime? _ms(Object? v) {
    if (v == null) return null;
    return DateTime.fromMillisecondsSinceEpoch((v as num).toInt(), isUtc: true);
  }
}
