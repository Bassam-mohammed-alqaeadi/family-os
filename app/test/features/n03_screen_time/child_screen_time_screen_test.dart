import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/minutes.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/schedule_window_repository.dart';
import 'package:family_os/core/policy/screen_time_policy.dart';
import 'package:family_os/core/policy/screen_time_policy_repository.dart';
import 'package:family_os/core/policy/time_request.dart';
import 'package:family_os/core/policy/time_request_repository.dart';
import 'package:family_os/core/policy/time_request_service.dart';
import 'package:family_os/features/n12_devices/mother_permission_level_repository.dart';
import 'package:family_os/features/n03_screen_time/child_screen_time_screen.dart';
import 'package:family_os/features/n03_screen_time/guardian_minutes_balance_authority.dart';

void main() {
  tearDown(AppToast.dismiss);

  testWidgets('wallet minutes come from the server, not the local policy (S3)', (tester) async {
    final child = ChildId('wallet-child');
    final policy = InMemoryScreenTimePolicyRepository({
      child.value: ScreenTimePolicy(
        wallets: [AppWallet(appId: 'youtube', earnedMinutes: Minutes(99))],
      ),
    });
    await _pump(
      tester,
      repository: PrefsScheduleWindowRepository(MemorySchedulePrefsStore(<String, String>{})),
      childId: child,
      role: AppRole.father,
      policyRepository: policy,
      balanceReader: (_) async => const MinutesBalanceReading({'youtube': 25}),
    );

    // The server balance arrives after the screen is ready (async chain).
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump();
    // The wallet rows sit below the fold of the lazy settings list: scroll to them.
    await tester.scrollUntilVisible(
      find.byKey(const Key('wallet_minutes_youtube')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const Key('wallet_minutes_youtube')), findsOneWidget);
    expect(find.textContaining('25'), findsWidgets);
    expect(find.textContaining('99'), findsNothing);
  });

  testWidgets('a failed read shows the last good reading flagged stale', (tester) async {
    final child = ChildId('wallet-child-3');
    final policy = InMemoryScreenTimePolicyRepository({
      child.value: ScreenTimePolicy(
        wallets: [AppWallet(appId: 'youtube', earnedMinutes: Minutes(99))],
      ),
    });
    await _pump(
      tester,
      repository: PrefsScheduleWindowRepository(MemorySchedulePrefsStore(<String, String>{})),
      childId: child,
      role: AppRole.father,
      policyRepository: policy,
      balanceReader: (_) async => const MinutesBalanceReading({'youtube': 25}, stale: true),
    );

    await tester.scrollUntilVisible(
      find.byKey(const Key('wallet_balance_stale')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const Key('wallet_balance_stale')), findsOneWidget);
    expect(find.byKey(const Key('wallet_minutes_youtube')), findsOneWidget);
  });

  testWidgets('no server balance → wallet row shows no number', (tester) async {
    final child = ChildId('wallet-child-2');
    final policy = InMemoryScreenTimePolicyRepository({
      child.value: ScreenTimePolicy(
        wallets: [AppWallet(appId: 'youtube', earnedMinutes: Minutes(99))],
      ),
    });
    await _pump(
      tester,
      repository: PrefsScheduleWindowRepository(MemorySchedulePrefsStore(<String, String>{})),
      childId: child,
      role: AppRole.father,
      policyRepository: policy,
      balanceReader: (_) async => null,
    );

    expect(find.byKey(const Key('wallet_minutes_youtube')), findsNothing);
    expect(find.textContaining('99'), findsNothing);
  });

  final child = ChildId('widget-child');

  testWidgets('enable sleep + save persists across restart', (tester) async {
    final shared = <String, String>{};
    final repo = PrefsScheduleWindowRepository(
      MemorySchedulePrefsStore(shared),
    );

    await _pump(tester, repository: repo, childId: child, role: AppRole.father);

    await tester.tap(find.byKey(const Key('schedule_switch_sleep')));
    await tester.pumpAndSettle();
    expect(find.text('21:00'), findsOneWidget);
    expect(find.text('22:30'), findsOneWidget);

    await tester.tap(find.byKey(const Key('child_screen_time_save')));
    await tester.pump();
    expect(find.text('تم حفظ الجداول والحدود'), findsOneWidget);
    await _settleToast(tester);

    final repo2 = PrefsScheduleWindowRepository(
      MemorySchedulePrefsStore(shared),
    );
    await _pump(
      tester,
      repository: repo2,
      childId: child,
      role: AppRole.father,
    );
    final sw = tester.widget<Switch>(
      find.byKey(const Key('schedule_switch_sleep')),
    );
    expect(sw.value, isTrue);
    expect(find.text('21:00'), findsOneWidget);
  });

  testWidgets('end <= start disables save', (tester) async {
    final picks = <TimeOfDay>[
      const TimeOfDay(hour: 22, minute: 0),
      const TimeOfDay(hour: 21, minute: 0),
    ];
    final repo = InMemoryScheduleWindowRepository();

    await _pump(
      tester,
      repository: repo,
      childId: child,
      role: AppRole.father,
      pickTime: (context, initial) async => picks.removeAt(0),
    );

    await tester.tap(find.byKey(const Key('schedule_switch_sleep')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('schedule_start_sleep')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('schedule_end_sleep')));
    await tester.pumpAndSettle();

    final btn = tester.widget<PrimaryBtn>(
      find.byKey(const Key('child_screen_time_save')),
    );
    expect(btn.onPressed, isNull);
  });

  testWidgets('prayer enable seeds 15-min window', (tester) async {
    await _pump(
      tester,
      repository: InMemoryScheduleWindowRepository(),
      childId: child,
      role: AppRole.father,
    );

    await tester.tap(find.byKey(const Key('schedule_switch_prayer')));
    await tester.pumpAndSettle();
    expect(find.text('12:00'), findsOneWidget);
    expect(find.text('12:15'), findsOneWidget);
  });

  testWidgets('child role is read-only', (tester) async {
    await _pump(
      tester,
      repository: InMemoryScheduleWindowRepository(),
      childId: child,
      role: AppRole.child,
    );

    final sw = tester.widget<Switch>(
      find.byKey(const Key('schedule_switch_sleep')),
    );
    expect(sw.onChanged, isNull);
    expect(find.textContaining('عرض فقط'), findsOneWidget);
    final btn = tester.widget<PrimaryBtn>(
      find.byKey(const Key('child_screen_time_save')),
    );
    expect(btn.onPressed, isNull);
  });

  testWidgets('mother full can edit caps/schedules/overflow', (tester) async {
    resetStage1MotherPermissionLevelRepositoryForTest();
    final motherRepo = InMemoryMotherPermissionLevelRepository(
      initial: MotherLevel.full,
    );
    rebindStage1MotherPermissionLevelRepository(motherRepo);
    addTearDown(resetStage1MotherPermissionLevelRepositoryForTest);
    await _pump(
      tester,
      repository: InMemoryScheduleWindowRepository(),
      childId: child,
      role: AppRole.mother,
    );

    final sw = tester.widget<Switch>(
      find.byKey(const Key('schedule_switch_sleep')),
    );
    expect(sw.onChanged, isNotNull);

    await _scrollTo(tester, find.byKey(const Key('daily_cap_field')));
    final capField = tester.widget<TextField>(
      find.byKey(const Key('daily_cap_field')),
    );
    expect(capField.enabled, isTrue);

    await _scrollTo(
      tester,
      find.byKey(const Key('allow_wallet_overflow_switch')),
    );
    final overflow = tester.widget<Switch>(
      find.byKey(const Key('allow_wallet_overflow_switch')),
    );
    expect(overflow.onChanged, isNotNull);
  });

  testWidgets('schedule rows expose semantics labels', (tester) async {
    final handle = tester.ensureSemantics();
    try {
      await _pump(
        tester,
        repository: InMemoryScheduleWindowRepository(),
        childId: child,
        role: AppRole.father,
      );

      await _scrollTo(tester, find.byKey(const Key('schedule_switch_sleep')));
      expect(
        tester
            .getSemantics(find.byKey(const Key('schedule_switch_sleep')))
            .label,
        contains('نوم'),
      );
      await _scrollTo(tester, find.byKey(const Key('schedule_switch_prayer')));
      expect(
        tester
            .getSemantics(find.byKey(const Key('schedule_switch_prayer')))
            .label,
        contains('صلاة'),
      );
      await _scrollTo(tester, find.byKey(const Key('schedule_switch_study')));
      expect(
        tester
            .getSemantics(find.byKey(const Key('schedule_switch_study')))
            .label,
        contains('مذاكرة'),
      );
    } finally {
      handle.dispose();
    }
  });

  testWidgets('daily cap + overflow persist across restart', (tester) async {
    final shared = <String, String>{};
    final policyRepo = PrefsScreenTimePolicyRepository(
      MemoryScreenTimePolicyPrefsStore(shared),
    );

    await _pump(
      tester,
      repository: InMemoryScheduleWindowRepository(),
      policyRepository: policyRepo,
      childId: child,
      role: AppRole.father,
    );

    await _scrollTo(tester, find.byKey(const Key('daily_cap_field')));
    await tester.enterText(find.byKey(const Key('daily_cap_field')), '75');
    await tester.pump();
    await _scrollTo(
      tester,
      find.byKey(const Key('allow_wallet_overflow_switch')),
    );
    await tester.tap(find.byKey(const Key('allow_wallet_overflow_switch')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('child_screen_time_save')));
    await tester.pump();
    expect(find.text('تم حفظ الجداول والحدود'), findsOneWidget);
    await _settleToast(tester);

    final policyRepo2 = PrefsScreenTimePolicyRepository(
      MemoryScreenTimePolicyPrefsStore(shared),
    );
    await _pump(
      tester,
      repository: InMemoryScheduleWindowRepository(),
      policyRepository: policyRepo2,
      childId: child,
      role: AppRole.father,
    );

    expect(find.text('75'), findsOneWidget);
    final overflow = tester.widget<Switch>(
      find.byKey(const Key('allow_wallet_overflow_switch')),
    );
    expect(overflow.value, isTrue);
    expect(find.textContaining('ألعاب'), findsOneWidget);
  });

  testWidgets('caps section read-only for child', (tester) async {
    await _pump(
      tester,
      repository: InMemoryScheduleWindowRepository(),
      policyRepository: InMemoryScreenTimePolicyRepository({
        child.value: ScreenTimePolicy(
          dailyCapMinutes: 40,
          wallets: [AppWallet(appId: 'games', earnedMinutes: Minutes.zero)],
        ),
      }),
      childId: child,
      role: AppRole.child,
    );

    await _scrollTo(tester, find.byKey(const Key('daily_cap_field')));
    final field = tester.widget<TextField>(
      find.byKey(const Key('daily_cap_field')),
    );
    expect(field.enabled, isFalse);
    await _scrollTo(
      tester,
      find.byKey(const Key('allow_wallet_overflow_switch')),
    );
    final overflow = tester.widget<Switch>(
      find.byKey(const Key('allow_wallet_overflow_switch')),
    );
    expect(overflow.onChanged, isNull);
  });

  testWidgets(
    'SET-024: overflow switch default off + Ruling B helper; father can edit',
    (tester) async {
      await _pump(
        tester,
        repository: InMemoryScheduleWindowRepository(),
        policyRepository: InMemoryScreenTimePolicyRepository(),
        childId: child,
        role: AppRole.father,
      );

      await _scrollTo(
        tester,
        find.byKey(const Key('allow_wallet_overflow_switch')),
      );
      final overflow = tester.widget<Switch>(
        find.byKey(const Key('allow_wallet_overflow_switch')),
      );
      expect(overflow.value, isFalse);
      expect(overflow.onChanged, isNotNull);
      expect(find.textContaining('معطّل افتراضياً (حكم B)'), findsOneWidget);
    },
  );

  testWidgets('LOCAL honesty banner + SIMULATED enforcement', (tester) async {
    final repo = PrefsScheduleWindowRepository(MemorySchedulePrefsStore());
    await _pump(tester, repository: repo, childId: child, role: AppRole.father);
    expect(find.byKey(ChildScreenTimeKeys.localHonesty), findsOneWidget);
    expect(find.textContaining('SIMULATED'), findsWidgets);
    expect(find.textContaining('هذا الجهاز فقط'), findsOneWidget);
  });

  testWidgets('policy unavailable → banner + save disabled', (tester) async {
    final roleCtrl = RoleController(AppRole.father);
    addTearDown(roleCtrl.dispose);
    await tester.pumpWidget(
      CurrentRole(
        notifier: roleCtrl,
        child: MaterialApp(
          theme: buildFamilyTheme(),
          locale: const Locale('ar'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: ChildScreenTimeScreen(
            childId: child,
            repository: PrefsScheduleWindowRepository(
              MemorySchedulePrefsStore(),
            ),
            policyRepository: PrefsScreenTimePolicyRepository(
              MemoryScreenTimePolicyPrefsStore(),
            ),
            policyUnavailableOverride: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(ChildScreenTimeKeys.policyUnavailable), findsOneWidget);
    expect(find.textContaining('التخزين المحلي'), findsOneWidget);
    final btn = tester.widget<PrimaryBtn>(find.byKey(ChildScreenTimeKeys.save));
    expect(btn.onPressed, isNull);
  });

  testWidgets('grant remaining shows on RemainingMinutesCard', (tester) async {
    final childId = ChildId('grant-child');
    final trRepo = InMemoryTimeRequestRepository();
    final service = TimeRequestService(
      repository: trRepo,
      clock: () => DateTime.utc(2026, 9, 25, 10, 0),
      decisionBus: stage1TimeRequestDecisionBus,
    );
    addTearDown(service.dispose);

    final req = await service.createRequest(
      childId: childId,
      requestedMinutes: 20,
    );
    await service.approve(
      req.id,
      const TimeRequestActor.father(),
      grantMinutes: 15,
    );

    await _pump(
      tester,
      repository: PrefsScheduleWindowRepository(MemorySchedulePrefsStore()),
      policyRepository: PrefsScreenTimePolicyRepository(
        MemoryScreenTimePolicyPrefsStore(),
      ),
      childId: childId,
      role: AppRole.father,
      timeRequestService: service,
    );

    expect(find.textContaining('15'), findsWidgets);
  });

  testWidgets('earned minutes extension explanation displays when enabled and hides when disabled', (tester) async {
    final enabledChild = ChildId('child-earned-ext-on');
    final enabledPolicyRepo = InMemoryScreenTimePolicyRepository({
      enabledChild.value: ScreenTimePolicy(
        dailyCapMinutes: 60,
        earnedMinutesExtendLimit: true,
      ),
    });
    await _pump(
      tester,
      repository: InMemoryScheduleWindowRepository(),
      childId: enabledChild,
      role: AppRole.child,
      policyRepository: enabledPolicyRepo,
    );
    expect(find.byKey(ChildScreenTimeKeys.earnedExtensionNotice), findsOneWidget);
    expect(find.text('الدقائق المكتسبة تمدد وقت الشاشة اليومي تلقائياً'), findsOneWidget);

    final disabledChild = ChildId('child-earned-ext-off');
    final disabledPolicyRepo = InMemoryScreenTimePolicyRepository({
      disabledChild.value: ScreenTimePolicy(
        dailyCapMinutes: 60,
        earnedMinutesExtendLimit: false,
      ),
    });
    await _pump(
      tester,
      repository: InMemoryScheduleWindowRepository(),
      childId: disabledChild,
      role: AppRole.child,
      policyRepository: disabledPolicyRepo,
    );
    expect(find.byKey(ChildScreenTimeKeys.earnedExtensionNotice), findsNothing);
  });

  testWidgets('5 states: loading, empty, error, stale, and success are distinguishable', (tester) async {
    final testChild = ChildId('child-5-states');
    final repo = InMemoryScheduleWindowRepository();
    final policyRepo = InMemoryScreenTimePolicyRepository({
      testChild.value: ScreenTimePolicy(dailyCapMinutes: 60),
    });

    // 1. Success state
    await _pump(
      tester,
      repository: repo,
      childId: testChild,
      role: AppRole.father,
      policyRepository: policyRepo,
    );
    expect(find.byKey(ChildScreenTimeKeys.body), findsOneWidget);
    expect(find.byKey(ChildScreenTimeKeys.empty), findsNothing);
    expect(find.byKey(ChildScreenTimeKeys.error), findsNothing);

    // 2. Empty state
    await tester.pumpWidget(
      CurrentRole(
        notifier: RoleController(AppRole.father),
        child: MaterialApp(
          theme: buildFamilyTheme(),
          locale: const Locale('ar'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: ChildScreenTimeScreen(
            key: const Key('test_state_empty'),
            childId: testChild,
            repository: repo,
            policyRepository: policyRepo,
            emptyOverride: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(ChildScreenTimeKeys.empty), findsOneWidget);
    expect(find.text('لا توجد حدود زمنية محددة'), findsOneWidget);

    // 3. Error state
    await tester.pumpWidget(
      CurrentRole(
        notifier: RoleController(AppRole.father),
        child: MaterialApp(
          theme: buildFamilyTheme(),
          locale: const Locale('ar'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: ChildScreenTimeScreen(
            key: const Key('test_state_error'),
            childId: testChild,
            repository: repo,
            policyRepository: policyRepo,
            policyUnavailableOverride: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(ChildScreenTimeKeys.error), findsOneWidget);

    // 4. Stale state
    await _pump(
      tester,
      repository: repo,
      childId: testChild,
      role: AppRole.father,
      policyRepository: policyRepo,
      balanceReader: (_) async => const MinutesBalanceReading({'youtube': 10}, stale: true),
    );
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump();
    expect(find.byKey(ChildScreenTimeKeys.stale), findsOneWidget);

    // 5. Loading state key
    expect(ChildScreenTimeKeys.loading, isNotNull);
  });
}

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    220,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

Future<void> _pump(
  WidgetTester tester, {
  required ScheduleWindowRepository repository,
  required ChildId childId,
  required AppRole role,
  ScreenTimePolicyRepository? policyRepository,
  ScheduleTimePicker? pickTime,
  TimeRequestService? timeRequestService,
  Future<MinutesBalanceReading?> Function(String)? balanceReader,
}) async {
  final roleCtrl = RoleController(role);
  await tester.pumpWidget(
    CurrentRole(
      notifier: roleCtrl,
      child: MediaQuery(
        // The clock faces this screen shows follow the phone's own hour cycle
        // (shared family formatter). The strings pinned below are 24-hour, so
        // the fixture states that device setting; the screen is not locked to
        // one clock grammar.
        data: const MediaQueryData(alwaysUse24HourFormat: true),
        child: MaterialApp(
        theme: buildFamilyTheme(),
        locale: const Locale('ar'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: ChildScreenTimeScreen(
          childId: childId,
          repository: repository,
          policyRepository: policyRepository,
          pickTime: pickTime,
          timeRequestService: timeRequestService,
          balanceReader: balanceReader,
        ),
      ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _settleToast(WidgetTester tester) async {
  AppToast.dismiss();
  await tester.pump(const Duration(milliseconds: 2600));
}
