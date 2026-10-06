import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/identity/identity_models.dart';
import 'package:family_os/core/identity/identity_runtime.dart';
import 'package:family_os/core/identity/identity_scope.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n02_day/children_list_local_repository.dart';
import 'package:family_os/features/n02_day/children_list_repository.dart';
import 'package:family_os/features/n02_day/day_child_mock.dart';
import 'package:family_os/features/n12_devices/family_members_identity_repository.dart';
import 'package:family_os/features/n12_devices/family_members_remote_repository.dart';
import 'package:family_os/features/n12_devices/family_members_role_labels.dart';
import 'package:family_os/features/n12_devices/family_members_repository.dart';
import 'package:family_os/features/n12_devices/family_members_screen.dart';
import 'package:family_os/foundation_gate/family_membership_api_client.dart';

void main() {
  testWidgets('SCR-FAT-027 empty → AppEmptyState + owner invite CTA', (
    tester,
  ) async {
    var invited = false;
    final repo = InMemoryFamilyMembersRepository();

    await tester.pumpWidget(
      _app(
        child: FamilyMembersScreen(
          repository: repo,
          roleOverride: AppRole.father,
          onInvite: () => invited = true,
          onSos: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(FamilyMembersKeys.empty), findsOneWidget);
    expect(find.byType(AppEmptyState), findsOneWidget);
    expect(find.byKey(FamilyMembersKeys.list), findsNothing);
    expect(find.byKey(FamilyMembersKeys.inviteCta), findsOneWidget);
    expect(find.byKey(FamilyMembersKeys.footer), findsOneWidget);

    await tester.tap(find.byKey(FamilyMembersKeys.inviteCta));
    await tester.pumpAndSettle();
    expect(invited, isTrue);
  });

  testWidgets('SCR-FAT-027 roster · owner/mother/guardian/children + SOS', (
    tester,
  ) async {
    var sos = false;
    String? motherOpened;
    final repo = InMemoryFamilyMembersRepository(
      members: _fullFixture,
    );

    await tester.pumpWidget(
      _app(
        child: FamilyMembersScreen(
          repository: repo,
          roleOverride: AppRole.father,
          onInvite: () {},
          onSos: () => sos = true,
          onOpenMotherLevel: (id) => motherOpened = id,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(FamilyMembersKeys.list), findsOneWidget);
    expect(
      find.byKey(FamilyMembersKeys.memberRow('member_owner')),
      findsOneWidget,
    );
    expect(
      find.byKey(FamilyMembersKeys.memberRow('member_mother')),
      findsOneWidget,
    );
    expect(
      find.byKey(FamilyMembersKeys.memberRow('member_guardian')),
      findsOneWidget,
    );
    expect(find.byKey(FamilyMembersKeys.memberRow('child_a')), findsOneWidget);
    expect(find.byKey(FamilyMembersKeys.memberRow('child_b')), findsOneWidget);
    expect(find.textContaining('أنت'), findsOneWidget);
    expect(find.textContaining('مشاركة'), findsOneWidget);
    expect(find.byKey(FamilyMembersKeys.sosCta), findsOneWidget);

    await tester.tap(find.byKey(FamilyMembersKeys.sosCta));
    await tester.pumpAndSettle();
    expect(sos, isTrue);

    await tester.tap(find.byKey(FamilyMembersKeys.memberRow('member_mother')));
    await tester.pumpAndSettle();
    expect(motherOpened, 'member_mother');

    // Invite CTA is below the fold — scroll the ListView into range.
    await tester.scrollUntilVisible(
      find.byKey(FamilyMembersKeys.inviteCta),
      200,
      scrollable: find.descendant(
        of: find.byKey(FamilyMembersKeys.list),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.byKey(FamilyMembersKeys.inviteCta), findsOneWidget);
  });

  testWidgets(
    'SCR-FAT-027 mother — view OK · invite disabled · no level edit',
    (tester) async {
      var invited = false;
      String? motherOpened;
      var sos = false;
      final repo = InMemoryFamilyMembersRepository(
        members: _fullFixture,
      );

      await tester.pumpWidget(
        _app(
          child: FamilyMembersScreen(
            repository: repo,
            roleOverride: AppRole.mother,
            onInvite: () => invited = true,
            onSos: () => sos = true,
            onOpenMotherLevel: (id) => motherOpened = id,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(FamilyMembersKeys.list), findsOneWidget);
      expect(find.byKey(FamilyMembersKeys.childLean), findsNothing);
      expect(find.byKey(FamilyMembersKeys.inviteCta), findsNothing);
      expect(find.byKey(FamilyMembersKeys.inviteDisabled), findsOneWidget);
      expect(find.textContaining('تغيير'), findsNothing);
      expect(motherOpened, isNull);
      expect(invited, isFalse);

      await tester.tap(find.byKey(FamilyMembersKeys.sosCta));
      await tester.pumpAndSettle();
      expect(sos, isTrue);
    },
  );

  testWidgets('SCR-FAT-027 child lean — SOS still ungated', (tester) async {
    var sos = false;
    final repo = InMemoryFamilyMembersRepository(
      members: _fullFixture,
    );

    await tester.pumpWidget(
      _app(
        child: FamilyMembersScreen(
          repository: repo,
          roleOverride: AppRole.child,
          onSos: () => sos = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(FamilyMembersKeys.childLean), findsOneWidget);
    expect(find.byKey(FamilyMembersKeys.list), findsNothing);
    expect(find.byKey(FamilyMembersKeys.sosCta), findsOneWidget);

    await tester.tap(find.byKey(FamilyMembersKeys.sosCta));
    await tester.pumpAndSettle();
    expect(sos, isTrue);
  });

  testWidgets('SCR-FAT-027 load error → AppErrorState + Retry', (tester) async {
    final repo = InMemoryFamilyMembersRepository(failLoad: true);

    await tester.pumpWidget(
      _app(
        child: FamilyMembersScreen(
          repository: repo,
          roleOverride: AppRole.father,
          onSos: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(FamilyMembersKeys.error), findsOneWidget);
    expect(find.byKey(const Key('app_error_retry')), findsOneWidget);

    repo
      ..failLoad = false
      ..seed(_ownerOnlyFixture);
    await tester.tap(find.byKey(const Key('app_error_retry')));
    await tester.pumpAndSettle();

    expect(find.byKey(FamilyMembersKeys.list), findsOneWidget);
    expect(
      find.byKey(FamilyMembersKeys.memberRow('member_owner')),
      findsOneWidget,
    );
  });

  testWidgets(
    'SCR-FAT-027 a pending invitation can be accepted, and the server is asked first',
    (tester) async {
      // The screen used to show members this device had recorded. An invitation addressed
      // to the caller is the one row it must act on, and it must act through the server.
      final commands = _RecordingCommands();
      final repository = InMemoryFamilyMembersRepository(
        members: [
          _member(
            id: 'member_owner',
            kind: FamilyMemberKind.owner,
            status: FamilyMembershipStatus.active,
          ),
          _member(
            id: 'member_invited_self',
            kind: FamilyMemberKind.mother,
            displayName: FamilyMembersRoleLabels.mother,
            monogram: FamilyMembersRoleLabels.motherMonogram,
            swatch: DayChildSwatch.sky,
            isSelf: true,
            status: FamilyMembershipStatus.invited,
          ),
        ],
      );

      await tester.pumpWidget(
        _app(
          child: FamilyMembersScreen(
            repository: repository,
            membershipCommands: commands,
            roleOverride: AppRole.mother,
            onInvite: () {},
            onSos: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final accept = find.byKey(
        FamilyMembersKeys.acceptInvitation('member_invited_self'),
      );
      expect(accept, findsOneWidget, reason: 'the invitation must be acceptable');

      await tester.tap(accept);
      await tester.pumpAndSettle();

      expect(commands.accepted, ['member_invited_self']);
      expect(commands.lastIdempotencyKey, isNotNull);
      final reloaded = await repository.listMembers(familyId: 'fam_stage1');
      expect(
        reloaded
            .where((member) => member.id == 'member_invited_self')
            .single
            .membershipStatus,
        FamilyMembershipStatus.invited,
        reason: 'the screen reads the roster back from the source rather than '
            'redrawing it from its own hope: the command confirmed nothing here',
      );
    },
  );

  testWidgets(
    'SCR-FAT-027 an owner can withdraw an invitation and remove an active member',
    (tester) async {
      final commands = _RecordingCommands();
      final repository = InMemoryFamilyMembersRepository(
        members: [
          _member(
            id: 'member_owner',
            kind: FamilyMemberKind.owner,
            isSelf: true,
            status: FamilyMembershipStatus.active,
          ),
          _member(
            id: 'member_pending',
            kind: FamilyMemberKind.mother,
            displayName: FamilyMembersRoleLabels.mother,
            monogram: FamilyMembersRoleLabels.motherMonogram,
            swatch: DayChildSwatch.sky,
            status: FamilyMembershipStatus.invited,
          ),
          _member(
            id: 'member_active',
            kind: FamilyMemberKind.guardian,
            displayName: FamilyMembersRoleLabels.guardian,
            monogram: FamilyMembersRoleLabels.guardianMonogram,
            swatch: DayChildSwatch.amber,
            levelLocked: true,
            status: FamilyMembershipStatus.active,
          ),
        ],
      );

      await tester.pumpWidget(
        _app(
          child: FamilyMembersScreen(
            repository: repository,
            membershipCommands: commands,
            roleOverride: AppRole.father,
            onInvite: () {},
            onSos: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(FamilyMembersKeys.cancelInvitation('member_pending')),
      );
      await tester.pumpAndSettle();
      expect(commands.revoked, ['member_pending']);
      expect(commands.lastReasonCode, 'invitation_withdrawn');

      await tester.tap(
        find.byKey(FamilyMembersKeys.removeMember('member_active')),
      );
      await tester.pumpAndSettle();
      expect(commands.revoked, ['member_pending', 'member_active']);
      expect(
        commands.lastReasonCode,
        'member_left',
        reason: 'removing an active member and withdrawing an invitation are different '
            'facts, and the server is told which one happened',
      );

      // The owner's own row offers nothing, and a child row offers nothing: the primary
      // guardian is removed only through the continuity process, and a child is removed
      // from the child's own profile.
      expect(
        find.byKey(FamilyMembersKeys.removeMember('member_owner')),
        findsNothing,
      );
    },
  );

  testWidgets('SCR-FAT-027 a refused command says so and changes nothing', (
    tester,
  ) async {
    final commands = _RecordingCommands(fail: true);
    final repository = InMemoryFamilyMembersRepository(
      members: [
        _member(
          id: 'member_pending',
          kind: FamilyMemberKind.mother,
          displayName: FamilyMembersRoleLabels.mother,
          monogram: FamilyMembersRoleLabels.motherMonogram,
          swatch: DayChildSwatch.sky,
          status: FamilyMembershipStatus.invited,
        ),
      ],
    );

    await tester.pumpWidget(
      _app(
        child: FamilyMembersScreen(
          repository: repository,
          membershipCommands: commands,
          roleOverride: AppRole.father,
          onInvite: () {},
          onSos: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(FamilyMembersKeys.cancelInvitation('member_pending')),
    );
    await tester.pumpAndSettle();

    expect(commands.revoked, ['member_pending']);
    expect(
      find.byKey(FamilyMembersKeys.memberRow('member_pending')),
      findsOneWidget,
      reason: 'a failed command leaves the roster exactly as it was',
    );
    expect(
      find.textContaining('تعذر الإكمال'),
      findsWidgets,
      reason: 'the guardian is told the change did not happen',
    );
  });

  testWidgets(
    'SCR-FAT-027 without live commands no membership action is offered at all',
    (tester) async {
      // A build with no server must not draw buttons that could only fail. The rows stay
      // readable; the actions are absent.
      final repository = InMemoryFamilyMembersRepository(
        members: [
          _member(
            id: 'member_pending',
            kind: FamilyMemberKind.mother,
            displayName: FamilyMembersRoleLabels.mother,
            monogram: FamilyMembersRoleLabels.motherMonogram,
            swatch: DayChildSwatch.sky,
            status: FamilyMembershipStatus.invited,
          ),
        ],
      );

      await tester.pumpWidget(
        _app(
          child: FamilyMembersScreen(
            repository: repository,
            roleOverride: AppRole.father,
            onInvite: () {},
            onSos: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(FamilyMembersKeys.memberRow('member_pending')),
        findsOneWidget,
      );
      expect(
        find.byKey(FamilyMembersKeys.cancelInvitation('member_pending')),
        findsNothing,
      );
      expect(
        find.byKey(FamilyMembersKeys.acceptInvitation('member_pending')),
        findsNothing,
      );
    },
  );

  test('Rule 23 — no planted person names in FAT-027 sources/ARB', () {
    final files = [
      'lib/features/n12_devices/family_members_screen.dart',
      'lib/features/n12_devices/family_members_repository.dart',
      'lib/features/n12_devices/family_members_role_labels.dart',
      'lib/features/n12_devices/family_members_remote_repository.dart',
    ];
    for (final path in files) {
      final src = File(path).readAsStringSync();
      expect(src.contains('خالد'), isFalse, reason: path);
      expect(src.contains('نورة'), isFalse, reason: path);
      expect(src.contains('عبدالله'), isFalse, reason: path);
      expect(src.contains('نوال'), isFalse, reason: path);
    }

    final arArb = File('lib/core/i18n/app_ar.arb').readAsStringSync();
    final enArb = File('lib/core/i18n/app_en.arb').readAsStringSync();
    final re = RegExp(r'"familyMembers[^"]*"\s*:\s*"((?:\\.|[^"\\])*)"');
    for (final value in [
      ...re.allMatches(arArb).map((m) => m.group(1)!),
      ...re.allMatches(enArb).map((m) => m.group(1)!),
    ]) {
      expect(value.contains('خالد'), isFalse, reason: value);
      expect(value.contains('نورة'), isFalse, reason: value);
      expect(value.contains('عبدالله'), isFalse, reason: value);
      expect(value.contains('نوال'), isFalse, reason: value);
    }
  });

  testWidgets(
    'family selector switches context and prevents cross-family leak',
    (tester) async {
      final runtime = IdentityRuntime(
        account: Account(id: AccountId('acc_owner')),
        session: Session(
          id: SessionId('sess_owner'),
          accountId: AccountId('acc_owner'),
          startedAt: DateTime.utc(2026, 1, 1),
        ),
        families: [
          Family(
            id: FamilyId('fam_a'),
            name: 'Family A',
            ownerMemberId: MemberId('mem_owner_a'),
          ),
          Family(
            id: FamilyId('fam_b'),
            name: 'Family B',
            ownerMemberId: MemberId('mem_owner_b'),
          ),
        ],
        memberships: [
          FamilyMembership(
            id: MemberId('mem_owner_a'),
            accountId: AccountId('acc_owner'),
            familyId: FamilyId('fam_a'),
            role: AppRole.father,
            tier: MembershipTier.primary,
            isPrimaryOwner: true,
          ),
          FamilyMembership(
            id: MemberId('mem_owner_b'),
            accountId: AccountId('acc_owner'),
            familyId: FamilyId('fam_b'),
            role: AppRole.father,
            tier: MembershipTier.primary,
            isPrimaryOwner: true,
          ),
        ],
        activeFamilyId: FamilyId('fam_a'),
        activeChildScope: ChildScope(
          familyId: FamilyId('fam_a'),
          childId: ChildId('child_a'),
        ),
        children: [
          ChildIdentity(id: ChildId('child_a'), familyId: FamilyId('fam_a')),
          ChildIdentity(id: ChildId('child_b'), familyId: FamilyId('fam_b')),
        ],
      );

      final repo = InMemoryFamilyMembersRepository(
        byFamily: {
          'fam_a': [
            const FamilyMemberEntry(
              id: 'member_owner_a',
              familyId: 'fam_a',
              displayName: 'وليّ الأمر أ',
              kind: FamilyMemberKind.owner,
              monogram: 'أ',
              swatch: DayChildSwatch.purple,
            ),
          ],
          'fam_b': [
            const FamilyMemberEntry(
              id: 'member_owner_b',
              familyId: 'fam_b',
              displayName: 'وليّ الأمر ب',
              kind: FamilyMemberKind.owner,
              monogram: 'ب',
              swatch: DayChildSwatch.sky,
            ),
          ],
        },
      );

      await tester.pumpWidget(
        CurrentIdentity(
          runtime: runtime,
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
            home: FamilyMembersScreen(
              repository: repo,
              roleOverride: AppRole.father,
              onSos: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Family A'), findsOneWidget);
      expect(find.text('وليّ الأمر أ'), findsOneWidget);
      expect(find.text('وليّ الأمر ب'), findsNothing);

      await tester.tap(find.byType(DropdownButton<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Family B').last);
      await tester.pumpAndSettle();

      expect(runtime.activeFamilyId, FamilyId('fam_b'));
      expect(find.text('وليّ الأمر ب'), findsOneWidget);
      expect(find.text('وليّ الأمر أ'), findsNothing);
    },
  );

  testWidgets('SCR-FAT-027 without Identity → empty (fail-closed)', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildFamilyTheme(),
        locale: const Locale('ar'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: FamilyMembersScreen(
          repository: InMemoryFamilyMembersRepository(
            members: _fullFixture,
          ),
          roleOverride: AppRole.father,
          onSos: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(FamilyMembersKeys.empty), findsOneWidget);
    expect(
      find.byKey(FamilyMembersKeys.memberRow('member_owner')),
      findsNothing,
    );
  });

  testWidgets('SCR-FAT-027 Identity projection + LOCAL_DEMO banner', (
    tester,
  ) async {
    resetStage1ChildrenListRepositoryForTest();
    resetStage1FamilyMembersRepositoryForTest();
    rebindStage1ChildrenListRepository(
      InMemoryChildrenListRepository(
        byFamily: {
          ChildrenListLocalSeed.famStage1.value:
              ChildrenListLocalSeed.famStage1Children,
        },
        provenance: kChildrenListLocalDemoProvenance,
      ),
    );
    rebindStage1FamilyMembersRepository(IdentityFamilyMembersRepository());

    await tester.pumpWidget(
      _app(
        child: FamilyMembersScreen(
          roleOverride: AppRole.father,
          onInvite: () {},
          onSos: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(FamilyMembersKeys.list), findsOneWidget);
    expect(
      find.byKey(FamilyMembersKeys.memberRow('mem_stage1_owner')),
      findsOneWidget,
    );
    expect(
      find.byKey(FamilyMembersKeys.memberRow('mem_stage1_mother')),
      findsOneWidget,
    );
    expect(
      find.byKey(FamilyMembersKeys.memberRow('demo-child')),
      findsOneWidget,
    );
    expect(find.byKey(FamilyMembersKeys.localDemoBanner), findsOneWidget);
    expect(find.textContaining('خالد'), findsNothing);

    resetStage1ChildrenListRepositoryForTest();
    resetStage1FamilyMembersRepositoryForTest();
  });
}

Widget _app({required Widget child}) {
  return CurrentIdentity(
    runtime: createStage1IdentityRuntime(),
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
      home: child,
    ),
  );
}

/// One roster row. A factory rather than a literal so the entries stay plainly
/// non-constant: these are values a test built, not compile-time constants the analyzer
/// would rightly ask to be marked const.
FamilyMemberEntry _member({
  required String id,
  required FamilyMemberKind kind,
  String? displayName,
  String? monogram,
  DayChildSwatch swatch = DayChildSwatch.purple,
  bool isSelf = false,
  MotherLevel? motherLevel,
  bool levelLocked = false,
  FamilyMembershipStatus? status,
}) {
  return FamilyMemberEntry(
    id: id,
    familyId: 'fam_stage1',
    displayName: displayName ?? FamilyMembersRoleLabels.owner,
    kind: kind,
    monogram: monogram ?? FamilyMembersRoleLabels.ownerMonogram,
    swatch: swatch,
    isSelf: isSelf,
    motherLevel: motherLevel,
    levelLocked: levelLocked,
    membershipStatus: status,
  );
}

final List<FamilyMemberEntry> _fullFixture = [
  _member(
    id: 'member_owner',
    kind: FamilyMemberKind.owner,
    displayName: FamilyMembersRoleLabels.owner,
    isSelf: true,
    status: FamilyMembershipStatus.active,
  ),
  _member(
    id: 'member_mother',
    kind: FamilyMemberKind.mother,
    displayName: FamilyMembersRoleLabels.mother,
    monogram: FamilyMembersRoleLabels.motherMonogram,
    swatch: DayChildSwatch.sky,
    motherLevel: MotherLevel.partner,
    status: FamilyMembershipStatus.active,
  ),
  _member(
    id: 'member_guardian',
    kind: FamilyMemberKind.guardian,
    displayName: FamilyMembersRoleLabels.guardian,
    monogram: FamilyMembersRoleLabels.guardianMonogram,
    swatch: DayChildSwatch.amber,
    motherLevel: MotherLevel.observer,
    levelLocked: true,
    status: FamilyMembershipStatus.active,
  ),
  _member(
    id: 'child_a',
    kind: FamilyMemberKind.child,
    displayName: 'ابن 1',
    monogram: '🦁',
    swatch: DayChildSwatch.purple,
  ),
  _member(
    id: 'child_b',
    kind: FamilyMemberKind.child,
    displayName: 'ابن 2',
    monogram: '🐱',
    swatch: DayChildSwatch.sky,
  ),
];

/// Owner-only family, so the invite CTA has a start state to work from.
final List<FamilyMemberEntry> _ownerOnlyFixture = [
  _member(
    id: 'member_owner',
    kind: FamilyMemberKind.owner,
    isSelf: true,
    status: FamilyMembershipStatus.active,
  ),
];
