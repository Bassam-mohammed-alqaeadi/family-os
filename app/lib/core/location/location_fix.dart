import 'package:flutter/foundation.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';

import 'geo_point.dart';

/// Honest acquisition state — never claim located without coordinates.
enum LocationAcquisitionStatus {
  /// Fix in progress (no usable coordinates yet).
  acquiring,

  /// Fresh usable fix with coordinates.
  located,

  /// Last-known coordinates; may be stale.
  staleLastKnown,

  /// No coordinates available.
  unavailable,
}

extension LocationAcquisitionStatusWire on LocationAcquisitionStatus {
  String get wireName => switch (this) {
    LocationAcquisitionStatus.acquiring => 'ACQUIRING',
    LocationAcquisitionStatus.located => 'LOCATED',
    LocationAcquisitionStatus.staleLastKnown => 'STALE_LAST_KNOWN',
    LocationAcquisitionStatus.unavailable => 'UNAVAILABLE',
  };

  static LocationAcquisitionStatus parse(String raw) {
    switch (raw.trim().toUpperCase()) {
      case 'ACQUIRING':
        return LocationAcquisitionStatus.acquiring;
      case 'LOCATED':
        return LocationAcquisitionStatus.located;
      case 'STALE_LAST_KNOWN':
      case 'STALE':
        return LocationAcquisitionStatus.staleLastKnown;
      case 'UNAVAILABLE':
        return LocationAcquisitionStatus.unavailable;
      default:
        throw FormatException('Unknown LocationAcquisitionStatus: $raw');
    }
  }
}

/// One trail sample (Class A fact). Identity envelope required (LOC-OD-18).
@immutable
final class LocationFix {
  const LocationFix({
    required this.id,
    required this.familyId,
    required this.childId,
    required this.deviceId,
    required this.acquisition,
    required this.recordedAt,
    this.point,
    this.accuracyMeters,
    this.integritySoftWarning = false,
  });

  final String id;
  final FamilyId familyId;
  final ChildId childId;
  final DeviceId deviceId;
  final LocationAcquisitionStatus acquisition;
  final GeoPoint? point;
  final double? accuracyMeters;

  /// Soft parent warning signal only (Q-LOC-07=C) — not a score.
  final bool integritySoftWarning;
  final DateTime recordedAt;

  bool get hasCoordinates => point != null && point!.isValid;

  /// Domain invariant: located/stale require coordinates; unavailable/acquiring
  /// must not pretend to be a successful live fix.
  bool get isHonest {
    switch (acquisition) {
      case LocationAcquisitionStatus.located:
      case LocationAcquisitionStatus.staleLastKnown:
        return hasCoordinates;
      case LocationAcquisitionStatus.acquiring:
      case LocationAcquisitionStatus.unavailable:
        return true;
    }
  }
}

/// Thrown when a fix would pretend GPS success dishonestly.
final class DishonestLocationFixException implements Exception {
  const DishonestLocationFixException(this.reason);
  final String reason;

  @override
  String toString() => 'DishonestLocationFixException: $reason';
}
