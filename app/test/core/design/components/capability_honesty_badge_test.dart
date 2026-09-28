import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/components/capability_honesty_badge.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/fs_foundation/capability_status.dart';
import 'package:family_os/core/i18n/app_localizations.dart';

void main() {
  Widget wrap(Widget child, {Locale locale = const Locale('ar')}) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildFamilyTheme(),
      home: Scaffold(body: child),
    );
  }

  testWidgets('renders glossary IMPLEMENTED badge (AR)', (tester) async {
    await tester.pumpWidget(
      wrap(const CapabilityHonestyBadge(status: CapabilityStatus.implemented)),
    );
    expect(find.text('يعمل'), findsOneWidget);
  });

  testWidgets('renders glossary MOCK-REMOTE badge (AR)', (tester) async {
    await tester.pumpWidget(
      wrap(const CapabilityHonestyBadge(status: CapabilityStatus.mockRemote)),
    );
    expect(find.text('على هذا الجهاز'), findsOneWidget);
  });

  testWidgets('renders glossary DEGRADED badge (EN)', (tester) async {
    await tester.pumpWidget(
      wrap(
        const CapabilityHonestyBadge(status: CapabilityStatus.degraded),
        locale: const Locale('en'),
      ),
    );
    expect(find.text('Partly working'), findsOneWidget);
    expect(find.byType(Semantics), findsWidgets);
  });
}
