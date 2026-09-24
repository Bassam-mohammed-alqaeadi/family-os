import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n17_child_learn/child_interactive_stories_repository.dart';
import 'package:family_os/features/n17_child_learn/child_interactive_stories_screen.dart';

void main() {
  tearDown(AppToast.dismiss);

  testWidgets('empty → CHD-014', (tester) async {
    final nav = <String>[];
    await _pump(
      tester,
      repository: InMemoryChildInteractiveStoriesRepository(
        seed: childInteractiveStoriesEmptyFixture(),
      ),
      onNavigate: nav.add,
    );
    expect(find.byKey(ChildInteractiveStoriesKeys.empty), findsOneWidget);
    await tester.tap(find.text('My learning'));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-CHD-014'));
  });

  testWidgets('choose honesty path', (tester) async {
    final repo = InMemoryChildInteractiveStoriesRepository(
      seed: childInteractiveStoriesPrototypeFixture(),
    );
    await _pump(tester, repository: repo);
    expect(find.byKey(ChildInteractiveStoriesKeys.chapter), findsOneWidget);
    await tester.tap(find.byKey(ChildInteractiveStoriesKeys.choice('return')));
    await tester.pump();
    expect(find.textContaining('honesty'), findsOneWidget);
    expect(repo.lastChoiceId, 'return');
    AppToast.dismiss();
    await tester.pumpAndSettle();
  });

  testWidgets('loading then body', (tester) async {
    final gate = Completer<void>();
    final repo = InMemoryChildInteractiveStoriesRepository(
      seed: childInteractiveStoriesOneFixture(),
    )..loadGate = () => gate.future;
    await _pump(tester, repository: repo, settle: false);
    await tester.pump();
    expect(find.byKey(ChildInteractiveStoriesKeys.loading), findsOneWidget);
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(ChildInteractiveStoriesKeys.body), findsOneWidget);
  });

  testWidgets('parent lean + SOS', (tester) async {
    var sos = false;
    await _pump(tester, role: AppRole.father, onSos: () => sos = true);
    expect(find.byKey(ChildInteractiveStoriesKeys.parentLean), findsOneWidget);
    await tester.tap(find.byKey(ChildInteractiveStoriesKeys.sosIconCta));
    await tester.pumpAndSettle();
    expect(sos, isTrue);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  ChildInteractiveStoriesRepository? repository,
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
        home: ChildInteractiveStoriesScreen(
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
