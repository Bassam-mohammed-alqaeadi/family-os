import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/family_shell.dart';
import 'package:family_os/app/role_controller.dart';
import 'package:family_os/app/router.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n02_day/day_board_projection.dart';
import 'package:family_os/features/n02_day/day_board_screen.dart';
import 'package:family_os/features/n02_day/day_child_mock.dart';

void main() {
  testWidgets('settings hub keeps device switch; drops FAT-009 and FAT-018', (
    tester,
  ) async {
    final role = RoleController(AppRole.father);
    final router = createAppRouter(
      roleListenable: role,
      initialLocation: '/scr-fat-025',
    );
    await tester.pumpWidget(
      CurrentRole(
        notifier: role,
        child: MaterialApp.router(
          theme: buildFamilyTheme(),
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          routerConfig: router,
          builder: (context, child) => FamilyShellHost(
            router: router,
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final l10n = lookupAppLocalizations(const Locale('en'));
    expect(find.text(l10n.shellShortcutDeviceSwitch), findsOneWidget);
    expect(find.text(l10n.shellShortcutAcceptInvite), findsNothing);
    expect(find.text(l10n.shellShortcutSosAlert), findsNothing);
  });

  testWidgets('quick actions + child profile use push (Back returns)', (
    tester,
  ) async {
    final paths = <String>[];
    final router = GoRouter(
      initialLocation: '/scr-fat-010',
      routes: [
        GoRoute(
          path: '/scr-fat-010',
          builder: (context, state) => DayBoardScreen(
            projection: DayBoardProjection(
              children: DayChildMock.manyFixture,
            ),
          ),
        ),
        GoRoute(
          path: '/scr-fat-013',
          builder: (context, state) {
            paths.add(state.uri.toString());
            return const Scaffold(body: Text('profile'));
          },
        ),
        GoRoute(
          path: '/scr-fat-014',
          builder: (context, state) {
            paths.add(state.uri.toString());
            return const Scaffold(body: Text('map'));
          },
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
        theme: buildFamilyTheme(),
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(DayBoardKeys.activeChild));
    await tester.pumpAndSettle();
    expect(paths.any((p) => p.startsWith('/scr-fat-013')), isTrue);
    expect(router.canPop(), isTrue);

    router.pop();
    await tester.pumpAndSettle();
    expect(find.byType(DayBoardScreen), findsOneWidget);

    final l10n = lookupAppLocalizations(const Locale('en'));
    await tester.tap(find.text(l10n.dayBoardQuickMap));
    await tester.pumpAndSettle();
    expect(
      paths.any((p) => p.contains('/scr-fat-014') && p.contains('childId=')),
      isTrue,
    );
  });
}
