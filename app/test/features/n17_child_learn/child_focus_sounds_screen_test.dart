import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n17_child_learn/child_focus_sounds_repository.dart';
import 'package:family_os/features/n17_child_learn/child_focus_sounds_screen.dart';

void main() {
  tearDown(AppToast.dismiss);

  testWidgets('empty → CHD-018', (tester) async {
    final nav = <String>[];
    await _pump(
      tester,
      repository: InMemoryChildFocusSoundsRepository(
        seed: childFocusSoundsEmptyFixture(),
      ),
      onNavigate: nav.add,
    );
    expect(find.byKey(ChildFocusSoundsKeys.empty), findsOneWidget);
    await tester.tap(find.text('Focus mode'));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-CHD-018'));
  });

  testWidgets('play rain + start focus', (tester) async {
    final nav = <String>[];
    final repo = InMemoryChildFocusSoundsRepository(
      seed: childFocusSoundsPrototypeFixture(),
    );
    await _pump(tester, repository: repo, onNavigate: nav.add);
    expect(find.byKey(ChildFocusSoundsKeys.grid), findsOneWidget);
    await tester.tap(find.byKey(ChildFocusSoundsKeys.sound('rain')));
    await tester.pump();
    expect(find.textContaining('Quiet rain is playing'), findsOneWidget);
    expect(repo.activeSoundId, 'rain');
    AppToast.dismiss();
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(ChildFocusSoundsKeys.startFocusCta));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ChildFocusSoundsKeys.startFocusCta));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-CHD-018'));
  });

  testWidgets('loading then body', (tester) async {
    final gate = Completer<void>();
    final repo = InMemoryChildFocusSoundsRepository(
      seed: childFocusSoundsOneFixture(),
    )..loadGate = () => gate.future;
    await _pump(tester, repository: repo, settle: false);
    await tester.pump();
    expect(find.byKey(ChildFocusSoundsKeys.loading), findsOneWidget);
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(ChildFocusSoundsKeys.body), findsOneWidget);
  });

  testWidgets('parent lean + SOS', (tester) async {
    var sos = false;
    await _pump(tester, role: AppRole.father, onSos: () => sos = true);
    expect(find.byKey(ChildFocusSoundsKeys.parentLean), findsOneWidget);
    await tester.tap(find.byKey(ChildFocusSoundsKeys.sosIconCta));
    await tester.pumpAndSettle();
    expect(sos, isTrue);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  ChildFocusSoundsRepository? repository,
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
        home: ChildFocusSoundsScreen(
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
