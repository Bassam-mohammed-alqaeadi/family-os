import 'package:flutter/foundation.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/policy/sos_alert.dart';

import 'sos_evidence_policy.dart';

/// Child hold trigger only — break-glass is never a create source (RD-02).
enum SosTriggerSource { hold }

/// Durable SOS incident (schema v9) — FS-006 owns lifecycle.
@immutable
final class SosIncident {
  const SosIncident({
    required this.id,
    required this.familyId,
    required this.childId,
    required this.triggeredAt,
    required this.status,
    this.terminalReason,
    this.acknowledgedAt,
    this.acknowledgedBy,
    this.resolvedAt,
    this.resolvedBy,
    this.triggerSource = SosTriggerSource.hold,
    this.locationClass = SosLocationClass.acquiring,
    this.connectionClass = SosConnectionClass.online,
    this.batteryPercent = 0,
    this.panicQuietAtTrigger = false,
    required this.evidenceRetainUntil,
    this.deliveriesJson = '[]',
    this.childDisplayName = '',
    this.childEmoji = '',
    this.locationLabel = '',
  });

  final String id;
  final FamilyId familyId;
  final ChildId childId;
  final DateTime triggeredAt;
  final SosAlertStatus status;
  final SosTerminalReason? terminalReason;
  final DateTime? acknowledgedAt;
  final String? acknowledgedBy;
  final DateTime? resolvedAt;
  final String? resolvedBy;
  final SosTriggerSource triggerSource;
  final SosLocationClass locationClass;
  final SosConnectionClass connectionClass;
  final int batteryPercent;
  final bool panicQuietAtTrigger;
  final DateTime evidenceRetainUntil;
  final String deliveriesJson;
  final String childDisplayName;
  final String childEmoji;
  final String locationLabel;

  bool get isOpen =>
      status == SosAlertStatus.active ||
      status == SosAlertStatus.acknowledged ||
      status == SosAlertStatus.escalating;

  bool get isResolved => status == SosAlertStatus.resolved;

  SosIncident copyWith({
    SosAlertStatus? status,
    SosTerminalReason? terminalReason,
    bool clearTerminalReason = false,
    DateTime? acknowledgedAt,
    String? acknowledgedBy,
    DateTime? resolvedAt,
    String? resolvedBy,
    SosLocationClass? locationClass,
    SosConnectionClass? connectionClass,
    int? batteryPercent,
    String? deliveriesJson,
    String? locationLabel,
  }) {
    return SosIncident(
      id: id,
      familyId: familyId,
      childId: childId,
      triggeredAt: triggeredAt,
      status: status ?? this.status,
      terminalReason: clearTerminalReason
          ? null
          : (terminalReason ?? this.terminalReason),
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      acknowledgedBy: acknowledgedBy ?? this.acknowledgedBy,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      triggerSource: triggerSource,
      locationClass: locationClass ?? this.locationClass,
      connectionClass: connectionClass ?? this.connectionClass,
      batteryPercent: batteryPercent ?? this.batteryPercent,
      panicQuietAtTrigger: panicQuietAtTrigger,
      evidenceRetainUntil: evidenceRetainUntil,
      deliveriesJson: deliveriesJson ?? this.deliveriesJson,
      childDisplayName: childDisplayName,
      childEmoji: childEmoji,
      locationLabel: locationLabel ?? this.locationLabel,
    );
  }

  Map<String, Object?> toRow() => {
        'id': id,
        'family_id': familyId.value,
        'child_id': childId.value,
        'status': status.name,
        'terminal_reason': terminalReason?.name,
        'triggered_at': triggeredAt.toUtc().millisecondsSinceEpoch,
        'acknowledged_at': acknowledgedAt?.toUtc().millisecondsSinceEpoch,
        'acknowledged_by': acknowledgedBy,
        'resolved_at': resolvedAt?.toUtc().millisecondsSinceEpoch,
        'resolved_by': resolvedBy,
        'trigger_source': triggerSource.name,
        'location_class': locationClass.name,
        'connection_class': connectionClass.name,
        'battery_percent': batteryPercent,
        'panic_quiet_at_trigger': panicQuietAtTrigger ? 1 : 0,
        'evidence_retain_until':
            evidenceRetainUntil.toUtc().millisecondsSinceEpoch,
        'deliveries_json': deliveriesJson,
        'child_display_name': childDisplayName,
        'child_emoji': childEmoji,
        'location_label': locationLabel,
      };

