import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n05_lock/child_mode_lock_service.dart';
import 'package:family_os/features/n05_lock/parent_second_key_screen.dart';

void main() {
  tearDown(() {
    AppToast.dismiss();
    stage1ChildModeLockService.resetForTests();
  });

  testWidgets('empty inbox when no pending unlock request', (tester) async {
    final lock = ChildModeLockService();
    await _pump(tester, lockService: lock);

    expect(find.byKey(ParentSecondKeyKeys.emptyInbox), findsOneWidget);
    expect(find.byKey(ParentSecondKeyKeys.pendingCard), findsNothing);
    expect(find.byKey(ParentSecondKeyKeys.attemptsEmpty), findsOneWidget);
    expect(find.byKey(ParentSecondKeyKeys.sosCta), findsOneWidget);
  });

  testWidgets('father allow grants 10-minute window and clears inbox',
      (tester) async {
    final lock = ChildModeLockService();
    _seedAwaiting(lock);
    await _pump(tester, lockService: lock);

    final id = lock.pendingRequest!.id;
    expect(find.byKey(ParentSecondKeyKeys.pendingCard), findsOneWidget);
    expect(find.byKey(ParentSecondKeyKeys.emptyInbox), findsNothing);

    await tester.tap(find.byKey(ParentSecondKeyKeys.approve(id)));
    await tester.pump();
    AppToast.dismiss();
    await tester.pumpAndSettle();

    expect(lock.pendingRequest?.isApproved, isTrue);
    expect(lock.awaitingSecondKeyRequests, isEmpty);
    expect(find.byKey(ParentSecondKeyKeys.emptyInbox), findsOneWidget);
    expect(
      lock.audit.entries.any((e) => e.contains('second_key:approved')),
      isTrue,
    );
  });

  testWidgets('father deny clears pending and keeps device locked',
      (tester) async {
    final lock = ChildModeLockService();
    _seedAwaiting(lock);
    await _pump(tester, lockService: lock);

    final id = lock.pendingRequest!.id;
    await tester.tap(find.byKey(ParentSecondKeyKeys.deny(id)));
    await tester.pump();
    AppToast.dismiss();
    await tester.pumpAndSettle();

    expect(lock.pendingRequest, isNull);
    expect(lock.awaitingSecondKeyRequests, isEmpty);
    expect(find.byKey(ParentSecondKeyKeys.emptyInbox), findsOneWidget);
    expect(
      lock.audit.entries.any((e) => e.contains('second_key:rejected')),
      isTrue,
    );
  });

  testWidgets('failed attempts appear in father attempt log', (tester) async {
    final lock = ChildModeLockService();
    lock.openSecretEntry();
    lock.verifyAccountPassword('wrong-1');
    lock.verifyAccountPassword('wrong-2');
    await _pump(tester, lockService: lock);

    expect(find.byKey(ParentSecondKeyKeys.attemptsLog), findsOneWidget);
    expect(find.byKey(ParentSecondKeyKeys.attemptRow(0)), findsOneWidget);
    expect(find.byKey(ParentSecondKeyKeys.attemptRow(1)), findsOneWidget);
  });

  testWidgets('mother sees pending but cannot decide (father holds key)',
      (tester) async {
    final lock = ChildModeLockService();
    _seedAwaiting(lock);
    await _pump(tester, lockService: lock, role: AppRole.mother);

    expect(find.byKey(ParentSecondKeyKeys.pendingCard), findsOneWidget);
    expect(find.byKey(ParentSecondKeyKeys.motherHint), findsOneWidget);
    expect(
      find.byKey(ParentSecondKeyKeys.approve(lock.pendingRequest!.id)),
      findsNothing,
    );
    expect(
      find.byKey(ParentSecondKeyKeys.deny(lock.pendingRequest!.id)),
      findsNothing,
    );
  });

  testWidgets('child RoleGuard lean — no decide controls', (tester) async {
    final lock = ChildModeLockService();
    _seedAwaiting(lock);
    await _pump(tester, lockService: lock, role: AppRole.child);

    expect(find.byKey(ParentSecondKeyKeys.childLean), findsOneWidget);
    expect(find.byKey(ParentSecondKeyKeys.pendingCard), findsNothing);
    expect(find.byKey(ParentSecondKeyKeys.sosIconCta), findsOneWidget);
  });
}

void _seedAwaiting(ChildModeLockService lock) {
  lock.openSecretEntry();
  final result = lock.verifyAccountPassword(kChildModeLockMockPassword);
  expect(result.outcome, ChildModeUnlockOutcome.awaitingSecondKey);
  expect(lock.awaitingSecondKeyRequests, hasLength(1));
}

Future<void> _pump(
  WidgetTester tester, {
  required ChildModeLockService lockService,
  AppRole role = AppRole.father,
}) async {
  final roleCtrl = RoleController(role);
  addTearDown(roleCtrl.dispose);
  await tester.pumpWidget(
    CurrentRole(
      notifier: roleCtrl,
      child: MaterialApp(
        theme: buildFamilyTheme(),
        locale: const Locale('ar'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: ParentSecondKeyScreen(
          lockService: lockService,
          roleOverride: role,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
