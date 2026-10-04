import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/policy/anti_tamper_alert_bus.dart';
import 'package:family_os/core/policy/anti_tamper_policy.dart';
import 'package:family_os/core/policy/notification_prefs.dart';
import 'package:family_os/core/policy/notification_prefs_repository.dart';
import 'package:family_os/core/policy/sos_alert_repository.dart';
import 'package:family_os/core/policy/time_request.dart';
import 'package:family_os/features/n02_day/alerts_hub_local_projection.dart';
import 'package:family_os/features/n02_day/alerts_hub_repository.dart';
import 'package:family_os/features/n02_day/outer_circle_models.dart';
import 'package:family_os/features/n02_day/outer_circle_repository.dart';

void main() {
  test('tamper + time-request + friend project into hub rows', () async {
    final bus = AntiTamperAlertBus();
    bus.simulateBypassAttempt(
      ChildId('demo-child'),
      const AntiTamperPolicy(bypassAlert: true),
    );
    final circle = InMemoryOuterCircleRepository(
      seed: OuterCircleSnapshot(
        pending: [
          OuterCircleMember(
            id: 'p1',
            kind: OuterCircleMemberKind.pendingFriend,
            nameKey: 'pendingFriend',
            metaKey: 'classmate',
            statusKey: 'pending',
          ),
        ],
      ),
    );
    final repo = ProjectingAlertsHubRepository(
      sos: InMemorySosAlertRepository(),
      tamperBus: bus,
      outerCircle: circle,
      listTimePending: () async => [
        TimeRequest(
          id: 'tr-hub',
          childId: ChildId('demo-child'),
          requestedMinutes: 10,
          status: TimeRequestStatus.pending,
          createdAt: DateTime.utc(2026, 9, 26),
        ),
      ],
      listAppPending: (_) async => const [],
    );

    final snap = await repo.load();
    expect(snap.critical.any((a) => a.titleKey == 'tamper'), isTrue);
    expect(snap.attention.any((a) => a.titleKey == 'time'), isTrue);
    expect(snap.attention.any((a) => a.titleKey == 'friend'), isTrue);
    expect(
      snap.attention.where((a) => a.titleKey == 'friend').single.target,
      HubAlertTarget.friendApproval,
    );
  });

  test('active SOS projects as critical row', () async {
    final repo = ProjectingAlertsHubRepository(
      sos: InMemorySosAlertRepository(
        initialActive: InMemorySosAlertRepository.demoActive(),
      ),
      tamperBus: AntiTamperAlertBus(),
      listTimePending: () async => const [],
      listAppPending: (_) async => const [],
      outerCircle: InMemoryOuterCircleRepository(),
    );
    final snap = await repo.load();
    expect(snap.critical.single.titleKey, 'sos');
    expect(snap.critical.single.alertKind, 'sos');
  });

  test('childRequestsEnabled=false hides time/app/friend rows', () async {
    final prefs = InMemoryNotificationPrefsRepository();
    await prefs.save(
      const NotificationPrefs(memberId: 'father', childRequestsEnabled: false),
    );
    final bus = AntiTamperAlertBus();
    bus.simulateBypassAttempt(
      ChildId('demo-child'),
      const AntiTamperPolicy(bypassAlert: true),
    );
    final repo = ProjectingAlertsHubRepository(
      sos: InMemorySosAlertRepository(),
      tamperBus: bus,
      notificationPrefs: prefs,
      listTimePending: () async => [
        TimeRequest(
          id: 'tr-hub',
          childId: ChildId('demo-child'),
          requestedMinutes: 10,
          status: TimeRequestStatus.pending,
          createdAt: DateTime.utc(2026, 9, 26),
        ),
      ],
      listAppPending: (_) async => const [],
      outerCircle: InMemoryOuterCircleRepository(
        seed: OuterCircleSnapshot(
          pending: [
            OuterCircleMember(
              id: 'p1',
              kind: OuterCircleMemberKind.pendingFriend,
              nameKey: 'pendingFriend',
              metaKey: 'classmate',
              statusKey: 'pending',
            ),
          ],
        ),
      ),
    );
    final snap = await repo.load();
    expect(snap.critical.any((a) => a.titleKey == 'tamper'), isTrue);
    expect(snap.attention, isEmpty);
  });

  test('mother prefsMemberId hides child requests for mother only', () async {
    final prefs = InMemoryNotificationPrefsRepository();
    await prefs.save(
      const NotificationPrefs(memberId: 'father', childRequestsEnabled: true),
    );
    await prefs.save(
      const NotificationPrefs(memberId: 'mother', childRequestsEnabled: false),
    );
    final repoMother = ProjectingAlertsHubRepository(
      sos: InMemorySosAlertRepository(),
      tamperBus: AntiTamperAlertBus(),
      notificationPrefs: prefs,
      prefsMemberId: 'mother',
      listTimePending: () async => [
        TimeRequest(
          id: 'tr-m',
          childId: ChildId('demo-child'),
          requestedMinutes: 5,
          status: TimeRequestStatus.pending,
          createdAt: DateTime.utc(2026, 9, 26),
        ),
      ],
      listAppPending: (_) async => const [],
      outerCircle: InMemoryOuterCircleRepository(),
    );
    final repoFather = ProjectingAlertsHubRepository(
      sos: InMemorySosAlertRepository(),
      tamperBus: AntiTamperAlertBus(),
      notificationPrefs: prefs,
      prefsMemberId: 'father',
      listTimePending: () async => [
        TimeRequest(
          id: 'tr-f',
          childId: ChildId('demo-child'),
          requestedMinutes: 5,
          status: TimeRequestStatus.pending,
          createdAt: DateTime.utc(2026, 9, 26),
        ),
      ],
      listAppPending: (_) async => const [],
      outerCircle: InMemoryOuterCircleRepository(),
    );
    expect((await repoMother.load()).attention, isEmpty);
    expect((await repoFather.load()).attention, isNotEmpty);
  });
}
