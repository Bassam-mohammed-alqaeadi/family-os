import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/web_filter_evaluator.dart';
import 'package:family_os/core/policy/web_filter_policy.dart';
import 'package:family_os/core/policy/web_filter_policy_repository.dart';
import 'package:family_os/core/policy/web_unlock_request.dart';
import 'package:family_os/core/policy/web_unlock_request_repository.dart';
import 'package:family_os/core/policy/web_unlock_service.dart';
import 'package:family_os/features/n04_web_filter/web_block_page.dart';
import 'package:family_os/features/n04_web_filter/web_filter_screen.dart';
import 'package:family_os/features/n04_web_filter/web_unlock_inbox.dart';

void main() {
  tearDown(AppToast.dismiss);

  final child = ChildId('set006-ui-child');
  final adultsUrl = Uri.parse('https://adult.example/page');

  WebFilterPolicy adultsOnPolicy() => WebFilterPolicy(
        level: WebFilterLevel.open,
        categories: {
          for (final k in WebFilterCategories.known) k: false,
          WebFilterCategories.adults: true,
        },
      );

  ({
    WebUnlockService service,
    InMemoryWebFilterPolicyRepository policyRepo,
  }) harness() {
    final policyRepo = InMemoryWebFilterPolicyRepository({
      child.value: adultsOnPolicy(),
    });
    final service = WebUnlockService(
      requestRepository: InMemoryWebUnlockRequestRepository(),
      idFactory: () => 'ui-req-1',
    );
    return (service: service, policyRepo: policyRepo);
  }

  testWidgets(
    'E2E: unlock CTA → partner approve → host allowed by evaluator',
    (tester) async {
      final h = harness();
      final snapshot = WebFilterDecisionSnapshot.evaluate(
        adultsUrl,
        adultsOnPolicy(),
      );

      await tester.pumpWidget(
        _l10nApp(
          home: WebBlockPage(
            snapshot: snapshot,
            childId: child,
            unlockService: h.service,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('web_block_unlock_cta')));
      await tester.pumpAndSettle();
      AppToast.dismiss();
      await tester.pump(const Duration(milliseconds: 2600));

      final pending = await h.service.listPending(childId: child);
      expect(pending, hasLength(1));

      await tester.pumpWidget(
        _l10nApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: WebUnlockInbox(
                service: h.service,
                role: AppRole.mother,
                motherLevel: MotherLevel.partner,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('web_unlock_inbox')), findsOneWidget);
      await tester.tap(find.byKey(Key('web_unlock_approve_${pending.first.id}')));
      await tester.pumpAndSettle();
      AppToast.dismiss();
      await tester.pump(const Duration(milliseconds: 100));

      final policy = await h.policyRepo.load(child);
      expect(policy.allowList, isEmpty);
      final temps = await h.service.activeTemporaryHosts(child);
      expect(temps, contains('adult.example'));
      expect(
        WebFilterEvaluator.decide(
          adultsUrl,
          policy,
          activeTemporaryAllows: temps,
        ).isDenied,
        isFalse,
      );
      expect(find.byKey(const Key('web_unlock_inbox_empty')), findsOneWidget);
    },
  );

  testWidgets('mother observer sees list but Approve absent', (tester) async {
    final h = harness();
    await h.service.requestUnlock(child, adultsUrl.toString());

    await tester.pumpWidget(
      _l10nApp(
        home: Scaffold(
          body: WebUnlockInbox(
            service: h.service,
            role: AppRole.mother,
            motherLevel: MotherLevel.observer,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('web_unlock_row_ui-req-1')), findsOneWidget);
    expect(find.byKey(const Key('web_unlock_approve_ui-req-1')), findsNothing);
    expect(
      find.byKey(const Key('web_unlock_observer_only_ui-req-1')),
      findsOneWidget,
    );
  });

  testWidgets('FAT-036 inbox section present for father', (tester) async {
    final h = harness();
    await _pumpFilter(
      tester,
      repository: h.policyRepo,
      unlockService: h.service,
      childId: child,
      role: AppRole.father,
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('web_unlock_inbox')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('web_unlock_inbox')), findsOneWidget);
    expect(find.byKey(const Key('web_unlock_inbox_empty')), findsOneWidget);
  });

  testWidgets('child decision bus publishes after father deny', (tester) async {
    final h = harness();
    final created =
        await h.service.requestUnlock(child, adultsUrl.toString());
    WebUnlockRequest? heard;
    h.service.decisionBus.addListener(() {
      heard = h.service.decisionBus.lastDecision;
    });

    await h.service.deny(
      created.request.id,
      const WebUnlockActor.father(),
      reason: 'no',
    );
    expect(heard?.status.name, 'denied');
  });
}

Future<void> _pumpFilter(
  WidgetTester tester, {
  required WebFilterPolicyRepository repository,
  required WebUnlockService unlockService,
  required ChildId childId,
  required AppRole role,
  MotherLevel motherLevel = MotherLevel.partner,
}) async {
  await tester.pumpWidget(
    CurrentRole(
      notifier: RoleController(role),
      child: MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildFamilyTheme(),
        home: WebFilterScreen(
          childId: childId,
          repository: repository,
          unlockService: unlockService,
          motherLevel: motherLevel,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Widget _l10nApp({required Widget home}) {
  return MaterialApp(
    locale: const Locale('ar'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    theme: buildFamilyTheme(),
    home: home,
  );
}
