import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/ai_suggestion_repository.dart';
import 'package:family_os/core/policy/rules_engine_rule_repository.dart';
import 'package:family_os/features/n07_advisor/my_advisor_screen.dart';

void main() {
  testWidgets('SET-022 two labeled sections + serves banner', (tester) async {
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

    expect(find.byKey(MyAdvisorKeys.servesBanner), findsOneWidget);
    expect(find.byKey(MyAdvisorKeys.suggestionsSection), findsOneWidget);
    expect(find.byKey(MyAdvisorKeys.myRulesSection), findsOneWidget);
    expect(find.text('اقتراحات المستشار'), findsOneWidget);
    expect(find.text('قواعطي'), findsOneWidget);
    expect(find.textContaining('يخدم'), findsWidgets);
  });

  testWidgets('SET-022 approve → appears under My rules; no execute', (
    tester,
  ) async {
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

    expect(find.byKey(MyAdvisorKeys.suggestionsList), findsOneWidget);
    expect(find.byKey(MyAdvisorKeys.rulesList), findsNothing);

    final firstId = (await suggestions.listPending()).first.id;
    await tester.tap(find.byKey(MyAdvisorKeys.approveBtn(firstId)));
    await tester.pumpAndSettle();

    expect(find.byKey(MyAdvisorKeys.rulesList), findsOneWidget);
    final enabled = await rules.listEnabled();
    expect(enabled, isNotEmpty);
    expect(enabled.first.sourceSuggestionId, firstId);

    // Suggestion object remains non-executable — no execute API.
    final inbox = await suggestions.listInbox();
    final approved = inbox.firstWhere((i) => i.id == firstId);
    expect(approved.decision, AiSuggestionDecision.approved);
    expect(
      approved.suggestion.runtimeType.toString().contains('execute'),
      isFalse,
    );
  });

  testWidgets('SET-022 mother read-only — no approve/reject', (tester) async {
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

    expect(find.byKey(MyAdvisorKeys.readOnlyHint), findsOneWidget);
    expect(find.byKey(MyAdvisorKeys.suggestionsSection), findsOneWidget);
    expect(find.text('موافقة'), findsNothing);
    expect(find.text('رفض'), findsNothing);
  });
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
