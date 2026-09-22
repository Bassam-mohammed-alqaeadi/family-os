import 'package:family_os/features/n16_tasks/family_tasks_models.dart';

/// Rule 25 seam — Stage-1 mock family tasks (no backend).
abstract class FamilyTasksRepository {
  Future<FamilyTasksSnapshot> load();

  /// Stage-1 local approve — pending → completed.
  Future<void> approveTask(String taskId);
}

/// In-memory mock — prototype FAT-054 shape by default.
final class InMemoryFamilyTasksRepository implements FamilyTasksRepository {
  InMemoryFamilyTasksRepository({FamilyTasksSnapshot? seed})
    : _snap = seed ?? familyTasksPrototypeFixture();

  FamilyTasksSnapshot _snap;

  /// Optional gate for loading-state widget tests.
  Future<void> Function()? loadGate;

  @override
  Future<FamilyTasksSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    return FamilyTasksSnapshot(
      childTasks: List<FamilyChildTask>.from(_snap.childTasks),
      motherHelpTasks: List<MotherHelpTask>.from(_snap.motherHelpTasks),
    );
  }

  @override
  Future<void> approveTask(String taskId) async {
    final tasks = List<FamilyChildTask>.from(_snap.childTasks);
    final idx = tasks.indexWhere((t) => t.id == taskId);
    if (idx == -1) return;
    tasks[idx] = tasks[idx].copyWith(status: FamilyTaskStatus.completed);
    _snap = FamilyTasksSnapshot(
      childTasks: tasks,
      motherHelpTasks: _snap.motherHelpTasks,
    );
  }

  void seed(FamilyTasksSnapshot snap) {
    _snap = snap;
  }
}

/// Shared Stage-1 singleton (prototype fixture until a screen/test seeds).
final InMemoryFamilyTasksRepository stage1FamilyTasksRepository =
    InMemoryFamilyTasksRepository();

/// Empty — Rule 23 empty-state coverage → SCR-FAT-003.
FamilyTasksSnapshot familyTasksEmptyFixture() {
  return const FamilyTasksSnapshot();
}

/// One pending task — Rule 23 one-item coverage.
FamilyTasksSnapshot familyTasksOneFixture() {
  return const FamilyTasksSnapshot(
    childTasks: [
      FamilyChildTask(
        id: 't-pending',
        titleKey: 'tidyRoom',
        assigneeNameKey: 'childThree',
        avatarKey: 'panda',
        rewardMinutes: 15,
        status: FamilyTaskStatus.pendingApproval,
        proofKey: 'photoAttached',
        timeKey: 'tenMinAgo',
      ),
    ],
  );
}

/// Prototype FAT-054 — three child tasks + one mother help request.
///
/// Rule 23: titleKey / assigneeNameKey / timeKey only (no planted person names).
FamilyTasksSnapshot familyTasksPrototypeFixture() {
  return const FamilyTasksSnapshot(
    childTasks: [
      FamilyChildTask(
        id: 't1',
        titleKey: 'tidyRoom',
        assigneeNameKey: 'childThree',
        avatarKey: 'panda',
        rewardMinutes: 15,
        status: FamilyTaskStatus.pendingApproval,
        proofKey: 'photoAttached',
        timeKey: 'tenMinAgo',
      ),
      FamilyChildTask(
        id: 't2',
        titleKey: 'washDishes',
        assigneeNameKey: 'childOne',
        avatarKey: 'lion',
        rewardMinutes: 15,
        status: FamilyTaskStatus.assigned,
        timeKey: 'today',
      ),
      FamilyChildTask(
        id: 't3',
        titleKey: 'mathStudy',
        assigneeNameKey: 'childOne',
        avatarKey: 'lion',
        rewardMinutes: 30,
        status: FamilyTaskStatus.completed,
        timeKey: 'yesterday',
      ),
    ],
    motherHelpTasks: [
      MotherHelpTask(
        id: 'm1',
        titleKey: 'schoolReturnList',
        status: MotherHelpTaskStatus.open,
        timeKey: 'today',
      ),
    ],
  );
}
