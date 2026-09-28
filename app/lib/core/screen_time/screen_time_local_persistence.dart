import 'package:family_os/core/fs_foundation/fs_session_kernel.dart';
import 'package:family_os/core/fs_foundation/local_database.dart';
import 'package:family_os/core/policy/app_access_rules_repository.dart';
import 'package:family_os/core/policy/schedule_window_repository.dart';
import 'package:family_os/core/policy/screen_time_policy_repository.dart';
import 'package:family_os/core/policy/time_request_repository.dart';

/// Screen Time durable KV namespaces (DOM-ST-01 · Option A).
///
/// Ownership: **Screen Time only**. Never write Modes `mode_*` or AC tables.
abstract final class ScreenTimeKvNamespaces {
  static const policy = 'st_policy';
  static const schedule = 'st_schedule';

  /// Holds Prefs keys `time_requests` and `time_grants` (same store shape).
  static const time = 'st_time';

  /// Per-app ST axes (limitMinutes / countable / unlimited) — APP-OD-12.
  /// Distinct from AC allow/block (`ac_document`).
  static const appAxes = 'st_app_axes';
}

/// [FamilyLocalDatabase] `kv_store` adapter for ST Prefs repository seams.
///
/// Preserves existing Prefs JSON string values. Requires an **open** database —
/// does not fall back to Memory Prefs (no second production authority).
final class LocalScreenTimeKvPrefsStore
    implements
        ScreenTimePolicyPrefsStore,
        SchedulePrefsStore,
        TimeRequestPrefsStore,
        AppAccessRulesPrefsStore {
  LocalScreenTimeKvPrefsStore(
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
    await _db.insert(
      _table,
      {
        'namespace': namespace,
        'key': key,
        'value': value,
        'updated_at': _clock().toUtc().millisecondsSinceEpoch,
      },
      conflictAlgorithm: LocalConflictAlgorithm.replace,
    );
  }
}

/// Composition helpers — caller supplies [FamilyLocalDatabase] (Rule 25).
///
/// Production policy bind (DOM-ST-02A) uses [openPolicyRepository] via
/// [FsSessionKernel] — not a new Stage1ScreenTimeRuntime singleton.
abstract final class ScreenTimeLocalPersistence {
  ScreenTimeLocalPersistence._();

  static ScreenTimePolicyRepository policyRepository(FamilyLocalDatabase db) {
    return PrefsScreenTimePolicyRepository(
      LocalScreenTimeKvPrefsStore(
        db,
        namespace: ScreenTimeKvNamespaces.policy,
      ),
    );
  }

  /// Opens the shared session DB then returns the durable policy repository.
  ///
  /// Throws if [FsSessionKernel.ensureOpen] fails, or if the session used
  /// Memory because SQLite open failed ([FsSessionKernel.sqliteFallbackToMemory])
  /// — process-memory is not restart-safe (DOM-ST-02A.1 honesty).
  ///
  /// Does **not** fall back to [MemoryScreenTimePolicyPrefsStore].
  static Future<ScreenTimePolicyRepository> openPolicyRepository() async {
    await FsSessionKernel.ensureOpen();
    if (FsSessionKernel.sqliteFallbackToMemory) {
      throw StateError(
        'DOM-ST-02A.1: Screen Time Policy refuses SQLite→Memory fallback '
        '(not restart-safe)',
      );
    }
    return policyRepository(FsSessionKernel.db);
  }

  static ScheduleWindowRepository scheduleRepository(FamilyLocalDatabase db) {
    return PrefsScheduleWindowRepository(
      LocalScreenTimeKvPrefsStore(
        db,
        namespace: ScreenTimeKvNamespaces.schedule,
      ),
    );
  }

  /// Opens the shared session DB then returns the durable schedule repository.
  ///
  /// Throws if [FsSessionKernel.ensureOpen] fails, or if the session used
  /// Memory because SQLite open failed ([FsSessionKernel.sqliteFallbackToMemory])
  /// — process-memory is not restart-safe (DOM-ST-02B honesty = 02A.1 rule).
  ///
  /// Does **not** fall back to [MemorySchedulePrefsStore].
  static Future<ScheduleWindowRepository> openScheduleRepository() async {
    await FsSessionKernel.ensureOpen();
    if (FsSessionKernel.sqliteFallbackToMemory) {
      throw StateError(
        'DOM-ST-02B: Screen Time ScheduleWindow refuses SQLite→Memory fallback '
        '(not restart-safe)',
      );
    }
    return scheduleRepository(FsSessionKernel.db);
  }

  static TimeRequestRepository timeRequestRepository(FamilyLocalDatabase db) {
    return PrefsTimeRequestRepository(
      LocalScreenTimeKvPrefsStore(db, namespace: ScreenTimeKvNamespaces.time),
    );
  }

  /// Opens the shared session DB then returns the durable TimeRequest repository.
  ///
  /// Throws if [FsSessionKernel.ensureOpen] fails, or if the session used
  /// Memory because SQLite open failed ([FsSessionKernel.sqliteFallbackToMemory])
  /// — process-memory is not restart-safe (DOM-ST-02C honesty = 02A.1 rule).
  ///
  /// Does **not** fall back to [MemoryTimeRequestPrefsStore].
  static Future<TimeRequestRepository> openTimeRequestRepository() async {
    await FsSessionKernel.ensureOpen();
    if (FsSessionKernel.sqliteFallbackToMemory) {
      throw StateError(
        'DOM-ST-02C: Screen Time TimeRequest refuses SQLite→Memory fallback '
        '(not restart-safe)',
      );
    }
    return timeRequestRepository(FsSessionKernel.db);
  }
}
