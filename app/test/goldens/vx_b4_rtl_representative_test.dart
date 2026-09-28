import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n02_day/day_board_screen.dart';
import 'package:family_os/features/n02_day/children_list_screen.dart';
import 'package:family_os/features/n02_day/child_day_board_screen.dart';

/// VX-B4 · RTL smoke at 360 dp (superseded for full homes by VX-B7 render suite).
void main() {
  Future<void> pumpAt360(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildFamilyTheme(),
        home: home,
      ),
    );
    await tester.pump();
  }

  testWidgets('FAT-010 day board renders at 360 AR', (tester) async {
    await pumpAt360(tester, const DayBoardScreen());
    expect(find.byType(DayBoardScreen), findsOneWidget);
  });

  testWidgets('FAT-012 children list renders at 360 AR', (tester) async {
    await pumpAt360(tester, const ChildrenListScreen());
    expect(find.byType(ChildrenListScreen), findsOneWidget);
  });

  testWidgets('CHD-004 child day board renders at 360 AR', (tester) async {
    await pumpAt360(tester, ChildDayBoardScreen());
    expect(find.byType(ChildDayBoardScreen), findsOneWidget);
  });

  // CHD-012 learn-home 360 overflow tracked for VX-B7 render pass (not a B4 block).
}
