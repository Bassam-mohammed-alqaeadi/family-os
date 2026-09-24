import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n17_child_learn/child_focus_repository.dart';
import 'package:family_os/features/n17_child_learn/child_focus_screen.dart';

void main() {
  tearDown(AppToast.dismiss);

  testWidgets('empty → CHD-012', (tester) async {
    final nav = <String>[];
    await _pump(
      tester,
      repository: InMemoryChildFocusRepository(seed: childFocusEmptyFixture()),
      onNavigate: nav.add,
    );
    expect(find.byKey(ChildFocusKeys.empty), findsOneWidget);
    await tester.tap(find.text('Back to My learning'));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-CHD-012'));
  });

  testWidgets('body + start toast + sounds →035', (tester) async {
    final nav = <String>[];
    await _pump(
      tester,
      repository: InMemoryChildFocusRepository(
        seed: childFocusPrototypeFixture(),
      ),
      onNavigate: nav.add,
    );
    expect(find.byKey(ChildFocusKeys.body), findsOneWidget);
    expect(find.byKey(ChildFocusKeys.timerCircle), findsOneWidget);
    expect(find.text('25:00'), findsOneWidget);
    expect(find.byKey(ChildFocusKeys.honestyNote), findsOneWidget);
    expect(find.byKey(ChildFocusKeys.praiseBanner), findsOneWidget);
    expect(find.textContaining('Proud of you'), findsOneWidget);

    await tester.tap(find.byKey(ChildFocusKeys.startCta));
    await tester.pump();
    expect(find.textContaining('Focus started'), findsOneWidget);
    AppToast.dismiss();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ChildFocusKeys.soundsCta));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-CHD-035'));
  });

  testWidgets('one fixture — no praise banner', (tester) async {
    await _pump(
      tester,
      repository: InMemoryChildFocusRepository(seed: childFocusOneFixture()),
    );
    expect(find.byKey(ChildFocusKeys.body), findsOneWidget);
    expect(find.byKey(ChildFocusKeys.praiseBanner), findsNothing);
  });

  testWidgets('loading then body', (tester) async {
    final gate = Completer<void>();
    final repo = InMemoryChildFocusRepository(seed: childFocusOneFixture())
      ..loadGate = () => gate.future;
    await _pump(tester, repository: repo, settle: false);
    await tester.pump();
    expect(find.byKey(ChildFocusKeys.loading), findsOneWidget);
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(ChildFocusKeys.body), findsOneWidget);
  });

  testWidgets('parent lean', (tester) async {
    await _pump(tester, role: AppRole.father);
    expect(find.byKey(ChildFocusKeys.parentLean), findsOneWidget);
  });

  testWidgets('SOS', (tester) async {
    var sos = 0;
    await _pump(
      tester,
      repository: InMemoryChildFocusRepository(seed: childFocusOneFixture()),
      onSos: () => sos++,
    );
    await tester.tap(find.byKey(ChildFocusKeys.sosIconCta));
    await tester.pumpAndSettle();
    expect(sos, 1);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  ChildFocusRepository? repository,
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
        home: ChildFocusScreen(
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
