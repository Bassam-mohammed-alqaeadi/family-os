import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/policy/notification_delivery.dart';
import 'package:family_os/core/policy/notification_prefs.dart';
import 'package:family_os/core/policy/notification_prefs_repository.dart';
import 'package:family_os/core/policy/notification_tier.dart';

void main() {
  group('NotificationDelivery SET-010', () {
    final quietOn = NotificationPrefs(
      memberId: 'father',
      quietHoursEnabled: true,
      quietStart: const TimeOfDay(hour: 22, minute: 0),
      quietEnd: const TimeOfDay(hour: 7, minute: 0),
    );

    test('critical always delivers inside quiet window', () {
      const now = TimeOfDay(hour: 23, minute: 30);
      expect(
        NotificationDelivery.shouldDeliver(
          NotificationTier.critical,
          quietOn,
          now,
        ),
        isTrue,
      );
    });

    test('nonCritical suppressed inside quiet window when enabled', () {
      const now = TimeOfDay(hour: 23, minute: 30);
      expect(
        NotificationDelivery.shouldDeliver(
          NotificationTier.nonCritical,
          quietOn,
          now,
        ),
        isFalse,
      );
    });

    test('nonCritical delivers outside quiet window', () {
      const now = TimeOfDay(hour: 12, minute: 0);
      expect(
        NotificationDelivery.shouldDeliver(
          NotificationTier.nonCritical,
          quietOn,
          now,
        ),
        isTrue,
      );
    });

    test('nonCritical delivers when quiet hours disabled', () {
      final off = quietOn.copyWith(quietHoursEnabled: false);
      const now = TimeOfDay(hour: 23, minute: 30);
      expect(
        NotificationDelivery.shouldDeliver(
          NotificationTier.nonCritical,
          off,
          now,
        ),
        isTrue,
      );
    });

    test('same-day quiet window suppresses nonCritical', () {
      final sameDay = NotificationPrefs(
        memberId: 'father',
        quietHoursEnabled: true,
        quietStart: const TimeOfDay(hour: 13, minute: 0),
        quietEnd: const TimeOfDay(hour: 15, minute: 0),
      );
      expect(
        NotificationDelivery.shouldDeliver(
          NotificationTier.nonCritical,
          sameDay,
          const TimeOfDay(hour: 14, minute: 0),
        ),
        isFalse,
      );
      expect(
        NotificationDelivery.shouldDeliver(
          NotificationTier.critical,
          sameDay,
          const TimeOfDay(hour: 14, minute: 0),
        ),
        isTrue,
      );
    });

    test('simulateSosAlert delivers to father and mother with quiet ON', () {
      final motherQuiet = NotificationPrefs(
        memberId: 'mother',
        quietHoursEnabled: true,
        quietStart: const TimeOfDay(hour: 22, minute: 0),
        quietEnd: const TimeOfDay(hour: 7, minute: 0),
      );
      final results = NotificationDelivery.simulateSosAlert(
        const ['father', 'mother'],
        prefsByMember: {
          'father': quietOn,
          'mother': motherQuiet,
        },
        now: const TimeOfDay(hour: 23, minute: 0),
      );

      expect(results, hasLength(2));
      expect(results.every((r) => r.tier == NotificationTier.critical), isTrue);
      expect(results.every((r) => r.delivered), isTrue);
      expect(
        results.map((r) => r.recipientId).toSet(),
        {'father', 'mother'},
      );
    });

    test('prefs filter excludes critical tier', () {
      expect(
        NotificationPrefs.filterableTiers().toList(),
        [NotificationTier.nonCritical],
      );
      expect(
        NotificationPrefs.quietHoursAppliesTo(NotificationTier.critical),
        isFalse,
      );
      expect(
        NotificationPrefs.quietHoursAppliesTo(NotificationTier.nonCritical),
        isTrue,
      );
    });
  });

  group('NotificationPrefs schema P-4', () {
    test('fromJson rejects sosMuted', () {
      expect(
        () => NotificationPrefs.fromJson({
          'memberId': 'father',
          'quietHoursEnabled': false,
          'sosMuted': true,
        }),
        throwsA(isA<ForbiddenSosMuteFieldException>()),
      );
    });

    test('fromJson rejects sos_enabled=false', () {
      expect(
        () => NotificationPrefs.fromJson({
          'memberId': 'father',
          'sos_enabled': false,
        }),
        throwsA(isA<ForbiddenSosMuteFieldException>()),
      );
    });

    test('toJson never includes SOS mute fields', () {
      final prefs = NotificationPrefs.defaults(memberId: 'father');
      final json = prefs.toJson();
      expect(json.containsKey('sosMuted'), isFalse);
      expect(json.containsKey('sos_enabled'), isFalse);
      expect(json.keys.where(kForbiddenSosMuteKeys.contains), isEmpty);
    });
  });

  group('NotificationPrefsRepository', () {
    test('Prefs round-trip quiet hours', () async {
      final store = MemoryNotificationPrefsStore();
      final repo = PrefsNotificationPrefsRepository(store);
      final saved = NotificationPrefs(
        memberId: 'father',
        quietHoursEnabled: true,
        quietStart: const TimeOfDay(hour: 22, minute: 0),
        quietEnd: const TimeOfDay(hour: 7, minute: 0),
      );
      await repo.save(saved);
      final loaded = await repo.load('father');
      expect(loaded, saved);
    });

    test('InMemory save/load', () async {
      final repo = InMemoryNotificationPrefsRepository();
      final prefs = NotificationPrefs(
        memberId: 'mother',
        quietHoursEnabled: true,
        quietStart: const TimeOfDay(hour: 21, minute: 0),
        quietEnd: const TimeOfDay(hour: 6, minute: 30),
      );
      await repo.save(prefs);
      expect(await repo.load('mother'), prefs);
      expect(
        await repo.load('unknown'),
        NotificationPrefs.defaults(memberId: 'unknown'),
      );
    });
  });

  group('SET-011 mother identity', () {
    test('independent quiet hours rows for two members', () async {
      final repo = InMemoryNotificationPrefsRepository();
      await repo.save(
        const NotificationPrefs(
          memberId: 'father',
          quietHoursEnabled: false,
        ),
      );
      await repo.save(
        const NotificationPrefs(
          memberId: 'mother',
          quietHoursEnabled: true,
          quietStart: TimeOfDay(hour: 22, minute: 0),
          quietEnd: TimeOfDay(hour: 7, minute: 0),
        ),
      );
      expect((await repo.load('father')).quietHoursEnabled, isFalse);
      expect((await repo.load('mother')).quietHoursEnabled, isTrue);
    });

    test('mother quiet toggle does not mutate father row', () async {
      final repo = InMemoryNotificationPrefsRepository();
      const father = NotificationPrefs(
        memberId: 'father',
        quietHoursEnabled: false,
        analysisNoticesEnabled: true,
      );
      await repo.save(father);
      await repo.save(
        const NotificationPrefs(
          memberId: 'mother',
          quietHoursEnabled: false,
        ),
      );
      await repo.save(
        const NotificationPrefs(
          memberId: 'mother',
          quietHoursEnabled: true,
          quietStart: TimeOfDay(hour: 22, minute: 0),
          quietEnd: TimeOfDay(hour: 7, minute: 0),
        ),
      );
      expect(await repo.load('father'), father);
    });

    test('setSosMuted rejected; sosReceiptAlwaysOn', () async {
      expect(NotificationPrefs.sosReceiptAlwaysOn, isTrue);
      final repo = InMemoryNotificationPrefsRepository();
      expect(
        () => repo.setSosMuted('mother', true),
        throwsA(isA<ForbiddenSosMuteFieldException>()),
      );
      expect(
        () => repo.setSosMuted('guardian', true),
        throwsA(isA<ForbiddenSosMuteFieldException>()),
      );
      expect(
        () => repo.setSosMuted('father', true),
        throwsA(isA<ForbiddenSosMuteFieldException>()),
      );
      final prefsRepo = PrefsNotificationPrefsRepository(
        MemoryNotificationPrefsStore(),
      );
      expect(
        () => prefsRepo.setSosMuted('father', false),
        throwsA(isA<ForbiddenSosMuteFieldException>()),
      );
    });

    test('analysisNotices default on and independent per member', () async {
      final mother = NotificationPrefs.defaults(memberId: 'mother');
      final father = NotificationPrefs.defaults(memberId: 'father');
      expect(mother.analysisNoticesEnabled, isTrue);
      expect(father.analysisNoticesEnabled, isTrue);

      final motherOff = mother.copyWith(analysisNoticesEnabled: false);
      expect(motherOff.analysisNoticesEnabled, isFalse);
      expect(father.analysisNoticesEnabled, isTrue);
    });

    test('simulateAnalysisNotify delivers when mother flag on', () {
      final mother = NotificationPrefs.defaults(memberId: 'mother');
      final result = NotificationDelivery.simulateAnalysisNotify(
        'mother',
        prefs: mother,
        now: const TimeOfDay(hour: 12, minute: 0),
      );
      expect(result.delivered, isTrue);
      expect(result.tier, NotificationTier.nonCritical);
      expect(result.recipientId, 'mother');
    });

    test('simulateAnalysisNotify suppressed when mother flag off', () {
      final mother = NotificationPrefs.defaults(memberId: 'mother')
          .copyWith(analysisNoticesEnabled: false);
      final result = NotificationDelivery.simulateAnalysisNotify(
        'mother',
        prefs: mother,
      );
      expect(result.delivered, isFalse);
    });

    test('fromJson round-trips analysisNoticesEnabled', () {
      final prefs = NotificationPrefs(
        memberId: 'mother',
        analysisNoticesEnabled: false,
      );
      final round = NotificationPrefs.fromJson(prefs.toJson());
      expect(round.analysisNoticesEnabled, isFalse);
      expect(round.toJson()['sosReceiptAlwaysOn'], isTrue);
    });
  });

  group('SET-021 no SOS mute mother/guardian', () {
    test('simulateSosAlert delivers to mother OBSERVER', () {
      final motherQuiet = NotificationPrefs(
        memberId: 'mother',
        quietHoursEnabled: true,
        quietStart: const TimeOfDay(hour: 22, minute: 0),
        quietEnd: const TimeOfDay(hour: 7, minute: 0),
      );
      final results = NotificationDelivery.simulateSosAlert(
        const ['mother'],
        prefsByMember: {'mother': motherQuiet},
        motherLevelByMember: const {'mother': MotherLevel.observer},
        now: const TimeOfDay(hour: 23, minute: 15),
      );

      expect(results, hasLength(1));
      expect(results.single.recipientId, 'mother');
      expect(results.single.tier, NotificationTier.critical);
      expect(results.single.delivered, isTrue);
      expect(
        NotificationDelivery.guardianReceivesSos(
          memberId: 'mother',
          motherLevel: MotherLevel.observer,
        ),
        isTrue,
      );
    });

    test('simulateSosAlert delivers to mother at every level', () {
      for (final level in MotherLevel.values) {
        final results = NotificationDelivery.simulateSosAlert(
          const ['mother'],
          motherLevelByMember: {'mother': level},
          now: const TimeOfDay(hour: 23, minute: 0),
        );
        expect(results.single.delivered, isTrue, reason: 'level=$level');
      }
    });

    test('guardian sosMuted=true write rejected', () async {
      final repo = InMemoryNotificationPrefsRepository();
      for (final id in NotificationPrefs.guardianMemberIds) {
        expect(
          () => repo.setSosMuted(id, true),
          throwsA(isA<ForbiddenSosMuteFieldException>()),
          reason: id,
        );
      }
    });
  });
}
