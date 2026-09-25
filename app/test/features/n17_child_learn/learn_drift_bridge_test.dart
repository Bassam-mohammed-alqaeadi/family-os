import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/data/family_database.dart';
import 'package:family_os/core/data/stage1_row_vocabulary.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/minutes.dart';
import 'package:family_os/features/education/learning_assignment_models.dart';
import 'package:family_os/features/education/learning_result_models.dart';
import 'package:family_os/features/n17_child_learn/learn_ux_bridge.dart';

/// DEV-5a — the learning domain (SCR-CHD-012 · CHD-016 · CHD-019 · CHD-029) and
/// the father→child seams over the ADR-054 v6 rows.
void main() {
  group('learning over real rows', () {
    late Directory dir;
    late File file;
    late FamilyDatabase db;
    late DateTime now;
    var dbClosed = false;

    setUp(() async {
      dbClosed = false;
      now = DateTime(2026, 9, 24, 12);
      dir = await Directory.systemTemp.createTemp('dev5a_');
      file = File('${dir.path}/dev5a.sqlite');
      db = FamilyDatabase(NativeDatabase(file));
    });

    tearDown(() async {
      if (!dbClosed) await db.close();
      await dir.delete(recursive: true);
    });

    Future<void> child({
      required String id,
      String familyId = 'fam_1',
      required DateTime createdAt,
    }) => db.into(db.children).insert(
      ChildrenCompanion.insert(
        id: id,
        familyId: familyId,
        displayName: 'child_$id',
        alias: 'child_$id',
        createdAt: Value(createdAt),
      ),
    );

    Future<void> assignment({
      required String id,
      String familyId = 'fam_1',
      String childId = 'chi_1',
      String kind = 'MATH',
      String contentRef = 'math.lesson.3',
      int rewardMinutes = 20,
      String status = Stage1RowVocabulary.learnAssigned,
      String source = 'homework',
      required DateTime createdAt,
    }) => db.into(db.learnAssignments).insert(
      LearnAssignmentsCompanion.insert(
        id: id,
        familyId: familyId,
        childId: childId,
        kind: kind,
        contentRef: contentRef,
        rewardMinutes: Value(rewardMinutes),
        status: status,
        assignedByAccount: 'acc_father',
        requestId: Stage1RowVocabulary.learnRequestIdFor(source, createdAt),
        createdAt: Value(createdAt),
        updatedAt: Value(createdAt),
      ),
    );

    Future<void> progress({
      required String id,
      String childId = 'chi_1',
      required String contentRef,
      int percent = 0,
    }) => db.into(db.learnProgress).insert(
      LearnProgressCompanion.insert(
        id: id,
        childId: childId,
        contentRef: contentRef,
        progressPercent: Value(percent),
      ),
    );

    Future<void> streak({
      required String id,
      String childId = 'chi_1',
      int current = 0,
      int record = 0,
    }) => db.into(db.learnStreaks).insert(
      LearnStreaksCompanion.insert(
        id: id,
        childId: childId,
        kind: Stage1RowVocabulary.learnStreakAll,
        currentDays: Value(current),
        recordDays: Value(record),
      ),
    );

    Future<void> achievement({
      required String id,
      String familyId = 'fam_1',
      String childId = 'chi_1',
      required String badgeRef,
      required DateTime earnedAt,
    }) => db.into(db.learnAchievements).insert(
      LearnAchievementsCompanion.insert(
        id: id,
        familyId: familyId,
        childId: childId,
        badgeRef: badgeRef,
        kind: Stage1RowVocabulary.achievementBadge,
        earnedAt: Value(earnedAt),
      ),
    );

    Future<void> ledger({
      required String id,
      String familyId = 'fam_1',
      String childId = 'chi_1',
      required int delta,
      String? sourceRef,
      required DateTime createdAt,
    }) => db.into(db.walletLedgerEntries).insert(
      WalletLedgerEntriesCompanion.insert(
        id: id,
        familyId: familyId,
        childId: childId,
        deltaMinutes: delta,
        reason: Stage1RowVocabulary.walletEarned,
        sourceRef: Value(sourceRef),
        createdAt: Value(createdAt),
      ),
    );

    Future<void> gap({
      required String id,
      String childId = 'chi_1',
      required String skillRef,
      String status = Stage1RowVocabulary.learnOpen,
    }) => db.into(db.learnSkillGaps).insert(
      LearnSkillGapsCompanion.insert(
        id: id,
        childId: childId,
        skillRef: skillRef,
        missed: const Value(2),
        total: const Value(5),
        status: status,
        updatedAt: Value(now),
      ),
    );

    DriftChildLearnHomeRepository home() =>
        DriftChildLearnHomeRepository(db, familyId: 'fam_1', childId: 'chi_1', clock: () => now);
    DriftChildWalletRepository wallet() =>
        DriftChildWalletRepository(db, familyId: 'fam_1', childId: 'chi_1', clock: () => now);
    DriftChildDailyReviewRepository review() =>
        DriftChildDailyReviewRepository(db, familyId: 'fam_1', childId: 'chi_1', clock: () => now);
    DriftChildResultRepository result() =>
        DriftChildResultRepository(db, familyId: 'fam_1', childId: 'chi_1', clock: () => now);
    DriftLearningAssignmentRepository assignments() =>
        DriftLearningAssignmentRepository(
          db,
          familyId: 'fam_1',
          childId: 'chi_1',
          createdByAccount: 'acc_father',
          clock: () => now,
        );
    DriftLearningResultRepository results() => DriftLearningResultRepository(
      db,
      familyId: 'fam_1',
      childId: 'chi_1',
      clock: () => now,
    );

    Future<void> seedFamilyOne() async {
      await child(id: 'chi_1', createdAt: DateTime.utc(2026, 1, 1));
      await child(id: 'chi_2', createdAt: DateTime.utc(2026, 1, 2));
    }

    test('SCR-CHD-012 reads the child\'s own rows, never a fixture', () async {
      await seedFamilyOne();
      await assignment(id: 'a1', createdAt: now.subtract(const Duration(hours: 2)));
      await progress(id: 'p1', contentRef: 'math.lesson.3', percent: 40);
      await streak(id: 's1', current: 4, record: 9);
      await achievement(
        id: 'ach1',
        badgeRef: 'firstWird',
        earnedAt: now.subtract(const Duration(days: 3)),
      );
      await achievement(
        id: 'ach2',
        badgeRef: 'adhkarWeek',
        earnedAt: now.subtract(const Duration(days: 1)),
      );
      await ledger(
        id: 'l1',
        delta: 25,
        sourceRef: 'youtube',
        createdAt: now.subtract(const Duration(hours: 1)),
      );

      final snap = await home().load();

      expect(snap.level, 2);
      expect(snap.levelTitleKey, 'explorer');
      expect(snap.minutesEarnedThisMonth, 25);
      expect(snap.streakDays, 4);
      expect(snap.freeTime, isTrue);
      // The host that published the assignment survives through request_id.
      expect(snap.challenge?.titleKey, 'assignedHomework');
      expect(snap.challenge?.rewardMinutes, 20);
      expect(snap.challenge?.ctaScreenId, 'SCR-CHD-013');
      expect(snap.materials, hasLength(1));
      final material = snap.materials.single;
      expect(material.kind.name, 'math');
      expect(material.titleKey, 'math');
      expect(material.subtitleKey, 'math.lesson.3');
      expect(material.tag.name, 'progress');
      expect(material.progressPercent, 40);
      expect(snap.levelProgressPercent, 40);
    });

    test('a child this family does not own sees nothing', () async {
      await seedFamilyOne();
      await child(
        id: 'chi_9',
        familyId: 'fam_2',
        createdAt: DateTime.utc(2026, 1, 3),
      );
      await assignment(
        id: 'a9',
        familyId: 'fam_2',
        childId: 'chi_9',
        createdAt: now,
      );
      await gap(id: 'g9', childId: 'chi_9', skillRef: 'fractions');
      await ledger(id: 'l9', familyId: 'fam_2', childId: 'chi_9', delta: 90, createdAt: now);
      await streak(id: 's9', childId: 'chi_9', current: 30);

      expect((await home().load()).isEmpty, isTrue);
      expect((await wallet().load()).isEmpty, isTrue);
      expect((await review().load()).hasCards, isFalse);
      expect((await result().load()).isEmpty, isTrue);
      expect(await assignments().listForChild(ChildId('chi_9')), isEmpty);
    });

    test('SCR-CHD-019 wallet reads signed ledger balances', () async {
      await seedFamilyOne();
      await ledger(id: 'w1', delta: 40, sourceRef: 'youtube', createdAt: now.subtract(const Duration(days: 2)));
      await ledger(id: 'w2', delta: -10, sourceRef: 'youtube', createdAt: now.subtract(const Duration(days: 1)));
      await ledger(id: 'w3', delta: 30, sourceRef: 'games', createdAt: now.subtract(const Duration(hours: 3)));
      await streak(id: 's1', current: 5, record: 9);
      await achievement(id: 'ach1', badgeRef: 'firstWird', earnedAt: now.subtract(const Duration(days: 4)));
      await achievement(id: 'ach2', badgeRef: 'focusFive', earnedAt: now.subtract(const Duration(days: 2)));

      final snap = await wallet().load();

      expect(snap.totalMinutes, 60);
      expect(snap.streakDays, 5);
      expect(snap.recordStreakDays, 9);
      expect(snap.earnedBadgeCount, 2);
      // Newest badge first, straight from `learn_achievement.earned_at`.
      expect(snap.badges.map((b) => b.labelKey), ['focusFive', 'firstWird']);
      final byApp = {for (final a in snap.apps) a.id: a.walletMinutes};
      expect(byApp['youtube'], 30);
      expect(byApp['games'], 30);
      expect(snap.apps.first.nameKey, 'youtube');
    });

    test('SCR-CHD-029 review leaves a row that survives a reopen', () async {
      await seedFamilyOne();
      await gap(id: 'g1', skillRef: 'fractions');
      await gap(id: 'g2', skillRef: 'unit4', status: Stage1RowVocabulary.learnMastered);
      await gap(id: 'g3', skillRef: 'waterCycle', status: Stage1RowVocabulary.learnClosed);

      final before = await review().load();
      expect(before.cards.map((c) => c.titleKey), ['fractions', 'unit4']);
      expect(before.cards.first.metaKey, Stage1RowVocabulary.learnOpen);
      expect(before.cards.last.strong, isTrue);
      expect(before.sessionDone, isFalse);

      final done = await review().completeSession();
      expect(done.sessionDone, isTrue);

      await db.close();
      dbClosed = true;
      db = FamilyDatabase(NativeDatabase(file));

      final reopened = await review().load();
      expect(reopened.sessionDone, isTrue, reason: 'ADR-042 — the row is the fact');
      expect(reopened.cards, hasLength(2));
    });

    test('SCR-CHD-016 reads what the quiz actually wrote', () async {
      await seedFamilyOne();
      final submission = await results().submit(
        LearningResultSubmitRequest(
          childId: ChildId('chi_1'),
          kind: LearningResultKind.quiz,
          titleKey: 'dividingFractions',
          rewardMinutes: Minutes(20),
          scoreCorrect: 9,
          scoreTotal: 10,
        ),
      );
      expect(submission.rewardMinutes.inMinutes, 20);

      final sessions = await db.select(db.learnSessions).get();
      final findings = await db.select(db.learnResults).get();
      final paid = await db.select(db.walletLedgerEntries).get();
      expect(sessions, hasLength(1));
      expect(sessions.single.kind, Stage1RowVocabulary.learnKindQuiz);
      expect(sessions.single.minutes, 20);
      expect(findings.single.skillRef, 'dividingFractions');
      expect(findings.single.masteryPercent, 90);
      expect(paid.single.deltaMinutes, 20);
      expect(paid.single.reason, Stage1RowVocabulary.walletEarned);

      final snap = await result().load();
      expect(snap.scoreCorrect, 9);
      expect(snap.scoreTotal, 10);
      // Nine of ten is not a full score, so no mastered praise is claimed.
      expect(snap.praiseKey, isNull);
      expect(snap.rewards, hasLength(1));
      expect(snap.rewards.single.titleKey, Stage1RowVocabulary.walletEarned);
      expect(snap.rewards.single.subtitleKey, '20 min');

      final recent = await results().listRecent();
      expect(recent, hasLength(1));
      expect(recent.single.kind, LearningResultKind.quiz);
      expect(recent.single.rewardMinutes.inMinutes, 20);
      expect(recent.single.scoreCorrect, 9);
    });

    test('a foreign child is never written to', () async {
      await seedFamilyOne();
      await child(
        id: 'chi_9',
        familyId: 'fam_2',
        createdAt: DateTime.utc(2026, 1, 3),
      );

      await results().submit(
        LearningResultSubmitRequest(
          childId: ChildId('chi_9'),
          kind: LearningResultKind.familyChallenge,
          titleKey: 'challenge.day3',
          rewardMinutes: Minutes(45),
          scoreCorrect: 1,
          scoreTotal: 1,
        ),
      );
      await assignments().publish(
        LearningAssignmentPublishRequest(
          childId: ChildId('chi_9'),
          titleKey: 'math.lesson.9',
          rewardMinutes: Minutes(30),
          source: LearningAssignmentSource.attribution,
        ),
      );

      expect(await db.select(db.learnSessions).get(), isEmpty);
      expect(await db.select(db.learnResults).get(), isEmpty);
      expect(await db.select(db.walletLedgerEntries).get(), isEmpty);
      expect(await db.select(db.learnAssignments).get(), isEmpty);
    });

    test('the assignment seam round-trips through request_id', () async {
      await seedFamilyOne();
      final seam = assignments();
      final firstEvent = seam.assignments.first;

      final published = await seam.publish(
        LearningAssignmentPublishRequest(
          childId: ChildId('chi_1'),
          titleKey: 'quran.wird.7',
          rewardMinutes: Minutes(30),
          source: LearningAssignmentSource.familyChallenge,
          materialKindKey: 'quran',
        ),
      );
      expect(published.source, LearningAssignmentSource.familyChallenge);
      expect(published.ctaScreenId, 'SCR-CHD-034');
      expect(published.materialKindKey, 'quran');

      final row = (await db.select(db.learnAssignments).get()).single;
      expect(Stage1RowVocabulary.learnSourceOf(row.requestId), 'familyChallenge');

      final listed = await seam.listForChild(ChildId('chi_1'));
      expect(listed, hasLength(1));
      expect(listed.single.source, LearningAssignmentSource.familyChallenge);
      expect((await seam.latestForChild(ChildId('chi_1')))?.id, published.id);
      expect((await firstEvent).id, published.id);
    });
  });
}
