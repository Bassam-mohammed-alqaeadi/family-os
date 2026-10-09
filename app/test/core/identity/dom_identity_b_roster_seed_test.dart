import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/fs_foundation/fs_session_kernel.dart';
import 'package:family_os/core/fs_foundation/memory_local_database.dart';
import 'package:family_os/core/fs_foundation/sqlite_local_database.dart';
import 'package:family_os/core/identity/identity_local_persistence.dart';
import 'package:family_os/features/n02_day/children_list_local_repository.dart';
import 'package:family_os/features/n02_day/children_list_repository.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() async {
    resetStage1ChildrenListRepositoryForTest();
    await FsSessionKernel.resetForTest();
  });

  test('seed→persist→close→reopen→read REAL_LOCAL provenance', () async {
    final dir = await Directory.systemTemp.createTemp('dom_id_b_');
    final path = p.join(dir.path, 'roster.db');
    final fam = FamilyId('fam_stage1');

    final db1 = await SqliteLocalDatabase.openAt(path);
    await FsSessionKernel.ensureOpen(override: db1);
    final repo1 = await IdentityLocalPersistence.openChildrenListRepository();
    final kids1 = await repo1.listChildren(familyId: fam);
    expect(kids1.length, 2);
    expect(kids1.map((e) => e.id), containsAll(['demo-child', 'child_b']));
    expect(
      await repo1.loadProvenance(familyId: fam),
      kChildrenListRealLocalProvenance,
    );
    await FsSessionKernel.resetForTest();

    final db2 = await SqliteLocalDatabase.openAt(path);
    await FsSessionKernel.ensureOpen(override: db2);
    final repo2 = await IdentityLocalPersistence.openChildrenListRepository();
    final kids2 = await repo2.listChildren(familyId: fam);
    expect(kids2.length, 2);
    expect(kids2.firstWhere((e) => e.id == 'demo-child').displayName, 'ابن 1');
    // The local roster does not fabricate a connectivity or device warning.
    expect(kids2.firstWhere((e) => e.id == 'child_b').warnRing, isFalse);
    expect(
      await repo2.loadProvenance(familyId: fam),
      kChildrenListRealLocalProvenance,
    );
    // Provenance proves a local seed — not GPS/battery authority.
    expect(
      await repo2.loadProvenance(familyId: fam),
      isNot(anyOf('GPS', 'NATIVE', 'OS_BATTERY')),
    );

    await FsSessionKernel.resetForTest();
    await dir.delete(recursive: true);
  });

  test('openChildrenListRepository refuses sqliteFallbackToMemory', () async {
    await FsSessionKernel.resetForTest();
    await FsSessionKernel.ensureOpen(preferSqlite: true);
    if (FsSessionKernel.usingSqlite) {
      expect(FsSessionKernel.sqliteFallbackToMemory, isFalse);
      return;
    }
    expect(FsSessionKernel.sqliteFallbackToMemory, isTrue);
    expect(FsSessionKernel.db, isA<MemoryLocalDatabase>());
    await expectLater(
      IdentityLocalPersistence.openChildrenListRepository(),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('refuses SQLite→Memory fallback'),
        ),
      ),
    );
  });

  test('bind exposes populated roster on stage1 accessor', () async {
    final dir = await Directory.systemTemp.createTemp('dom_id_b_bind_');
    final path = p.join(dir.path, 'bind.db');
    final db = await SqliteLocalDatabase.openAt(path);
    await FsSessionKernel.ensureOpen(override: db);
    expect(await IdentityLocalPersistence.tryBindStage1ChildrenList(), isTrue);
    final kids = await stage1ChildrenListRepository.listChildren(
      familyId: FamilyId('fam_stage1'),
    );
    expect(kids, isNotEmpty);
    expect(kids.length, 2);

    resetStage1ChildrenListRepositoryForTest();
    await FsSessionKernel.resetForTest();
    await dir.delete(recursive: true);
  });
}
