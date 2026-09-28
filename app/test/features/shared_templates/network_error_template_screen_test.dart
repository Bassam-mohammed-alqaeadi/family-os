import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/shared_templates/network_error_template_screen.dart';

void main() {
  testWidgets('SCR-SHR-005 catalog hosts AppErrorState network kind', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildFamilyTheme(),
        locale: const Locale('ar'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const NetworkErrorTemplateScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('shr_005_catalog_error')), findsOneWidget);
  });
}
