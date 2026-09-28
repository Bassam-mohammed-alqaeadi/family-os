import 'package:family_os/features/n16_tasks/child_tasks_models.dart';
import 'package:family_os/features/n16_tasks/family_tasks_models.dart';
import 'package:family_os/features/n16_tasks/family_tasks_repository.dart';
import 'package:family_os/core/domain/minutes.dart';

abstract class ChildTasksRepository {
  Future<ChildTasksSnapshot> load();
  Future<ChildTasksSnapshot> submitProof(String taskId);
}

/// Projects [FamilyTasksRepository] into the child CHD-022 view.
///
/// One authority with FAT-054 — submitProof mutates the shared family store.
final class FamilyBoundChildTasksRepository implements ChildTasksRepository {
  FamilyBoundChildTasksRepository({
    FamilyTasksRepository? family,
    this.assigneeNameKey,
    this.loadError,
  }) : _familyOverride = family;

  final FamilyTasksRepository? _familyOverride;

  FamilyTasksRepository get _family =>
      _familyOverride ?? stage1FamilyTasksRepository;

  /// When set, only tasks for this assignee key (childOne / childTwo / …).
  /// Null = all child tasks (single-device Stage-1 demo).
  final String? assigneeNameKey;

  /// Test seam — forces load failure once consumed.
  Object? loadError;

  Future<void> Function()? loadGate;

  @override
  Future<ChildTasksSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    final err = loadError;
    if (err != null) {
      loadError = null;
      throw err;
    }
    final snap = await _family.load();
    return _project(snap);
  }

  @override
  Future<ChildTasksSnapshot> submitProof(String taskId) async {
    await _family.submitProof(taskId);
    return _project(await _family.load());
  }

  ChildTasksSnapshot _project(FamilyTasksSnapshot snap) {
    final filtered = assigneeNameKey == null
        ? snap.childTasks
        : snap.childTasks
            .where((t) => t.assigneeNameKey == assigneeNameKey)
            .toList();
    return ChildTasksSnapshot(
      tasks: filtered.map(_mapTask).toList(),
    );
  }

  ChildTaskItem _mapTask(FamilyChildTask t) {
    return ChildTaskItem(
      id: t.id,
      titleKey: t.titleKey,
      reward: t.reward,
      status: switch (t.status) {
        FamilyTaskStatus.assigned => ChildTaskItemStatus.assigned,
        FamilyTaskStatus.pendingApproval => ChildTaskItemStatus.pendingApproval,
        FamilyTaskStatus.completed => ChildTaskItemStatus.completed,
      },
    );
  }
}

/// Isolated in-memory seam for widget tests that do not need FAT-054 loop.
final class InMemoryChildTasksRepository implements ChildTasksRepository {
  InMemoryChildTasksRepository({ChildTasksSnapshot? seed})
    : _snap = seed ?? childTasksEmptyFixture();

  ChildTasksSnapshot _snap;
  Future<void> Function()? loadGate;
  Object? loadError;

  @override
  Future<ChildTasksSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    final err = loadError;
    if (err != null) {
      loadError = null;
      throw err;
    }
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

/// Production Stage-1 singleton — always reads live [stage1FamilyTasksRepository].
final ChildTasksRepository stage1ChildTasksRepository =
    FamilyBoundChildTasksRepository();

ChildTasksSnapshot childTasksEmptyFixture() => const ChildTasksSnapshot();

ChildTasksSnapshot childTasksOneFixture() {
  return ChildTasksSnapshot(
    tasks: [
      ChildTaskItem(
        id: 't1',
        titleKey: 'tidyRoom',
        reward: Minutes(15),
        status: ChildTaskItemStatus.assigned,
      ),
    ],
  );
}

ChildTasksSnapshot childTasksPrototypeFixture() {
  return ChildTasksSnapshot(
    tasks: [
      ChildTaskItem(
        id: 't1',
        titleKey: 'tidyRoom',
        reward: Minutes(15),
        status: ChildTaskItemStatus.assigned,
      ),
      ChildTaskItem(
        id: 't2',
        titleKey: 'mathReview',
        reward: Minutes(20),
        status: ChildTaskItemStatus.pendingApproval,
      ),
      ChildTaskItem(
        id: 't3',
        titleKey: 'wirdDone',
        reward: Minutes(10),
        status: ChildTaskItemStatus.completed,
      ),
    ],
  );
}
