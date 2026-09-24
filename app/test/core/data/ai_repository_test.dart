import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/data/ai_repository.dart';
import 'package:family_os/core/data/communication_rules.dart';
import 'package:family_os/core/data/family_database.dart';

/// PERS-2d — what the AI layer observed, and what it suggested.
///
/// The two rules that matter most are measured here: the AI layer addresses a
/// child by alias and never by name, and a suggestion's ten-minute undo is a
/// real window that actually closes.
final DateTime _base = DateTime(2026, 9, 24, 12);

void main() {
  late FamilyDatabase db;
  late DriftAiRepository repo;

  setUp(() {
    db = FamilyDatabase(NativeDatabase.memory());
    repo = DriftAiRepository(db);
  });

  tearDown(() => db.close());

  Future<int> observe({
    String alias = 'lion-01',
    String domain = 'SEC',
    int severity = 3,
    String payload = '{}',
    DateTime? at,
  }) =>
      repo.recordEvent(
        familyId: 'fam-1',
        childAlias: alias,
        domain: domain,
        kind: 'RISKY_WORD',
        severity: severity,
        payload: payload,
        at: at ?? _base,
      );

  Future<AiSuggestionRow> suggest({
    String id = 'sug-1',
    String actionLabel = 'اسأل',
    int? pct = 80,
  }) =>
      repo.addSuggestion(
        id: id,
        familyId: 'fam-1',
        headline: 'لاحظنا تغيّرًا في وقت النوم',
        actionLabel: actionLabel,
        actionKind: 'ASK',
        confidence: AiConfidence.analysis,
        childAlias: 'lion-01',
        confidencePct: pct,
        at: _base,
      );

  group('observed events', () {
    test('an event is stored against the alias, never the name', () async {
      await observe(payload: '{"excerpt":"..."}');

      final events = await repo.eventsInFamily('fam-1');

      expect(events, hasLength(1));
      expect(events.single.childAlias, 'lion-01');
      expect(events.single.domain, 'SEC');
      expect(events.single.severity, 3);
      expect(events.single.payload, '{"excerpt":"..."}');
    });

    test('events are newest-first and scope by alias', () async {
      await observe(at: _base);
      await observe(alias: 'fox-02', at: _base.add(const Duration(minutes: 5)));

      final all = await repo.eventsInFamily('fam-1');
      expect(all, hasLength(2));
      expect(all.first.childAlias, 'fox-02');

      final justLion = await repo.eventsInFamily('fam-1', childAlias: 'lion-01');
      expect(justLion, hasLength(1));
    });

    test('severe events start at the severity asked for', () async {
      await observe(severity: 2, at: _base);
      await observe(severity: 5, at: _base);

      final severe = await repo.severeEventsInFamily('fam-1', minSeverity: 4);

      expect(severe, hasLength(1));
      expect(severe.single.severity, 5);
    });

    test('an empty alias, an unknown domain or a bad severity is refused', () async {
      await expectLater(observe(alias: '  '), throwsA(isA<ArgumentError>()));
      await expectLater(observe(domain: 'FIN'), throwsA(isA<ArgumentError>()));
      await expectLater(observe(severity: 9), throwsA(isA<ArgumentError>()));

      expect(await repo.eventsInFamily('fam-1'), isEmpty);
    });

    test('the payload must be an excerpt and must be JSON', () async {
      await expectLater(
        observe(payload: 'x' * (kMaxPayloadChars + 1)),
        throwsA(isA<ArgumentError>()),
      );
      await expectLater(
        observe(payload: 'not json'),
        throwsA(isA<ArgumentError>()),
      );

      expect(await repo.eventsInFamily('fam-1'), isEmpty);
    });
  });

  group('suggestions', () {
    test('a suggestion carries one action and its confidence', () async {
      final suggestion = await suggest();

      expect(suggestion.actionLabel, 'اسأل');
      expect(suggestion.actionKind, 'ASK');
      expect(suggestion.confidence, AiConfidence.analysis);
      expect(suggestion.confidencePct, 80);
      expect(suggestion.appliedAt, isNull);
      expect(suggestion.undoneAt, isNull);
      expect(suggestion.dismissedAt, isNull);
    });

    test('an empty action or a percentage off the scale is refused', () async {
      await expectLater(
        suggest(actionLabel: ' '),
        throwsA(isA<ArgumentError>()),
      );
      await expectLater(suggest(pct: 140), throwsA(isA<ArgumentError>()));

      expect(await repo.suggestionsInFamily('fam-1'), isEmpty);
    });

    test('applying records that a person acted, and cannot happen twice', () async {
      await suggest();

      final applied = await repo.applySuggestion(
        'sug-1',
        at: _base.add(const Duration(minutes: 1)),
      );
      expect(applied.appliedAt, _base.add(const Duration(minutes: 1)));

      await expectLater(
        repo.applySuggestion('sug-1', at: _base.add(const Duration(minutes: 2))),
        throwsA(isA<SuggestionStateException>()),
      );
    });

    test('the ten-minute undo works, and then closes', () async {
      await suggest();
      await repo.applySuggestion('sug-1', at: _base);

      final undone = await repo.undoSuggestion(
        'sug-1',
        at: _base.add(const Duration(minutes: 9)),
      );
      expect(undone.undoneAt, _base.add(const Duration(minutes: 9)));
    });

    test('an undo after the window is refused', () async {
      await suggest();
      await repo.applySuggestion('sug-1', at: _base);

      await expectLater(
        repo.undoSuggestion(
          'sug-1',
          at: _base.add(const Duration(minutes: 11)),
        ),
        throwsA(isA<SuggestionStateException>()),
      );
    });

    test('undoing something never applied is refused', () async {
      await suggest();

      await expectLater(
        repo.undoSuggestion('sug-1', at: _base),
        throwsA(isA<SuggestionStateException>()),
      );
    });

    test('a dismissed suggestion cannot be undone', () async {
      await suggest();
      await repo.applySuggestion('sug-1', at: _base);
      await repo.dismissSuggestion(
        'sug-1',
        at: _base.add(const Duration(minutes: 1)),
      );

      await expectLater(
        repo.undoSuggestion('sug-1', at: _base.add(const Duration(minutes: 2))),
        throwsA(isA<SuggestionStateException>()),
      );
    });

    test('an unknown suggestion is refused, not silently ignored', () async {
      await expectLater(
        repo.applySuggestion('nope'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('acceptance — observations survive a database reopen', () {
    test('record + suggest, close, reopen, read', () async {
      final dir = Directory.systemTemp.createTempSync('family_os_pers2d_ai');
      final file = File('${dir.path}/family_os.sqlite');

      try {
        var fileDb = FamilyDatabase(NativeDatabase(file));
        var fileRepo = DriftAiRepository(fileDb);
        await fileRepo.recordEvent(
          familyId: 'fam-1',
          childAlias: 'lion-01',
          domain: 'EDU',
          kind: 'LATE_NIGHT',
          severity: 4,
          payload: '{"excerpt":"..."}',
          at: _base,
        );
        await fileRepo.addSuggestion(
          id: 'sug-9',
          familyId: 'fam-1',
          headline: 'وقت نوم متأخّر',
          actionLabel: 'أنشئ قاعدة',
          actionKind: 'RULE',
          confidence: AiConfidence.preliminary,
          at: _base,
        );
        await fileDb.close();

        // A fresh handle over the same file — nothing shared in memory.
        fileDb = FamilyDatabase(NativeDatabase(file));
        fileRepo = DriftAiRepository(fileDb);

        final events = await fileRepo.eventsInFamily('fam-1');
        final suggestions = await fileRepo.suggestionsInFamily('fam-1');

        expect(events, hasLength(1));
        expect(events.single.childAlias, 'lion-01');
        expect(suggestions, hasLength(1));
        expect(suggestions.single.confidence, AiConfidence.preliminary);
        await fileDb.close();
      } finally {
        dir.deleteSync(recursive: true);
      }
    });
  });
}
