import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/data/ai_repository.dart';
import 'package:family_os/core/data/family_database.dart';
import 'package:family_os/core/data/stage1_row_vocabulary.dart';
import 'package:family_os/core/policy/ai_stage_id.dart';
import 'package:family_os/core/policy/rules_engine_rule_repository.dart';
import 'package:family_os/features/n07_advisor/advisor_followup_bridge.dart';

/// WIR-01 — the advisor domain's six surfaces on the ADR-054 v6 rows:
/// `ai_suggestion` (مساعدي · الاقتراحات · لوحة العقل) · `family` (صوت المستشار ·
/// عقل عائلتي) · `ai_event` (إخطارات الذكاء للأم).
void main() {
  group('advisor surfaces over real rows', () {
    late Directory dir;
    late File file;
    late FamilyDatabase db;
    late DateTime now;
    var dbClosed = false;

    setUp(() async {
      dbClosed = false;
      now = DateTime(2026, 9, 25, 12);
      dir = await Directory.systemTemp.createTemp('wir01_');
      file = File('${dir.path}/wir01.sqlite');
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

    Future<void> child(String id, {String familyId = 'fam_1'}) => db
        .into(db.children)
        .insert(
          ChildrenCompanion.insert(
            id: id,
            familyId: familyId,
            displayName: 'Child $id',
            alias: '${id}_alias',
            createdAt: Value(now.subtract(const Duration(days: 90))),
          ),
        );

    Future<void> suggestion({
      required String id,
      String familyId = 'fam_1',
      required String headline,
      String actionLabel = 'act',
      String actionKind = 'focus',
      AiConfidence confidence = AiConfidence.analysis,
      DateTime? appliedAt,
      DateTime? dismissedAt,
    }) => db
        .into(db.aiSuggestions)
        .insert(
          AiSuggestionsCompanion.insert(
            id: id,
            familyId: familyId,
            headline: headline,
            actionLabel: actionLabel,
            actionKind: actionKind,
            confidence: confidence,
            createdAt: Value(now.subtract(const Duration(hours: 1))),
            appliedAt: Value(appliedAt),
            dismissedAt: Value(dismissedAt),
          ),
        );

    Future<List<AiEvent>> whisperRows() => (db.select(db.aiEvents)..where(
          (t) => t.kind.equals(Stage1RowVocabulary.aiKindMothersWhisper),
        ))
        .get();

    test('inbox: pending rows, and approve / reject are real stamps (ADR-042)', () async {
      await family();
      await suggestion(id: 'sug_a', headline: 'sleepShiftLater');
      await suggestion(id: 'sug_b', headline: 'screenCut');
      await suggestion(
        id: 'sug_done',
        headline: 'oldInsight',
        appliedAt: now.subtract(const Duration(days: 1)),
      );
      await suggestion(
        id: 'sug_gone',
        headline: 'dismissedInsight',
        dismissedAt: now.subtract(const Duration(days: 1)),
      );

      final rules = InMemoryRulesEngineRuleRepository();
      final repo = DriftAiSuggestionRepository(
        db,
        rules: rules,
        familyId: 'fam_1',
        clock: () => now,
      );

      final before = await repo.listPending();
      expect(before.map((i) => i.id).toSet(), {'sug_a', 'sug_b'});
      final first = before.firstWhere((i) => i.id == 'sug_a');
      // The row's own headline is the title; the body has no column.
      expect(first.suggestion.title, 'sleepShiftLater');
      expect(first.suggestion.body, '');

      await repo.approve('sug_a');
      expect((await repo.listPending()).map((i) => i.id).toSet(), {'sug_b'});
      // Approving is a real rule in the screen's own store.
      expect(
        (await rules.listEnabled()).map((r) => r.sourceSuggestionId),
        contains('sug_a'),
      );

      await repo.reject('sug_b');
      expect(await repo.listPending(), isEmpty);

      // ADR-042 — the decision outlives the process.
      await db.close();
      dbClosed = true;
      db = FamilyDatabase(NativeDatabase(file));
      final reopened = DriftAiSuggestionRepository(
        db,
        familyId: 'fam_1',
        clock: () => now,
      );
      expect(await reopened.listPending(), isEmpty);
      final rows = await db.select(db.aiSuggestions).get();
      expect(rows.firstWhere((r) => r.id == 'sug_a').appliedAt, now);
      expect(rows.firstWhere((r) => r.id == 'sug_b').dismissedAt, now);
    });

    test('inbox: an empty scope reads nothing and an unknown id refuses', () async {
      final stranger = DriftAiSuggestionRepository(
        db,
        familyId: 'fam_none',
        clock: () => now,
      );
      expect(await stranger.listInbox(), isEmpty);
      expect(await stranger.listPending(), isEmpty);

      final blank = DriftAiSuggestionRepository(
        db,
        familyId: '',
        clock: () => now,
      );
      expect(await blank.listPending(), isEmpty);

      await expectLater(
        stranger.approve('missing'),
        throwsA(isA<StateError>()),
      );
      await expectLater(
        stranger.reject('missing'),
        throwsA(isA<StateError>()),
      );
    });

    test('voice: the family row is the whole truth and talking writes nothing', () async {
      final off = await DriftAdvisorVoiceRepository(
        db,
        familyId: 'fam_1',
        clock: () => now,
      ).load();
      expect(off.hasFamily, isFalse);
      expect(off.isEmpty, isTrue);
      expect(off.lastTurns, isEmpty);

      await family();
      final repo = DriftAdvisorVoiceRepository(
        db,
        familyId: 'fam_1',
        clock: () => now,
      );
      final snap = await repo.load();
      expect(snap.hasFamily, isTrue);
      expect(snap.isEmpty, isFalse);
      // No transcript table — the last turns are a declared gap.
      expect(snap.lastTurns, isEmpty);

      final talked = await repo.pressTalk();
      expect(talked.listening, isTrue);
      expect(await db.select(db.aiEvents).get(), isEmpty);
    });

    test('hub: the family row turns the hub on, the catalog is screen structure', () async {
      final off = await DriftFamilyAdvisorHubRepository(
        db,
        familyId: 'fam_1',
        clock: () => now,
      ).load();
      expect(off.isEmpty, isTrue);

      await family();
      final repo = DriftFamilyAdvisorHubRepository(
        db,
        familyId: 'fam_1',
        clock: () => now,
      );
      final snap = await repo.load();
      expect(snap.hasFamily, isTrue);
      expect(snap.isEmpty, isFalse);
      expect(snap.capabilities.map((c) => c.id), contains('voice'));
      expect(
        snap.sovereigntyRows.map((c) => c.id),
        containsAll(['limits', 'agentLog']),
      );
      expect(snap.suggestions.map((c) => c.id), contains('weekly'));

      // The free-text ask has no local row in stage 1 — it writes nothing.
      await repo.askFreeText('How is sleep?');
      expect(await db.select(db.aiEvents).get(), isEmpty);
    });

    test('feed: summaries are stored events and the whisper is a real one (ADR-042)', () async {
      await family();
      await child('kid_1');
      final ai = DriftAiRepository(db);
      await ai.recordEvent(
        familyId: 'fam_1',
        childAlias: 'kid_1_alias',
        domain: 'EDU',
        kind: 'mathDip',
        severity: 2,
        at: now.subtract(const Duration(hours: 3)),
      );
      await ai.recordEvent(
        familyId: 'fam_1',
        childAlias: 'kid_1_alias',
        domain: 'COM',
        kind: 'lateNightChat',
        severity: 5,
        at: now.subtract(const Duration(hours: 1)),
      );

      final repo = DriftMotherAiFeedRepository(
        db,
        familyId: 'fam_1',
        clock: () => now,
      );
      final before = await repo.load();
      expect(before.hasFamily, isTrue);
      expect(before.whisperSent, isFalse);
      expect(before.items, hasLength(2));
      // Newest first, and the tag follows the event's own severity.
      expect(before.items.first.titleKey, 'lateNightChat');
      expect(before.items.first.bodyKey, 'COM');
      expect(before.items.first.tagKey, 'watch');
      expect(before.items.last.tagKey, 'good');

      final sent = await repo.sendWhisper();
      expect(sent.whisperSent, isTrue);
      // The whisper is a real event keyed by the child's alias, and it is not
      // one of the feed's own summaries.
      expect(sent.items, hasLength(2));
      final rows = await whisperRows();
      expect(rows, hasLength(1));
      expect(rows.single.domain, Stage1RowVocabulary.aiDomainCommunication);
      expect(rows.single.childAlias, 'kid_1_alias');

      // A second whisper is the same one, never a second row.
      await repo.sendWhisper();
      expect(await whisperRows(), hasLength(1));

      // ADR-042 — the whisper outlives the process.
      await db.close();
      dbClosed = true;
      db = FamilyDatabase(NativeDatabase(file));
      final reopened = await DriftMotherAiFeedRepository(
        db,
        familyId: 'fam_1',
        clock: () => now,
      ).load();
      expect(reopened.whisperSent, isTrue);
      expect(reopened.items, hasLength(2));

      // A scope that owns no family reads nothing and whispers nothing.
      final stranger = DriftMotherAiFeedRepository(
        db,
        familyId: 'fam_none',
        clock: () => now,
      );
      expect((await stranger.load()).isEmpty, isTrue);
      expect((await stranger.sendWhisper()).whisperSent, isFalse);
      expect(await whisperRows(), hasLength(1));
    });

    test('brain gateway: an enabled stage opens the stored suggestions', () async {
      await family();
      await suggestion(id: 'sug_1', headline: 'bedtimePause');
      await suggestion(id: 'sug_old', headline: 'olderInsight', appliedAt: now);

      final gateway = DriftAdvisorGateway(
        db,
        familyId: 'fam_1',
        clock: () => now,
      );
      final suggest = await gateway.suggestions();
      expect(
        suggest.map((s) => s.title).toSet(),
        {'bedtimePause', 'olderInsight'},
      );
      expect(suggest.first.body, '');
      expect(suggest.first.stage, AiStageId.suggest);

      // No stage column — every enabled stage reads the same stored rows.
      final analyze = await gateway.suggestions(stage: AiStageId.analyze);
      expect(analyze.map((s) => s.title).toSet(), {'bedtimePause', 'olderInsight'});

      final empty = await DriftAdvisorGateway(
        db,
        familyId: 'fam_none',
        clock: () => now,
      ).suggestions();
      expect(empty, isEmpty);
    });
  });
}
