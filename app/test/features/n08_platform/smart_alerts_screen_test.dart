import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n08_platform/smart_alerts_repository.dart';
import 'package:family_os/features/n08_platform/smart_alerts_screen.dart';

void main() {
  testWidgets('empty → FAT-003', (tester) async {
    final nav = <String>[];
    await _pump(
      tester,
      repository: InMemorySmartAlertsRepository(
        seed: smartAlertsEmptyFixture(),
      ),
      onNavigate: nav.add,
    );
    expect(find.byKey(SmartAlertsKeys.empty), findsOneWidget);
    await tester.tap(find.text('Add a child'));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-003'));
  });

  testWidgets('alert →066 + settings →067', (tester) async {
    final nav = <String>[];
    await _pump(
      tester,
      repository: InMemorySmartAlertsRepository(
        seed: smartAlertsPrototypeFixture(),
      ),
      onNavigate: nav.add,
    );
    expect(find.byKey(SmartAlertsKeys.body), findsOneWidget);
    expect(find.byKey(SmartAlertsKeys.honestyBanner), findsOneWidget);
    expect(find.textContaining('transparent'), findsOneWidget);

    await tester.tap(find.byKey(SmartAlertsKeys.alert('a1')));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-066'));

    await tester.ensureVisible(find.byKey(SmartAlertsKeys.settingsCta));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(SmartAlertsKeys.settingsCta));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-067'));
  });

  testWidgets('loading then body', (tester) async {
    final gate = Completer<void>();
    final repo = InMemorySmartAlertsRepository(seed: smartAlertsOneFixture())
      ..loadGate = () => gate.future;
    await _pump(tester, repository: repo, settle: false);
    await tester.pump();
    expect(find.byKey(SmartAlertsKeys.loading), findsOneWidget);
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(SmartAlertsKeys.body), findsOneWidget);
  });

  testWidgets('child lean', (tester) async {
    await _pump(tester, role: AppRole.child);
    expect(find.byKey(SmartAlertsKeys.childLean), findsOneWidget);
  });

  testWidgets('SOS', (tester) async {
    var sos = 0;
    await _pump(
      tester,
      repository: InMemorySmartAlertsRepository(seed: smartAlertsOneFixture()),
      onSos: () => sos++,
    );
    await tester.tap(find.byKey(SmartAlertsKeys.sosIconCta));
    await tester.pumpAndSettle();
    expect(sos, 1);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  SmartAlertsRepository? repository,
  AppRole role = AppRole.father,
  VoidCallback? onSos,
  void Function(String screenId)? onNavigate,
  bool settle = true,
}) async {
  await tester.pumpWidget(
    CurrentRole(
      notifier: RoleController(role),
      child: MaterialApp(
        theme: buildFamilyTheme(),
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: SmartAlertsScreen(
          repository: repository,
          roleOverride: role,
          onSos: onSos,
          onNavigate: onNavigate,
        ),
      ),
    ),
  );
  if (settle) await tester.pumpAndSettle();
}
