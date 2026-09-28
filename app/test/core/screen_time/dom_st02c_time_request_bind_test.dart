import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/fs_foundation/fs_session_kernel.dart';
import 'package:family_os/core/fs_foundation/memory_local_database.dart';
import 'package:family_os/core/fs_foundation/sqlite_local_database.dart';
import 'package:family_os/core/policy/time_request.dart';
import 'package:family_os/core/screen_time/screen_time_local_persistence.dart';
import 'package:family_os/core/screen_time/stage1_time_request_runtime.dart';

/// DOM-ST-02C — TimeRequest/Grant production path + honesty.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() async {
    Stage1TimeRequestRuntime.resetForTest();
    await FsSessionKernel.resetForTest();
  });

  test('openTimeRequestRepository write→close→reopen→read', () async {
    final dir = await Directory.systemTemp.createTemp('dom_st02c_');
    final path = p.join(dir.path, 'time.db');
    final child = ChildId('child_tr_prod');
    final created = DateTime.utc(2026, 9, 25, 10);
    final expires = DateTime.utc(2026, 9, 25, 22);

    final pending = TimeRequest(
      id: 'tr_1',
      childId: child,
      requestedMinutes: 20,
      childReason: 'homework',
      status: TimeRequestStatus.pending,
      createdAt: created,
    );
    final grant = TimeGrant(
      id: 'tg_1',
      requestId: 'tr_1',
      childId: child,
      minutes: 20,
      remainingMinutes: 15,
      grantedBy: 'father',
      createdAt: created,
      expiresAt: expires,
      status: TimeGrantStatus.active,
    );

    final db1 = await SqliteLocalDatabase.openAt(path);
    await FsSessionKernel.ensureOpen(override: db1);
    final repo1 = await ScreenTimeLocalPersistence.openTimeRequestRepository();
    await repo1.saveAll([pending]);
    await repo1.saveGrant(grant);
    await FsSessionKernel.resetForTest();

    final db2 = await SqliteLocalDatabase.openAt(path);
    await FsSessionKernel.ensureOpen(override: db2);
    final repo2 = await ScreenTimeLocalPersistence.openTimeRequestRepository();
    final loaded = await repo2.loadAll();
    expect(loaded.single.id, 'tr_1');
    expect(loaded.single.childId, child);
    expect(loaded.single.status, TimeRequestStatus.pending);

    final grants = await repo2.loadGrants();
    expect(grants.single.id, 'tg_1');
    expect(grants.single.remainingMinutes, 15);
    expect(grants.single.isActiveAt(DateTime.utc(2026, 9, 25, 15)), isTrue);
    expect(grants.single.isActiveAt(DateTime.utc(2026, 9, 25, 22, 1)), isFalse);

    await FsSessionKernel.resetForTest();
    await dir.delete(recursive: true);
  });

  test('openTimeRequestRepository refuses sqliteFallbackToMemory', () async {
    await FsSessionKernel.resetForTest();
    await FsSessionKernel.ensureOpen(preferSqlite: true);
    if (FsSessionKernel.usingSqlite) {
      expect(FsSessionKernel.sqliteFallbackToMemory, isFalse);
      return;
    }
    expect(FsSessionKernel.sqliteFallbackToMemory, isTrue);
    expect(FsSessionKernel.db, isA<MemoryLocalDatabase>());
    await expectLater(
      ScreenTimeLocalPersistence.openTimeRequestRepository(),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('refuses SQLite→Memory fallback'),
        ),
      ),
    );
  });

  test('Stage1TimeRequestRuntime shares Local KV authority', () async {
    final dir = await Directory.systemTemp.createTemp('dom_st02c_rt_');
    final path = p.join(dir.path, 'rt.db');
    final child = ChildId('c_rt');

    final db = await SqliteLocalDatabase.openAt(path);
    await FsSessionKernel.ensureOpen(override: db);
    final service = await Stage1TimeRequestRuntime.ensureOpen();
    await service.createRequest(
      childId: child,
      requestedMinutes: 15,
      childReason: 'test',
    );
    final pending = await Stage1TimeRequestRuntime.repository.loadAll();
    expect(pending.single.childId, child);
    expect(pending.single.requestedMinutes, 15);

    Stage1TimeRequestRuntime.resetForTest();
    await FsSessionKernel.resetForTest();
    await dir.delete(recursive: true);
  });
}
