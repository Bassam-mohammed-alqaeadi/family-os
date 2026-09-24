import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n17_child_learn/child_result_repository.dart';
import 'package:family_os/features/n17_child_learn/child_result_screen.dart';

void main() {
  tearDown(AppToast.dismiss);

  testWidgets('empty → CHD-012', (tester) async {
    final nav = <String>[];
    await _pump(
      tester,
      repository: InMemoryChildResultRepository(
        seed: childResultEmptyFixture(),
      ),
      onNavigate: nav.add,
    );
    expect(find.byKey(ChildResultKeys.empty), findsOneWidget);
    await tester.tap(find.text('Back to My learning'));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-CHD-012'));
  });

  testWidgets('prototype score + review→013 home→012', (tester) async {
    final nav = <String>[];
    await _pump(
      tester,
      repository: InMemoryChildResultRepository(
        seed: childResultPrototypeFixture(),
      ),
      onNavigate: nav.add,
    );
    expect(find.byKey(ChildResultKeys.body), findsOneWidget);
    expect(find.byKey(ChildResultKeys.score), findsOneWidget);
    expect(find.textContaining('9 of 10'), findsOneWidget);
    expect(find.byKey(ChildResultKeys.missedCard), findsOneWidget);

    await tester.ensureVisible(find.byKey(ChildResultKeys.reviewCta));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ChildResultKeys.reviewCta));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-CHD-013'));

    await tester.tap(find.byKey(ChildResultKeys.homeCta));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-CHD-012'));
  });

  testWidgets('loading then body', (tester) async {
    final gate = Completer<void>();
    final repo = InMemoryChildResultRepository(seed: childResultOneFixture())
      ..loadGate = () => gate.future;
    await _pump(tester, repository: repo, settle: false);
    await tester.pump();
    expect(find.byKey(ChildResultKeys.loading), findsOneWidget);
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(ChildResultKeys.body), findsOneWidget);
  });

  testWidgets('parent lean', (tester) async {
    await _pump(tester, role: AppRole.mother);
    expect(find.byKey(ChildResultKeys.parentLean), findsOneWidget);
  });

  testWidgets('SOS', (tester) async {
    var sos = 0;
    await _pump(
      tester,
      repository: InMemoryChildResultRepository(seed: childResultOneFixture()),
      onSos: () => sos++,
    );
    await tester.tap(find.byKey(ChildResultKeys.sosIconCta));
    await tester.pumpAndSettle();
    expect(sos, 1);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  ChildResultRepository? repository,
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
        home: ChildResultScreen(
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
