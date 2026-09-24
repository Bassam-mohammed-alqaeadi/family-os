import 'dart:convert';

import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/policy/sos_alert.dart';
import 'package:family_os/core/policy/sos_alert_repository.dart';
import 'package:family_os/core/policy/sos_role_actions.dart';
import 'package:family_os/core/sos_final/sos_final_service.dart';
import 'package:family_os/core/sos_final/sos_incident.dart';

/// Projects [SosFinalService] incidents into Stage-1 [SosAlertRepository].
///
/// Slice 01 AUTH-FS006 — local lifecycle bind only. Missing UI map fields
/// (movement / accuracy / pin) stay honest empties — never invent GPS.
final class DomainSosAlertRepository implements SosAlertRepository {
  DomainSosAlertRepository(this._service);

  final SosFinalService _service;

  @override
  Future<SosAlert?> loadActive({String? alertId}) async {
    final trimmed = alertId?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      final byId = await _service.loadById(trimmed);
      if (byId == null || !byId.isOpen) return null;
      return _map(byId);
    }
    final open = await _service.loadOpen();
    if (open == null) return null;
    return _map(open);
  }

  @override
  Future<SosAlert> acknowledge(String alertId, {required SosActor actor}) async {
    final next = await _service.acknowledge(
      incidentId: alertId,
      actor: actor,
      actorId: _actorId(actor),
    );
    return _map(next);
  }

  @override
  Future<SosAlert> resolve(
    String alertId, {
    required SosActor actor,
    SosTerminalReason reason = SosTerminalReason.helped,
  }) async {
    final next = await _service.resolve(
      incidentId: alertId,
      actor: actor,
      actorId: _actorId(actor),
      reason: reason,
    );
    return _map(next);
  }

  @override
  Future<SosAlert> escalateEmergencyContacts(
    String alertId, {
    required SosActor actor,
  }) async {
    final next = await _service.escalate(
      incidentId: alertId,
      actor: actor,
      actorId: _actorId(actor),
    );
    return _map(next);
  }

  static String _actorId(SosActor actor) {
    switch (actor.role) {
      case AppRole.father:
        return 'father';
      case AppRole.mother:
        return 'mother';
      case AppRole.child:
        return 'child';
    }
  }

  static SosAlert _map(SosIncident i) {
    return SosAlert(
      id: i.id,
      childId: i.childId.value,
      childDisplayName: i.childDisplayName.isEmpty ? 'ابن' : i.childDisplayName,
      childEmoji: i.childEmoji.isEmpty ? '🛡️' : i.childEmoji,
      pressedAt: i.triggeredAt,
      locationLabel: i.locationLabel,
      batteryPercent: i.batteryPercent,
      // Honest empties — Domain has no live GPS motion claim.
      movementLabel: '',
      accuracyMeters: 0,
      recipientLabels: const [],
      status: i.status,
      terminalReason: i.terminalReason,
      locationClass: i.locationClass,
      connectionClass: i.connectionClass,
      deliveries: _parseDeliveries(i.deliveriesJson),
      acknowledgedAt: i.acknowledgedAt,
      panicQuietAtTrigger: i.panicQuietAtTrigger,
    );
  }

  static List<SosDeliveryRow> _parseDeliveries(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final rows = <SosDeliveryRow>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final statusRaw = '${map['status'] ?? 'pending'}';
        rows.add(
          SosDeliveryRow(
            recipientId: '${map['recipientId'] ?? map['recipient_id'] ?? ''}',
            channel: '${map['channel'] ?? 'in_app'}',
            status: _deliveryStatus(statusRaw),
          ),
        );
      }
      return rows;
    } catch (_) {
      return const [];
    }
  }

  static SosDeliveryClass _deliveryStatus(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'delivered':
        return SosDeliveryClass.delivered;
      case 'failed':
        return SosDeliveryClass.failed;
      case 'unavailable':
        return SosDeliveryClass.unavailable;
      case 'not_configured':
      case 'notconfigured':
        return SosDeliveryClass.notConfigured;
      default:
        return SosDeliveryClass.pending;
    }
  }
}
