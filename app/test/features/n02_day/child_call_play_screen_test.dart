import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n02_day/child_call_play_repository.dart';
import 'package:family_os/features/n02_day/child_call_play_screen.dart';

void main() {
  tearDown(AppToast.dismiss);

  testWidgets('empty → CHD-007', (tester) async {
    final nav = <String>[];
    await _pump(
      tester,
      repository: InMemoryChildCallPlayRepository(
        seed: childCallPlayEmptyFixture(),
      ),
      onNavigate: nav.add,
    );
    expect(find.byKey(ChildCallPlayKeys.empty), findsOneWidget);
    await tester.tap(find.text('My chats'));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-CHD-007'));
  });

  testWidgets('open draw board', (tester) async {
    final repo = InMemoryChildCallPlayRepository(
      seed: childCallPlayPrototypeFixture(),
    );
    await _pump(tester, repository: repo);
    expect(find.byKey(ChildCallPlayKeys.hero), findsOneWidget);
    await tester.tap(find.byKey(ChildCallPlayKeys.game('draw')));
    await tester.pump();
    expect(find.textContaining('Board open'), findsOneWidget);
    expect(repo.lastGameId, 'draw');
    AppToast.dismiss();
    await tester.pumpAndSettle();
  });

  testWidgets('loading then body', (tester) async {
    final gate = Completer<void>();
    final repo = InMemoryChildCallPlayRepository(
      seed: childCallPlayOneFixture(),
    )..loadGate = () => gate.future;
    await _pump(tester, repository: repo, settle: false);
    await tester.pump();
    expect(find.byKey(ChildCallPlayKeys.loading), findsOneWidget);
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(ChildCallPlayKeys.body), findsOneWidget);
  });

  testWidgets('parent lean + SOS', (tester) async {
    var sos = false;
    await _pump(tester, role: AppRole.father, onSos: () => sos = true);
    expect(find.byKey(ChildCallPlayKeys.parentLean), findsOneWidget);
    await tester.tap(find.byKey(ChildCallPlayKeys.sosIconCta));
    await tester.pumpAndSettle();
    expect(sos, isTrue);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  ChildCallPlayRepository? repository,
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
        home: ChildCallPlayScreen(
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
