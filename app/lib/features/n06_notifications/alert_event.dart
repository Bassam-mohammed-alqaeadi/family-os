import 'package:flutter/foundation.dart';

import 'package:family_os/features/n06_notifications/family_alert_catalog.dart';

/// Platform alert envelope — producers drop this into the Notifications mailbox.
///
/// Stage-1: projecting repos read domain sources directly; later campaigns may
/// enqueue [AlertEvent] into a journal/bus that feeds the same hub.
@immutable
final class AlertEvent {
  const AlertEvent({
    required this.id,
    required this.kind,
    required this.lane,
    required this.at,
    this.childId,
    this.payload = const {},
  });

  final String id;
  final String kind;
  final FamilyAlertLane lane;
  final DateTime at;
  final String? childId;
  final Map<String, Object?> payload;

  factory AlertEvent.fromCatalog({
    required String id,
    required FamilyAlertKindSpec spec,
    required DateTime at,
    String? childId,
    Map<String, Object?> payload = const {},
  }) {
    return AlertEvent(
      id: id,
      kind: spec.kind,
      lane: spec.lane,
      at: at,
      childId: childId,
      payload: payload,
    );
  }
}
