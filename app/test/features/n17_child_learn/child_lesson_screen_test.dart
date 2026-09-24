import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n17_child_learn/child_lesson_repository.dart';
import 'package:family_os/features/n17_child_learn/child_lesson_screen.dart';

void main() {
  tearDown(AppToast.dismiss);

  testWidgets('empty → CHD-012', (tester) async {
    final nav = <String>[];
    final repo = InMemoryChildLessonRepository(seed: childLessonEmptyFixture());
    await _pump(tester, repository: repo, onNavigate: nav.add);
    expect(find.byKey(ChildLessonKeys.empty), findsOneWidget);
    await tester.tap(find.text('Back to My learning'));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-CHD-012'));
  });

  testWidgets('prototype next→014 tutor→017', (tester) async {
    final nav = <String>[];
    final repo = InMemoryChildLessonRepository(
      seed: childLessonPrototypeFixture(),
    );
    await _pump(tester, repository: repo, onNavigate: nav.add);
    expect(find.byKey(ChildLessonKeys.body), findsOneWidget);
    expect(find.byKey(ChildLessonKeys.pizza), findsOneWidget);

    await tester.tap(find.byKey(ChildLessonKeys.nextCta));
    await tester.pump();
    expect(find.textContaining('+10 minutes'), findsOneWidget);
    AppToast.dismiss();
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-CHD-014'));

    await tester.tap(find.byKey(ChildLessonKeys.tutorCta));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-CHD-017'));
  });

  testWidgets('loading then body', (tester) async {
    final gate = Completer<void>();
    final repo = InMemoryChildLessonRepository(seed: childLessonOneFixture())
      ..loadGate = () => gate.future;
    await _pump(tester, repository: repo, settle: false);
    await tester.pump();
    expect(find.byKey(ChildLessonKeys.loading), findsOneWidget);
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(ChildLessonKeys.body), findsOneWidget);
  });

  testWidgets('parent lean', (tester) async {
    await _pump(tester, role: AppRole.father);
    expect(find.byKey(ChildLessonKeys.parentLean), findsOneWidget);
  });

  testWidgets('SOS icon', (tester) async {
    var sos = 0;
    await _pump(
      tester,
      repository: InMemoryChildLessonRepository(seed: childLessonOneFixture()),
      onSos: () => sos++,
    );
    await tester.tap(find.byKey(ChildLessonKeys.sosIconCta));
    await tester.pumpAndSettle();
    expect(sos, 1);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  ChildLessonRepository? repository,
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
        home: ChildLessonScreen(
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
