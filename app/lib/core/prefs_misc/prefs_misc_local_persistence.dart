import 'package:family_os/core/fs_foundation/fs_session_kernel.dart';
import 'package:family_os/core/fs_foundation/local_database.dart';
import 'package:family_os/core/policy/anti_tamper_repository.dart';
import 'package:family_os/core/policy/desired_monitoring_prefs_repository.dart';
import 'package:family_os/core/policy/device_lock_service.dart';
import 'package:family_os/core/policy/notification_prefs_repository.dart';
import 'package:family_os/core/policy/privacy_collection_repository.dart';
import 'package:family_os/core/policy/web_unlock_service.dart' show AuditAppend;

/// Prefs-misc durable KV namespaces (DOM-PREFS-MISC · per-setting).
abstract final class PrefsMiscKvNamespaces {
  static const notification = 'prefs_notif';
  static const privacy = 'prefs_privacy';
  static const antiTamper = 'prefs_at';
  static const deviceLock = 'prefs_devicelock';
  static const monitoring = 'prefs_monitoring';
}

/// [FamilyLocalDatabase] `kv_store` adapter for Prefs-misc seams.
final class LocalPrefsMiscKvStore
    implements
        NotificationPrefsStore,
        PrivacyCollectionPrefsStore,
        AntiTamperPrefsStore,
        DeviceLockPrefsStore,
        DesiredMonitoringPrefsStore {
  LocalPrefsMiscKvStore(
    this._db, {
    required this.namespace,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final FamilyLocalDatabase _db;
  final String namespace;
  final DateTime Function() _clock;

  static const _table = 'kv_store';

  @override
  Future<String?> read(String key) async {
    final rows = await _db.query(
      _table,
      where: 'namespace = ? AND key = ?',
      whereArgs: [namespace, key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  @override
  Future<void> write(String key, String value) async {
    await _db.insert(_table, {
      'namespace': namespace,
      'key': key,
      'value': value,
      'updated_at': _clock().toUtc().millisecondsSinceEpoch,
    }, conflictAlgorithm: LocalConflictAlgorithm.replace);
  }
}

/// Composition helpers — Notification Prefs Local KV (DOM-PREFS-MISC-NOTIF).
abstract final class PrefsMiscLocalPersistence {
  PrefsMiscLocalPersistence._();

  static NotificationPrefsRepository notificationRepository(
    FamilyLocalDatabase db,
  ) {
    return PrefsNotificationPrefsRepository(
      LocalPrefsMiscKvStore(db, namespace: PrefsMiscKvNamespaces.notification),
    );
  }

  /// Opens session DB; refuses SQLite→Memory fallback.
  static Future<NotificationPrefsRepository>
  openNotificationRepository() async {
    await FsSessionKernel.ensureOpen();
    if (FsSessionKernel.sqliteFallbackToMemory) {
      throw StateError(
        'DOM-PREFS-MISC-NOTIF: Notification Prefs refuses SQLite→Memory '
        'fallback (not restart-safe)',
      );
    }
    return notificationRepository(FsSessionKernel.db);
  }

  static PrivacyCollectionRepository privacyRepository(
    FamilyLocalDatabase db, {
    AuditAppend? audit,
  }) {
    return PrefsPrivacyCollectionRepository(
      LocalPrefsMiscKvStore(db, namespace: PrefsMiscKvNamespaces.privacy),
      audit: audit ?? stage1PrivacyCollectionAudit,
    );
  }

  /// Opens privacy collection Prefs on Local KV; refuses Memory fallback.
  static Future<PrivacyCollectionRepository> openPrivacyRepository({
    AuditAppend? audit,
  }) async {
    await FsSessionKernel.ensureOpen();
    if (FsSessionKernel.sqliteFallbackToMemory) {
      throw StateError(
        'DOM-PREFS-MISC-PRIVACY: Privacy Prefs refuses SQLite→Memory '
        'fallback (not restart-safe)',
      );
    }
    return privacyRepository(FsSessionKernel.db, audit: audit);
  }

  static AntiTamperRepository antiTamperRepository(
    FamilyLocalDatabase db, {
    AuditAppend? audit,
  }) {
    return PrefsAntiTamperRepository(
      LocalPrefsMiscKvStore(db, namespace: PrefsMiscKvNamespaces.antiTamper),
      audit: audit ?? stage1AntiTamperAudit,
    );
  }

  /// Opens anti-tamper Prefs on Local KV; refuses Memory fallback.
  static Future<AntiTamperRepository> openAntiTamperRepository({
    AuditAppend? audit,
  }) async {
    await FsSessionKernel.ensureOpen();
    if (FsSessionKernel.sqliteFallbackToMemory) {
      throw StateError(
        'DOM-PREFS-MISC-AT: Anti-tamper Prefs refuses SQLite→Memory '
        'fallback (not restart-safe)',
      );
    }
    return antiTamperRepository(FsSessionKernel.db, audit: audit);
  }

  static DeviceLockService deviceLockService(
    FamilyLocalDatabase db, {
    AuditAppend? audit,
    DeviceLockNotifyBus? notifyBus,
  }) {
    return DeviceLockService(
      store: LocalPrefsMiscKvStore(
        db,
        namespace: PrefsMiscKvNamespaces.deviceLock,
      ),
      audit: audit ?? stage1DeviceLockAudit,
      notifyBus: notifyBus ?? stage1DeviceLockNotifyBus,
    );
  }

  /// Opens DeviceLock Prefs on Local KV; refuses Memory fallback.
  static Future<DeviceLockService> openDeviceLockService({
    AuditAppend? audit,
    DeviceLockNotifyBus? notifyBus,
  }) async {
    await FsSessionKernel.ensureOpen();
    if (FsSessionKernel.sqliteFallbackToMemory) {
      throw StateError(
        'DOM-PREFS-MISC-DEVICELOCK: DeviceLock Prefs refuses SQLite→Memory '
        'fallback (not restart-safe)',
      );
    }
    return deviceLockService(
      FsSessionKernel.db,
      audit: audit,
      notifyBus: notifyBus,
    );
  }

  static DesiredMonitoringPrefsRepository monitoringRepository(
    FamilyLocalDatabase db,
  ) {
    return PrefsDesiredMonitoringPrefsRepository(
      LocalPrefsMiscKvStore(db, namespace: PrefsMiscKvNamespaces.monitoring),
    );
  }

  /// Opens DesiredMonitoring Prefs on Local KV; refuses Memory fallback.
  static Future<DesiredMonitoringPrefsRepository>
  openMonitoringRepository() async {
    await FsSessionKernel.ensureOpen();
    if (FsSessionKernel.sqliteFallbackToMemory) {
      throw StateError(
        'DOM-PREFS-MISC-MONITORING: DesiredMonitoring Prefs refuses '
        'SQLite→Memory fallback (not restart-safe)',
      );
    }
    return monitoringRepository(FsSessionKernel.db);
  }
}
