import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/advisor_repository.dart';
import 'package:family_os/core/policy/ai_stage_id.dart';
import 'package:family_os/core/policy/ai_suggestion_repository.dart';
import 'package:family_os/core/policy/rule_consequent.dart';
import 'package:family_os/core/policy/rules_engine_rule_repository.dart';
import 'package:family_os/features/n07_advisor/my_advisor_screen.dart';
import 'package:family_os/features/n07_advisor/rule_editor.dart';

void main() {
  testWidgets(
    'SET-023 picker omits ANTI_TAMPER / BLOCK_OVERRIDE / DELEGATION_EDIT',
    (tester) async {
      final rules = InMemoryRulesEngineRuleRepository();
      final suggestions = MockAiSuggestionRepository(rules: rules);

      await tester.pumpWidget(
        _app(
          child: MyAdvisorScreen(
            suggestions: suggestions,
            rules: rules,
            roleOverride: AppRole.father,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(RuleEditorKeys.section), findsOneWidget);
      expect(find.byKey(RuleEditorKeys.picker), findsOneWidget);

      for (final c in RuleConsequent.values) {
        expect(find.byKey(RuleEditorKeys.option(c)), findsOneWidget);
      }

      for (final id in ForbiddenRuleConsequentIds.all) {
        expect(
          find.byKey(RuleEditorKeys.forbiddenOption(id)),
          findsNothing,
          reason: '$id must not appear in consequent picker',
        );
        expect(find.textContaining(id), findsNothing);
      }

      expect(find.text('ANTI_TAMPER'), findsNothing);
      expect(find.text('BLOCK_OVERRIDE'), findsNothing);
      expect(find.text('DELEGATION_EDIT'), findsNothing);
    },
  );

  testWidgets('SET-023 father can save allow-listed consequent', (tester) async {
    final rules = InMemoryRulesEngineRuleRepository();

    await tester.pumpWidget(
      _app(
        child: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: RuleEditor(rules: rules, canEdit: true),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(RuleEditorKeys.option(RuleConsequent.grantMinutes)),
    );
    await tester.tap(
      find.byKey(RuleEditorKeys.option(RuleConsequent.grantMinutes)),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(RuleEditorKeys.saveBtn));
    await tester.tap(find.byKey(RuleEditorKeys.saveBtn));
    await tester.pumpAndSettle();

    final enabled = await rules.listEnabled();
    expect(enabled, isNotEmpty);
    expect(enabled.last.consequents, [RuleConsequent.grantMinutes]);
  });

  testWidgets('SET-023 mother has no rule editor', (tester) async {
    final rules = InMemoryRulesEngineRuleRepository();
    final suggestions = MockAiSuggestionRepository(rules: rules);

    await tester.pumpWidget(
      _app(
        child: MyAdvisorScreen(
          suggestions: suggestions,
          rules: rules,
          roleOverride: AppRole.mother,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(RuleEditorKeys.section), findsNothing);
    expect(find.byKey(RuleEditorKeys.picker), findsNothing);
  });

  testWidgets('SET-023 approve forbidden draft stays pending', (tester) async {
    final rules = InMemoryRulesEngineRuleRepository();
    final suggestions = MockAiSuggestionRepository(
      advisor: const _ForbiddenAdvisor(),
      rules: rules,
    );

    await tester.pumpWidget(
      _app(
        child: MyAdvisorScreen(
          suggestions: suggestions,
          rules: rules,
          roleOverride: AppRole.father,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(MyAdvisorKeys.approveBtn('sug-forbidden')));
    await tester.pumpAndSettle();

    expect(find.byKey(MyAdvisorKeys.approveForbiddenBlocked), findsOneWidget);
    expect(await rules.listEnabled(), isEmpty);
    expect(
      (await suggestions.listPending()).any((i) => i.id == 'sug-forbidden'),
      isTrue,
    );
  });
}

final class _ForbiddenAdvisor implements AdvisorRepository {
  const _ForbiddenAdvisor();

  @override
  Future<List<AiSuggestion>> suggestions({
    AiStageId stage = AiStageId.suggest,
  }) async {
    return const [
      AiSuggestion(
        id: 'sug-forbidden',
        title: 'Unlock blocked apps via rule',
        body: 'Must be blocked at approve.',
        proposedConsequentIds: [ForbiddenRuleConsequentIds.blockOverride],
      ),
    ];
  }
}

Widget _app({required Widget child}) {
  return MaterialApp(
    theme: buildFamilyTheme(),
    locale: const Locale('ar'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: child,
  );
}
