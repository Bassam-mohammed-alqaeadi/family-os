import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/policy/schedule_window.dart';
import 'package:family_os/core/policy/schedule_window_query.dart';
import 'package:family_os/core/policy/schedule_window_repository.dart';
import 'package:family_os/core/policy/smart_modes.dart';
import 'package:family_os/core/policy/time_engine.dart';

void main() {
  final child = ChildId('c1');

  group('ScheduleWindow validation & defaults', () {
    test('end <= start is invalid when enabled', () {
      const w = ScheduleWindow(
        kind: ScheduleKind.sleep,
        enabled: true,
        start: TimeOfDay(hour: 22, minute: 0),
        end: TimeOfDay(hour: 21, minute: 0),
      );
      expect(w.isValid, isFalse);
    });

    test('prayer enable seeds 15-minute window', () {
      const unset = ScheduleWindow(kind: ScheduleKind.prayer, enabled: true);
      final seeded = ScheduleWindowDefaults.seedOnEnable(unset);
      expect(seeded.start, ScheduleWindowDefaults.prayerSeedStart);
      expect(
        ScheduleWindow.toMinutes(seeded.end)! -
            ScheduleWindow.toMinutes(seeded.start)!,
        ScheduleWindowDefaults.prayerDurationMinutes,
      );
    });
  });

  group('PrefsScheduleWindowRepository restart', () {
    test('enable sleep + times persists across new repo instance', () async {
      final shared = <String, String>{};
      final store = MemorySchedulePrefsStore(shared);
      final repo1 = PrefsScheduleWindowRepository(store);

      final sleep = const ScheduleWindow(
        kind: ScheduleKind.sleep,
        enabled: true,
        start: TimeOfDay(hour: 21, minute: 0),
        end: TimeOfDay(hour: 22, minute: 30),
      );
      await repo1.save(child, [
        sleep,
        const ScheduleWindow(kind: ScheduleKind.prayer, enabled: false),
        const ScheduleWindow(kind: ScheduleKind.study, enabled: false),
      ]);

      final repo2 = PrefsScheduleWindowRepository(
        MemorySchedulePrefsStore(shared),
      );
      final loaded = await repo2.get(child, ScheduleKind.sleep);
      expect(loaded, isNotNull);
      expect(loaded!.enabled, isTrue);
      expect(loaded.start, const TimeOfDay(hour: 21, minute: 0));
      expect(loaded.end, const TimeOfDay(hour: 22, minute: 30));
    });
  });

  group('ScheduleWindowQuery → TimeEngine', () {
    test('active sleep window sets modeActive for TimeEngine', () {
      final snapshot = ScheduleSnapshot(const [
        ScheduleWindow(
          kind: ScheduleKind.sleep,
          enabled: true,
          start: TimeOfDay(hour: 21, minute: 0),
          end: TimeOfDay(hour: 22, minute: 30),
        ),
      ]);
      const now = TimeOfDay(hour: 21, minute: 30);
      expect(
        ScheduleWindowQuery.isInScheduleWindow(
          snapshot,
          ScheduleKind.sleep,
          now,
        ),
        isTrue,
      );
      expect(
        ScheduleWindowQuery.activeBuiltInMode(snapshot, now),
        BuiltInModeId.sleep,
      );

      final ctx = ScheduleWindowQuery.timeContextFromSchedules(
        base: TimeContext(childId: child, appAllowedInMode: false),
        snapshot: snapshot,
        now: now,
      );
      expect(ctx.modeActive, isTrue);
      expect(TimeEngine.resolve(ctx), AppAccess.deniedMode);
    });
  });
}
