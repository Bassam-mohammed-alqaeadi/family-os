import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import 'package:family_os/core/data/family_database.dart';
import 'package:family_os/core/data/stage1_row_vocabulary.dart';
import 'package:family_os/features/n16_tasks/child_tasks_models.dart';
import 'package:family_os/features/n16_tasks/child_tasks_repository.dart';
import 'package:family_os/features/n16_tasks/create_task_models.dart';
import 'package:family_os/features/n16_tasks/create_task_repository.dart';
import 'package:family_os/features/n16_tasks/family_tasks_models.dart';
import 'package:family_os/features/n16_tasks/family_tasks_repository.dart';
import 'package:family_os/features/n16_tasks/smart_chore_distributor_models.dart';
import 'package:family_os/features/n16_tasks/smart_chore_distributor_repository.dart';

/// Stage-2 composition root for the tasks domain (ADR-054 §5 · §11.1).
///
/// Same shape as `Stage1DevicesRuntime`: one process-wide [FamilyDatabase],
/// the real Drift repositories built once, and the screens defaulting to them.
/// Tests keep injecting their in-memory seams, so nothing in the existing
/// suite changes.
final class Stage1TasksRuntime {
  Stage1TasksRuntime._();

  static FamilyDatabase? _db;
  static var _opened = false;

  /// Opens once. Pass [override] to inject a database (tests own its lifecycle).
  ///
  /// Without an override the store is an in-process Drift database — honest for
  /// this slice: with no sync backend yet there is nothing to persist against,
  /// and on-device persistence swaps in behind the same repos.
  static Future<void> ensureOpen({FamilyDatabase? override}) async {
    if (_opened && override == null) return;
    _db = override ?? (_db ?? FamilyDatabase(NativeDatabase.memory()));
    _opened = true;
  }

  static FamilyDatabase get db {
    final value = _db;
    if (value == null) {
      throw StateError('Call Stage1TasksRuntime.ensureOpen() first');
    }
    return value;
  }

  /// SCR-FAT-054 — the family's task board over `task` + `task_submission`.
  static FamilyTasksRepository familyTasks({String? familyId}) =>
      DriftFamilyTasksRepository(db, familyId: familyId ?? '');

  /// SCR-FAT-055 — assigning a task to a child, over `child` + `task`.
  static CreateTaskRepository createTask({
    String? familyId,
    String? createdByAccount,
  }) => DriftCreateTaskRepository(
    db,
    familyId: familyId ?? '',
    createdByAccount: createdByAccount,
  );

  /// SCR-CHD-012 — the child's own list over `task` + `task_submission`.
  static ChildTasksRepository childTasks({String? familyId, String? childId}) =>
      DriftChildTasksRepository(db, familyId: familyId ?? '', childId: childId);

  /// SCR-FAT-056 — the chore split over `chore_distribution`.
  static SmartChoreDistributorRepository choreDistributor({String? familyId}) =>
      DriftSmartChoreDistributorRepository(db, familyId: familyId ?? '');

  /// Clears this runtime only. An injected database is closed by its owner.
  static void resetForTest() {
    _opened = false;
    _db = null;
  }
}

/// SCR-FAT-054 over real rows: `task` joined to `child` for the assignee, with
/// `task_submission` supplying the proof line — and the help-request lane read
/// from the rows whose assignee is a parent (no child, kind `HELP`).
///
/// Mirrors [InMemoryFamilyTasksRepository]'s contract, including the fail-closed
/// rule for an unscoped family.
final class DriftFamilyTasksRepository implements FamilyTasksRepository {
  DriftFamilyTasksRepository(
    this._db, {
    required String familyId,
    DateTime Function()? clock,
  }) : _familyId = familyId.trim(),
       clock = clock ?? DateTime.now;

  final FamilyDatabase _db;
  final String _familyId;
  final DateTime Function() clock;

