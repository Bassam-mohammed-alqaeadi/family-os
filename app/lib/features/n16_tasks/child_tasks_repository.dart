import 'package:family_os/features/n16_tasks/child_tasks_models.dart';

abstract class ChildTasksRepository {
  Future<ChildTasksSnapshot> load();
  Future<ChildTasksSnapshot> submitProof(String taskId);
}

final class InMemoryChildTasksRepository implements ChildTasksRepository {
  InMemoryChildTasksRepository({ChildTasksSnapshot? seed})
    : _snap = seed ?? childTasksPrototypeFixture();

  ChildTasksSnapshot _snap;
  Future<void> Function()? loadGate;

  @override
  Future<ChildTasksSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    return ChildTasksSnapshot(tasks: List<ChildTaskItem>.from(_snap.tasks));
  }

  @override
  Future<ChildTasksSnapshot> submitProof(String taskId) async {
    final tasks = List<ChildTaskItem>.from(_snap.tasks);
    final idx = tasks.indexWhere((t) => t.id == taskId);
    if (idx != -1) {
      tasks[idx] = tasks[idx].copyWith(
        status: ChildTaskItemStatus.pendingApproval,
      );
      _snap = ChildTasksSnapshot(tasks: tasks);
    }
    return ChildTasksSnapshot(tasks: List<ChildTaskItem>.from(_snap.tasks));
  }

  void seed(ChildTasksSnapshot snap) => _snap = snap;
}

final InMemoryChildTasksRepository stage1ChildTasksRepository =
    InMemoryChildTasksRepository();

ChildTasksSnapshot childTasksEmptyFixture() => const ChildTasksSnapshot();

ChildTasksSnapshot childTasksOneFixture() {
  return const ChildTasksSnapshot(
    tasks: [
      ChildTaskItem(
        id: 't1',
        titleKey: 'tidyRoom',
        rewardMinutes: 15,
        status: ChildTaskItemStatus.assigned,
      ),
    ],
  );
}

ChildTasksSnapshot childTasksPrototypeFixture() {
  return const ChildTasksSnapshot(
    tasks: [
      ChildTaskItem(
        id: 't1',
        titleKey: 'tidyRoom',
        rewardMinutes: 15,
        status: ChildTaskItemStatus.assigned,
      ),
      ChildTaskItem(
        id: 't2',
        titleKey: 'mathReview',
        rewardMinutes: 20,
        status: ChildTaskItemStatus.pendingApproval,
      ),
      ChildTaskItem(
        id: 't3',
        titleKey: 'wirdDone',
        rewardMinutes: 10,
        status: ChildTaskItemStatus.completed,
      ),
    ],
  );
}
