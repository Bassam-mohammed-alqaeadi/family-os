import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/app/gallery_screen.dart';
import 'package:family_os/app/role_controller.dart';
import 'package:family_os/app/router.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/shared_onboarding/welcome_screen.dart';
import 'package:family_os/main.dart';

void main() {
  testWidgets('product entry is welcome SCR-SHR-001', (tester) async {
    await tester.pumpWidget(const FamilyOsApp());
    await tester.pumpAndSettle();

    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.text('ابدأ الآن'), findsOneWidget);
    expect(find.textContaining('عائلتي'), findsWidgets);
  });

  testWidgets('gallery still reachable at /gallery', (tester) async {
    final role = RoleController(AppRole.father);
    final router = createAppRouter(
      roleListenable: role,
      initialLocation: '/gallery',
    );
    addTearDown(() {
      router.dispose();
      role.dispose();
    });

    await tester.pumpWidget(
      CurrentRole(
        notifier: role,
        child: MaterialApp.router(
          theme: buildFamilyTheme(),
          locale: const Locale('ar'),
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
    );
    await tester.pumpAndSettle();

    expect(find.byType(GalleryScreen), findsOneWidget);
    expect(find.text('الألوان'), findsOneWidget);
    expect(find.text('الظلال'), findsOneWidget);
    expect(find.text('p500'), findsOneWidget);
    expect(find.text('#7C5CE6'), findsOneWidget);
  });
}
