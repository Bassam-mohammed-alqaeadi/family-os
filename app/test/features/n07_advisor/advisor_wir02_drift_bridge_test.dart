import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/data/family_database.dart';
import 'package:family_os/core/data/stage1_row_vocabulary.dart';
import 'package:family_os/features/n07_advisor/advisor_followup_bridge.dart';
import 'package:family_os/features/n07_advisor/agent_action_log_models.dart';
import 'package:family_os/features/n07_advisor/family_patterns_models.dart';
import 'package:family_os/features/n07_advisor/individual_timeline_models.dart';
import 'package:family_os/features/n07_advisor/knowledge_maps_models.dart';

/// WIR-02 — the advisor domain's remaining six surfaces on the ADR-054 v6 rows:
/// SCR-FAT-052 (الخطّ الزمني) · SCR-FAT-053 (أنماط العائلة) ·
/// SCR-FAT-054 (خرائط المعرفة) · SCR-FAT-055 (مقارنة الأقران) ·
/// SCR-FAT-056 (سجلّ أفعال المستشار) · SCR-FAT-057 (لحظات العائلة).
void main() {
  group('advisor surfaces B over real rows', () {
    late Directory dir;
    late File file;
    late FamilyDatabase db;
    late DateTime now;
    var dbClosed = false;

    setUp(() async {
      dbClosed = false;
      now = DateTime(2026, 9, 25, 12);
      dir = await Directory.systemTemp.createTemp('wir02_');
      file = File('${dir.path}/wir02.sqlite');
      db = FamilyDatabase(NativeDatabase(file));
    });

    tearDown(() async {
      if (!dbClosed) await db.close();
      await dir.delete(recursive: true);
    });

    Future<void> family({String id = 'fam_1'}) => db
        .into(db.families)
        .insert(
          FamiliesCompanion.insert(
            id: id,
            name: 'Family $id',
            ownerAccountId: 'acc_1',
            createdAt: Value(now),
          ),
        );

    Future<void> child(
      String id, {
      String familyId = 'fam_1',
      String? alias,
      int? birthYear,
      DateTime? createdAt,
    }) => db
        .into(db.children)
        .insert(
          ChildrenCompanion.insert(
            id: id,
            familyId: familyId,
            displayName: 'Child $id',
            alias: alias ?? '${id}_alias',
            birthYear: Value(birthYear),
            createdAt: Value(createdAt ?? now.subtract(const Duration(days: 90))),
          ),
        );

    Future<void> session({
      required String id,
      required String childId,
      String kind = 'FOCUS',
      String? contentRef,
      required DateTime startedAt,
      int minutes = 45,
    }) => db
        .into(db.learnSessions)
        .insert(
          LearnSessionsCompanion.insert(
            id: id,
            familyId: 'fam_1',
            childId: childId,
            kind: kind,
            contentRef: Value(contentRef),
            startedAt: Value(startedAt),
            minutes: Value(minutes),
            status: Stage1RowVocabulary.learnDone,
            requestId: 'req_$id',
          ),
        );

    Future<void> fence(String id, {String name = 'schoolGate'}) => db
        .into(db.geofences)
        .insert(
          GeofencesCompanion.insert(
            id: id,
            familyId: 'fam_1',
            name: name,
            shape: GeofenceShape.circle,
            lat: 24.7,
            lon: 46.7,
            createdBy: 'acc_1',
          ),
        );

    Future<void> enter({
      required String geofenceId,
      required String childId,
      required DateTime at,
    }) => db
        .into(db.geofenceEvents)
        .insert(
          GeofenceEventsCompanion.insert(
            geofenceId: geofenceId,
            childId: childId,
            kind: GeofenceEventKind.enter,
            occurredAt: at,
          ),
        );

    Future<void> suggestion({
      required String id,
      String familyId = 'fam_1',
      required String headline,
      String actionKind = 'focus',
      String? childAlias,
      DateTime? createdAt,
      DateTime? appliedAt,
      DateTime? dismissedAt,
      DateTime? undoneAt,
    }) => db
        .into(db.aiSuggestions)
        .insert(
          AiSuggestionsCompanion.insert(
            id: id,
            familyId: familyId,
            childAlias: Value(childAlias),
            headline: headline,
            actionLabel: 'act',
            actionKind: actionKind,
            confidence: AiConfidence.analysis,
            createdAt: Value(createdAt ?? now.subtract(const Duration(hours: 1))),
            appliedAt: Value(appliedAt),
            undoneAt: Value(undoneAt),
            dismissedAt: Value(dismissedAt),
          ),
        );

    Future<void> gap({
      required String id,
      required String childId,
      required String skillRef,
      int missed = 2,
      int total = 10,
      String status = 'OPEN',
      DateTime? updatedAt,
    }) => db
        .into(db.learnSkillGaps)
        .insert(
          LearnSkillGapsCompanion.insert(
            id: id,
            childId: childId,
            skillRef: skillRef,
            missed: Value(missed),
            total: Value(total),
            status: status,
            updatedAt: Value(updatedAt ?? now),
          ),
        );

    Future<void> learningPath({
      required String id,
      required String childId,
      String subjectRef = 'math',
      int progressPercent = 48,
      DateTime? updatedAt,
    }) => db
        .into(db.learningPaths)
        .insert(
          LearningPathsCompanion.insert(
            id: id,
            familyId: 'fam_1',
            childId: childId,
            subjectRef: subjectRef,
            progressPercent: Value(progressPercent),
            updatedAt: Value(updatedAt ?? now),
          ),
        );

    Future<void> plan({
      required String id,
      required String childId,
      String surahRef = 'AlBaqarah',
      int fromAyah = 1,
      int toAyah = 5,
      bool active = true,
      DateTime? updatedAt,
    }) => db
        .into(db.quranPlans)
        .insert(
          QuranPlansCompanion.insert(
            id: id,
            familyId: 'fam_1',
            childId: childId,
            surahRef: surahRef,
            fromAyah: fromAyah,
            toAyah: toAyah,
            reciterRef: 'rec_1',
            active: Value(active),
            updatedAt: Value(updatedAt ?? now),
          ),
        );

    Future<void> memorization({
      required String id,
      required String childId,
      String surahRef = 'AlBaqarah',
      int progress = 62,
    }) => db
        .into(db.quranMemorizations)
        .insert(
          QuranMemorizationsCompanion.insert(
            id: id,
            childId: childId,
            surahRef: surahRef,
            progress: Value(progress),
            updatedAt: Value(now),
          ),
        );

    Future<void> recitation({
      required String id,
      required String childId,
      required String planId,
      int completedAyahs = 12,
      DateTime? createdAt,
    }) => db
        .into(db.quranRecitations)
        .insert(
          QuranRecitationsCompanion.insert(
            id: id,
            planId: planId,
            childId: childId,
            day: '2026-09-25',
            kind: 'MEMORIZE',
            status: 'DONE',
            completedAyahs: Value(completedAyahs),
            createdAt: Value(createdAt ?? now),
          ),
        );

    Future<void> submission({
      required String id,
      required String childId,
      String taskId = 'task_1',
      DateTime? submittedAt,
      DateTime? reviewedAt,
      bool reviewed = true,
    }) => db
        .into(db.taskSubmissions)
        .insert(
          TaskSubmissionsCompanion.insert(
            id: id,
            taskId: taskId,
            childId: childId,
            mediaRef: 'media_$id',
            submittedAt: Value(submittedAt ?? now),
            status: 'REVIEWED',
            reviewedAt: Value(reviewed ? (reviewedAt ?? now) : null),
          ),
        );

    Future<void> alert({
      required String id,
      required String childId,
      required DateTime at,
    }) => db
        .into(db.sosAlerts)
        .insert(
          SosAlertsCompanion.insert(
            id: id,
            familyId: 'fam_1',
            childId: childId,
            triggeredAt: at,
            status: SosStatus.active,
            requestId: 'req_$id',
          ),
        );

    test('timeline: today stops come from sittings + fence entries, newest is now', () async {
      await family();
      await child('kid_1');
      await child(
        'kid_2',
        createdAt: now.subtract(const Duration(days: 80)),
      );
      // A sitting this morning and one yesterday (yesterday is out of scope).
      await session(
        id: 'sess_today',
        childId: 'kid_1',
        kind: 'FOCUS',
        contentRef: 'mathHour',
        startedAt: DateTime(2026, 9, 25, 9),
      );
      await session(
        id: 'sess_yesterday',
        childId: 'kid_1',
        contentRef: 'lateStudy',
        startedAt: DateTime(2026, 9, 24, 20),
      );
      await fence('gf_1', name: 'schoolGate');
      await enter(
        geofenceId: 'gf_1',
        childId: 'kid_1',
        at: DateTime(2026, 9, 25, 7, 30),
      );
      await suggestion(
        id: 'sug_1',
        headline: 'shortNightSleep',
        actionKind: 'sleep',
        appliedAt: now.subtract(const Duration(hours: 2)),
      );

      final snap = await DriftIndividualTimelineRepository(
        db,
        familyId: 'fam_1',
        childId: 'kid_1',
        clock: () => now,
      ).load();
      expect(snap.nameKey, 'childOne');
      expect(snap.todayStops, hasLength(2));
      // Chronological: the fence entrance, then the sitting.
      expect(snap.todayStops.first.kind, IndividualTimelineStopKind.schoolMode);
      expect(snap.todayStops.first.titleKey, 'schoolGate');
      expect(snap.todayStops.first.isNow, isFalse);
      expect(snap.todayStops.last.titleKey, 'mathHour');
      expect(snap.todayStops.last.isNow, isTrue);
      for (final stop in snap.todayStops) {
        expect(stop.timeKey.trim(), isNotEmpty);
      }
      // The insight is the newest applied suggestion's own content.
      expect(snap.insight, isNotNull);
      expect(snap.insight!.suggestionKey, 'shortNightSleep');
      expect(snap.insight!.badgeKey, 'sleep');

      // The acting child's own ordinal labels the thread (Rule 23).
      final second = DriftIndividualTimelineRepository(
        db,
        familyId: 'fam_1',
        childId: 'kid_2',
        clock: () => now,
      );
      final empty = await second.load();
      expect(empty.nameKey, 'childTwo');
      expect(empty.todayStops, isEmpty);
      expect(empty.isEmpty, isTrue);

      final stranger = await DriftIndividualTimelineRepository(
        db,
        familyId: 'fam_none',
        clock: () => now,
      ).load();
      expect(stranger.isEmpty, isTrue);
      expect(stranger.nameKey, isNull);
    });

    test('patterns: open gaps are the rows and confidence is their own arithmetic', () async {
      await family();
      await child('kid_1');
      await child(
        'kid_2',
        createdAt: now.subtract(const Duration(days: 80)),
      );
      await gap(id: 'g_1', childId: 'kid_1', skillRef: 'mathFractions', missed: 2, total: 10);
      await gap(id: 'g_2', childId: 'kid_1', skillRef: 'readingFluency', missed: 1, total: 5);
      // A closed gap is not an open pattern.
      await gap(
        id: 'g_done',
        childId: 'kid_1',
        skillRef: 'spelling',
        status: 'DONE',
      );
      await learningPath(id: 'lp_1', childId: 'kid_1', progressPercent: 70);
      await learningPath(
        id: 'lp_2',
        childId: 'kid_2',
        progressPercent: 40,
        updatedAt: now.subtract(const Duration(days: 1)),
      );

      final snap = await DriftFamilyPatternsRepository(
        db,
        familyId: 'fam_1',
        clock: () => now,
      ).load();
      expect(snap.children, hasLength(2));
      final first = snap.children.first;
      expect(first.nameKey, 'childOne');
      // Only this child's own open gaps hang on this card.
      expect(first.patterns.map((p) => p.titleKey).toSet(), {
        'mathFractions',
        'readingFluency',
      });
      expect(first.patterns.first.tag, FamilyPatternTag.watch);
      expect(first.patterns.first.domain, FamilyPatternDomain.education);
      expect(first.confidencePercent, 70);
      expect(snap.children.last.patterns, isEmpty);

      // (total - missed) / total over the family's open gaps = 12/15.
      expect(snap.advisorConfidencePercent, 80);

      final stranger = await DriftFamilyPatternsRepository(
        db,
        familyId: 'fam_none',
        clock: () => now,
      ).load();
      expect(stranger.isEmpty, isTrue);
    });

    test('knowledge maps: the child\'s quran pair and newest path carry the cards', () async {
      await family();
      await child('kid_1');
      await plan(id: 'p_1', childId: 'kid_1', fromAyah: 1, toAyah: 5);
      await memorization(id: 'm_1', childId: 'kid_1', progress: 62);
      await learningPath(
        id: 'lp_1',
        childId: 'kid_1',
        subjectRef: 'math',
        progressPercent: 48,
      );

      final repo = DriftKnowledgeMapsRepository(
        db,
        familyId: 'fam_1',
        childId: 'kid_1',
        clock: () => now,
      );
      final snap = await repo.load();
      expect(snap.isEmpty, isFalse);
      expect(snap.childNameKey, 'childOne');
      // The tag is the acting child's own newest measured path.
      expect(snap.masteryPercent, 48);
      expect(snap.learningPaths, hasLength(2));
      final quran = snap.learningPaths.first;
      expect(quran.kind, KnowledgeMapPathKind.quran);
      expect(quran.titleKey, 'AlBaqarah');
      expect(quran.subtitleKey, '1-5');
      expect(quran.progressPercent, 62);
      expect(quran.ctaScreenId, 'SCR-CHD-025');
      final math = snap.learningPaths.last;
      expect(math.kind, KnowledgeMapPathKind.math);
      expect(math.titleKey, 'math');
      expect(math.progressPercent, 48);
      expect(math.ctaScreenId, 'SCR-CHD-013');

      // Declared gaps: no share table and no dinner-question table in v6.
      expect(snap.socialShares, isEmpty);
      expect(snap.dinnerQuestionKeys, isEmpty);
      expect(snap.currentDinnerQuestionKey, isNull);

      // Asking for the next question writes nothing and returns the same rows.
      final asked = await repo.nextDinnerQuestion();
      expect(asked.learningPaths, hasLength(2));
      expect(await db.select(db.aiEvents).get(), isEmpty);
      expect(await db.select(db.aiSuggestions).get(), isEmpty);

      final stranger = await DriftKnowledgeMapsRepository(
        db,
        familyId: 'fam_none',
        clock: () => now,
      ).load();
      expect(stranger.isEmpty, isTrue);
    });

    test('peer compare: the child\'s own age is computed, peers stay declared empty', () async {
      final off = await DriftPeerCompareRepository(
        db,
        familyId: 'fam_1',
        clock: () => now,
      ).load();
      expect(off.hasFamily, isFalse);
      expect(off.isEmpty, isTrue);

      await family();
      await child('kid_1', birthYear: 2015);

      final snap = await DriftPeerCompareRepository(
        db,
        familyId: 'fam_1',
        childId: 'kid_1',
        clock: () => now,
      ).load();
      expect(snap.hasFamily, isTrue);
      expect(snap.childLabelKey, 'childOne');
      expect(snap.ageYears, 11);
      // No peer-aggregate table exists in v6 — declared empty, never faked.
      expect(snap.metrics, isEmpty);

      // A child with no birth year reads 0 = unknown, never a planted age.
      await child('kid_2', createdAt: now.subtract(const Duration(days: 80)));
      final unknown = await DriftPeerCompareRepository(
        db,
        familyId: 'fam_1',
        childId: 'kid_2',
        clock: () => now,
      ).load();
      expect(unknown.ageYears, 0);
    });

    test('agent log: bless and gentle undo are real stamps that survive a reopen', () async {
      await family();
      await child('kid_1');
      // Outside the week window and never the live row.
      await suggestion(
        id: 'sug_old',
        headline: 'olderInsight',
        createdAt: now.subtract(const Duration(days: 10)),
      );
      await suggestion(
        id: 'sug_new',
        headline: 'autoRewardWeek',
        actionKind: 'reward',
        createdAt: now.subtract(const Duration(hours: 1)),
      );

      final repo = DriftAgentActionLogRepository(
        db,
        familyId: 'fam_1',
        clock: () => now,
      );
      final before = await repo.load();
      expect(before.hasFamily, isTrue);
      expect(before.hasLiveAction, isTrue);
      // The live row's own action kind is the rule it belongs to.
      expect(before.ruleKey, 'reward');
      // No alias on the row — the acting child's alias keys the action.
      expect(before.childLabelKey, 'kid_1_alias');
      expect(before.state, AgentActionState.pending);
      // No minutes / app / seconds columns on a suggestion — declared zeros.
      expect(before.minutesGranted, 0);
      expect(before.taskKeys, isEmpty);
      expect(before.appTargetKey, '');
      expect(before.secondsLeft, 0);
      expect(before.weekly, hasLength(1));
      expect(before.weekly.single.titleKey, 'autoRewardWeek');
      expect(before.weekly.single.ruleKey, 'reward');
      expect(before.weekly.single.metaKey.trim(), isNotEmpty);

      final blessed = await repo.bless();
      expect(blessed.state, AgentActionState.blessed);
      var row = await (db.select(db.aiSuggestions)
            ..where((t) => t.id.equals('sug_new')))
          .getSingle();
      expect(row.appliedAt, now);

      // ADR-042 — the blessing outlives the process.
      await db.close();
      dbClosed = true;
      db = FamilyDatabase(NativeDatabase(file));
      final reopened = await DriftAgentActionLogRepository(
        db,
        familyId: 'fam_1',
        clock: () => now,
      ).load();
      expect(reopened.state, AgentActionState.blessed);

      final undone = await DriftAgentActionLogRepository(
        db,
        familyId: 'fam_1',
        clock: () => now,
      ).gentleUndo();
      expect(undone.state, AgentActionState.undone);
      row = await (db.select(db.aiSuggestions)
            ..where((t) => t.id.equals('sug_new')))
          .getSingle();
      expect(row.undoneAt, now);

      // A scope that owns no family reads nothing and stamps nothing.
      final stranger = DriftAgentActionLogRepository(
        db,
        familyId: 'fam_none',
        clock: () => now,
      );
      expect((await stranger.load()).isEmpty, isTrue);
      expect((await stranger.bless()).isEmpty, isTrue);
      expect((await stranger.gentleUndo()).isEmpty, isTrue);
      row = await (db.select(db.aiSuggestions)
            ..where((t) => t.id.equals('sug_new')))
          .getSingle();
      expect(row.appliedAt, now);
      expect(row.undoneAt, now);
    });

    test('family moments: the week\'s numbers are the rows, the album stays empty', () async {
      await family();
      await child('kid_1', alias: 'kid_1_alias');
      await child(
        'kid_2',
        createdAt: now.subtract(const Duration(days: 80)),
      );
      // This week's sitting counts; last week's does not.
      await session(
        id: 'sess_in',
        childId: 'kid_1',
        startedAt: now.subtract(const Duration(hours: 3)),
        minutes: 90,
      );
      await session(
        id: 'sess_out',
        childId: 'kid_1',
        startedAt: now.subtract(const Duration(days: 8)),
        minutes: 120,
      );
      await plan(id: 'p_1', childId: 'kid_1');
      await recitation(
        id: 'rec_in',
        childId: 'kid_1',
        planId: 'p_1',
        completedAyahs: 12,
        createdAt: now.subtract(const Duration(days: 1)),
      );
      await recitation(
        id: 'rec_out',
        childId: 'kid_1',
        planId: 'p_1',
        completedAyahs: 30,
        createdAt: now.subtract(const Duration(days: 9)),
      );
      // A reviewed submission counts; an unreviewed one does not.
      await submission(id: 'sub_in', childId: 'kid_1');
      await submission(id: 'sub_pending', childId: 'kid_1', reviewed: false);
      await alert(
        id: 'sos_in',
        childId: 'kid_1',
        at: now.subtract(const Duration(days: 1)),
      );
      await alert(
        id: 'sos_out',
        childId: 'kid_1',
        at: now.subtract(const Duration(days: 9)),
      );
      await db
          .into(db.walletLedgerEntries)
          .insert(
            WalletLedgerEntriesCompanion.insert(
              id: 'w_1',
              familyId: 'fam_1',
              childId: 'kid_1',
              deltaMinutes: 15,
              reason: 'challenge',
              createdAt: Value(now.subtract(const Duration(hours: 2))),
            ),
          );

      final repo = DriftFamilyMomentsRepository(
        db,
        familyId: 'fam_1',
        clock: () => now,
      );
      final snap = await repo.load();
      expect(snap.hasFamily, isTrue);
      expect(snap.learnHours, 1);
      expect(snap.versesMemorized, 12);
      expect(snap.tasksDone, 1);
      expect(snap.worryAlerts, 1);
      expect(snap.stars, hasLength(2));
      expect(snap.stars.first.childLabelKey, 'childOne');
      expect(snap.stars.first.titleKey, 'Child kid_1');
      // The star's own earned minutes, never a planted number.
      expect(snap.stars.first.subKey, '15');
      expect(snap.stars.first.emoji.trim(), isNotEmpty);
      expect(snap.stars.last.subKey, '0');

      // No album table and no row that records a share or a reminder.
      expect(snap.album, isEmpty);
      expect(snap.prideShared, isFalse);
      expect(snap.touchReminded, isFalse);
      expect((await repo.sharePrideCard()).prideShared, isFalse);
      expect((await repo.remindTouch()).touchReminded, isFalse);
      expect((await repo.addMoment()).album, isEmpty);
      expect(await db.select(db.aiEvents).get(), isEmpty);

      final stranger = await DriftFamilyMomentsRepository(
        db,
        familyId: 'fam_none',
        clock: () => now,
      ).load();
      expect(stranger.isEmpty, isTrue);
      expect(stranger.stars, isEmpty);
      expect(stranger.learnHours, 0);
    });

    // --- tests below (added in the following edits) ---
  });
}
