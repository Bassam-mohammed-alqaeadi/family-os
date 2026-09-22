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

void main() {
  tearDown(AppToast.dismiss);

  final child = ChildId('set005-child');
  final adultsUrl = Uri.parse('https://adult.example/page');

  WebFilterPolicy adultsOnPolicy({int version = 1}) => WebFilterPolicy(
        level: WebFilterLevel.open,
        categories: {
          for (final k in WebFilterCategories.known) k: false,
          WebFilterCategories.adults: true,
        },
        policyVersion: version,
      );

  testWidgets(
    'same URL+policy → identical verdict on child page and father preview',
    (tester) async {
      final policy = adultsOnPolicy(version: 4);
      final snapshot = WebFilterDecisionSnapshot.evaluate(adultsUrl, policy);

      await tester.pumpWidget(
        _l10nApp(
          home: WebBlockPage(
            key: const Key('child_block'),
            snapshot: snapshot,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('web_block_verdict_deny_adults_v4')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('web_block_unlock_cta')), findsOneWidget);
      expect(find.textContaining('بالغين'), findsOneWidget);
      expect(find.text('adults'), findsNothing);

      final repo = InMemoryWebFilterPolicyRepository({child.value: policy});
      await _pumpFilter(
        tester,
        repository: repo,
        childId: child,
        role: AppRole.father,
      );

      await _scrollToPreview(tester);
      await tester.enterText(
        find.byKey(const Key('web_filter_preview_url')),
        adultsUrl.toString(),
      );
      await tester.tap(find.byKey(const Key('web_filter_preview_open')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('web_filter_preview_block')), findsOneWidget);
      expect(
        find.byKey(const Key('web_block_verdict_deny_adults_v4')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('web_block_reason')), findsOneWidget);
      expect(find.textContaining('بالغين'), findsWidgets);
    },
  );

  testWidgets('adults category shows Arabic human reason (G-3)', (tester) async {
    final snapshot = WebFilterDecisionSnapshot.evaluate(
      adultsUrl,
      adultsOnPolicy(),
    );

    await tester.pumpWidget(
      _l10nApp(home: WebBlockPage(snapshot: snapshot)),
    );
    await tester.pumpAndSettle();

    final reason = tester.widget<Text>(find.byKey(const Key('web_block_reason')));
    expect(reason.data, isNotNull);
    expect(reason.data!, contains('بالغين'));
    expect(reason.data!, isNot(equals('adults')));
    expect(find.text('adults'), findsNothing);
  });

  testWidgets('unlock CTA visible on deny', (tester) async {
    var tapped = false;
    final snapshot = WebFilterDecisionSnapshot.evaluate(
      adultsUrl,
      adultsOnPolicy(),
    );

    await tester.pumpWidget(
      _l10nApp(
        home: WebBlockPage(
          snapshot: snapshot,
          onRequestUnlock: () => tapped = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('web_block_unlock_cta')), findsOneWidget);
    await tester.tap(find.byKey(const Key('web_block_unlock_cta')));
    await tester.pump();
    expect(tapped, isTrue);
  });

  testWidgets('unlock CTA absent on allow', (tester) async {
    final policy = WebFilterPolicy(
      level: WebFilterLevel.open,
      categories: {for (final k in WebFilterCategories.known) k: false},
    );
    final snapshot = WebFilterDecisionSnapshot.evaluate(
      Uri.parse('https://school.example/'),
      policy,
    );

    await tester.pumpWidget(
      _l10nApp(home: WebBlockPage(snapshot: snapshot)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('web_block_unlock_cta')), findsNothing);
    expect(find.byKey(const Key('web_block_allowed_body')), findsOneWidget);
  });

  testWidgets('preview reopen re-evaluates after policy change', (tester) async {
    final repo = InMemoryWebFilterPolicyRepository({
      child.value: adultsOnPolicy(version: 1),
    });

    await _pumpFilter(
      tester,
      repository: repo,
      childId: child,
      role: AppRole.father,
    );

    await _scrollToPreview(tester);
    await tester.tap(find.byKey(const Key('web_filter_preview_open')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('web_block_verdict_deny_adults_v1')),
      findsOneWidget,
    );

    // Dismiss sheet (reopen must re-evaluate — SET-005).
    Navigator.of(
      tester.element(find.byKey(const Key('web_filter_preview_block'))),
    ).pop();
    await tester.pumpAndSettle();

    // Turn adults off in UI + save (bumps version).
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
    await _settleToast(tester);

    await _scrollToPreview(tester);
    await tester.tap(find.byKey(const Key('web_filter_preview_open')));
    await tester.pumpAndSettle();

    // Same fixture URL, new policy → allow + bumped version.
    expect(
      find.byKey(const Key('web_block_verdict_allow_none_v2')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('web_block_unlock_cta')), findsNothing);
  });
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
  required AppRole role,
}) async {
  final roleCtrl = RoleController(role);
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

Future<void> _settleToast(WidgetTester tester) async {
  AppToast.dismiss();
  await tester.pump(const Duration(milliseconds: 2600));
}
