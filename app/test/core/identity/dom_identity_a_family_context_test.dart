import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/fs_foundation/fs_session_kernel.dart';
import 'package:family_os/core/fs_foundation/memory_local_database.dart';
import 'package:family_os/core/fs_foundation/sqlite_local_database.dart';
import 'package:family_os/core/identity/identity_local_persistence.dart';
import 'package:family_os/core/identity/identity_runtime.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() async {
    resetStage1IdentityRuntimeForTest();
    await FsSessionKernel.resetForTest();
  });

  test('family context write→close→reopen→read', () async {
    final dir = await Directory.systemTemp.createTemp('dom_id_a_');
    final path = p.join(dir.path, 'id.db');
    final account = AccountId('acc_stage1_father');
    final family = FamilyId('fam_stage2');

    final db1 = await SqliteLocalDatabase.openAt(path);
    await FsSessionKernel.ensureOpen(override: db1);
    final store1 = await IdentityLocalPersistence.openFamilyContextStore();
    await store1.saveActiveFamily(account, family);
    await FsSessionKernel.resetForTest();

    final db2 = await SqliteLocalDatabase.openAt(path);
    await FsSessionKernel.ensureOpen(override: db2);
    final store2 = await IdentityLocalPersistence.openFamilyContextStore();
    expect(store2.loadActiveFamily(account), family);

    await FsSessionKernel.resetForTest();
    await dir.delete(recursive: true);
  });

  test('openFamilyContextStore refuses sqliteFallbackToMemory', () async {
    await FsSessionKernel.resetForTest();
    await FsSessionKernel.ensureOpen(preferSqlite: true);
    if (FsSessionKernel.usingSqlite) {
      expect(FsSessionKernel.sqliteFallbackToMemory, isFalse);
      return;
    }
    expect(FsSessionKernel.sqliteFallbackToMemory, isTrue);
    expect(FsSessionKernel.db, isA<MemoryLocalDatabase>());
    await expectLater(
      IdentityLocalPersistence.openFamilyContextStore(),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('refuses SQLite→Memory fallback'),
        ),
      ),
    );
  });
}
