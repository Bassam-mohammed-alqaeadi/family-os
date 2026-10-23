// S3 polish — the live controls on the guardian's screen-time panel.
//
// Three promises are tested here, and each one is a way a dashboard can lie:
//   * a quick grant writes a real, expiring gift and then re-reads, so the number under it
//     is the server's new number and not the old one plus a guess;
//   * a cap outside what a day can hold says so, instead of silently doing nothing;
//   * a banner that reports a dead server carries the one thing a parent can do about it.
import 'dart:convert';

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

  testWidgets('a quick grant writes an expiring gift and then re-reads',
      (tester) async {
    final transport = ScreenTimeFakeTransport({
      '/grants': FoundationGateHttpResponse(
        statusCode: 201,
        body: jsonEncode(<String, Object?>{
          'entry': <String, Object?>{'minutes': 15},
          'balance': <String, Object?>{},
        }),
      ),
      '/screen-time': FoundationGateHttpResponse(
        statusCode: 200,
        body: screenTimeSnapshotJson(),
      ),
    });
    await _pump(tester, transport);
    final readsBefore = transport.calls
        .where((call) => call.endsWith('/screen-time'))
        .length;

    final grant = find.byKey(const Key('screen_time_server_grant_15'));
    await tester.ensureVisible(grant);
    await tester.pumpAndSettle();
    await tester.tap(grant);
    await tester.pumpAndSettle();

    final body = jsonDecode(
      transport.bodies.single,
    ) as Map<String, Object?>;
    expect(body['minutes'], 15);
    expect(
      body['scope'],
      'temporary',
      reason: 'a gift to a wallet that expires is the only kind today can hold',
    );
    expect(
      body['expiresAt'],
      isA<String>(),
      reason: 'without an expiry the server would count it forever',
    );
    expect(
      transport.calls.where((call) => call.endsWith('/screen-time')).length,
      greaterThan(readsBefore),
      reason: 'the number under the button must be the server\'s new number',
    );
    expect(
      find.byKey(const Key('screen_time_server_grant_done')),
      findsOneWidget,
    );
  });

  testWidgets('a cap outside the range is refused out loud', (tester) async {
    final transport = ScreenTimeFakeTransport({
      '/screen-time': FoundationGateHttpResponse(
        statusCode: 200,
        body: screenTimeSnapshotJson(),
      ),
    });
    await _pump(tester, transport);
    final writesBefore = transport.bodies.length;

    await tester.enterText(
      find.byKey(const Key('screen_time_server_cap_field')),
      '5000',
    );
    await tester.tap(find.byKey(const Key('screen_time_server_cap_save')));
    await tester.pumpAndSettle();

    expect(find.text('الحد اليومي بين ٠ و١٤٤٠ دقيقة.'), findsOneWidget);
    expect(
      transport.bodies.length,
      writesBefore,
      reason: 'a number a day cannot hold is never sent',
    );
  });

  testWidgets('a dead server offers the one thing a parent can do', (tester) async {
    final transport = ScreenTimeFakeTransport({})
      ..failure = StateError('socket closed');
    await _pump(tester, transport);

    expect(find.byKey(const Key('screen_time_server_unreachable')), findsOneWidget);
    final retry = find.byKey(const Key('screen_time_server_retry'));
    expect(retry, findsOneWidget);

    transport.failure = null;
    transport.responses['/screen-time'] = FoundationGateHttpResponse(
      statusCode: 200,
      body: screenTimeSnapshotJson(),
    );
    await tester.tap(retry);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('screen_time_server_state_card')),
      findsOneWidget,
      reason: 'trying again must be able to end in an answer',
    );
  });
}
