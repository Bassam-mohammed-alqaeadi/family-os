import 'dart:io';

import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/fs_foundation/fs_session_kernel.dart';
import 'package:family_os/core/fs_foundation/sqlite_local_database.dart';
import 'package:family_os/core/policy/schedule_window.dart';
import 'package:family_os/core/screen_time/screen_time_local_persistence.dart';

/// DOM-ST-02B — production ScheduleWindow path survives SQLite reopen.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() async {
    await FsSessionKernel.resetForTest();
  });

  test('openScheduleRepository write→close→reopen→read', () async {
    final dir = await Directory.systemTemp.createTemp('dom_st02b_');
    final path = p.join(dir.path, 'schedule.db');
    final child = ChildId('child_sched_prod');

    final windows = [
      const ScheduleWindow(
        kind: ScheduleKind.sleep,
        enabled: true,
        start: TimeOfDay(hour: 21, minute: 0),
        end: TimeOfDay(hour: 22, minute: 30),
      ),
      const ScheduleWindow(kind: ScheduleKind.prayer, enabled: false),
      const ScheduleWindow(
        kind: ScheduleKind.study,
        enabled: true,
        start: TimeOfDay(hour: 16, minute: 0),
        end: TimeOfDay(hour: 18, minute: 0),
      ),
    ];

    final db1 = await SqliteLocalDatabase.openAt(path);
    await FsSessionKernel.ensureOpen(override: db1);
    final repo1 = await ScreenTimeLocalPersistence.openScheduleRepository();
    await repo1.save(child, windows);
    await FsSessionKernel.resetForTest();

    final db2 = await SqliteLocalDatabase.openAt(path);
    await FsSessionKernel.ensureOpen(override: db2);
    final loaded =
        await (await ScreenTimeLocalPersistence.openScheduleRepository()).load(
          child,
        );

    expect(loaded.length, 3);
    final sleep = loaded.firstWhere((w) => w.kind == ScheduleKind.sleep);
    expect(sleep.enabled, isTrue);
    expect(ScheduleWindow.toMinutes(sleep.start), 21 * 60);
    expect(ScheduleWindow.toMinutes(sleep.end), 22 * 60 + 30);

    final prayer = loaded.firstWhere((w) => w.kind == ScheduleKind.prayer);
    expect(prayer.enabled, isFalse);

    final study = loaded.firstWhere((w) => w.kind == ScheduleKind.study);
    expect(study.enabled, isTrue);
    expect(ScheduleWindow.toMinutes(study.start), 16 * 60);
    expect(ScheduleWindow.toMinutes(study.end), 18 * 60);

    // Missing/default: fresh child → disabled stubs.
    final empty =
        await (await ScreenTimeLocalPersistence.openScheduleRepository()).load(
          ChildId('never_saved'),
        );
    expect(empty.every((w) => !w.enabled), isTrue);

    await FsSessionKernel.resetForTest();
    await dir.delete(recursive: true);
  });
}
