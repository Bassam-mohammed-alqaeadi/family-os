import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/policy/advisor_repository.dart';
import 'package:family_os/core/policy/ai_suggestion_repository.dart';
import 'package:family_os/core/policy/rules_engine_rule_repository.dart';

void main() {
  group('SET-022 AiSuggestionRepository', () {
    test('approve creates rule; suggestion stays non-executable', () async {
      final rules = InMemoryRulesEngineRuleRepository();
      final suggestions = MockAiSuggestionRepository(rules: rules);

      final pending = await suggestions.listPending();
      expect(pending, isNotEmpty);
      final id = pending.first.id;

      await suggestions.approve(id);

      final enabled = await rules.listEnabled();
      expect(enabled.single.sourceSuggestionId, id);
      expect(enabled.single.authoredByFather, isTrue);

      final inbox = await suggestions.listInbox();
      expect(
        inbox.firstWhere((i) => i.id == id).decision,
        AiSuggestionDecision.approved,
      );

      // Type surface: AiSuggestion has no execute (compile + architecture).
      const sample = AiSuggestion(id: 'x', title: 't', body: 'b');
      expect(sample.id, 'x');
    });

    test('reject removes from pending without creating a rule', () async {
      final rules = InMemoryRulesEngineRuleRepository();
      final suggestions = MockAiSuggestionRepository(rules: rules);
      final id = (await suggestions.listPending()).first.id;

      await suggestions.reject(id);

      final pendingAfter = await suggestions.listPending();
      expect(pendingAfter.any((i) => i.id == id), isFalse);
      expect(await rules.listEnabled(), isEmpty);
    });
  });

  group('architecture — ADR-038', () {
    test('AiSuggestion has no execute method in source', () {
      final files = [
        File('lib/core/policy/advisor_repository.dart'),
        File('lib/core/policy/ai_suggestion_repository.dart'),
      ];
      final methodPattern = RegExp(
        r'(Future(<[^>]+>)?|void|bool|dynamic)\s+execute\s*\(',
      );
      for (final f in files) {
        expect(f.existsSync(), isTrue, reason: f.path);
        final text = f.readAsStringSync();
        expect(
          methodPattern.hasMatch(text),
          isFalse,
          reason: 'Forbidden AiSuggestion.execute() in ${f.path}',
        );
      }
    });

    test('RulesEngineRuleRepository is outside AI gateways', () {
      final text =
          File('lib/core/policy/rules_engine_rule_repository.dart')
              .readAsStringSync();
      expect(text.contains('implements AdvisorRepository'), isFalse);
      expect(text.contains('implements InsightsRepository'), isFalse);
      expect(text.contains('implements TutorRepository'), isFalse);
      expect(
        text.contains('Advisor / Insights / Tutor'),
        isTrue,
        reason: 'ADR-038 comment must keep RulesEngine outside AI gateways',
      );
    });

    test('lib has no AiSuggestion.execute call sites', () {
      final lib = Directory('lib');
      final offenders = <String>[];
      final callPattern = RegExp(r'AiSuggestion[^\n]*\.execute\s*\(');
      for (final entity in lib.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final text = entity.readAsStringSync();
        if (callPattern.hasMatch(text) ||
            RegExp(r'\.execute\s*\(\s*\).*suggestion', caseSensitive: false)
                .hasMatch(text)) {
          offenders.add(entity.path);
        }
      }
      expect(offenders, isEmpty, reason: 'execute call sites: $offenders');
    });
  });
}
