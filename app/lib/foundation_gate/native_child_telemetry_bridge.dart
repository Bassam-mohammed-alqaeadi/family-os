import 'package:flutter/services.dart';

/// Android boundary for the real child-device telemetry engine.
///
/// This has no mock implementation. On unsupported platforms it reports that
/// native telemetry is unavailable; it never manufactures sensor readings or a
/// successful pairing state.
class NativeChildTelemetryBridge {
  NativeChildTelemetryBridge._();

  static const MethodChannel _channel = MethodChannel(
    'com.familyos.family_os/native_child_telemetry',
  );

  static Future<NativeTelemetryPermissionState> requestLocationPermissions() async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'requestLocationPermissions',
      );
      return NativeTelemetryPermissionState.fromMap(result);
    } on MissingPluginException {
      return const NativeTelemetryPermissionState.unavailable();
    } on PlatformException {
      return const NativeTelemetryPermissionState.unavailable();
    }
  }

  static Future<NativeTelemetryStatus> status() async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>('status');
      return NativeTelemetryStatus.fromMap(result);
    } on MissingPluginException {
      return const NativeTelemetryStatus.unavailable();
    } on PlatformException {
      return const NativeTelemetryStatus.unavailable();
    }
  }

  static Future<bool> stop() async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>('stop');
      return result?['stopped'] == true;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  /// Moves the one-time device credential directly into Android Keystore-backed
  /// storage, then starts the foreground service only if real location access
  /// has been granted by the device owner/guardian.
  static Future<NativeTelemetryStartResult> configureAndStart({
    required String apiOrigin,
    required String deviceId,
    required String deviceCredential,
  }) async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'configureAndStart',
        {
          'apiOrigin': apiOrigin,
          'deviceId': deviceId,
          'deviceCredential': deviceCredential,
        },
      );
      return NativeTelemetryStartResult.fromMap(result);
    } on MissingPluginException {
      return const NativeTelemetryStartResult.unavailable();
    } on PlatformException {
      return const NativeTelemetryStartResult.unavailable();
    }
  }
}

class NativeTelemetryPermissionState {
  const NativeTelemetryPermissionState({
    required this.fineLocationGranted,
    required this.backgroundLocationGranted,
    required this.available,
  });

  const NativeTelemetryPermissionState.unavailable()
    : fineLocationGranted = false,
      backgroundLocationGranted = false,
      available = false;

  final bool fineLocationGranted;
  final bool backgroundLocationGranted;
  final bool available;

  factory NativeTelemetryPermissionState.fromMap(Map<String, dynamic>? value) =>
      NativeTelemetryPermissionState(
        fineLocationGranted: value?['fineLocationGranted'] == true,
        backgroundLocationGranted: value?['backgroundLocationGranted'] == true,
        available: value?['available'] == true,
      );
}

class NativeTelemetryStartResult {
  const NativeTelemetryStartResult({
    required this.started,
    required this.reason,
  });

  const NativeTelemetryStartResult.unavailable()
    : started = false,
      reason = 'native_telemetry_unavailable';

  final bool started;
  final String reason;

  factory NativeTelemetryStartResult.fromMap(Map<String, dynamic>? value) =>
      NativeTelemetryStartResult(
        started: value?['started'] == true,
        reason: value?['reason'] as String? ?? 'native_telemetry_unavailable',
      );
}


class NativeTelemetryStatus {
  const NativeTelemetryStatus({
    required this.available,
    required this.running,
    required this.configured,
    required this.fineLocationGranted,
    required this.backgroundLocationGranted,
  });

  const NativeTelemetryStatus.unavailable()
    : available = false,
      running = false,
      configured = false,
      fineLocationGranted = false,
      backgroundLocationGranted = false;

  final bool available;
  final bool running;
  final bool configured;
  final bool fineLocationGranted;
  final bool backgroundLocationGranted;

  factory NativeTelemetryStatus.fromMap(Map<String, dynamic>? value) =>
      NativeTelemetryStatus(
        available: value?['available'] == true,
        running: value?['running'] == true,
        configured: value?['configured'] == true,
        fineLocationGranted: value?['fineLocationGranted'] == true,
        backgroundLocationGranted: value?['backgroundLocationGranted'] == true,
      );
}
