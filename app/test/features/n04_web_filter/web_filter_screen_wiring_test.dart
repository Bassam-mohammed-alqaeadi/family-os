// W6 — the wiring itself, asserted where it can be seen: inside the filter screen.
//
// The panel has a file of its own for what it says; this one proves the other half of the
// wave's standard, which is that `WebFilterScreen` renders the server's policy and the honest
// protection state when a session is bound - and that a build with no session offers no panel
// at all, instead of drawing a green shield nobody checked.
//
// It is deliberately small. A wiring test that re-tested the panel would be a second copy of
// the panel's own tests, and the copy is the one that goes stale.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/web_filter_policy_repository.dart';
import 'package:family_os/features/n04_web_filter/web_filter_screen.dart';
import 'package:family_os/features/n04_web_filter/web_filter_server_authority.dart';

import 'support/web_filter_fake_server.dart';

Future<void> _pump(
  WidgetTester tester, {
  AppRole role = AppRole.father,
  WebFilterPolicyRepository? repository,
}) async {
  final roleCtrl = RoleController(role);
  addTearDown(roleCtrl.dispose);
  await tester.pumpWidget(
    CurrentRole(
      notifier: roleCtrl,
      child: MaterialApp(
        theme: buildFamilyTheme(),
        locale: const Locale('ar'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        // The child is named explicitly, the way the screen is opened from a child's page: the
        // server row is addressed by that name and by nothing this build guesses.
        home: WebFilterScreen(
          childId: ChildId(webFilterChildId),
          repository: repository,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  tearDown(() => bindWebFilterServerAuthority(null));

  testWidgets('a bound session puts the server policy on the screen the guardian opens', (tester) async {
    final transport = WebFilterFakeTransport({
      '/web-filter/temp-allows': webFilterOk(webFilterQuestionJson()),
      '/web-filter/protection': webFilterOk(webFilterProtectionJson(state: 'at_risk', reason: 'no_reports')),
      '/web-filter': webFilterOk(webFilterPolicyJson()),
    });
    bindWebFilterServerAuthority(webFilterAuthorityFor(transport));
    await _pump(
      tester,
      repository: InMemoryWebFilterPolicyRepository(),
    );

    expect(
      find.byKey(const Key('web_filter_server_panel')),
      findsOneWidget,
      reason: 'the wave is only delivered when the surface a family opens carries it',
    );
    expect(
      find.byKey(const Key('web_filter_server_protection_card')),
      findsOneWidget,
      reason: 'and the protection line on it is the server\'s, not a green dot this build drew',
    );
    expect(
      transport.calls,
      contains(
        'GET /v1/families/$webFilterFamilyId/children/$webFilterChildId/web-filter',
      ),
      reason: 'the screen asked the server, because this build had a session to ask with',
    );
  });

  testWidgets('a build with no session shows no server policy at all', (tester) async {
    await _pump(
      tester,
      repository: InMemoryWebFilterPolicyRepository(),
    );

    expect(
      find.byKey(const Key('web_filter_server_panel')),
      findsNothing,
      reason: 'a policy nobody stated on the server is not drawn as if the server said it',
    );
    expect(
      find.byKey(const Key('web_filter_server_protection_card')),
      findsNothing,
    );
  });
}
