import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/fs_foundation/fs_session_kernel.dart';
import 'package:family_os/core/fs_foundation/sqlite_local_database.dart';
import 'package:family_os/core/policy/sos_ladder.dart';
import 'package:family_os/core/policy/web_unlock_request.dart';
import 'package:family_os/core/sos_final/sos_prefs_local_persistence.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() async {
    SosPrefsRuntime.resetForTest();
    await FsSessionKernel.resetForTest();
  });

  test('SOS settings+ladder+unlock queue survive restart', () async {
    final dir = await Directory.systemTemp.createTemp('sos_prefs_');
    final path = p.join(dir.path, 'sos.db');

    final db1 = await SqliteLocalDatabase.openAt(path);
    await FsSessionKernel.ensureOpen(override: db1);
    await SosPrefsRuntime.ensureOpen();

    SosPrefsRuntime.settings!.setPanicQuietPreferred(true);
    await Future<void>.delayed(const Duration(milliseconds: 80));

    await SosPrefsRuntime.ladder!.save(SosLadder.defaults());

    await SosPrefsRuntime.webUnlockRequests!.save(
      WebUnlockRequest(
        id: 'req_1',
        childId: ChildId('demo-child'),
        url: 'https://example.com',
        status: WebUnlockRequestStatus.pending,
        createdAt: DateTime.utc(2026, 9, 25),
      ),
    );

    SosPrefsRuntime.resetForTest();
    await FsSessionKernel.resetForTest();

    final db2 = await SqliteLocalDatabase.openAt(path);
    await FsSessionKernel.ensureOpen(override: db2);
    await SosPrefsRuntime.ensureOpen();

    expect(SosPrefsRuntime.settings!.settings.panicQuietPreferred, isTrue);
    final loadedLadder = await SosPrefsRuntime.ladder!.load();
    expect(loadedLadder.familyId, SosLadder.defaultFamilyId);
    final unlocks = await SosPrefsRuntime.webUnlockRequests!.loadAll();
    expect(unlocks.any((r) => r.id == 'req_1'), isTrue);

    SosPrefsRuntime.resetForTest();
    await FsSessionKernel.resetForTest();
    await dir.delete(recursive: true);
  });
}
