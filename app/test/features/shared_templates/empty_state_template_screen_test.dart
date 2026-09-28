import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/shared_templates/empty_state_template_screen.dart';

void main() {
  testWidgets('SCR-SHR-006 catalog hosts AppEmptyState', (tester) async {
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
        home: const EmptyStateTemplateScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('shr_006_catalog_empty')), findsOneWidget);
  });
}
