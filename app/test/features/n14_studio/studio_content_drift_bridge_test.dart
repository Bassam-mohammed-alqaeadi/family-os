import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/data/family_database.dart';
import 'package:family_os/core/data/stage1_row_vocabulary.dart';
import 'package:family_os/features/education/approved_pack_repository.dart';
import 'package:family_os/features/n14_studio/add_from_source_repository.dart';
import 'package:family_os/features/n14_studio/generation_outputs_models.dart';
import 'package:family_os/features/n14_studio/materials_lessons_models.dart';
import 'package:family_os/features/n14_studio/preview_approve_models.dart';
import 'package:family_os/features/n14_studio/staged_project_models.dart';
import 'package:family_os/features/n14_studio/studio_content_bridge.dart';

/// DEV-6b — the content side of the studio
/// (SCR-FAT-041 · 043 · 044 · 047 · 048) over the ADR-054 v6 rows:
/// `content_pack` · `content_item` · `learning_path` / `learning_path_stop` ·
/// `wallet_ledger`.
void main() {
  group('studio content over real rows', () {
    late Directory dir;
    late File file;
    late FamilyDatabase db;
    late DateTime now;
    var dbClosed = false;

    setUp(() async {
      dbClosed = false;
      now = DateTime(2026, 9, 24, 12);
      dir = await Directory.systemTemp.createTemp('dev6b_');
      file = File('${dir.path}/dev6b.sqlite');
      db = FamilyDatabase(NativeDatabase(file));
    });

    tearDown(() async {
      if (!dbClosed) await db.close();
      await dir.delete(recursive: true);
    });

    Future<void> child(String id, {String familyId = 'fam_1'}) =>
        db.into(db.children).insert(
          ChildrenCompanion.insert(
            id: id,
            familyId: familyId,
            displayName: 'Child $id',
            alias: '${id}_alias',
            createdAt: Value(now.subtract(const Duration(days: 90))),
          ),
        );

    Future<void> pack({
      required String id,
      required String kind,
      String sourceRef = Stage1RowVocabulary.sourceKindFamily,
      String status = Stage1RowVocabulary.packStatusStaged,
      String? difficulty,
      String familyId = 'fam_1',
      DateTime? createdAt,
    }) => db.into(db.contentPacks).insert(
      ContentPacksCompanion.insert(
        id: id,
        familyId: familyId,
        kind: kind,
        sourceRef: sourceRef,
        status: status,
        difficulty: Value(difficulty),
        createdByAccount: 'acc_1',
        createdAt: Value(createdAt ?? now),
        updatedAt: Value(createdAt ?? now),
      ),
    );

    Future<void> item({
      required String id,
      required String packId,
      required String kind,
      String? titleRef,
      String? bodyRef,
      int? ruleSeconds,
      int sortOrder = 0,
      bool phaseLocked = false,
    }) => db.into(db.contentItems).insert(
      ContentItemsCompanion.insert(
        id: id,
        packId: packId,
        kind: kind,
        titleRef: titleRef ?? id,
        bodyRef: Value(bodyRef),
        ruleSeconds: Value(ruleSeconds),
        sortOrder: Value(sortOrder),
        phaseLocked: Value(phaseLocked),
      ),
    );

    Future<void> path({
      required String id,
      required String childId,
      String subjectRef = 'homeGarden',
      int progressPercent = 0,
      int completedLessons = 0,
      DateTime? createdAt,
    }) => db.into(db.learningPaths).insert(
      LearningPathsCompanion.insert(
        id: id,
        familyId: 'fam_1',
        childId: childId,
        subjectRef: subjectRef,
        progressPercent: Value(progressPercent),
        completedLessons: Value(completedLessons),
        createdAt: Value(createdAt ?? now),
        updatedAt: Value(createdAt ?? now),
      ),
    );

    Future<void> stop({
      required String id,
      required String pathId,
      required String titleRef,
      required String status,
      int rewardMinutes = 0,
      int sortOrder = 0,
    }) => db.into(db.learningPathStops).insert(
      LearningPathStopsCompanion.insert(
        id: id,
        pathId: pathId,
        titleRef: titleRef,
        status: status,
        kind: 'STAGE',
        rewardMinutes: Value(rewardMinutes),
        sortOrder: Value(sortOrder),
      ),
    );

    DriftPreviewApproveRepository preview({
      ApprovedPackRepository? packs,
      String familyId = 'fam_1',
    }) => DriftPreviewApproveRepository(
      db,
      familyId: familyId,
      childId: 'child_a',
      accountId: 'acc_1',
      clock: () => now,
      packs: packs,
    );

    DriftMaterialsLessonsRepository materials() =>
        DriftMaterialsLessonsRepository(
          db,
          familyId: 'fam_1',
          childId: 'child_a',
          accountId: 'acc_1',
          clock: () => now,
        );

    DriftStagedProjectRepository staged({String childId = 'child_a'}) =>
        DriftStagedProjectRepository(
          db,
          familyId: 'fam_1',
          childId: childId,
          clock: () => now,
        );

    test('preview: the staged pack is the queue and approval moves it', () async {
      await child('child_a');
      await pack(
        id: 'pack_1',
        kind: Stage1RowVocabulary.packKindGenerated,
        sourceRef: Stage1RowVocabulary.sourceKindCamera,
        difficulty: Stage1RowVocabulary.difficultyHarder,
      );
      await item(
        id: 'item_q1',
        packId: 'pack_1',
        kind: Stage1RowVocabulary.itemKindQuiz,
        titleRef: 'q1',
        // The options the contract keeps no table for: `key:1` = the correct one.
        bodyRef: 'q1a:1;q1b:0;q1c:0',
        ruleSeconds: 90,
      );
      await item(
        id: 'item_l1',
        packId: 'pack_1',
        kind: Stage1RowVocabulary.itemKindLesson,
        titleRef: 'pizza',
        sortOrder: 1,
      );

      final packs = InMemoryApprovedPackRepository();
      final repo = preview(packs: packs);
      final snap = await repo.load();

      expect(snap.questions, hasLength(1));
      expect(snap.questions.single.promptKey, 'q1');
      expect(
        snap.questions.single.options.map((o) => o.id),
        ['q1a', 'q1b', 'q1c'],
      );
      expect(snap.questions.single.options.first.isCorrect, isTrue);
      expect(snap.questions.single.options[1].isCorrect, isFalse);
      expect(snap.lesson?.summaryKey, 'pizza');
      expect(snap.ruleSeconds, 90);
      expect(snap.difficulty, PreviewDifficulty.harder);
      expect(snap.elapsedSeconds, 0, reason: 'لا عمود لزمن المعاينة');
      expect(snap.canApprove, isTrue);

      final approved = await repo.approve();

      expect(approved.isEmpty, isTrue, reason: 'الرفّ خرج من الطابور');
      final row = (await db.select(db.contentPacks).get()).single;
      expect(row.status, Stage1RowVocabulary.packStatusApproved);
      expect(row.approvedAt, isNotNull);
      expect(row.approvedByAccount, 'acc_1');
      // The child's own load seam got the pack on the same snapshot.
      expect(await packs.latestApproved(), isNotNull);
    });

    test('preview: rejecting leaves the queue, and no pack reads empty', () async {
      final repo = preview(packs: InMemoryApprovedPackRepository());
      final empty = await repo.load();

      expect(empty.isEmpty, isTrue);
      expect(empty.canApprove, isFalse);
      await repo.approve();
      await repo.reject();
      expect(await db.select(db.contentPacks).get(), isEmpty);

      await child('child_a');
      await pack(
        id: 'pack_1',
        kind: Stage1RowVocabulary.packKindGenerated,
      );
      await item(
        id: 'item_q1',
        packId: 'pack_1',
        kind: Stage1RowVocabulary.itemKindQuiz,
        bodyRef: 'q1a:1',
      );

      final rejected = await repo.reject();

      expect(rejected.isEmpty, isTrue);
      final row = (await db.select(db.contentPacks).get()).single;
      expect(row.status, Stage1RowVocabulary.packStatusRejected);
      expect(row.approvedAt, isNull);
      expect(row.approvedByAccount, isNull);
    });

    test('materials: subjects are packs and the counts are their items', () async {
      await child('child_a');
      await pack(
        id: 'pack_math',
        kind: Stage1RowVocabulary.subjectKindMath,
        status: Stage1RowVocabulary.packStatusDraft,
      );
      await item(
        id: 'math_l1',
        packId: 'pack_math',
        kind: Stage1RowVocabulary.itemKindLesson,
      );
      await item(
        id: 'math_l2',
        packId: 'pack_math',
        kind: Stage1RowVocabulary.itemKindLesson,
        sortOrder: 1,
      );
      await item(
        id: 'math_q1',
        packId: 'pack_math',
        kind: Stage1RowVocabulary.itemKindQuiz,
        sortOrder: 2,
      );
      await pack(
        id: 'pack_science',
        kind: Stage1RowVocabulary.subjectKindScience,
        status: Stage1RowVocabulary.packStatusDraft,
      );

      final repo = materials();
      final snap = await repo.load();

      expect(snap.subjects.map((s) => s.id), ['pack_math', 'pack_science']);
      final math = snap.subjects.first;
      expect(math.kind, MaterialsSubjectKind.math);
      expect(math.titleKey, 'math');
      expect(math.subtitleKey, 'lessonCount');
      expect(math.lessons, 2);
      expect(math.quizzes, 1);
      expect(math.flashcards, 0);
      expect(math.hasActivePath, isFalse);
      expect(snap.subjects[1].kind, MaterialsSubjectKind.science);
      expect(snap.subjects[1].lessons, 0);

      // A path only shows where a real row exists.
      await path(id: 'path_1', childId: 'child_a', subjectRef: 'pack_math');
      expect((await repo.load()).subjects.first.hasActivePath, isTrue);

      final created = await repo.addSubject();
      expect(created.kind, MaterialsSubjectKind.custom);
      expect(created.titleKey, 'custom');
      expect(await db.select(db.contentPacks).get(), hasLength(3));

      final updated = await repo.addLesson(subjectId: 'pack_math');
      expect(updated.id, 'pack_math');
      expect(updated.lessons, 3);
      expect(updated.quizzes, 1);
      expect(
        await db.select(db.contentItems).get(),
        hasLength(4),
        reason: 'درس واحد أُضيف فعلًا',
      );
    });

    test('generation: the staged pack\'s items carry their own P1 gate', () async {
      await pack(
        id: 'pack_1',
        kind: Stage1RowVocabulary.packKindGenerated,
        sourceRef: Stage1RowVocabulary.sourceKindCamera,
      );
      await item(
        id: 'out_lesson',
        packId: 'pack_1',
        kind: Stage1RowVocabulary.itemKindLesson,
      );
      await item(
        id: 'out_quiz',
        packId: 'pack_1',
        kind: Stage1RowVocabulary.itemKindQuiz,
        sortOrder: 1,
      );
      await item(
        id: 'out_review',
        packId: 'pack_1',
        kind: Stage1RowVocabulary.itemKindReviewGame,
        sortOrder: 2,
        phaseLocked: true,
      );

      final snap = await DriftGenerationOutputsRepository(
        db,
        familyId: 'fam_1',
        clock: () => now,
      ).load();

      expect(snap.sourceKey, 'addFromSourceCameraTitle');
      expect(snap.outputs.map((o) => o.id), [
        'out_lesson',
        'out_quiz',
        'out_review',
      ]);
      expect(snap.outputs[0].kind, GenerationOutputKind.lesson);
      expect(snap.outputs[1].kind, GenerationOutputKind.quiz);
      expect(snap.outputs[2].kind, GenerationOutputKind.reviewGame);
      // The gate is a column: a locked output is never chosen.
      expect(snap.outputs[2].phaseLocked, isTrue);
      expect(snap.outputs[2].selected, isFalse);
      expect(snap.outputs[0].selected, isTrue);
      expect(snap.selectedCount, 2);

      // Nothing staged → nothing generated.
      final none = await DriftGenerationOutputsRepository(
        db,
        familyId: 'fam_none',
        clock: () => now,
      ).load();
      expect(none.isEmpty, isTrue);
    });

    test('staged project: the path row and its stops are the project', () async {
      await child('child_a');
      await path(
        id: 'path_1',
        childId: 'child_a',
        progressPercent: 40,
        completedLessons: 1,
        createdAt: now.subtract(const Duration(days: 14)),
      );
      await stop(
        id: 's1',
        pathId: 'path_1',
        titleRef: 'research',
        status: Stage1RowVocabulary.statusDone,
        rewardMinutes: 30,
      );
      await stop(
        id: 's2',
        pathId: 'path_1',
        titleRef: 'plant',
        status: Stage1RowVocabulary.stopStatusActive,
        rewardMinutes: 40,
        sortOrder: 1,
      );
      await stop(
        id: 's3',
        pathId: 'path_1',
        titleRef: 'water',
        status: Stage1RowVocabulary.stopStatusLocked,
        rewardMinutes: 50,
        sortOrder: 2,
      );
      await stop(
        id: 's4',
        pathId: 'path_1',
        titleRef: 'harvest',
        status: Stage1RowVocabulary.stopStatusLocked,
        rewardMinutes: 80,
        sortOrder: 3,
      );

      final snap = await staged().load();

      expect(snap.isEmpty, isFalse);
      expect(snap.titleKey, 'homeGarden');
      expect(snap.childLabelKey, 'childOne');
      expect(snap.stageCount, 4);
      expect(snap.currentStage, 2);
      expect(snap.progress, closeTo(0.4, 0.001));
      expect(snap.weeks, 3, reason: 'أسبوعان + الأسبوع الجاري من عمر الصفّ');
      expect(snap.stages.map((s) => s.status), [
        ProjectStageStatus.done,
        ProjectStageStatus.active,
        ProjectStageStatus.locked,
        ProjectStageStatus.locked,
      ]);
      expect(snap.stages.first.subKey, 'researchSub');
      expect(snap.stages[1].rewardMinutes, 40);

      final none = await DriftStagedProjectRepository(
        db,
        familyId: 'fam_none',
        clock: () => now,
      ).load();
      expect(none.isEmpty, isTrue);
    });

    test('staged project: confirming pays the stage and opens the next (ADR-042)', () async {
      await child('child_a');
      await path(
        id: 'path_1',
        childId: 'child_a',
        createdAt: now.subtract(const Duration(days: 3)),
      );
      await stop(
        id: 's1',
        pathId: 'path_1',
        titleRef: 'research',
        status: Stage1RowVocabulary.statusDone,
        rewardMinutes: 30,
      );
      await stop(
        id: 's2',
        pathId: 'path_1',
        titleRef: 'plant',
        status: Stage1RowVocabulary.stopStatusActive,
        rewardMinutes: 40,
        sortOrder: 1,
      );
      await stop(
        id: 's3',
        pathId: 'path_1',
        titleRef: 'water',
        status: Stage1RowVocabulary.stopStatusLocked,
        rewardMinutes: 50,
        sortOrder: 2,
      );

      final repo = staged();
      final snap = await repo.confirmActiveStage();

      expect(snap.currentStage, 3);
      // The row keeps whole percents, so the bar is the stored 67%.
      expect(snap.progress, closeTo(0.67, 0.001));
      expect(snap.stages[1].status, ProjectStageStatus.done);
      expect(snap.stages[2].status, ProjectStageStatus.active);

      final pathRow = (await db.select(db.learningPaths).get()).single;
      expect(pathRow.completedLessons, 2);
      expect(pathRow.progressPercent, (2 / 3 * 100).round());

      // Minutes only (ع-١), and the entry points back at the project.
      final entries = await db.select(db.walletLedgerEntries).get();
      expect(entries, hasLength(1));
      expect(entries.single.deltaMinutes, 40);
      expect(entries.single.reason, Stage1RowVocabulary.walletEarned);
      expect(entries.single.sourceRef, 'path_1');
      expect(entries.single.childId, 'child_a');

      // A project standing on no active stage pays nothing.
      await child('child_b');
      await path(id: 'path_b', childId: 'child_b');
      await stop(
        id: 'b1',
        pathId: 'path_b',
        titleRef: 'research',
        status: Stage1RowVocabulary.statusDone,
        rewardMinutes: 60,
      );
      await DriftStagedProjectRepository(
        db,
        familyId: 'fam_1',
        childId: 'child_b',
        clock: () => now,
      ).confirmActiveStage();
      expect(
        await db.select(db.walletLedgerEntries).get(),
        hasLength(1),
        reason: 'لا مرحلة جارية ⇒ لا مكافأة',
      );

      // ADR-042 — the ladder and the payment outlive the connection.
      await db.close();
      dbClosed = true;
      db = FamilyDatabase(NativeDatabase(file));

      final reopened = await staged().load();
      expect(reopened.stages[1].status, ProjectStageStatus.done);
      expect(reopened.stages[2].status, ProjectStageStatus.active);
      expect(await db.select(db.walletLedgerEntries).get(), hasLength(1));
    });

    test('add from source: the gate stages a real pack (and a scope with no family stages nothing)', () async {
      final repo = DriftAddFromSourceRepository(
        db,
        familyId: 'fam_1',
        accountId: 'acc_1',
        clock: () => now,
      );

      final result = await repo.addSource(AddSourceKind.camera);

      expect(result.kind, AddSourceKind.camera);
      expect(result.packId, isNotEmpty);
      final row = (await db.select(db.contentPacks).get()).single;
      expect(row.kind, Stage1RowVocabulary.packKindGenerated);
      expect(row.sourceRef, Stage1RowVocabulary.sourceKindCamera);
      expect(row.status, Stage1RowVocabulary.packStatusStaged);
      expect(row.createdByAccount, 'acc_1');

      // The pack it staged is the one the next surfaces work on.
      final outputs = await DriftGenerationOutputsRepository(
        db,
        familyId: 'fam_1',
        clock: () => now,
      ).load();
      expect(outputs.sourceKey, 'addFromSourceCameraTitle');
      expect(outputs.isEmpty, isTrue, reason: 'لم يُولَّد بعد شيء');

      // No family scope → nothing staged, nothing claimed.
      final none = await DriftAddFromSourceRepository(
        db,
        familyId: '',
        clock: () => now,
      ).addSource(AddSourceKind.pdf);
      expect(none.packId, isEmpty);
      expect(await db.select(db.contentPacks).get(), hasLength(1));
    });
  });
}
