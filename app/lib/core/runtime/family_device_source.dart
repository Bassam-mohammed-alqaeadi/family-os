import 'package:flutter/foundation.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/runtime/runtime_data_origin.dart';
// A pure-Dart contract mirror: no widgets, no feature code, no dependency back into this
// file. The server owns what a device's condition is; the client carries the server's
// answer rather than recomputing it, which is why the model has to travel with the
// summary instead of being rebuilt from a battery level at the point of display.
import 'package:family_os/foundation_gate/device_lifecycle.dart';

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
    this.devices = const <FoundationGateGuardianDevice>[],
    this.needsAttention = false,
    this.deviceLabel,
    this.batteryLevel,
    this.batteryStatus,
    this.locationLabel,
    this.lastSeenAt,
  });

  final ChildId childId;
  final ChildDeviceConnectionState connectionState;
  final int deviceCount;

  /// Every device this child has, as the server described it, or empty when the device
  /// source did not read them (the local enrollment path does not).
  ///
  /// A device the server did not describe completely is absent rather than present with
  /// guessed values, so nothing here can be rendered as a condition the server never
  /// stated.
  final List<FoundationGateGuardianDevice> devices;

  /// The server's decision that this child's device needs the guardian's hand.
  ///
  /// Not derived here from battery level, last-seen age or anything else: a client that
  /// computed this could disagree with the server about whether a child is protected, and
  /// a disagreement about that is worse than a missing badge.
  final bool needsAttention;

  /// The selected latest device is shown only when the remote device endpoint
  /// provided it. Null remains an honest "not reported" state.
  final String? deviceLabel;
  final int? batteryLevel;
  final String? batteryStatus;
  final String? locationLabel;
  final DateTime? lastSeenAt;

  bool get hasTelemetry =>
      batteryLevel != null || locationLabel != null || lastSeenAt != null;

  /// The device the guardian should be shown, or null when nothing is asking for them.
  ///
  /// Chosen by the same priority rule the server uses, so the roster and the device
  /// surface name the same device rather than each picking its own.
  FoundationGateGuardianDevice? get attentionDevice =>
      attentionDeviceForChild(devices);
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
