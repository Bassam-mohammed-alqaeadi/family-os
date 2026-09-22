import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/placeholder_screen.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n01_linking/onboarding_progress_flags.dart';
import 'package:family_os/features/n01_linking/onboarding_progress_repository.dart';
import 'package:family_os/features/n01_linking/setup_wizard_screen.dart';

void main() {
  testWidgets('renders progress + checklist; done row not navigable', (
    tester,
  ) async {
    var addChild = 0;
    await _pumpWizard(
      tester,
      onAddChild: () => addChild++,
      repository: InMemoryOnboardingProgressRepository(
        OnboardingProgressFlags.afterFamilyCreate(),
      ),
    );

    expect(find.text('إعداد عائلتك'), findsOneWidget);
    expect(find.text('٤ دقائق'), findsOneWidget);
    // Account-only flags → 25% cached suggestion progress.
    expect(find.text('25٪'), findsOneWidget);
    expect(find.text('من الإعداد المقترح'), findsOneWidget);
    expect(find.text('إنشاء الحساب والعائلة'), findsOneWidget);
    expect(find.text('تمّ'), findsOneWidget);
    expect(find.text('الأهم الآن'), findsOneWidget);

    // Done row has no onTap — tapping must not fire navigation seam.
    await tester.tap(find.byKey(const Key('setup_wizard_done_account')));
    await tester.pump();
    expect(addChild, 0);
  });

  testWidgets('add-child row → /scr-fat-003', (tester) async {
    final router = _router();
    addTearDown(router.dispose);
    await _pumpWizardRouter(tester, router);

    await tester.tap(find.byKey(const Key('setup_wizard_add_child')));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/scr-fat-003');
    expect(find.text('SCR-FAT-003'), findsWidgets);
  });

  testWidgets('invite mother → /scr-fat-008', (tester) async {
    final router = _router();
    addTearDown(router.dispose);
    await _pumpWizardRouter(tester, router);

    await tester.tap(find.byKey(const Key('setup_wizard_invite_mother')));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/scr-fat-008');
    expect(find.text('SCR-FAT-008'), findsWidgets);
  });

  testWidgets('SOS row → /scr-fat-028', (tester) async {
    final router = _router();
    addTearDown(router.dispose);
    await _pumpWizardRouter(tester, router);

    await tester.tap(find.byKey(const Key('setup_wizard_sos')));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/scr-fat-028');
    expect(find.text('SCR-FAT-028'), findsWidgets);
  });

  testWidgets('skip later → /scr-fat-010', (tester) async {
    final router = _router();
    addTearDown(router.dispose);
    await _pumpWizardRouter(tester, router);

    await tester.tap(find.byKey(const Key('setup_wizard_skip')));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/scr-fat-010');
    expect(find.text('SCR-FAT-010'), findsWidgets);
  });

  testWidgets('Rule 23 — no sample person names', (tester) async {
    await _pumpWizard(tester);
    expect(find.textContaining('خالد'), findsNothing);
    expect(find.textContaining('أحمد'), findsNothing);
    expect(find.textContaining('عبدالله'), findsNothing);
  });

  // —— UI-002 acceptance ——

  testWidgets(
    'AC1 — skip proceeds with zero optional rows done (no gate)',
    (tester) async {
      final flags = OnboardingProgressFlags.afterFamilyCreate();
      expect(flags.noOptionalRowsDone, isTrue);
      expect(flags.progressPercent, 25);

      var skipped = 0;
      await _pumpWizard(
        tester,
        onSkipLater: () => skipped++,
        repository: InMemoryOnboardingProgressRepository(flags),
      );

      final skipBtn = tester.widget<PrimaryBtn>(
        find.byKey(const Key('setup_wizard_skip')),
      );
      expect(skipBtn.onPressed, isNotNull);

      await tester.tap(find.byKey(const Key('setup_wizard_skip')));
      await tester.pump();
      expect(skipped, 1);
    },
  );

  testWidgets('AC2 — copy reads as suggestion (not must-complete)', (
    tester,
  ) async {
    await _pumpWizard(
      tester,
      repository: InMemoryOnboardingProgressRepository(
        OnboardingProgressFlags.afterFamilyCreate(),
      ),
    );

    expect(find.text('من الإعداد المقترح'), findsOneWidget);
    expect(find.text('مقترح · ~ دقيقتان'), findsOneWidget);
    expect(find.text('مقترح · دقيقة واحدة'), findsOneWidget);
    expect(find.textContaining('مقترح لتطمئن معك'), findsOneWidget);
    expect(find.textContaining('اختياري'), findsOneWidget);
    // Coercive completeness caption must be gone.
    expect(find.text('من الإعداد اكتمل'), findsNothing);
  });

  testWidgets(
    'AC3 — mother invite remains optional; skip without inviting',
    (tester) async {
      var inviteTaps = 0;
      var skipped = 0;
      final flags = const OnboardingProgressFlags(
        accountCreated: true,
        childLinked: false,
        motherInvited: false,
        sosConfigured: false,
      );

      await _pumpWizard(
        tester,
        onInviteMother: () => inviteTaps++,
        onSkipLater: () => skipped++,
        repository: InMemoryOnboardingProgressRepository(flags),
      );

      expect(find.textContaining('اختياري'), findsOneWidget);

      // Skip without ever opening invite.
      await tester.tap(find.byKey(const Key('setup_wizard_skip')));
      await tester.pump();
      expect(inviteTaps, 0);
      expect(skipped, 1);
      expect(flags.motherInvited, isFalse);
    },
  );

  testWidgets('offline cache — shows last saved progress percent', (
    tester,
  ) async {
    final store = MemoryOnboardingProgressStore();
    final prefs = PrefsOnboardingProgressRepository(store);
    await prefs.save(
      const OnboardingProgressFlags(
        accountCreated: true,
        childLinked: true,
        motherInvited: false,
        sosConfigured: false,
      ),
    );

    await _pumpWizard(
      tester,
      repository: PrefsOnboardingProgressRepository(store),
    );

    // 2/4 = 50% — cached from store (offline-safe seam).
    expect(find.text('50٪'), findsOneWidget);
  });

  testWidgets('empty optional flags still allow skip to board via router', (
    tester,
  ) async {
    final router = _router(
      repository: InMemoryOnboardingProgressRepository(
        OnboardingProgressFlags.empty(),
      ),
    );
    addTearDown(router.dispose);
    await _pumpWizardRouter(tester, router);

    expect(find.text('0٪'), findsOneWidget);

    await tester.tap(find.byKey(const Key('setup_wizard_skip')));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/scr-fat-010');
  });
}

