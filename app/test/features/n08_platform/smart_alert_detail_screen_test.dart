import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n08_platform/smart_alert_detail_repository.dart';
import 'package:family_os/features/n08_platform/smart_alert_detail_screen.dart';

void main() {
  tearDown(AppToast.dismiss);

  testWidgets('empty → FAT-065', (tester) async {
    final nav = <String>[];
    await _pump(
      tester,
      repository: InMemorySmartAlertDetailRepository(
        seed: smartAlertDetailEmptyFixture(),
      ),
      onNavigate: nav.add,
    );
    expect(find.byKey(SmartAlertDetailKeys.empty), findsOneWidget);
    await tester.tap(find.text('Back to smart watch'));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-065'));
  });

  testWidgets('dialogue CTAs', (tester) async {
    await _pump(
      tester,
      repository: InMemorySmartAlertDetailRepository(
        seed: smartAlertDetailPrototypeFixture(),
      ),
    );
    expect(find.byKey(SmartAlertDetailKeys.body), findsOneWidget);
    expect(find.byKey(SmartAlertDetailKeys.behaviorBanner), findsOneWidget);
    expect(find.textContaining('not a judgment'), findsOneWidget);

    await tester.ensureVisible(find.byKey(SmartAlertDetailKeys.scheduleCta));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(SmartAlertDetailKeys.scheduleCta));
    await tester.pump();
    expect(find.textContaining('Added to your calendar'), findsOneWidget);
    AppToast.dismiss();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(SmartAlertDetailKeys.silentCta));
    await tester.pump();
    expect(find.textContaining('keep watching'), findsOneWidget);
    AppToast.dismiss();
    await tester.pumpAndSettle();
  });

  testWidgets('loading then body', (tester) async {
    final gate = Completer<void>();
    final repo = InMemorySmartAlertDetailRepository(
      seed: smartAlertDetailOneFixture(),
    )..loadGate = () => gate.future;
    await _pump(tester, repository: repo, settle: false);
    await tester.pump();
    expect(find.byKey(SmartAlertDetailKeys.loading), findsOneWidget);
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(SmartAlertDetailKeys.body), findsOneWidget);
  });

  testWidgets('child lean', (tester) async {
    await _pump(tester, role: AppRole.child);
    expect(find.byKey(SmartAlertDetailKeys.childLean), findsOneWidget);
  });

  testWidgets('SOS', (tester) async {
    var sos = 0;
    await _pump(
      tester,
      repository: InMemorySmartAlertDetailRepository(
        seed: smartAlertDetailOneFixture(),
      ),
      onSos: () => sos++,
    );
    await tester.tap(find.byKey(SmartAlertDetailKeys.sosIconCta));
    await tester.pumpAndSettle();
    expect(sos, 1);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  SmartAlertDetailRepository? repository,
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
        home: SmartAlertDetailScreen(
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
