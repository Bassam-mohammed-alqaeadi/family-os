import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/app_error_state.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n02_day/alerts_hub_mock.dart';
import 'package:family_os/features/n02_day/alerts_hub_repository.dart';
import 'package:family_os/features/n02_day/alerts_hub_screen.dart';

void main() {
  testWidgets('SCR-FAT-019 empty → AppEmptyState + SOS ungated',
      (tester) async {
    var sos = false;
    await tester.pumpWidget(
      _app(
        child: AlertsHubScreen(
          repository: InMemoryAlertsHubRepository(),
          roleOverride: AppRole.father,
          onSos: () => sos = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(AlertsHubKeys.empty), findsOneWidget);
    expect(find.byType(AppEmptyState), findsOneWidget);
    expect(find.byKey(AlertsHubKeys.body), findsNothing);
    expect(find.byKey(AlertsHubKeys.sosCta), findsOneWidget);

    await tester.tap(find.byKey(AlertsHubKeys.sosCta));
    await tester.pumpAndSettle();
    expect(sos, isTrue);
  });

  testWidgets('SCR-FAT-019 three tiers + counters + honesty', (tester) async {
    await tester.pumpWidget(
      _app(
        child: AlertsHubScreen(
          repository: InMemoryAlertsHubRepository(
            initial: AlertsHubMock.seeded,
          ),
          roleOverride: AppRole.father,
          onSos: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(AlertsHubKeys.body), findsOneWidget);
    expect(find.byKey(AlertsHubKeys.honestyBanner), findsOneWidget);
    expect(find.byKey(AlertsHubKeys.p4Banner), findsOneWidget);
    expect(find.byKey(AlertsHubKeys.sectionCritical), findsOneWidget);
    expect(find.byKey(AlertsHubKeys.sectionAttention), findsOneWidget);
    expect(find.byKey(AlertsHubKeys.sectionReassurance), findsOneWidget);
    expect(find.byKey(AlertsHubKeys.countCritical), findsOneWidget);
    expect(find.byKey(AlertsHubKeys.countAttention), findsOneWidget);
    expect(find.byKey(AlertsHubKeys.countReassurance), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('2'), findsNWidgets(2));
    expect(find.byKey(AlertsHubKeys.row('a_stranger')), findsOneWidget);
    expect(find.byKey(AlertsHubKeys.row('a_battery')), findsOneWidget);
    expect(find.byKey(AlertsHubKeys.row('a_arrive')), findsOneWidget);
    expect(find.byKey(AlertsHubKeys.row('a_tasks')), findsOneWidget);
  });

  testWidgets('SCR-FAT-019 row → alert detail with kind', (tester) async {
    HubAlert? opened;
    await tester.pumpWidget(
      _app(
        child: AlertsHubScreen(
          repository: InMemoryAlertsHubRepository(
            initial: AlertsHubMock.seeded,
          ),
          roleOverride: AppRole.father,
          onSos: () {},
          onOpenAlert: (a) => opened = a,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(AlertsHubKeys.row('a_battery')));
    await tester.tap(find.byKey(AlertsHubKeys.row('a_battery')));
    await tester.pumpAndSettle();

    expect(opened, isNotNull);
    expect(opened!.id, 'a_battery');
    expect(opened!.alertKind, 'battery');
    expect(opened!.target, HubAlertTarget.alertDetail);
  });

  testWidgets('SCR-FAT-019 row → time requests / app approval', (tester) async {
    var time = false;
    var app = false;
    await tester.pumpWidget(
      _app(
        child: AlertsHubScreen(
          repository: InMemoryAlertsHubRepository(
            initial: AlertsHubMock.seeded,
          ),
          roleOverride: AppRole.mother,
          onSos: () {},
          onOpenTimeRequests: () => time = true,
          onOpenAppApproval: () => app = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(AlertsHubKeys.row('a_extra')));
    await tester.pumpAndSettle();
    expect(time, isTrue);

    await tester.tap(find.byKey(AlertsHubKeys.row('a_app')));
    await tester.pumpAndSettle();
    expect(app, isTrue);
  });

  testWidgets('SCR-FAT-019 info row not tappable', (tester) async {
    HubAlert? opened;
    await tester.pumpWidget(
      _app(
        child: AlertsHubScreen(
          repository: InMemoryAlertsHubRepository(
            initial: AlertsHubMock.seeded,
          ),
          roleOverride: AppRole.father,
          onSos: () {},
          onOpenAlert: (a) => opened = a,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(AlertsHubKeys.row('a_tasks')));
    await tester.tap(find.byKey(AlertsHubKeys.row('a_tasks')));
    await tester.pumpAndSettle();
    expect(opened, isNull);
  });

  testWidgets('SCR-FAT-019 child lean', (tester) async {
    await tester.pumpWidget(
      _app(
        child: AlertsHubScreen(
          repository: InMemoryAlertsHubRepository(
            initial: AlertsHubMock.seeded,
          ),
          roleOverride: AppRole.child,
          onSos: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(AlertsHubKeys.childLean), findsOneWidget);
    expect(find.byKey(AlertsHubKeys.body), findsNothing);
    expect(find.byKey(AlertsHubKeys.sosCta), findsOneWidget);
  });

  testWidgets('SCR-FAT-019 error → AppErrorState + retry', (tester) async {
    final repo = InMemoryAlertsHubRepository(failLoad: true);
    await tester.pumpWidget(
      _app(
        child: AlertsHubScreen(
          repository: repo,
          roleOverride: AppRole.father,
          onSos: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(AlertsHubKeys.error), findsOneWidget);
    expect(find.byType(AppErrorState), findsOneWidget);

    repo.failLoad = false;
    repo.seed(AlertsHubMock.seeded);
    await tester.tap(find.byKey(const Key('app_error_retry')));
    await tester.pumpAndSettle();

    expect(find.byKey(AlertsHubKeys.body), findsOneWidget);
  });

  test('SCR-FAT-019 stage1 repo defaults empty (Rule 23)', () async {
    final snap = await InMemoryAlertsHubRepository().load();
    expect(snap.isEmpty, isTrue);
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
