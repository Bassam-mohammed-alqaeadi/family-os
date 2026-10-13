import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/foundation_gate/native_child_telemetry_bridge.dart';

import 'support/native_telemetry_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const healthy = <String, Object?>{
    'available': true,
    'state': 'fully_protected',
    'reasons': <String>[],
    'reason': null,
    'queueDepth': 0,
    'live': true,
    'backgroundLocationGranted': true,
    'notificationsGranted': true,
  };

  group('NativeProtectionState.fromMap', () {
    test('null or unavailable map yields unavailable', () {
      expect(
        NativeProtectionState.fromMap(null).available,
        isFalse,
      );
      expect(
        NativeProtectionState.fromMap({'available': false}).state,
        NativeProtectionVerdict.unavailable,
      );
    });

    test('unknown state word is never guessed', () {
      final parsed = NativeProtectionState.fromMap({
        ...healthy,
        'state': 'super_protected',
      });
      expect(parsed.state, NativeProtectionVerdict.unavailable);
      expect(parsed.available, isFalse);
    });

    test('healthy map parses fully', () {
      final parsed = NativeProtectionState.fromMap(healthy);
      expect(parsed.available, isTrue);
      expect(parsed.state, NativeProtectionVerdict.fullyProtected);
      expect(parsed.queueDepth, 0);
      expect(parsed.live, isTrue);
      expect(parsed.backgroundLocationGranted, isTrue);
    });

    test('degraded reasons and queue depth survive the crossing', () {
      final parsed = NativeProtectionState.fromMap({
        ...healthy,
        'state': 'degraded',
        'reasons': ['battery_restricted', 'offline'],
        'queueDepth': 7,
      });
      expect(parsed.state, NativeProtectionVerdict.degraded);
      expect(parsed.reasons, ['battery_restricted', 'offline']);
      expect(parsed.queueDepth, 7);
    });
  });

  group('NativeProtectionState.effective (overlay distrust)', () {
    test('explicit grant loss distrusts a healthy verdict', () {
      final parsed = NativeProtectionState.fromMap({
        ...healthy,
        'backgroundLocationGranted': false,
      }).effective;
      expect(parsed.state, NativeProtectionVerdict.stopped);
      expect(parsed.reason, 'permission_revoked');
    });

    test('missing overlay never flips the verdict', () {
      final parsed = NativeProtectionState.fromMap({
        ...healthy,
      }..remove('backgroundLocationGranted'))
          .effective;
      expect(parsed.state, NativeProtectionVerdict.fullyProtected);
    });

    test('stopped verdicts pass through untouched', () {
      final parsed = NativeProtectionState.fromMap({
        ...healthy,
        'state': 'stopped',
        'reason': 'service_down',
        'live': false,
        'backgroundLocationGranted': false,
      }).effective;
      expect(parsed.state, NativeProtectionVerdict.stopped);
      expect(parsed.reason, 'service_down');
    });
  });

  group('NativeBatteryGuidance.fromMap', () {
    test('unavailable on null or missing flag', () {
      expect(NativeBatteryGuidance.fromMap(null).available, isFalse);
      expect(
        NativeBatteryGuidance.fromMap({'vendor': 'xiaomi'}).available,
        isFalse,
      );
    });

    test('full map parses', () {
      final parsed = NativeBatteryGuidance.fromMap({
        'available': true,
        'vendor': 'xiaomi',
        'action': 'android.settings.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS',
        'package': 'com.miui.powerkeeper',
        'activity': 'com.miui.powerkeeper.ui.HiddenAppsConfigActivity',
        'stepsKey': 'oem_xiaomi',
      });
      expect(parsed.available, isTrue);
      expect(parsed.vendor, 'xiaomi');
      expect(parsed.stepsKey, 'oem_xiaomi');
    });
  });

  group('bridge channel path (canned mock)', () {
    test('protectionState round-trips through the method channel', () async {
      mockNativeChildTelemetryChannel(
        responses: {'protectionState': healthy},
      );
      final state = await NativeChildTelemetryBridge.protectionState();
      expect(state.available, isTrue);
      expect(state.state, NativeProtectionVerdict.fullyProtected);
    });

    test('uncanned methods still take the unavailable path', () async {
      mockNativeChildTelemetryChannel();
      expect(
        (await NativeChildTelemetryBridge.protectionState()).available,
        isFalse,
      );
      expect(
        (await NativeChildTelemetryBridge.batteryGuidance()).available,
        isFalse,
      );
      expect(
        await NativeChildTelemetryBridge.openBatterySettings(),
        isFalse,
      );
    });

    test('batteryGuidance + openBatterySettings round-trip', () async {
      mockNativeChildTelemetryChannel(
        responses: {
          'batteryGuidance': {
            'available': true,
            'vendor': 'xiaomi',
            'action': 'a',
            'package': 'p',
            'activity': 'c',
            'stepsKey': 'oem_xiaomi',
          },
          'openBatterySettings': {'opened': true},
        },
      );
      final guidance = await NativeChildTelemetryBridge.batteryGuidance();
      expect(guidance.available, isTrue);
      expect(guidance.stepsKey, 'oem_xiaomi');
      expect(await NativeChildTelemetryBridge.openBatterySettings(), isTrue);
    });
  });
}
