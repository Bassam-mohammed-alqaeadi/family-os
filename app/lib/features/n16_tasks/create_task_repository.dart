import 'package:family_os/features/n16_tasks/create_task_models.dart';

/// Rule 25 seam — Stage-1 mock create family task (no backend).
abstract class CreateTaskRepository {
  Future<CreateTaskSnapshot> load();

  Future<CreateTaskSnapshot> submitTask(CreateTaskDraft draft);
}

/// In-memory mock — prototype FAT-055 shape by default.
final class InMemoryCreateTaskRepository implements CreateTaskRepository {
  InMemoryCreateTaskRepository({CreateTaskSnapshot? seed})
    : _snap = seed ?? createTaskPrototypeFixture();

  CreateTaskSnapshot _snap;

  /// Optional gate for loading-state widget tests.
  Future<void> Function()? loadGate;

  @override
  Future<CreateTaskSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    return _copy(_snap);
  }

  @override
  Future<CreateTaskSnapshot> submitTask(CreateTaskDraft draft) async {
    if (_snap.isEmpty) return _copy(_snap);
    final trimmed = draft.title.trim();
    if (trimmed.isEmpty) return _copy(_snap);
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

/// Shared Stage-1 singleton (prototype fixture until a screen/test seeds).
final InMemoryCreateTaskRepository stage1CreateTaskRepository =
    InMemoryCreateTaskRepository();

/// Empty — Rule 23 empty-state coverage (no children to assign tasks).
CreateTaskSnapshot createTaskEmptyFixture() {
  return const CreateTaskSnapshot();
}

/// One child — minimal family for single-target tasks.
CreateTaskSnapshot createTaskOneFixture() {
  return const CreateTaskSnapshot(
    children: [
      CreateTaskChild(id: 'child_a', nameKey: 'one'),
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
  return const CreateTaskSnapshot(
    children: [
      CreateTaskChild(id: 'child_a', nameKey: 'one'),
      CreateTaskChild(id: 'child_b', nameKey: 'two'),
      CreateTaskChild(id: 'child_c', nameKey: 'three'),
    ],
    draft: CreateTaskDraft(
      title: '',
      assigneeNameKey: 'childOne',
      courageMinutes: CreateTaskCourageMinutes.fifteen,
      playtimeMinutes: CreateTaskPlaytimeMinutes.fifteen,
    ),
  );
}
