import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/policy/advisor_repository.dart';
import 'package:family_os/core/policy/ai_stage_id.dart';
import 'package:family_os/core/policy/ai_suggestion_repository.dart';
import 'package:family_os/core/policy/rule_consequent.dart';
import 'package:family_os/core/policy/rules_engine_rule_repository.dart';

void main() {
  group('SET-023 RuleConsequent allow-list', () {
    test('enum excludes forbidden owner-only consequents', () {
      final ids = RuleConsequent.values.map((c) => c.id).toSet();
      expect(ids.contains(ForbiddenRuleConsequentIds.antiTamper), isFalse);
      expect(ids.contains(ForbiddenRuleConsequentIds.blockOverride), isFalse);
      expect(ids.contains(ForbiddenRuleConsequentIds.delegationEdit), isFalse);
      expect(ids, containsAll(['NOTIFY_FATHER', 'GRANT_MINUTES', 'SOFT_LOCK']));
    });

    test('validate / save reject forbidden payload', () async {
      final rules = InMemoryRulesEngineRuleRepository();

      expect(
        () => rules.validate([ForbiddenRuleConsequentIds.antiTamper]),
        throwsA(isA<ForbiddenRuleConsequentException>()),
      );
      expect(
        () => rules.validate([ForbiddenRuleConsequentIds.blockOverride]),
        throwsA(isA<ForbiddenRuleConsequentException>()),
      );
      expect(
        () => rules.validate([ForbiddenRuleConsequentIds.delegationEdit]),
        throwsA(isA<ForbiddenRuleConsequentException>()),
      );

      await expectLater(
        rules.save(
          title: 'Hack',
          body: 'should fail',
          consequentIds: [ForbiddenRuleConsequentIds.antiTamper],
        ),
        throwsA(isA<ForbiddenRuleConsequentException>()),
      );
      expect(await rules.listAll(), isEmpty);

      final ok = await rules.save(
        title: 'Notify',
        body: 'ok',
        consequentIds: [RuleConsequent.notifyFather.id],
      );
      expect(ok.consequents, [RuleConsequent.notifyFather]);
    });

    test('approve suggestion with forbidden draft is blocked', () async {
      final rules = InMemoryRulesEngineRuleRepository();
      final advisor = _ForbiddenDraftAdvisor();
      final suggestions = MockAiSuggestionRepository(
        advisor: advisor,
        rules: rules,
      );

      final id = (await suggestions.listPending()).first.id;
      await expectLater(
        suggestions.approve(id),
        throwsA(isA<ForbiddenRuleConsequentException>()),
      );

      expect(await rules.listEnabled(), isEmpty);
      final inbox = await suggestions.listInbox();
      expect(
        inbox.firstWhere((i) => i.id == id).decision,
        AiSuggestionDecision.pending,
      );
    });
  });
}

/// Advisor that drafts an ADR-038(d) forbidden consequent.
final class _ForbiddenDraftAdvisor implements AdvisorRepository {
  @override
  Future<List<AiSuggestion>> suggestions({
    AiStageId stage = AiStageId.suggest,
  }) async {
    return const [
      AiSuggestion(
        id: 'sug-forbidden',
        title: 'Disable anti-tamper overnight',
        body: 'Draft must not become a rule.',
        proposedConsequentIds: [ForbiddenRuleConsequentIds.antiTamper],
      ),
    ];
  }
}
