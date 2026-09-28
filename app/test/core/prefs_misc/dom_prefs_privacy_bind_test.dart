import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/fs_foundation/fs_session_kernel.dart';
import 'package:family_os/core/fs_foundation/memory_local_database.dart';
import 'package:family_os/core/fs_foundation/sqlite_local_database.dart';
import 'package:family_os/core/policy/collection_scope.dart';
import 'package:family_os/core/policy/privacy_collection_policy.dart';
import 'package:family_os/core/policy/privacy_collection_repository.dart';
import 'package:family_os/core/prefs_misc/prefs_misc_local_persistence.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() async {
    await FsSessionKernel.resetForTest();
  });

  test('privacy prefs write→close→reopen→read', () async {
    final dir = await Directory.systemTemp.createTemp('dom_prefs_priv_');
    final path = p.join(dir.path, 'priv.db');

    final db1 = await SqliteLocalDatabase.openAt(path);
    await FsSessionKernel.ensureOpen(override: db1);
    final repo1 = await PrefsMiscLocalPersistence.openPrivacyRepository();
    final policy = PrivacyCollectionPolicy.defaults(childId: 'demo-child')
        .withScope(CollectionScope.location, false);
    final result = await repo1.save(policy, actor: AppRole.father);
    expect(result, isA<PrivacyCollectionWriteOk>());
    await FsSessionKernel.resetForTest();

    final db2 = await SqliteLocalDatabase.openAt(path);
    await FsSessionKernel.ensureOpen(override: db2);
    final loaded =
        await (await PrefsMiscLocalPersistence.openPrivacyRepository())
            .load('demo-child');
    expect(loaded.isEnabled(CollectionScope.location), isFalse);

    await FsSessionKernel.resetForTest();
    await dir.delete(recursive: true);
  });

  test('openPrivacyRepository refuses sqliteFallbackToMemory', () async {
    await FsSessionKernel.resetForTest();
    await FsSessionKernel.ensureOpen(preferSqlite: true);
    if (FsSessionKernel.usingSqlite) {
      expect(FsSessionKernel.sqliteFallbackToMemory, isFalse);
      return;
    }
    expect(FsSessionKernel.sqliteFallbackToMemory, isTrue);
    expect(FsSessionKernel.db, isA<MemoryLocalDatabase>());
    await expectLater(
      PrefsMiscLocalPersistence.openPrivacyRepository(),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('refuses SQLite→Memory'),
        ),
      ),
    );
  });
}
