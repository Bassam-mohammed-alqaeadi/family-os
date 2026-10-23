import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/minutes.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/policy_sync_bus.dart';
import 'package:family_os/core/policy/screen_time_policy.dart';
import 'package:family_os/core/policy/smart_mode_activation_bus.dart';
import 'package:family_os/features/n02_day/child_day_board_screen.dart';

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

void main() {
  tearDown(AppToast.dismiss);

  final testChildId = ChildId('child-1234');

  testWidgets(
    'the child is told when earned minutes extend today limit',
    (tester) async {
      final syncBus = PolicySyncBus();
      final activationBus = SmartModeActivationBus();

      syncBus.hydrate(
        testChildId,
        policy: ScreenTimePolicy(
          dailyCapMinutes: 90,
          earnedMinutesExtendLimit: true,
          wallets: [
            AppWallet(appId: 'games', earnedMinutes: Minutes(30)),
          ],
        ),
      );

      await tester.pumpWidget(
        _wrap(
          ChildDayBoardScreen(
            childId: testChildId,
            syncBus: syncBus,
            activationBus: activationBus,
            showModeNotices: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final noteFinder = find.byKey(ChildDayBoardKeys.earnedExtensionNote);
      expect(noteFinder, findsOneWidget);
      final textWidget = tester.widget<Text>(noteFinder);
      expect(
        textWidget.data,
        'الدقائق التي تكسبها من أنشطتك تُضاف إلى وقتك اليومي',
      );
    },
  );

  testWidgets(
    'the child is told when earned minutes do not extend today limit',
    (tester) async {
      final syncBus = PolicySyncBus();
      final activationBus = SmartModeActivationBus();

      syncBus.hydrate(
        testChildId,
        policy: ScreenTimePolicy(
          dailyCapMinutes: 90,
          earnedMinutesExtendLimit: false,
          wallets: [
            AppWallet(appId: 'games', earnedMinutes: Minutes(30)),
          ],
        ),
      );

      await tester.pumpWidget(
        _wrap(
          ChildDayBoardScreen(
            childId: testChildId,
            syncBus: syncBus,
            activationBus: activationBus,
            showModeNotices: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final noteFinder = find.byKey(ChildDayBoardKeys.earnedExtensionNote);
      expect(noteFinder, findsOneWidget);
      final textWidget = tester.widget<Text>(noteFinder);
      expect(
        textWidget.data,
        'الدقائق التي تكسبها من أنشطتك لا تُضاف إلى وقت اليوم — تُحفظ لك',
      );
    },
  );

  testWidgets(
    'nothing about earned minutes appears before a policy is applied',
    (tester) async {
      final syncBus = PolicySyncBus();
      final activationBus = SmartModeActivationBus();

      await tester.pumpWidget(
        _wrap(
          ChildDayBoardScreen(
            childId: testChildId,
            syncBus: syncBus,
            activationBus: activationBus,
            showModeNotices: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(ChildDayBoardKeys.earnedExtensionNote), findsNothing);
    },
  );
}

