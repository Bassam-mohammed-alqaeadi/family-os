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
import 'package:family_os/features/n04_web_filter/home_router_filter_repository.dart';
import 'package:family_os/features/n04_web_filter/home_router_filter_screen.dart';

void main() {
  tearDown(AppToast.dismiss);

  testWidgets('empty → FAT-003', (tester) async {
    final nav = <String>[];
    await _pump(
      tester,
      repository: InMemoryHomeRouterFilterRepository(
        seed: homeRouterFilterEmptyFixture(),
      ),
      onNavigate: nav.add,
    );
    expect(find.byKey(HomeRouterFilterKeys.empty), findsOneWidget);
    await tester.tap(find.text('Add a child'));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-003'));
  });

  testWidgets('prototype guide + check toasts', (tester) async {
    final repo = InMemoryHomeRouterFilterRepository(
      seed: homeRouterFilterPrototypeFixture(),
    );
    await _pump(tester, repository: repo);
    expect(find.byKey(HomeRouterFilterKeys.body), findsOneWidget);
    expect(find.byKey(HomeRouterFilterKeys.hero), findsOneWidget);
    expect(find.textContaining('12'), findsWidgets);

    await tester.tap(find.byKey(HomeRouterFilterKeys.guideCta));
    await tester.pump();
    expect(find.textContaining('step-by-step'), findsOneWidget);
    AppToast.dismiss();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(HomeRouterFilterKeys.checkCta));
    await tester.pump();
    expect(find.textContaining('protected'), findsWidgets);
    expect(repo.checkCount, 1);
    AppToast.dismiss();
    await tester.pumpAndSettle();
  });

  testWidgets('observer mother sees hint; guide disabled', (tester) async {
    await _pump(
      tester,
      repository: InMemoryHomeRouterFilterRepository(
        seed: homeRouterFilterPrototypeFixture(),
      ),
      role: AppRole.mother,
      motherLevel: MotherLevel.observer,
    );
    expect(find.byKey(HomeRouterFilterKeys.observerHint), findsOneWidget);
    expect(find.byKey(HomeRouterFilterKeys.guideCta), findsOneWidget);
  });

  testWidgets('loading then body', (tester) async {
    final gate = Completer<void>();
    final repo = InMemoryHomeRouterFilterRepository(
      seed: homeRouterFilterOneFixture(),
    )..loadGate = () => gate.future;
    await _pump(tester, repository: repo, settle: false);
    await tester.pump();
    expect(find.byKey(HomeRouterFilterKeys.loading), findsOneWidget);
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(HomeRouterFilterKeys.body), findsOneWidget);
  });

  testWidgets('child lean + SOS', (tester) async {
    var sos = false;
    await _pump(tester, role: AppRole.child, onSos: () => sos = true);
    expect(find.byKey(HomeRouterFilterKeys.childLean), findsOneWidget);
    await tester.tap(find.byKey(HomeRouterFilterKeys.sosIconCta));
    await tester.pumpAndSettle();
    expect(sos, isTrue);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  HomeRouterFilterRepository? repository,
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
        home: HomeRouterFilterScreen(
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
