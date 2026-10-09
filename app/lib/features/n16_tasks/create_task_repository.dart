import 'package:family_os/core/domain/minutes.dart';
import 'package:family_os/core/identity/roster_children.dart';
import 'package:family_os/features/n16_tasks/create_task_models.dart';
import 'package:family_os/features/n16_tasks/family_tasks_models.dart';
import 'package:family_os/features/n16_tasks/family_tasks_repository.dart';

/// Rule 25 seam — create family task (FAT-055) → shared [FamilyTasksRepository].
abstract class CreateTaskRepository {
  Future<CreateTaskSnapshot> load();

  Future<CreateTaskSnapshot> submitTask(CreateTaskDraft draft);
}

/// Writes approved creates into [FamilyTasksRepository] (CE-B1 / CE-G013).
final class InMemoryCreateTaskRepository implements CreateTaskRepository {
  InMemoryCreateTaskRepository({
    CreateTaskSnapshot? seed,
    FamilyTasksRepository? familyTasks,
  }) : _snap = seed ?? createTaskEmptyFixture(),
       _family = familyTasks;

  CreateTaskSnapshot _snap;
  final FamilyTasksRepository? _family;
  var _seq = 0;

  FamilyTasksRepository get _familyRepo =>
      _family ?? stage1FamilyTasksRepository;

  /// Optional gate for loading-state widget tests.
  Future<void> Function()? loadGate;

  @override
  Future<CreateTaskSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    _snap = bindCreateTaskToRoster(_snap);
    return _copy(_snap);
  }

  @override
  Future<CreateTaskSnapshot> submitTask(CreateTaskDraft draft) async {
    _snap = bindCreateTaskToRoster(_snap);
    if (_snap.isEmpty) return _copy(_snap);
    final trimmed = draft.title.trim();
    if (trimmed.isEmpty) return _copy(_snap);

    final isMotherHelp = draft.assigneeNameKey == 'mother';
    if (!isMotherHelp) {
      _seq += 1;
      final reward = Minutes(
        draft.courageMinutes.value + draft.playtimeMinutes.value,
      );
      await _familyRepo.addTask(
        FamilyChildTask(
          id: 'created_$_seq',
          titleKey: 'custom:$trimmed',
          assigneeNameKey: draft.assigneeNameKey,
          avatarKey: switch (draft.assigneeNameKey) {
            'childTwo' => 'cat',
            'childThree' => 'panda',
            _ => 'lion',
          },
          reward: reward,
          status: FamilyTaskStatus.assigned,
          timeKey: 'today',
        ),
      );
    }

    _snap = _snap.copyWith(
      draft: draft.copyWith(title: trimmed),
      submittedCount: _snap.submittedCount + 1,
    );
    return _copy(_snap);
  }

  void seed(CreateTaskSnapshot snap) {
    _snap = snap;
  }

  CreateTaskSnapshot _copy(CreateTaskSnapshot s) {
    return CreateTaskSnapshot(
      children: List<CreateTaskChild>.from(s.children),
      draft: s.draft,
      submittedCount: s.submittedCount,
    );
  }
}

/// Shared Stage-1 singleton.
final InMemoryCreateTaskRepository stage1CreateTaskRepository =
    InMemoryCreateTaskRepository();

/// Empty — Rule 23 empty-state coverage (no children to assign tasks).
CreateTaskSnapshot createTaskEmptyFixture() {
  return const CreateTaskSnapshot();
}

/// One child — minimal family for single-target tasks.
CreateTaskSnapshot createTaskOneFixture() {
  final roster = activeFamilyRosterChildren();
  if (roster.isEmpty) return const CreateTaskSnapshot();
  return CreateTaskSnapshot(
    children: [
      CreateTaskChild(id: roster.first.id.value, nameKey: roster.first.nameKey),
    ],
    draft: CreateTaskDraft(
      title: '',
      assigneeNameKey: 'childOne',
      courageMinutes: CreateTaskCourageMinutes.fifteen,
      playtimeMinutes: CreateTaskPlaytimeMinutes.fifteen,
    ),
  );
}

/// Prototype FAT-055 — three children + reward defaults.
///
/// Rule 23: nameKey only (no planted person names).
/// ع-١: minutes-only rewards (15 courage + 15 playtime).
CreateTaskSnapshot createTaskPrototypeFixture() {
  final roster = activeFamilyRosterChildren();
  return CreateTaskSnapshot(
    children: [
      for (final c in roster)
        CreateTaskChild(id: c.id.value, nameKey: c.nameKey),
    ],
    draft: CreateTaskDraft(
      title: '',
      assigneeNameKey: 'childOne',
      courageMinutes: CreateTaskCourageMinutes.fifteen,
      playtimeMinutes: CreateTaskPlaytimeMinutes.fifteen,
    ),
  );
}

CreateTaskSnapshot bindCreateTaskToRoster(CreateTaskSnapshot snap) {
  final roster = activeFamilyRosterChildren();
  if (snap.children.isEmpty && snap.submittedCount == 0) {
    return snap;
  }
  if (roster.isEmpty) {
    return const CreateTaskSnapshot();
  }
  return snap.copyWith(
    children: [
      for (final c in roster)
        CreateTaskChild(id: c.id.value, nameKey: c.nameKey),
    ],
  );
}
