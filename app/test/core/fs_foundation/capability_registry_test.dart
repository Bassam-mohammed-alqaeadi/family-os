import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/fs_foundation/capability_registry.dart';
import 'package:family_os/core/fs_foundation/capability_status.dart';
import 'package:family_os/core/fs_foundation/memory_local_database.dart';

void main() {
  late MemoryLocalDatabase db;
  late CapabilityRegistry registry;

  setUp(() async {
    db = MemoryLocalDatabase();
    await db.open();
    registry = CapabilityRegistry(
      db,
      clock: () => DateTime.utc(2026, 9, 24, 12),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('ensureSeeded writes FS-A…FS-007 baseline rows once', () async {
    await registry.ensureSeeded();
    final all = await registry.listAll();
    expect(all, isNotEmpty);
    expect(all.any((e) => e.id == 'fs_a.sqlite_kernel'), isTrue);
    expect(all.any((e) => e.systemId == 'FS-007'), isTrue);

    final count = all.length;
    await registry.ensureSeeded();
    expect((await registry.listAll()).length, count);
  });

  test('setStatus upgrades honesty and persists', () async {
    await registry.ensureSeeded();
    final updated = await registry.setStatus(
      'fs001.location_domain',
      CapabilityStatus.implemented,
      note: 'FS-001-DOM landed',
    );
    expect(updated.status, CapabilityStatus.implemented);
    expect(updated.note, 'FS-001-DOM landed');

    final loaded = await registry.get('fs001.location_domain');
    expect(loaded?.status, CapabilityStatus.implemented);
  });

  test('wire parse round-trips MOCK-REMOTE', () {
    expect(
      CapabilityStatusWire.parse('MOCK-REMOTE'),
      CapabilityStatus.mockRemote,
    );
    expect(CapabilityStatus.mockRemote.wireName, 'MOCK-REMOTE');
  });

  test('listBySystem filters FS-006', () async {
    await registry.ensureSeeded();
    final sos = await registry.listBySystem('FS-006');
    expect(sos, isNotEmpty);
    expect(sos.every((e) => e.systemId == 'FS-006'), isTrue);
  });
}