  factory SosIncident.fromRow(Map<String, Object?> row) {
    return SosIncident(
      id: row['id']! as String,
      familyId: FamilyId(row['family_id']! as String),
      childId: ChildId(row['child_id']! as String),
      triggeredAt: DateTime.fromMillisecondsSinceEpoch(
        row['triggered_at']! as int,
        isUtc: true,
      ),
      status: SosAlertStatus.values.byName(row['status']! as String),
      terminalReason: row['terminal_reason'] == null
          ? null
          : SosTerminalReason.values.byName(row['terminal_reason']! as String),
      acknowledgedAt: _ms(row['acknowledged_at']),
      acknowledgedBy: row['acknowledged_by'] as String?,
      resolvedAt: _ms(row['resolved_at']),
      resolvedBy: row['resolved_by'] as String?,
      triggerSource:
          SosTriggerSource.values.byName(row['trigger_source']! as String),
      locationClass:
          SosLocationClass.values.byName(row['location_class']! as String),
      connectionClass: SosConnectionClass.values
          .byName(row['connection_class']! as String),
      batteryPercent: row['battery_percent']! as int,
      panicQuietAtTrigger: (row['panic_quiet_at_trigger']! as int) == 1,
      evidenceRetainUntil: DateTime.fromMillisecondsSinceEpoch(
        row['evidence_retain_until']! as int,
        isUtc: true,
      ),
      deliveriesJson: row['deliveries_json']! as String,
      childDisplayName: (row['child_display_name'] as String?) ?? '',
      childEmoji: (row['child_emoji'] as String?) ?? '',
      locationLabel: (row['location_label'] as String?) ?? '',
    );
  }

  static DateTime? _ms(Object? v) {
    if (v == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(v as int, isUtc: true);
  }

  /// Factory for a newly fired local incident (HOLD complete → ACTIVE).
  factory SosIncident.fire({
    required String id,
    required FamilyId familyId,
    required ChildId childId,
    required DateTime triggeredAt,
    SosLocationClass locationClass = SosLocationClass.acquiring,
    SosConnectionClass connectionClass = SosConnectionClass.online,
    int batteryPercent = 0,
    bool panicQuietAtTrigger = false,
    String deliveriesJson = '[]',
    String childDisplayName = '',
    String childEmoji = '',
    String locationLabel = '',
  }) {
    return SosIncident(
      id: id,
      familyId: familyId,
      childId: childId,
      triggeredAt: triggeredAt.toUtc(),
      status: SosAlertStatus.active,
      triggerSource: SosTriggerSource.hold,
      locationClass: locationClass,
      connectionClass: connectionClass,
      batteryPercent: batteryPercent,
      panicQuietAtTrigger: panicQuietAtTrigger,
      evidenceRetainUntil: SosEvidencePolicy.retainUntilFrom(triggeredAt),
      deliveriesJson: deliveriesJson,
      childDisplayName: childDisplayName,
      childEmoji: childEmoji,
      locationLabel: locationLabel,
    );
  }
}

@immutable
final class SosLifecycleAuditEntry {
  const SosLifecycleAuditEntry({
    required this.id,
    required this.incidentId,
    required this.familyId,
    required this.eventType,
    required this.at,
    this.actorId,
    this.payloadJson = '{}',
  });

  final String id;
  final String incidentId;
  final FamilyId familyId;
  final SosAuditEventType eventType;
  final DateTime at;
  final String? actorId;
  final String payloadJson;

  Map<String, Object?> toRow() => {
        'id': id,
        'incident_id': incidentId,
        'family_id': familyId.value,
        'event_type': eventType.name,
        'at_ms': at.toUtc().millisecondsSinceEpoch,
        'actor_id': actorId,
        'payload_json': payloadJson,
      };

  factory SosLifecycleAuditEntry.fromRow(Map<String, Object?> row) {
    return SosLifecycleAuditEntry(
      id: row['id']! as String,
      incidentId: row['incident_id']! as String,
      familyId: FamilyId(row['family_id']! as String),
      eventType: SosAuditEventType.values.byName(row['event_type']! as String),
      at: DateTime.fromMillisecondsSinceEpoch(row['at_ms']! as int, isUtc: true),
      actorId: row['actor_id'] as String?,
      payloadJson: row['payload_json']! as String,
    );
  }
}

@immutable
final class SosOpsSample {
  const SosOpsSample({
    required this.id,
    required this.incidentId,
    required this.familyId,
    required this.kind,
    required this.capturedAt,
    required this.retainUntil,
    this.payloadJson = '{}',
  });

  final String id;
  final String incidentId;
  final FamilyId familyId;
  final SosOpsSampleKind kind;
  final DateTime capturedAt;
  final DateTime retainUntil;
  final String payloadJson;

  Map<String, Object?> toRow() => {
        'id': id,
        'incident_id': incidentId,
        'family_id': familyId.value,
        'kind': kind.name,
        'captured_at': capturedAt.toUtc().millisecondsSinceEpoch,
        'retain_until': retainUntil.toUtc().millisecondsSinceEpoch,
        'payload_json': payloadJson,
      };

  factory SosOpsSample.fromRow(Map<String, Object?> row) {
    return SosOpsSample(
      id: row['id']! as String,
      incidentId: row['incident_id']! as String,
      familyId: FamilyId(row['family_id']! as String),
      kind: SosOpsSampleKind.values.byName(row['kind']! as String),
      capturedAt: DateTime.fromMillisecondsSinceEpoch(
        row['captured_at']! as int,
        isUtc: true,
      ),
      retainUntil: DateTime.fromMillisecondsSinceEpoch(
        row['retain_until']! as int,
        isUtc: true,
      ),
      payloadJson: row['payload_json']! as String,
    );
  }
}
