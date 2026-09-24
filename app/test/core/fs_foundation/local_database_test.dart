import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/fs_foundation/local_database.dart';
import 'package:family_os/core/fs_foundation/memory_local_database.dart';
import 'package:family_os/core/fs_foundation/mock_remote_adapter.dart';

void main() {
  late MemoryLocalDatabase db;

  setUp(() async {
    db = MemoryLocalDatabase();
    await db.open();
  });

  tearDown(() async {
    await db.close();
  });

  test('schema version is current after open', () async {
    expect(await db.schemaVersion(), FamilyLocalSchema.currentVersion);
  });

  test('kv_store replace upsert works', () async {
    await db.insert('kv_store', {
      'namespace': 'fs',
      'key': 'demo',
      'value': 'a',
      'updated_at': 1,
    });
    await db.insert('kv_store', {
      'namespace': 'fs',
      'key': 'demo',
      'value': 'b',
      'updated_at': 2,
    }, conflictAlgorithm: LocalConflictAlgorithm.replace);
    final rows = await db.query(
      'kv_store',
      where: 'namespace = ? AND key = ?',
      whereArgs: ['fs', 'demo'],
    );
    expect(rows.single['value'], 'b');
  });

  test('MockRemoteAdapter enqueue + flush delivers', () async {
    final remote = MockRemoteAdapter(
      db,
      clock: () => DateTime.utc(2026, 9, 24),
      idFactory: () => 'id-1',
    );
    await remote.enqueue(channel: 'fs001.events', payload: {'kind': 'ENTER'});
    expect((await remote.pending()).length, 1);
    final result = await remote.flush();
    expect(result.delivered, 1);
    expect(result.failed, 0);
    expect((await remote.pending()), isEmpty);
  });

  test('MockRemoteAdapter failChannels marks error', () async {
    final remote = MockRemoteAdapter(
      db,
      failChannels: {'fs002.cloud'},
      idFactory: () => 'id-fail',
    );
    await remote.enqueue(channel: 'fs002.cloud', payload: {'x': 1});
    final result = await remote.flush();
    expect(result.failed, 1);
    expect((await remote.pending()).length, 1);
    expect((await remote.pending()).single.lastError, contains('MOCK_REMOTE'));
  });
}
