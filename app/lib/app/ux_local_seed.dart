import 'package:flutter/foundation.dart';

import 'package:family_os/core/app_control/app_control_runtime.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/policy/notification_prefs.dart';
import 'package:family_os/core/prefs_misc/prefs_misc_runtime.dart';
import 'package:family_os/core/screen_time/screen_time_runtime.dart';

/// Stage-1 UX local seed — fills **producers** the projecting hubs already read.
///
/// Idempotent. Safe in debug/profile; no-op in release.
/// Does **not** plant GPS / AI / FCM / billing as live (LDR seed contract).
///
/// Complements [applyAuditPopulation] (in-memory fixtures for unbound repos).
///
/// [isReleaseMode] exists only so a test can prove the release branch without building
/// a release binary (safety phase S1 guard: a release APK plants nothing). Production
/// callers pass nothing and get the compile-time [kReleaseMode].
Future<int> applyUxLocalSeed({bool? isReleaseMode}) async {
  if (isReleaseMode ?? kReleaseMode) return 0;
  var n = 0;
  n += await _seedPendingAppInstall();
  n += await _seedNotificationPrefsRows();
  n += await _ensureTimeRequestSeed();
  return n;
}

/// One pending install ticket so FAT-019 / day-board show an app-approval row.
Future<int> _seedPendingAppInstall() async {
  try {
    await Stage1AppControlRuntime.ensureOpen();
    final service = Stage1AppControlRuntime.service;
    final childId = ChildId('demo-child');
    final pending = await service.listPendingInstalls(childId);
    if (pending.isNotEmpty) return 0;
    await service.observeInstall(
      childId: childId,
      packageId: 'com.familyos.uxseed.game',
      label: 'لعبة تعليمية',
    );
    return 1;
  } catch (e, st) {
    debugPrint('UX-LOCAL-SEED app-install skipped: $e\n$st');
    return 0;
  }
}

/// Persist father + mother notification prefs so FAT-058 / hub filters have KV rows.
Future<int> _seedNotificationPrefsRows() async {
  try {
    await PrefsMiscRuntime.ensureOpen();
    final repo = PrefsMiscRuntime.notification;
    if (repo == null) return 0;
    var wrote = 0;
    for (final id in const ['father', 'mother']) {
      final existing = await repo.load(id);
      // Skip if user already customized quiet hours or digests.
      if (existing.quietHoursEnabled ||
          !existing.childRequestsEnabled ||
          !existing.summaryDigestEnabled) {
        continue;
      }
      await repo.save(NotificationPrefs.defaults(memberId: id));
      wrote++;
    }
    return wrote;
  } catch (e, st) {
    debugPrint('UX-LOCAL-SEED notif prefs skipped: $e\n$st');
    return 0;
  }
}

/// Re-arm the LDR time-request sample if Screen Time runtime is open.
Future<int> _ensureTimeRequestSeed() async {
  try {
    await ScreenTimeRuntime.tryBind();
    final service = ScreenTimeRuntime.timeRequest;
    if (service == null) return 0;
    await ScreenTimeRuntime.ensureRealLocalTimeRequestSeeded(service);
    return 1;
  } catch (e, st) {
    debugPrint('UX-LOCAL-SEED time-request skipped: $e\n$st');
    return 0;
  }
}

