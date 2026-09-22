import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/sos_alert_repository.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/features/n10_emergency/sos_alert_screen.dart';

void main() {
  testWidgets('SCR-FAT-018 father sees active coral board + CTAs',
      (tester) async {
    final repo = InMemorySosAlertRepository(
      initialActive: InMemorySosAlertRepository.demoActive(),
    );

    await tester.pumpWidget(
      _app(
        child: SosAlertScreen(
          repository: repo,
          roleOverride: AppRole.father,
          autoCallDelay: const Duration(hours: 1),
          onCallNow: () {},
          onOpenLiveMap: (_) {},
          onResolved: () {},
          onEscalate: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(SosAlertKeys.body), findsOneWidget);
    expect(find.byKey(SosAlertKeys.sirenBanner), findsOneWidget);
    expect(find.byKey(SosAlertKeys.p4Banner), findsOneWidget);
    expect(find.byKey(SosAlertKeys.map), findsOneWidget);
    expect(find.byKey(SosAlertKeys.pin), findsOneWidget);
    expect(find.byKey(SosAlertKeys.metaCard), findsOneWidget);
    expect(find.byKey(SosAlertKeys.callNow), findsOneWidget);
    expect(find.byKey(SosAlertKeys.liveMap), findsOneWidget);
    expect(find.byKey(SosAlertKeys.resolve), findsOneWidget);
    expect(find.byKey(SosAlertKeys.escalate), findsOneWidget);
    expect(find.byKey(SosAlertKeys.recipients), findsOneWidget);
    expect(find.byKey(SosAlertKeys.autoCallNote), findsOneWidget);
    expect(find.textContaining('ابن ١ يطلب النجدة'), findsOneWidget);
  });

  testWidgets('SCR-FAT-018 mother observer can resolve (P-4 / SET-021)',
      (tester) async {
    final repo = InMemorySosAlertRepository(
      initialActive: InMemorySosAlertRepository.demoActive(),
    );
    var resolved = false;

    await tester.pumpWidget(
      _app(
        child: SosAlertScreen(
          repository: repo,
          roleOverride: AppRole.mother,
          motherLevel: MotherLevel.observer,
          autoCallDelay: const Duration(hours: 1),
          onResolved: () => resolved = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(SosAlertKeys.body), findsOneWidget);
    await _tapVisible(tester, SosAlertKeys.resolve);
    expect(resolved, isTrue);
    expect(repo.resolveCount, 1);
    expect(await repo.loadActive(), isNull);
  });

  testWidgets('SCR-FAT-018 mother full can escalate', (tester) async {
    final repo = InMemorySosAlertRepository(
      initialActive: InMemorySosAlertRepository.demoActive(),
    );
    var escalated = false;

    await tester.pumpWidget(
      _app(
        child: SosAlertScreen(
          repository: repo,
          roleOverride: AppRole.mother,
          motherLevel: MotherLevel.full,
          autoCallDelay: const Duration(hours: 1),
          onEscalate: () => escalated = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _tapVisible(tester, SosAlertKeys.escalate);
    expect(escalated, isTrue);
    expect(repo.escalateCount, 1);
  });

  testWidgets('SCR-FAT-018 auto-call fires after delay (S-SEC-028)',
      (tester) async {
    final repo = InMemorySosAlertRepository(
      initialActive: InMemorySosAlertRepository.demoActive(),
    );
    var calls = 0;

    await tester.pumpWidget(
      _app(
        child: SosAlertScreen(
          repository: repo,
          roleOverride: AppRole.father,
          autoCallDelay: const Duration(seconds: 5),
          onCallNow: () => calls++,
        ),
      ),
    );
    // First frames only — do not settle (would drain the auto-call timer).
    await tester.pump();
    await tester.pump();
    expect(calls, 0);
    expect(find.byKey(SosAlertKeys.autoCallNote), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    expect(calls, 1);
    expect(find.byKey(SosAlertKeys.autoCallNote), findsNothing);
  });

  testWidgets('SCR-FAT-018 empty when no active alert', (tester) async {
    final repo = InMemorySosAlertRepository();
    var setup = false;

    await tester.pumpWidget(
      _app(
        child: SosAlertScreen(
          repository: repo,
          roleOverride: AppRole.father,
          onOpenSetup: () => setup = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(SosAlertKeys.empty), findsOneWidget);
    expect(find.byKey(SosAlertKeys.body), findsNothing);
    await tester.tap(find.byKey(SosAlertKeys.setupCta));
    await tester.pumpAndSettle();
    expect(setup, isTrue);
  });

  testWidgets('SCR-FAT-018 child lean', (tester) async {
    await tester.pumpWidget(
      _app(
        child: SosAlertScreen(
          repository: InMemorySosAlertRepository(
            initialActive: InMemorySosAlertRepository.demoActive(),
          ),
          roleOverride: AppRole.child,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(SosAlertKeys.childLean), findsOneWidget);
    expect(find.byKey(SosAlertKeys.body), findsNothing);
  });

  testWidgets('SCR-FAT-018 call + live map seams', (tester) async {
    final repo = InMemorySosAlertRepository(
      initialActive: InMemorySosAlertRepository.demoActive(),
    );
    var called = false;
    String? mapChild;

    await tester.pumpWidget(
      _app(
        child: SosAlertScreen(
          repository: repo,
          roleOverride: AppRole.father,
          autoCallDelay: const Duration(hours: 1),
          onCallNow: () => called = true,
          onOpenLiveMap: (id) => mapChild = id,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _tapVisible(tester, SosAlertKeys.callNow);
    expect(called, isTrue);

    await _tapVisible(tester, SosAlertKeys.liveMap);
    expect(mapChild, 'child_a');
  });

  test('SCR-FAT-018 fireAndSeedSosAlert is entitlement-free + P-4', () async {
    final sos = MockSosFireService();
    final alerts = InMemorySosAlertRepository();
    final result = await fireAndSeedSosAlert(
      childId: 'child_a',
      sosFire: sos,
      alerts: alerts,
    );
    expect(result.fired, isTrue);
    expect(sos.fireCount, 1);
    expect(await alerts.loadActive(), isNotNull);
    // API shape: SosFireService.fire has no entitlement param (UI-007).
    expect(sos, isA<SosFireService>());
  });
}

Future<void> _tapVisible(WidgetTester tester, Key key) async {
  await tester.ensureVisible(find.byKey(key));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
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
