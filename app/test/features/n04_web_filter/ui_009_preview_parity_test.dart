import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/web_filter_evaluator.dart';
import 'package:family_os/core/policy/web_filter_policy.dart';
import 'package:family_os/core/policy/web_filter_policy_repository.dart';
import 'package:family_os/features/n04_web_filter/web_block_page.dart';
import 'package:family_os/features/n04_web_filter/web_filter_screen.dart';

/// UI-009 — FAT-036 father preview ≡ child block page (SET-005 / P-8).
void main() {
  tearDown(AppToast.dismiss);

  final child = ChildId('ui009-child');
  final adultsUrl = Uri.parse(kWebFilterPreviewFixtureUrl);

  WebFilterPolicy adultsOnPolicy({int version = 1}) => WebFilterPolicy(
        level: WebFilterLevel.open,
        categories: {
          for (final k in WebFilterCategories.known) k: false,
          WebFilterCategories.adults: true,
        },
        policyVersion: version,
      );

  test('AC1 unit: same URL+policy → identical snapshot (shared evaluate)', () {
    final policy = adultsOnPolicy(version: 9);
    final childSnap = WebFilterDecisionSnapshot.evaluate(adultsUrl, policy);
    final previewSnap = WebFilterDecisionSnapshot.evaluate(adultsUrl, policy);

    expect(childSnap, previewSnap);
    expect(childSnap.isDenied, isTrue);
    expect(childSnap.categoryKey, WebFilterCategories.adults);
    expect(childSnap.policyVersion, 9);
    expect(childSnap.policyVersion, childSnap.decision.policyVersion);
  });

  testWidgets(
    'AC1: same URL verdict on child WebBlockPage and FAT-036 preview',
    (tester) async {
      final policy = adultsOnPolicy(version: 5);
      final snapshot = WebFilterDecisionSnapshot.evaluate(adultsUrl, policy);
      final verdictKey = const Key('web_block_verdict_deny_adults_v5');

      await tester.pumpWidget(
        _l10nApp(
          home: WebBlockPage(
            key: const Key('ui009_child_block'),
            snapshot: snapshot,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(verdictKey), findsOneWidget);
      expect(find.byKey(const Key('web_block_unlock_cta')), findsOneWidget);

      final repo = InMemoryWebFilterPolicyRepository({child.value: policy});
      await _pumpFilter(
        tester,
        repository: repo,
        childId: child,
      );

      await _scrollToPreview(tester);
      await tester.enterText(
        find.byKey(const Key('web_filter_preview_url')),
        adultsUrl.toString(),
      );
      await tester.tap(find.byKey(const Key('web_filter_preview_open')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('web_filter_preview_block')), findsOneWidget);
      expect(find.byKey(verdictKey), findsOneWidget);
      expect(find.byKey(const Key('web_block_preview_caption')), findsOneWidget);
    },
  );

  testWidgets('AC2: preview CTA reachable from FAT-036', (tester) async {
    final repo = InMemoryWebFilterPolicyRepository({
      child.value: adultsOnPolicy(),
    });

    await _pumpFilter(
      tester,
      repository: repo,
      childId: child,
    );

    expect(find.byKey(const Key('web_filter_preview_open')), findsNothing);
    await _scrollToPreview(tester);

    expect(find.byKey(const Key('web_filter_preview_open')), findsOneWidget);
    expect(find.byKey(const Key('web_filter_preview_url')), findsOneWidget);
    expect(find.byKey(const Key('web_filter_preview_fixture')), findsOneWidget);

    await tester.tap(find.byKey(const Key('web_filter_preview_fixture')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('web_filter_preview_open')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('web_filter_preview_block')), findsOneWidget);
    expect(
      find.byKey(const Key('web_block_verdict_deny_adults_v1')),
      findsOneWidget,
    );
  });

  testWidgets(
    'stale preview after policy edit → reopen refreshes verdict',
    (tester) async {
      final repo = InMemoryWebFilterPolicyRepository({
        child.value: adultsOnPolicy(version: 1),
      });

      await _pumpFilter(
        tester,
        repository: repo,
        childId: child,
      );

      await _scrollToPreview(tester);
      await tester.tap(find.byKey(const Key('web_filter_preview_open')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('web_block_verdict_deny_adults_v1')),
        findsOneWidget,
      );

      Navigator.of(
        tester.element(find.byKey(const Key('web_filter_preview_block'))),
      ).pop();
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byKey(const Key('web_filter_switch_adults')),
        -300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('web_filter_switch_adults')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('web_filter_save')));
      await tester.pump();
      AppToast.dismiss();
      await tester.pump(const Duration(milliseconds: 2600));

      await _scrollToPreview(tester);
      await tester.tap(find.byKey(const Key('web_filter_preview_open')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('web_block_verdict_allow_none_v2')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('web_block_unlock_cta')), findsNothing);
    },
  );
}

Widget _l10nApp({required Widget home}) {
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
    home: home,
  );
}

Future<void> _pumpFilter(
  WidgetTester tester, {
  required WebFilterPolicyRepository repository,
  required ChildId childId,
}) async {
  final roleCtrl = RoleController(AppRole.father);
  await tester.pumpWidget(
    CurrentRole(
      notifier: roleCtrl,
      child: _l10nApp(
        home: WebFilterScreen(
          childId: childId,
          repository: repository,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _scrollToPreview(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.byKey(const Key('web_filter_preview_open')),
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}
