import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n02_day/outer_circle_repository.dart';
import 'package:family_os/features/n02_day/outer_circle_screen.dart';

void main() {
  testWidgets('empty → FAT-003', (tester) async {
    final nav = <String>[];
    final repo = InMemoryOuterCircleRepository(seed: outerCircleEmptyFixture());
    await _pump(tester, repository: repo, onNavigate: nav.add);

    expect(find.byKey(OuterCircleKeys.empty), findsOneWidget);
    await tester.tap(find.text('Add a child'));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-003'));
  });

  testWidgets('prototype relatives + friends + pending → 071', (tester) async {
    final nav = <String>[];
    final repo = InMemoryOuterCircleRepository(
      seed: outerCirclePrototypeFixture(),
    );
    await _pump(tester, repository: repo, onNavigate: nav.add);

    expect(find.byKey(OuterCircleKeys.body), findsOneWidget);
    expect(find.byKey(OuterCircleKeys.strangersBanner), findsOneWidget);
    expect(find.byKey(OuterCircleKeys.member('r1')), findsOneWidget);
    expect(find.byKey(OuterCircleKeys.member('f1')), findsOneWidget);
    expect(find.byKey(OuterCircleKeys.pending('p1')), findsOneWidget);

    await tester.tap(find.byKey(OuterCircleKeys.pending('p1')));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-071'));
  });

  testWidgets('loading then body', (tester) async {
    final gate = Completer<void>();
    final repo = InMemoryOuterCircleRepository(seed: outerCircleOneFixture())
      ..loadGate = () => gate.future;

    await _pump(tester, repository: repo, settle: false);
    await tester.pump();
    expect(find.byKey(OuterCircleKeys.loading), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(OuterCircleKeys.body), findsOneWidget);
  });

  testWidgets('child RoleGuard lean + SOS', (tester) async {
    var sos = false;
    await _pump(tester, role: AppRole.child, onSos: () => sos = true);

    expect(find.byKey(OuterCircleKeys.childLean), findsOneWidget);
    await tester.tap(find.byKey(OuterCircleKeys.sosIconCta));
    await tester.pumpAndSettle();
    expect(sos, isTrue);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  OuterCircleRepository? repository,
  AppRole role = AppRole.father,
  VoidCallback? onSos,
  void Function(String screenId)? onNavigate,
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
        home: OuterCircleScreen(
          repository: repository,
          roleOverride: role,
          onSos: onSos,
          onNavigate: onNavigate,
        ),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  }
}