GoRouter _router({OnboardingProgressRepository? repository}) {
  return GoRouter(
    initialLocation: '/scr-fat-002',
    routes: [
      GoRoute(
        path: '/scr-fat-002',
        builder: (context, state) => SetupWizardScreen(
          repository: repository ??
              InMemoryOnboardingProgressRepository(
                OnboardingProgressFlags.afterFamilyCreate(),
              ),
        ),
      ),
      GoRoute(
        path: '/scr-fat-003',
        builder: (context, state) => const PlaceholderScreen(
          screenId: 'SCR-FAT-003',
          title: 'إضافة ابن',
        ),
      ),
      GoRoute(
        path: '/scr-fat-008',
        builder: (context, state) => const PlaceholderScreen(
          screenId: 'SCR-FAT-008',
          title: 'دعوة الأم',
        ),
      ),
      GoRoute(
        path: '/scr-fat-010',
        builder: (context, state) => const PlaceholderScreen(
          screenId: 'SCR-FAT-010',
          title: 'لوحة اليوم',
        ),
      ),
      GoRoute(
        path: '/scr-fat-028',
        builder: (context, state) => const PlaceholderScreen(
          screenId: 'SCR-FAT-028',
          title: 'إعداد الطوارئ',
        ),
      ),
    ],
  );
}

Future<void> _pumpWizardRouter(WidgetTester tester, GoRouter router) async {
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
}

Future<void> _pumpWizard(
  WidgetTester tester, {
  VoidCallback? onAddChild,
  VoidCallback? onInviteMother,
  VoidCallback? onSkipLater,
  OnboardingProgressRepository? repository,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildFamilyTheme(),
      locale: const Locale('ar'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: SetupWizardScreen(
        onAddChild: onAddChild,
        onInviteMother: onInviteMother,
        onSkipLater: onSkipLater,
        repository: repository ??
            InMemoryOnboardingProgressRepository(
              OnboardingProgressFlags.afterFamilyCreate(),
            ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
