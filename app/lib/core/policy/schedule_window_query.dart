import 'package:flutter/material.dart' show TimeOfDay;

import 'schedule_window.dart';
import 'schedule_window_repository.dart';
import 'smart_modes.dart';
import 'time_engine.dart';

/// Query helpers that bridge schedule windows → TimeEngine / SmartModes.
///
/// Stage-1: callers pass a [ScheduleSnapshot] loaded from
/// [ScheduleWindowRepository]. Live updates: [PolicySyncBus] (SET-003).
abstract final class ScheduleWindowQuery {
  /// Whether [now] falls in an enabled window of [kind].
  static bool isInScheduleWindow(
    ScheduleSnapshot snapshot,
    ScheduleKind kind,
    TimeOfDay now,
  ) =>
      snapshot.isActive(kind, now);

  /// Maps schedule kind → built-in mode when the window is active.
  static BuiltInModeId? activeBuiltInMode(
    ScheduleSnapshot snapshot,
    TimeOfDay now,
  ) {
    // Stricter / priority: sleep > prayer > study (calm beats focus).
    if (isInScheduleWindow(snapshot, ScheduleKind.sleep, now)) {
      return BuiltInModeId.sleep;
    }
    if (isInScheduleWindow(snapshot, ScheduleKind.prayer, now)) {
      // Prayer pause has no dedicated BuiltInModeId — treat as sleep calm.
      return BuiltInModeId.sleep;
    }
    if (isInScheduleWindow(snapshot, ScheduleKind.study, now)) {
      return BuiltInModeId.study;
    }
    return null;
  }

  /// Builds a [TimeContext] with [modeActive] from schedule windows.
  static TimeContext timeContextFromSchedules({
    required TimeContext base,
    required ScheduleSnapshot snapshot,
    required TimeOfDay now,
  }) {
    final mode = activeBuiltInMode(snapshot, now);
    if (mode == null) return base;
    return TimeContext(
      childId: base.childId,
      instantLock: base.instantLock,
      permanentlyBlocked: base.permanentlyBlocked,
      modeActive: true,
      appAllowedInMode: base.appAllowedInMode,
      hasModeException: base.hasModeException,
      dailyLimitExhausted: base.dailyLimitExhausted,
      earnedBalance: base.earnedBalance,
      dailyCapIncludesWallet: base.dailyCapIncludesWallet,
      allowWalletOverflow: base.allowWalletOverflow,
    );
  }
}
