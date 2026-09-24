/// SOS domain - incident / location / delivery / connection (UI slice).
library;

import 'package:flutter/foundation.dart';

/// Incident lifecycle (separate from delivery / location).
enum SosAlertStatus {
  active,
  acknowledged,
  escalating,
  resolved,
}

/// How an open incident was closed.
enum SosTerminalReason {
  helped,
  falseAlarm,
  other,
}

/// Location honesty (OD-16) — independent of incident status.
enum SosLocationClass {
  ready,
  acquiring,
  stale,
  unavailable,
}

/// Per-channel delivery honesty (OD-09 / OD-20).
enum SosDeliveryClass {
  pending,
  delivered,
  failed,
  unavailable,
  notConfigured,
}

enum SosConnectionClass {
  online,
  degraded,
  offline,
}

/// One recipient×channel delivery row (mock-first).
@immutable
final class SosDeliveryRow {
  const SosDeliveryRow({
    required this.recipientId,
    required this.channel,
    required this.status,
  });

  final String recipientId;
  final String channel; // push | in_app | sms | call
  final SosDeliveryClass status;

  SosDeliveryRow copyWith({SosDeliveryClass? status}) => SosDeliveryRow(
        recipientId: recipientId,
        channel: channel,
        status: status ?? this.status,
      );
}

/// Parent SOS incident payload (SCR-FAT-018 / CHD-006).
@immutable
final class SosAlert {
  const SosAlert({
    required this.id,
    required this.childId,
    required this.childDisplayName,
    required this.childEmoji,
    required this.pressedAt,
    required this.locationLabel,
    required this.batteryPercent,
    required this.movementLabel,
    required this.accuracyMeters,
    required this.recipientLabels,
    this.status = SosAlertStatus.active,
    this.terminalReason,
    this.locationClass = SosLocationClass.acquiring,
    this.connectionClass = SosConnectionClass.online,
    this.deliveries = const [],
    this.acknowledgedAt,
    this.pinFracX = 0.62,
    this.pinFracY = 0.42,
    this.panicQuietAtTrigger = false,
  });

  final String id;
  final String childId;
  final String childDisplayName;
  final String childEmoji;
  final DateTime pressedAt;
  final String locationLabel;
  final int batteryPercent;
  final String movementLabel;
  final int accuracyMeters;
  final List<String> recipientLabels;
  final SosAlertStatus status;
  final SosTerminalReason? terminalReason;
  final SosLocationClass locationClass;
  final SosConnectionClass connectionClass;
  final List<SosDeliveryRow> deliveries;
  final DateTime? acknowledgedAt;
  final double pinFracX;
  final double pinFracY;
  final bool panicQuietAtTrigger;

  bool get isOpen =>
      status == SosAlertStatus.active ||
      status == SosAlertStatus.acknowledged ||
      status == SosAlertStatus.escalating;

  bool get isActive => isOpen; // backward-compatible name for open incident

  bool get isResolved => status == SosAlertStatus.resolved;

  SosAlert copyWith({
    String? id,
    String? childId,
    String? childDisplayName,
    String? childEmoji,
    DateTime? pressedAt,
    String? locationLabel,
    int? batteryPercent,
    String? movementLabel,
    int? accuracyMeters,
    List<String>? recipientLabels,
    SosAlertStatus? status,
    SosTerminalReason? terminalReason,
    bool clearTerminalReason = false,
    SosLocationClass? locationClass,
    SosConnectionClass? connectionClass,
    List<SosDeliveryRow>? deliveries,
    DateTime? acknowledgedAt,
    bool clearAcknowledgedAt = false,
    double? pinFracX,
    double? pinFracY,
    bool? panicQuietAtTrigger,
  }) {
    return SosAlert(
      id: id ?? this.id,
      childId: childId ?? this.childId,
      childDisplayName: childDisplayName ?? this.childDisplayName,
      childEmoji: childEmoji ?? this.childEmoji,
      pressedAt: pressedAt ?? this.pressedAt,
      locationLabel: locationLabel ?? this.locationLabel,
      batteryPercent: batteryPercent ?? this.batteryPercent,
      movementLabel: movementLabel ?? this.movementLabel,
      accuracyMeters: accuracyMeters ?? this.accuracyMeters,
      recipientLabels: recipientLabels ?? this.recipientLabels,
      status: status ?? this.status,
      terminalReason:
          clearTerminalReason ? null : (terminalReason ?? this.terminalReason),
      locationClass: locationClass ?? this.locationClass,
      connectionClass: connectionClass ?? this.connectionClass,
      deliveries: deliveries ?? this.deliveries,
      acknowledgedAt: clearAcknowledgedAt
          ? null
          : (acknowledgedAt ?? this.acknowledgedAt),
      pinFracX: pinFracX ?? this.pinFracX,
      pinFracY: pinFracY ?? this.pinFracY,
      panicQuietAtTrigger: panicQuietAtTrigger ?? this.panicQuietAtTrigger,
    );
  }
}
