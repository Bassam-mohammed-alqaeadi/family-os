import 'package:flutter/foundation.dart';

import '../domain/child_id.dart';
import '../domain/mother_level.dart';
import '../domain/role.dart';

/// Lifecycle of a child→parent extra-time request (UF-05 / UI-006 / D-3).
enum TimeRequestStatus { pending, approved, rejected }

/// Who decides a time request (UF-05 / ADR-039).
@immutable
final class TimeRequestActor {
  const TimeRequestActor.father()
      : role = AppRole.father,
        motherLevel = null;

  const TimeRequestActor.mother(this.motherLevel) : role = AppRole.mother;

  const TimeRequestActor.child()
      : role = AppRole.child,
        motherLevel = null;

  final AppRole role;
  final MotherLevel? motherLevel;

  /// Father always; mother partner/full; observer and child cannot.
  bool get canDecide {
    if (role == AppRole.father) return true;
    if (role == AppRole.mother) {
      return motherLevel == MotherLevel.partner ||
          motherLevel == MotherLevel.full;
    }
    return false;
  }

  /// ADR-039: mother ②/③ cannot grant above [activeCeilingMinutes].
  /// Father (OWNER) may grant any positive duration.
  bool canGrantMinutes(int minutes, int activeCeilingMinutes) {
    if (!canDecide || minutes <= 0) return false;
    if (role == AppRole.father) return true;
    return minutes <= activeCeilingMinutes;
  }

  String get auditLabel {
    if (role == AppRole.father) return 'father';
    if (role == AppRole.mother) {
      return 'mother:${motherLevel?.name ?? 'unknown'}';
    }
    return 'child';
  }
}

/// Child request for extra screen-time minutes (D-3 `time_request`).
@immutable
final class TimeRequest {
  factory TimeRequest({
    required String id,
    required ChildId childId,
    required int requestedMinutes,
    String? childReason,
    TimeRequestStatus status = TimeRequestStatus.pending,
    DateTime? createdAt,
    String? decidedBy,
    String? decisionReason,
    int? grantedMinutes,
  }) {
    return TimeRequest._(
      id: id,
      childId: childId,
      requestedMinutes: requestedMinutes,
      childReason: childReason,
      status: status,
      createdAt: createdAt ?? DateTime.now().toUtc(),
      decidedBy: decidedBy,
      decisionReason: decisionReason,
      grantedMinutes: grantedMinutes,
    );
  }

  const TimeRequest._({
    required this.id,
    required this.childId,
    required this.requestedMinutes,
    required this.status,
    required this.createdAt,
    this.childReason,
    this.decidedBy,
    this.decisionReason,
    this.grantedMinutes,
  });

  final String id;
  final ChildId childId;
  final int requestedMinutes;
  final String? childReason;
  final TimeRequestStatus status;
  final DateTime createdAt;
  final String? decidedBy;

  /// Parent reject / approve note — child-visible on decide (UF-05).
  final String? decisionReason;

  /// Minutes deposited on approve (may differ from [requestedMinutes]).
  final int? grantedMinutes;

  bool get isPending => status == TimeRequestStatus.pending;

  TimeRequest copyWith({
    TimeRequestStatus? status,
    String? decidedBy,
    String? decisionReason,
    int? grantedMinutes,
    bool clearDecisionReason = false,
    bool clearGrantedMinutes = false,
  }) {
    return TimeRequest._(
      id: id,
      childId: childId,
      requestedMinutes: requestedMinutes,
      childReason: childReason,
      status: status ?? this.status,
      createdAt: createdAt,
      decidedBy: decidedBy ?? this.decidedBy,
      decisionReason: clearDecisionReason
          ? null
          : (decisionReason ?? this.decisionReason),
      grantedMinutes: clearGrantedMinutes
          ? null
          : (grantedMinutes ?? this.grantedMinutes),
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'childId': childId.value,
        'requestedMinutes': requestedMinutes,
        'childReason': childReason,
        'status': status.name,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'decidedBy': decidedBy,
        'decisionReason': decisionReason,
        'grantedMinutes': grantedMinutes,
      };

  factory TimeRequest.fromJson(Map<String, Object?> json) {
    final statusName = json['status'] as String? ?? 'pending';
    final status = TimeRequestStatus.values.firstWhere(
      (s) => s.name == statusName,
      orElse: () => TimeRequestStatus.pending,
    );
    final rawCreated = json['createdAt'];
    DateTime created = DateTime.now().toUtc();
    if (rawCreated is String) {
      created = DateTime.tryParse(rawCreated)?.toUtc() ?? created;
    }
    return TimeRequest._(
      id: json['id'] as String? ?? '',
      childId: ChildId(json['childId'] as String? ?? 'unknown'),
      requestedMinutes: (json['requestedMinutes'] as num?)?.toInt() ?? 0,
      childReason: json['childReason'] as String?,
      status: status,
      createdAt: created,
      decidedBy: json['decidedBy'] as String?,
      decisionReason: json['decisionReason'] as String?,
      grantedMinutes: (json['grantedMinutes'] as num?)?.toInt(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeRequest &&
          id == other.id &&
          childId == other.childId &&
          requestedMinutes == other.requestedMinutes &&
          childReason == other.childReason &&
          status == other.status &&
          createdAt == other.createdAt &&
          decidedBy == other.decidedBy &&
          decisionReason == other.decisionReason &&
          grantedMinutes == other.grantedMinutes;

  @override
  int get hashCode => Object.hash(
        id,
        childId,
        requestedMinutes,
        childReason,
        status,
        createdAt,
        decidedBy,
        decisionReason,
        grantedMinutes,
      );
}

/// Immutable grant row (D-3 `time_grant`) produced on approve.
@immutable
final class TimeGrant {
  const TimeGrant({
    required this.id,
    required this.requestId,
    required this.childId,
    required this.minutes,
    required this.grantedBy,
    required this.createdAt,
  });

  final String id;
  final String requestId;
  final ChildId childId;
  final int minutes;
  final String grantedBy;
  final DateTime createdAt;

  Map<String, Object?> toJson() => {
        'id': id,
        'requestId': requestId,
        'childId': childId.value,
        'minutes': minutes,
        'grantedBy': grantedBy,
        'createdAt': createdAt.toUtc().toIso8601String(),
      };

  factory TimeGrant.fromJson(Map<String, Object?> json) {
    final rawCreated = json['createdAt'];
    DateTime created = DateTime.now().toUtc();
    if (rawCreated is String) {
      created = DateTime.tryParse(rawCreated)?.toUtc() ?? created;
    }
    return TimeGrant(
      id: json['id'] as String? ?? '',
      requestId: json['requestId'] as String? ?? '',
      childId: ChildId(json['childId'] as String? ?? 'unknown'),
      minutes: (json['minutes'] as num?)?.toInt() ?? 0,
      grantedBy: json['grantedBy'] as String? ?? '',
      createdAt: created,
    );
  }
}

/// ADR-039 default per-grant ceiling (minutes) when no father rule edit.
const int kDefaultMotherGrantCeilingMinutes = 30;

/// Standard grant chips for FAT-033 (mother clamps ≤ active ceiling).
const List<int> kTimeGrantOptionMinutes = [15, 30, 45, 60];
