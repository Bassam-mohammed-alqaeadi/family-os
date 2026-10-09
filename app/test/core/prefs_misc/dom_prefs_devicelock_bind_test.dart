import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/fs_foundation/fs_session_kernel.dart';
import 'package:family_os/core/fs_foundation/memory_local_database.dart';
import 'package:family_os/core/fs_foundation/sqlite_local_database.dart';
import 'package:family_os/core/policy/device_lock_service.dart';
import 'package:family_os/core/policy/device_lock_state.dart';
import 'package:family_os/core/prefs_misc/prefs_misc_local_persistence.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() async {
    await FsSessionKernel.resetForTest();
  });

  test('device lock write→close→reopen→read', () async {
    final dir = await Directory.systemTemp.createTemp('dom_prefs_dl_');
    final path = p.join(dir.path, 'dl.db');
    final child = ChildId('demo-child');

    final db1 = await SqliteLocalDatabase.openAt(path);
    await FsSessionKernel.ensureOpen(override: db1);
    final svc1 = await PrefsMiscLocalPersistence.openDeviceLockService();
    final result = await svc1.lock(child, const DeviceLockActor.father());
    expect(result, isA<DeviceLockCommandOk>());
    expect((result as DeviceLockCommandOk).state.locked, isTrue);
    await FsSessionKernel.resetForTest();

    final db2 = await SqliteLocalDatabase.openAt(path);
    await FsSessionKernel.ensureOpen(override: db2);
    final loaded =
        await (await PrefsMiscLocalPersistence.openDeviceLockService()).load(
          child,
        );
    expect(loaded.locked, isTrue);
    expect(loaded.lockedBy, DeviceLockedBy.father);

    await FsSessionKernel.resetForTest();
    await dir.delete(recursive: true);
  });

  test('openDeviceLockService refuses sqliteFallbackToMemory', () async {
    await FsSessionKernel.resetForTest();
    await FsSessionKernel.ensureOpen(preferSqlite: true);
    if (FsSessionKernel.usingSqlite) {
      expect(FsSessionKernel.sqliteFallbackToMemory, isFalse);
      return;
    }
    expect(FsSessionKernel.sqliteFallbackToMemory, isTrue);
    expect(FsSessionKernel.db, isA<MemoryLocalDatabase>());
    await expectLater(
      PrefsMiscLocalPersistence.openDeviceLockService(),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('refuses SQLite→Memory'),
        ),
      ),
    );
  });

  test('DeviceLock Local path does not claim OS Device Admin', () async {
    final dir = await Directory.systemTemp.createTemp('dom_prefs_dl_h_');
    final path = p.join(dir.path, 'dl.db');
    final db = await SqliteLocalDatabase.openAt(path);
    await FsSessionKernel.ensureOpen(override: db);
    final svc = await PrefsMiscLocalPersistence.openDeviceLockService();
    final ok = await svc.lock(
      ChildId('demo-child'),
      const DeviceLockActor.father(),
    );
    expect(ok, isA<DeviceLockCommandOk>());
    final json = (ok as DeviceLockCommandOk).state.toJson();
    expect(json.containsKey('deviceAdminGranted'), isFalse);
    expect(json.containsKey('osEnforced'), isFalse);
    await FsSessionKernel.resetForTest();
    await dir.delete(recursive: true);
  });
}
