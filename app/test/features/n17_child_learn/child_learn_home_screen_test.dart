import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n17_child_learn/child_learn_home_repository.dart';
import 'package:family_os/features/n17_child_learn/child_learn_home_screen.dart';

void main() {
  tearDown(AppToast.dismiss);

  testWidgets('empty → SOS CTA', (tester) async {
    var sos = 0;
    final repo = InMemoryChildLearnHomeRepository(
      seed: childLearnHomeEmptyFixture(),
    );
    await _pump(tester, repository: repo, onSos: () => sos++);

    expect(find.byKey(ChildLearnHomeKeys.empty), findsOneWidget);
    expect(find.byKey(ChildLearnHomeKeys.body), findsNothing);
    await tester.tap(find.text('SOS'));
    await tester.pumpAndSettle();
    expect(sos, 1);
  });

  testWidgets('one material loads body', (tester) async {
    final repo = InMemoryChildLearnHomeRepository(
      seed: childLearnHomeOneFixture(),
    );
    await _pump(tester, repository: repo);

    expect(find.byKey(ChildLearnHomeKeys.body), findsOneWidget);
    expect(find.byKey(ChildLearnHomeKeys.levelCard), findsOneWidget);
    expect(
      find.byKey(ChildLearnHomeKeys.materialRow('mat-math')),
      findsOneWidget,
    );
  });

  testWidgets('prototype challenge→015 math→013 qact→014/017/018', (
    tester,
  ) async {
    final nav = <String>[];
    final repo = InMemoryChildLearnHomeRepository(
      seed: childLearnHomePrototypeFixture(),
    );
    await _pump(tester, repository: repo, onNavigate: nav.add);

    expect(find.byKey(ChildLearnHomeKeys.challengeCard), findsOneWidget);
    expect(find.textContaining('Fractions quiz'), findsOneWidget);

    await tester.tap(find.byKey(ChildLearnHomeKeys.challengeCta));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-CHD-015'));

    await tester.tap(find.byKey(ChildLearnHomeKeys.materialRow('mat-math')));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-CHD-013'));

    await tester.ensureVisible(
      find.byKey(ChildLearnHomeKeys.quickAction('homework')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ChildLearnHomeKeys.quickAction('homework')));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-CHD-014'));

    await tester.tap(find.byKey(ChildLearnHomeKeys.quickAction('tutor')));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-CHD-017'));

    await tester.tap(find.byKey(ChildLearnHomeKeys.quickAction('focus')));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-CHD-018'));
  });

  testWidgets('loading then body', (tester) async {
    final gate = Completer<void>();
    final repo = InMemoryChildLearnHomeRepository(
      seed: childLearnHomeOneFixture(),
    )..loadGate = () => gate.future;

    await _pump(tester, repository: repo, settle: false);
    await tester.pump();
    expect(find.byKey(ChildLearnHomeKeys.loading), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(ChildLearnHomeKeys.body), findsOneWidget);
  });

  testWidgets('parent lean', (tester) async {
    await _pump(tester, role: AppRole.father);
    expect(find.byKey(ChildLearnHomeKeys.parentLean), findsOneWidget);
    expect(find.byKey(ChildLearnHomeKeys.body), findsNothing);
  });

  testWidgets('child SOS icon', (tester) async {
    var sos = 0;
    await _pump(
      tester,
      repository: InMemoryChildLearnHomeRepository(
        seed: childLearnHomeOneFixture(),
      ),
      onSos: () => sos++,
    );
    await tester.tap(find.byKey(ChildLearnHomeKeys.sosIconCta));
    await tester.pumpAndSettle();
    expect(sos, 1);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  ChildLearnHomeRepository? repository,
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
        home: ChildLearnHomeScreen(
          repository: repository,
          roleOverride: role,
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
