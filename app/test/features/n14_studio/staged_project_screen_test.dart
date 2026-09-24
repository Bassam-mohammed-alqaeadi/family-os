import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n14_studio/staged_project_repository.dart';
import 'package:family_os/features/n14_studio/staged_project_screen.dart';

void main() {
  tearDown(AppToast.dismiss);

  testWidgets('empty → FAT-003', (tester) async {
    final nav = <String>[];
    await _pump(
      tester,
      repository: InMemoryStagedProjectRepository(
        seed: stagedProjectEmptyFixture(),
      ),
      onNavigate: nav.add,
    );
    expect(find.byKey(StagedProjectKeys.empty), findsOneWidget);
    await tester.tap(find.text('Add a child'));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-003'));
  });

  testWidgets('confirm stage + template', (tester) async {
    final repo = InMemoryStagedProjectRepository(
      seed: stagedProjectPrototypeFixture(),
    );
    await _pump(tester, repository: repo);
    expect(find.byKey(StagedProjectKeys.hero), findsOneWidget);
    await tester.tap(find.byKey(StagedProjectKeys.confirmCta));
    await tester.pump();
    expect(find.text('Stage approved! +40 min deposited'), findsOneWidget);
    expect(repo.confirmed, isTrue);
    AppToast.dismiss();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(StagedProjectKeys.templateCta));
    await tester.pump();
    expect(find.textContaining('Templates'), findsOneWidget);
    AppToast.dismiss();
    await tester.pumpAndSettle();
  });

  testWidgets('loading then body', (tester) async {
    final gate = Completer<void>();
    final repo = InMemoryStagedProjectRepository(
      seed: stagedProjectOneFixture(),
    )..loadGate = () => gate.future;
    await _pump(tester, repository: repo, settle: false);
    await tester.pump();
    expect(find.byKey(StagedProjectKeys.loading), findsOneWidget);
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(StagedProjectKeys.body), findsOneWidget);
  });

  testWidgets('child lean + SOS', (tester) async {
    var sos = false;
    await _pump(tester, role: AppRole.child, onSos: () => sos = true);
    expect(find.byKey(StagedProjectKeys.childLean), findsOneWidget);
    await tester.tap(find.byKey(StagedProjectKeys.sosIconCta));
    await tester.pumpAndSettle();
    expect(sos, isTrue);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  StagedProjectRepository? repository,
  AppRole role = AppRole.father,
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
        home: StagedProjectScreen(
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
