import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/shared_onboarding/login_screen.dart';

/// VX-B6 / FVX-C-02 — login validation + local honesty + 48 dp links.
void main() {
  tearDown(AppToast.dismiss);

  testWidgets('empty submit shows required validation; honesty line present', (
    tester,
  ) async {
    var loggedIn = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildFamilyTheme(),
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: LoginScreen(onLoginSuccess: () => loggedIn++),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(LoginKeys.honesty), findsOneWidget);
    expect(find.text('Account is saved on this device'), findsOneWidget);

    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pump();

    expect(loggedIn, 0);
    expect(find.byKey(LoginKeys.emailError), findsOneWidget);
    expect(find.text('Enter email and password to continue'), findsWidgets);

    final forgot = tester.getSize(find.byKey(const Key('login_forgot')));
    expect(forgot.height, greaterThanOrEqualTo(48));
    AppToast.dismiss();
    await tester.pump();
  });

  testWidgets('filled fields allow login success seam', (tester) async {
    var loggedIn = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildFamilyTheme(),
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: LoginScreen(onLoginSuccess: () => loggedIn++),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('login_email')), 'a@b.c');
    await tester.enterText(find.byKey(const Key('login_password')), 'secret');
    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pump();

    expect(loggedIn, 1);
  });
}
