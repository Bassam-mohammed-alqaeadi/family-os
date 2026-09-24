import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/identity/adult_invite_repository.dart';
import 'package:family_os/core/identity/identity_models.dart';
import 'package:family_os/core/identity/identity_runtime.dart';
import 'package:family_os/core/identity/identity_scope.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/sys3_identity/sys3_identity_screens.dart';

void main() {
  final accountId = AccountId('acc_owner');
  final motherAccountId = AccountId('acc_mother');
  final famA = FamilyId('fam_a');
  final famB = FamilyId('fam_b');
  final ownerMember = MemberId('mem_owner');
  final motherMember = MemberId('mem_mother');
  final ownerSession = SessionId('sess_owner');

  IdentityRuntime primaryRuntime({
    List<Family>? families,
    List<FamilyMembership>? memberships,
    List<Session>? sessions,
    List<Enrollment> enrollments = const [],
    FamilyId? activeFamilyId,
  }) {
    return IdentityRuntime(
      account: Account(id: accountId),
      session: Session(
        id: ownerSession,
        accountId: accountId,
        startedAt: DateTime.utc(2026, 1, 1),
        expiresAt: DateTime.utc(2026, 1, 2),
      ),
      sessions: sessions,
      families:
          families ??
          [
            Family(id: famA, name: 'Family A', ownerMemberId: ownerMember),
            Family(id: famB, name: 'Family B', ownerMemberId: ownerMember),
          ],
      memberships:
          memberships ??
          [
            FamilyMembership(
              id: ownerMember,
              accountId: accountId,
              familyId: famA,
              role: AppRole.father,
              tier: MembershipTier.primary,
              isPrimaryOwner: true,
            ),
            FamilyMembership(
              id: MemberId('mem_owner_b'),
              accountId: accountId,
              familyId: famB,
              role: AppRole.father,
              tier: MembershipTier.primary,
              isPrimaryOwner: true,
            ),
            FamilyMembership(
              id: motherMember,
              accountId: motherAccountId,
              familyId: famA,
              role: AppRole.mother,
              tier: MembershipTier.coParent,
              motherLevel: MotherLevel.partner,
            ),
          ],
      activeFamilyId: activeFamilyId ?? famA,
      activeChildScope: ChildScope(familyId: famA, childId: ChildId('child_a')),
      children: [
        ChildIdentity(id: ChildId('child_a'), familyId: famA),
        ChildIdentity(id: ChildId('child_b'), familyId: famB),
      ],
      accounts: [
        Account(id: accountId),
        Account(id: motherAccountId),
      ],
      enrollments: enrollments,
      nowProvider: () => DateTime.utc(2026, 1, 3),
    );
  }

  IdentityRuntime coParentRuntime() {
    return IdentityRuntime(
      account: Account(id: motherAccountId),
      session: Session(
        id: SessionId('sess_mother'),
        accountId: motherAccountId,
        startedAt: DateTime.utc(2026, 1, 1),
      ),
      families: [
        Family(id: famA, name: 'Family A', ownerMemberId: ownerMember),
      ],
      memberships: [
        FamilyMembership(
          id: ownerMember,
          accountId: accountId,
          familyId: famA,
          role: AppRole.father,
          tier: MembershipTier.primary,
          isPrimaryOwner: true,
        ),
        FamilyMembership(
          id: motherMember,
          accountId: motherAccountId,
          familyId: famA,
          role: AppRole.mother,
          tier: MembershipTier.coParent,
          motherLevel: MotherLevel.full,
        ),
      ],
      activeFamilyId: famA,
      activeChildScope: ChildScope(familyId: famA, childId: ChildId('child_a')),
      children: [ChildIdentity(id: ChildId('child_a'), familyId: famA)],
      accounts: [
        Account(id: accountId),
        Account(id: motherAccountId),
      ],
    );
  }

  testWidgets('Phase B: session restore succeeds for expired session', (
    tester,
  ) async {
    final runtime = primaryRuntime();
    expect(runtime.activeSession.isExpiredAt(DateTime.utc(2026, 1, 3)), isTrue);

    await tester.pumpWidget(
      _app(runtime: runtime, child: const SessionRestoreScreen()),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(Sys3Keys.sessionRestore), findsOneWidget);
    expect(find.byKey(Sys3Keys.mockBanner), findsOneWidget);

    await tester.tap(find.byKey(const Key('sys3_restore_action')));
    await tester.pumpAndSettle();

    expect(find.byKey(Sys3Keys.success), findsOneWidget);
    expect(
      runtime.activeSession.isExpiredAt(DateTime.utc(2026, 1, 3)),
      isFalse,
    );
  });

  testWidgets('Phase B: session expired offers restore and sign-in again', (
    tester,
  ) async {
    final runtime = primaryRuntime();
    await tester.pumpWidget(
      _routerApp(
        runtime: runtime,
        routes: [
          GoRoute(path: '/', builder: (_, __) => const SessionExpiredScreen()),
          GoRoute(
            path: '/sys3-session-restore',
            builder: (_, __) => const SessionRestoreScreen(),
          ),
          GoRoute(
            path: '/scr-shr-003',
            builder: (_, __) => const Scaffold(body: Text('login')),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(Sys3Keys.sessionExpired), findsOneWidget);

    await tester.tap(find.byKey(const Key('sys3_expired_restore')));
    await tester.pumpAndSettle();
    expect(find.byKey(Sys3Keys.sessionRestore), findsOneWidget);
  });

  testWidgets('Phase B: logout confirmation ends current session', (
    tester,
  ) async {
    final runtime = primaryRuntime(
      sessions: [
        Session(
          id: ownerSession,
          accountId: accountId,
          startedAt: DateTime.utc(2026, 1, 1),
        ),
        Session(
          id: SessionId('sess_other'),
          accountId: accountId,
          startedAt: DateTime.utc(2026, 1, 1, 1),
        ),
      ],
    );
    await tester.pumpWidget(
      _app(runtime: runtime, child: const LogoutConfirmScreen()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sys3_logout_action')));
    await tester.pumpAndSettle();
    expect(find.byKey(Sys3Keys.success), findsOneWidget);
    expect(
      runtime.sessions.firstWhere((s) => s.id == ownerSession).endedAt,
      isNotNull,
    );
  });

  testWidgets(
    'Phase B: account recovery records local success without email claim',
    (tester) async {
      final runtime = primaryRuntime();
      await tester.pumpWidget(
        _app(runtime: runtime, child: const AccountRecoveryScreen()),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('sys3_recovery_email')),
        'a@b.co',
      );
      await tester.tap(find.byKey(const Key('sys3_recovery_action')));
      await tester.pumpAndSettle();
      expect(find.byKey(Sys3Keys.success), findsOneWidget);
      expect(find.byKey(Sys3Keys.mockBanner), findsOneWidget);
    },
  );

  testWidgets('Phase B: account deactivation revokes account sessions', (
    tester,
  ) async {
    final runtime = primaryRuntime();
    await tester.pumpWidget(
      _app(runtime: runtime, child: const AccountDeactivateScreen()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sys3_deactivate_action')));
    await tester.pumpAndSettle();
    expect(find.byKey(Sys3Keys.success), findsOneWidget);
    expect(runtime.account.deactivatedAt, isNotNull);
    expect(runtime.activeSession.isRevoked, isTrue);
  });

  testWidgets(
    'Phase B: family selector lists memberships when multiple exist',
    (tester) async {
      final runtime = primaryRuntime();
      FamilyId? selected;
      await tester.pumpWidget(
        _app(
          runtime: runtime,
          child: FamilySelectorScreen(onSelected: (id) => selected = id),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(Sys3Keys.family('fam_a')), findsOneWidget);
      expect(find.byKey(Sys3Keys.family('fam_b')), findsOneWidget);
      await tester.tap(find.byKey(Sys3Keys.family('fam_b')));
      await tester.pumpAndSettle();
      expect(selected, famB);
      expect(runtime.activeFamilyId, famB);
    },
  );

  testWidgets('Phase B: family selector auto-opens single membership', (
    tester,
  ) async {
    final runtime = primaryRuntime(
      families: [
        Family(id: famA, name: 'Family A', ownerMemberId: ownerMember),
      ],
      memberships: [
        FamilyMembership(
          id: ownerMember,
          accountId: accountId,
          familyId: famA,
          role: AppRole.father,
          isPrimaryOwner: true,
        ),
      ],
    );
    var selectedCount = 0;
    await tester.pumpWidget(
      _app(
        runtime: runtime,
        child: FamilySelectorScreen(onSelected: (_) => selectedCount++),
      ),
    );
    await tester.pumpAndSettle();
    expect(selectedCount, 1);
    expect(runtime.activeFamilyId, famA);
  });

  testWidgets('Phase B: remove adult denied for non-primary', (tester) async {
    final deniedRuntime = coParentRuntime();
    await tester.pumpWidget(
      _app(
        runtime: deniedRuntime,
        child: RemoveAdultScreen(memberId: motherMember.value),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(Sys3Keys.denied), findsOneWidget);
    expect(find.byKey(const Key('sys3_remove_adult_action')), findsNothing);
  });

  testWidgets('Phase B: remove adult confirms removal for primary', (
    tester,
  ) async {
    final runtime = primaryRuntime();
    await tester.pumpWidget(
      _app(
        runtime: runtime,
        child: RemoveAdultScreen(memberId: motherMember.value),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sys3_remove_adult_action')));
    await tester.pumpAndSettle();
    expect(find.byKey(Sys3Keys.success), findsOneWidget);
    expect(
      runtime.adultMembershipsForFamily(famA).any((m) => m.id == motherMember),
      isFalse,
    );
  });

  testWidgets('Phase B: ownership transfer primary→eligible adult success', (
    tester,
  ) async {
    final runtime = primaryRuntime();
    await tester.pumpWidget(
      _app(runtime: runtime, child: const OwnershipTransferScreen()),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(Sys3Keys.ownershipTransfer), findsOneWidget);
    expect(find.byKey(Sys3Keys.member(motherMember.value)), findsOneWidget);
    await tester.tap(find.byKey(const Key('sys3_transfer_action')));
    await tester.pumpAndSettle();
    expect(find.byKey(Sys3Keys.success), findsOneWidget);
    expect(
      runtime
          .adultMembershipsForFamily(famA)
          .singleWhere((m) => m.id == motherMember)
          .isPrimaryOwner,
      isTrue,
    );
    expect(
      runtime
          .adultMembershipsForFamily(famA)
          .singleWhere((m) => m.id == ownerMember)
          .isPrimaryOwner,
      isFalse,
    );
  });

  testWidgets(
    'Phase B: ownership transfer denied for non-primary (MotherLevel full)',
    (tester) async {
      final runtime = coParentRuntime();
      expect(runtime.authorizationContext.motherLevel, MotherLevel.full);
      expect(runtime.authorizationContext.isPrimaryOwner, isFalse);
      await tester.pumpWidget(
        _app(runtime: runtime, child: const OwnershipTransferScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(Sys3Keys.denied), findsOneWidget);
    },
  );

  testWidgets('Phase B: invite status shows lifecycle for token lookup', (
    tester,
  ) async {
    final runtime = primaryRuntime();
    final repo = InMemoryAdultInviteRepository(runtime: runtime);
    final invite = repo.createInvite(
      familyId: famA,
      target: 'mother@example.com',
      level: MotherLevel.partner,
      actorMemberId: ownerMember,
    );
    expect(invite.id.value, isNot(equals(invite.tokenId.value)));

    await tester.pumpWidget(
      _app(
        runtime: runtime,
        child: InviteStatusScreen(
          inviteTokenId: invite.tokenId.value,
          repository: repo,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(Sys3Keys.inviteState(InviteLifecycleState.active)),
      findsOneWidget,
    );

    repo.revokeInvite(inviteId: invite.id, actorMemberId: ownerMember);
    await tester.tap(find.byKey(const Key('sys3_invite_lookup')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(Sys3Keys.inviteState(InviteLifecycleState.revoked)),
      findsOneWidget,
    );
  });

  testWidgets('Phase B: invite status unknown token is honest error', (
    tester,
  ) async {
    final runtime = primaryRuntime();
    final repo = InMemoryAdultInviteRepository(runtime: runtime);
    await tester.pumpWidget(
      _app(
        runtime: runtime,
        child: InviteStatusScreen(
          inviteTokenId: 'tok_missing',
          repository: repo,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(Sys3Keys.error), findsOneWidget);
  });

  testWidgets('Phase B: adult sessions list + revoke confirm', (tester) async {
    final runtime = primaryRuntime(
      sessions: [
        Session(
          id: ownerSession,
          accountId: accountId,
          startedAt: DateTime.utc(2026, 1, 1),
        ),
        Session(
          id: SessionId('sess_tablet'),
          accountId: accountId,
          startedAt: DateTime.utc(2026, 1, 1, 2),
        ),
      ],
    );
    await tester.pumpWidget(
      _routerApp(
        runtime: runtime,
        routes: [
          GoRoute(path: '/', builder: (_, __) => const AdultSessionsScreen()),
          GoRoute(
            path: '/sys3-revoke-confirm',
            builder: (context, state) => RevokeConfirmScreen(
              kind: state.uri.queryParameters['kind'],
              id: state.uri.queryParameters['id'],
            ),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(Sys3Keys.session('sess_tablet')), findsOneWidget);
    await tester.tap(find.byKey(const Key('sys3_revoke_session_sess_tablet')));
    await tester.pumpAndSettle();
    expect(find.byKey(Sys3Keys.revokeConfirm), findsOneWidget);
    await tester.tap(find.byKey(const Key('sys3_revoke_action')));
    await tester.pumpAndSettle();
    expect(find.byKey(Sys3Keys.success), findsOneWidget);
    expect(
      runtime.sessions
          .singleWhere((s) => s.id.value == 'sess_tablet')
          .isRevoked,
      isTrue,
    );
  });

  testWidgets(
    'Phase B: child sessions + primary remote-end dedicated surface',
    (tester) async {
      final enrollmentId = EnrollmentId('enr_child_a');
      final runtime = primaryRuntime(
        enrollments: [
          Enrollment(
            id: enrollmentId,
            deviceId: DeviceId('dev_1'),
            familyId: famA,
            childId: ChildId('child_a'),
            createdAt: DateTime.utc(2026, 1, 1),
            state: EnrollmentState.enrolled,
          ),
        ],
      );
      await tester.pumpWidget(
        _routerApp(
          runtime: runtime,
          routes: [
            GoRoute(path: '/', builder: (_, __) => const ChildSessionsScreen()),
            GoRoute(
              path: '/sys3-remote-end',
              builder: (context, state) => RemoteEndChildSessionScreen(
                enrollmentId: state.uri.queryParameters['enrollmentId'],
                childId: state.uri.queryParameters['childId'],
              ),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(Sys3Keys.enrollment('enr_child_a')), findsOneWidget);
      await tester.tap(find.byKey(Sys3Keys.enrollment('enr_child_a')));
      await tester.pumpAndSettle();
      expect(find.byKey(Sys3Keys.remoteEnd), findsOneWidget);
      await tester.tap(find.byKey(const Key('sys3_remote_end_action')));
      await tester.pumpAndSettle();
      expect(find.byKey(Sys3Keys.success), findsOneWidget);
    },
  );

  testWidgets('Phase B: remote-end denied for non-primary', (tester) async {
    final runtime = coParentRuntime();
    await tester.pumpWidget(
      _app(
        runtime: runtime,
        child: const RemoteEndChildSessionScreen(enrollmentId: 'enr_x'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(Sys3Keys.denied), findsOneWidget);
  });
}

Widget _app({required IdentityRuntime runtime, required Widget child}) {
  return MaterialApp(
    theme: buildFamilyTheme(),
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: CurrentIdentity(runtime: runtime, child: child),
  );
}

Widget _routerApp({
  required IdentityRuntime runtime,
  required List<GoRoute> routes,
}) {
  final router = GoRouter(initialLocation: '/', routes: routes);
  return MaterialApp.router(
    theme: buildFamilyTheme(),
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    routerConfig: router,
    builder: (context, child) => CurrentIdentity(
      runtime: runtime,
      child: child ?? const SizedBox.shrink(),
    ),
  );
}
