import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/events/local_event_emitter.dart';
import 'package:family_os/core/events/local_event_journal.dart';
import 'package:family_os/core/fs_foundation/fs_session_kernel.dart';
import 'package:family_os/core/fs_foundation/memory_local_database.dart';
import 'package:family_os/core/fs_foundation/sqlite_local_database.dart';
import 'package:family_os/core/sos_final/sos_final_service.dart';
import 'package:family_os/core/sos_final/sos_final_store.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() async {
    await FsSessionKernel.resetForTest();
  });

  test('journal append→close→reopen→read', () async {
    final dir = await Directory.systemTemp.createTemp('evt01a_');
    final path = p.join(dir.path, 'evt.db');

    final db1 = await SqliteLocalDatabase.openAt(path);
    await FsSessionKernel.ensureOpen(override: db1);
    final emitter = await LocalEventPersistence.openEmitter();
    final id = await emitter.emit(
      channel: 'test.channel',
      payload: {'k': 'v'},
    );
    expect(id, isNotNull);
    await FsSessionKernel.resetForTest();

    final db2 = await SqliteLocalDatabase.openAt(path);
    await FsSessionKernel.ensureOpen(override: db2);
    final loaded = await LocalEventJournal(FsSessionKernel.db).load(id!);
    expect(loaded, isNotNull);
    expect(loaded!.channel, 'test.channel');
    expect(loaded.payload['k'], 'v');
    expect(loaded.toJson()['deliveryClaim'], 'queued_locally');

    final pending = await FsSessionKernel.remoteSyncPort.pending();
    expect(pending.where((e) => e.channel == 'test.channel'), isNotEmpty);

    await FsSessionKernel.resetForTest();
    await dir.delete(recursive: true);
  });

  test('openEmitter refuses sqliteFallbackToMemory', () async {
    await FsSessionKernel.resetForTest();
    await FsSessionKernel.ensureOpen(preferSqlite: true);
    if (FsSessionKernel.usingSqlite) {
      expect(FsSessionKernel.sqliteFallbackToMemory, isFalse);
      return;
    }
    expect(FsSessionKernel.sqliteFallbackToMemory, isTrue);
    expect(FsSessionKernel.db, isA<MemoryLocalDatabase>());
    await expectLater(
      LocalEventPersistence.openEmitter(),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('refuses SQLite→Memory'),
        ),
      ),
    );
  });

  test('SOS fireHold journals + enqueues without claiming delivery', () async {
    final dir = await Directory.systemTemp.createTemp('evt01a_sos_');
    final path = p.join(dir.path, 'sos.db');
    final db = await SqliteLocalDatabase.openAt(path);
    await FsSessionKernel.ensureOpen(override: db);

    final store = LocalSosFinalStore(FsSessionKernel.db);
    final emitter = LocalEventPersistence.emitter(FsSessionKernel.db);
    final svc = SosFinalService(
      store: store,
      familyId: FamilyId('fam_stage1'),
      localEvents: emitter,
    );
    final incident = await svc.fireHold(childId: ChildId('demo-child'));
    expect(incident.id, isNotEmpty);

    final recent = await LocalEventJournal(FsSessionKernel.db).listRecent();
    expect(
      recent.any((e) => e.channel == 'sos.lifecycle.fired'),
      isTrue,
    );
    final pending = await FsSessionKernel.remoteSyncPort.pending();
    final sosItems =
        pending.where((e) => e.channel == 'sos.lifecycle.fired').toList();
    expect(sosItems, isNotEmpty);
    expect(sosItems.first.deliveredAt, isNull);
    expect(sosItems.first.payload['deliveryClaim'], 'queued_locally');

    await FsSessionKernel.resetForTest();
    await dir.delete(recursive: true);
  });
}
