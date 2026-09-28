import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/policy/time_request.dart';
import 'package:family_os/features/n02_day/children_list_local_repository.dart';
import 'package:family_os/features/n02_day/children_list_repository.dart';
import 'package:family_os/features/n02_day/day_board_projection.dart';
import 'package:family_os/features/n02_day/outer_circle_models.dart';
import 'package:family_os/features/n02_day/outer_circle_repository.dart';

void main() {
  tearDown(() {
    resetStage1ChildrenListRepositoryForTest();
  });

  test('time + friend pending surface; athkar opens FAT-072 not CHD-027', () async {
    final memory = InMemoryChildrenListRepository(
      byFamily: {
        ChildrenListLocalSeed.famStage1.value:
            ChildrenListLocalSeed.famStage1Children,
      },
    );
    final circle = InMemoryOuterCircleRepository(
      seed: OuterCircleSnapshot(
        pending: [
          OuterCircleMember(
            id: 'p1',
            kind: OuterCircleMemberKind.pendingFriend,
            nameKey: 'pendingFriend',
            metaKey: 'classmate',
            statusKey: 'pending',
          ),
        ],
      ),
    );
    final repo = RosterDayBoardProjectionRepository(
      children: memory,
      outerCircle: circle,
      listTimePending: () async => [
        TimeRequest(
          id: 'tr-1',
          childId: ChildId('demo-child'),
          requestedMinutes: 15,
          status: TimeRequestStatus.pending,
          createdAt: DateTime.utc(2026, 9, 26),
        ),
      ],
      listAppInstallPending: () async => const [],
    );

    final p = await repo.load();
    expect(p.pendingRequests.map((e) => e.titleKey).toList(), [
      'timeRequest',
      'friendRequest',
    ]);
    expect(p.pendingRequests.first.inboxPath, '/scr-fat-033');
    expect(
      p.pendingRequests.where((e) => e.titleKey == 'friendRequest').single.inboxPath,
      '/scr-fat-071',
    );
  });
}
