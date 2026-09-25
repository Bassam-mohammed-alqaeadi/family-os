import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/data/family_database.dart';
import 'package:family_os/core/data/stage1_row_vocabulary.dart';
import 'package:family_os/features/n17_child_learn/child_quran_ward_models.dart';
import 'package:family_os/features/n17_child_learn/learn_followup_bridge.dart';

/// DEV-6d — the child's learning surfaces on the ADR-054 v6 rows:
/// `learning_path` / `learning_path_stop` · `content_pack` / `content_item` ·
/// `learn_skill_gap` / `learn_session` / `learn_assignment` /
/// `wallet_ledger` · `quran_plan` / `quran_recitation` / `quran_memorization` /
/// `learn_achievement`.
void main() {
  group('child learning over real rows', () {
    late Directory dir;
    late File file;
    late FamilyDatabase db;
    late DateTime now;
    var dbClosed = false;

    setUp(() async {
      dbClosed = false;
      now = DateTime(2026, 9, 25, 12);
      dir = await Directory.systemTemp.createTemp('dev6d_');
      file = File('${dir.path}/dev6d.sqlite');
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

    Future<void> path({
      String id = 'path_1',
      String childId = 'kid_1',
      String subjectRef = 'fractions',
      int progressPercent = 40,
      int completedLessons = 2,
      int totalLessons = 5,
    }) => db.into(db.learningPaths).insert(
      LearningPathsCompanion.insert(
        id: id,
        familyId: 'fam_1',
        childId: childId,
        subjectRef: subjectRef,
        progressPercent: Value(progressPercent),
        completedLessons: Value(completedLessons),
        totalLessons: Value(totalLessons),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );

    Future<void> stop({
      required String id,
      String pathId = 'path_1',
      required String titleRef,
      required String status,
      String kind = Stage1RowVocabulary.itemKindLesson,
      int? masteryPercent,
      int rewardMinutes = 0,
      int sortOrder = 0,
    }) => db.into(db.learningPathStops).insert(
      LearningPathStopsCompanion.insert(
        id: id,
        pathId: pathId,
        titleRef: titleRef,
        status: status,
        kind: kind,
        masteryPercent: Value(masteryPercent),
        rewardMinutes: Value(rewardMinutes),
        sortOrder: Value(sortOrder),
      ),
    );

    Future<void> pack({
      required String id,
      String kind = Stage1RowVocabulary.packKindFlashcards,
      String sourceRef = 'schoolFractions',
      String status = Stage1RowVocabulary.packStatusApproved,
    }) => db.into(db.contentPacks).insert(
      ContentPacksCompanion.insert(
        id: id,
        familyId: 'fam_1',
        kind: kind,
        sourceRef: sourceRef,
        status: status,
        createdByAccount: 'acc_1',
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );

    Future<void> item({
      required String id,
      required String packId,
      String kind = Stage1RowVocabulary.itemKindFlashcards,
      required String titleRef,
      String? bodyRef,
      int sortOrder = 0,
    }) => db.into(db.contentItems).insert(
      ContentItemsCompanion.insert(
        id: id,
        packId: packId,
        kind: kind,
        titleRef: titleRef,
        bodyRef: Value(bodyRef),
        sortOrder: Value(sortOrder),
      ),
    );

    Future<void> assignment({
      String id = 'assign_1',
      String childId = 'kid_1',
      String contentRef = 'schoolFractions',
      int rewardMinutes = 50,
      String status = Stage1RowVocabulary.learnAssigned,
    }) => db
        .into(db.learnAssignments)
        .insert(
          LearnAssignmentsCompanion.insert(
            id: id,
            familyId: 'fam_1',
            childId: childId,
            kind: Stage1RowVocabulary.learnKindHomework,
            contentRef: contentRef,
            rewardMinutes: Value(rewardMinutes),
            status: status,
            assignedByAccount: 'acc_1',
            requestId: 'req_$id',
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

    Future<void> gap({
      String id = 'gap_1',
      String childId = 'kid_1',
      String skillRef = 'times7',
      String status = Stage1RowVocabulary.learnOpen,
    }) => db.into(db.learnSkillGaps).insert(
      LearnSkillGapsCompanion.insert(
        id: id,
        childId: childId,
        skillRef: skillRef,
        missed: const Value(3),
        total: const Value(8),
        status: status,
        updatedAt: Value(now),
      ),
    );

    Future<void> memorization({
      required String id,
      String childId = 'kid_1',
      required String surahRef,
      int progress = 0,
      int extraAyahs = 0,
    }) => db.into(db.quranMemorizations).insert(
      QuranMemorizationsCompanion.insert(
        id: id,
        childId: childId,
        surahRef: surahRef,
        progress: Value(progress),
        extraAyahs: Value(extraAyahs),
        updatedAt: Value(now),
      ),
    );

    Future<void> achievement({
      required String id,
      String childId = 'kid_1',
      required String badgeRef,
      String kind = 'QURAN',
    }) => db.into(db.learnAchievements).insert(
      LearnAchievementsCompanion.insert(
        id: id,
        familyId: 'fam_1',
        childId: childId,
        badgeRef: badgeRef,
        kind: kind,
        earnedAt: Value(now),
        sourceRef: const Value('hifz'),
      ),
    );

    Future<void> plan({
      String id = 'plan_1',
      String childId = 'kid_1',
      String surahRef = 'mulk',
      int fromAyah = 1,
      int toAyah = 30,
      String reciterRef = 'defaultReciter',
      int rewardMinutes = 30,
      bool offlineReady = true,
      bool active = true,
    }) => db.into(db.quranPlans).insert(
      QuranPlansCompanion.insert(
        id: id,
        familyId: 'fam_1',
        childId: childId,
        surahRef: surahRef,
        fromAyah: fromAyah,
        toAyah: toAyah,
        reciterRef: reciterRef,
        rewardMinutes: Value(rewardMinutes),
        offlineReady: Value(offlineReady),
        active: Value(active),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );

    Future<void> recitation({
      required String id,
      String planId = 'plan_1',
      String childId = 'kid_1',
      String status = Stage1RowVocabulary.recitationPending,
      int completedAyahs = 0,
      String? dueDay,
    }) => db.into(db.quranRecitations).insert(
      QuranRecitationsCompanion.insert(
        id: id,
        planId: planId,
        childId: childId,
        day: '2026-09-25',
        kind: Stage1RowVocabulary.learnKindReview,
        status: status,
        completedAyahs: Value(completedAyahs),
        dueDay: Value(dueDay),
        createdAt: Value(now),
      ),
    );

    Future<void> ledger({
      required String id,
      String childId = 'kid_1',
      required int deltaMinutes,
      String? sourceRef,
    }) => db
        .into(db.walletLedgerEntries)
        .insert(
          WalletLedgerEntriesCompanion.insert(
            id: id,
            familyId: 'fam_1',
            childId: childId,
            deltaMinutes: deltaMinutes,
            reason: Stage1RowVocabulary.walletEarned,
            sourceRef: Value(sourceRef),
            createdAt: Value(now),
          ),
        );

    test('the lesson is the path active stop, not a planted slide', () async {
      await child('kid_1');
      await path();
      await stop(
        id: 'stop_1',
        titleRef: 'concept',
        status: Stage1RowVocabulary.statusDone,
        masteryPercent: 100,
        sortOrder: 0,
      );
      await stop(
        id: 'stop_2',
        titleRef: 'adding',
        status: Stage1RowVocabulary.stopStatusActive,
        rewardMinutes: 12,
        sortOrder: 1,
      );
      await stop(
        id: 'stop_3',
        titleRef: 'finalQuiz',
        status: Stage1RowVocabulary.stopStatusLocked,
        kind: Stage1RowVocabulary.itemKindQuiz,
        rewardMinutes: 20,
        sortOrder: 2,
      );

      final snap = await DriftChildLessonRepository(
        db,
        familyId: 'fam_1',
        childId: 'kid_1',
        clock: () => now,
      ).load();

      expect(snap.titleKey, 'adding');
      expect(snap.progressPercent, 40);
      expect(snap.rewardMinutes, 12);
      // One slice per lesson the path holds, filled by its own counter.
      expect(snap.pizzaFilled, [true, true, false, false, false]);
      // The hook and the body are editorial copy with no column.
      expect(snap.hookKey, isNull);
      expect(snap.bodyKey, isNull);
    });

    test('the flashcards are the pack own items in order', () async {
      await child('kid_1');
      await pack(id: 'pack_1');
      await item(
        id: 'card_1',
        packId: 'pack_1',
        titleRef: 'oneThird',
        bodyRef: 'oneThirdAnswer',
        sortOrder: 0,
      );
      await item(
        id: 'card_2',
        packId: 'pack_1',
        titleRef: 'twoFifths',
        bodyRef: 'twoFifthsAnswer',
        sortOrder: 1,
      );
      // A lesson item in the same pack is not a card.
      await item(
        id: 'lesson_1',
        packId: 'pack_1',
        kind: Stage1RowVocabulary.itemKindLesson,
        titleRef: 'intro',
        sortOrder: 2,
      );
      await assignment();

      final repo = DriftChildFlashcardsRepository(
        db,
        familyId: 'fam_1',
        childId: 'kid_1',
        clock: () => now,
      );
      final snap = await repo.load();

      expect(snap.cards.map((c) => c.id).toList(), ['card_1', 'card_2']);
      expect(snap.cards.first.questionKey, 'oneThird');
      expect(snap.cards.first.answerKey, 'oneThirdAnswer');
      expect(snap.lessonTitleKey, 'schoolFractions');
      expect(snap.sourceNameKey, Stage1RowVocabulary.packKindFlashcards);
      // The reward is the assignment's own number.
      expect(snap.quizRewardMinutes, 50);

      final flipped = await repo.flip();
      expect(flipped.flipped, isTrue);
      final next = await repo.next();
      expect(next.currentIndex, 1);
      expect(next.flipped, isFalse);
    });

    test('the smart plan reads the gap and the path, and acts on rows', () async {
      await child('kid_1');
      await gap();
      await path(
        progressPercent: 33,
        completedLessons: 1,
        totalLessons: 3,
      );
      await stop(
        id: 'stop_1',
        titleRef: 'concept',
        status: Stage1RowVocabulary.statusDone,
        masteryPercent: 100,
        sortOrder: 0,
      );
      await stop(
        id: 'stop_2',
        titleRef: 'adding',
        status: Stage1RowVocabulary.stopStatusActive,
        rewardMinutes: 15,
        sortOrder: 1,
      );
      await stop(
        id: 'stop_3',
        titleRef: 'finalQuiz',
        status: Stage1RowVocabulary.stopStatusLocked,
        kind: Stage1RowVocabulary.itemKindQuiz,
        rewardMinutes: 20,
        sortOrder: 2,
      );

      final repo = DriftChildSmartPlanRepository(
        db,
        familyId: 'fam_1',
        childId: 'kid_1',
        clock: () => now,
      );
      final before = await repo.load();
      expect(before.hasPlan, isTrue);
      expect(before.gapKey, 'times7');
      expect(before.projectKey, 'fractions');
      expect(before.projectStageKey, 'adding');
      expect(before.projectDone, isFalse);
      expect(before.pathDone, 1);
      expect(before.pathTotal, 3);
      expect(before.planStarted, isFalse);

      final started = await repo.startRepairPlan();
      expect(started.planStarted, isTrue);
      final sittings = await db.select(db.learnSessions).get();
      expect(sittings.length, 1);
      expect(sittings.single.kind, Stage1RowVocabulary.learnKindReview);
      expect(sittings.single.requestId, 'times7');
      expect(sittings.single.contentRef, 'times7');
      // Starting again does not stack a second sitting.
      await repo.startRepairPlan();
      expect((await db.select(db.learnSessions).get()).length, 1);

      final completed = await repo.completeProjectStage();
      expect(completed.projectStageKey, 'finalQuiz');
      expect(completed.projectDone, isFalse);
      expect(completed.pathDone, 2);
      expect(completed.pathTotal, 3);

      final stops = await db.select(db.learningPathStops).get();
      expect(
        stops.firstWhere((s) => s.id == 'stop_2').status,
        Stage1RowVocabulary.statusDone,
      );
      expect(
        stops.firstWhere((s) => s.id == 'stop_3').status,
        Stage1RowVocabulary.stopStatusActive,
      );
      final entries = await db.select(db.walletLedgerEntries).get();
      expect(entries.single.deltaMinutes, 15);
      expect(entries.single.sourceRef, 'adding');
      final pathRow =
          await (db.select(db.learningPaths)
                ..where((t) => t.id.equals('path_1')))
              .getSingle();
      expect(pathRow.progressPercent, 67);
      expect(pathRow.completedLessons, 2);
    });

    test('memorisation reads its own rows, badges and reviews', () async {
      await child('kid_1');
      await plan();
      await memorization(
        id: 'mem_1',
        surahRef: 'mulk',
        progress: 60,
        extraAyahs: 4,
      );
      await memorization(id: 'mem_2', surahRef: 'naba', progress: 25);
      await achievement(id: 'badge_1', badgeRef: 'hifzFive');
      await recitation(
        id: 'rec_1',
        status: Stage1RowVocabulary.recitationApproved,
        completedAyahs: 30,
        dueDay: '2026-09-25',
      );
      await recitation(id: 'rec_2');

      final repo = DriftChildMemorizationRepository(
        db,
        familyId: 'fam_1',
        childId: 'kid_1',
        clock: () => now,
      );
      final snap = await repo.load();

      expect(snap.hasProgress, isTrue);
      expect(snap.surahCount, 2);
      expect(snap.extraAyahs, 4);
      expect(snap.surahs.map((s) => s.nameKey).toList(), ['mulk', 'naba']);
      expect(snap.surahs.first.progress, 0.6);
      expect(snap.surahs.last.progress, 0.25);
      expect(snap.badges.single.labelKey, 'hifzFive');
      expect(snap.badges.single.earned, isTrue);

      final byId = {for (final r in snap.reviews) r.id: r};
      expect(byId.length, 2);
      // A recitation row carries its plan — the plan names the surah.
      expect(byId['rec_2']!.titleKey, 'mulk');
      expect(byId['rec_2']!.dueToday, isTrue);
      expect(byId['rec_1']!.metaKey, Stage1RowVocabulary.recitationApproved);

      await repo.startReview('rec_2');
      final sittings = await db.select(db.learnSessions).get();
      expect(sittings.single.kind, Stage1RowVocabulary.learnKindReview);
      expect(sittings.single.requestId, 'rec_2');
      expect(sittings.single.contentRef, 'mulk');
    });

    test('smart tilawah is the plan, and its device work writes no row', () async {
      await child('kid_1');
      final empty = await DriftChildSmartTilawahRepository(
        db,
        familyId: 'fam_1',
        childId: 'kid_1',
        clock: () => now,
      ).load();
      expect(empty.hasSession, isFalse);

      await plan(fromAyah: 5, toAyah: 30);
      final repo = DriftChildSmartTilawahRepository(
        db,
        familyId: 'fam_1',
        childId: 'kid_1',
        clock: () => now,
      );
      final snap = await repo.load();
      expect(snap.hasSession, isTrue);
      expect(snap.surahKey, 'mulk');
      expect(snap.ayahNumber, 5);
      expect(snap.ayahKey, 'mulk5');
      expect(snap.listening, isFalse);
      expect(snap.sheikhPlayed, isFalse);

      final listening = await repo.startListening();
      expect(listening.listening, isTrue);
      final played = await repo.playSheikh();
      expect(played.sheikhPlayed, isTrue);
      expect(await db.select(db.learnSessions).get(), isEmpty);
    });

    test('the ward submits a real recitation and counts real gifts', () async {
      await child('kid_1');
      await plan();
      final repo = DriftChildQuranWardRepository(
        db,
        familyId: 'fam_1',
        childId: 'kid_1',
        clock: () => now,
      );
      final before = await repo.load();
      expect(before.hasWard, isTrue);
      expect(before.surahKey, 'mulk');
      expect(before.fromAyah, 1);
      expect(before.toAyah, 30);
      expect(before.ayahKey, 'mulk1');
      expect(before.reciterKey, 'defaultReciter');
      expect(before.rewardMinutes, 30);
      expect(before.offlineReady, isTrue);
      expect(before.recitationStatus, ChildWardRecitationStatus.none);
      expect(before.giftCount, 0);
      expect(before.playing, isFalse);

      final sent = await repo.submitRecitation();
      expect(sent.recitationStatus, ChildWardRecitationStatus.sent);
      final rows = await db.select(db.quranRecitations).get();
      expect(rows.single.status, Stage1RowVocabulary.recitationPending);
      // The submission covers the plan's own range — no timer is invented.
      expect(rows.single.completedAyahs, 30);
      expect(rows.single.day, '2026-09-25');
      expect(rows.single.planId, 'plan_1');

      // The father approves the same row → the child reads it approved.
      await (db.update(
        db.quranRecitations,
      )..where((t) => t.id.equals(rows.single.id))).write(
        QuranRecitationsCompanion(
          status: const Value(Stage1RowVocabulary.recitationApproved),
        ),
      );
      final approved = await repo.load();
      expect(approved.recitationStatus, ChildWardRecitationStatus.approved);

      await ledger(id: 'gift_1', deltaMinutes: 15);
      await ledger(id: 'spend_1', deltaMinutes: -5);
      final withGifts = await repo.load();
      expect(withGifts.giftCount, 1);

      final playing = await repo.togglePlay();
      expect(playing.playing, isTrue);
    });

    test('the rows survive closing and reopening the database', () async {
      await child('kid_1');
      await plan();
      await pack(id: 'pack_1');
      await item(id: 'card_1', packId: 'pack_1', titleRef: 'oneThird');
      await memorization(id: 'mem_1', surahRef: 'mulk', progress: 60);

      await db.close();
      dbClosed = true;
      db = FamilyDatabase(NativeDatabase(file));

      final ward = await DriftChildQuranWardRepository(
        db,
        familyId: 'fam_1',
        childId: 'kid_1',
        clock: () => now,
      ).load();
      expect(ward.surahKey, 'mulk');
      expect(ward.toAyah, 30);

      final cards = await DriftChildFlashcardsRepository(
        db,
        familyId: 'fam_1',
        childId: 'kid_1',
        clock: () => now,
      ).load();
      expect(cards.cards.single.questionKey, 'oneThird');

      final memorisation = await DriftChildMemorizationRepository(
        db,
        familyId: 'fam_1',
        childId: 'kid_1',
        clock: () => now,
      ).load();
      expect(memorisation.surahs.single.nameKey, 'mulk');
      expect(memorisation.surahs.single.progress, 0.6);
    });
  });
}