  @override
  Future<FamilyTasksSnapshot> load() async {
    if (_familyId.isEmpty) {
      // Fail closed — an unscoped board would mix families.
      return const FamilyTasksSnapshot();
    }
    final rows =
        await (_db.select(_db.tasks)
              ..where((t) => t.familyId.equals(_familyId))
              ..orderBy([
                (t) => OrderingTerm.desc(t.createdAt),
                (t) => OrderingTerm.asc(t.id),
              ]))
            .get();
    if (rows.isEmpty) return const FamilyTasksSnapshot();

    final children = await _childrenInOrder();
    final byId = {for (final c in children) c.id: c};
    final proofOf = await _proofRefs(rows.map((r) => r.id).toList());

    final childTasks = <FamilyChildTask>[];
    final motherHelp = <MotherHelpTask>[];
    for (final row in rows) {
      final assignee = (row.assigneeChildId ?? '').trim();
      final timeKey = Stage1RowVocabulary.timeKeyFor(
        row.dueAt ?? row.createdAt,
        clock(),
      );
      if (assignee.isEmpty ||
          row.kind == Stage1RowVocabulary.taskKindHelp) {
        motherHelp.add(
          MotherHelpTask(
            id: row.id,
            titleKey: row.titleRef,
            status: _helpIsDone(row.status)
                ? MotherHelpTaskStatus.done
                : MotherHelpTaskStatus.open,
            timeKey: timeKey,
          ),
        );
        continue;
      }
      final ordinal = children.indexWhere((c) => c.id == assignee);
      final avatar = (byId[assignee]?.avatar ?? '').trim();
      childTasks.add(
        FamilyChildTask(
          id: row.id,
          titleKey: row.titleRef,
          // Ordinal key when the child is ours; the stored value otherwise —
          // never a different child's label.
          assigneeNameKey: ordinal == -1
              ? assignee
              : Stage1RowVocabulary.childKeyFor(ordinal),
          avatarKey: avatar.isEmpty ? 'lion' : avatar,
          rewardMinutes: row.rewardMinutes,
          status: _statusOf(row.status),
          proofKey: proofOf[row.id],
          timeKey: timeKey,
        ),
      );
    }
    return FamilyTasksSnapshot(
      childTasks: childTasks,
      motherHelpTasks: motherHelp,
    );
  }

  @override
  Future<void> approveTask(String taskId) async {
    if (_familyId.isEmpty) return;
    final now = clock();
    await (_db.update(_db.tasks)
          ..where(
            (t) => t.id.equals(taskId) & t.familyId.equals(_familyId),
          ))
        .write(
          TasksCompanion(
            status: const Value(Stage1RowVocabulary.statusCompleted),
            updatedAt: Value(now),
          ),
        );
    final submissions =
        await (_db.select(_db.taskSubmissions)
              ..where((s) => s.taskId.equals(taskId)))
            .get();
    for (final submission in submissions) {
      await (_db.update(_db.taskSubmissions)
            ..where((s) => s.id.equals(submission.id)))
          .write(
            TaskSubmissionsCompanion(
              status: const Value(Stage1RowVocabulary.submissionApproved),
              reviewedAt: Value(now),
            ),
          );
    }
  }

  Future<List<ChildrenData>> _childrenInOrder() {
    return (_db.select(_db.children)
          ..where((c) => c.familyId.equals(_familyId))
          ..orderBy([(c) => OrderingTerm.asc(c.createdAt)]))
        .get();
  }

  /// taskId → the attached media reference, for the rows that have one.
  Future<Map<String, String>> _proofRefs(List<String> taskIds) async {
    if (taskIds.isEmpty) return const <String, String>{};
    final rows =
        await (_db.select(_db.taskSubmissions)
              ..where((s) => s.taskId.isIn(taskIds)))
            .get();
    final out = <String, String>{};
    for (final row in rows) {
      final ref = row.mediaRef.trim();
      if (ref.isEmpty) continue;
      out[row.taskId] = ref;
    }
    return out;
  }

  static FamilyTaskStatus _statusOf(String status) => switch (status) {
    Stage1RowVocabulary.statusPendingApproval =>
      FamilyTaskStatus.pendingApproval,
    Stage1RowVocabulary.statusCompleted => FamilyTaskStatus.completed,
    _ => FamilyTaskStatus.assigned,
  };

  static bool _helpIsDone(String status) =>
      status == Stage1RowVocabulary.statusDone ||
      status == Stage1RowVocabulary.statusCompleted;
}

/// SCR-FAT-055 over real rows: the children come from `child`, and submitting
/// writes a real `task` row — the typed title kept verbatim (it is the father's
/// own words, not a planted string), the reward split into its two columns.
final class DriftCreateTaskRepository implements CreateTaskRepository {
  DriftCreateTaskRepository(
    this._db, {
    required String familyId,
    String? createdByAccount,
    DateTime Function()? clock,
  }) : _familyId = familyId.trim(),
       _createdBy = (createdByAccount ?? '').trim(),
       clock = clock ?? DateTime.now;

  final FamilyDatabase _db;
  final String _familyId;
  final String _createdBy;
  final DateTime Function() clock;

  /// `task.created_by_account` is NOT NULL in the contract; until the identity
  /// layer hands us the signed-in account this marker says so out loud.
  static const _unattributed = 'unattributed';

