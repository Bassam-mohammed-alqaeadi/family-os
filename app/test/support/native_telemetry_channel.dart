import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const MethodChannel _nativeChildTelemetryChannel = MethodChannel(
  'com.familyos.family_os/native_child_telemetry',
);

/// Binds a silent handler for the native child-telemetry channel.
///
/// Widget tests have no platform side, and an unbound MethodChannel future
/// never completes — a screen that waits on the paired handset (the consent
/// ledger read, the disclosure recording) would spin its loader forever and
/// time out `pumpAndSettle`. Answering `null` makes the bridge take its
/// honest "native unavailable" path, exactly as a non-Android host would.
///
/// Call from `setUp` (or inside a `testWidgets` before pumping).
void mockNativeChildTelemetryChannel() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_nativeChildTelemetryChannel, (call) async => null);
  addTearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_nativeChildTelemetryChannel, null);
  });
}
