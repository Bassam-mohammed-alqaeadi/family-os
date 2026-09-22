import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/app_error_state.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n02_day/alert_detail_mock.dart';
import 'package:family_os/features/n02_day/alert_detail_repository.dart';
import 'package:family_os/features/n02_day/alert_detail_screen.dart';

void main() {
  testWidgets('SCR-FAT-020 loads by alertId', (tester) async {
    await tester.pumpWidget(
      _app(
        child: AlertDetailScreen(
          alertId: 'a_battery',
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
    expect(find.byKey(AlertDetailKeys.title), findsOneWidget);
    expect(find.textContaining('ابن ٢'), findsWidgets);
    expect(find.byKey(AlertDetailKeys.primaryAction), findsOneWidget);
    expect(find.byKey(AlertDetailKeys.honestyBanner), findsOneWidget);
    expect(find.byKey(AlertDetailKeys.p4Banner), findsOneWidget);
  });

  testWidgets('SCR-FAT-020 loads by alertKind', (tester) async {
    await tester.pumpWidget(
      _app(
        child: AlertDetailScreen(
          alertKind: 'arrive',
          repository: InMemoryAlertDetailRepository(
            initial: AlertDetailMock.seeded,
          ),
          roleOverride: AppRole.mother,
          motherLevel: MotherLevel.partner,
          onSos: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(AlertDetailKeys.body), findsOneWidget);
    expect(find.byKey(AlertDetailKeys.primaryAction), findsOneWidget);
    expect(find.byKey(AlertDetailKeys.secondaryAction), findsOneWidget);
  });

  testWidgets('SCR-FAT-020 Rule 23 — no planted names in default empty',
      (tester) async {
    await tester.pumpWidget(
      _app(
        child: AlertDetailScreen(
          alertId: 'a_stranger',
          repository: InMemoryAlertDetailRepository(),
          roleOverride: AppRole.father,
          onSos: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(AlertDetailKeys.notFound), findsOneWidget);
    expect(find.textContaining('خالد'), findsNothing);
    expect(find.textContaining('نورة'), findsNothing);
    expect(find.textContaining('سعد'), findsNothing);
    expect(find.textContaining('عبدالله'), findsNothing);
  });

  testWidgets('SCR-FAT-020 Rule 23 — seeded uses generic labels only',
      (tester) async {
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
    expect(find.textContaining('خالد'), findsNothing);
    expect(find.textContaining('نورة'), findsNothing);
    expect(find.textContaining('سعد'), findsNothing);
    expect(find.textContaining('ابن ١'), findsWidgets);
  });

  testWidgets('SCR-FAT-020 child lean + SOS ungated (P-4)', (tester) async {
    var sos = false;
    await tester.pumpWidget(
      _app(
        child: AlertDetailScreen(
          alertId: 'a_stranger',
          repository: InMemoryAlertDetailRepository(
            initial: AlertDetailMock.seeded,
          ),
          roleOverride: AppRole.child,
          onSos: () => sos = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(AlertDetailKeys.childLean), findsOneWidget);
    expect(find.byKey(AlertDetailKeys.body), findsNothing);
    expect(find.byKey(AlertDetailKeys.sosCta), findsOneWidget);

    await tester.tap(find.byKey(AlertDetailKeys.sosCta));
    await tester.pumpAndSettle();
    expect(sos, isTrue);
  });

  testWidgets('SCR-FAT-020 empty when no id/kind', (tester) async {
    await tester.pumpWidget(
      _app(
        child: AlertDetailScreen(
          repository: InMemoryAlertDetailRepository(
            initial: AlertDetailMock.seeded,
          ),
          roleOverride: AppRole.father,
          onSos: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(AlertDetailKeys.empty), findsOneWidget);
    expect(find.byType(AppEmptyState), findsOneWidget);
    expect(find.byKey(AlertDetailKeys.body), findsNothing);
    expect(find.byKey(AlertDetailKeys.sosCta), findsOneWidget);
  });

  testWidgets('SCR-FAT-020 not-found by unknown id', (tester) async {
    await tester.pumpWidget(
      _app(
        child: AlertDetailScreen(
          alertId: 'missing_alert',
          repository: InMemoryAlertDetailRepository(
            initial: AlertDetailMock.seeded,
          ),
          roleOverride: AppRole.father,
          onSos: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(AlertDetailKeys.notFound), findsOneWidget);
    expect(find.byKey(AlertDetailKeys.body), findsNothing);
  });

  testWidgets('SCR-FAT-020 error → AppErrorState + retry', (tester) async {
    final repo = InMemoryAlertDetailRepository(
      initial: AlertDetailMock.seeded,
      failLoad: true,
    );
    await tester.pumpWidget(
      _app(
        child: AlertDetailScreen(
          alertId: 'a_battery',
          repository: repo,
          roleOverride: AppRole.father,
          onSos: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(AlertDetailKeys.error), findsOneWidget);
    expect(find.byType(AppErrorState), findsOneWidget);

    repo.failLoad = false;
    await tester.tap(find.byKey(const Key('app_error_retry')));
    await tester.pumpAndSettle();

    expect(find.byKey(AlertDetailKeys.body), findsOneWidget);
  });

  testWidgets('SCR-FAT-020 mother partner → request block (not rules)',
      (tester) async {
    await tester.pumpWidget(
      _app(
        child: AlertDetailScreen(
          alertId: 'a_stranger',
          repository: InMemoryAlertDetailRepository(
            initial: AlertDetailMock.seeded,
          ),
          roleOverride: AppRole.mother,
          motherLevel: MotherLevel.partner,
          onSos: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(AlertDetailKeys.requestBlock), findsOneWidget);
    expect(find.byKey(AlertDetailKeys.primaryAction), findsNothing);
  });

  testWidgets('SCR-FAT-020 mother full → block CTA', (tester) async {
    await tester.pumpWidget(
      _app(
        child: AlertDetailScreen(
          alertId: 'a_stranger',
          repository: InMemoryAlertDetailRepository(
            initial: AlertDetailMock.seeded,
          ),
          roleOverride: AppRole.mother,
          motherLevel: MotherLevel.full,
          onSos: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(AlertDetailKeys.primaryAction), findsOneWidget);
    expect(find.byKey(AlertDetailKeys.requestBlock), findsNothing);
  });

  testWidgets('SCR-FAT-020 kind actions: games → screen time + dismiss',
      (tester) async {
    String? screenTimeChild;
    await tester.pumpWidget(
      _app(
        child: AlertDetailScreen(
          alertId: 'a_games',
          repository: InMemoryAlertDetailRepository(
            initial: AlertDetailMock.seeded,
          ),
          roleOverride: AppRole.father,
          onSos: () {},
          onOpenScreenTime: (id) => screenTimeChild = id,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(AlertDetailKeys.secondaryAction));
    await tester.pumpAndSettle();
    expect(screenTimeChild, 'child_a');

    await tester.tap(find.byKey(AlertDetailKeys.primaryAction));
    await tester.pumpAndSettle();
    expect(find.byKey(AlertDetailKeys.primaryDone), findsOneWidget);
  });

  testWidgets('SCR-FAT-020 arrive → map with childId', (tester) async {
    String? mapChild;
    await tester.pumpWidget(
      _app(
        child: AlertDetailScreen(
          alertId: 'a_arrive',
          repository: InMemoryAlertDetailRepository(
            initial: AlertDetailMock.seeded,
          ),
          roleOverride: AppRole.father,
          onSos: () {},
          onOpenMap: (id) => mapChild = id,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(AlertDetailKeys.secondaryAction));
    await tester.pumpAndSettle();
    expect(mapChild, 'child_c');
  });

  test('SCR-FAT-020 stage1 repo defaults empty (Rule 23)', () async {
    final detail = await InMemoryAlertDetailRepository().load(
      alertId: 'a_stranger',
    );
    expect(detail, isNull);
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
