import 'package:flutter/foundation.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';

/// Why the server did not confirm a device revocation.
enum DeviceRevokeFailure {
  invalidInput,
  conflict,
  accessDenied,
  sessionInvalid,
  serviceUnavailable,
  networkUnavailable,
  unavailable,
}

/// The server's answer to cutting one child device off.
///
/// [isConfirmed] is true only after the server's revocation write succeeded or
/// durably replayed. A screen may claim the device is cut — and only then close
/// the local mirror — on a confirmed result; every other outcome is a refusal
/// or an unknown, never a local pretend-success.
@immutable
final class DeviceRevokeResult {
  const DeviceRevokeResult.confirmed() : failure = null;

  const DeviceRevokeResult.failed(this.failure);

  final DeviceRevokeFailure? failure;

  bool get isConfirmed => failure == null;
}

/// Main-app device-revocation boundary.
///
/// The device summary source deliberately grants no mutation authority; this
/// port is the one write it may not perform. It fails closed: no configured
/// remote capability means an honest `unavailable` result, never a local
/// revocation presented as server truth.
abstract interface class FamilyDeviceRevocationSource {
  /// [reasonCode] is the server's closed vocabulary
  /// (`lost` · `stolen` · `replaced` · `no_longer_used` · `other`) or null when
  /// the guardian did not classify the loss.
  Future<DeviceRevokeResult> revokeDevice({
    required FamilyId familyId,
    required ChildId childId,
    required String deviceId,
    required String? reasonCode,
    required String idempotencyKey,
  });

  void dispose();
}

final class UnavailableFamilyDeviceRevocationSource
    implements FamilyDeviceRevocationSource {
  @override
  Future<DeviceRevokeResult> revokeDevice({
    required FamilyId familyId,
    required ChildId childId,
    required String deviceId,
    required String? reasonCode,
    required String idempotencyKey,
  }) async => const DeviceRevokeResult.failed(DeviceRevokeFailure.unavailable);

  @override
  void dispose() {}
}
