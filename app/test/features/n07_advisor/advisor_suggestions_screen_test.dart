import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/advisor_repository.dart';
import 'package:family_os/core/policy/ai_stage_id.dart';
import 'package:family_os/core/policy/ai_suggestion_repository.dart';
import 'package:family_os/core/policy/rules_engine_rule_repository.dart';
import 'package:family_os/features/n07_advisor/advisor_suggestions_screen.dart';

void main() {
  testWidgets('SCR-FAT-011 Bark banner + suggest-only list (no silent apply)', (
    tester,
  ) async {
    final rules = InMemoryRulesEngineRuleRepository();
    final suggestions = MockAiSuggestionRepository(rules: rules);

    await tester.pumpWidget(
      _app(
        child: AdvisorSuggestionsScreen(
          suggestions: suggestions,
          rules: rules,
          roleOverride: AppRole.father,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(AdvisorSuggestionsKeys.servesBanner), findsOneWidget);
    expect(find.byKey(AdvisorSuggestionsKeys.list), findsOneWidget);
    expect(find.textContaining('تقرر'), findsWidgets);

    // Pending still pending — nothing applied until confirm.
    final pending = await suggestions.listPending();
    expect(pending, isNotEmpty);
    expect(await rules.listEnabled(), isEmpty);
  });

  testWidgets('SCR-FAT-011 empty → AppEmptyState', (tester) async {
    final rules = InMemoryRulesEngineRuleRepository();
    final suggestions = MockAiSuggestionRepository(
      advisor: const _EmptyAdvisor(),
      rules: rules,
    );

    await tester.pumpWidget(
      _app(
        child: AdvisorSuggestionsScreen(
          suggestions: suggestions,
          rules: rules,
          roleOverride: AppRole.father,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(AdvisorSuggestionsKeys.empty), findsOneWidget);
    expect(find.byType(AppEmptyState), findsOneWidget);
    expect(find.byKey(AdvisorSuggestionsKeys.list), findsNothing);
    expect(find.byKey(AdvisorSuggestionsKeys.servesBanner), findsOneWidget);
  });

  testWidgets('SCR-FAT-011 approve requires explicit confirm before rule', (
    tester,
  ) async {
    final rules = InMemoryRulesEngineRuleRepository();
    final suggestions = MockAiSuggestionRepository(rules: rules);

    await tester.pumpWidget(
      _app(
        child: AdvisorSuggestionsScreen(
          suggestions: suggestions,
          rules: rules,
          roleOverride: AppRole.father,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final firstId = (await suggestions.listPending()).first.id;

    // Tap approve → dialog only; no rule yet.
    await tester.tap(find.byKey(AdvisorSuggestionsKeys.approveBtn(firstId)));
    await tester.pumpAndSettle();
    expect(
      find.byKey(AdvisorSuggestionsKeys.approveConfirmDialog),
      findsOneWidget,
    );
    expect(await rules.listEnabled(), isEmpty);
    expect(
      (await suggestions.listInbox())
          .firstWhere((i) => i.id == firstId)
          .decision,
      AiSuggestionDecision.pending,
    );

    // Cancel keeps pending.
    await tester.tap(find.byKey(AdvisorSuggestionsKeys.approveConfirmCancel));
    await tester.pumpAndSettle();
    expect(await rules.listEnabled(), isEmpty);

    // Confirm → rule created; suggestion never executes.
    await tester.tap(find.byKey(AdvisorSuggestionsKeys.approveBtn(firstId)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(AdvisorSuggestionsKeys.approveConfirmAction));
    await tester.pumpAndSettle();

    final enabled = await rules.listEnabled();
    expect(enabled, isNotEmpty);
    expect(enabled.first.sourceSuggestionId, firstId);
    final approved = (await suggestions.listInbox()).firstWhere(
      (i) => i.id == firstId,
    );
    expect(approved.decision, AiSuggestionDecision.approved);
    expect(
      approved.suggestion.runtimeType.toString().contains('execute'),
      isFalse,
    );
  });

  testWidgets('SCR-FAT-011 reject dismisses without creating a rule', (
    tester,
  ) async {
    final rules = InMemoryRulesEngineRuleRepository();
    final suggestions = MockAiSuggestionRepository(rules: rules);

    await tester.pumpWidget(
      _app(
        child: AdvisorSuggestionsScreen(
          suggestions: suggestions,
          rules: rules,
          roleOverride: AppRole.father,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final firstId = (await suggestions.listPending()).first.id;
    await tester.tap(find.byKey(AdvisorSuggestionsKeys.rejectBtn(firstId)));
    await tester.pumpAndSettle();

    expect(await rules.listEnabled(), isEmpty);
    expect(
      (await suggestions.listInbox())
          .firstWhere((i) => i.id == firstId)
          .decision,
      AiSuggestionDecision.rejected,
    );
  });

  testWidgets('SCR-FAT-011 mother read-only — no approve/reject', (
    tester,
  ) async {
    final rules = InMemoryRulesEngineRuleRepository();
    final suggestions = MockAiSuggestionRepository(rules: rules);

    await tester.pumpWidget(
      _app(
        child: AdvisorSuggestionsScreen(
          suggestions: suggestions,
          rules: rules,
          roleOverride: AppRole.mother,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(AdvisorSuggestionsKeys.readOnlyHint), findsOneWidget);
    expect(find.byKey(AdvisorSuggestionsKeys.list), findsOneWidget);
    expect(find.text('موافقة'), findsNothing);
    expect(find.text('رفض'), findsNothing);
  });

  testWidgets('SCR-FAT-011 load error → AppErrorState + Retry', (tester) async {
    await tester.pumpWidget(
      _app(
        child: AdvisorSuggestionsScreen(
          suggestions: _FailingSuggestions(),
          rules: InMemoryRulesEngineRuleRepository(),
          roleOverride: AppRole.father,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(AdvisorSuggestionsKeys.error), findsOneWidget);
    expect(find.byKey(const Key('app_error_retry')), findsOneWidget);
  });
}

class _EmptyAdvisor implements AdvisorRepository {
  const _EmptyAdvisor();

  @override
  Future<List<AiSuggestion>> suggestions({
    AiStageId stage = AiStageId.suggest,
  }) async =>
      const [];
}

class _FailingSuggestions implements AiSuggestionRepository {
  @override
  Future<void> approve(String suggestionId) async {}

  @override
  Future<List<AiSuggestionInboxItem>> listInbox() async {
    throw StateError('mock load failure');
  }

  @override
  Future<List<AiSuggestionInboxItem>> listPending() async {
    throw StateError('mock load failure');
  }

  @override
  Future<void> reject(String suggestionId) async {}
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
