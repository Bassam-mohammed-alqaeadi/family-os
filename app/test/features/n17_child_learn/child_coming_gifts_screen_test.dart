import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n17_child_learn/child_coming_gifts_repository.dart';
import 'package:family_os/features/n17_child_learn/child_coming_gifts_screen.dart';

void main() {
  testWidgets('empty → CHD-012', (tester) async {
    final nav = <String>[];
    await _pump(
      tester,
      repository: InMemoryChildComingGiftsRepository(
        seed: childComingGiftsEmptyFixture(),
      ),
      onNavigate: nav.add,
    );
    expect(find.byKey(ChildComingGiftsKeys.empty), findsOneWidget);
    await tester.tap(find.text('My learning'));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-CHD-012'));
  });

  testWidgets('body + callPlay → CHD-036', (tester) async {
    final nav = <String>[];
    await _pump(
      tester,
      repository: InMemoryChildComingGiftsRepository(
        seed: childComingGiftsPrototypeFixture(),
      ),
      onNavigate: nav.add,
    );
    expect(find.byKey(ChildComingGiftsKeys.body), findsOneWidget);

    await tester.tap(find.byKey(ChildComingGiftsKeys.link('callPlay')));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-CHD-036'));
  });

  testWidgets('loading then body', (tester) async {
    final gate = Completer<void>();
    final repo = InMemoryChildComingGiftsRepository(
      seed: childComingGiftsOneFixture(),
    )..loadGate = () => gate.future;
    await _pump(tester, repository: repo, settle: false);
    await tester.pump();
    expect(find.byKey(ChildComingGiftsKeys.loading), findsOneWidget);
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(ChildComingGiftsKeys.body), findsOneWidget);
  });

  testWidgets('parent lean', (tester) async {
    await _pump(tester, role: AppRole.father);
    expect(find.byKey(ChildComingGiftsKeys.parentLean), findsOneWidget);
  });

  testWidgets('SOS', (tester) async {
    var sos = 0;
    await _pump(
      tester,
      repository: InMemoryChildComingGiftsRepository(
        seed: childComingGiftsOneFixture(),
      ),
      onSos: () => sos++,
    );
    await tester.tap(find.byKey(ChildComingGiftsKeys.sosIconCta));
    await tester.pumpAndSettle();
    expect(sos, 1);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  ChildComingGiftsRepository? repository,
  AppRole role = AppRole.child,
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
        home: ChildComingGiftsScreen(
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
