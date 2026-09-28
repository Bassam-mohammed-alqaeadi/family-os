import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/fs_foundation/fs_session_kernel.dart';
import 'package:family_os/core/policy/schedule_window_repository.dart';
import 'package:family_os/core/policy/screen_time_policy_repository.dart';
import 'package:family_os/core/policy/time_request_service.dart';
import 'package:family_os/features/n03_screen_time/child_time_request_repository.dart';

import 'screen_time_local_persistence.dart';
import 'stage1_time_request_runtime.dart';

/// Boot-once Screen Time Domain host (HOST-ROUTER-B).
///
/// Opens policy + schedule + TimeRequest Local KV once. Screens read from
/// here when injectable constructor params are null.
final class ScreenTimeRuntime {
  ScreenTimeRuntime._();

  static var _opened = false;
  static var _unavailable = false;

  static ScreenTimePolicyRepository? _policy;
  static ScheduleWindowRepository? _schedule;
  static TimeRequestService? _timeRequest;

  static bool get isOpen => _opened;
  static bool get unavailable => _unavailable;

  static ScreenTimePolicyRepository? get policy => _policy;
  static ScheduleWindowRepository? get schedule => _schedule;
  static TimeRequestService? get timeRequest => _timeRequest;

  /// Idempotent. Refuses SQLite→Memory — sets [unavailable].
  static Future<void> ensureOpen() async {
    if (_opened) return;
    await FsSessionKernel.ensureOpen();
    if (FsSessionKernel.sqliteFallbackToMemory) {
      _unavailable = true;
      _opened = true;
      return;
    }
    _policy = await ScreenTimeLocalPersistence.openPolicyRepository();
    _schedule = await ScreenTimeLocalPersistence.openScheduleRepository();
    _timeRequest = await Stage1TimeRequestRuntime.ensureOpen();
    // LDR-B4 — day board / alerts / CHD-020 must share Local KV authority.
    rebindStage1TimeRequestService(_timeRequest!);
    rebindStage1ChildTimeRequestRepository(
      ServiceChildTimeRequestRepository(
        service: _timeRequest!,
        repository: Stage1TimeRequestRuntime.repository,
      ),
    );
    await ensureRealLocalTimeRequestSeeded(_timeRequest!);
    _unavailable = false;
    _opened = true;
  }

  /// LDR-B4 — one pending time request when none exist (REAL_LOCAL).
  static Future<void> ensureRealLocalTimeRequestSeeded(
    TimeRequestService service,
  ) async {
    try {
      final pending = await service.listPending();
      if (pending.isNotEmpty) return;
      await service.createRequest(
        childId: ChildId('demo-child'),
        requestedMinutes: 15,
        childReason: 'real_local_seed',
      );
    } catch (_) {
      // Soft — duplicate pending / unavailable must not block boot.
    }
  }

  /// Soft bind from [main] — never throws.
  static Future<void> tryBind() async {
    try {
      await ensureOpen();
    } catch (e, st) {
      // ignore: avoid_print
      print('HOST-ROUTER-B ScreenTimeRuntime.tryBind soft-fail: $e\n$st');
      _unavailable = true;
      _opened = true;
    }
  }

  static void resetForTest() {
    _opened = false;
    _unavailable = false;
    _policy = null;
    _schedule = null;
    _timeRequest = null;
    Stage1TimeRequestRuntime.resetForTest();
  }
}
