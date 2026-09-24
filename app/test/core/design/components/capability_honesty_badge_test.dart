import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:family_os/core/design/components/capability_honesty_badge.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/fs_foundation/capability_status.dart';
import 'package:family_os/core/i18n/app_localizations.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildFamilyTheme(),
      home: Scaffold(body: child),
    );
  }

  testWidgets('renders IMPLEMENTED badge', (tester) async {
    await tester.pumpWidget(
      wrap(const CapabilityHonestyBadge(status: CapabilityStatus.implemented)),
    );
    expect(find.text('IMPLEMENTED'), findsOneWidget);
  });

  testWidgets('renders MOCK-REMOTE badge', (tester) async {
    await tester.pumpWidget(
      wrap(const CapabilityHonestyBadge(status: CapabilityStatus.mockRemote)),
    );
    expect(find.text('MOCK-REMOTE'), findsOneWidget);
  });

  testWidgets('semantics label present', (tester) async {
    await tester.pumpWidget(
      wrap(const CapabilityHonestyBadge(status: CapabilityStatus.degraded)),
    );
    expect(find.text('DEGRADED'), findsOneWidget);
    expect(find.byType(Semantics), findsWidgets);
  });
}
