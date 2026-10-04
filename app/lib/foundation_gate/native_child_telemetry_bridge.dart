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

  /// Opens this app's Android settings page after the person has seen the
  /// background-location rationale. Returning true means Settings opened, not
  /// that any permission was granted.
  static Future<bool> openLocationSettings() async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>('openLocationSettings');
      return result?['opened'] == true;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  /// Opens a native QR view for a code that remains in Flutter widget memory.
  static Future<bool> showPairingQr({
    required String pairingCode,
    required String title,
    required String body,
    required String contentDescription,
    required String dismissLabel,
  }) async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>('showPairingQr', {
        'pairingCode': pairingCode,
        'title': title,
        'body': body,
        'contentDescription': contentDescription,
        'dismissLabel': dismissLabel,
      });
      return result?['shown'] == true;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  /// Scans an actual QR image with Android's camera and returns only a valid
  /// one-time pairing capability. Cancellation or unavailable camera returns null.
  static Future<String?> scanPairingCode({required String contentDescription}) async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>('scanPairingCode', {
        'contentDescription': contentDescription,
      });
      final code = result?['pairingCode'];
      return code is String && RegExp(r'^[A-Za-z0-9_-]{32,128}$').hasMatch(code)
          ? code
          : null;
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
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

  /// Starts Child Mode again using only the configuration already encrypted in
  /// Android Keystore. The device credential never returns to Dart.
  static Future<NativeTelemetryStartResult> startStored() async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>('startStored');
      return NativeTelemetryStartResult.fromMap(result);
    } on MissingPluginException {
      return const NativeTelemetryStartResult.unavailable();
    } on PlatformException {
      return const NativeTelemetryStartResult.unavailable();
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
