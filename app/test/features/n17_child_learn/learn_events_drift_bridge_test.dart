import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/data/family_database.dart';
import 'package:family_os/core/data/stage1_row_vocabulary.dart';
import 'package:family_os/features/n17_child_learn/child_tutor_models.dart';
import 'package:family_os/features/n17_child_learn/learn_followup_bridge.dart';

/// DEV-6d (دفعة ٢) — the child's remaining learning surfaces on the ADR-054 v6
/// rows: `learn_progress` + `learn_session` (الأذكار) · `tutor_thread` /
/// `tutor_turn` (المعلّم) · `family_challenge` / `family_challenge_day`
/// (التحديات) · `focus_schedule` / `focus_advisor_note` + `learn_session`
/// (التركيز) · `content_pack` / `content_item` + `learn_session` (القصص) ·
/// `wallet_ledger` (الهدايا).
void main() {
  group('learn events over real rows', () {
    late Directory dir;
    late File file;
    late FamilyDatabase db;
    late DateTime now;
    var dbClosed = false;

    setUp(() async {
      dbClosed = false;
      now = DateTime(2026, 9, 25, 12);
      dir = await Directory.systemTemp.createTemp('dev6d_events_');
      file = File('${dir.path}/dev6d_events.sqlite');
      db = FamilyDatabase(NativeDatabase(file));
    });

    tearDown(() async {
      if (!dbClosed) await db.close();
      await dir.delete(recursive: true);
    });

    Future<void> child(
      String id, {
      String familyId = 'fam_1',
      int daysOld = 90,
    }) => db
        .into(db.children)
        .insert(
          ChildrenCompanion.insert(
            id: id,
            familyId: familyId,
            displayName: 'Child $id',
            alias: '${id}_alias',
            createdAt: Value(now.subtract(Duration(days: daysOld))),
          ),
        );

    Future<void> progress({
      required String id,
      String childId = 'kid_1',
      required String contentRef,
      int completedUnits = 0,
      int totalUnits = 0,
    }) => db
        .into(db.learnProgress)
        .insert(
          LearnProgressCompanion.insert(
            id: id,
            childId: childId,
            contentRef: contentRef,
            completedUnits: Value(completedUnits),
            totalUnits: Value(totalUnits),
            updatedAt: Value(now),
          ),
        );

    Future<void> thread({
      String id = 'thread_1',
      String childId = 'kid_1',
      String topicRef = 'fractionsHelp',
      String status = 'OPEN',
    }) => db
        .into(db.tutorThreads)
        .insert(
          TutorThreadsCompanion.insert(
            id: id,
            childId: childId,
            topicRef: topicRef,
            status: status,
            startedAt: Value(now),
          ),
        );

    Future<void> turn({
      required String id,
      String threadId = 'thread_1',
      required String role,
      required String contentRef,
      int minutesAgo = 0,
    }) => db
        .into(db.tutorTurns)
        .insert(
          TutorTurnsCompanion.insert(
            id: id,
            threadId: threadId,
            role: role,
            contentRef: contentRef,
            createdAt: Value(now.subtract(Duration(minutes: minutesAgo))),
          ),
        );

    Future<void> challenge({
      required String id,
      String familyId = 'fam_1',
      required String titleRef,
      String startsDay = '2026-09-21',
      String endsDay = '2026-09-27',
      bool active = true,
    }) => db
        .into(db.familyChallenges)
        .insert(
          FamilyChallengesCompanion.insert(
            id: id,
            familyId: familyId,
            titleRef: titleRef,
            kind: 'STEPS',
            startsDay: startsDay,
            endsDay: endsDay,
            active: Value(active),
            createdByAccount: 'acc_1',
            createdAt: Value(now),
          ),
        );

    Future<void> challengeDay({
      required String challengeId,
      String childId = 'kid_1',
      required int dayIndex,
      bool done = false,
    }) => db
        .into(db.familyChallengeDays)
        .insert(
          FamilyChallengeDaysCompanion.insert(
            id: '${challengeId}_${childId}_$dayIndex',
            challengeId: challengeId,
            childId: childId,
            dayIndex: dayIndex,
            day: '2026-09-${21 + dayIndex}',
            done: Value(done),
            createdAt: Value(now),
          ),
        );

    Future<void> schedule({
      String id = 'schedule_1',
      String childId = 'kid_1',
      int startMinute = 8 * 60,
      int endMinute = 8 * 60 + 45,
      bool enabled = true,
    }) => db
        .into(db.focusSchedules)
        .insert(
          FocusSchedulesCompanion.insert(
            id: id,
            familyId: 'fam_1',
            nameRef: 'schoolWindow',
            childId: childId,
            startMinute: startMinute,
            endMinute: endMinute,
            enabled: Value(enabled),
          ),
        );

    Future<void> advisorNote({
      String id = 'note_1',
      String childId = 'kid_1',
      String titleRef = 'focusPraise1',
      DateTime? praiseSentAt,
    }) => db
        .into(db.focusAdvisorNotes)
        .insert(
          FocusAdvisorNotesCompanion.insert(
            id: id,
            familyId: 'fam_1',
            childId: childId,
            weekStart: '2026-09-21',
            titleRef: titleRef,
            bodyRef: '${titleRef}Body',
            praiseSentAt: Value(praiseSentAt),
            rewardSentAt: const Value(null),
          ),
        );

    Future<void> pack({
      String id = 'pack_1',
      String kind = Stage1RowVocabulary.packKindStory,
      String sourceRef = 'desertAdventure',
      String status = Stage1RowVocabulary.packStatusApproved,
    }) => db
        .into(db.contentPacks)
        .insert(
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
      String packId = 'pack_1',
      String kind = Stage1RowVocabulary.itemKindStory,
      required String titleRef,
      String? bodyRef,
      int sortOrder = 0,
    }) => db
        .into(db.contentItems)
        .insert(
          ContentItemsCompanion.insert(
            id: id,
            packId: packId,
            kind: kind,
            titleRef: titleRef,
            bodyRef: Value(bodyRef),
            sortOrder: Value(sortOrder),
          ),
        );

    Future<void> ledger({
      required String id,
      String childId = 'kid_1',
      required int deltaMinutes,
      required String sourceRef,
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

    test('athkar read both tracks and a thikr moves only the day own row', () async {
      await child('kid_1');
      await progress(
        id: 't_ev',
        contentRef: Stage1RowVocabulary.athkarRefEvening,
        completedUnits: 3,
        totalUnits: 7,
      );
      await progress(
        id: 't_mo',
        contentRef: Stage1RowVocabulary.athkarRefMorning,
        completedUnits: 1,
        totalUnits: 5,
      );

      final repo = DriftChildAthkarRepository(
        db,
        familyId: 'fam_1',
        childId: 'kid_1',
        clock: () => now,
      );
      final before = await repo.load();

      expect(before.hasSession, isTrue);
      expect(before.sessionKey, 'evening');
      expect(before.done, 3);
      expect(before.total, 7);
      expect(before.morningDone, 1);
      expect(before.morningTotal, 5);

      final after = await repo.markSaid();

      expect(after.done, 4);
      // The morning track is its own row — saying an evening thikr leaves it.
      expect(after.morningDone, 1);
      final evening = await (db.select(db.learnProgress)
            ..where((t) => t.id.equals('t_ev')))
          .getSingle();
      expect(evening.completedUnits, 4);
      expect(evening.lastSeenAt, now);
      final sittings = await (db.select(db.learnSessions)
            ..where(
              (t) =>
                  t.kind.equals(Stage1RowVocabulary.learnKindAthkar) &
                  t.childId.equals('kid_1'),
            ))
          .get();
      expect(sittings, hasLength(1));
      expect(sittings.single.status, Stage1RowVocabulary.learnDone);
      expect(sittings.single.contentRef, Stage1RowVocabulary.athkarRefEvening);
    });

    test('athkar never pass the track own total and survive a reopen', () async {
      await child('kid_1');
      await progress(
        id: 't_ev',
        contentRef: Stage1RowVocabulary.athkarRefEvening,
        completedUnits: 6,
        totalUnits: 7,
      );

      final repo = DriftChildAthkarRepository(
        db,
        familyId: 'fam_1',
        childId: 'kid_1',
        clock: () => now,
      );
      for (var i = 0; i < 4; i++) {
        await repo.markSaid();
      }

      var snap = await repo.load();
      expect(snap.done, 7);
      expect(snap.total, 7);

      // ADR-042 — the count is a row, so it outlives the process.
      await db.close();
      dbClosed = true;
      db = FamilyDatabase(NativeDatabase(file));
      snap = await DriftChildAthkarRepository(
        db,
        familyId: 'fam_1',
        childId: 'kid_1',
        clock: () => now,
      ).load();
      expect(snap.done, 7);
      expect(snap.sessionKey, 'evening');
    });

    test('the tutor bubbles are the thread own turns, oldest first', () async {
      await child('kid_1');
      await thread();
      await turn(
        id: 'turn_1',
        role: 'tutor',
        contentRef: 'askFirst',
        minutesAgo: 10,
      );
      await turn(
        id: 'turn_2',
        role: 'child',
        contentRef: 'myAnswer',
        minutesAgo: 5,
      );
      await turn(id: 'turn_3', role: 'TUTOR', contentRef: 'wellDone');

      final snap = await DriftChildTutorRepository(
        db,
        familyId: 'fam_1',
        childId: 'kid_1',
        clock: () => now,
      ).load();

      expect(snap.hasThread, isTrue);
      expect(snap.bubbles.map((b) => b.textKey).toList(), [
        'askFirst',
        'myAnswer',
        'wellDone',
      ]);
      expect(snap.bubbles.map((b) => b.kind).toList(), [
        ChildTutorBubbleKind.tutor,
        ChildTutorBubbleKind.child,
        ChildTutorBubbleKind.tutor,
      ]);
      // The suggested questions are copy with no column — declared empty.
      expect(snap.choices, isEmpty);
    });

    test('the challenge is the family own race, per child and day', () async {
      await child('kid_1', daysOld: 90);
      await child('kid_2', daysOld: 60);
      await challenge(id: 'ch_old', titleRef: 'oldRace', active: false);
      await challenge(
        id: 'ch_1',
        titleRef: 'stepsTogether',
        startsDay: '2026-09-21',
        endsDay: '2026-09-25',
      );
      await challengeDay(challengeId: 'ch_1', dayIndex: 0, done: true);
      await challengeDay(challengeId: 'ch_1', dayIndex: 2, done: true);
      await challengeDay(
        challengeId: 'ch_1',
        childId: 'kid_2',
        dayIndex: 1,
        done: true,
      );

      final snap = await DriftChildFamilyChallengesRepository(
        db,
        familyId: 'fam_1',
        childId: 'kid_1',
        clock: () => now,
      ).load();

      expect(snap.hasChallenges, isTrue);
      expect(snap.activeTitleKey, 'stepsTogether');
      // The range is the row's own two day keys.
      expect(snap.activeSubKey, '2026-09-21..2026-09-25');
      // Rule 23 — a peer is labelled by their order in the family.
      expect(snap.peers.map((p) => p.labelKey).toList(), [
        Stage1RowVocabulary.childKeyFor(0),
        Stage1RowVocabulary.childKeyFor(1),
      ]);
      expect(snap.peers.first.days, hasLength(5));
      expect(snap.peers.first.days.map((d) => d.done).toList(), [
        true,
        false,
        true,
        false,
        false,
      ]);
      // A tick belongs to the child whose row it is.
      expect(snap.peers.last.days.map((d) => d.done).toList(), [
        false,
        true,
        false,
        false,
        false,
      ]);
      expect(snap.done, hasLength(1));
      expect(snap.done.single.titleKey, 'oldRace');
    });

    test('focus reads the window and the sent praise, and opens one sitting', () async {
      await child('kid_1');
      await schedule(startMinute: 8 * 60, endMinute: 8 * 60 + 45);
      await advisorNote(id: 'note_draft');
      await advisorNote(id: 'note_1', praiseSentAt: now);

      final repo = DriftChildFocusRepository(
        db,
        familyId: 'fam_1',
        childId: 'kid_1',
        clock: () => now,
      );
      final before = await repo.load();

      expect(before.sessionMinutes, 45);
      // Only praise the father actually sent is spoken.
      expect(before.praiseMessageKey, 'focusPraise1');
      expect(before.sessionActive, isFalse);

      final started = await repo.startSession();

      expect(started.sessionActive, isTrue);
      final sittings = await (db.select(db.learnSessions)
            ..where((t) => t.kind.equals(Stage1RowVocabulary.learnKindFocus)))
          .get();
      expect(sittings, hasLength(1));
      expect(sittings.single.status, Stage1RowVocabulary.learnOpen);
      expect(sittings.single.childId, 'kid_1');

      // A second start is the same sitting, never a duplicate row.
      await repo.startSession();
      expect(
        await (db.select(db.learnSessions)
              ..where(
                (t) => t.kind.equals(Stage1RowVocabulary.learnKindFocus),
              ))
            .get(),
        hasLength(1),
      );

      // ADR-042 — the sitting outlives the process.
      await db.close();
      dbClosed = true;
      db = FamilyDatabase(NativeDatabase(file));
      final reopened = await DriftChildFocusRepository(
        db,
        familyId: 'fam_1',
        childId: 'kid_1',
        clock: () => now,
      ).load();
      expect(reopened.sessionActive, isTrue);
    });

    test('the story is the pack own chapter and its choices', () async {
      await child('kid_1');
      await pack();
      await item(
        id: 'chapter_1',
        titleRef: 'desert3',
        bodyRef: 'desert3Body',
        sortOrder: 0,
      );
      await item(
        id: 'choice_1',
        titleRef: 'goLeft',
        bodyRef: 'leftToast',
        sortOrder: 1,
      );
      await item(
        id: 'choice_2',
        titleRef: 'goRight',
        bodyRef: 'rightToast',
        sortOrder: 2,
      );
      // A non-story item in the same pack is not a page of the story.
      await item(
        id: 'card_1',
        kind: Stage1RowVocabulary.itemKindFlashcards,
        titleRef: 'oneThird',
        sortOrder: 3,
      );

      final repo = DriftChildInteractiveStoriesRepository(
        db,
        familyId: 'fam_1',
        childId: 'kid_1',
        clock: () => now,
      );
      final before = await repo.load();

      expect(before.hasStory, isTrue);
      expect(before.chapterKey, 'desert3');
      expect(before.bodyKey, 'desert3Body');
      expect(before.choices.map((c) => c.id).toList(), [
        'choice_1',
        'choice_2',
      ]);
      expect(before.choices.first.toastKey, 'leftToast');
      expect(before.lastChoiceId, isNull);

      final chosen = await repo.choose('choice_2');

      expect(chosen.lastChoiceId, 'choice_2');
      final sittings = await (db.select(db.learnSessions)
            ..where(
              (t) =>
                  t.kind.equals(Stage1RowVocabulary.learnKindStory) &
                  t.childId.equals('kid_1'),
            ))
          .get();
      expect(sittings, hasLength(1));
      expect(sittings.single.contentRef, 'choice_2');
      // The sitting names the pack it came from.
      expect(sittings.single.requestId, 'desertAdventure');

      // ADR-042 — the last choice is a row, not screen state.
      await db.close();
      dbClosed = true;
      db = FamilyDatabase(NativeDatabase(file));
      final reopened = await DriftChildInteractiveStoriesRepository(
        db,
        familyId: 'fam_1',
        childId: 'kid_1',
        clock: () => now,
      ).load();
      expect(reopened.lastChoiceId, 'choice_2');
    });

    test('the coming gifts are the positive ledger entries only', () async {
      await child('kid_1');
      await child('kid_2', daysOld: 60);
      await ledger(id: 'gift_1', deltaMinutes: 10, sourceRef: 'giftChore');
      await ledger(id: 'gift_2', deltaMinutes: 15, sourceRef: 'giftReading');
      await ledger(id: 'spend_1', deltaMinutes: -5, sourceRef: 'spendGame');
      await ledger(
        id: 'gift_other',
        childId: 'kid_2',
        deltaMinutes: 20,
        sourceRef: 'giftOther',
      );

      final snap = await DriftChildComingGiftsRepository(
        db,
        familyId: 'fam_1',
        childId: 'kid_1',
        clock: () => now,
      ).load();

      expect(snap.ready, isTrue);
      expect(snap.links.map((l) => l.id).toList(), ['gift_1', 'gift_2']);
      expect(snap.links.first.titleKey, 'giftChore');
      // A gift is minutes in the wallet — that is where it opens.
      expect(snap.links.first.navigateTo, 'SCR-CHD-019');
      expect(snap.links.first.subKey, '');
    });

    test('an empty scope reads nothing on every event screen', () async {
      final athkar = await DriftChildAthkarRepository(
        db,
        familyId: 'fam_1',
        childId: 'kid_1',
        clock: () => now,
      ).load();
      final tutor = await DriftChildTutorRepository(
        db,
        familyId: 'fam_1',
        childId: 'kid_1',
        clock: () => now,
      ).load();
      final challenges = await DriftChildFamilyChallengesRepository(
        db,
        familyId: 'fam_1',
        childId: 'kid_1',
        clock: () => now,
      ).load();
      final focus = await DriftChildFocusRepository(
        db,
        familyId: 'fam_1',
        childId: 'kid_1',
        clock: () => now,
      ).load();
      final stories = await DriftChildInteractiveStoriesRepository(
        db,
        familyId: 'fam_1',
        childId: 'kid_1',
        clock: () => now,
      ).load();
      final gifts = await DriftChildComingGiftsRepository(
        db,
        familyId: 'fam_1',
        childId: 'kid_1',
        clock: () => now,
      ).load();

      expect(athkar.hasSession, isFalse);
      // No rows means no counts — never the screen's own fixture numbers.
      expect(athkar.total, 0);
      expect(athkar.morningTotal, 0);
      expect(tutor.hasThread, isFalse);
      expect(tutor.bubbles, isEmpty);
      expect(challenges.hasChallenges, isFalse);
      expect(challenges.activeTitleKey, '');
      expect(challenges.peers, isEmpty);
      // No window on record means no minutes to claim.
      expect(focus.sessionMinutes, 0);
      expect(focus.sessionActive, isFalse);
      expect(focus.praiseMessageKey, isNull);
      expect(stories.hasStory, isFalse);
      expect(stories.chapterKey, '');
      expect(stories.choices, isEmpty);
      expect(gifts.ready, isFalse);
      expect(gifts.links, isEmpty);
    });
  });
}
