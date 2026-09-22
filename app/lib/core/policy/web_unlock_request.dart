import 'package:flutter/foundation.dart';

import '../domain/child_id.dart';
import 'web_filter_policy.dart';

/// Lifecycle of a child→parent web unlock request (SET-006 / WFR).
enum WebUnlockRequestStatus { pending, approved, denied }

/// Child request to unlock a blocked URL (Family Link–style approve/deny).
@immutable
final class WebUnlockRequest {
  factory WebUnlockRequest({
    required String id,
    required ChildId childId,
    required String url,
    WebUnlockRequestStatus status = WebUnlockRequestStatus.pending,
    DateTime? createdAt,
    String? decidedBy,
    String? reason,
  }) {
    return WebUnlockRequest._(
      id: id,
      childId: childId,
      url: url.trim(),
      host: WebFilterPolicy.normalizeHost(_hostOf(url)),
      status: status,
      createdAt: createdAt ?? DateTime.now().toUtc(),
      decidedBy: decidedBy,
      reason: reason,
    );
  }

  const WebUnlockRequest._({
    required this.id,
    required this.childId,
    required this.url,
    required this.host,
    required this.status,
    required this.createdAt,
    this.decidedBy,
    this.reason,
  });

  final String id;
  final ChildId childId;
  final String url;

  /// Normalized host derived from [url] (allow-list key).
  final String host;

  final WebUnlockRequestStatus status;
  final DateTime createdAt;
  final String? decidedBy;
  final String? reason;

  bool get isPending => status == WebUnlockRequestStatus.pending;

  WebUnlockRequest copyWith({
    WebUnlockRequestStatus? status,
    String? decidedBy,
    String? reason,
    bool clearReason = false,
  }) {
    return WebUnlockRequest._(
      id: id,
      childId: childId,
      url: url,
      host: host,
      status: status ?? this.status,
      createdAt: createdAt,
      decidedBy: decidedBy ?? this.decidedBy,
      reason: clearReason ? null : (reason ?? this.reason),
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'childId': childId.value,
        'url': url,
        'host': host,
        'status': status.name,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'decidedBy': decidedBy,
        'reason': reason,
      };

  factory WebUnlockRequest.fromJson(Map<String, Object?> json) {
    final statusName = json['status'] as String? ?? 'pending';
    final status = WebUnlockRequestStatus.values.firstWhere(
      (s) => s.name == statusName,
      orElse: () => WebUnlockRequestStatus.pending,
    );
    final rawCreated = json['createdAt'];
    DateTime created = DateTime.now().toUtc();
    if (rawCreated is String) {
      created = DateTime.tryParse(rawCreated)?.toUtc() ?? created;
    }
    final url = json['url'] as String? ?? '';
    final hostRaw = json['host'] as String?;
    return WebUnlockRequest._(
      id: json['id'] as String? ?? '',
      childId: ChildId(json['childId'] as String? ?? 'unknown'),
      url: url,
      host: WebFilterPolicy.normalizeHost(
        hostRaw ?? _hostOf(url),
      ),
      status: status,
      createdAt: created,
      decidedBy: json['decidedBy'] as String?,
      reason: json['reason'] as String?,
    );
  }

  static String _hostOf(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return '';
    final withScheme =
        trimmed.contains('://') ? trimmed : 'https://$trimmed';
    final uri = Uri.tryParse(withScheme);
    return uri?.host ?? '';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WebUnlockRequest &&
          id == other.id &&
          childId == other.childId &&
          url == other.url &&
          host == other.host &&
          status == other.status &&
          createdAt == other.createdAt &&
          decidedBy == other.decidedBy &&
          reason == other.reason;

  @override
  int get hashCode => Object.hash(
        id,
        childId,
        url,
        host,
        status,
        createdAt,
        decidedBy,
        reason,
      );
}
