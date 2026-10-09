import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/fs_foundation/fs_session_kernel.dart';
import 'package:family_os/core/fs_foundation/memory_local_database.dart';
import 'package:family_os/core/fs_foundation/sqlite_local_database.dart';
import 'package:family_os/core/policy/screen_time_policy.dart';
import 'package:family_os/core/screen_time/screen_time_local_persistence.dart';

/// DOM-ST-02A.1 — policy must not bind when SQLite fell back to Memory.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() async {
    await FsSessionKernel.resetForTest();
  });

  test('openPolicyRepository refuses sqliteFallbackToMemory', () async {
    await FsSessionKernel.resetForTest();
    await FsSessionKernel.ensureOpen(preferSqlite: true);
    if (FsSessionKernel.usingSqlite) {
      expect(FsSessionKernel.sqliteFallbackToMemory, isFalse);
      return;
    }
    expect(FsSessionKernel.sqliteFallbackToMemory, isTrue);
    expect(FsSessionKernel.db, isA<MemoryLocalDatabase>());
    await expectLater(
      ScreenTimeLocalPersistence.openPolicyRepository(),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('refuses SQLite→Memory fallback'),
        ),
      ),
    );
  });

  test(
    'intentional test Memory (no fallback flag) still opens policy repo',
    () async {
      await FsSessionKernel.resetForTest();
      await FsSessionKernel.ensureOpen(preferSqlite: false);
      expect(FsSessionKernel.sqliteFallbackToMemory, isFalse);
      expect(FsSessionKernel.usingSqlite, isFalse);
      final repo = await ScreenTimeLocalPersistence.openPolicyRepository();
      await repo.save(ChildId('t'), ScreenTimePolicy(dailyCapMinutes: 10));
      expect((await repo.load(ChildId('t'))).dailyCapMinutes, 10);
    },
  );

  test('healthy SQLite openPolicyRepository still restart-safe', () async {
    final dir = await Directory.systemTemp.createTemp('dom_st02a1_');
    final path = p.join(dir.path, 'ok.db');
    final child = ChildId('c_ok');

    final db1 = await SqliteLocalDatabase.openAt(path);
    await FsSessionKernel.ensureOpen(override: db1);
    expect(FsSessionKernel.sqliteFallbackToMemory, isFalse);
    expect(FsSessionKernel.usingSqlite, isTrue);
    final repo1 = await ScreenTimeLocalPersistence.openPolicyRepository();
    await repo1.save(child, ScreenTimePolicy(dailyCapMinutes: 55));
    await FsSessionKernel.resetForTest();

    final db2 = await SqliteLocalDatabase.openAt(path);
    await FsSessionKernel.ensureOpen(override: db2);
    final loaded =
        await (await ScreenTimeLocalPersistence.openPolicyRepository()).load(
          child,
        );
    expect(loaded.dailyCapMinutes, 55);

    await FsSessionKernel.resetForTest();
    await dir.delete(recursive: true);
  });
}
