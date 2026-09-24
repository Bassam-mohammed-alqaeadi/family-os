import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n02_day/road_safety_repository.dart';
import 'package:family_os/features/n02_day/road_safety_screen.dart';

void main() {
  testWidgets('empty → FAT-003', (tester) async {
    final nav = <String>[];
    await _pump(
      tester,
      repository: InMemoryRoadSafetyRepository(seed: roadSafetyEmptyFixture()),
      onNavigate: nav.add,
    );
    expect(find.byKey(RoadSafetyKeys.empty), findsOneWidget);
    await tester.tap(find.text('Add a child'));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-003'));
  });

  testWidgets('prototype trip + toggle crash', (tester) async {
    final repo = InMemoryRoadSafetyRepository(
      seed: roadSafetyPrototypeFixture(),
    );
    await _pump(tester, repository: repo);
    expect(find.byKey(RoadSafetyKeys.body), findsOneWidget);
    expect(find.byKey(RoadSafetyKeys.honesty), findsOneWidget);
    expect(find.byKey(RoadSafetyKeys.tripCard), findsOneWidget);
    expect(find.textContaining('Zero'), findsOneWidget);
    final sw = find.byKey(RoadSafetyKeys.crashSwitch);
    expect(tester.widget<Switch>(sw).value, isTrue);
    await tester.tap(sw);
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(sw).value, isFalse);
  });

  testWidgets('mother partner cannot edit (full only)', (tester) async {
    final repo = InMemoryRoadSafetyRepository(
      seed: roadSafetyPrototypeFixture(),
    );
    await _pump(
      tester,
      repository: repo,
      role: AppRole.mother,
      motherLevel: MotherLevel.partner,
    );
    final sw = find.byKey(RoadSafetyKeys.crashSwitch);
    expect(tester.widget<Switch>(sw).onChanged, isNull);
  });

  testWidgets('loading then body', (tester) async {
    final gate = Completer<void>();
    final repo = InMemoryRoadSafetyRepository(seed: roadSafetyOneFixture())
      ..loadGate = () => gate.future;
    await _pump(tester, repository: repo, settle: false);
    await tester.pump();
    expect(find.byKey(RoadSafetyKeys.loading), findsOneWidget);
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(RoadSafetyKeys.body), findsOneWidget);
  });

  testWidgets('child lean + SOS', (tester) async {
    var sos = false;
    await _pump(tester, role: AppRole.child, onSos: () => sos = true);
    expect(find.byKey(RoadSafetyKeys.childLean), findsOneWidget);
    await tester.tap(find.byKey(RoadSafetyKeys.sosIconCta));
    await tester.pumpAndSettle();
    expect(sos, isTrue);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  RoadSafetyRepository? repository,
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
        home: RoadSafetyScreen(
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
