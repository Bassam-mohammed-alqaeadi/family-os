import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/sos_alert_repository.dart';
import 'package:family_os/features/n10_emergency/sos_alert_screen.dart';

void main() {
  testWidgets('VX-B5: FAT-018 no-alert shows designed empty (SHR-006)', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        theme: buildFamilyTheme(),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: SosAlertScreen(
          repository: InMemorySosAlertRepository(),
          roleOverride: AppRole.father,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(SosAlertKeys.empty), findsOneWidget);
    expect(find.byType(AppEmptyState), findsOneWidget);
    final l10n = lookupAppLocalizations(const Locale('en'));
    expect(find.text(l10n.sosAlertEmptyTitle), findsOneWidget);
    expect(find.text(l10n.sosAlertEmptyMessage), findsOneWidget);
  });
}
