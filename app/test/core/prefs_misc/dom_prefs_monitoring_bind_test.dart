import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:family_os/core/fs_foundation/fs_session_kernel.dart';
import 'package:family_os/core/fs_foundation/memory_local_database.dart';
import 'package:family_os/core/fs_foundation/sqlite_local_database.dart';
import 'package:family_os/core/policy/desired_monitoring_prefs.dart';
import 'package:family_os/core/prefs_misc/prefs_misc_local_persistence.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() async {
    await FsSessionKernel.resetForTest();
  });

  test('desired monitoring write→close→reopen→read', () async {
    final dir = await Directory.systemTemp.createTemp('dom_prefs_mon_');
    final path = p.join(dir.path, 'mon.db');

    final db1 = await SqliteLocalDatabase.openAt(path);
    await FsSessionKernel.ensureOpen(override: db1);
    final repo1 = await PrefsMiscLocalPersistence.openMonitoringRepository();
    final prefs = DesiredMonitoringPrefs.defaults(
      childId: 'demo-child',
    ).copyWith(webFilter: true, locationAlways: true);
    await repo1.save(prefs);
    await FsSessionKernel.resetForTest();

    final db2 = await SqliteLocalDatabase.openAt(path);
    await FsSessionKernel.ensureOpen(override: db2);
    final loaded =
        await (await PrefsMiscLocalPersistence.openMonitoringRepository()).load(
          'demo-child',
        );
    expect(loaded.webFilter, isTrue);
    expect(loaded.locationAlways, isTrue);
    expect(loaded.appLimits, isFalse);

    await FsSessionKernel.resetForTest();
    await dir.delete(recursive: true);
  });

  test('openMonitoringRepository refuses sqliteFallbackToMemory', () async {
    await FsSessionKernel.resetForTest();
    await FsSessionKernel.ensureOpen(preferSqlite: true);
    if (FsSessionKernel.usingSqlite) {
      expect(FsSessionKernel.sqliteFallbackToMemory, isFalse);
      return;
    }
    expect(FsSessionKernel.sqliteFallbackToMemory, isTrue);
    expect(FsSessionKernel.db, isA<MemoryLocalDatabase>());
    await expectLater(
      PrefsMiscLocalPersistence.openMonitoringRepository(),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('refuses SQLite→Memory'),
        ),
      ),
    );
  });

  test('DesiredMonitoring Local path is prefs not native telemetry', () async {
    final dir = await Directory.systemTemp.createTemp('dom_prefs_mon_h_');
    final path = p.join(dir.path, 'mon.db');
    final db = await SqliteLocalDatabase.openAt(path);
    await FsSessionKernel.ensureOpen(override: db);
    final repo = await PrefsMiscLocalPersistence.openMonitoringRepository();
    final prefs = DesiredMonitoringPrefs.defaults(
      childId: 'demo-child',
    ).copyWith(notificationListen: true);
    await repo.save(prefs);
    final json = (await repo.load('demo-child')).toJson();
    expect(json.containsKey('nativeGranted'), isFalse);
    expect(json.containsKey('osEnforced'), isFalse);
    expect(json['notificationListen'], isTrue);
    await FsSessionKernel.resetForTest();
    await dir.delete(recursive: true);
  });
}
