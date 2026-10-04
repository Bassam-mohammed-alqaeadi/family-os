import 'package:flutter_test/flutter_test.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/fs_foundation/fs_session_kernel.dart';
import 'package:family_os/core/fs_foundation/memory_local_database.dart';
import 'package:family_os/core/policy/advisor_repository.dart';
import 'package:family_os/features/n02_day/children_list_local_repository.dart';
import 'package:family_os/features/n02_day/children_list_local_seed_mock.dart';
import 'package:family_os/features/n02_day/children_list_repository.dart';
import 'package:family_os/features/n02_day/location_map_repository.dart';
import 'package:family_os/features/n02_day/location_ux_bridge.dart';
import 'package:family_os/features/quran/quran_local_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() async {
    Stage1LocationRuntime.resetForTest();
    QuranLocalPersistence.resetForTest();
    rebindStage1AdvisorRepository(const EmptyAdvisorRepository());
    rebindStage1LocationMapRepository(InMemoryLocationMapRepository());
    await FsSessionKernel.resetForTest();
  });

  test('LDR-B1 roster seed has identity fields only (no fake GPS/battery)', () {
    for (final c in ChildrenListLocalSeedMock.famStage1Children) {
      expect(c.displayName, isNotEmpty);
      expect(c.locationLabel, isEmpty);
      expect(c.batteryLabel, isEmpty);
      expect(c.lastSeenLabel, isEmpty);
      expect(c.warnRing, isFalse);
    }
  });

  test('LDR-B1 EmptyAdvisor returns no planted suggestions', () async {
    final list = await const EmptyAdvisorRepository().suggestions();
    expect(list, isEmpty);
    expect(stage1AdvisorRepository, isA<EmptyAdvisorRepository>());
  });

  test(
    'LDR-B1 LocalChildrenListRepository seeds REAL_LOCAL provenance',
    () async {
      final db = MemoryLocalDatabase();
      await db.open();
      final repo = LocalChildrenListRepository(db);
      final kids = await repo.listChildren(
        familyId: ChildrenListLocalSeed.famStage1,
      );
      expect(kids, isNotEmpty);
      expect(kids.first.locationLabel, isEmpty);
      final prov = await repo.loadProvenance(
        familyId: ChildrenListLocalSeed.famStage1,
      );
      expect(prov, kChildrenListRealLocalProvenance);
      expect(isChildrenListSeededProvenance(prov), isTrue);
    },
  );

  test(
    'LDR-B1 DomainLocationMapRepository pins from roster without trails',
    () async {
      await FsSessionKernel.ensureOpen(
        preferSqlite: false,
        override: MemoryLocalDatabase(),
      );
      await Stage1LocationRuntime.ensureOpen();
      final domain = Stage1LocationRuntime.store;
      final map = DomainLocationMapRepository(
        domain: domain,
        familyId: FamilyId('fam_stage1'),
        children: InMemoryChildrenListRepository(
          byFamily: {'fam_stage1': ChildrenListLocalSeedMock.famStage1Children},
        ),
      );
      final snap = await map.load();
      expect(snap, isNotNull);
      expect(snap!.pins.length, 2);
      expect(snap.pins.first.locationLabel, isEmpty);
      expect(snap.threadStops, isEmpty);
    },
  );

  test('LDR-B1 QuranLocalBridgeStore round-trips offlineReady', () async {
    final db = MemoryLocalDatabase();
    await db.open();
    final store = LocalQuranBridgeStore(db);
    final bridge = QuranLocalBridge()..markOfflineReady();
    await store.persist(bridge);
    final loaded = QuranLocalBridge();
    await store.hydrate(loaded);
    expect(loaded.offlineReady, isTrue);
  });
}