  @override
  Future<CreateTaskSnapshot> load() async {
    if (_familyId.isEmpty) {
      // Fail closed — no family, no children to assign to.
      return const CreateTaskSnapshot();
    }
    final children = await _childrenInOrder();
    final stored =
        await (_db.selectOnly(_db.tasks)
              ..addColumns([_db.tasks.id.count()])
              ..where(_db.tasks.familyId.equals(_familyId)))
            .getSingle();
    final count = stored.read(_db.tasks.id.count()) ?? 0;
    return CreateTaskSnapshot(
      children: [
        for (var i = 0; i < children.length; i++)
          CreateTaskChild(
            id: children[i].id,
            nameKey: Stage1RowVocabulary.childKeyFor(i),
          ),
      ],
      draft: const CreateTaskDraft(),
      submittedCount: count,
    );
  }

  @override
  Future<CreateTaskSnapshot> submitTask(CreateTaskDraft draft) async {
    final snapshot = await load();
    if (snapshot.isEmpty) return snapshot;
    final title = draft.title.trim();
    if (title.isEmpty) return snapshot;

    final now = clock();
    final children = await _childrenInOrder();
    final helper = draft.isMotherAssignee;
    String? assignee;
    if (!helper) {
      final ordinal = Stage1RowVocabulary.childOrdinalFor(
        draft.assigneeNameKey,
      );
      if (ordinal != null && ordinal < children.length) {
        assignee = children[ordinal].id;
      }
    }

    await _db
        .into(_db.tasks)
        .insert(
          TasksCompanion.insert(
            id: stage1RowId('task', now),
            familyId: _familyId,
            titleRef: title,
            assigneeChildId: Value(assignee),
            kind: helper
                ? Stage1RowVocabulary.taskKindHelp
                : Stage1RowVocabulary.taskKindChore,
            // The row's payout is the two rewards summed; the split keeps its
            // own columns so the breakdown is never lost.
            rewardMinutes: Value(
              draft.courageMinutes.value + draft.playtimeMinutes.value,
            ),
            courageMinutes: Value(draft.courageMinutes.value),
            playtimeMinutes: Value(draft.playtimeMinutes.value),
            status: Stage1RowVocabulary.statusAssigned,
            createdByAccount: _createdBy.isEmpty ? _unattributed : _createdBy,
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
    return load();
  }

  Future<List<ChildrenData>> _childrenInOrder() {
    return (_db.select(_db.children)
          ..where((c) => c.familyId.equals(_familyId))
          ..orderBy([(c) => OrderingTerm.asc(c.createdAt)]))
        .get();
  }
}

/// SCR-CHD-012 over real rows: the child's own list is `task` filtered by the
/// assignee, and submitting proof writes a real `task_submission` row and moves
/// the task to `PENDING_APPROVAL` — the approval then happens on the parent's
/// board (SCR-FAT-054).
final class DriftChildTasksRepository implements ChildTasksRepository {
  DriftChildTasksRepository(
    this._db, {
    required String familyId,
    String? childId,
    DateTime Function()? clock,
  }) : _familyId = familyId.trim(),
       _childId = (childId ?? '').trim(),
       clock = clock ?? DateTime.now;

  final FamilyDatabase _db;
  final String _familyId;
  final String _childId;
  final DateTime Function() clock;

  @override
  Future<ChildTasksSnapshot> load() async {
    if (_familyId.isEmpty) {
      // Fail closed — never hand another family's tasks to a child screen.
      return const ChildTasksSnapshot();
    }
    final query = _db.select(_db.tasks)
      ..where((t) => t.familyId.equals(_familyId))
      ..where((t) => t.assigneeChildId.isNotNull())
      ..orderBy([
        (t) => OrderingTerm.desc(t.createdAt),
        (t) => OrderingTerm.asc(t.id),
      ]);
    if (_childId.isNotEmpty) {
      query.where((t) => t.assigneeChildId.equals(_childId));
    }
    final rows = await query.get();
    return ChildTasksSnapshot(
      tasks: [
        for (final row in rows)
          ChildTaskItem(
            id: row.id,
            titleKey: row.titleRef,
            rewardMinutes: row.rewardMinutes,
            status: _statusOf(row.status),
          ),
      ],
    );
  }

  @override
  Future<ChildTasksSnapshot> submitProof(String taskId) async {
    final snapshot = await load();
    // Only a task this child can actually see may be touched.
    final visible = snapshot.tasks.any((t) => t.id == taskId);
    if (!visible) return snapshot;

    final now = clock();
    final rows =
        await (_db.select(_db.tasks)
              ..where(
                (t) => t.id.equals(taskId) & t.familyId.equals(_familyId),
              ))
            .get();
    if (rows.isEmpty) return snapshot;
    final task = rows.first;
    final childId = (task.assigneeChildId ?? _childId).trim();

    await _db
        .into(_db.taskSubmissions)
        .insert(
          TaskSubmissionsCompanion.insert(
            id: stage1RowId('sub', now),
            taskId: taskId,
            childId: childId,
            // No media picker on this slice: the submission is recorded, and
            // an empty reference says plainly that nothing is attached.
            mediaRef: '',
            submittedAt: Value(now),
            status: Stage1RowVocabulary.submissionSubmitted,
          ),
        );
    await (_db.update(_db.tasks)
          ..where((t) => t.id.equals(taskId) & t.familyId.equals(_familyId)))
        .write(
          TasksCompanion(
            status: const Value(Stage1RowVocabulary.statusPendingApproval),
            updatedAt: Value(now),
          ),
        );
    return load();
  }

  static ChildTaskItemStatus _statusOf(String status) => switch (status) {
    Stage1RowVocabulary.statusPendingApproval =>
      ChildTaskItemStatus.pendingApproval,
    Stage1RowVocabulary.statusCompleted => ChildTaskItemStatus.completed,
    _ => ChildTaskItemStatus.assigned,
  };
}

/// SCR-FAT-056 over real rows: the split lives in `chore_distribution`.
///
/// Approving stamps every stored row; «اقترح توزيعًا آخر» rotates the chores
/// between the children and clears the approval, so the alternative is a real
/// change in storage rather than a flipped flag. The child keeps their own note
/// (it belongs to the child, not to the chore).
final class DriftSmartChoreDistributorRepository
    implements SmartChoreDistributorRepository {
  DriftSmartChoreDistributorRepository(
    this._db, {
    required String familyId,
  }) : _familyId = familyId.trim();

  final FamilyDatabase _db;
  final String _familyId;

  @override
  Future<SmartChoreDistributorSnapshot> load() async {
    if (_familyId.isEmpty) {
      // Fail closed — an unscoped split would mix families.
      return const SmartChoreDistributorSnapshot();
    }
    final children = await _childrenInOrder();
    final rows = await _rowsInOrder();
    if (children.isEmpty && rows.isEmpty) {
      return const SmartChoreDistributorSnapshot();
    }
    return SmartChoreDistributorSnapshot(
      hasFamily: true,
      assignments: [
        for (final row in rows)
          ChoreAssignment(
            id: row.id,
            childLabelKey: _labelFor(row.childId, children),
            choresKey: row.choresRef,
            noteKey: (row.noteRef ?? '').trim(),
          ),
      ],
      approved: rows.isNotEmpty && rows.every((r) => r.approved),
      // No column stores «an alternative was proposed» — the flag belongs to
      // the sitting, and vanishes with it (ADR-042 covers the rows, not this).
      altReady: false,
    );
  }

  @override
  Future<SmartChoreDistributorSnapshot> approve() async {
    if (_familyId.isEmpty) return const SmartChoreDistributorSnapshot();
    for (final row in await _rowsInOrder()) {
      await (_db.update(_db.choreDistributions)
            ..where((c) => c.id.equals(row.id)))
          .write(const ChoreDistributionsCompanion(approved: Value(true)));
    }
    return load();
  }

  @override
  Future<SmartChoreDistributorSnapshot> shuffle() async {
    if (_familyId.isEmpty) return const SmartChoreDistributorSnapshot();
    final rows = await _rowsInOrder();
    if (rows.length >= 2) {
      final chores = [for (final row in rows) row.choresRef];
      for (var i = 0; i < rows.length; i++) {
        final next = chores[(i + 1) % chores.length];
        await (_db.update(_db.choreDistributions)
              ..where((c) => c.id.equals(rows[i].id)))
            .write(
              ChoreDistributionsCompanion(
                choresRef: Value(next),
                approved: const Value(false),
              ),
            );
      }
    } else {
      for (final row in rows) {
        await (_db.update(_db.choreDistributions)
              ..where((c) => c.id.equals(row.id)))
            .write(const ChoreDistributionsCompanion(approved: Value(false)));
      }
    }
    return load();
  }

  Future<List<ChildrenData>> _childrenInOrder() {
    return (_db.select(_db.children)
          ..where((c) => c.familyId.equals(_familyId))
          ..orderBy([(c) => OrderingTerm.asc(c.createdAt)]))
        .get();
  }

  Future<List<ChoreDistribution>> _rowsInOrder() {
    return (_db.select(_db.choreDistributions)
          ..where((c) => c.familyId.equals(_familyId))
          ..orderBy([
            (c) => OrderingTerm.asc(c.createdAt),
            (c) => OrderingTerm.asc(c.id),
          ]))
        .get();
  }

  static String _labelFor(String childId, List<ChildrenData> children) {
    final ordinal = children.indexWhere((c) => c.id == childId);
    return ordinal == -1
        ? childId
        : Stage1RowVocabulary.childKeyFor(ordinal);
  }
}
