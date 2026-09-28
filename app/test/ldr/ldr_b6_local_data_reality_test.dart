import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/features/n02_day/active_call_repository.dart';
import 'package:family_os/features/n02_day/call_history_repository.dart';
import 'package:family_os/features/n12_devices/device_health_seam.dart';

void main() {
  test('LDR-B6 call history stage1 is empty (no fake call log)', () async {
    final snap = await stage1CallHistoryRepository.load();
    expect(snap.isEmpty, isTrue);
  });

  test('LDR-B6 active call stage1 has no planted calls', () async {
    final call = await stage1ActiveCallRepository.load('any');
    expect(call, isNull);
  });

  test('LDR-B6 device health stage1 is empty (not Fake.demo)', () {
    expect(stage1DeviceHealthSeam.devices, isEmpty);
  });
}
