import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n16_tasks/child_tasks_repository.dart';
import 'package:family_os/features/n16_tasks/child_tasks_screen.dart';

void main() {
  tearDown(AppToast.dismiss);

  testWidgets('empty → CHD-004', (tester) async {
    final nav = <String>[];
    await _pump(
      tester,
      repository: InMemoryChildTasksRepository(seed: childTasksEmptyFixture()),
      onNavigate: nav.add,
    );
    expect(find.byKey(ChildTasksKeys.empty), findsOneWidget);
    await tester.tap(find.text('Back to my day'));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-CHD-004'));
  });

  testWidgets('submit proof toast', (tester) async {
    await _pump(
      tester,
      repository: InMemoryChildTasksRepository(seed: childTasksOneFixture()),
    );
    expect(find.byKey(ChildTasksKeys.body), findsOneWidget);
    expect(find.textContaining('minutes'), findsWidgets);

    await tester.ensureVisible(find.byKey(ChildTasksKeys.submit('t1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ChildTasksKeys.submit('t1')));
    await tester.pump();
    expect(find.textContaining('Proof sent'), findsOneWidget);
    AppToast.dismiss();
    await tester.pumpAndSettle();
    expect(find.textContaining('Awaiting'), findsOneWidget);
  });

  testWidgets('loading then body', (tester) async {
    final gate = Completer<void>();
    final repo = InMemoryChildTasksRepository(seed: childTasksOneFixture())
      ..loadGate = () => gate.future;
    await _pump(tester, repository: repo, settle: false);
    await tester.pump();
    expect(find.byKey(ChildTasksKeys.loading), findsOneWidget);
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(ChildTasksKeys.body), findsOneWidget);
  });

  testWidgets('parent lean', (tester) async {
    await _pump(tester, role: AppRole.father);
    expect(find.byKey(ChildTasksKeys.parentLean), findsOneWidget);
  });

  testWidgets('SOS', (tester) async {
    var sos = 0;
    await _pump(
      tester,
      repository: InMemoryChildTasksRepository(seed: childTasksOneFixture()),
      onSos: () => sos++,
    );
    await tester.tap(find.byKey(ChildTasksKeys.sosIconCta));
    await tester.pumpAndSettle();
    expect(sos, 1);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  ChildTasksRepository? repository,
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
        home: ChildTasksScreen(
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
