import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/features/n12_devices/device_health_seam.dart';

void main() {
  test('device health seam scopes device list by family id', () async {
    final seam = FakeDeviceHealthSeam(
      initial: [
        const DeviceHealthSnapshot(
          deviceId: 'dev_a',
          familyId: 'fam_a',
          childId: 'child_a',
          enrollmentId: 'enr_a',
          displayLabel: 'A',
          modelLabel: 'Model A',
          level: DeviceHealthLevel.healthy,
          permissions: [],
        ),
        const DeviceHealthSnapshot(
          deviceId: 'dev_b',
          familyId: 'fam_b',
          childId: 'child_b',
          enrollmentId: 'enr_b',
          displayLabel: 'B',
          modelLabel: 'Model B',
          level: DeviceHealthLevel.healthy,
          permissions: [],
        ),
      ],
    );

    final scopedA = await seam.watchDevices(familyId: 'fam_a').first;
    final scopedB = await seam.watchDevices(familyId: 'fam_b').first;

    expect(scopedA, hasLength(1));
    expect(scopedA.first.deviceId, 'dev_a');
    expect(scopedB, hasLength(1));
    expect(scopedB.first.deviceId, 'dev_b');
  });

  test('unscoped device health watch fails closed (empty)', () async {
    final seam = FakeDeviceHealthSeam(
      initial: [
        const DeviceHealthSnapshot(
          deviceId: 'dev_a',
          familyId: 'fam_a',
          childId: 'child_a',
          enrollmentId: 'enr_a',
          displayLabel: 'A',
          modelLabel: 'Model A',
          level: DeviceHealthLevel.healthy,
          permissions: [],
        ),
      ],
    );
    final unscoped = await seam.watchDevices().first;
    expect(unscoped, isEmpty);
  });
}
