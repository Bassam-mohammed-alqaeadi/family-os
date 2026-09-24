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
import 'package:family_os/features/n12_devices/mother_permission_level_repository.dart';
import 'package:family_os/features/n03_screen_time/child_screen_time_screen.dart';

void main() {
  tearDown(AppToast.dismiss);

  final child = ChildId('widget-child');

  testWidgets('enable sleep + save persists across restart', (tester) async {
    final shared = <String, String>{};
    final repo = PrefsScheduleWindowRepository(MemorySchedulePrefsStore(shared));

    await _pump(
      tester,
      repository: repo,
      childId: child,
      role: AppRole.father,
    );

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
    stage1MotherPermissionLevelRepository.seed(level: MotherLevel.full);
    addTearDown(stage1MotherPermissionLevelRepository.resetForTests);
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
    final capField = tester.widget<TextField>(find.byKey(const Key('daily_cap_field')));
    expect(capField.enabled, isTrue);

    await _scrollTo(tester, find.byKey(const Key('allow_wallet_overflow_switch')));
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

      expect(
        tester
            .getSemantics(find.byKey(const Key('schedule_switch_sleep')))
            .label,
        contains('نوم'),
      );
      expect(
        tester
            .getSemantics(find.byKey(const Key('schedule_switch_prayer')))
            .label,
        contains('صلاة'),
      );
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
          wallets: [
            AppWallet(
              appId: 'games',
              earnedMinutes: Minutes.zero,
            ),
          ],
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
      expect(
        find.textContaining('معطّل افتراضياً (حكم B)'),
        findsOneWidget,
      );
    },
  );
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
}) async {
  final roleCtrl = RoleController(role);
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
          childId: childId,
          repository: repository,
          policyRepository: policyRepository,
          pickTime: pickTime,
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
