import 'package:flutter/foundation.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';

import 'package_id.dart';

enum AppInstallDecisionStatus { pendingDecision, approved, denied }

/// Child-scoped install ticket (APP-OD-08 / APP-OD-18).
@immutable
final class AppInstallTicket {
  factory AppInstallTicket({
    required String id,
    required FamilyId familyId,
    required ChildId childId,
    required String packageId,
    required AppInstallDecisionStatus status,
    required DateTime observedAt,
    String? labelSnapshot,
  }) {
    return AppInstallTicket._(
      id: id,
      familyId: familyId,
      childId: childId,
      packageId: PackageId.normalize(packageId),
      status: status,
      observedAt: observedAt.toUtc(),
      labelSnapshot: labelSnapshot,
    );
  }

  const AppInstallTicket._({
    required this.id,
    required this.familyId,
    required this.childId,
    required this.packageId,
    required this.status,
    required this.observedAt,
    required this.labelSnapshot,
  });

  final String id;
  final FamilyId familyId;
  final ChildId childId;
  final String packageId;
  final AppInstallDecisionStatus status;
  final DateTime observedAt;
  final String? labelSnapshot;

  bool get isPending => status == AppInstallDecisionStatus.pendingDecision;

  Map<String, Object?> toRow() => {
    'id': id,
    'family_id': familyId.value,
    'child_id': childId.value,
    'package_id': packageId,
    'status': status.name,
    'observed_at': observedAt.millisecondsSinceEpoch,
    'label_snapshot': labelSnapshot,
  };

  factory AppInstallTicket.fromRow(Map<String, Object?> row) {
    return AppInstallTicket(
      id: row['id'] as String? ?? '',
      familyId: FamilyId(row['family_id'] as String? ?? 'fam'),
      childId: ChildId(row['child_id'] as String? ?? ''),
      packageId: row['package_id'] as String? ?? '',
      status: AppInstallDecisionStatus.values.firstWhere(
        (s) => s.name == row['status'],
        orElse: () => AppInstallDecisionStatus.pendingDecision,
      ),
      observedAt: DateTime.fromMillisecondsSinceEpoch(
        (row['observed_at'] as num?)?.toInt() ?? 0,
        isUtc: true,
      ),
      labelSnapshot: row['label_snapshot'] as String?,
    );
  }
}
