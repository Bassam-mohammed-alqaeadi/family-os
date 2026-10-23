import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/foundation_gate/child_screen_time_state_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';

const _channel = MethodChannel('com.familyos.family_os/native_child_telemetry');

void _mockMethodCall(
  Future<Map<String, dynamic>> Function(MethodCall call) handler,
) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_channel, handler);
}

void _mockPlatformException(String code) {
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

  test(
    'a paired handset parses its own state through the native proxy',
    () async {
      final payload = jsonEncode(<String, Object?>{
        'childId': '22222222-2222-4222-8222-222222222222',
        'date': '2026-10-23',
        'policy': <String, Object?>{
          'childId': '22222222-2222-4222-8222-222222222222',
          'configured': true,
          'dailyLimitMinutes': 120,
          'earnedMinutesExtendLimit': true,
        },
        'state': <String, Object?>{
          'kind': 'limited',
          'reasonCode': 'daily_limit',
          'remainingMinutes': 75,
          'capMinutes': 120,
          'countableUsedMinutes': 45,
          'grantedMinutes': 0,
        },
      });

      _mockMethodCall((call) async {
        expect(call.method, 'screenTimeStateRequest');
        expect(call.arguments, isNull);
        return <String, dynamic>{
          'statusCode': 200,
          'body': payload,
        };
      });

      final client = childScreenTimeState();
      final reading = await client.read();

      expect(reading.kind, 'limited');
      expect(reading.remainingMinutes, 75);
      expect(reading.earnedMinutesExtendLimit, isTrue);
      expect(reading.capMinutes, 120);
      expect(reading.countableUsedMinutes, 45);
      expect(reading.reasonCode, 'daily_limit');
    },
  );

  test(
    'an unpaired handset is unauthenticated, not offline',
    () async {
      _mockPlatformException('device_screen_time_not_configured');

      final client = childScreenTimeState();
      try {
        await client.read();
        fail('expected an unauthenticated exception');
      } on FoundationGateApiException catch (e) {
        expect(e.failure, FoundationGateApiFailure.unauthenticated);
      }
    },
  );

  test(
    'an unreachable service is a network fault',
    () async {
      _mockPlatformException('device_screen_time_unreachable');

      final client = childScreenTimeState();
      try {
        await client.read();
        fail('expected a network fault exception');
      } on FoundationGateApiException catch (e) {
        expect(e.failure, FoundationGateApiFailure.networkUnavailable);
      }
    },
  );

  test(
    'a refused answer is access denied',
    () async {
      _mockMethodCall((call) async {
        expect(call.method, 'screenTimeStateRequest');
        return <String, dynamic>{
          'statusCode': 403,
          'body': '{"error":{"code":"FORBIDDEN"}}',
        };
      });

      final client = childScreenTimeState();
      try {
        await client.read();
        fail('expected access denied exception');
      } on FoundationGateApiException catch (e) {
        expect(e.failure, FoundationGateApiFailure.accessDenied);
      }
    },
  );
}

