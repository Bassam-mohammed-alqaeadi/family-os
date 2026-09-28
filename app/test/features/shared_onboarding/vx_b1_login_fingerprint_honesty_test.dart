import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/shared_onboarding/login_screen.dart';

/// VX-B1 / FVX-C-01 — fingerprint is NATIVE_CLOSED: honest toast, no sign-in.
void main() {
  tearDown(AppToast.dismiss);

  for (final locale in const [Locale('ar'), Locale('en')]) {
    testWidgets('fingerprint never claims success (${locale.languageCode})', (
      tester,
    ) async {
      var signedIn = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildFamilyTheme(),
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: LoginScreen(onLoginSuccess: () => signedIn = true),
        ),
      );
      await tester.pumpAndSettle();

      final biometric = find.byKey(const Key('login_biometric'));
      await tester.ensureVisible(biometric);
      await tester.tap(biometric);
      await tester.pump();

      final l10n = lookupAppLocalizations(locale);
      expect(find.text(l10n.loginBiometricUnavailable), findsOneWidget);
      expect(find.text('تم الدخول بالبصمة'), findsNothing);
      expect(find.text('Signed in with fingerprint'), findsNothing);
      expect(signedIn, isFalse);
      expect(find.byType(LoginScreen), findsOneWidget);

      AppToast.dismiss();
      await tester.pump();
    });
  }
}
