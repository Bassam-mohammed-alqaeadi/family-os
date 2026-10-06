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

  static Future<NativeTelemetryPermissionState>
  requestLocationPermissions() async {
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

  /// Reads this installation's server record through native code. The Android
  /// host authenticates with its Keystore credential and returns only a
  /// sanitized snapshot; the capability never crosses this boundary.
  static Future<NativeChildDeviceSnapshotResult> loadDeviceSnapshot() async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'getDeviceSnapshot',
      );
      return NativeChildDeviceSnapshotResult.fromMap(result);
    } on MissingPluginException {
      return const NativeChildDeviceSnapshotResult.unsupported();
    } on PlatformException {
      return const NativeChildDeviceSnapshotResult.unavailable();
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
      final result = await _channel
          .invokeMapMethod<String, dynamic>('configureAndStart', {
            'apiOrigin': apiOrigin,
            'deviceId': deviceId,
            'deviceCredential': deviceCredential,
          });
      return NativeTelemetryStartResult.fromMap(result);
    } on MissingPluginException {
      return const NativeTelemetryStartResult.unavailable();
    } on PlatformException {
      return const NativeTelemetryStartResult.unavailable();
    }
  }
}

enum NativeChildDeviceSnapshotState {
  ready,
  unconfigured,
  unavailable,
  unsupported,
}

enum NativeChildBatteryStatus { charging, unplugged }

class NativeChildDeviceSnapshot {
  const NativeChildDeviceSnapshot({
    required this.deviceId,
    required this.label,
    required this.batteryLevel,
    required this.batteryStatus,
    required this.lastSeenAt,
  });

  final String deviceId;
  final String label;
  final int? batteryLevel;
  final NativeChildBatteryStatus? batteryStatus;
  final DateTime? lastSeenAt;

  static NativeChildDeviceSnapshot? fromMap(Object? value) {
    if (value is! Map) return null;
    final id = value['id'];
    final rawLabel = value['label'];
    if (id is! String || id.trim().isEmpty || rawLabel is! String) return null;
    final label = rawLabel.trim();
    if (label.isEmpty || label.length > 80) return null;

    final rawBatteryLevel = value['batteryLevel'];
    if (rawBatteryLevel != null && rawBatteryLevel is! int) return null;
    final batteryLevel = rawBatteryLevel as int?;
    if (batteryLevel != null && (batteryLevel < 0 || batteryLevel > 100)) {
      return null;
    }

    final rawBatteryStatus = value['batteryStatus'];
    final batteryStatus = switch (rawBatteryStatus) {
      null => null,
      'charging' => NativeChildBatteryStatus.charging,
      'unplugged' => NativeChildBatteryStatus.unplugged,
      _ => null,
    };
    if (rawBatteryStatus != null && batteryStatus == null) return null;

    final rawLastSeenAt = value['lastSeenAt'];
    final parsedLastSeenAt = rawLastSeenAt is String
        ? DateTime.tryParse(rawLastSeenAt)?.toLocal()
        : null;
    if (rawLastSeenAt != null && parsedLastSeenAt == null) return null;

    return NativeChildDeviceSnapshot(
      deviceId: id.trim(),
      label: label,
      batteryLevel: batteryLevel,
      batteryStatus: batteryStatus,
      lastSeenAt: parsedLastSeenAt,
    );
  }
}

class NativeChildDeviceSnapshotResult {
  const NativeChildDeviceSnapshotResult._(this.state, this.snapshot);

  const NativeChildDeviceSnapshotResult.ready(
    NativeChildDeviceSnapshot snapshot,
  ) : this._(NativeChildDeviceSnapshotState.ready, snapshot);

  const NativeChildDeviceSnapshotResult.unconfigured()
    : this._(NativeChildDeviceSnapshotState.unconfigured, null);

  const NativeChildDeviceSnapshotResult.unavailable()
    : this._(NativeChildDeviceSnapshotState.unavailable, null);

  const NativeChildDeviceSnapshotResult.unsupported()
    : this._(NativeChildDeviceSnapshotState.unsupported, null);

  final NativeChildDeviceSnapshotState state;
  final NativeChildDeviceSnapshot? snapshot;

  factory NativeChildDeviceSnapshotResult.fromMap(
    Map<String, dynamic>? value,
  ) {
    if (value?['status'] == 'ready') {
      final snapshot = NativeChildDeviceSnapshot.fromMap(value?['device']);
      return snapshot == null
          ? const NativeChildDeviceSnapshotResult.unavailable()
          : NativeChildDeviceSnapshotResult.ready(snapshot);
    }
    return switch (value?['status']) {
      'unconfigured' => const NativeChildDeviceSnapshotResult.unconfigured(),
      'unavailable' => const NativeChildDeviceSnapshotResult.unavailable(),
      _ => const NativeChildDeviceSnapshotResult.unavailable(),
    };
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
