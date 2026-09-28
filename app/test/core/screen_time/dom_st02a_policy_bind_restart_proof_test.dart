import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/minutes.dart';
import 'package:family_os/core/fs_foundation/fs_session_kernel.dart';
import 'package:family_os/core/fs_foundation/sqlite_local_database.dart';
import 'package:family_os/core/policy/screen_time_policy.dart';
import 'package:family_os/core/screen_time/screen_time_local_persistence.dart';

/// DOM-ST-02A — production policy repository path survives SQLite reopen.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() async {
    await FsSessionKernel.resetForTest();
  });

  test('openPolicyRepository write→close→reopen→read', () async {
    final dir = await Directory.systemTemp.createTemp('dom_st02a_');
    final path = p.join(dir.path, 'policy.db');
    final child = ChildId('child_prod');

    final db1 = await SqliteLocalDatabase.openAt(path);
    await FsSessionKernel.ensureOpen(override: db1);
    final repo1 = await ScreenTimeLocalPersistence.openPolicyRepository();
    await repo1.save(
      child,
      ScreenTimePolicy(
        dailyCapMinutes: 88,
        allowWalletOverflow: true,
        usedMinutesToday: 3,
        wallets: [
          AppWallet(appId: 'games', earnedMinutes: Minutes(10)),
        ],
      ),
    );
    await FsSessionKernel.resetForTest();

    final db2 = await SqliteLocalDatabase.openAt(path);
    await FsSessionKernel.ensureOpen(override: db2);
    final repo2 = await ScreenTimeLocalPersistence.openPolicyRepository();
    final loaded = await repo2.load(child);
    expect(loaded.dailyCapMinutes, 88);
    expect(loaded.allowWalletOverflow, isTrue);
    expect(loaded.usedMinutesToday, 3);
    expect(loaded.wallets.single.earnedMinutes.inMinutes, 10);

    await FsSessionKernel.resetForTest();
    await dir.delete(recursive: true);
  });
}
