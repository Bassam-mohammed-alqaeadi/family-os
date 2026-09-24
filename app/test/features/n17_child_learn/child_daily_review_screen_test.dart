import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n17_child_learn/child_daily_review_repository.dart';
import 'package:family_os/features/n17_child_learn/child_daily_review_screen.dart';

void main() {
  tearDown(AppToast.dismiss);

  testWidgets('empty → CHD-012', (tester) async {
    final nav = <String>[];
    await _pump(
      tester,
      repository: InMemoryChildDailyReviewRepository(
        seed: childDailyReviewEmptyFixture(),
      ),
      onNavigate: nav.add,
    );
    expect(find.byKey(ChildDailyReviewKeys.empty), findsOneWidget);
    await tester.tap(find.text('My learning'));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-CHD-012'));
  });

  testWidgets('body + cards + done toast', (tester) async {
    await _pump(
      tester,
      repository: InMemoryChildDailyReviewRepository(
        seed: childDailyReviewPrototypeFixture(),
      ),
    );
    expect(find.byKey(ChildDailyReviewKeys.body), findsOneWidget);
    expect(find.byKey(ChildDailyReviewKeys.cards), findsOneWidget);

    await tester.tap(find.byKey(ChildDailyReviewKeys.startCta));
    await tester.pump();
    expect(find.textContaining('muscle'), findsOneWidget);
    expect(find.textContaining('+10 min'), findsOneWidget);
    AppToast.dismiss();
  });

  testWidgets('loading then body', (tester) async {
    final gate = Completer<void>();
    final repo = InMemoryChildDailyReviewRepository(
      seed: childDailyReviewOneFixture(),
    )..loadGate = () => gate.future;
    await _pump(tester, repository: repo, settle: false);
    await tester.pump();
    expect(find.byKey(ChildDailyReviewKeys.loading), findsOneWidget);
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(ChildDailyReviewKeys.body), findsOneWidget);
  });

  testWidgets('parent lean', (tester) async {
    await _pump(tester, role: AppRole.father);
    expect(find.byKey(ChildDailyReviewKeys.parentLean), findsOneWidget);
  });

  testWidgets('SOS', (tester) async {
    var sos = 0;
    await _pump(
      tester,
      repository: InMemoryChildDailyReviewRepository(
        seed: childDailyReviewOneFixture(),
      ),
      onSos: () => sos++,
    );
    await tester.tap(find.byKey(ChildDailyReviewKeys.sosIconCta));
    await tester.pumpAndSettle();
    expect(sos, 1);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  ChildDailyReviewRepository? repository,
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
        home: ChildDailyReviewScreen(
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
