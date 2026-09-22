import 'package:flutter/foundation.dart';

/// Lifecycle of a parent-facing SOS alert (S-SEC-026 state machine).
enum SosAlertStatus {
  /// Live broadcast — siren + map + auto-call path active.
  active,

  /// Parent acknowledged / arrived — alert closed, audit retained.
  resolved,
}

/// Parent SOS alert board payload (SCR-FAT-018 / S-SEC-026…030).
///
/// Rule 23: never plant person names in screen defaults — inject via
/// [SosAlertRepository] fixtures in tests / demos only.
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
    this.pinFracX = 0.62,
    this.pinFracY = 0.42,
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

  /// Display labels for who received the piercing alert (father/mother/backup).
  final List<String> recipientLabels;

  final SosAlertStatus status;

  /// Fractional pin on the stylized map canvas (0–1).
  final double pinFracX;
  final double pinFracY;

  bool get isActive => status == SosAlertStatus.active;

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
    double? pinFracX,
    double? pinFracY,
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
      pinFracX: pinFracX ?? this.pinFracX,
      pinFracY: pinFracY ?? this.pinFracY,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SosAlert &&
          id == other.id &&
          childId == other.childId &&
          childDisplayName == other.childDisplayName &&
          childEmoji == other.childEmoji &&
          pressedAt == other.pressedAt &&
          locationLabel == other.locationLabel &&
          batteryPercent == other.batteryPercent &&
          movementLabel == other.movementLabel &&
          accuracyMeters == other.accuracyMeters &&
          listEquals(recipientLabels, other.recipientLabels) &&
          status == other.status &&
          pinFracX == other.pinFracX &&
          pinFracY == other.pinFracY;

  @override
  int get hashCode => Object.hash(
        id,
        childId,
        childDisplayName,
        childEmoji,
        pressedAt,
        locationLabel,
        batteryPercent,
        movementLabel,
        accuracyMeters,
        Object.hashAll(recipientLabels),
        status,
        pinFracX,
        pinFracY,
      );
}
