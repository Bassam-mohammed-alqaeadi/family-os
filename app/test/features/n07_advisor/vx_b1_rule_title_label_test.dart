import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/ai_suggestion_repository.dart';
import 'package:family_os/core/policy/rule_consequent.dart';
import 'package:family_os/core/policy/rules_engine_rule_repository.dart';
import 'package:family_os/features/n07_advisor/my_advisor_screen.dart';
import 'package:family_os/features/n07_advisor/rule_editor.dart';

/// VX-B1 / FVX-C-04 — SCR-FAT-079 saved rules read as people words,
/// never "Rule" + a wire id.
void main() {
  for (final locale in const [Locale('ar'), Locale('en')]) {
    testWidgets('editor rule reads as words (${locale.languageCode})', (
      tester,
    ) async {
      final rules = InMemoryRulesEngineRuleRepository();
      final saved = await rules.save(
        title: 'Rule',
        body: RuleConsequent.grantMinutes.id,
        consequentIds: [RuleConsequent.grantMinutes.id],
      );

      await tester.pumpWidget(
        _app(
          locale: locale,
          child: MyAdvisorScreen(
            suggestions: MockAiSuggestionRepository(rules: rules),
            rules: rules,
            roleOverride: AppRole.father,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final row = find.byKey(MyAdvisorKeys.ruleRow(saved.id));
      await tester.ensureVisible(row);
      final l10n = lookupAppLocalizations(locale);
      Finder inRow(String text) =>
          find.descendant(of: row, matching: find.text(text));
      final label = ruleConsequentLabel(l10n, RuleConsequent.grantMinutes);
      expect(inRow(l10n.myAdvisorOwnRuleTitle), findsOneWidget);
      expect(inRow(label), findsOneWidget);
      expect(inRow('Rule'), findsNothing);
      expect(inRow('GRANT_MINUTES'), findsNothing);
    });
  }
}

Widget _app({required Locale locale, required Widget child}) {
  return MaterialApp(
    theme: buildFamilyTheme(),
    locale: locale,
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
