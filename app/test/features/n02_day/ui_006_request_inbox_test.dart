import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/time_request.dart';
import 'package:family_os/core/policy/time_request_repository.dart';
import 'package:family_os/core/policy/time_request_service.dart';
import 'package:family_os/features/n02_day/request_inbox_screen.dart';

void main() {
  final child = ChildId('ui006-child');

  TimeRequestService buildService({
    List<TimeRequest>? seed,
    int ceiling = kDefaultMotherGrantCeilingMinutes,
    bool offline = false,
    TimeRequestDecisionBus? bus,
  }) {
    return TimeRequestService(
      repository: InMemoryTimeRequestRepository(seed),
      decisionBus: bus ?? TimeRequestDecisionBus(),
      activeCeilingMinutes: ceiling,
      offline: offline,
    );
  }

  Widget wrap(
    Widget child, {
    Locale locale = const Locale('ar'),
  }) {
    return MaterialApp(
      theme: buildFamilyTheme(),
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: child,
    );
  }

  testWidgets('UI-006 AC1: empty inbox uses SHR-006 AppEmptyState', (
    tester,
  ) async {
    final service = buildService();
    addTearDown(service.dispose);

    await tester.pumpWidget(
      wrap(RequestInboxScreen(service: service)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(RequestInboxKeys.emptyState), findsOneWidget);
    expect(find.byType(AppEmptyState), findsOneWidget);
    expect(find.text('لا يوجد شيء هنا بعد'), findsOneWidget);
    expect(find.byKey(RequestInboxKeys.list), findsNothing);
  });

  testWidgets(
    'UI-006 AC2: mother cannot submit / select grant above ADR-039 ceiling',
    (tester) async {
      final pending = TimeRequest(
        id: 'tr-m1',
        childId: child,
        requestedMinutes: 60,
        childReason: 'واجب',
      );
      final service = buildService(seed: [pending], ceiling: 30);
      addTearDown(service.dispose);

      await tester.pumpWidget(
        wrap(
          RequestInboxScreen(
            service: service,
            role: AppRole.mother,
            motherLevel: MotherLevel.full,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(RequestInboxKeys.grantChip(15)), findsOneWidget);
      expect(find.byKey(RequestInboxKeys.grantChip(30)), findsOneWidget);
      expect(find.byKey(RequestInboxKeys.grantChip(45)), findsNothing);
      expect(find.byKey(RequestInboxKeys.grantChip(60)), findsNothing);

      // Service hard-deny if mother somehow tries over-ceiling.
      await expectLater(
        service.approve(
          'tr-m1',
          const TimeRequestActor.mother(MotherLevel.partner),
          grantMinutes: 45,
        ),
        throwsA(isA<TimeRequestNotAllowedException>()),
      );

      await tester.tap(find.byKey(RequestInboxKeys.grantChip(30)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(RequestInboxKeys.approve('tr-m1')));
      await tester.pumpAndSettle();

      final decided = await service.getById('tr-m1');
      expect(decided?.status, TimeRequestStatus.approved);
      expect(decided?.grantedMinutes, 30);
      expect(decided!.grantedMinutes! <= 30, isTrue);
    },
  );

  testWidgets('observer is blocked from request decisions', (tester) async {
    final pending = TimeRequest(
      id: 'tr-ob1',
      childId: child,
      requestedMinutes: 15,
    );
    final service = buildService(seed: [pending], ceiling: 30);
    addTearDown(service.dispose);

    await tester.pumpWidget(
      wrap(
        RequestInboxScreen(
          service: service,
          role: AppRole.mother,
          motherLevel: MotherLevel.observer,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(RequestInboxKeys.observerHint), findsOneWidget);
    expect(find.byKey(RequestInboxKeys.approve('tr-ob1')), findsNothing);
  });

  testWidgets(
    'UI-006 AC3: child sees reject reason via decision seam',
    (tester) async {
      final bus = TimeRequestDecisionBus();
      final pending = TimeRequest(
        id: 'tr-r1',
        childId: child,
        requestedMinutes: 15,
      );
      final service = buildService(seed: [pending], bus: bus);
      addTearDown(service.dispose);

      await tester.pumpWidget(
        wrap(
          Column(
            children: [
              Expanded(
                child: RequestInboxScreen(
                  service: service,
                  role: AppRole.father,
                ),
              ),
              ChildTimeDecisionSeam(
                decisionBus: bus,
                childId: child.value,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      const reason = 'أنهِ واجبك أولًا';
      await tester.enterText(
        find.byKey(RequestInboxKeys.rejectReason('tr-r1')),
        reason,
      );
      await tester.tap(find.byKey(RequestInboxKeys.reject('tr-r1')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('child_time_decision_rejected')), findsOneWidget);
      expect(find.textContaining(reason), findsOneWidget);

      final stored = await service.getById('tr-r1');
      expect(stored?.status, TimeRequestStatus.rejected);
      expect(stored?.decisionReason, reason);
      expect(bus.lastDecision?.decisionReason, reason);
    },
  );

  testWidgets('UI-006 father may grant over-ceiling options', (tester) async {
    final pending = TimeRequest(
      id: 'tr-f1',
      childId: child,
      requestedMinutes: 60,
    );
    final service = buildService(seed: [pending], ceiling: 30);
    addTearDown(service.dispose);

    await tester.pumpWidget(
      wrap(
        RequestInboxScreen(
          service: service,
          role: AppRole.father,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(RequestInboxKeys.grantChip(60)), findsOneWidget);
    await tester.tap(find.byKey(RequestInboxKeys.grantChip(60)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(RequestInboxKeys.approve('tr-f1')));
    await tester.pumpAndSettle();

    final decided = await service.getById('tr-f1');
    expect(decided?.grantedMinutes, 60);
  });

  testWidgets('UI-006 offline queues decisions until flush', (tester) async {
    final pending = TimeRequest(
      id: 'tr-off',
      childId: child,
      requestedMinutes: 15,
    );
    final service = buildService(seed: [pending], offline: true);
    addTearDown(service.dispose);

    await tester.pumpWidget(
      wrap(RequestInboxScreen(service: service, role: AppRole.father)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(RequestInboxKeys.offlineBanner), findsOneWidget);

    await tester.enterText(
      find.byKey(RequestInboxKeys.rejectReason('tr-off')),
      'لاحقًا',
    );
    await tester.tap(find.byKey(RequestInboxKeys.reject('tr-off')));
    await tester.pumpAndSettle();

    expect(service.pendingOfflineDecisions, hasLength(1));
    expect((await service.getById('tr-off'))?.status, TimeRequestStatus.pending);

    service.offline = false;
    await service.flushOfflineQueue();
    expect((await service.getById('tr-off'))?.status, TimeRequestStatus.rejected);
    expect((await service.getById('tr-off'))?.decisionReason, 'لاحقًا');
  });

  testWidgets('UI-006 router: /scr-fat-033 hosts RequestInboxScreen', (
    tester,
  ) async {
    final service = buildService();
    addTearDown(service.dispose);

    final router = GoRouter(
      initialLocation: '/scr-fat-033',
      routes: [
        GoRoute(
          path: '/scr-fat-033',
          name: 'SCR-FAT-033',
          builder: (context, state) => RequestInboxScreen(service: service),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
        theme: buildFamilyTheme(),
        locale: const Locale('ar'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(RequestInboxScreen), findsOneWidget);
    expect(find.byKey(RequestInboxKeys.emptyState), findsOneWidget);
  });
}
