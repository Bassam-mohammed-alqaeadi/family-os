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
import 'package:family_os/features/n07_advisor/mother_ai_feed_repository.dart';
import 'package:family_os/features/n07_advisor/mother_ai_feed_screen.dart';

void main() {
  tearDown(AppToast.dismiss);

  testWidgets('empty → FAT-003', (tester) async {
    final nav = <String>[];
    await _pump(
      tester,
      repository: InMemoryMotherAiFeedRepository(
        seed: motherAiFeedEmptyFixture(),
      ),
      onNavigate: nav.add,
    );
    expect(find.byKey(MotherAiFeedKeys.empty), findsOneWidget);
    await tester.tap(find.text('Add a child'));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-003'));
  });

  testWidgets('whisper send + father watch banner', (tester) async {
    final repo = InMemoryMotherAiFeedRepository(
      seed: motherAiFeedPrototypeFixture(),
    );
    await _pump(tester, repository: repo);
    expect(find.byKey(MotherAiFeedKeys.fatherWatch), findsOneWidget);
    expect(find.byKey(MotherAiFeedKeys.item('i1')), findsOneWidget);
    await tester.ensureVisible(find.byKey(MotherAiFeedKeys.whisperCta));
    await tester.tap(find.byKey(MotherAiFeedKeys.whisperCta));
    await tester.pump();
    expect(find.textContaining('Whisper and tip sent'), findsOneWidget);
    AppToast.dismiss();
    await tester.pumpAndSettle();
    expect(find.byKey(MotherAiFeedKeys.whisperSent), findsOneWidget);
  });

  testWidgets('mother observer blocked whisper', (tester) async {
    await _pump(
      tester,
      repository: InMemoryMotherAiFeedRepository(
        seed: motherAiFeedPrototypeFixture(),
      ),
      role: AppRole.mother,
      motherLevel: MotherLevel.observer,
    );
    expect(find.byKey(MotherAiFeedKeys.observerHint), findsOneWidget);
    expect(find.byKey(MotherAiFeedKeys.fatherWatch), findsNothing);
  });

  testWidgets('loading then body', (tester) async {
    final gate = Completer<void>();
    final repo = InMemoryMotherAiFeedRepository(seed: motherAiFeedOneFixture())
      ..loadGate = () => gate.future;
    await _pump(tester, repository: repo, settle: false);
    await tester.pump();
    expect(find.byKey(MotherAiFeedKeys.loading), findsOneWidget);
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(MotherAiFeedKeys.body), findsOneWidget);
  });

  testWidgets('child lean + SOS', (tester) async {
    var sos = false;
    await _pump(tester, role: AppRole.child, onSos: () => sos = true);
    expect(find.byKey(MotherAiFeedKeys.childLean), findsOneWidget);
    await tester.tap(find.byKey(MotherAiFeedKeys.sosIconCta));
    await tester.pumpAndSettle();
    expect(sos, isTrue);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  MotherAiFeedRepository? repository,
  AppRole role = AppRole.father,
  MotherLevel motherLevel = MotherLevel.partner,
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
        home: MotherAiFeedScreen(
          repository: repository,
          roleOverride: role,
          motherLevel: motherLevel,
          onSos: onSos,
          onNavigate: onNavigate,
        ),
      ),
    ),
  );
  if (settle) await tester.pumpAndSettle();
}
