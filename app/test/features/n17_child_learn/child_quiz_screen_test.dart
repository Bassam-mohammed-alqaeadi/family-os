import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n17_child_learn/child_quiz_repository.dart';
import 'package:family_os/features/n17_child_learn/child_quiz_screen.dart';

void main() {
  tearDown(AppToast.dismiss);

  testWidgets('empty → CHD-012', (tester) async {
    final nav = <String>[];
    await _pump(
      tester,
      repository: InMemoryChildQuizRepository(seed: childQuizEmptyFixture()),
      onNavigate: nav.add,
    );
    expect(find.byKey(ChildQuizKeys.empty), findsOneWidget);
    await tester.tap(find.text('Back to My learning'));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-CHD-012'));
  });

  testWidgets('wrong then correct →016', (tester) async {
    final nav = <String>[];
    await _pump(
      tester,
      repository: InMemoryChildQuizRepository(
        seed: childQuizPrototypeFixture(),
      ),
      onNavigate: nav.add,
    );
    expect(find.byKey(ChildQuizKeys.body), findsOneWidget);

    await tester.tap(find.byKey(ChildQuizKeys.option('b')));
    await tester.pump();
    expect(find.textContaining('So close'), findsOneWidget);
    AppToast.dismiss();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ChildQuizKeys.option('a')));
    await tester.pump();
    expect(find.textContaining('Brilliant'), findsOneWidget);
    AppToast.dismiss();
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-CHD-016'));
  });

  testWidgets('loading then body', (tester) async {
    final gate = Completer<void>();
    final repo = InMemoryChildQuizRepository(seed: childQuizOneFixture())
      ..loadGate = () => gate.future;
    await _pump(tester, repository: repo, settle: false);
    await tester.pump();
    expect(find.byKey(ChildQuizKeys.loading), findsOneWidget);
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(ChildQuizKeys.body), findsOneWidget);
  });

  testWidgets('parent lean', (tester) async {
    await _pump(tester, role: AppRole.father);
    expect(find.byKey(ChildQuizKeys.parentLean), findsOneWidget);
  });

  testWidgets('SOS', (tester) async {
    var sos = 0;
    await _pump(
      tester,
      repository: InMemoryChildQuizRepository(seed: childQuizOneFixture()),
      onSos: () => sos++,
    );
    await tester.tap(find.byKey(ChildQuizKeys.sosIconCta));
    await tester.pumpAndSettle();
    expect(sos, 1);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  ChildQuizRepository? repository,
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
        home: ChildQuizScreen(
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
