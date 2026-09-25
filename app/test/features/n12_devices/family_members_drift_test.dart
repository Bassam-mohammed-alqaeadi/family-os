import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/data/family_database.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/features/n12_devices/family_members_drift_repository.dart';
import 'package:family_os/features/n12_devices/family_members_repository.dart';

/// DEV-2 — the roster over real rows (`member` ⋈ `account`, plus `child`).
void main() {
  group('DEV-2 — family roster over real rows', () {
    late Directory dir;
    late File file;
    late FamilyDatabase db;
    late DriftFamilyMembersRepository repo;
    var dbClosed = false;

    setUp(() async {
      dbClosed = false;
      dir = await Directory.systemTemp.createTemp('dev2_');
      file = File('${dir.path}/dev2.sqlite');
      db = FamilyDatabase(NativeDatabase(file));
      repo = DriftFamilyMembersRepository(db, selfAccountId: 'acc_father');
    });

    tearDown(() async {
      if (!dbClosed) await db.close();
      await dir.delete(recursive: true);
    });

    Future<void> account(String id, String name, String email) =>
        db.into(db.accounts).insert(
          AccountsCompanion.insert(
            id: id,
            email: email,
            passwordHash: 'x',
            displayName: name,
          ),
        );

    Future<void> member({
      required String id,
      required String accountId,
      required MemberRole role,
      required PermLevel level,
      required DateTime joinedAt,
    }) => db.into(db.members).insert(
      MembersCompanion.insert(
        id: id,
        familyId: 'fam_1',
        accountId: accountId,
        role: role,
        permissionLevel: level,
        joinedAt: Value(joinedAt),
      ),
    );

    Future<void> seed() async {
      await account('acc_father', 'بسام', 'father@example.com');
      await account('acc_mother', 'نوال', 'mother@example.com');
      await account('acc_guardian', 'سالم', 'guardian@example.com');
      await member(
        id: 'mem_owner',
        accountId: 'acc_father',
        role: MemberRole.owner,
        level: PermLevel.full,
        joinedAt: DateTime.utc(2026, 1, 1),
      );
      await member(
        id: 'mem_mother',
        accountId: 'acc_mother',
        role: MemberRole.parent,
        level: PermLevel.partner,
        joinedAt: DateTime.utc(2026, 1, 2),
      );
      await member(
        id: 'mem_guardian',
        accountId: 'acc_guardian',
        role: MemberRole.guardian,
        level: PermLevel.observer,
        joinedAt: DateTime.utc(2026, 1, 3),
      );
      await db.into(db.children).insert(
        ChildrenCompanion.insert(
          id: 'chi_1',
          familyId: 'fam_1',
          displayName: 'ريان',
          alias: 'child_1',
          createdAt: Value(DateTime.utc(2026, 1, 4)),
        ),
      );
    }

    test('reads owners, mother level, guardians and children from rows',
        () async {
      await seed();

      final roster = await repo.listMembers(familyId: 'fam_1');

      expect(
        roster.map((m) => m.id).toList(),
        ['mem_owner', 'mem_mother', 'mem_guardian', 'chi_1'],
      );
      expect(roster[0].kind, FamilyMemberKind.owner);
      expect(roster[0].displayName, 'بسام');
      expect(roster[0].motherLevel, isNull);

      expect(roster[1].kind, FamilyMemberKind.mother);
      expect(roster[1].displayName, 'نوال');
      expect(roster[1].motherLevel, MotherLevel.partner);

      expect(roster[2].kind, FamilyMemberKind.guardian);
      expect(roster[2].motherLevel, isNull);
      // Guardians stay observer — never promoted to FAT-031.
      expect(roster[2].levelLocked, isTrue);

      expect(roster[3].kind, FamilyMemberKind.child);
      expect(roster[3].displayName, 'ريان');
      // Names come from rows; the app plants none (Rule 23).
      expect(roster.where((m) => m.displayName.trim().isEmpty), isEmpty);
    });

    test('marks the signed-in account as self, and only it', () async {
      await seed();

      final roster = await repo.listMembers(familyId: 'fam_1');

      expect(roster.where((m) => m.isSelf).map((m) => m.id), ['mem_owner']);
    });

    test('an unscoped or unknown family fails closed', () async {
      await seed();

      expect(await repo.listMembers(), isEmpty);
      expect(await repo.listMembers(familyId: '   '), isEmpty);
      expect(await repo.listMembers(familyId: 'fam_other'), isEmpty);
    });

    test('ADR-042 — the roster survives close + reopen', () async {
      await seed();
      await db.close();
      dbClosed = true;

      final reopened = FamilyDatabase(NativeDatabase(file));
      addTearDown(reopened.close);
      final reopenedRepo = DriftFamilyMembersRepository(
        reopened,
        selfAccountId: 'acc_father',
      );

      final roster = await reopenedRepo.listMembers(familyId: 'fam_1');
      expect(roster, hasLength(4));
      expect(roster[1].displayName, 'نوال');
      expect(roster[1].motherLevel, MotherLevel.partner);
    });

    test('guardian level comes from the row, never from the widget', () async {
      await seed();
      // Promote the guardian's stored level — the row wins, the flag stays.
      await (db.update(db.members)..where((t) => t.id.equals('mem_guardian')))
          .write(const MembersCompanion(permissionLevel: Value(PermLevel.full)));

      final roster = await repo.listMembers(familyId: 'fam_1');
      final guardian = roster.firstWhere(
        (m) => m.kind == FamilyMemberKind.guardian,
      );
      expect(guardian.levelLocked, isTrue);
    });
  });
}
