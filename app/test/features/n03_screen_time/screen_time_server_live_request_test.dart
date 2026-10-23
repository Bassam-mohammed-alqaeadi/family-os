// S3 — the question arrives while the parent is looking.
//
// The child's handset files a request on its own clock, which has nothing to do with when a
// parent opens this screen. Two behaviours make that work, and both are tested here: an open
// panel reads again on its own (and on coming back to the foreground), and a read that
// fails in the background does not dim a screen that is still telling the truth.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n03_screen_time/screen_time_server_authority.dart';
import 'package:family_os/features/n03_screen_time/screen_time_server_panel.dart';
import 'package:family_os/foundation_gate/foundation_gate_http.dart';

import 'support/screen_time_fake_server.dart';

const _requestCard = Key('screen_time_server_request_card');

Future<void> _pump(WidgetTester tester, ScreenTimeFakeTransport transport) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildFamilyTheme(),
      locale: const Locale('ar'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: ScreenTimeServerPanel(
          childId: ChildId(screenTimeChildId),
          authority: screenTimeAuthorityFor(transport),
          idempotencyKey: () => 'w5-live-key',
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  tearDown(() => bindScreenTimeServerAuthority(null));

  testWidgets('a question asked while the panel is open appears by itself',
      (tester) async {
    final transport = ScreenTimeFakeTransport({
      '/screen-time': FoundationGateHttpResponse(
        statusCode: 200,
        body: screenTimeSnapshotJson(),
      ),
    });
    await _pump(tester, transport);
    expect(find.byKey(_requestCard), findsNothing);

    // The child asks now, on their own handset.
    transport.responses['/screen-time'] = FoundationGateHttpResponse(
      statusCode: 200,
      body: screenTimeSnapshotJson(openRequest: screenTimeRequestJson()),
    );

    await tester.pump(const Duration(seconds: 21));
    await tester.pumpAndSettle();

    expect(
      find.byKey(_requestCard),
      findsOneWidget,
      reason: 'a parent who left the screen open must still be asked',
    );
    expect(find.text('سؤال من الابن بانتظارك: 20 دقيقة'), findsOneWidget);
  });

  testWidgets('the question is drawn above the numbers, not under them',
      (tester) async {
    final transport = ScreenTimeFakeTransport({
      '/screen-time': FoundationGateHttpResponse(
        statusCode: 200,
        body: screenTimeSnapshotJson(openRequest: screenTimeRequestJson()),
      ),
    });
    await _pump(tester, transport);

    final request = tester.getTopLeft(find.byKey(_requestCard)).dy;
    final state = tester.getTopLeft(
      find.byKey(const Key('screen_time_server_state_card')),
    ).dy;

    expect(
      request,
      lessThan(state),
      reason: 'the only thing that expires while nobody looks goes first',
    );
  });

  testWidgets('a silent background read leaves the last true answer alone',
      (tester) async {
    final transport = ScreenTimeFakeTransport({
      '/screen-time': FoundationGateHttpResponse(
        statusCode: 200,
        body: screenTimeSnapshotJson(reason: 'daily_limit', kind: 'blocked'),
      ),
    });
    await _pump(tester, transport);
    expect(find.text('انتهى وقت اليوم'), findsOneWidget);

    transport.failure = StateError('socket closed');
    await tester.pump(const Duration(seconds: 21));
    await tester.pumpAndSettle();

    expect(find.text('انتهى وقت اليوم'), findsOneWidget);
    expect(
      find.byKey(const Key('screen_time_server_unreachable')),
      findsNothing,
      reason: 'a poll that fails is not news a parent can act on',
    );
  });
}
