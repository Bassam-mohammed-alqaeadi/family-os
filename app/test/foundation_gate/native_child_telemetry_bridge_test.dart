import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/foundation_gate/native_child_telemetry_bridge.dart';

void main() {
  test('sanitized native device snapshot parses genuine nullable telemetry', () {
    final result = NativeChildDeviceSnapshotResult.fromMap({
      'status': 'ready',
      'device': {
        'id': '76331550-5bab-4bc4-9f56-d98c9d80ef25',
        'label': 'Amani Android',
        'batteryLevel': 62,
        'batteryStatus': 'charging',
        'lastSeenAt': '2026-10-06T11:30:00.000Z',
      },
    });

    expect(result.state, NativeChildDeviceSnapshotState.ready);
    expect(result.snapshot?.deviceId, '76331550-5bab-4bc4-9f56-d98c9d80ef25');
    expect(result.snapshot?.label, 'Amani Android');
    expect(result.snapshot?.batteryLevel, 62);
    expect(result.snapshot?.batteryStatus, NativeChildBatteryStatus.charging);
    expect(result.snapshot?.lastSeenAt, isNotNull);
  });

  test('null telemetry stays null instead of becoming demo values', () {
    final result = NativeChildDeviceSnapshotResult.fromMap({
      'status': 'ready',
      'device': {
        'id': '76331550-5bab-4bc4-9f56-d98c9d80ef25',
        'label': 'Child handset',
        'batteryLevel': null,
        'batteryStatus': null,
        'lastSeenAt': null,
      },
    });

    expect(result.state, NativeChildDeviceSnapshotState.ready);
    expect(result.snapshot?.batteryLevel, isNull);
    expect(result.snapshot?.batteryStatus, isNull);
    expect(result.snapshot?.lastSeenAt, isNull);
  });

  test('malformed native snapshot fails closed as unavailable', () {
    final invalidBattery = NativeChildDeviceSnapshotResult.fromMap({
      'status': 'ready',
      'device': {
        'id': '76331550-5bab-4bc4-9f56-d98c9d80ef25',
        'label': 'Child handset',
        'batteryLevel': 101,
        'batteryStatus': 'charging',
        'lastSeenAt': null,
      },
    });
    final invalidTimestamp = NativeChildDeviceSnapshotResult.fromMap({
      'status': 'ready',
      'device': {
        'id': '76331550-5bab-4bc4-9f56-d98c9d80ef25',
        'label': 'Child handset',
        'batteryLevel': 20,
        'batteryStatus': 'unplugged',
        'lastSeenAt': 'not-a-timestamp',
      },
    });

    expect(invalidBattery.state, NativeChildDeviceSnapshotState.unavailable);
    expect(invalidBattery.snapshot, isNull);
    expect(invalidTimestamp.state, NativeChildDeviceSnapshotState.unavailable);
    expect(invalidTimestamp.snapshot, isNull);
  });
}
