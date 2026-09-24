import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/identity/identity_models.dart';
import 'package:family_os/core/identity/identity_runtime.dart';
import 'package:family_os/core/identity/identity_scope.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n02_day/day_child_mock.dart';
import 'package:family_os/features/n12_devices/family_members_mock.dart';
import 'package:family_os/features/n12_devices/family_members_repository.dart';
import 'package:family_os/features/n12_devices/family_members_screen.dart';

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
      members: FamilyMembersMock.fullFixture,
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
    expect(find.byKey(FamilyMembersKeys.inviteCta), findsOneWidget);
    expect(find.byKey(FamilyMembersKeys.sosCta), findsOneWidget);

    await tester.tap(find.byKey(FamilyMembersKeys.sosCta));
    await tester.pumpAndSettle();
    expect(sos, isTrue);

    await tester.tap(find.byKey(FamilyMembersKeys.memberRow('member_mother')));
    await tester.pumpAndSettle();
    expect(motherOpened, 'member_mother');
  });

  testWidgets(
    'SCR-FAT-027 mother — view OK · invite disabled · no level edit',
    (tester) async {
      var invited = false;
      String? motherOpened;
      var sos = false;
      final repo = InMemoryFamilyMembersRepository(
        members: FamilyMembersMock.fullFixture,
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
      members: FamilyMembersMock.fullFixture,
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
      ..seed(FamilyMembersMock.ownerOnlyFixture);
    await tester.tap(find.byKey(const Key('app_error_retry')));
    await tester.pumpAndSettle();

    expect(find.byKey(FamilyMembersKeys.list), findsOneWidget);
    expect(
      find.byKey(FamilyMembersKeys.memberRow('member_owner')),
      findsOneWidget,
    );
  });

  test('Rule 23 — no planted person names in FAT-027 sources/ARB', () {
    final files = [
      'lib/features/n12_devices/family_members_screen.dart',
      'lib/features/n12_devices/family_members_repository.dart',
      'lib/features/n12_devices/family_members_mock.dart',
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
          child: _app(
            child: const FamilyMembersScreen(roleOverride: AppRole.father),
          ),
        ),
      );
      // Rebuild with repository injected.
      await tester.pumpWidget(
        CurrentIdentity(
          runtime: runtime,
          child: _app(
            child: FamilyMembersScreen(
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
}

Widget _app({required Widget child}) {
  return MaterialApp(
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
  );
}
