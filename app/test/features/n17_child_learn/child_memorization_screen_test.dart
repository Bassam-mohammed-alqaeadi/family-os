import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n17_child_learn/child_memorization_repository.dart';
import 'package:family_os/features/n17_child_learn/child_memorization_screen.dart';

void main() {
  tearDown(AppToast.dismiss);

  testWidgets('empty → CHD-025', (tester) async {
    final nav = <String>[];
    await _pump(
      tester,
      repository: InMemoryChildMemorizationRepository(
        seed: childMemorizationEmptyFixture(),
      ),
      onNavigate: nav.add,
    );
    expect(find.byKey(ChildMemorizationKeys.empty), findsOneWidget);
    await tester.tap(find.text('My Quran ward'));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-CHD-025'));
  });

  testWidgets('body + hero + review toast', (tester) async {
    await _pump(
      tester,
      repository: InMemoryChildMemorizationRepository(
        seed: childMemorizationPrototypeFixture(),
      ),
    );
    expect(find.byKey(ChildMemorizationKeys.body), findsOneWidget);
    expect(find.byKey(ChildMemorizationKeys.hero), findsOneWidget);
    expect(find.byKey(ChildMemorizationKeys.reviews), findsOneWidget);

    await tester.tap(find.byKey(ChildMemorizationKeys.reviewCta('r1')));
    await tester.pump();
    expect(find.textContaining('Recite'), findsOneWidget);
    AppToast.dismiss();
  });

  testWidgets('loading then body', (tester) async {
    final gate = Completer<void>();
    final repo = InMemoryChildMemorizationRepository(
      seed: childMemorizationOneFixture(),
    )..loadGate = () => gate.future;
    await _pump(tester, repository: repo, settle: false);
    await tester.pump();
    expect(find.byKey(ChildMemorizationKeys.loading), findsOneWidget);
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(ChildMemorizationKeys.body), findsOneWidget);
  });

  testWidgets('parent lean', (tester) async {
    await _pump(tester, role: AppRole.father);
    expect(find.byKey(ChildMemorizationKeys.parentLean), findsOneWidget);
  });

  testWidgets('SOS', (tester) async {
    var sos = 0;
    await _pump(
      tester,
      repository: InMemoryChildMemorizationRepository(
        seed: childMemorizationOneFixture(),
      ),
      onSos: () => sos++,
    );
    await tester.tap(find.byKey(ChildMemorizationKeys.sosIconCta));
    await tester.pumpAndSettle();
    expect(sos, 1);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  ChildMemorizationRepository? repository,
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
        home: ChildMemorizationScreen(
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
