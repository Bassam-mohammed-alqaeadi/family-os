import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/data/family_database.dart';
import 'package:family_os/core/data/stage1_row_vocabulary.dart';
import 'package:family_os/features/n16_tasks/child_tasks_models.dart';
import 'package:family_os/features/n16_tasks/create_task_models.dart';
import 'package:family_os/features/n16_tasks/family_tasks_models.dart';
import 'package:family_os/features/n16_tasks/family_tasks_repository.dart';
import 'package:family_os/features/n16_tasks/tasks_ux_bridge.dart';

/// DEV-3b — the tasks domain (SCR-FAT-054 · FAT-055 · CHD-012 · FAT-056) over
/// the ADR-054 v6 rows: `task`, `task_submission`, `chore_distribution`.
void main() {
  group('tasks over real rows', () {
    late Directory dir;
    late File file;
    late FamilyDatabase db;
    late DateTime now;
    var dbClosed = false;

    setUp(() async {
      dbClosed = false;
      now = DateTime(2026, 9, 24, 12);
      dir = await Directory.systemTemp.createTemp('dev3b_');
      file = File('${dir.path}/dev3b.sqlite');
      db = FamilyDatabase(NativeDatabase(file));
    });

    tearDown(() async {
      if (!dbClosed) await db.close();
      await dir.delete(recursive: true);
    });

    Future<void> child({
      required String id,
      required String alias,
      String avatar = 'lion',
      String familyId = 'fam_1',
      required DateTime createdAt,
    }) => db.into(db.children).insert(
      ChildrenCompanion.insert(
        id: id,
        familyId: familyId,
        displayName: alias,
        alias: alias,
        avatar: Value(avatar),
        createdAt: Value(createdAt),
      ),
    );

    Future<void> task({
      required String id,
      String familyId = 'fam_1',
      required String titleRef,
      String? assigneeChildId,
      String kind = Stage1RowVocabulary.taskKindChore,
      int rewardMinutes = 15,
      String status = Stage1RowVocabulary.statusAssigned,
      String createdByAccount = 'acc_father',
      required DateTime createdAt,
    }) => db.into(db.tasks).insert(
      TasksCompanion.insert(
        id: id,
        familyId: familyId,
        titleRef: titleRef,
        assigneeChildId: Value(assigneeChildId),
        kind: kind,
        rewardMinutes: Value(rewardMinutes),
        status: status,
        createdByAccount: createdByAccount,
        createdAt: Value(createdAt),
        updatedAt: Value(createdAt),
      ),
    );

    Future<void> seed() async {
      await child(
        id: 'chi_1',
        alias: 'child_1',
        avatar: 'panda',
        createdAt: DateTime.utc(2026, 1, 1),
      );
      await child(
        id: 'chi_2',
        alias: 'child_2',
        avatar: 'lion',
        createdAt: DateTime.utc(2026, 1, 2),
      );
      await task(
        id: 't_pending',
        titleRef: 'tidyRoom',
        assigneeChildId: 'chi_1',
        status: Stage1RowVocabulary.statusPendingApproval,
        createdAt: now.subtract(const Duration(minutes: 10)),
      );
      await task(
        id: 't_assigned',
        titleRef: 'washDishes',
        assigneeChildId: 'chi_2',
        createdAt: now.subtract(const Duration(days: 3)),
      );
      await task(
        id: 't_help',
        titleRef: 'schoolReturnList',
        kind: Stage1RowVocabulary.taskKindHelp,
        rewardMinutes: 0,
        status: Stage1RowVocabulary.statusOpen,
        createdAt: now,
      );
      // Another family's board must never leak in.
      await task(
        id: 't_other',
        familyId: 'fam_2',
        titleRef: 'otherFamilyTask',
        assigneeChildId: 'chi_other',
        createdAt: now,
      );
    }

    FamilyTasksRepository board({String familyId = 'fam_1'}) =>
        DriftFamilyTasksRepository(db, familyId: familyId, clock: () => now);

    test('reads the board from rows — both lanes, one family', () async {
      await seed();

      final snap = await board().load();

      expect(snap.childTasks.map((t) => t.id), ['t_pending', 't_assigned']);
      final pending = snap.childTasks.first;
      expect(pending.titleKey, 'tidyRoom');
      expect(pending.assigneeNameKey, 'childOne');
      expect(pending.avatarKey, 'panda');
      expect(pending.rewardMinutes, 15);
      expect(pending.status, FamilyTaskStatus.pendingApproval);
      expect(pending.timeKey, 'tenMinAgo');

      final assigned = snap.childTasks.last;
      expect(assigned.assigneeNameKey, 'childTwo');
      // Older than yesterday keeps its real date — never a false «today».
      expect(assigned.timeKey, '2026-09-21');

      expect(snap.motherHelpTasks, hasLength(1));
      expect(snap.motherHelpTasks.single.titleKey, 'schoolReturnList');
      expect(snap.motherHelpTasks.single.status, MotherHelpTaskStatus.open);
      expect(snap.pendingApproval, hasLength(1));
    });

    test('an unscoped family fails closed', () async {
      await seed();

      expect((await board(familyId: '').load()).isEmpty, isTrue);
      expect((await board(familyId: '   ').load()).isEmpty, isTrue);
      expect((await board(familyId: 'fam_unknown').load()).isEmpty, isTrue);
    });

    test('approving completes the row and closes its submission '
        '(ADR-042: survives close + reopen)', () async {
      await seed();
      await db.into(db.taskSubmissions).insert(
        TaskSubmissionsCompanion.insert(
          id: 'sub_1',
          taskId: 't_pending',
          childId: 'chi_1',
          mediaRef: 'proof_ref',
          submittedAt: Value(now.subtract(const Duration(minutes: 5))),
          status: Stage1RowVocabulary.submissionSubmitted,
        ),
      );

      await board().approveTask('t_pending');

      final after = await board().load();
      expect(after.childTasks.first.status, FamilyTaskStatus.completed);
      expect(after.childTasks.first.proofKey, 'proof_ref');
      final submission =
          await (db.select(db.taskSubmissions)
                ..where((s) => s.id.equals('sub_1')))
              .getSingle();
      expect(
        submission.status,
        Stage1RowVocabulary.submissionApproved,
      );
      expect(submission.reviewedAt, isNotNull);

      // ADR-042 — the fact is in storage, not in the widget.
      await db.close();
      dbClosed = true;
      final reopened = FamilyDatabase(NativeDatabase(file));
      addTearDown(reopened.close);
      final reopenedBoard = DriftFamilyTasksRepository(
        reopened,
        familyId: 'fam_1',
        clock: () => now,
      );
      final rows = await reopenedBoard.load();
      expect(rows.childTasks.first.status, FamilyTaskStatus.completed);
    });

    test('the child lane submits a real proof row and moves the task',
        () async {
      await seed();
      await task(
        id: 't_todo',
        titleRef: 'wirdDone',
        assigneeChildId: 'chi_1',
        createdAt: now.subtract(const Duration(hours: 2)),
      );
      final repo = DriftChildTasksRepository(
        db,
        familyId: 'fam_1',
        childId: 'chi_1',
        clock: () => now,
      );

      final before = await repo.load();
      expect(before.tasks.map((t) => t.id), ['t_pending', 't_todo']);
      expect(before.tasks.last.status, ChildTaskItemStatus.assigned);

      final after = await repo.submitProof('t_todo');
      expect(after.tasks.last.status, ChildTaskItemStatus.pendingApproval);

      final rows = await db.select(db.taskSubmissions).get();
      expect(rows, hasLength(1));
      expect(rows.single.taskId, 't_todo');
      expect(rows.single.childId, 'chi_1');
      // No media picker on this slice: the row says nothing is attached.
      expect(rows.single.mediaRef, '');
      expect(rows.single.status, Stage1RowVocabulary.submissionSubmitted);

      // A task this child cannot see is never touched.
      final untouched = await repo.submitProof('t_assigned');
      expect(untouched.tasks.map((t) => t.id), ['t_pending', 't_todo']);
      expect(await db.select(db.taskSubmissions).get(), hasLength(1));
    });

    test('create-task writes a real row, and lists the real children',
        () async {
      await seed();
      final repo = DriftCreateTaskRepository(
        db,
        familyId: 'fam_1',
        createdByAccount: 'acc_father',
        clock: () => now,
      );

      final loaded = await repo.load();
      expect(loaded.children.map((c) => c.id), ['chi_1', 'chi_2']);
      expect(loaded.children.map((c) => c.nameKey), ['childOne', 'childTwo']);
      expect(loaded.submittedCount, 3);

      await repo.submitTask(
        const CreateTaskDraft(
          title: 'ترتيب الغرفة قبل النوم',
          assigneeNameKey: 'childTwo',
          courageMinutes: CreateTaskCourageMinutes.twentyFive,
          playtimeMinutes: CreateTaskPlaytimeMinutes.ten,
        ),
      );

      final stored =
          await (db.select(db.tasks)
                ..where((t) => t.titleRef.equals('ترتيب الغرفة قبل النوم')))
              .getSingle();
      expect(stored.assigneeChildId, 'chi_2');
      expect(stored.kind, Stage1RowVocabulary.taskKindChore);
      // The payout is the two rewards summed, and the split survives.
      expect(stored.rewardMinutes, 35);
      expect(stored.courageMinutes, 25);
      expect(stored.playtimeMinutes, 10);
      expect(stored.createdByAccount, 'acc_father');
      expect(stored.status, Stage1RowVocabulary.statusAssigned);

      // The mother's lane is a help row with no child attached.
      await repo.submitTask(
        const CreateTaskDraft(
          title: 'قائمة المدرسة',
          assigneeNameKey: 'mother',
        ),
      );
      final help =
          await (db.select(db.tasks)
                ..where((t) => t.titleRef.equals('قائمة المدرسة')))
              .getSingle();
      expect(help.kind, Stage1RowVocabulary.taskKindHelp);
      expect(help.assigneeChildId, isNull);

      // An empty title writes nothing …
      final before = (await db.select(db.tasks).get()).length;
      await repo.submitTask(const CreateTaskDraft(title: '   '));
      expect((await db.select(db.tasks).get()).length, before);

      // … and a family with no children writes nothing either.
      final none = DriftCreateTaskRepository(
        db,
        familyId: 'fam_empty',
        clock: () => now,
      );
      expect((await none.load()).isEmpty, isTrue);
      final refused = await none.submitTask(
        const CreateTaskDraft(title: 'shouldNotLand'),
      );
      expect(refused.isEmpty, isTrue);
      expect((await db.select(db.tasks).get()).length, before);
    });

    test('the chore split approves and rotates in storage', () async {
      await seed();
      Future<void> split(
        String id,
        String childId,
        String chores,
        String note,
      ) => db.into(db.choreDistributions).insert(
        ChoreDistributionsCompanion.insert(
          id: id,
          familyId: 'fam_1',
          childId: childId,
          choresRef: chores,
          noteRef: Value(note),
          createdAt: Value(now),
        ),
      );
      await split('c_1', 'chi_1', 'dishesPlants', 'examTue');
      await split('c_2', 'chi_2', 'livingLaundry', 'rotated');

      final repo = DriftSmartChoreDistributorRepository(
        db,
        familyId: 'fam_1',
      );
      final loaded = await repo.load();
      expect(loaded.hasFamily, isTrue);
      expect(loaded.assignments.map((a) => a.childLabelKey), [
        'childOne',
        'childTwo',
      ]);
      expect(loaded.assignments.first.choresKey, 'dishesPlants');
      expect(loaded.approved, isFalse);

      expect((await repo.approve()).approved, isTrue);

      final shuffled = await repo.shuffle();
      expect(shuffled.approved, isFalse);
      expect(shuffled.assignments.map((a) => a.choresKey), [
        'livingLaundry',
        'dishesPlants',
      ]);
      // The note belongs to the child, not to the chore — it stays put.
      expect(shuffled.assignments.map((a) => a.noteKey), [
        'examTue',
        'rotated',
      ]);

      // ADR-042 — the rotation is a stored fact, not a widget state.
      final row =
          await (db.select(db.choreDistributions)
                ..where((c) => c.id.equals('c_1')))
              .getSingle();
      expect(row.choresRef, 'livingLaundry');
      expect(row.approved, isFalse);
    });
  });
}
