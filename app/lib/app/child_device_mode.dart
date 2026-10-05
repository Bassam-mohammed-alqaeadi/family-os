import 'package:family_os/core/fs_foundation/fs_session_kernel.dart';
import 'package:family_os/core/prefs_misc/prefs_misc_local_persistence.dart';

import 'package:family_os/foundation_gate/foundation_gate_configuration.dart';
import 'package:family_os/foundation_gate/native_child_telemetry_bridge.dart';

/// Non-secret, local record that this handset was paired as a child device.
///
/// It holds only opaque server UUIDs (child / device) so the app can
/// boot straight into the child home after a successful pairing. The device
/// credential itself never comes here — it lives exclusively in the Android
/// Keystore-backed native store ([NativeChildTelemetryBridge]).
///
/// The marker is advisory: on cold start it is honoured only when the native
/// side still reports a configured telemetry service. If the native config is
/// gone (data cleared, reinstall), the marker is discarded so the app can never
/// claim "child mode" without a real paired credential behind it.
final class ChildDeviceModeRecord {
  const ChildDeviceModeRecord({required this.childId, required this.deviceId});

  final String childId;
  final String deviceId;

  /// Child home route for this paired device.
  String get homeLocation => '/scr-chd-004?childId=$childId';
}

final class ChildDeviceMode {
  ChildDeviceMode._();

  static const kvNamespace = 'child_device_mode';
  static const _kChildId = 'child_id';
  static const _kDeviceId = 'device_id';

  static LocalPrefsMiscKvStore? _store() {
    if (FsSessionKernel.sqliteFallbackToMemory) return null;
    return LocalPrefsMiscKvStore(FsSessionKernel.db, namespace: kvNamespace);
  }

  /// Persists the pairing outcome. Rejects anything that is not a server UUID.
  static Future<bool> markPaired({
    required String childId,
    required String deviceId,
  }) async {
    if (!isFoundationGateUuid(childId) || !isFoundationGateUuid(deviceId)) {
      return false;
    }
    final store = _store();
    if (store == null) return false;
    await store.write(_kChildId, childId);
    await store.write(_kDeviceId, deviceId);
    return true;
  }

  static Future<void> clear() async {
    final store = _store();
    if (store == null) return;
    await store.write(_kChildId, '');
    await store.write(_kDeviceId, '');
  }

  /// Reads the local marker without consulting the native side.
  static Future<ChildDeviceModeRecord?> readLocal() async {
    final store = _store();
    if (store == null) return null;
    final childId = (await store.read(_kChildId))?.trim() ?? '';
    final deviceId = (await store.read(_kDeviceId))?.trim() ?? '';
    if (!isFoundationGateUuid(childId) || !isFoundationGateUuid(deviceId)) {
      return null;
    }
    return ChildDeviceModeRecord(childId: childId, deviceId: deviceId);
  }

  /// Cold-start resolution: the marker counts only if the native telemetry
  /// configuration (Keystore-backed credential) is still present.
  static Future<ChildDeviceModeRecord?> resolveForBoot({
    Future<NativeTelemetryStatus> Function()? nativeStatus,
  }) async {
    final record = await readLocal();
    if (record == null) return null;
    final status = await (nativeStatus ?? NativeChildTelemetryBridge.status)();
    if (!status.configured) {
      await clear();
      return null;
    }
    return record;
  }
}
