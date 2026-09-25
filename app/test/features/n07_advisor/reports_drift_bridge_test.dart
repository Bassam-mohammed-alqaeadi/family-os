import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/data/ai_repository.dart';
import 'package:family_os/core/data/family_database.dart';
import 'package:family_os/core/data/stage1_row_vocabulary.dart';
import 'package:family_os/features/n07_advisor/reports_ux_bridge.dart';
import 'package:family_os/features/n14_studio/focus_report_models.dart';

/// DEV-8 — the three report surfaces (SCR-FAT-069 · SCR-FAT-073 · SCR-FAT-051)
/// over the ADR-054 v6 rows: `wallet_ledger`, `learn_session`,
/// `focus_schedule` / `focus_schedule_app`, `focus_advisor_note`,
/// `ai_suggestion`.
void main() {
  group('reports over real rows', () {
    late Directory dir;
    late File file;
    late FamilyDatabase db;
    late DateTime now;
    var dbClosed = false;

    setUp(() async {
      dbClosed = false;
      // A Thursday: the reported week runs from the Saturday before it.
      now = DateTime(2026, 9, 24, 12);
      dir = await Directory.systemTemp.createTemp('dev8_');
      file = File('${dir.path}/dev8.sqlite');
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

    Future<void> ledger({
      required String id,
      required int deltaMinutes,
      String childId = 'child_a',
      String? sourceRef,
      String reason = Stage1RowVocabulary.walletEarned,
      DateTime? at,
    }) => db.into(db.walletLedgerEntries).insert(
      WalletLedgerEntriesCompanion.insert(
        id: id,
        familyId: 'fam_1',
        childId: childId,
        deltaMinutes: deltaMinutes,
        reason: reason,
        sourceRef: Value(sourceRef),
        createdAt: Value(at ?? now),
      ),
    );

    Future<void> focusSession({
      required String id,
      required int minutes,
      required DateTime startedAt,
      String kind = Stage1RowVocabulary.learnKindFocus,
      String childId = 'child_a',
    }) => db.into(db.learnSessions).insert(
      LearnSessionsCompanion.insert(
        id: id,
        familyId: 'fam_1',
        childId: childId,
        kind: kind,
        status: Stage1RowVocabulary.statusDone,
        requestId: 'session:$id',
        minutes: Value(minutes),
        startedAt: Value(startedAt),
      ),
    );

    DriftChildUsageReportRepository usage({
      String childId = 'child_a',
      String familyId = 'fam_1',
    }) => DriftChildUsageReportRepository(
      db,
      familyId: familyId,
      childId: childId,
      clock: () => now,
    );

    DriftWeeklyReportRepository weekly({String familyId = 'fam_1'}) =>
        DriftWeeklyReportRepository(
          db,
          familyId: familyId,
          childId: 'child_a',
          clock: () => now,
        );

    DriftFocusReportRepository focus({String childId = 'child_a'}) =>
        DriftFocusReportRepository(
          db,
          familyId: 'fam_1',
          childId: childId,
          clock: () => now,
        );

    test('usage: the week of ledger rows is the report', () async {
      await child('child_a');
      // The reported week is Sat 2026-09-19 → Fri 2026-09-25.
      await ledger(
        id: 'l_sat',
        deltaMinutes: -30,
        sourceRef: 'youtube',
        reason: Stage1RowVocabulary.walletSourceFocus,
        at: DateTime(2026, 9, 19, 18),
      );
      await ledger(
        id: 'l_tue_app',
        deltaMinutes: -60,
        sourceRef: 'youtube',
        at: DateTime(2026, 9, 22, 17),
      );
      await ledger(
        id: 'l_tue_game',
        deltaMinutes: -30,
        sourceRef: 'games',
        at: DateTime(2026, 9, 22, 19),
      );
      await ledger(
        id: 'l_thu',
        deltaMinutes: -50,
        sourceRef: 'youtube',
        at: DateTime(2026, 9, 24, 9),
      );
      // Gifted minutes: the positive side of the same ledger.
      await ledger(
        id: 'l_gift',
        deltaMinutes: 20,
        sourceRef: 'youtube',
        at: DateTime(2026, 9, 23, 10),
      );
      // Outside the week — neither day nor total may take it in.
      await ledger(
        id: 'l_before',
        deltaMinutes: -999,
        sourceRef: 'games',
        at: DateTime(2026, 9, 18, 12),
      );
      await ledger(
        id: 'l_after',
        deltaMinutes: -777,
        sourceRef: 'games',
        at: DateTime(2026, 10, 1, 12),
      );

      final snap = await usage().load();

      expect(snap.childNameKey, 'childOne');
      expect(snap.weekHours, 2);
      expect(snap.weekMinutes, 50);
      expect(snap.retentionDays, 30);

      // Bars are relative to the busiest day: Tuesday (90) is the 100% peak.
      expect(snap.dayHeights, hasLength(7));
      expect(snap.dayHeights[0], 33);
      expect(snap.dayHeights[1], 0);
      expect(snap.dayHeights[3], 100);
      expect(snap.dayHeights[5], 56);

      expect(snap.categories, hasLength(2));
      final top = snap.categories.first;
      expect(top.id, 'youtube');
      expect(top.labelKey, 'youtube');
      expect(top.hours, closeTo(140 / 60, 0.001));
      expect(top.progress, 1);
      expect(top.giftMinutes, isTrue);
      final second = snap.categories[1];
      expect(second.id, 'games');
      expect(second.hours, closeTo(0.5, 0.001));
      expect(second.progress, closeTo(30 / 140, 0.001));
      expect(second.giftMinutes, isFalse);

      // The screens reach the same rows through the composition root.
      Stage1ReportsRuntime.resetForTest();
      expect(
        identical(Stage1ReportsRuntime.ensureOpenSync(override: db), db),
        isTrue,
      );
      expect(identical(Stage1ReportsRuntime.ensureOpenSync(), db), isTrue);
      Stage1ReportsRuntime.resetForTest();
    });

    test('usage: one child is reported, and an empty family reports nothing', () async {
      await child('child_a');
      await child('child_b');
      await ledger(id: 'l_a', deltaMinutes: -60, sourceRef: 'youtube');
      await ledger(
        id: 'l_b',
        deltaMinutes: -90,
        childId: 'child_b',
        sourceRef: 'games',
      );

      final mine = await usage(childId: 'child_b').load();

      expect(mine.childNameKey, 'childTwo');
      expect(mine.weekMinutes, 30);
      expect(mine.weekHours, 1);
      expect(mine.categories.map((c) => c.id), ['games']);

      final other = await usage(childId: 'child_a').load();
      expect(other.weekMinutes, 0);
      expect(other.categories.map((c) => c.id), ['youtube']);

      // A scope that owns no rows never invents a child.
      final empty = await usage(familyId: 'fam_none').load();
      expect(empty.isEmpty, isTrue);
      expect(empty.childNameKey, isNull);
      expect(empty.categories, isEmpty);
    });

    test('weekly: the learning line is earned minutes against the week before', () async {
      await child('child_a');
      // This week: 120 earned. The week before (09-12 → 09-19): 100 earned.
      await ledger(
        id: 'w_now_1',
        deltaMinutes: 70,
        at: DateTime(2026, 9, 22, 15),
      );
      await ledger(
        id: 'w_now_2',
        deltaMinutes: 50,
        at: DateTime(2026, 9, 23, 15),
      );
      await ledger(
        id: 'w_prev',
        deltaMinutes: 100,
        at: DateTime(2026, 9, 16, 15),
      );
      // Older and spent rows change neither side.
      await ledger(
        id: 'w_old',
        deltaMinutes: 500,
        at: DateTime(2026, 9, 2, 15),
      );
      await ledger(
        id: 'w_spent',
        deltaMinutes: -80,
        sourceRef: 'youtube',
        at: DateTime(2026, 9, 24, 8),
      );

      final snap = await weekly().load();

      expect(snap.hasFamily, isTrue);
      expect(snap.isEmpty, isFalse);
      expect(snap.learnDeltaPercent, 20);
      // The contract has no sleep rows — nothing is claimed.
      expect(snap.sleepDeltaMinutes, 0);
      expect(snap.whenKey, 'fridayMorning');
      expect(snap.styleKey, 'detailed');

      // A family that owns no rows reports nothing at all.
      final fresh = await weekly(familyId: 'fam_none').load();
      expect(fresh.isEmpty, isTrue);
    });

    test('weekly: the recommendation is the newest stored suggestion', () async {
      await child('child_a');
      final ai = DriftAiRepository(db);
      await ai.addSuggestion(
        id: 'sug_old',
        familyId: 'fam_1',
        headline: 'olderInsight',
        actionLabel: 'act',
        actionKind: 'focus',
        confidence: AiConfidence.analysis,
        at: DateTime(2026, 9, 20, 9),
      );
      await ai.addSuggestion(
        id: 'sug_new',
        familyId: 'fam_1',
        headline: 'sleepShiftLater',
        actionLabel: 'act',
        actionKind: 'sleep',
        confidence: AiConfidence.confirmed,
        at: DateTime(2026, 9, 23, 9),
      );

      final before = await weekly().load();
      expect(before.recommendationKey, 'sleepShiftLater');
      expect(before.recommendationApplied, isFalse);
      expect(before.recommendationDeferred, isFalse);

      final after = await weekly().applyRecommendation();

      expect(after.recommendationApplied, isTrue);
      final rows = await db.select(db.aiSuggestions).get();
      final newest = rows.firstWhere((r) => r.id == 'sug_new');
      expect(newest.appliedAt, isNotNull);
      final older = rows.firstWhere((r) => r.id == 'sug_old');
      expect(older.appliedAt, isNull, reason: 'لا يُطبَّق إلا الاقتراح المعروض');
    });

    test('weekly: deferring is written down, and the delivery choices hold', () async {
      await child('child_a');
      final ai = DriftAiRepository(db);
      await ai.addSuggestion(
        id: 'sug_1',
        familyId: 'fam_1',
        headline: 'screenCut',
        actionLabel: 'act',
        actionKind: 'screen',
        confidence: AiConfidence.preliminary,
        at: DateTime(2026, 9, 23, 9),
      );

      final repo = weekly();
      final deferred = await repo.deferRecommendation();

      expect(deferred.recommendationDeferred, isTrue);
      expect(deferred.recommendationApplied, isFalse);
      final row = (await db.select(db.aiSuggestions).get()).single;
      expect(row.dismissedAt, isNotNull);

      // The delivery choices flip in place; the contract carries no table for
      // them yet, so they live with this repository (declared gap).
      expect((await repo.toggleWhen()).whenKey, 'saturdayEvening');
      expect((await repo.toggleStyle()).styleKey, 'brief');
      expect((await repo.toggleInclude('quran')).include.quran, isFalse);
      final reloaded = await repo.load();
      expect(reloaded.whenKey, 'saturdayEvening');
      expect(reloaded.styleKey, 'brief');
      expect(reloaded.include.quran, isFalse);
      final untouched = await weekly().load();
      expect(untouched.include.quran, isTrue);
      expect(untouched.whenKey, 'fridayMorning');
    });

    test('focus: the week is the focus sittings, the goal is the plan', () async {
      await child('child_a');
      await db.into(db.focusSchedules).insert(
        FocusSchedulesCompanion.insert(
          id: 'sched_live',
          familyId: 'fam_1',
          nameRef: 'afternoonStudy',
          childId: 'child_a',
          startMinute: 960,
          endMinute: 1020,
          daysMask: const Value(0x03),
        ),
      );
      await db.into(db.focusScheduleApps).insert(
        FocusScheduleAppsCompanion.insert(
          id: 'app_1',
          scheduleId: 'sched_live',
          appRef: 'youtube',
        ),
      );
      await db.into(db.focusScheduleApps).insert(
        FocusScheduleAppsCompanion.insert(
          id: 'app_2',
          scheduleId: 'sched_live',
          appRef: 'games',
        ),
      );
      // A switched-off plan is on the books but sets no goal.
      await db.into(db.focusSchedules).insert(
        FocusSchedulesCompanion.insert(
          id: 'sched_off',
          familyId: 'fam_1',
          nameRef: 'eveningStudy',
          childId: 'child_a',
          startMinute: 1200,
          endMinute: 1320,
          daysMask: const Value(0x7F),
          enabled: const Value(false),
        ),
      );

      await focusSession(
        id: 'f_1',
        minutes: 50,
        startedAt: DateTime(2026, 9, 21, 16),
      );
      await focusSession(
        id: 'f_2',
        minutes: 55,
        startedAt: DateTime(2026, 9, 23, 16),
      );
      // Another week, and another kind of sitting, stay out.
      await focusSession(
        id: 'f_before',
        minutes: 300,
        startedAt: DateTime(2026, 9, 17, 16),
      );
      await focusSession(
        id: 'f_other',
        minutes: 300,
        startedAt: DateTime(2026, 9, 22, 16),
        kind: Stage1RowVocabulary.learnKindLesson,
      );

      final snap = await focus().load();

      expect(snap.child?.id, 'child_a');
      expect(snap.child?.nameKey, 'childOne');
      expect(snap.weeklySummary?.sessionsCount, 2);
      expect(snap.weeklySummary?.totalDurationMinutes, 105);
      expect(snap.weeklySummary?.longestSessionMinutes, 55);
      // The goal is the family's own plan: (1020 − 960) × 2 days = 120 minutes.
      expect(snap.weeklySummary?.goalStatus, FocusReportGoalStatus.inProgress);

      final item = snap.schedules.firstWhere((s) => s.id == 'sched_live');
      expect(item.nameKey, 'afternoonStudy');
      expect(item.childNameKey, 'childOne');
      expect(item.timeKey, '16:00-17:00');
      expect(item.daysKey, '0,1');
      expect(item.blockedAppKeys, ['youtube', 'games']);
      expect(item.enabled, isTrue);
      expect(snap.schedules.map((s) => s.id), contains('sched_off'));

      // Meeting the plan turns the goal tag over.
      await focusSession(
        id: 'f_3',
        minutes: 20,
        startedAt: DateTime(2026, 9, 24, 16),
      );
      final met = await focus().load();
      expect(met.weeklySummary?.totalDurationMinutes, 125);
      expect(met.weeklySummary?.goalStatus, FocusReportGoalStatus.complete);
    });

    test('focus: praise, reward and a toggle are real rows (ADR-042)', () async {
      await child('child_a');
      await db.into(db.focusSchedules).insert(
        FocusSchedulesCompanion.insert(
          id: 'sched_1',
          familyId: 'fam_1',
          nameRef: 'afternoonStudy',
          childId: 'child_a',
          startMinute: 960,
          endMinute: 1020,
          daysMask: const Value(0x03),
        ),
      );
      await db.into(db.focusAdvisorNotes).insert(
        FocusAdvisorNotesCompanion.insert(
          id: 'note_1',
          familyId: 'fam_1',
          childId: 'child_a',
          weekStart: '2026-09-19',
          titleRef: 'selfDiscipline',
          bodyRef: 'scienceResist',
        ),
      );

      final repo = focus();
      final before = await repo.load();
      final fresh = before.advisorNote;
      expect(fresh, isNotNull);
      expect(fresh!.praiseSent, isFalse);
      expect(fresh.praiseQuoteKey, isNull);
      expect(fresh.rewardSent, isFalse);

      final praised = await repo.sendPraise();
      expect(praised.advisorNote?.praiseSent, isTrue);
      expect(praised.advisorNote?.praiseQuoteKey, 'resistDistraction');

      final rewarded = await repo.rewardSelfDiscipline();
      expect(rewarded.advisorNote?.rewardSent, isTrue);
      expect(rewarded.advisorNote?.praiseSent, isTrue);

      // Minutes only (ع-١): the reward is a ledger entry on the focus side.
      final entries = await db.select(db.walletLedgerEntries).get();
      expect(entries, hasLength(1));
      expect(entries.single.deltaMinutes, 15);
      expect(entries.single.reason, Stage1RowVocabulary.walletEarned);
      expect(entries.single.sourceRef, Stage1RowVocabulary.walletSourceFocus);

      final toggled = await repo.toggleSchedule('sched_1', false);
      expect(toggled.schedules.single.enabled, isFalse);

      await db.close();
      dbClosed = true;
      db = FamilyDatabase(NativeDatabase(file));

      final reopened = await focus().load();
      expect(reopened.advisorNote?.praiseSent, isTrue);
      expect(reopened.advisorNote?.rewardSent, isTrue);
      expect(reopened.schedules.single.enabled, isFalse);
      expect(reopened.weeklySummary?.sessionsCount, 0);

      // A reward already sent is not a second one.
      await focus().rewardSelfDiscipline();
      expect(await db.select(db.walletLedgerEntries).get(), hasLength(1));

      // A scope that owns no rows reads nothing and writes nothing.
      final stranger = DriftFocusReportRepository(
        db,
        familyId: 'fam_none',
        childId: 'child_a',
        clock: () => now,
      );
      expect((await stranger.load()).isEmpty, isTrue);
      await stranger.sendPraise();
      await stranger.rewardSelfDiscipline();
      expect(await db.select(db.walletLedgerEntries).get(), hasLength(1));
      final note = (await db.select(db.focusAdvisorNotes).get()).single;
      expect(note.praiseSentAt, isNotNull, reason: 'كوّت الأسرة الأخرى وحدها');
    });
  });
}
