import 'package:flutter/foundation.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';

import 'location_fix.dart';

/// Shared SOS↔Location honesty vocabulary (L-S12 / LOC handoff).
///
/// Maps 1:1 with SOS Final presentation words — FS-001 owns the fact;
/// SOS Final owns incident lifecycle binding.
enum SosLocationHonesty { acquiring, located, staleLastKnown, unavailable }

extension SosLocationHonestyWire on SosLocationHonesty {
  /// Child-facing status words only during ACTIVE SOS (Q-LOC-09).
  String get childStatusWord => switch (this) {
    SosLocationHonesty.acquiring => 'acquiring',
    SosLocationHonesty.located => 'located',
    SosLocationHonesty.staleLastKnown => 'stale',
    SosLocationHonesty.unavailable => 'unavailable',
  };

  String get wireName => switch (this) {
    SosLocationHonesty.acquiring => 'ACQUIRING',
    SosLocationHonesty.located => 'LOCATED',
    SosLocationHonesty.staleLastKnown => 'STALE_LAST_KNOWN',
    SosLocationHonesty.unavailable => 'UNAVAILABLE',
  };

  static SosLocationHonesty fromAcquisition(LocationAcquisitionStatus s) {
    return switch (s) {
      LocationAcquisitionStatus.acquiring => SosLocationHonesty.acquiring,
      LocationAcquisitionStatus.located => SosLocationHonesty.located,
      LocationAcquisitionStatus.staleLastKnown =>
        SosLocationHonesty.staleLastKnown,
      LocationAcquisitionStatus.unavailable => SosLocationHonesty.unavailable,
    };
  }
}

/// Location evidence pack attached to an SOS incident (facts only).
@immutable
final class SosLocationEvidence {
  const SosLocationEvidence({
    required this.incidentId,
    required this.familyId,
    required this.childId,
    required this.deviceId,
    required this.honesty,
    required this.attachedAt,
    this.fixId,
    this.latitude,
    this.longitude,
    this.accuracyMeters,
  });

  final String incidentId;
  final FamilyId familyId;
  final ChildId childId;
  final DeviceId deviceId;
  final SosLocationHonesty honesty;
  final DateTime attachedAt;
  final String? fixId;
  final double? latitude;
  final double? longitude;
  final double? accuracyMeters;

  bool get hasCoordinates =>
      latitude != null &&
      longitude != null &&
      latitude!.isFinite &&
      longitude!.isFinite;
}

/// Result of FS-001 attach attempt — never blocks SOS fire.
@immutable
final class SosLocationAttachResult {
  const SosLocationAttachResult({
    required this.firedWithoutLocationBlocked,
    required this.honesty,
    required this.childStatusWord,
    this.evidence,
  });

  /// Always true: GPS failure must not block SOS (SOS OD-16 / L-S12).
  final bool firedWithoutLocationBlocked;
  final SosLocationHonesty honesty;
  final String childStatusWord;
  final SosLocationEvidence? evidence;
}

/// Break-glass must never be treated as Find My Child (Q-LOC-10).
abstract final class SosBreakGlassLocationLaw {
  static const bool breakGlassIsFindMyChild = false;

  static void assertNotFindMyChild() {
    assert(
      !breakGlassIsFindMyChild,
      'Break-glass ≠ Find My Child (Q-LOC-10 / LOC-OD-10)',
    );
  }
}
