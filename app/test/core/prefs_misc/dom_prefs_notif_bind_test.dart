import 'dart:io';

import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:family_os/core/fs_foundation/fs_session_kernel.dart';
import 'package:family_os/core/fs_foundation/memory_local_database.dart';
import 'package:family_os/core/fs_foundation/sqlite_local_database.dart';
import 'package:family_os/core/policy/notification_prefs.dart';
import 'package:family_os/core/prefs_misc/prefs_misc_local_persistence.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() async {
    await FsSessionKernel.resetForTest();
  });

  test('notification prefs write→close→reopen→read', () async {
    final dir = await Directory.systemTemp.createTemp('dom_prefs_notif_');
    final path = p.join(dir.path, 'notif.db');

    final db1 = await SqliteLocalDatabase.openAt(path);
    await FsSessionKernel.ensureOpen(override: db1);
    final repo1 = await PrefsMiscLocalPersistence.openNotificationRepository();
    await repo1.save(
      NotificationPrefs(
        memberId: 'father',
        quietHoursEnabled: true,
        quietStart: const TimeOfDay(hour: 22, minute: 0),
        quietEnd: const TimeOfDay(hour: 7, minute: 0),
        analysisNoticesEnabled: false,
      ),
    );
    await FsSessionKernel.resetForTest();

    final db2 = await SqliteLocalDatabase.openAt(path);
    await FsSessionKernel.ensureOpen(override: db2);
    final loaded =
        await (await PrefsMiscLocalPersistence.openNotificationRepository())
            .load('father');
    expect(loaded.quietHoursEnabled, isTrue);
    expect(loaded.analysisNoticesEnabled, isFalse);
    expect(loaded.quietStart, const TimeOfDay(hour: 22, minute: 0));

    await FsSessionKernel.resetForTest();
    await dir.delete(recursive: true);
  });

  test('openNotificationRepository refuses sqliteFallbackToMemory', () async {
    await FsSessionKernel.resetForTest();
    await FsSessionKernel.ensureOpen(preferSqlite: true);
    if (FsSessionKernel.usingSqlite) {
      expect(FsSessionKernel.sqliteFallbackToMemory, isFalse);
      return;
    }
    expect(FsSessionKernel.sqliteFallbackToMemory, isTrue);
    expect(FsSessionKernel.db, isA<MemoryLocalDatabase>());
    await expectLater(
      PrefsMiscLocalPersistence.openNotificationRepository(),
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
