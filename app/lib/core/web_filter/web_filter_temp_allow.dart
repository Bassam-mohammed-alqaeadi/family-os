import 'package:flutter/foundation.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/policy/web_filter_policy.dart';

/// Timed temporary allow (Q-WF-09 / WF-OD-09) — never a permanent allowlist write.
enum WebFilterTempAllowStatus { active, expired, revoked }

/// Stage-1 placeholder duration until T-WF-01 is frozen.
abstract final class WebFilterTempAllowDefaults {
  static const Duration placeholderDuration = Duration(hours: 1);
  static const String durationHonesty = 'T-WF-01 TBD — Stage-1 1h placeholder';
}

@immutable
final class WebFilterTempAllow {
  const WebFilterTempAllow({
    required this.id,
    required this.familyId,
    required this.childId,
    required this.host,
    required this.requestId,
    required this.startsAt,
    required this.expiresAt,
    required this.status,
  });

  final String id;
  final FamilyId familyId;
  final ChildId childId;
  final String host;
  final String requestId;
  final DateTime startsAt;
  final DateTime expiresAt;
  final WebFilterTempAllowStatus status;

  bool isActiveAt(DateTime now) {
    if (status != WebFilterTempAllowStatus.active) return false;
    final n = now.toUtc();
    return !n.isBefore(startsAt.toUtc()) && n.isBefore(expiresAt.toUtc());
  }

  WebFilterTempAllow copyWith({WebFilterTempAllowStatus? status}) =>
      WebFilterTempAllow(
        id: id,
        familyId: familyId,
        childId: childId,
        host: host,
        requestId: requestId,
        startsAt: startsAt,
        expiresAt: expiresAt,
        status: status ?? this.status,
      );

  Map<String, Object?> toRow() => {
    'id': id,
    'family_id': familyId.value,
    'child_id': childId.value,
    'host': host,
    'request_id': requestId,
    'starts_at': startsAt.toUtc().millisecondsSinceEpoch,
    'expires_at': expiresAt.toUtc().millisecondsSinceEpoch,
    'status': status.name,
  };

  factory WebFilterTempAllow.fromRow(Map<String, Object?> row) {
    final statusName = row['status'] as String? ?? 'active';
    final status = WebFilterTempAllowStatus.values.firstWhere(
      (s) => s.name == statusName,
      orElse: () => WebFilterTempAllowStatus.active,
    );
    return WebFilterTempAllow(
      id: row['id']! as String,
      familyId: FamilyId(row['family_id']! as String),
      childId: ChildId(row['child_id']! as String),
      host: WebFilterPolicy.normalizeHost(row['host']! as String),
      requestId: row['request_id']! as String,
      startsAt: DateTime.fromMillisecondsSinceEpoch(
        row['starts_at']! as int,
        isUtc: true,
      ),
      expiresAt: DateTime.fromMillisecondsSinceEpoch(
        row['expires_at']! as int,
        isUtc: true,
      ),
      status: status,
    );
  }
}

/// Rule 25 seam for timed temporary allows.
abstract class WebFilterTempAllowRepository {
  Future<void> save(WebFilterTempAllow allow);

  Future<WebFilterTempAllow?> getById(String id);

  Future<List<WebFilterTempAllow>> listForChild(
    FamilyId familyId,
    ChildId childId,
  );

  /// Active hosts for engine injection (sweeps expiry).
  Future<Set<String>> activeHosts(
    FamilyId familyId,
    ChildId childId, {
    DateTime? now,
  });

  Future<void> revokeForHost(FamilyId familyId, ChildId childId, String host);
}
