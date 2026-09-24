import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/data/child_repository.dart';
import 'package:family_os/core/data/family_database.dart';

/// PERS-2a acceptance — the identity core is a real store, not a mock list.
///
/// The last test is the card's measured criterion: a child written to the
/// device database is still there after the database is closed and reopened.
ChildrenCompanion _child({
  String id = 'child-1',
  String familyId = 'fam-1',
  String name = 'خالد',
  String alias = 'child_a7f3',
}) {
  return ChildrenCompanion.insert(
    id: id,
    familyId: familyId,
    displayName: name,
    alias: alias,
  );
}

void main() {
  group('child repository over the local database', () {
    late FamilyDatabase db;
    late DriftChildRepository repo;

    setUp(() {
      db = FamilyDatabase(NativeDatabase.memory());
      repo = DriftChildRepository(db);
    });

    tearDown(() => db.close());

    test('insert then read back with contract defaults', () async {
      await repo.upsert(_child());

      final row = await repo.byId('child-1');

      expect(row, isNotNull);
      expect(row!.displayName, 'خالد');
      expect(row.alias, 'child_a7f3');
      expect(row.familyId, 'fam-1');
      expect(row.avatar, 'lion', reason: 'contract default avatar');
      expect(row.birthYear, isNull, reason: 'optional in the contract');
    });

    test('alias is unique across the store', () async {
      await repo.upsert(_child());

      await expectLater(
        repo.upsert(_child(id: 'child-2', name: 'نورة')),
        throwsA(isA<Exception>()),
        reason: 'child.alias is UNIQUE in the contract',
      );
    });

    test('upsert updates an existing row instead of duplicating it', () async {
      await repo.upsert(_child());
      await repo.upsert(_child(name: 'خالد بن عبدالله'));

      final rows = await repo.allInFamily('fam-1');

      expect(rows, hasLength(1));
      expect(rows.single.displayName, 'خالد بن عبدالله');
    });

    test('rows are scoped to their family', () async {
      await repo.upsert(_child());
      await repo.upsert(_child(id: 'child-9', familyId: 'fam-2', alias: 'child_b9k2', name: 'سعد'));

      expect(await repo.allInFamily('fam-1'), hasLength(1));
      expect(await repo.allInFamily('fam-2'), hasLength(1));
    });

    test('delete removes the row', () async {
      await repo.upsert(_child());

      expect(await repo.deleteById('child-1'), 1);
      expect(await repo.byId('child-1'), isNull);
    });
  });

  group('acceptance — the child survives a database reopen', () {
    test('write, close, reopen, read', () async {
      final dir = Directory.systemTemp.createTempSync('family_os_db_test');
      final file = File('${dir.path}/family_os.sqlite');

      try {
        var db = FamilyDatabase(NativeDatabase(file));
        await DriftChildRepository(db).upsert(_child());
        await db.close();

        // A fresh handle over the same file — nothing shared in memory.
        db = FamilyDatabase(NativeDatabase(file));
        final reopened = await DriftChildRepository(db).byId('child-1');

        expect(reopened, isNotNull);
        expect(reopened!.displayName, 'خالد');
        expect(reopened.alias, 'child_a7f3');
        await db.close();
      } finally {
        dir.deleteSync(recursive: true);
      }
    });
  });
}
