import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/fs_foundation/fs_session_kernel.dart';
import 'package:family_os/core/fs_foundation/memory_local_database.dart';
import 'package:family_os/core/screen_time/screen_time_runtime.dart';
import 'package:family_os/core/screen_time/stage1_time_request_runtime.dart';
import 'package:family_os/features/n02_day/children_list_local_seed_mock.dart';
import 'package:family_os/features/n02_day/children_list_repository.dart';
import 'package:family_os/features/n02_day/day_board_projection.dart';
import 'package:family_os/features/n02_day/outer_circle_local_repository.dart';
import 'package:family_os/features/n02_day/outer_circle_repository.dart';
import 'package:family_os/features/n03_screen_time/child_time_request_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() async {
    ScreenTimeRuntime.resetForTest();
    await FsSessionKernel.resetForTest();
  });

  test(
    'LDR-B4 ScreenTimeRuntime rebinds stage1 to Local KV + seeds pending',
    () async {
      await FsSessionKernel.ensureOpen(override: MemoryLocalDatabase());
      await ScreenTimeRuntime.ensureOpen();
      expect(ScreenTimeRuntime.unavailable, isFalse);
      final pending = await stage1TimeRequestService.listPending();
      expect(pending, isNotEmpty);
      expect(pending.first.childId, ChildId('demo-child'));
      expect(pending.first.requestedMinutes, 15);
      // Same authority as runtime
      expect(
        identical(stage1TimeRequestService, Stage1TimeRequestRuntime.service),
        isTrue,
      );
    },
  );

  test(
    'LDR-B4 day board merges time + friend pending from local producers',
    () async {
      await FsSessionKernel.ensureOpen(override: MemoryLocalDatabase());
      await ScreenTimeRuntime.ensureOpen();
      final circle = LocalOuterCircleRepository(FsSessionKernel.db);
      await circle.ensureRealLocalSeeded();
      rebindStage1OuterCircleRepository(circle);

      final board = RosterDayBoardProjectionRepository(
        children: InMemoryChildrenListRepository(
          byFamily: {'fam_stage1': ChildrenListLocalSeedMock.famStage1Children},
        ),
        familyId: () => ChildrenListLocalSeedMock.famStage1,
        outerCircle: circle,
        listTimePending: () => stage1TimeRequestService.listPending(),
      );
      final proj = await board.load();
      expect(proj.children.length, 2);
      expect(proj.children.first.locationLabel, isEmpty);
      expect(
        proj.pendingRequests.any((p) => p.titleKey == 'timeRequest'),
        isTrue,
      );
      expect(
        proj.pendingRequests.any((p) => p.titleKey == 'friendRequest'),
        isTrue,
      );
    },
  );
}
