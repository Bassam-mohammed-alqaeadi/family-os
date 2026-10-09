import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/fs_foundation/fs_session_kernel.dart';
import 'package:family_os/core/fs_foundation/sqlite_local_database.dart';
import 'package:family_os/core/policy/screen_time_policy.dart';
import 'package:family_os/core/screen_time/screen_time_runtime.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() async {
    ScreenTimeRuntime.resetForTest();
    await FsSessionKernel.resetForTest();
  });

  test(
    'ScreenTimeRuntime boot-once opens policy+schedule+timeRequest',
    () async {
      final dir = await Directory.systemTemp.createTemp('host_router_b_');
      final path = p.join(dir.path, 'st.db');
      final db = await SqliteLocalDatabase.openAt(path);
      await FsSessionKernel.ensureOpen(override: db);

      await ScreenTimeRuntime.ensureOpen();
      expect(ScreenTimeRuntime.isOpen, isTrue);
      expect(ScreenTimeRuntime.unavailable, isFalse);
      expect(ScreenTimeRuntime.policy, isNotNull);
      expect(ScreenTimeRuntime.schedule, isNotNull);
      expect(ScreenTimeRuntime.timeRequest, isNotNull);

      final p0 = ScreenTimeRuntime.policy;
      await ScreenTimeRuntime.ensureOpen();
      expect(identical(ScreenTimeRuntime.policy, p0), isTrue);

      ScreenTimeRuntime.resetForTest();
      await FsSessionKernel.resetForTest();
      await dir.delete(recursive: true);
    },
  );

  test('ScreenTimeRuntime policy write→close→reopen', () async {
    final dir = await Directory.systemTemp.createTemp('host_router_b_r_');
    final path = p.join(dir.path, 'st.db');
    final child = ChildId('demo-child');

    final db1 = await SqliteLocalDatabase.openAt(path);
    await FsSessionKernel.ensureOpen(override: db1);
    await ScreenTimeRuntime.ensureOpen();
    await ScreenTimeRuntime.policy!.save(
      child,
      ScreenTimePolicy.defaults().copyWith(dailyCapMinutes: 90),
    );
    ScreenTimeRuntime.resetForTest();
    await FsSessionKernel.resetForTest();

    final db2 = await SqliteLocalDatabase.openAt(path);
    await FsSessionKernel.ensureOpen(override: db2);
    await ScreenTimeRuntime.ensureOpen();
    final loaded = await ScreenTimeRuntime.policy!.load(child);
    expect(loaded.dailyCapMinutes, 90);

    ScreenTimeRuntime.resetForTest();
    await FsSessionKernel.resetForTest();
    await dir.delete(recursive: true);
  });
}
