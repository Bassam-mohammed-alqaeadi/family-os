import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n17_child_learn/child_flashcards_repository.dart';
import 'package:family_os/features/n17_child_learn/child_flashcards_screen.dart';

void main() {
  tearDown(AppToast.dismiss);

  testWidgets('empty → CHD-012', (tester) async {
    final nav = <String>[];
    final repo = InMemoryChildFlashcardsRepository(
      seed: childFlashcardsEmptyFixture(),
    );
    await _pump(tester, repository: repo, onNavigate: nav.add);
    expect(find.byKey(ChildFlashcardsKeys.empty), findsOneWidget);
    await tester.tap(find.text('Back to My learning'));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-CHD-012'));
  });

  testWidgets('prototype flip + quiz→015', (tester) async {
    final nav = <String>[];
    final repo = InMemoryChildFlashcardsRepository(
      seed: childFlashcardsPrototypeFixture(),
    );
    await _pump(tester, repository: repo, onNavigate: nav.add);

    expect(find.byKey(ChildFlashcardsKeys.body), findsOneWidget);
    expect(find.textContaining('ordinary fraction'), findsOneWidget);

    await tester.tap(find.byKey(ChildFlashcardsKeys.flipCard));
    await tester.pumpAndSettle();
    expect(find.byKey(ChildFlashcardsKeys.knownCta), findsOneWidget);

    await tester.ensureVisible(find.byKey(ChildFlashcardsKeys.quizCta));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ChildFlashcardsKeys.quizCta));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-CHD-015'));
  });

  testWidgets('loading then body', (tester) async {
    final gate = Completer<void>();
    final repo = InMemoryChildFlashcardsRepository(
      seed: childFlashcardsOneFixture(),
    )..loadGate = () => gate.future;
    await _pump(tester, repository: repo, settle: false);
    await tester.pump();
    expect(find.byKey(ChildFlashcardsKeys.loading), findsOneWidget);
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(ChildFlashcardsKeys.body), findsOneWidget);
  });

  testWidgets('parent lean', (tester) async {
    await _pump(tester, role: AppRole.mother);
    expect(find.byKey(ChildFlashcardsKeys.parentLean), findsOneWidget);
  });

  testWidgets('SOS icon', (tester) async {
    var sos = 0;
    await _pump(
      tester,
      repository: InMemoryChildFlashcardsRepository(
        seed: childFlashcardsOneFixture(),
      ),
      onSos: () => sos++,
    );
    await tester.tap(find.byKey(ChildFlashcardsKeys.sosIconCta));
    await tester.pumpAndSettle();
    expect(sos, 1);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  ChildFlashcardsRepository? repository,
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
        home: ChildFlashcardsScreen(
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
