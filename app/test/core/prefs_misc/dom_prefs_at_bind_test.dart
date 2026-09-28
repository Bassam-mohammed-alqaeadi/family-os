import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/fs_foundation/fs_session_kernel.dart';
import 'package:family_os/core/fs_foundation/memory_local_database.dart';
import 'package:family_os/core/fs_foundation/sqlite_local_database.dart';
import 'package:family_os/core/policy/anti_tamper_policy.dart';
import 'package:family_os/core/policy/anti_tamper_repository.dart';
import 'package:family_os/core/prefs_misc/prefs_misc_local_persistence.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() async {
    await FsSessionKernel.resetForTest();
  });

  test('anti-tamper prefs write→close→reopen→read', () async {
    final dir = await Directory.systemTemp.createTemp('dom_prefs_at_');
    final path = p.join(dir.path, 'at.db');
    final child = ChildId('demo-child');

    final db1 = await SqliteLocalDatabase.openAt(path);
    await FsSessionKernel.ensureOpen(override: db1);
    final repo1 = await PrefsMiscLocalPersistence.openAntiTamperRepository();
    final policy = AntiTamperPolicy.defaults().copyWith(
      noVpn: true,
      bypassAlert: true,
    );
    final result = await repo1.write(child, policy, actor: AppRole.father);
    expect(result, isA<AntiTamperWriteOk>());
    await FsSessionKernel.resetForTest();

    final db2 = await SqliteLocalDatabase.openAt(path);
    await FsSessionKernel.ensureOpen(override: db2);
    final loaded =
        await (await PrefsMiscLocalPersistence.openAntiTamperRepository())
            .load(child);
    expect(loaded.noVpn, isTrue);
    expect(loaded.bypassAlert, isTrue);

    await FsSessionKernel.resetForTest();
    await dir.delete(recursive: true);
  });

  test('openAntiTamperRepository refuses sqliteFallbackToMemory', () async {
    await FsSessionKernel.resetForTest();
    await FsSessionKernel.ensureOpen(preferSqlite: true);
    if (FsSessionKernel.usingSqlite) {
      expect(FsSessionKernel.sqliteFallbackToMemory, isFalse);
      return;
    }
    expect(FsSessionKernel.sqliteFallbackToMemory, isTrue);
    expect(FsSessionKernel.db, isA<MemoryLocalDatabase>());
    await expectLater(
      PrefsMiscLocalPersistence.openAntiTamperRepository(),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('refuses SQLite→Memory'),
        ),
      ),
    );
  });

  test('AT Local path does not claim native Device Admin enforcement', () async {
    // Honesty: PrefsAntiTamperRepository persists JSON policy only —
    // deviceAdminGranted remains a screen seam, not OS telemetry.
    final dir = await Directory.systemTemp.createTemp('dom_prefs_at_h_');
    final path = p.join(dir.path, 'at.db');
    final db = await SqliteLocalDatabase.openAt(path);
    await FsSessionKernel.ensureOpen(override: db);
    final repo = await PrefsMiscLocalPersistence.openAntiTamperRepository();
    final saved = await repo.write(
      ChildId('demo-child'),
      AntiTamperPolicy.defaults().copyWith(noDelete: true),
      actor: AppRole.father,
    );
    expect(saved, isA<AntiTamperWriteOk>());
    final policy = (saved as AntiTamperWriteOk).policy;
    expect(policy.noDelete, isTrue);
    // No native provenance field — policy is durable Prefs, not OS grant proof.
    expect(policy.toJson().containsKey('deviceAdminGranted'), isFalse);
    await FsSessionKernel.resetForTest();
    await dir.delete(recursive: true);
  });
}
