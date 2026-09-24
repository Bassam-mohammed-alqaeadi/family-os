import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/fs_foundation/fs_session_kernel.dart';
import 'package:family_os/core/fs_foundation/local_database.dart';
import 'package:family_os/core/fs_foundation/memory_local_database.dart';
import 'package:family_os/core/fs_foundation/sqlite_local_database.dart';
import 'package:family_os/core/location/geo_point.dart';
import 'package:family_os/core/location/location_store.dart';
import 'package:family_os/core/location/safe_zone_definition.dart';
import 'package:family_os/core/location/zone_geometry.dart';

/// STOR-01 — prove real SQLite write → close → reopen → read.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() async {
    await FsSessionKernel.resetForTest();
  });

  test('STOR-01 product zone survives SQLite reopen', () async {
    final dir = await Directory.systemTemp.createTemp('fs_stor01_');
    final path = p.join(dir.path, 'restart.db');
    final family = FamilyId('fam_stor01');
    final child = ChildId('child_a');
    final now = DateTime.utc(2026, 9, 24, 18);

    final db1 = await SqliteLocalDatabase.openAt(path);
    expect(await db1.schemaVersion(), FamilyLocalSchema.currentVersion);
    final store1 = LocalLocationStore(db1, clock: () => now);
    await store1.saveZone(
      SafeZoneDefinition(
        id: 'zone_home',
        familyId: family,
        name: 'Home',
        emoji: '🏠',
        geometry: const CircleGeometry(
          center: GeoPoint(latitude: 24.7136, longitude: 46.6753),
          radiusMeters: 150,
        ),
        assignedChildIds: [child],
        createdAt: now,
        updatedAt: now,
      ),
    );
    await db1.close();

    final db2 = await SqliteLocalDatabase.openAt(path);
    final store2 = LocalLocationStore(db2);
    final loaded = await store2.getZone('zone_home');
    expect(loaded, isNotNull);
    expect(loaded!.name, 'Home');
    expect(loaded.familyId, family);
    expect(loaded.assignedChildIds, [child]);
    expect(loaded.geometry, isA<CircleGeometry>());
    final circle = loaded.geometry as CircleGeometry;
    expect(circle.radiusMeters, 150);

    await db2.close();
    await dir.delete(recursive: true);
  });

  test('STOR-01 kv_store survives SQLite reopen', () async {
    final dir = await Directory.systemTemp.createTemp('fs_stor01_kv_');
    final path = p.join(dir.path, 'kv.db');

    final db1 = await SqliteLocalDatabase.openAt(path);
    await db1.insert('kv_store', {
      'namespace': 'stor01',
      'key': 'marker',
      'value': 'alive',
      'updated_at': 1,
    });
    await db1.close();

    final db2 = await SqliteLocalDatabase.openAt(path);
    final rows = await db2.query(
      'kv_store',
      where: 'namespace = ? AND key = ?',
      whereArgs: const ['stor01', 'marker'],
    );
    expect(rows.single['value'], 'alive');
    await db2.close();
    await dir.delete(recursive: true);
  });

  test('STOR-01 intentional Memory is not claimed as SQLite fallback', () async {
    await FsSessionKernel.resetForTest();
    await FsSessionKernel.ensureOpen(preferSqlite: false);
    expect(FsSessionKernel.usingSqlite, isFalse);
    expect(FsSessionKernel.sqliteFallbackToMemory, isFalse);
    expect(FsSessionKernel.db, isA<MemoryLocalDatabase>());
  });

  test('STOR-01 preferSqlite open failure is honest Memory fallback', () async {
    await FsSessionKernel.resetForTest();
    // Forced preferSqlite: under unit test, openDefault often fails without
    // path_provider → Memory + sqliteFallbackToMemory (honest DEGRADED).
    await FsSessionKernel.ensureOpen(preferSqlite: true);
    if (FsSessionKernel.usingSqlite) {
      expect(FsSessionKernel.sqliteFallbackToMemory, isFalse);
      expect(FsSessionKernel.db, isA<SqliteLocalDatabase>());
    } else {
      expect(FsSessionKernel.sqliteFallbackToMemory, isTrue);
      expect(FsSessionKernel.db, isA<MemoryLocalDatabase>());
    }
  });

  test('STOR-01 override Sqlite does not set fallback flag', () async {
    await FsSessionKernel.resetForTest();
    final dir = await Directory.systemTemp.createTemp('fs_stor01_ov_');
    final path = p.join(dir.path, 'ov.db');
    final db = await SqliteLocalDatabase.openAt(path);
    await FsSessionKernel.ensureOpen(override: db);
    expect(FsSessionKernel.usingSqlite, isTrue);
    expect(FsSessionKernel.sqliteFallbackToMemory, isFalse);
    await FsSessionKernel.resetForTest();
    await dir.delete(recursive: true);
  });
}
