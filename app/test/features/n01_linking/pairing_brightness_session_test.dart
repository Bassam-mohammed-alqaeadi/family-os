import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/features/n01_linking/pairing_brightness_session.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('family_os_test/pairing_brightness');

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('maximize captures and restore returns the exact prior value', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'maximize') return 0.42;
          return null;
        });
    final session = PairingBrightnessSession(channel: channel);

    await session.maximize();
    await session.restore();
    await session.restore();

    expect(calls.map((call) => call.method), ['maximize', 'restore']);
    expect(
      (calls.last.arguments as Map<Object?, Object?>)['brightness'],
      0.42,
    );
  });

  test('dispose-style early restore is honored after maximize resolves', () async {
    final calls = <MethodCall>[];
    final maximizeResult = Completer<double>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'maximize') return maximizeResult.future;
          return null;
        });
    final session = PairingBrightnessSession(channel: channel);

    final maximize = session.maximize();
    await session.restore();
    maximizeResult.complete(-1);
    await maximize;

    expect(calls.map((call) => call.method), ['maximize', 'restore']);
    expect(
      (calls.last.arguments as Map<Object?, Object?>)['brightness'],
      -1,
    );
  });
}
