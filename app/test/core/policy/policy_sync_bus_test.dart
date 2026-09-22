import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/minutes.dart';
import 'package:family_os/core/policy/policy_sync_bus.dart';
import 'package:family_os/core/policy/schedule_window.dart';
import 'package:family_os/core/policy/screen_time_policy.dart';

void main() {
  late PolicySyncBus bus;
  late ChildId child;

  setUp(() {
    bus = PolicySyncBus();
    child = ChildId('sync-child');
  });

  tearDown(() {
    bus.dispose();
  });

  test('online publish delivers policy and updates remaining', () async {
    bus.hydrate(
      child,
      policy: ScreenTimePolicy(
        dailyCapMinutes: 120,
        usedMinutesToday: 30,
      ),
    );
    expect(bus.mirrorOf(child).remainingMinutes, 90);

    final events = <ChildPolicyMirror>[];
    final sub = bus.watch(child).listen(events.add);

    final status = bus.publish(
      PolicySyncEvent(
        childId: child,
        updatedAt: DateTime.utc(2026, 9, 20, 12),
        kind: PolicySyncKind.policy,
        policy: ScreenTimePolicy(
          dailyCapMinutes: 90,
          usedMinutesToday: 30,
        ),
      ),
    );

    expect(status, PolicySyncStatus.delivered);
    expect(bus.statusOf(child), PolicySyncStatus.delivered);
    await Future<void>.delayed(Duration.zero);
    expect(bus.mirrorOf(child).remainingMinutes, 60);
    expect(bus.mirrorOf(child).applyCount, 1);
    expect(
      events.where((e) => e.remainingMinutes == 60).isNotEmpty,
      isTrue,
    );
    await sub.cancel();
  });

  test('offline save stays queued; markOnline delivers', () async {
    bus.hydrate(
      child,
      policy: ScreenTimePolicy(
        dailyCapMinutes: 120,
        usedMinutesToday: 10,
      ),
    );
    bus.markChildOffline(child);

    final status = bus.publish(
      PolicySyncEvent(
        childId: child,
        updatedAt: DateTime.utc(2026, 9, 20, 13),
        kind: PolicySyncKind.policy,
        policy: ScreenTimePolicy(
          dailyCapMinutes: 90,
          usedMinutesToday: 10,
        ),
      ),
    );

    expect(status, PolicySyncStatus.offlineQueued);
    expect(bus.statusOf(child), PolicySyncStatus.offlineQueued);
    expect(bus.mirrorOf(child).remainingMinutes, 110); // old values
    expect(bus.mirrorOf(child).applyCount, 0);

    bus.markChildOnline(child);
    expect(bus.statusOf(child), PolicySyncStatus.delivered);
    expect(bus.mirrorOf(child).remainingMinutes, 80);
    expect(bus.mirrorOf(child).applyCount, 1);
  });

  test('idempotent re-delivery of same updatedAt does not bump applyCount', () {
    final stamp = DateTime.utc(2026, 9, 20, 14);
    final policy = ScreenTimePolicy(
      dailyCapMinutes: 100,
      usedMinutesToday: 40,
      wallets: [
        AppWallet(appId: 'games', earnedMinutes: Minutes(10)),
      ],
    );

    bus.publish(
      PolicySyncEvent(
        childId: child,
        updatedAt: stamp,
        kind: PolicySyncKind.policy,
        policy: policy,
      ),
    );
    expect(bus.mirrorOf(child).applyCount, 1);
    expect(bus.mirrorOf(child).remainingMinutes, 60);
    expect(
      bus.mirrorOf(child).policy.walletFor('games')!.earnedMinutes.inMinutes,
      10,
    );

    // Re-deliver same stamp — must not double-apply / mutate usage wallets.
    bus.publish(
      PolicySyncEvent(
        childId: child,
        updatedAt: stamp,
        kind: PolicySyncKind.policy,
        policy: policy.copyWith(
          usedMinutesToday: 99,
          wallets: [
            AppWallet(appId: 'games', earnedMinutes: Minutes(999)),
          ],
        ),
      ),
    );

    expect(bus.mirrorOf(child).applyCount, 1);
    expect(bus.mirrorOf(child).remainingMinutes, 60);
    expect(bus.mirrorOf(child).policy.usedMinutesToday, 40);
    expect(
      bus.mirrorOf(child).policy.walletFor('games')!.earnedMinutes.inMinutes,
      10,
    );
  });

  test('schedule sleep enable sets soft notice flag', () {
    bus.publish(
      PolicySyncEvent(
        childId: child,
        updatedAt: DateTime.utc(2026, 9, 20, 15),
        kind: PolicySyncKind.schedule,
        schedules: [
          ScheduleWindow(
            kind: ScheduleKind.sleep,
            enabled: true,
            start: const TimeOfDay(hour: 21, minute: 0),
            end: const TimeOfDay(hour: 22, minute: 30),
          ),
          ScheduleWindow(kind: ScheduleKind.prayer, enabled: false),
          ScheduleWindow(kind: ScheduleKind.study, enabled: false),
        ],
      ),
    );
    expect(bus.mirrorOf(child).sleepActiveNotice, isTrue);
    expect(bus.mirrorOf(child).applyCount, 1);
  });
}
