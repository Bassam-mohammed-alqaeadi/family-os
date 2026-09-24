import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/policy_sync_bus.dart';
import 'package:family_os/core/policy/schedule_window_repository.dart';
import 'package:family_os/core/policy/screen_time_policy.dart';
import 'package:family_os/core/policy/screen_time_policy_repository.dart';
import 'package:family_os/features/n03_screen_time/child_screen_time_screen.dart';
import 'package:family_os/features/n03_screen_time/child_time_mirror_screen.dart';

void main() {
  tearDown(AppToast.dismiss);

  final child = ChildId('p12-child');

  testWidgets(
    'P12: parent −30 cap → child mirror updates same session (no child cold restart)',
    (tester) async {
      final bus = PolicySyncBus();
      addTearDown(bus.dispose);

      final initial = ScreenTimePolicy(
        dailyCapMinutes: 120,
        usedMinutesToday: 20,
      );
      bus.hydrate(child, policy: initial);

      await tester.pumpWidget(
        _app(
          ChildScreenTimeMirror(
            childId: child,
            syncBus: bus,
            initialPolicy: initial,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('متبقي 100 دقيقة'), findsOneWidget);
      final mirrorState = tester.state(find.byType(ChildScreenTimeMirror));

      // Parent −30 cap emit (same isolate) — no child-only cold restart.
      bus.publish(
        PolicySyncEvent(
          childId: child,
          updatedAt: DateTime.utc(2026, 9, 20, 18),
          kind: PolicySyncKind.policy,
          policy: ScreenTimePolicy(
            dailyCapMinutes: 90,
            usedMinutesToday: 20,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('متبقي 70 دقيقة'), findsOneWidget);
      expect(
        identical(mirrorState, tester.state(find.byType(ChildScreenTimeMirror))),
        isTrue,
      );
    },
  );

  testWidgets(
    'offline: child keeps old values until markOnline delivers',
    (tester) async {
      final bus = PolicySyncBus();
      addTearDown(bus.dispose);

      final initial = ScreenTimePolicy(
        dailyCapMinutes: 120,
        usedMinutesToday: 0,
      );
      bus.hydrate(child, policy: initial);
      bus.markChildOffline(child);

      await tester.pumpWidget(
        _app(
          ChildScreenTimeMirror(
            childId: child,
            syncBus: bus,
            initialPolicy: initial,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('متبقي 120 دقيقة'), findsOneWidget);

      final status = bus.publish(
        PolicySyncEvent(
          childId: child,
          updatedAt: DateTime.utc(2026, 9, 20, 19),
          kind: PolicySyncKind.policy,
          policy: ScreenTimePolicy(dailyCapMinutes: 80),
        ),
      );
      expect(status, PolicySyncStatus.offlineQueued);
      await tester.pumpAndSettle();
      expect(find.text('متبقي 120 دقيقة'), findsOneWidget);

      bus.markChildOnline(child);
      await tester.pumpAndSettle();
      expect(find.text('متبقي 80 دقيقة'), findsOneWidget);
    },
  );

  testWidgets('parent save shows delivered Tag when child online', (tester) async {
    final bus = PolicySyncBus();
    addTearDown(bus.dispose);
    final policyRepo = InMemoryScreenTimePolicyRepository({
      child.value: ScreenTimePolicy.defaults(),
    });

    await tester.pumpWidget(
      _app(
        ChildScreenTimeScreen(
          childId: child,
          repository: InMemoryScheduleWindowRepository(),
          policyRepository: policyRepo,
          syncBus: bus,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _scrollTo(tester, find.byKey(const Key('daily_cap_field')));
    await tester.enterText(find.byKey(const Key('daily_cap_field')), '90');
    await tester.pump();
    await _scrollTo(tester, find.byKey(const Key('child_screen_time_save')));
    await tester.tap(find.byKey(const Key('child_screen_time_save')));
    await tester.pumpAndSettle();

    expect(find.text('وُصل للابن'), findsOneWidget);
    AppToast.dismiss();
    await tester.pump(const Duration(milliseconds: 2600));
  });

  testWidgets('parent save shows pending Tag when child offline', (tester) async {
    final bus = PolicySyncBus();
    addTearDown(bus.dispose);
    bus.markChildOffline(child);
    final policyRepo = InMemoryScreenTimePolicyRepository({
      child.value: ScreenTimePolicy.defaults(),
    });

    await tester.pumpWidget(
      _app(
        ChildScreenTimeScreen(
          childId: child,
          repository: InMemoryScheduleWindowRepository(),
          policyRepository: policyRepo,
          syncBus: bus,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _scrollTo(tester, find.byKey(const Key('daily_cap_field')));
    await tester.enterText(find.byKey(const Key('daily_cap_field')), '90');
    await tester.pump();
    await _scrollTo(tester, find.byKey(const Key('child_screen_time_save')));
    await tester.tap(find.byKey(const Key('child_screen_time_save')));
    await tester.pumpAndSettle();

    expect(find.text('بانتظار مزامنة الجهاز'), findsOneWidget);
    AppToast.dismiss();
    await tester.pump(const Duration(milliseconds: 2600));
  });
}

Widget _app(Widget home) {
  final roleCtrl = RoleController(AppRole.father);
  return CurrentRole(
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
      home: home,
    ),
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
