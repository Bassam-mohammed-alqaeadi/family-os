import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/domain/minutes.dart';
import 'package:family_os/core/fs_foundation/memory_local_database.dart';
import 'package:family_os/features/n16_tasks/family_tasks_local_repository.dart';
import 'package:family_os/features/n16_tasks/family_tasks_models.dart';
import 'package:family_os/features/n16_tasks/family_tasks_repository.dart';

/// CE-B1 — Family Tasks Minutes VO + Local restart proof.
void main() {
  test('FamilyChildTask uses Minutes VO (Q-CEX-003)', () {
    final task = FamilyChildTask(
      id: 't1',
      titleKey: 'tidyRoom',
      assigneeNameKey: 'childOne',
      avatarKey: 'lion',
      reward: Minutes(15),
      status: FamilyTaskStatus.assigned,
      timeKey: 'today',
    );
    expect(task.reward, Minutes(15));
    expect(task.rewardMinutes, 15);
  });

  test('InMemory empty-first + create→submit→approve loop', () async {
    final repo = InMemoryFamilyTasksRepository(seed: familyTasksEmptyFixture());
    expect((await repo.load()).isEmpty, isTrue);

    await repo.addTask(
      FamilyChildTask(
        id: 't-new',
        titleKey: 'custom:Wash',
        assigneeNameKey: 'childOne',
        avatarKey: 'lion',
        reward: Minutes(20),
        status: FamilyTaskStatus.assigned,
        timeKey: 'today',
      ),
    );
    var snap = await repo.load();
    expect(snap.childTasks, hasLength(1));

    await repo.submitProof('t-new');
    snap = await repo.load();
    expect(snap.childTasks.single.status, FamilyTaskStatus.pendingApproval);

    await repo.approveTask('t-new');
    snap = await repo.load();
    expect(snap.childTasks.single.status, FamilyTaskStatus.completed);
  });

  test('LocalFamilyTasksRepository restart proof via Memory DB', () async {
    final db = MemoryLocalDatabase();
    await db.open();
    final a = LocalFamilyTasksRepository(db);
    await a.addTask(
      FamilyChildTask(
        id: 'persist-1',
        titleKey: 'tidyRoom',
        assigneeNameKey: 'childTwo',
        avatarKey: 'cat',
        reward: Minutes(15),
        status: FamilyTaskStatus.assigned,
        timeKey: 'today',
      ),
    );

    final b = LocalFamilyTasksRepository(db);
    final snap = await b.load();
    expect(snap.childTasks, hasLength(1));
    expect(snap.childTasks.single.id, 'persist-1');
    expect(snap.childTasks.single.reward, Minutes(15));
  });
}
