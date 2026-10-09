// W5 — the wiring itself, asserted where it can be seen: inside the screen a guardian opens.
//
// The panel has a file of its own for what it says; this one proves the other half of the
// wave's standard, which is that `ChildScreenTimeScreen` renders the server's state - not a
// local imitation of it - and that a build with no session shows the sentence and no numbers.
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
import 'package:family_os/features/n03_screen_time/child_screen_time_screen.dart';
import 'package:family_os/features/n03_screen_time/screen_time_server_authority.dart';
import 'package:family_os/foundation_gate/foundation_gate_http.dart';

import 'support/screen_time_fake_server.dart';

Future<void> _pump(WidgetTester tester, {AppRole role = AppRole.father}) async {
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
        // No local seams are injected, which is exactly the state a real build boots in: the
        // screen then draws the server's answer, and nothing else.
        home: ChildScreenTimeScreen(childId: ChildId(screenTimeChildId)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  tearDown(() => bindScreenTimeServerAuthority(null));

  testWidgets('a bound session puts the server state on the screen the guardian opens', (tester) async {
    final transport = ScreenTimeFakeTransport({
      '/screen-time': FoundationGateHttpResponse(
        statusCode: 200,
        body: screenTimeSnapshotJson(kind: 'blocked', reason: 'daily_limit'),
      ),
    });
    bindScreenTimeServerAuthority(screenTimeAuthorityFor(transport));
    await _pump(tester);

    expect(
      find.byKey(const Key('screen_time_server_panel')),
      findsOneWidget,
      reason: 'the wave is only delivered when the surface a family opens carries it',
    );
    expect(
      find.text('انتهى وقت اليوم'),
      findsOneWidget,
      reason: 'and the sentence on it is the state the server returned, not a local one',
    );
    expect(
      transport.calls,
      contains(
        'GET /v1/families/$screenTimeFamilyId/children/$screenTimeChildId/screen-time',
      ),
      reason: 'the screen asked the server, because this build had a session to ask with',
    );
  });

  testWidgets('a build with no session shows the sentence and no numbers at all', (tester) async {
    await _pump(tester);

    expect(find.byKey(const Key('screen_time_server_panel')), findsOneWidget);
    expect(
      find.byKey(const Key('screen_time_server_no_session')),
      findsOneWidget,
      reason: 'a build with nobody to ask says so instead of drawing minutes it cannot enforce',
    );
    expect(find.byKey(const Key('screen_time_server_state_card')), findsNothing);
  });
}
