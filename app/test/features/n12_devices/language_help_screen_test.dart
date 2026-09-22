import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n12_devices/language_help_repository.dart';
import 'package:family_os/features/n12_devices/language_help_screen.dart';

void main() {
  tearDown(AppToast.dismiss);

  testWidgets('empty → FAT-003', (tester) async {
    final nav = <String>[];
    final repo = InMemoryLanguageHelpRepository(
      seed: languageHelpEmptyFixture(),
    );
    await _pump(tester, repository: repo, onNavigate: nav.add);

    expect(find.byKey(LanguageHelpKeys.empty), findsOneWidget);
    expect(find.byKey(LanguageHelpKeys.body), findsNothing);

    await tester.tap(find.text('Add a child'));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-003'));
  });

  testWidgets('one help link loads body + language card', (tester) async {
    final repo = InMemoryLanguageHelpRepository(
      seed: languageHelpOneFixture(),
    );
    await _pump(tester, repository: repo);

    expect(find.byKey(LanguageHelpKeys.body), findsOneWidget);
    expect(find.byKey(LanguageHelpKeys.languageCard), findsOneWidget);
    expect(find.byKey(LanguageHelpKeys.helpRow('help-device')), findsOneWidget);
    expect(find.byKey(LanguageHelpKeys.empty), findsNothing);
    expect(find.text('Current'), findsOneWidget);
  });

  testWidgets('prototype · help links → FAT-026 / FAT-030; English toast', (
    tester,
  ) async {
    final nav = <String>[];
    final repo = InMemoryLanguageHelpRepository(
      seed: languageHelpPrototypeFixture(),
    );
    await _pump(tester, repository: repo, onNavigate: nav.add);

    expect(find.byKey(LanguageHelpKeys.helpRow('help-device')), findsOneWidget);
    expect(
      find.byKey(LanguageHelpKeys.helpRow('help-parent-mode')),
      findsOneWidget,
    );
    expect(find.textContaining('disconnecting'), findsOneWidget);

    await tester.tap(find.byKey(LanguageHelpKeys.helpRow('help-device')));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-026'));

    nav.clear();
    await tester.tap(find.byKey(LanguageHelpKeys.helpRow('help-parent-mode')));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-030'));

    await tester.tap(find.byKey(LanguageHelpKeys.englishRow));
    await tester.pump();
    expect(find.textContaining('English interface'), findsOneWidget);
    AppToast.dismiss();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(LanguageHelpKeys.supportCta));
    await tester.pump();
    expect(find.textContaining('Arabic support chat'), findsOneWidget);
    AppToast.dismiss();
    await tester.pumpAndSettle();
  });

  testWidgets('loading then body', (tester) async {
    final gate = Completer<void>();
    final repo = InMemoryLanguageHelpRepository(
      seed: languageHelpOneFixture(),
    )..loadGate = () => gate.future;

    await _pump(tester, repository: repo, settle: false);
    await tester.pump();
    expect(find.byKey(LanguageHelpKeys.loading), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(LanguageHelpKeys.body), findsOneWidget);
  });

  testWidgets('mother observer view-only — English + support blocked', (
    tester,
  ) async {
    final nav = <String>[];
    final repo = InMemoryLanguageHelpRepository(
      seed: languageHelpPrototypeFixture(),
    );
    await _pump(
      tester,
      repository: repo,
      role: AppRole.mother,
      motherLevel: MotherLevel.observer,
      onNavigate: nav.add,
    );

    expect(find.byKey(LanguageHelpKeys.observerHint), findsOneWidget);

    await tester.tap(find.byKey(LanguageHelpKeys.englishRow));
    await tester.pump();
    AppToast.dismiss();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(LanguageHelpKeys.supportCta));
    await tester.pump();
    AppToast.dismiss();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(LanguageHelpKeys.helpRow('help-device')));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-026'));
  });

  testWidgets('mother partner may switch English toast', (tester) async {
    final repo = InMemoryLanguageHelpRepository(
      seed: languageHelpPrototypeFixture(),
    );
    await _pump(
      tester,
      repository: repo,
      role: AppRole.mother,
      motherLevel: MotherLevel.partner,
    );

    expect(find.byKey(LanguageHelpKeys.observerHint), findsNothing);

    await tester.tap(find.byKey(LanguageHelpKeys.englishRow));
    await tester.pump();
    expect(find.textContaining('English interface'), findsOneWidget);
    AppToast.dismiss();
    await tester.pumpAndSettle();
  });

  testWidgets('child lean + SOS', (tester) async {
    var sos = false;
    await _pump(tester, role: AppRole.child, onSos: () => sos = true);

    expect(find.byKey(LanguageHelpKeys.childLean), findsOneWidget);
    expect(find.byKey(LanguageHelpKeys.body), findsNothing);
    expect(find.byKey(LanguageHelpKeys.sosIconCta), findsOneWidget);

    await tester.tap(find.byKey(LanguageHelpKeys.sosIconCta));
    await tester.pumpAndSettle();
    expect(sos, isTrue);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  LanguageHelpRepository? repository,
  AppRole role = AppRole.father,
  MotherLevel motherLevel = MotherLevel.partner,
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
        home: LanguageHelpScreen(
          repository: repository,
          roleOverride: role,
          motherLevel: motherLevel,
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
