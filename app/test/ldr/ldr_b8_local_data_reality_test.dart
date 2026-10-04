import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/fs_foundation/fs_session_kernel.dart';
import 'package:family_os/core/fs_foundation/memory_local_database.dart';
import 'package:family_os/features/n02_day/children_list_local_repository.dart';
import 'package:family_os/features/n02_day/children_list_repository.dart';
import 'package:family_os/features/n02_day/child_profile_repository.dart';
import 'package:family_os/features/n02_day/day_board_projection.dart';
import 'package:family_os/features/n02_day/family_chat_local_store.dart';
import 'package:family_os/features/n02_day/location_map_repository.dart';
import 'package:family_os/features/n02_day/location_ux_bridge.dart';
import 'package:family_os/features/n16_tasks/family_tasks_local_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() async {
    Stage1LocationRuntime.resetForTest();
    rebindStage1ChildrenListRepository(InMemoryChildrenListRepository());
    rebindStage1LocationMapRepository(InMemoryLocationMapRepository());
    rebindStage1ChildProfileRepository(InMemoryChildProfileRepository());
    await FsSessionKernel.resetForTest();
  });

  test(
    'LDR-B8 cross-screen: roster child IDs align map/profile/zones/tasks/chat',
    () async {
      final db = MemoryLocalDatabase();
      await db.open();
      final familyId = ChildrenListLocalSeed.famStage1;

      final roster = LocalChildrenListRepository(db);
      final kids = await roster.listChildren(familyId: familyId);
      expect(kids.length, 2);
      final rosterIds = {for (final k in kids) k.id};
      expect(rosterIds, containsAll(<String>['demo-child', 'child_b']));

      rebindStage1ChildrenListRepository(roster);
      rebindStage1ChildProfileRepository(
        InMemoryChildProfileRepository(childrenList: roster),
      );

      for (final id in rosterIds) {
        final profile = await stage1ChildProfileRepository.loadById(
          id,
          familyId: familyId,
        );
        expect(profile, isNotNull);
        expect(profile!.id, id);
      }

      await FsSessionKernel.ensureOpen(preferSqlite: false, override: db);
      await Stage1LocationRuntime.ensureOpen();
      await ensureRealLocalSafeZonesSeeded(
        domain: Stage1LocationRuntime.store,
        familyId: familyId,
      );
      final zones = await Stage1LocationRuntime.store.listZones(familyId);
      expect(zones, isNotEmpty);
      for (final z in zones) {
        for (final c in z.assignedChildIds) {
          expect(rosterIds.contains(c.value), isTrue);
        }
      }

      final map = DomainLocationMapRepository(
        domain: Stage1LocationRuntime.store,
        familyId: familyId,
        children: roster,
      );
      final mapSnap = await map.load();
      expect(mapSnap, isNotNull);
      expect({for (final p in mapSnap!.pins) p.id}, rosterIds);

      final tasks = LocalFamilyTasksRepository(db);
      await tasks.ensureRealLocalSeeded();
      final taskSnap = await tasks.load();
      expect(taskSnap.childTasks.length, 2);
      expect({
        for (final t in taskSnap.childTasks) t.assigneeNameKey,
      }, containsAll(<String>['childOne', 'childTwo']));

      final chat = FamilyChatLocalStore(db);
      await chat.ensureRealLocalSampleMessages(familyId: familyId);
      final detail = await chat.loadDetail(
        FamilyChatLocalStore.familyChatWith,
        familyId: familyId,
      );
      expect(detail, isNotNull);
      expect(detail!.messages, isNotEmpty);

      final board = RosterDayBoardProjectionRepository(
        children: roster,
        familyId: () => familyId,
      );
      final boardSnap = await board.load();
      expect({for (final c in boardSnap.children) c.id}, rosterIds);
    },
  );

  test('LDR-B8 family identity keys stay stable for Stage-1', () {
    expect(ChildId('demo-child').value, 'demo-child');
    expect(ChildId('child_b').value, 'child_b');
    expect(FamilyId('fam_stage1').value, 'fam_stage1');
  });
}
