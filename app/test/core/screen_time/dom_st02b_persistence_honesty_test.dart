import 'dart:io';

import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/fs_foundation/fs_session_kernel.dart';
import 'package:family_os/core/fs_foundation/memory_local_database.dart';
import 'package:family_os/core/fs_foundation/sqlite_local_database.dart';
import 'package:family_os/core/policy/schedule_window.dart';
import 'package:family_os/core/screen_time/screen_time_local_persistence.dart';

/// DOM-ST-02B — ScheduleWindow must not bind when SQLite fell back to Memory.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() async {
    await FsSessionKernel.resetForTest();
  });

  test('openScheduleRepository refuses sqliteFallbackToMemory', () async {
    await FsSessionKernel.resetForTest();
    await FsSessionKernel.ensureOpen(preferSqlite: true);
    if (FsSessionKernel.usingSqlite) {
      expect(FsSessionKernel.sqliteFallbackToMemory, isFalse);
      return;
    }
    expect(FsSessionKernel.sqliteFallbackToMemory, isTrue);
    expect(FsSessionKernel.db, isA<MemoryLocalDatabase>());
    await expectLater(
      ScreenTimeLocalPersistence.openScheduleRepository(),
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
    'intentional test Memory (no fallback flag) still opens schedule repo',
    () async {
      await FsSessionKernel.resetForTest();
      await FsSessionKernel.ensureOpen(preferSqlite: false);
      expect(FsSessionKernel.sqliteFallbackToMemory, isFalse);
      expect(FsSessionKernel.usingSqlite, isFalse);
      final repo = await ScreenTimeLocalPersistence.openScheduleRepository();
      final child = ChildId('t_sched');
      await repo.save(child, [
        const ScheduleWindow(
          kind: ScheduleKind.sleep,
          enabled: true,
          start: TimeOfDay(hour: 21, minute: 0),
          end: TimeOfDay(hour: 22, minute: 0),
        ),
        const ScheduleWindow(kind: ScheduleKind.prayer, enabled: false),
        const ScheduleWindow(kind: ScheduleKind.study, enabled: false),
      ]);
      final loaded = await repo.load(child);
      expect(
        loaded.firstWhere((w) => w.kind == ScheduleKind.sleep).enabled,
        isTrue,
      );
    },
  );

  test('healthy SQLite openScheduleRepository still restart-safe', () async {
    final dir = await Directory.systemTemp.createTemp('dom_st02b_ok_');
    final path = p.join(dir.path, 'ok.db');
    final child = ChildId('c_sched_ok');

    final db1 = await SqliteLocalDatabase.openAt(path);
    await FsSessionKernel.ensureOpen(override: db1);
    expect(FsSessionKernel.sqliteFallbackToMemory, isFalse);
    expect(FsSessionKernel.usingSqlite, isTrue);
    final repo1 = await ScreenTimeLocalPersistence.openScheduleRepository();
    await repo1.save(child, [
      const ScheduleWindow(
        kind: ScheduleKind.study,
        enabled: true,
        start: TimeOfDay(hour: 15, minute: 0),
        end: TimeOfDay(hour: 17, minute: 0),
      ),
      const ScheduleWindow(kind: ScheduleKind.sleep, enabled: false),
      const ScheduleWindow(kind: ScheduleKind.prayer, enabled: false),
    ]);
    await FsSessionKernel.resetForTest();

    final db2 = await SqliteLocalDatabase.openAt(path);
    await FsSessionKernel.ensureOpen(override: db2);
    final loaded =
        await (await ScreenTimeLocalPersistence.openScheduleRepository())
            .load(child);
    final study = loaded.firstWhere((w) => w.kind == ScheduleKind.study);
    expect(study.enabled, isTrue);
    expect(ScheduleWindow.toMinutes(study.start), 15 * 60);
    expect(ScheduleWindow.toMinutes(study.end), 17 * 60);

    await FsSessionKernel.resetForTest();
    await dir.delete(recursive: true);
  });
}
