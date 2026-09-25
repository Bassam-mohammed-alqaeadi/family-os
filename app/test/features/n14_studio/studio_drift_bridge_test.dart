import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/data/family_database.dart';
import 'package:family_os/core/data/stage1_row_vocabulary.dart';
import 'package:family_os/features/n14_studio/attribution_reward_models.dart';
import 'package:family_os/features/n14_studio/create_assignment_models.dart';
import 'package:family_os/features/n14_studio/studio_board_models.dart';
import 'package:family_os/features/n14_studio/studio_ux_bridge.dart';

/// DEV-6a — the studio core (SCR-FAT-040 · FAT-045 · FAT-049) over the
/// ADR-054 v6 rows: `content_pack`, `attribution_rule`, `learn_skill_gap`,
/// `child` and the learning seam it publishes into.
void main() {
  group('studio over real rows', () {
    late Directory dir;
    late File file;
    late FamilyDatabase db;
    late DateTime now;
    var dbClosed = false;

    setUp(() async {
      dbClosed = false;
      // Thursday 2026-09-24 — bit 4 of the day mask, weekend bits 5 and 6.
      now = DateTime(2026, 9, 24, 12);
      dir = await Directory.systemTemp.createTemp('dev6a_');
      file = File('${dir.path}/dev6a.sqlite');
      db = FamilyDatabase(NativeDatabase(file));
    });

    tearDown(() async {
      if (!dbClosed) await db.close();
      await dir.delete(recursive: true);
    });

    Future<void> child({
      required String id,
      String familyId = 'fam_1',
      String avatar = 'lion',
      required DateTime createdAt,
    }) => db.into(db.children).insert(
      ChildrenCompanion.insert(
        id: id,
        familyId: familyId,
        displayName: 'child_$id',
        alias: 'child_$id',
        avatar: Value(avatar),
        createdAt: Value(createdAt),
      ),
    );

    Future<void> pack({
      required String id,
      String familyId = 'fam_1',
      String kind = Stage1RowVocabulary.packKindQuiz,
      String status = Stage1RowVocabulary.packStatusDraft,
      String sourceRef = 'math.fractions',
      required DateTime createdAt,
    }) => db.into(db.contentPacks).insert(
      ContentPacksCompanion.insert(
        id: id,
        familyId: familyId,
        kind: kind,
        sourceRef: sourceRef,
        status: status,
        createdByAccount: 'acc_father',
        createdAt: Value(createdAt),
        updatedAt: Value(createdAt),
      ),
    );

    Future<void> gap({
      required String id,
      String childId = 'chi_1',
      required String skillRef,
      int missed = 2,
      int total = 5,
      int? masteryPercent = 60,
      String status = Stage1RowVocabulary.learnOpen,
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

    Future<void> rule({
      required String id,
      String familyId = 'fam_1',
      String contentRef = 'math.fractions',
      String? childId,
      String kind = Stage1RowVocabulary.ruleKindWallet,
      int minutes = 20,
      bool enabled = true,
      bool autoAdded = false,
      bool assigned = false,
    }) => db.into(db.attributionRules).insert(
      AttributionRulesCompanion.insert(
        id: id,
        familyId: familyId,
        contentRef: contentRef,
        childId: Value(childId),
        kind: kind,
        minutes: Value(minutes),
        enabled: Value(enabled),
        autoAdded: Value(autoAdded),
        assigned: Value(assigned),
      ),
    );

    DriftStudioBoardRepository board() =>
        DriftStudioBoardRepository(db, familyId: 'fam_1', childId: '', clock: () => now);
    DriftCreateAssignmentRepository createAssignment({String childId = ''}) =>
        DriftCreateAssignmentRepository(
          db,
          familyId: 'fam_1',
          childId: childId,
          createdByAccount: 'acc_father',
          clock: () => now,
        );
    DriftAttributionRewardRepository attribution({String childId = ''}) =>
        DriftAttributionRewardRepository(
          db,
          familyId: 'fam_1',
          childId: childId,
          createdByAccount: 'acc_father',
          clock: () => now,
        );

    Future<void> seedTwoChildren() async {
      await child(id: 'chi_1', avatar: 'panda', createdAt: DateTime.utc(2026, 1, 1));
      await child(id: 'chi_2', avatar: 'lion', createdAt: DateTime.utc(2026, 1, 2));
    }

    test('SCR-FAT-040 reads the pack ladder and the real gaps', () async {
      await seedTwoChildren();
      await pack(
        id: 'pk_quiz',
        kind: Stage1RowVocabulary.packKindQuiz,
        status: Stage1RowVocabulary.packStatusApproved,
        createdAt: now.subtract(const Duration(hours: 3)),
      );
      await pack(
        id: 'pk_cards',
        kind: Stage1RowVocabulary.packKindFlashcards,
        status: Stage1RowVocabulary.packStatusDraft,
        createdAt: now.subtract(const Duration(hours: 1)),
      );
      await gap(id: 'g_open', skillRef: 'fractions', updatedAt: now);
      await gap(
        id: 'g_closed',
        skillRef: 'waterCycle',
        status: Stage1RowVocabulary.learnClosed,
        updatedAt: now,
      );

      final snap = await board().load();

      expect(snap.suggestions.map((s) => s.id), ['g_open']);
      expect(snap.suggestions.single.kind, StudioSuggestionKind.fractions);
      expect(snap.recent.map((r) => r.id), ['pk_cards', 'pk_quiz']);
      expect(snap.recent.first.kind, StudioContentKind.flashcards);
      expect(snap.recent.first.status, StudioContentStatus.active);
      expect(snap.recent.last.kind, StudioContentKind.quiz);
      expect(snap.recent.last.status, StudioContentStatus.excellent);
    });

    test('the board is scoped to its own family', () async {
      await seedTwoChildren();
      await child(id: 'chi_9', familyId: 'fam_2', createdAt: DateTime.utc(2026, 1, 3));
      await pack(id: 'pk_2', familyId: 'fam_2', createdAt: now);
      await gap(id: 'g_2', childId: 'chi_9', skillRef: 'quran.wird');

      expect((await board().load()).isEmpty, isTrue);
    });

    test('SCR-FAT-049 labels the child by order and reads the newest gap', () async {
      await seedTwoChildren();
      await gap(id: 'g_old', skillRef: 'fractions', updatedAt: now.subtract(const Duration(days: 2)));
      await gap(
        id: 'g_new',
        skillRef: 'dividingFractions',
        missed: 3,
        total: 8,
        updatedAt: now,
      );
      await rule(id: 'ru_gap', contentRef: 'dividingFractions', minutes: 45);

      final snap = await createAssignment().load();

      expect(snap.child?.id, 'chi_1');
      expect(snap.child?.nameKey, 'childOne');
      expect(snap.skillGap?.id, 'g_new');
      expect(snap.skillGap?.titleKey, 'dividingFractions');
      expect(snap.skillGap?.quizQuestions, 8);
      // The rule the family wrote decides the reward.
      expect(snap.skillGap?.rewardMinutes, 45);
      expect(snap.lastAssignedPath, isNull);
    });

    test('assignHomework publishes the father\'s own words', () async {
      await seedTwoChildren();

      final snap = await createAssignment().assignHomework('  رياضيات صفحة ١٢  ');

      expect(snap.lastAssignedPath, CreateAssignmentPath.homework);
      expect(snap.homeworkTitle, 'رياضيات صفحة ١٢');

      final row = (await db.select(db.learnAssignments).get()).single;
      expect(row.familyId, 'fam_1');
      expect(row.childId, 'chi_1');
      expect(row.contentRef, 'رياضيات صفحة ١٢');
      expect(row.kind, 'MATH');
      expect(row.status, Stage1RowVocabulary.learnAssigned);
      expect(row.assignedByAccount, 'acc_father');
      expect(row.rewardMinutes, 30);
      // The host rides inside request_id, so the child's screen reads it back.
      expect(Stage1RowVocabulary.learnSourceOf(row.requestId), 'homework');
    });

    test('the other two paths keep their own source', () async {
      await seedTwoChildren();
      await gap(id: 'g_new', skillRef: 'dividingFractions', updatedAt: now);

      await createAssignment().assignSkillGap();
      await createAssignment().assignFamilyChallenge('سؤال العائلة');

      final rows = await db.select(db.learnAssignments).get();
      expect(rows, hasLength(2));
      final bySource = {
        for (final r in rows)
          Stage1RowVocabulary.learnSourceOf(r.requestId): r.contentRef,
      };
      expect(bySource['skillGap'], 'dividingFractions');
      expect(bySource['familyChallenge'], 'سؤال العائلة');
    });

    test('SCR-FAT-045 writes the rule, the ledger and the assignment', () async {
      await seedTwoChildren();
      await gap(id: 'g_new', skillRef: 'fractions', masteryPercent: 60);
      await rule(id: 'ru_wallet', minutes: 20);
      await rule(
        id: 'ru_play',
        kind: Stage1RowVocabulary.ruleKindPlay,
        contentRef: 'play',
        minutes: 15,
        autoAdded: true,
      );

      final before = await attribution().load();
      expect(before.children.map((c) => c.nameKey), ['childOne', 'childTwo']);
      expect(before.children.first.emoji, 'panda');
      expect(before.selectedChildId, 'chi_1');
      expect(before.rewards.map((r) => r.kind), [
        AttributionRewardKind.wallet,
        AttributionRewardKind.play,
      ]);
      expect(before.masteryPercent, 60);
      expect(before.assigned, isFalse);
      expect(before.canAssign, isTrue);

      final assigned = await attribution().assign();
      expect(assigned.assigned, isTrue);

      final rules = await db.select(db.attributionRules).get();
      expect(rules.every((r) => r.assigned), isTrue);
      // The chosen schedule becomes the days it means: tomorrow is bit 5.
      expect(rules.first.scheduleDayMask, 1 << 5);

      final ledger = await db.select(db.walletLedgerEntries).get();
      expect(ledger, hasLength(2));
      final byApp = {for (final r in ledger) r.sourceRef: r.deltaMinutes};
      expect(byApp['education'], 20);
      expect(byApp['play'], 15);
      expect(ledger.every((r) => r.reason == Stage1RowVocabulary.walletEarned), isTrue);

      final assignment = (await db.select(db.learnAssignments).get()).single;
      expect(assignment.contentRef, 'attribution');
      expect(assignment.rewardMinutes, 35);
      expect(Stage1RowVocabulary.learnSourceOf(assignment.requestId), 'attribution');

      await db.close();
      dbClosed = true;
      db = FamilyDatabase(NativeDatabase(file));

      final reopened = await attribution().load();
      expect(reopened.assigned, isTrue, reason: 'ADR-042 — the row is the fact');
      expect(reopened.schedule, AttributionSchedule.tomorrowAfterSchool);
    });

    test('nothing is assigned or attributed while the choices are off', () async {
      await seedTwoChildren();
      await rule(id: 'ru_off', minutes: 20, enabled: false);

      final seeded = await attribution().load();
      expect(seeded.totalEnabledMinutes, 0);
      expect(seeded.canAssign, isFalse);
      expect((await attribution().assign()).assigned, isFalse);

      // And with no children at all the seams stay closed.
      await db.delete(db.children).go();
      final empty = createAssignment();
      expect((await empty.load()).isEmpty, isTrue);
      expect((await empty.assignHomework('x')).isEmpty, isTrue);
      expect((await attribution().load()).isEmpty, isTrue);

      expect(await db.select(db.walletLedgerEntries).get(), isEmpty);
      expect(await db.select(db.learnAssignments).get(), isEmpty);
      expect(
        (await db.select(db.attributionRules).get()).every((r) => !r.assigned),
        isTrue,
      );
    });
  });
}
