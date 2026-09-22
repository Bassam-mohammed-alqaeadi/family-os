import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/policy_sync_bus.dart';
import 'package:family_os/core/policy/screen_time_policy.dart';
import 'package:family_os/core/policy/smart_mode_activation.dart';
import 'package:family_os/core/policy/smart_mode_activation_bus.dart';
import 'package:family_os/core/policy/smart_modes.dart';
import 'package:family_os/features/n02_day/child_day_board_screen.dart';

void main() {
  tearDown(AppToast.dismiss);

  final child = ChildId('ui005-child');

  testWidgets(
    'UI-005 AC1: parent cap change reflects on CHD-004 without relaunch post-sync',
    (tester) async {
      final syncBus = PolicySyncBus();
      final activationBus = SmartModeActivationBus();
      addTearDown(syncBus.dispose);

      final initial = ScreenTimePolicy(
        dailyCapMinutes: 120,
        usedMinutesToday: 20,
      );
      syncBus.hydrate(child, policy: initial);

      await tester.pumpWidget(
        _wrap(
          ChildDayBoardScreen(
            childId: child,
            syncBus: syncBus,
            activationBus: activationBus,
            initialPolicy: initial,
            showModeNotices: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(ChildDayBoardKeys.remainingMinutes), findsOneWidget);
      expect(find.text('متبقي 100 دقيقة'), findsOneWidget);
      final boardState = tester.state(find.byType(ChildDayBoardScreen));

      syncBus.publish(
        PolicySyncEvent(
          childId: child,
          updatedAt: DateTime.utc(2026, 9, 21, 14),
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
        identical(boardState, tester.state(find.byType(ChildDayBoardScreen))),
        isTrue,
      );
    },
  );

  testWidgets(
    'UI-005 AC2: empty day uses SHR-006 AppEmptyState',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          ChildDayBoardScreen(
            childId: child,
            emptyDay: true,
            showModeNotices: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(ChildDayBoardKeys.emptyState), findsOneWidget);
      expect(find.byType(AppEmptyState), findsOneWidget);
      expect(find.text('لا يوجد شيء هنا بعد'), findsOneWidget);
      expect(find.byKey(ChildDayBoardKeys.remainingMinutes), findsNothing);
      expect(find.byKey(ChildDayBoardKeys.statusCard), findsNothing);
    },
  );

  testWidgets(
    'UI-005 AC3: no planted prototype minutes without synced policy',
    (tester) async {
      final syncBus = PolicySyncBus();
      final activationBus = SmartModeActivationBus();
      addTearDown(syncBus.dispose);

      await tester.pumpWidget(
        _wrap(
          ChildDayBoardScreen(
            childId: child,
            syncBus: syncBus,
            activationBus: activationBus,
            showModeNotices: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(ChildDayBoardKeys.remainingMinutes), findsNothing);
      expect(find.textContaining('متبقي'), findsNothing);
      expect(find.textContaining('120'), findsNothing);
      expect(find.textContaining('خالد'), findsNothing);
      expect(find.byKey(ChildDayBoardKeys.idleStatus), findsOneWidget);
    },
  );

  testWidgets(
    'UI-005: mode + expiry shown together after activation bus emit',
    (tester) async {
      final activationBus = SmartModeActivationBus();
      final expires = DateTime.utc(2026, 9, 21, 10, 45);

      await tester.pumpWidget(
        _wrap(
          ChildDayBoardScreen(
            childId: child,
            activationBus: activationBus,
            showModeNotices: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      activationBus.publish(
        SmartModeActivation(
          childId: child.value,
          modeId: BuiltInModeId.school,
          active: true,
          updatedAt: DateTime.utc(2026, 9, 21, 8),
          expiresAt: expires,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(ChildDayBoardKeys.activeModeLabel), findsOneWidget);
      expect(find.byKey(ChildDayBoardKeys.modeExpiry), findsOneWidget);
      expect(find.textContaining('المدرسة'), findsOneWidget);
    },
  );

  testWidgets(
    'UI-005: ChildId parametric — distinct children do not cross-bind',
    (tester) async {
      final syncBus = PolicySyncBus();
      addTearDown(syncBus.dispose);
      final a = ChildId('child-a');
      final b = ChildId('child-b');
      syncBus.hydrate(
        a,
        policy: ScreenTimePolicy(dailyCapMinutes: 60, usedMinutesToday: 0),
      );
      syncBus.hydrate(
        b,
        policy: ScreenTimePolicy(dailyCapMinutes: 200, usedMinutesToday: 0),
      );

      await tester.pumpWidget(
        _wrap(
          ChildDayBoardScreen(
            childId: a,
            syncBus: syncBus,
            initialPolicy:
                ScreenTimePolicy(dailyCapMinutes: 60, usedMinutesToday: 0),
            showModeNotices: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('متبقي 60 دقيقة'), findsOneWidget);
      expect(find.text('متبقي 200 دقيقة'), findsNothing);
    },
  );
}

Widget _wrap(Widget home) {
  return MaterialApp(
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
  );
}
