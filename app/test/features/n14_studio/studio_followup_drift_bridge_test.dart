import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/data/family_database.dart';
import 'package:family_os/core/data/stage1_row_vocabulary.dart';
import 'package:family_os/features/n14_studio/community_library_models.dart';
import 'package:family_os/features/n14_studio/learning_path_models.dart';
import 'package:family_os/features/n14_studio/quran_progress_models.dart';
import 'package:family_os/features/n14_studio/results_followup_models.dart';
import 'package:family_os/features/n14_studio/studio_followup_bridge.dart';

/// DEV-6c — the studio's remaining five surfaces on the ADR-054 v6 rows:
/// `community_cache` · `learning_path` / `learning_path_stop` ·
/// `learn_result` / `learn_skill_gap` / `learn_session` + `wallet_ledger` ·
/// `quran_plan` / `quran_recitation` / `learn_streak`.
void main() {
  group('studio follow-up over real rows', () {
    late Directory dir;
    late File file;
    late FamilyDatabase db;
    late DateTime now;
    var dbClosed = false;

    setUp(() async {
      dbClosed = false;
      now = DateTime(2026, 9, 24, 12);
      dir = await Directory.systemTemp.createTemp('dev6c_');
      file = File('${dir.path}/dev6c.sqlite');
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

    Future<void> communityRow({
      required String id,
      required String kind,
      required String titleRef,
      required String authorRef,
      double rating = 4,
      int ratingCount = 10,
      bool trusted = true,
      int lessons = 0,
      int quizzes = 0,
    }) => db
        .into(db.communityCacheEntries)
        .insert(
          CommunityCacheEntriesCompanion.insert(
            id: id,
            kind: kind,
            titleRef: titleRef,
            authorRef: authorRef,
            rating: Value(rating),
            ratingCount: Value(ratingCount),
            trusted: Value(trusted),
            lessons: Value(lessons),
            quizzes: Value(quizzes),
            fetchedAt: Value(now),
          ),
        );

    Future<void> path({
      required String id,
      required String childId,
      String subjectRef = 'fractions',
      int progressPercent = 0,
      int completedLessons = 0,
      int totalLessons = 0,
      DateTime? updatedAt,
    }) => db.into(db.learningPaths).insert(
      LearningPathsCompanion.insert(
        id: id,
        familyId: 'fam_1',
        childId: childId,
        subjectRef: subjectRef,
        progressPercent: Value(progressPercent),
        completedLessons: Value(completedLessons),
        totalLessons: Value(totalLessons),
        createdAt: Value(updatedAt ?? now),
        updatedAt: Value(updatedAt ?? now),
      ),
    );

    Future<void> stop({
      required String id,
      required String pathId,
      required String titleRef,
      required String status,
      required String kind,
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

    Future<void> result({
      required String id,
      required String childId,
      required String skillRef,
      int correct = 0,
      int total = 0,
      int? masteryPercent,
      DateTime? createdAt,
    }) => db.into(db.learnResults).insert(
      LearnResultsCompanion.insert(
        id: id,
        sessionId: 'session_$id',
        childId: childId,
        skillRef: skillRef,
        correct: Value(correct),
        total: Value(total),
        masteryPercent: Value(masteryPercent),
        createdAt: Value(createdAt ?? now),
      ),
    );

    Future<void> gap({
      required String id,
      required String childId,
      required String skillRef,
      String status = Stage1RowVocabulary.learnOpen,
      int missed = 0,
      int total = 0,
      int? masteryPercent,
      DateTime? updatedAt,
    }) => db.into(db.learnSkillGaps).insert(
      LearnSkillGapsCompanion.insert(
        id: id,
        childId: childId,
        skillRef: skillRef,
        missed: Value(missed),
        total: Value(total),
        masteryPercent: Value(masteryPercent),
        status: status,
        updatedAt: Value(updatedAt ?? now),
      ),
    );

    Future<void> session({
      required String id,
      required String childId,
      required String kind,
      String? contentRef,
      DateTime? startedAt,
    }) => db.into(db.learnSessions).insert(
      LearnSessionsCompanion.insert(
        id: id,
        familyId: 'fam_1',
        childId: childId,
        kind: kind,
        contentRef: Value(contentRef),
        startedAt: Value(startedAt ?? now),
        minutes: const Value(20),
        status: Stage1RowVocabulary.learnDone,
        requestId: 'req_$id',
      ),
    );

    Future<void> ledger({
      required String id,
      required String childId,
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

    Future<void> plan({
      required String id,
      required String childId,
      String surahRef = 'mulk',
      int fromAyah = 1,
      int toAyah = 30,
      String reciterRef = 'defaultReciter',
      int rewardMinutes = 25,
      bool offlineReady = true,
      bool active = true,
      DateTime? createdAt,
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
        createdAt: Value(createdAt ?? now),
        updatedAt: Value(createdAt ?? now),
      ),
    );

    Future<void> recitation({
      required String id,
      required String planId,
      required String childId,
      String status = Stage1RowVocabulary.recitationPending,
      int completedAyahs = 0,
    }) => db.into(db.quranRecitations).insert(
      QuranRecitationsCompanion.insert(
        id: id,
        planId: planId,
        childId: childId,
        day: '2026-09-24',
        kind: Stage1RowVocabulary.learnKindReview,
        status: status,
        completedAyahs: Value(completedAyahs),
        createdAt: Value(now),
      ),
    );

    Future<void> streak({
      required String id,
      required String childId,
      int currentDays = 0,
      int recordDays = 0,
    }) => db.into(db.learnStreaks).insert(
      LearnStreaksCompanion.insert(
        id: id,
        childId: childId,
        kind: Stage1RowVocabulary.learnStreakAll,
        currentDays: Value(currentDays),
        recordDays: Value(recordDays),
        lastDay: const Value('2026-09-24'),
        updatedAt: Value(now),
      ),
    );

    test('community shelf shows the cached rows the family pulled', () async {
      final empty = await DriftCommunityLibraryRepository(
        db,
        familyId: 'fam_1',
        clock: () => now,
      ).load();
      expect(empty.packages, isEmpty);
      expect(empty.publishOffer, isNull);

      await communityRow(
        id: 'pack_low',
        kind: 'fractions',
        titleRef: 'fractions',
        authorRef: 'fatherRiyadh',
        rating: 4.2,
        ratingCount: 120,
        lessons: 8,
        quizzes: 2,
      );
      await communityRow(
        id: 'pack_high',
        kind: 'quran',
        titleRef: 'juzAmma',
        authorRef: 'motherJeddah',
        rating: 4.9,
        ratingCount: 310,
        lessons: 12,
        quizzes: 4,
      );

      final snap = await DriftCommunityLibraryRepository(
        db,
        familyId: 'fam_1',
        clock: () => now,
      ).load();

      expect(snap.packages.map((p) => p.id).toList(), ['pack_high', 'pack_low']);
      expect(snap.packages.first.titleKey, 'juzAmma');
      expect(snap.packages.first.kind, CommunityPackageKind.quran);
      expect(snap.packages.first.authorKey, CommunityAuthorKey.motherJeddah);
      expect(snap.packages.first.rating, 4.9);
      expect(snap.packages.first.lessons, 12);
      expect(snap.packages.last.kind, CommunityPackageKind.fractions);
      expect(snap.packages.last.authorKey, CommunityAuthorKey.fatherRiyadh);
      // Nothing in the contract says a local pack is ready to publish.
      expect(snap.publishOffer, isNull);
    });

    test('learning path reads the child own ladder and stops', () async {
      await child('kid_1');
      await child('kid_2');
      await path(
        id: 'path_1',
        childId: 'kid_1',
        subjectRef: 'fractions',
        progressPercent: 40,
        completedLessons: 2,
        totalLessons: 5,
      );
      await stop(
        id: 'stop_1',
        pathId: 'path_1',
        titleRef: 'concept',
        status: Stage1RowVocabulary.learnMastered,
        kind: Stage1RowVocabulary.itemKindLesson,
        masteryPercent: 100,
        sortOrder: 0,
      );
      await stop(
        id: 'stop_2',
        pathId: 'path_1',
        titleRef: 'similar',
        status: Stage1RowVocabulary.stopStatusActive,
        kind: Stage1RowVocabulary.itemKindLesson,
        masteryPercent: 55,
        sortOrder: 1,
      );
      await stop(
        id: 'stop_3',
        pathId: 'path_1',
        titleRef: 'finalQuiz',
        status: Stage1RowVocabulary.stopStatusLocked,
        kind: Stage1RowVocabulary.itemKindQuiz,
        rewardMinutes: 15,
        sortOrder: 2,
      );

      final snap = await DriftLearningPathRepository(
        db,
        familyId: 'fam_1',
        childId: 'kid_1',
        clock: () => now,
      ).load();

      expect(snap.childNameKey, 'one');
      expect(snap.subjectKey, 'fractions');
      expect(snap.progressPercent, 40);
      expect(snap.completedLessons, 2);
      expect(snap.totalLessons, 5);
      expect(snap.stops.map((s) => s.id).toList(), [
        'stop_1',
        'stop_2',
        'stop_3',
      ]);
      expect(snap.stops.map((s) => s.status).toList(), [
        LearningStopStatus.mastered,
        LearningStopStatus.current,
        LearningStopStatus.locked,
      ]);
      expect(snap.stops.first.subtitleKey, 'mastered');
      expect(snap.stops.first.masteryPercent, 100);
      expect(snap.stops[1].subtitleKey, 'quizPending');
      expect(snap.stops[2].kind, LearningStopKind.quiz);
      expect(snap.stops[2].subtitleKey, 'reward');
      expect(snap.stops[2].rewardMinutes, 15);

      // The second child has no path of their own — nothing is borrowed.
      final other = await DriftLearningPathRepository(
        db,
        familyId: 'fam_1',
        childId: 'kid_2',
        clock: () => now,
      ).load();
      expect(other.stops, isEmpty);
      expect(other.progressPercent, 0);
    });

    test('results follow-up reads mastery, gap and earned minutes', () async {
      await child('kid_1');
      await result(
        id: 'res_1',
        childId: 'kid_1',
        skillRef: 'math',
        correct: 8,
        total: 10,
        masteryPercent: 80,
        createdAt: now,
      );
      await result(
        id: 'res_0',
        childId: 'kid_1',
        skillRef: 'math',
        correct: 5,
        total: 10,
        masteryPercent: 50,
        createdAt: now.subtract(const Duration(days: 3)),
      );
      await gap(
        id: 'gap_1',
        childId: 'kid_1',
        skillRef: 'fractionDivision',
        missed: 3,
        total: 8,
        masteryPercent: 62,
      );
      await session(
        id: 'session_1',
        childId: 'kid_1',
        kind: Stage1RowVocabulary.learnKindHomework,
        contentRef: 'schoolFractions',
        startedAt: now.subtract(const Duration(hours: 2)),
      );
      await session(
        id: 'session_2',
        childId: 'kid_1',
        kind: Stage1RowVocabulary.learnKindChallenge,
        contentRef: 'dailyChallenge',
        startedAt: now.subtract(const Duration(hours: 1)),
      );
      await ledger(
        id: 'entry_1',
        childId: 'kid_1',
        deltaMinutes: 25,
        sourceRef: 'schoolFractions',
      );

      final snap = await DriftResultsFollowupRepository(
        db,
        familyId: 'fam_1',
        childId: 'kid_1',
        clock: () => now,
      ).load();

      expect(snap.child!.nameKey, 'one');
      expect(snap.mastery!.subjectKey, 'math');
      expect(snap.mastery!.percent, 80);
      expect(snap.mastery!.previousPercent, 50);
      expect(snap.skillGap!.titleKey, 'fractionDivision');
      expect(snap.skillGap!.status, ResultsFollowupSkillGapStatus.pending);
      expect(snap.skillGap!.missed, 3);
      expect(snap.skillGap!.total, 8);
      expect(snap.skillGap!.masteryPercent, 62);
      expect(snap.activities.map((a) => a.id).toList(), [
        'session_2',
        'session_1',
      ]);
      final challenge = snap.activities.first;
      expect(challenge.kind, ResultsFollowupActivityKind.familyChallenge);
      expect(challenge.titleKey, 'dailyChallenge');
      expect(challenge.subtitleKey, 'justSubmitted');
      expect(challenge.minutes, isNull);
      final homework = snap.activities.last;
      expect(homework.kind, ResultsFollowupActivityKind.homework);
      expect(homework.subtitleKey, 'earnedMinutes');
      expect(homework.minutes, 25);
      expect(homework.statusKey, 'complete');
    });

    test('quran plan reads the row, the recitation and the streak', () async {
      await child('kid_1');
      await child('kid_2');
      await plan(id: 'plan_1', childId: 'kid_1');
      await recitation(
        id: 'rec_1',
        planId: 'plan_1',
        childId: 'kid_1',
        completedAyahs: 12,
      );
      await streak(id: 'streak_1', childId: 'kid_1', currentDays: 5);

      final repo = DriftQuranProgressRepository(
        db,
        familyId: 'fam_1',
        childId: 'kid_1',
        clock: () => now,
      );
      final snap = await repo.load();

      expect(snap.childNameKey, 'childOne');
      expect(snap.surahKey, 'mulk');
      expect(snap.fromAyah, 1);
      expect(snap.toAyah, 30);
      expect(snap.completedAyahs, 12);
      expect(snap.reciterKey, 'defaultReciter');
      expect(snap.streakDays, 5);
      expect(snap.rewardMinutes, 25);
      expect(snap.offlineReady, isTrue);
      // No column keeps a byte size — the line stays empty.
      expect(snap.audioSizeKey, isNull);
      expect(snap.recitationStatus, QuranRecitationStatus.recorded);

      final playing = await repo.togglePlay();
      expect(playing.playingAudio, isTrue);

      // The second child has no ward plan of their own.
      final other = await DriftQuranProgressRepository(
        db,
        familyId: 'fam_1',
        childId: 'kid_2',
        clock: () => now,
      ).load();
      expect(other.surahKey, isNull);
      expect(other.rewardMinutes, 0);
      expect(other.offlineReady, isFalse);
      expect(other.recitationStatus, QuranRecitationStatus.none);
    });

    test('approving a recitation moves the row and earns through the '
        'ledger', () async {
      await child('kid_1');
      await child('kid_2');
      await plan(id: 'plan_1', childId: 'kid_1', rewardMinutes: 25);
      await recitation(
        id: 'rec_1',
        planId: 'plan_1',
        childId: 'kid_1',
        completedAyahs: 12,
      );
      await plan(
        id: 'plan_2',
        childId: 'kid_2',
        surahRef: 'naba',
        rewardMinutes: 0,
      );
      await recitation(
        id: 'rec_2',
        planId: 'plan_2',
        childId: 'kid_2',
        completedAyahs: 4,
      );

      final repo = DriftQuranProgressRepository(
        db,
        familyId: 'fam_1',
        childId: 'kid_1',
        clock: () => now,
      );
      final snap = await repo.approveRecitation();

      expect(snap.recitationStatus, QuranRecitationStatus.approved);
      final rows = await db.select(db.quranRecitations).get();
      final first = rows.firstWhere((r) => r.id == 'rec_1');
      expect(first.status, Stage1RowVocabulary.recitationApproved);
      expect(first.completedAyahs, 12);

      var entries = await db.select(db.walletLedgerEntries).get();
      expect(entries.length, 1);
      expect(entries.single.childId, 'kid_1');
      expect(entries.single.deltaMinutes, 25);
      expect(entries.single.reason, Stage1RowVocabulary.walletEarned);
      expect(entries.single.sourceRef, 'plan_1');

      // A second tap has nothing left to confirm — it never pays twice.
      await repo.approveRecitation();
      entries = await db.select(db.walletLedgerEntries).get();
      expect(entries.length, 1);

      // A plan that rewards nothing approves the row and earns nothing.
      final rewardless = DriftQuranProgressRepository(
        db,
        familyId: 'fam_1',
        childId: 'kid_2',
        clock: () => now,
      );
      final second = await rewardless.approveRecitation();
      expect(second.recitationStatus, QuranRecitationStatus.approved);
      entries = await db.select(db.walletLedgerEntries).get();
      expect(entries.length, 1);
    });

    test('cycling the plan moves the active flag between stored plans', () async {
      await child('kid_1');
      await plan(
        id: 'plan_naba',
        childId: 'kid_1',
        surahRef: 'naba',
        toAyah: 40,
        rewardMinutes: 30,
        createdAt: now.subtract(const Duration(days: 2)),
      );
      await plan(
        id: 'plan_mulk',
        childId: 'kid_1',
        surahRef: 'mulk',
        toAyah: 30,
        rewardMinutes: 20,
        active: false,
        createdAt: now.subtract(const Duration(days: 1)),
      );

      final repo = DriftQuranProgressRepository(
        db,
        familyId: 'fam_1',
        childId: 'kid_1',
        clock: () => now,
      );
      final before = await repo.load();
      expect(before.surahKey, 'naba');

      final after = await repo.cyclePlanSurah();
      expect(after.surahKey, 'mulk');
      expect(after.toAyah, 30);
      expect(after.rewardMinutes, 20);

      final rows = await db.select(db.quranPlans).get();
      final active = rows.where((r) => r.active).toList();
      expect(active.length, 1);
      expect(active.single.id, 'plan_mulk');
    });

    test('the rows survive closing and reopening the database', () async {
      await child('kid_1');
      await plan(id: 'plan_1', childId: 'kid_1', rewardMinutes: 25);
      await communityRow(
        id: 'pack_1',
        kind: 'english',
        titleRef: 'englishCards',
        authorRef: 'fatherDammam',
        rating: 4.5,
      );

      await db.close();
      dbClosed = true;
      db = FamilyDatabase(NativeDatabase(file));

      final quran = await DriftQuranProgressRepository(
        db,
        familyId: 'fam_1',
        childId: 'kid_1',
        clock: () => now,
      ).load();
      expect(quran.surahKey, 'mulk');
      expect(quran.rewardMinutes, 25);
      expect(quran.offlineReady, isTrue);

      final community = await DriftCommunityLibraryRepository(
        db,
        familyId: 'fam_1',
        clock: () => now,
      ).load();
      expect(community.packages.single.titleKey, 'englishCards');
      expect(community.packages.single.kind, CommunityPackageKind.english);
      expect(
        community.packages.single.authorKey,
        CommunityAuthorKey.fatherDammam,
      );
    });
  });
}
