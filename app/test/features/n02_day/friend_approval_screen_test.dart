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
import 'package:family_os/features/n02_day/friend_approval_repository.dart';
import 'package:family_os/features/n02_day/friend_approval_screen.dart';

void main() {
  tearDown(AppToast.dismiss);

  testWidgets('empty → FAT-070', (tester) async {
    final nav = <String>[];
    final repo = InMemoryFriendApprovalRepository(
      seed: friendApprovalEmptyFixture(),
    );
    await _pump(tester, repository: repo, onNavigate: nav.add);

    expect(find.byKey(FriendApprovalKeys.empty), findsOneWidget);
    await tester.tap(find.text('Back to outer circle'));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-070'));
  });

  testWidgets('approve toast → FAT-070', (tester) async {
    final nav = <String>[];
    final repo = InMemoryFriendApprovalRepository(
      seed: friendApprovalPrototypeFixture(),
    );
    await _pump(tester, repository: repo, onNavigate: nav.add);

    expect(find.byKey(FriendApprovalKeys.body), findsOneWidget);
    await tester.ensureVisible(find.byKey(FriendApprovalKeys.approveCta));
    await tester.tap(find.byKey(FriendApprovalKeys.approveCta));
    await tester.pump();
    expect(find.textContaining('approved as a safe friend'), findsOneWidget);
    AppToast.dismiss();
    await tester.pumpAndSettle();
    expect(repo.lastDecision, 'approved');
    expect(nav, contains('SCR-FAT-070'));
  });

  testWidgets('decline gently → FAT-070', (tester) async {
    final nav = <String>[];
    final repo = InMemoryFriendApprovalRepository(
      seed: friendApprovalPrototypeFixture(),
    );
    await _pump(tester, repository: repo, onNavigate: nav.add);

    await tester.ensureVisible(find.byKey(FriendApprovalKeys.declineCta));
    await tester.tap(find.byKey(FriendApprovalKeys.declineCta));
    await tester.pump();
    expect(find.textContaining('Gentle reply'), findsOneWidget);
    AppToast.dismiss();
    await tester.pumpAndSettle();
    expect(repo.lastDecision, 'declined');
    expect(nav, contains('SCR-FAT-070'));
  });

  testWidgets('mother observer view-only', (tester) async {
    final repo = InMemoryFriendApprovalRepository(
      seed: friendApprovalPrototypeFixture(),
    );
    await _pump(
      tester,
      repository: repo,
      role: AppRole.mother,
      motherLevel: MotherLevel.observer,
    );

    expect(find.byKey(FriendApprovalKeys.observerHint), findsOneWidget);
    expect(find.byKey(FriendApprovalKeys.approveCta), findsNothing);
  });

  testWidgets('loading then body', (tester) async {
    final gate = Completer<void>();
    final repo = InMemoryFriendApprovalRepository(
      seed: friendApprovalOneFixture(),
    )..loadGate = () => gate.future;

    await _pump(tester, repository: repo, settle: false);
    await tester.pump();
    expect(find.byKey(FriendApprovalKeys.loading), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(FriendApprovalKeys.body), findsOneWidget);
  });

  testWidgets('child RoleGuard lean + SOS', (tester) async {
    var sos = false;
    await _pump(tester, role: AppRole.child, onSos: () => sos = true);

    expect(find.byKey(FriendApprovalKeys.childLean), findsOneWidget);
    await tester.tap(find.byKey(FriendApprovalKeys.sosIconCta));
    await tester.pumpAndSettle();
    expect(sos, isTrue);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  FriendApprovalRepository? repository,
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
        home: FriendApprovalScreen(
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
