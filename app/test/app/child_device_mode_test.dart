import 'package:family_os/core/fs_foundation/fs_session_kernel.dart';
import 'package:family_os/core/fs_foundation/memory_local_database.dart';
import 'package:family_os/app/child_device_mode.dart';
import 'package:family_os/foundation_gate/native_child_telemetry_bridge.dart';
import 'package:flutter_test/flutter_test.dart';

const _childId = '22222222-2222-4222-8222-222222222222';
const _deviceId = '44444444-4444-4444-8444-444444444444';

void main() {
  setUpAll(() async {
    await FsSessionKernel.ensureOpen(override: MemoryLocalDatabase());
  });

  setUp(() async => ChildDeviceMode.clear());

  test(
    'pairing marker stores only UUIDs and yields the child home route',
    () async {
      expect(
        await ChildDeviceMode.markPaired(
          childId: _childId,
          deviceId: _deviceId,
        ),
        isTrue,
      );
      final record = await ChildDeviceMode.readLocal();
      expect(record, isNotNull);
      expect(record!.childId, _childId);
      expect(record.homeLocation, '/scr-chd-004?childId=$_childId');
    },
  );

  test('marker rejects anything that is not a server UUID', () async {
    expect(
      await ChildDeviceMode.markPaired(
        childId: 'demo-child',
        deviceId: _deviceId,
      ),
      isFalse,
    );
    expect(await ChildDeviceMode.readLocal(), isNull);
  });

  test(
    'boot honours the marker only while the native credential exists',
    () async {
      await ChildDeviceMode.markPaired(childId: _childId, deviceId: _deviceId);

      final configured = await ChildDeviceMode.resolveForBoot(
        nativeStatus: () async => NativeTelemetryStatus.fromMap({
          'available': true,
          'running': false,
          'configured': true,
        }),
      );
      expect(configured, isNotNull);

      // Native config gone (data cleared / reinstall): marker is discarded so
      // the app cannot claim child mode without a real paired credential.
      final cleared = await ChildDeviceMode.resolveForBoot(
        nativeStatus: () async => const NativeTelemetryStatus.unavailable(),
      );
      expect(cleared, isNull);
      expect(await ChildDeviceMode.readLocal(), isNull);
    },
  );
}
