import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/dev_screen_gallery.dart';
import 'package:family_os/app/role_controller.dart';
import 'package:family_os/app/router.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/shared_onboarding/welcome_screen.dart';

void main() {
  testWidgets('DevScreenGallery lists SCR-IDs and opens a screen', (
    tester,
  ) async {
    final role = RoleController(AppRole.father);
    final router = createAppRouter(
      roleListenable: role,
      initialLocation: DevScreenGallery.routePath,
    );
    addTearDown(() {
      router.dispose();
      role.dispose();
    });

    await tester.pumpWidget(_App(router: router));
    await tester.pumpAndSettle();

    expect(find.byType(DevScreenGallery), findsOneWidget);
    expect(find.text('SCR-SHR-001'), findsOneWidget);

    final target = find.byKey(const ValueKey<String>('SCR-SHR-001'));
    expect(target, findsOneWidget);
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pumpAndSettle();

    expect(find.byType(WelcomeScreen), findsOneWidget);
  });

  test('createAppRouter registers /dev-screens', () {
    final role = RoleController(AppRole.father);
    final router = createAppRouter(roleListenable: role);
    addTearDown(() {
      router.dispose();
      role.dispose();
    });
    final routes = router.configuration.routes.whereType<GoRoute>();
    expect(
      routes.any(
        (r) =>
            r.path == DevScreenGallery.routePath ||
            r.name == DevScreenGallery.routeName,
      ),
      isTrue,
    );
  });
}

class _App extends StatelessWidget {
  const _App({required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: buildFamilyTheme(),
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
