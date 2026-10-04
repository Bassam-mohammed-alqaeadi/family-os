import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/fs_foundation/fs_session_kernel.dart';
import 'package:family_os/core/fs_foundation/memory_local_database.dart';
import 'package:family_os/features/n02_day/location_ux_bridge.dart';
import 'package:family_os/features/n02_day/safe_zones_repository.dart';
import 'package:family_os/features/n03_screen_time/child_apps_real_local_seed_mock.dart';
import 'package:family_os/features/n03_screen_time/child_apps_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() async {
    Stage1LocationRuntime.resetForTest();
    rebindStage1SafeZonesRepository(InMemorySafeZonesRepository());
    rebindStage1ChildAppsRepository(InMemoryChildAppsRepository());
    await FsSessionKernel.resetForTest();
  });

  test('LDR-B2 managed app catalog has zero usedMins (no fake OS usage)', () {
    for (final app in ChildAppsRealLocalSeedMock.managedCatalog) {
      expect(app.usedMins, 0);
    }
    expect(ChildAppsRealLocalSeedMock.managedCatalog, isNotEmpty);
  });

  test('LDR-B2 safe zone seed writes two definitions without trails', () async {
    await FsSessionKernel.ensureOpen(override: MemoryLocalDatabase());
    await Stage1LocationRuntime.ensureOpen();
    final domain = Stage1LocationRuntime.store;
    final familyId = FamilyId('fam_stage1');
    await ensureRealLocalSafeZonesSeeded(domain: domain, familyId: familyId);
    final zones = await domain.listZones(familyId);
    expect(zones.length, 2);
    expect(zones.map((z) => z.name), containsAll(['المنزل', 'المدرسة']));
    final trail = await domain.listTrail(
      familyId,
      ChildId('demo-child'),
      limit: 10,
    );
    expect(trail, isEmpty);
    await ensureRealLocalSafeZonesSeeded(domain: domain, familyId: familyId);
    expect((await domain.listZones(familyId)).length, 2);
  });

  test('LDR-B2 child apps seed via InMemory with managed catalog', () {
    final repo = InMemoryChildAppsRepository(
      seed: ChildAppsRealLocalSeedMock.forChildren([ChildId('demo-child')]),
    );
    final apps = repo.appsFor(ChildId('demo-child'));
    expect(apps.length, ChildAppsRealLocalSeedMock.managedCatalog.length);
    expect(apps.every((a) => a.usedMins == 0), isTrue);
  });
}
