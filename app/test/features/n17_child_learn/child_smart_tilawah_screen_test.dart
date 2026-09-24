import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n17_child_learn/child_smart_tilawah_repository.dart';
import 'package:family_os/features/n17_child_learn/child_smart_tilawah_screen.dart';

void main() {
  tearDown(AppToast.dismiss);

  testWidgets('empty → CHD-014', (tester) async {
    final nav = <String>[];
    await _pump(
      tester,
      repository: InMemoryChildSmartTilawahRepository(
        seed: childSmartTilawahEmptyFixture(),
      ),
      onNavigate: nav.add,
    );
    expect(find.byKey(ChildSmartTilawahKeys.empty), findsOneWidget);
    await tester.tap(find.text('My Quran ward'));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-CHD-014'));
  });

  testWidgets('listen + sheikh', (tester) async {
    final repo = InMemoryChildSmartTilawahRepository(
      seed: childSmartTilawahPrototypeFixture(),
    );
    await _pump(tester, repository: repo);
    expect(find.byKey(ChildSmartTilawahKeys.ayahCard), findsOneWidget);
    await tester.tap(find.byKey(ChildSmartTilawahKeys.listenCta));
    await tester.pump();
    expect(find.textContaining('Listening'), findsOneWidget);
    expect(repo.listening, isTrue);
    AppToast.dismiss();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ChildSmartTilawahKeys.sheikhCta));
    await tester.pump();
    expect(
      find.text('Sheikh clip for ayah 16 — from a licensed mushaf'),
      findsOneWidget,
    );
    expect(repo.sheikhPlayed, isTrue);
    AppToast.dismiss();
    await tester.pumpAndSettle();
  });

  testWidgets('loading then body', (tester) async {
    final gate = Completer<void>();
    final repo = InMemoryChildSmartTilawahRepository(
      seed: childSmartTilawahOneFixture(),
    )..loadGate = () => gate.future;
    await _pump(tester, repository: repo, settle: false);
    await tester.pump();
    expect(find.byKey(ChildSmartTilawahKeys.loading), findsOneWidget);
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(ChildSmartTilawahKeys.body), findsOneWidget);
  });

  testWidgets('parent lean + SOS', (tester) async {
    var sos = false;
    await _pump(tester, role: AppRole.father, onSos: () => sos = true);
    expect(find.byKey(ChildSmartTilawahKeys.parentLean), findsOneWidget);
    await tester.tap(find.byKey(ChildSmartTilawahKeys.sosIconCta));
    await tester.pumpAndSettle();
    expect(sos, isTrue);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  ChildSmartTilawahRepository? repository,
  AppRole role = AppRole.child,
  VoidCallback? onSos,
  void Function(String)? onNavigate,
  bool settle = true,
}) async {
  final roleCtrl = RoleController(role);
  addTearDown(roleCtrl.dispose);
  await tester.pumpWidget(
    CurrentRole(
      notifier: roleCtrl,
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
        home: ChildSmartTilawahScreen(
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
