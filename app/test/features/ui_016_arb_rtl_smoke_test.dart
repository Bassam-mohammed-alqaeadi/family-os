import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/policy_sync_bus.dart';
import 'package:family_os/core/policy/screen_time_policy.dart';
import 'package:family_os/core/policy/smart_mode_activation_bus.dart';
import 'package:family_os/core/policy/time_request_repository.dart';
import 'package:family_os/core/policy/time_request_service.dart';
import 'package:family_os/features/n02_day/child_day_board_screen.dart';
import 'package:family_os/features/n02_day/day_board_projection.dart';
import 'package:family_os/features/n02_day/day_board_screen.dart';
import 'package:family_os/features/n02_day/request_inbox_screen.dart';
import 'package:family_os/features/shared_onboarding/welcome_screen.dart';

/// UI-016 AC2 — AR+EN smoke on key FAT / CHD / SHR hosts (Rule 12 / G-3).
void main() {
  final child = ChildId('ui016-child');

  for (final locale in const [Locale('ar'), Locale('en')]) {
    final isAr = locale.languageCode == 'ar';

    testWidgets('FAT-010 DayBoard pumps ($locale) without exception', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          locale: locale,
          child: const DayBoardScreen(
            projection: DayBoardProjection.empty,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.text(isAr ? 'لوحة اليوم' : "Today's board"),
        findsOneWidget,
      );
      expect(
        Directionality.of(tester.element(find.byType(DayBoardScreen))),
        isAr ? TextDirection.rtl : TextDirection.ltr,
      );
    });

    testWidgets('CHD-004 ChildDayBoard pumps ($locale) without exception', (
      tester,
    ) async {
      final syncBus = PolicySyncBus();
      addTearDown(syncBus.dispose);
      final policy = ScreenTimePolicy(
        dailyCapMinutes: 90,
        usedMinutesToday: 10,
      );
      syncBus.hydrate(child, policy: policy);

      await tester.pumpWidget(
        _wrap(
          locale: locale,
          child: ChildDayBoardScreen(
            childId: child,
            syncBus: syncBus,
            activationBus: SmartModeActivationBus(),
            initialPolicy: policy,
            showModeNotices: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.text(isAr ? 'لوحة يومي' : 'My day board'),
        findsOneWidget,
      );
      expect(
        Directionality.of(tester.element(find.byType(ChildDayBoardScreen))),
        isAr ? TextDirection.rtl : TextDirection.ltr,
      );
    });

    testWidgets('FAT-033 RequestInbox pumps ($locale) without exception', (
      tester,
    ) async {
      final service = TimeRequestService(
        repository: InMemoryTimeRequestRepository(),
        decisionBus: TimeRequestDecisionBus(),
      );

      await tester.pumpWidget(
        _wrap(
          locale: locale,
          child: RequestInboxScreen(service: service),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.text(isAr ? 'طلبات الوقت الإضافي' : 'Extra time requests'),
        findsOneWidget,
      );
      expect(
        Directionality.of(tester.element(find.byType(RequestInboxScreen))),
        isAr ? TextDirection.rtl : TextDirection.ltr,
      );
    });

    testWidgets('SHR-001 Welcome pumps ($locale) without exception', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          locale: locale,
          child: WelcomeScreen(onStart: () {}, onLogin: () {}),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.text(isAr ? 'ابدأ الآن' : 'Get started'),
        findsOneWidget,
      );
      expect(
        Directionality.of(tester.element(find.byType(WelcomeScreen))),
        isAr ? TextDirection.rtl : TextDirection.ltr,
      );
    });
  }
}

Widget _wrap({required Locale locale, required Widget child}) {
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
