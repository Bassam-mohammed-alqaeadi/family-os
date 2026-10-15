// S3 D5 (pre-device) — the native bridge's refusals are named correctly. A pairing refusal is
// not a network fault. Tested through a mocked channel: no handset is needed for this part.
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/foundation_gate/child_minutes_balance_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';

const _channel = MethodChannel('com.familyos.family_os/native_child_telemetry');

void _refuse(String code) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_channel, (call) async {
    throw PlatformException(code: code);
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  Future<FoundationGateApiFailure> failureOf(String code) async {
    _refuse(code);
    try {
      await NativeChildMinutesBalanceTransport().readBalance('dev-a');
    } on FoundationGateApiException catch (e) {
      return e.failure;
    }
    throw StateError('expected a refusal');
  }

  test('a scope mismatch or an unconfigured handset is unauthenticated, not offline', () async {
    expect(
      await failureOf('device_minutes_scope_mismatch'),
      FoundationGateApiFailure.unauthenticated,
    );
    expect(
      await failureOf('device_minutes_not_configured'),
      FoundationGateApiFailure.unauthenticated,
    );
  });

  test('an unreachable service is a network fault', () async {
    expect(
      await failureOf('device_minutes_unreachable'),
      FoundationGateApiFailure.networkUnavailable,
    );
  });
}
