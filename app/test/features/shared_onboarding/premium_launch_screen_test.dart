import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/i18n/locale_controller.dart';
import 'package:family_os/features/shared_onboarding/premium_launch_screen.dart';
import 'package:family_os/features/shared_onboarding/welcome_screen.dart';

void main() {
  testWidgets('signed-out launch is bounded and persists language choice', (
    tester,
  ) async {
    String? persisted;
    final locale = LocaleController(
      persist: (languageCode) async => persisted = languageCode,
    );
    final router = GoRouter(
      initialLocation: '/launch',
      routes: [
        GoRoute(
          path: '/launch',
          builder: (context, state) => const PremiumLaunchScreen(),
        ),
        GoRoute(
          path: '/scr-shr-001',
          builder: (context, state) => const WelcomeScreen(),
        ),
      ],
    );
    addTearDown(() {
      router.dispose();
      locale.dispose();
    });

    await tester.pumpWidget(
      CurrentLocale(
        controller: locale,
        child: ListenableBuilder(
          listenable: locale,
          builder: (context, _) => MaterialApp.router(
            theme: buildFamilyTheme(),
            locale: locale.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            routerConfig: router,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(PremiumLaunchScreen), findsOneWidget);
    await tester.tap(find.byKey(const Key('launch_language_en')));
    await tester.pump();
    expect(locale.locale.languageCode, 'en');
    expect(persisted, 'en');

    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/scr-shr-001');
    expect(find.byType(WelcomeScreen), findsOneWidget);
  });
}
