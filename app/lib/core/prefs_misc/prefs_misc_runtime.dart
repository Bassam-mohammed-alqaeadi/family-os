import 'package:family_os/core/fs_foundation/fs_session_kernel.dart';
import 'package:family_os/core/policy/anti_tamper_repository.dart';
import 'package:family_os/core/policy/desired_monitoring_prefs_repository.dart';
import 'package:family_os/core/policy/device_lock_service.dart';
import 'package:family_os/core/policy/notification_prefs_repository.dart';
import 'package:family_os/core/policy/privacy_collection_repository.dart';

import 'prefs_misc_local_persistence.dart';

/// Boot-once Prefs-misc Domain host (HOST-ROUTER-A).
///
/// Opens all five Local KV namespaces once after [FsSessionKernel.ensureOpen].
/// Screens read from here when injectable constructor params are null.
final class PrefsMiscRuntime {
  PrefsMiscRuntime._();

  static var _opened = false;
  static var _unavailable = false;

  static NotificationPrefsRepository? _notification;
  static PrivacyCollectionRepository? _privacy;
  static AntiTamperRepository? _antiTamper;
  static DeviceLockService? _deviceLock;
  static DesiredMonitoringPrefsRepository? _monitoring;

  static bool get isOpen => _opened;
  static bool get unavailable => _unavailable;

  static NotificationPrefsRepository? get notification => _notification;
  static PrivacyCollectionRepository? get privacy => _privacy;
  static AntiTamperRepository? get antiTamper => _antiTamper;
  static DeviceLockService? get deviceLock => _deviceLock;
  static DesiredMonitoringPrefsRepository? get monitoring => _monitoring;

  /// Idempotent. Refuses SQLite→Memory — sets [unavailable] instead of Memory.
  static Future<void> ensureOpen() async {
    if (_opened) return;
    await FsSessionKernel.ensureOpen();
    if (FsSessionKernel.sqliteFallbackToMemory) {
      _unavailable = true;
      _opened = true;
      return;
    }
    _notification =
        await PrefsMiscLocalPersistence.openNotificationRepository();
    _privacy = await PrefsMiscLocalPersistence.openPrivacyRepository();
    _antiTamper = await PrefsMiscLocalPersistence.openAntiTamperRepository();
    _deviceLock = await PrefsMiscLocalPersistence.openDeviceLockService();
    _monitoring = await PrefsMiscLocalPersistence.openMonitoringRepository();
    _unavailable = false;
    _opened = true;
  }

  /// Soft bind from [main] — never throws; marks unavailable on failure.
  static Future<void> tryBind() async {
    try {
      await ensureOpen();
    } catch (e, st) {
      // ignore: avoid_print
      print('HOST-ROUTER-A PrefsMiscRuntime.tryBind soft-fail: $e\n$st');
      _unavailable = true;
      _opened = true;
    }
  }

  static void resetForTest() {
    _opened = false;
    _unavailable = false;
    _notification = null;
    _privacy = null;
    _antiTamper = null;
    _deviceLock = null;
    _monitoring = null;
  }
}
