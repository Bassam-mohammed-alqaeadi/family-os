import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/foundation_gate/device_lifecycle.dart';
import 'package:family_os/foundation_gate/device_repair_route.dart';

void main() {
  FoundationGateGuardianDevice deviceIn(
    FoundationGateDeviceHealthState state, {
    String childId = '33333333-3333-4333-8333-333333333333',
  }) {
    return FoundationGateGuardianDevice(
      id: '44444444-4444-4444-8444-444444444444',
      childId: childId,
      deviceLabel: 'هاتف أمانة',
      credentialState: state == FoundationGateDeviceHealthState.revoked
          ? FoundationGateDeviceCredentialState.revoked
          : FoundationGateDeviceCredentialState.active,
      batteryLevel: 41,
      batteryStatus: 'unplugged',
      locationLabel: 'البيت',
      lastSeenAt: DateTime.utc(2026, 10, 6, 9),
      linkedAt: DateTime.utc(2026, 10, 1, 9),
      capabilities: const <FoundationGateDeviceCapability>[],
      health: FoundationGateDeviceHealth(
        state: state,
        reasonCode: 'device_revoked',
        since: null,
        needsAttention: state != FoundationGateDeviceHealthState.active,
      ),
    );
  }

  test('a cut-off device is replaced by pairing that child again', () {
    final device = deviceIn(FoundationGateDeviceHealthState.revoked);

    expect(
      deviceRepairPath(device),
      '/scr-fat-004?childId=33333333-3333-4333-8333-333333333333',
      reason: 'the repair must be the pairing journey for this child, not a screen that '
          'describes the problem',
    );
  });

  test('the child id travels encoded', () {
    final device = deviceIn(
      FoundationGateDeviceHealthState.revoked,
      childId: 'child id&x=1',
    );

    expect(
      deviceRepairPath(device),
      '/scr-fat-004?childId=child%20id%26x%3D1',
      reason: 'an id that is not a plain uuid must not be able to break the route',
    );
  });

  test('no other state is sent to a screen that could not change it', () {
    // Each of these conditions lives on the child's handset. Landing their guardian on a
    // pairing screen would create a second device record and leave the real one untouched,
    // which is a lie dressed as help.
    for (final state in <FoundationGateDeviceHealthState>[
      FoundationGateDeviceHealthState.awaitingPairing,
      FoundationGateDeviceHealthState.neverReported,
      FoundationGateDeviceHealthState.active,
      FoundationGateDeviceHealthState.stale,
      FoundationGateDeviceHealthState.offline,
    ]) {
      expect(
        deviceRepairPath(deviceIn(state)),
        isNull,
        reason: '$state must not be offered an action this handset cannot carry out',
      );
    }
  });
}
