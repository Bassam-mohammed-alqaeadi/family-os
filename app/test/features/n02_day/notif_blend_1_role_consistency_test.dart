import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/anti_tamper_alert_bus.dart';
import 'package:family_os/core/policy/anti_tamper_policy.dart';
import 'package:family_os/core/policy/notification_prefs.dart';
import 'package:family_os/core/policy/notification_prefs_repository.dart';
import 'package:family_os/core/policy/sos_alert_repository.dart';
import 'package:family_os/core/policy/time_request.dart';
import 'package:family_os/features/n02_day/alert_detail_mock.dart';
import 'package:family_os/features/n02_day/alert_detail_repository.dart';
import 'package:family_os/features/n02_day/alert_detail_screen.dart';
import 'package:family_os/features/n02_day/alerts_hub_local_projection.dart';
import 'package:family_os/features/n02_day/outer_circle_models.dart';
import 'package:family_os/features/n02_day/outer_circle_repository.dart';

/// SYS-SEC-NOTIF-BLEND-1 — role-consistent mailbox proof.
void main() {
  group('hub prefs by active guardian memberId', () {
    late InMemoryNotificationPrefsRepository prefs;
    late AntiTamperAlertBus bus;
    late List<TimeRequest> pendingTime;
    late OuterCircleSnapshot circleSeed;

    setUp(() {
      prefs = InMemoryNotificationPrefsRepository();
      bus = AntiTamperAlertBus();
      bus.simulateBypassAttempt(
        ChildId('demo-child'),
        const AntiTamperPolicy(bypassAlert: true),
      );
      pendingTime = [
        TimeRequest(
          id: 'tr-blend',
          childId: ChildId('demo-child'),
          requestedMinutes: 10,
          status: TimeRequestStatus.pending,
          createdAt: DateTime.utc(2026, 9, 27),
        ),
      ];
      circleSeed = OuterCircleSnapshot(
        pending: [
          OuterCircleMember(
            id: 'p-blend',
            kind: OuterCircleMemberKind.pendingFriend,
            nameKey: 'pendingFriend',
            metaKey: 'classmate',
            statusKey: 'pending',
          ),
        ],
      );
    });

    ProjectingAlertsHubRepository hub({required String prefsMemberId}) {
      return ProjectingAlertsHubRepository(
        sos: InMemorySosAlertRepository(),
        tamperBus: bus,
        notificationPrefs: prefs,
        prefsMemberId: prefsMemberId,
        listTimePending: () async => pendingTime,
        listAppPending: (_) async => const [],
        outerCircle: InMemoryOuterCircleRepository(seed: circleSeed),
      );
    }

    test('mother childRequestsEnabled=false hides child-request rows',
        () async {
      await prefs.save(
        const NotificationPrefs(
          memberId: 'father',
          childRequestsEnabled: true,
        ),
      );
      await prefs.save(
        const NotificationPrefs(
          memberId: 'mother',
          childRequestsEnabled: false,
        ),
      );

      final motherSnap = await hub(prefsMemberId: 'mother').load();
      expect(motherSnap.critical.any((a) => a.titleKey == 'tamper'), isTrue);
      expect(motherSnap.attention, isEmpty);
    });

    test('father unchanged when only mother muted child requests', () async {
      await prefs.save(
        const NotificationPrefs(
          memberId: 'father',
          childRequestsEnabled: true,
        ),
      );
      await prefs.save(
        const NotificationPrefs(
          memberId: 'mother',
          childRequestsEnabled: false,
        ),
      );

      final fatherSnap = await hub(prefsMemberId: 'father').load();
      expect(fatherSnap.critical.any((a) => a.titleKey == 'tamper'), isTrue);
      expect(fatherSnap.attention.any((a) => a.titleKey == 'time'), isTrue);
      expect(fatherSnap.attention.any((a) => a.titleKey == 'friend'), isTrue);
    });

    test('resolvePrefsMemberId overrides static prefsMemberId', () async {
      await prefs.save(
        const NotificationPrefs(
          memberId: 'mother',
          childRequestsEnabled: false,
        ),
      );

      final repo = ProjectingAlertsHubRepository(
        sos: InMemorySosAlertRepository(),
        tamperBus: bus,
        notificationPrefs: prefs,
        prefsMemberId: 'father',
        resolvePrefsMemberId: () => 'mother',
        listTimePending: () async => pendingTime,
        listAppPending: (_) async => const [],
        outerCircle: InMemoryOuterCircleRepository(seed: circleSeed),
      );

      final snap = await repo.load();
      expect(snap.attention, isEmpty);
      expect(snap.critical.any((a) => a.titleKey == 'tamper'), isTrue);
    });
  });

  group('FAT-020 block authority by MotherLevel', () {
    testWidgets('observer cannot block stranger', (tester) async {
      await tester.pumpWidget(
        _app(
          child: AlertDetailScreen(
            alertId: 'a_stranger',
            repository: InMemoryAlertDetailRepository(
              initial: AlertDetailMock.seeded,
            ),
            roleOverride: AppRole.mother,
            motherLevel: MotherLevel.observer,
            onSos: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(AlertDetailKeys.body), findsOneWidget);
      expect(find.byKey(AlertDetailKeys.primaryAction), findsNothing);
      expect(find.byKey(AlertDetailKeys.requestBlock), findsOneWidget);
    });

    testWidgets('father unchanged — still blocks stranger', (tester) async {
      await tester.pumpWidget(
        _app(
          child: AlertDetailScreen(
            alertId: 'a_stranger',
            repository: InMemoryAlertDetailRepository(
              initial: AlertDetailMock.seeded,
            ),
            roleOverride: AppRole.father,
            onSos: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(AlertDetailKeys.body), findsOneWidget);
      expect(find.byKey(AlertDetailKeys.primaryAction), findsOneWidget);
      expect(find.byKey(AlertDetailKeys.requestBlock), findsNothing);
    });
  });
}

Widget _app({required Widget child}) {
  return MaterialApp(
    theme: buildFamilyTheme(),
    locale: const Locale('ar'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}
