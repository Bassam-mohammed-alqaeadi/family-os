import 'package:flutter/foundation.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/runtime/runtime_data_origin.dart';

/// The honest connection state available for a child from the device source.
///
/// This deliberately does not infer location, battery or safety from a device
/// identifier. Those facts require their own fresh, authorized sources.
enum ChildDeviceConnectionState {
  unavailable,
  noDevice,
  pairing,
  active,
  needsAttention,
}

@immutable
final class FamilyChildDeviceSummary {
  const FamilyChildDeviceSummary({
    required this.childId,
    required this.connectionState,
    required this.deviceCount,
    this.deviceLabel,
    this.batteryLevel,
    this.batteryStatus,
    this.locationLabel,
    this.lastSeenAt,
  });

  final ChildId childId;
  final ChildDeviceConnectionState connectionState;
  final int deviceCount;

  /// The selected latest device is shown only when the remote device endpoint
  /// provided it. Null remains an honest "not reported" state.
  final String? deviceLabel;
  final int? batteryLevel;
  final String? batteryStatus;
  final String? locationLabel;
  final DateTime? lastSeenAt;

  bool get hasTelemetry =>
      batteryLevel != null || locationLabel != null || lastSeenAt != null;
}

@immutable
final class FamilyDeviceSnapshot {
  const FamilyDeviceSnapshot({
    required this.familyId,
    required this.origin,
    required this.children,
    this.observedAt,
  });

  const FamilyDeviceSnapshot.unavailable()
    : familyId = null,
      origin = RuntimeDataOrigin.unavailable,
      children = const [],
      observedAt = null;

  final FamilyId? familyId;
  final RuntimeDataOrigin origin;
  final List<FamilyChildDeviceSummary> children;
  final DateTime? observedAt;

  FamilyChildDeviceSummary? forChild(ChildId childId) {
    for (final child in children) {
      if (child.childId == childId) return child;
    }
    return null;
  }
}

/// Typed source boundary for family-scoped device summaries.
abstract interface class FamilyDeviceSource
    implements ValueListenable<FamilyDeviceSnapshot> {
  Future<FamilyDeviceSnapshot> load(FamilyId familyId);

  void dispose();
}

/// Honest default while a composition root has no device source configured.
final class UnavailableFamilyDeviceSource extends ChangeNotifier
    implements FamilyDeviceSource {
  FamilyDeviceSnapshot _value = const FamilyDeviceSnapshot.unavailable();

  @override
  FamilyDeviceSnapshot get value => _value;

  @override
  Future<FamilyDeviceSnapshot> load(FamilyId familyId) async {
    _value = const FamilyDeviceSnapshot.unavailable();
    notifyListeners();
    return _value;
  }
}
