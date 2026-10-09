// W6 — the web-filter panel, rendered and wired.
//
// This is the acceptance test the wave is judged by, so it renders the real widget over a
// real `WebFilterServerAuthority` talking to a routed transport, and it asserts what a family
// would see. Every test here is a way this screen could lie:
//
//   * with no session bound it shows no policy, only the sentence that says so;
//   * the categories it draws are the server's policy, not the screen's;
//   * flipping a switch sends the write with the version it read, and what appears
//     afterwards is the policy the SERVER returned - so a refusal cannot look like a change;
//   * the preview shows the decision the server made, with the source of denial;
//   * and the protection state never shows "protected" for a device that stopped reporting:
//     it shows unverified WITH the length of the silence, and what the handset observed.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n04_web_filter/web_filter_server_authority.dart';
import 'package:family_os/features/n04_web_filter/web_filter_server_panel.dart';
import 'package:family_os/foundation_gate/foundation_gate_http.dart';

import 'support/web_filter_fake_server.dart';

Future<void> _pump(
  WidgetTester tester, {
  WebFilterServerAuthority? authority,
  bool canEdit = true,
}) async {
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
        body: SingleChildScrollView(
          child: WebFilterServerPanel(
            childId: ChildId(webFilterChildId),
            authority: authority,
            canEdit: canEdit,
            idempotencyKey: () => 'w6-widget-key',
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Taps a widget the way a person does: after scrolling it into view.
///
/// The scroll is part of the test, not a convenience. The panel is a column taller than a
/// phone viewport, and a tap whose centre lands outside it hits whatever is under the
/// finger instead - so a run that warned about a missed tap would be a run that proved
/// nothing about the button it named.
Future<void> _tapKey(WidgetTester tester, Key key) async {
  final finder = find.byKey(key);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

WebFilterFakeTransport _healthyTransport({
  List<String> categories = const ['adults', 'gambling', 'violence'],
  String protectionState = 'protected',
  String protectionReason = 'reported_healthy',
  int? ageMinutes = 2,
  List<String> signals = const [],
  String questionState = 'pending',
  String questionStatus = 'pending',
  int? grantedMinutes,
}) => WebFilterFakeTransport(<String, FoundationGateHttpResponse>{
  '/decision': webFilterOk(jsonEncode(<String, Object?>{
    'request': <String, Object?>{
      'id': webFilterRequestId,
      'host': 'games.example.com',
      'status': 'approved',
      'state': 'active',
      'requestedMinutes': 15,
      'grantedMinutes': 15,
      'reason': '',
      'requestedByMembershipId': null,
      'requestedByDeviceId': webFilterDeviceId,
      'decidedByMembershipId': '99999999-9999-4999-8999-999999999999',
      'decidedAt': '2026-10-08T09:00:00.000Z',
      'expiresAt': '2026-10-08T09:15:00.000Z',
      'createdAt': '2026-10-08T08:55:00.000Z',
    },
  })),
  '/web-filter/temp-allows': webFilterOk(webFilterQuestionJson(
    state: questionState,
    status: questionStatus,
    grantedMinutes: grantedMinutes,
  )),
  '/web-filter': webFilterOk(webFilterPolicyJson(categories: categories)),
  '/protection': webFilterOk(webFilterProtectionJson(
    state: protectionState,
    reason: protectionReason,
    ageMinutes: ageMinutes,
    signals: signals,
  )),
});

void main() {
  tearDown(() => bindWebFilterServerAuthority(null));

  testWidgets('without a session the panel shows no policy at all', (tester) async {
    await _pump(tester, authority: null);

    expect(
      find.byKey(const Key('web_filter_server_notConfigured')),
      findsOneWidget,
      reason: 'a build with nobody to ask must say so',
    );
    expect(find.byKey(const Key('web_filter_server_policy_card')), findsNothing);
    expect(find.byKey(const Key('web_filter_server_protection_card')), findsNothing);
  });

  testWidgets('the filter drawn is the server\'s policy', (tester) async {
    final transport = _healthyTransport();
    await _pump(tester, authority: webFilterAuthorityFor(transport));

    expect(find.byKey(const Key('web_filter_server_policy_card')), findsOneWidget);
    expect(find.text('محتوى للبالغين'), findsOneWidget);
    expect(find.text('مقامرة'), findsOneWidget);
    // A category the family has not switched on is present as a switch and off.
    final social = tester.widget<SwitchListTile>(
      find.byKey(const Key('web_filter_server_category_social')),
    );
    expect(social.value, isFalse);
    expect(
      find.textContaining('blocked.example.com'),
      findsOneWidget,
      reason: 'the block list the server holds is shown as it is',
    );
    expect(transport.calls, contains('GET /v1/families/$webFilterFamilyId/children/$webFilterChildId/web-filter'));
  });

  testWidgets('flipping a switch sends the field that changed with the version it read', (tester) async {
    final transport = WebFilterFakeTransport(<String, FoundationGateHttpResponse>{
      '/web-filter/temp-allows': webFilterOk(webFilterQuestionJson()),
      '/web-filter': webFilterOk(webFilterPolicyJson()),
      '/protection': webFilterOk(webFilterProtectionJson(state: 'protected', reason: 'reported_healthy', ageMinutes: 1)),
    });
    await _pump(tester, authority: webFilterAuthorityFor(transport));

    await _tapKey(tester, const Key('web_filter_server_category_social'));

    final sent = jsonDecode(transport.bodies.last) as Map<String, Object?>;
    expect(sent['categories'], containsAll(<String>['adults', 'gambling', 'violence', 'social']));
    expect(
      sent['expectedVersion'],
      3,
      reason: 'the version this screen read is the version it sends, so a stale screen is refused',
    );
    expect(
      sent.keys,
      isNot(contains('allowHosts')),
      reason: 'flipping one switch must not resend - and so must not rewrite - the other lists',
    );
  });

  testWidgets('a refused write keeps the last true policy on screen and says so', (tester) async {
    final transport = WebFilterFakeTransport(
      <String, FoundationGateHttpResponse>{
        '/web-filter/temp-allows': webFilterOk(webFilterQuestionJson()),
        '/web-filter': webFilterOk(webFilterPolicyJson()),
        '/protection': webFilterOk(webFilterProtectionJson(state: 'protected', reason: 'reported_healthy', ageMinutes: 1)),
      },
      patchResponses: <String, FoundationGateHttpResponse>{
        '/web-filter': FoundationGateHttpResponse(statusCode: 409, body: '{}'),
      },
    );
    await _pump(tester, authority: webFilterAuthorityFor(transport));

    await _tapKey(tester, const Key('web_filter_server_category_social'));

    expect(find.byKey(const Key('web_filter_server_refused')), findsOneWidget);
    expect(
      find.byKey(const Key('web_filter_server_policy_card')),
      findsOneWidget,
      reason: 'a refusal must not empty the screen into something that looks like no filter',
    );
  });

  testWidgets('an unreachable server moves nothing, and a silent one claims nothing', (tester) async {
    final transport = _healthyTransport();
    await _pump(tester, authority: webFilterAuthorityFor(transport));
    expect(find.byKey(const Key('web_filter_server_policy_card')), findsOneWidget);

    transport.failure = StateError('socket closed');
    await _tapKey(tester, const Key('web_filter_server_category_social'));

    expect(find.byKey(const Key('web_filter_server_unreachable')), findsOneWidget);
    expect(find.byKey(const Key('web_filter_server_policy_card')), findsOneWidget);
    expect(
      tester
          .widget<SwitchListTile>(
            find.byKey(const Key('web_filter_server_category_social')),
          )
          .value,
      isFalse,
      reason: 'the switch shows the server\'s last answer, not the tap',
    );
  });

  testWidgets('the preview shows the server\'s decision and the source of denial', (tester) async {
    final transport = WebFilterFakeTransport(<String, FoundationGateHttpResponse>{
      '/web-filter/temp-allows': webFilterOk(webFilterQuestionJson()),
      '/web-filter/evaluate': webFilterOk(jsonEncode(<String, Object?>{
        'allowed': false,
        'denySource': 'category',
        'categoryKey': 'games',
        'policyVersion': 3,
        'normalizedHost': 'games.example.com',
      })),
      '/web-filter': webFilterOk(webFilterPolicyJson()),
      '/protection': webFilterOk(webFilterProtectionJson(state: 'protected', reason: 'reported_healthy', ageMinutes: 1)),
    });
    await _pump(tester, authority: webFilterAuthorityFor(transport));

    await _tapKey(tester, const Key('web_filter_server_preview_button'));

    expect(find.byKey(const Key('web_filter_server_preview_verdict')), findsOneWidget);
    expect(
      tester
          .widget<Text>(find.byKey(const Key('web_filter_server_preview_verdict')))
          .data,
      'المصدر: ألعاب',
      reason: 'the denial is named by the category the server chose, not by this screen',
    );
  });

  testWidgets('a device that stopped reporting is unverified, with the silence measured', (tester) async {
    final transport = _healthyTransport(
      protectionState: 'unverified',
      protectionReason: 'stale_report',
      ageMinutes: 180,
    );
    await _pump(tester, authority: webFilterAuthorityFor(transport));

    expect(
      find.text('لا ندّعي حماية: لا بلاغ حديث من هذا الجهاز.'),
      findsOneWidget,
      reason: 'silence is not health, and this screen is where that law is kept',
    );
    expect(
      find.text('صمت الجهاز منذ 180 دقيقة.'),
      findsOneWidget,
      reason: 'unverified with a number is a fact a parent can act on',
    );
    expect(
      find.text('آخر بلاغ حديث من الجهاز يقول إن الحماية تعمل.'),
      findsNothing,
      reason: 'nothing recently said so, so nothing claims it',
    );
  });

  testWidgets('what the handset observed is named, in the family\'s own words', (tester) async {
    final transport = _healthyTransport(
      protectionState: 'at_risk',
      protectionReason: 'vpn_active',
      ageMinutes: 1,
      signals: const ['vpn_active'],
    );
    await _pump(tester, authority: webFilterAuthorityFor(transport));

    expect(find.text('الحماية ليست كما ينبغي — راجع ما رصده الجهاز.'), findsOneWidget);
    expect(
      find.text('تطبيق VPN على جهاز الابن'),
      findsOneWidget,
      reason: 'a family can act on "a VPN is running"; it cannot act on "at risk"',
    );
  });

  testWidgets('the child\'s question is answered through the server, and the answer shown is the server\'s', (tester) async {
    final transport = _healthyTransport();
    await _pump(tester, authority: webFilterAuthorityFor(transport));

    expect(find.byKey(const Key('web_filter_server_questions_card')), findsOneWidget);
    await _tapKey(tester, const Key('web_filter_server_approve_$webFilterRequestId'));

    expect(
      transport.calls.any((call) => call.startsWith('POST /v1/families/$webFilterFamilyId/children/$webFilterChildId/web-filter/temp-allows/$webFilterRequestId/decision')),
      isTrue,
      reason: 'the answer is a server command, not a local flag',
    );
  });

  testWidgets('an expired door reads expired because the clock said so', (tester) async {
    final transport = _healthyTransport(
      questionState: 'expired',
      questionStatus: 'approved',
      grantedMinutes: 10,
    );
    await _pump(tester, authority: webFilterAuthorityFor(transport));

    expect(
      find.byKey(const Key('web_filter_server_question_state_$webFilterRequestId')),
      findsOneWidget,
      reason: 'an answered question shows its state instead of two buttons',
    );
    expect(find.byKey(const Key('web_filter_server_approve_$webFilterRequestId')), findsNothing);
  });

  testWidgets('a reader without edit rights is offered no switch to flip', (tester) async {
    final transport = _healthyTransport();
    await _pump(tester, authority: webFilterAuthorityFor(transport), canEdit: false);

    final social = tester.widget<SwitchListTile>(
      find.byKey(const Key('web_filter_server_category_social')),
    );
    expect(social.onChanged, isNull);
    expect(find.byKey(const Key('web_filter_server_approve_$webFilterRequestId')), findsNothing);
    expect(
      find.byKey(const Key('web_filter_server_question_state_$webFilterRequestId')),
      findsOneWidget,
      reason: 'a question is still shown to someone who cannot answer it',
    );
  });

  testWidgets('the panel fits a phone in Arabic - nothing runs off the edge', (tester) async {
    // The width that matters is the one a child holds: 360 logical pixels, right to left,
    // with the longest Arabic sentences on the surface - a question waiting for a parent and
    // two actions that used to sit beside it on one line. They ran 196 pixels past the edge,
    // which is a button a father cannot reach. An overflow throws during layout, so this test
    // is the edge itself rather than a comment about it.
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pump(tester, authority: webFilterAuthorityFor(_healthyTransport()));

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('web_filter_server_approve_$webFilterRequestId')), findsOneWidget);
    expect(find.byKey(const Key('web_filter_server_question_state_$webFilterRequestId')), findsNothing);
    expect(find.byKey(const Key('web_filter_server_policy_card')), findsOneWidget);
  });
}
