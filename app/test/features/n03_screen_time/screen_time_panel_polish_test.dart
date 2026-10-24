// SCR-FAT-032 · the polish wave's own acceptance test for the guardian panel.
//
// `screen_time_server_panel_test.dart` already pins the panel's constitution — no numbers
// without a server answer, the last true answer survives a silence, a viewer writes nothing.
// This file pins what the polish added, and the first thing it pins is the thing the polish
// could most easily have broken: **the panel still opens with exactly one read.** An insights
// card that fetched its own graph, or a week card that fetched the app list "just in case",
// would double the panel's cost on every parent's phone and quietly change what "the server
// said" means.
//
// Everything else here is a promise the UI makes about a contract:
//   * the week editor is a draft, and one save writes the school-day set once;
//   * a weekend bedtime appears the moment the extension route carries it, and while it does
//     not, the card says so in the same sentence the panel uses everywhere;
//   * the custom extension validates before it writes, so a typo never becomes a grant;
//   * app rules are read when the parent opens the sheet, never before.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n03_screen_time/screen_time_panel_contracts.dart';
import 'package:family_os/features/n03_screen_time/screen_time_server_authority.dart';
import 'package:family_os/features/n03_screen_time/screen_time_server_panel.dart';
import 'package:family_os/foundation_gate/foundation_gate_http.dart';

import 'support/screen_time_fake_server.dart';

final class _FakeExtensionSource implements ScreenTimePolicyExtensionSource {
  _FakeExtensionSource(this.answer);

  ScreenTimeExtensionAnswer answer;
  final List<Map<String, Object?>> writes = <Map<String, Object?>>[];
  int reads = 0;

  @override
  Future<ScreenTimeExtensionAnswer> read(String childId) async {
    reads++;
    return answer;
  }

  @override
  Future<ScreenTimeExtensionAnswer> write(
    String childId, {
    required ScreenTimePolicyExtension policyExtension,
    required String Function() idempotencyKey,
  }) async {
    writes.add(policyExtension.toJson());
    return answer;
  }
}

Future<void> _pump(
  WidgetTester tester, {
  ScreenTimeServerAuthority? authority,
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
        body: ScreenTimeServerPanel(
          childId: ChildId(screenTimeChildId),
          authority: authority,
          canEdit: canEdit,
          idempotencyKey: () => 'polish-widget-key',
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

String _appsJson({int usedMinutes = 30}) => jsonEncode(<String, Object?>{
  'apps': <Object?>[
    <String, Object?>{
      'appId': 'com.example.puzzle',
      'displayName': 'Puzzle',
      'category': 'games',
      'ageRating': '7+',
      'knownOnDevice': true,
      'countable': true,
      'usedMinutes': usedMinutes,
      'remainingMinutes': null,
      'rule': null,
      'decision': <String, Object?>{'allowed': true, 'reasonCode': null},
    },
  ],
});

const _ruleJson =
    '{"rule":{"status":"blocked","limitMinutes":null,"unlimited":false,'
    '"version":2,"updatedAt":"2026-10-07T12:00:00.000Z"}}';

void main() {
  tearDown(() {
    bindScreenTimeServerAuthority(null);
    bindScreenTimePolicyExtension(null);
  });

  group('one read draws the whole panel', () {
    testWidgets('the cards are drawn from the snapshot and nothing else', (tester) async {
      final transport = ScreenTimeFakeTransport({
        '/screen-time': FoundationGateHttpResponse(
          statusCode: 200,
          body: screenTimeSnapshotJson(
            kind: 'limited',
            reason: null,
            usedMinutes: 30,
            remaining: 30,
            cap: 60,
          ),
        ),
      });
      await _pump(tester, authority: screenTimeAuthorityFor(transport));

      expect(
        transport.calls,
        <String>[
          'GET /v1/families/$screenTimeFamilyId/children/$screenTimeChildId/screen-time',
        ],
        reason: 'an insights card or a week card that fetched on its own would double the panel',
      );
      for (final key in const [
        'screen_time_server_lock_card',
        'screen_time_server_quick_grant_card',
        'screen_time_server_insights_card',
        'screen_time_server_week_card',
        'screen_time_server_apps_card',
        'screen_time_server_earned_minutes_card',
        'screen_time_server_policy_card',
      ]) {
        expect(find.byKey(Key(key)), findsOneWidget, reason: key);
      }
      expect(find.text('تحليل استهلاك اليوم'), findsOneWidget);
      expect(find.text('المستهلك'), findsOneWidget);
      expect(find.text('حد اليوم'), findsOneWidget);
      // The per-app bar reads the app the way the server named it — this panel has no second
      // source of names to prefer.
      expect(find.textContaining('com.example.puzzle'), findsOneWidget);
      expect(find.text('30 د'), findsAtLeastNWidgets(1));
      expect(find.text('منح إضافية'), findsNothing, reason: 'the server granted nothing today');
    });

    testWidgets('a day with no usage is stated as such, not drawn as zeroes', (tester) async {
      final transport = ScreenTimeFakeTransport({
        '/screen-time': FoundationGateHttpResponse(
          statusCode: 200,
          body: screenTimeSnapshotJson(
            kind: 'limited',
            reason: null,
            usedMinutes: 0,
            remaining: 60,
            cap: 60,
          ),
        ),
      });
      await _pump(tester, authority: screenTimeAuthorityFor(transport));

      expect(find.text('لا استهلاك مسجلاً اليوم'), findsOneWidget);
      expect(find.byKey(const Key('screen_time_server_insights_empty')), findsOneWidget);
      expect(find.textContaining('%'), findsNothing);
    });

    testWidgets('minutes past the cap are said out loud', (tester) async {
      final transport = ScreenTimeFakeTransport({
        '/screen-time': FoundationGateHttpResponse(
          statusCode: 200,
          body: screenTimeSnapshotJson(
            kind: 'blocked',
            reason: 'daily_limit',
            usedMinutes: 90,
            remaining: 0,
            cap: 60,
          ),
        ),
      });
      await _pump(tester, authority: screenTimeAuthorityFor(transport));

      expect(find.text('تجاوز الاستهلاك حد اليوم'), findsOneWidget);
      expect(find.textContaining('%'), findsOneWidget);
    });
  });

  group('the week', () {
    testWidgets('the day chips are a draft and one save writes the set once', (tester) async {
      final transport = ScreenTimeFakeTransport({
        '/screen-time': FoundationGateHttpResponse(
          statusCode: 200,
          body: screenTimeSnapshotJson(kind: 'limited', reason: null),
        ),
      });
      await _pump(tester, authority: screenTimeAuthorityFor(transport));

      final save = find.byKey(const Key('screen_time_server_week_save'));
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      expect(
        tester.widget<PrimaryBtn>(save).onPressed,
        isNull,
        reason: 'nothing was changed, so nothing is offered to save',
      );

      final friday = find.byKey(const Key('screen_time_server_day_chip_5'));
      await tester.ensureVisible(friday);
      await tester.pumpAndSettle();
      expect(find.text('الجمعة'), findsOneWidget);
      await tester.tap(friday);
      await tester.pumpAndSettle();
      expect(
        tester.widget<PrimaryBtn>(save).onPressed,
        isNotNull,
        reason: 'the draft differs from the server, and the card says so by offering the save',
      );

      // Tapping six more chips must not write six times.
      expect(transport.calls.where((call) => call.startsWith('PATCH')), isEmpty);

      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.pumpAndSettle();

      final patches = transport.calls
          .where((call) => call.startsWith('PATCH'))
          .toList(growable: false);
      expect(patches, hasLength(1));
      final body = jsonDecode(
        transport.bodies.firstWhere((raw) => raw.contains('schoolMode')),
      ) as Map<String, Object?>;
      expect(body['schoolMode'], <String, Object?>{
        'days': <int>[1, 2, 3, 4, 5, 7],
      });
      expect(body['expectedVersion'], 4, reason: 'a stale screen cannot overwrite a newer one');
    });

    testWidgets('a weekend window appears when the contract carries one', (tester) async {
      final source = _FakeExtensionSource(
        ScreenTimeExtensionAnswer.ready(
          const ScreenTimePolicyExtension(
            bedtimeWindows: {
              ScreenTimeWeekPart.weekend: ScreenTimeBedtimeWindow(
                weekPart: ScreenTimeWeekPart.weekend,
                startMinute: 1320,
                endMinute: 420,
              ),
            },
          ),
        ),
      );
      bindScreenTimePolicyExtension(source);
      final transport = ScreenTimeFakeTransport({
        '/screen-time': FoundationGateHttpResponse(
          statusCode: 200,
          body: screenTimeSnapshotJson(kind: 'limited', reason: null),
        ),
      });
      await _pump(tester, authority: screenTimeAuthorityFor(transport));

      expect(find.text('22:00 – 07:00'), findsOneWidget);
      expect(find.textContaining('عقد الخادم'), findsNothing);
      expect(source.reads, 1, reason: 'the extension is read once per panel, not once per card');
    });

    testWidgets('without the route it says what is missing instead of faking a save', (tester) async {
      final transport = ScreenTimeFakeTransport({
        '/screen-time': FoundationGateHttpResponse(
          statusCode: 200,
          body: screenTimeSnapshotJson(kind: 'limited', reason: null),
        ),
      });
      await _pump(tester, authority: screenTimeAuthorityFor(transport));

      expect(
        find.text('نافذة نوم منفصلة للعطلة تحتاج امتداداً في عقد الخادم'),
        findsOneWidget,
      );
      expect(transport.calls, hasLength(1), reason: 'an unbound contract costs no requests');
    });
  });

  group('extra minutes', () {
    testWidgets('a custom number is checked before it is sent', (tester) async {
      final transport = ScreenTimeFakeTransport({
        '/minutes/grants': const FoundationGateHttpResponse(
          statusCode: 201,
          body: '{"grant":{"minutes":23,"channel":"guardian_grant"}}',
        ),
        '/screen-time': FoundationGateHttpResponse(
          statusCode: 200,
          body: screenTimeSnapshotJson(kind: 'limited', reason: null),
        ),
      });
      await _pump(tester, authority: screenTimeAuthorityFor(transport));

      final custom = find.byKey(const Key('screen_time_server_custom_grant'));
      await tester.ensureVisible(custom);
      await tester.pumpAndSettle();
      await tester.tap(custom);
      await tester.pumpAndSettle();

      final field = find.byKey(const Key('screen_time_server_custom_grant_field'));
      final confirm = find.byKey(
        const Key('screen_time_server_custom_grant_confirm'),
      );
      expect(field, findsOneWidget);
      await tester.enterText(field, '999');
      await tester.ensureVisible(confirm);
      await tester.tap(confirm);
      await tester.pumpAndSettle();

      expect(find.text('أدخل عدد دقائق بين 1 و 240'), findsOneWidget);
      expect(
        transport.calls.any((call) => call.contains('minutes/grants')),
        isFalse,
        reason: 'an invalid number never reaches the server',
      );

      await tester.enterText(field, '23');
      await tester.ensureVisible(confirm);
      await tester.tap(confirm);
      await tester.pumpAndSettle();

      expect(field, findsNothing);
      expect(
        transport.calls.any(
          (call) =>
              call ==
              'POST /v1/families/$screenTimeFamilyId/children/$screenTimeChildId/minutes/grants',
        ),
        isTrue,
      );
      final body = jsonDecode(
        transport.bodies.firstWhere((raw) => raw.contains('guardian_instant_grant')),
      ) as Map<String, Object?>;
      expect(body['minutes'], 23);
    });

    testWidgets('a pending question is answered instead of a second grant', (tester) async {
      final transport = ScreenTimeFakeTransport({
        '/decision': FoundationGateHttpResponse(
          statusCode: 200,
          body: jsonEncode(<String, Object?>{
            'request': jsonDecode(screenTimeRequestJson()),
          }),
        ),
        '/minutes/grants': const FoundationGateHttpResponse(
          statusCode: 201,
          body: '{"grant":{"minutes":15,"channel":"guardian_grant"}}',
        ),
        '/screen-time': FoundationGateHttpResponse(
          statusCode: 200,
          body: screenTimeSnapshotJson(openRequest: screenTimeRequestJson()),
        ),
      });
      await _pump(tester, authority: screenTimeAuthorityFor(transport));

      expect(
        find.byKey(const Key('screen_time_server_request_card')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('screen_time_server_quick_grant_card')),
        findsNothing,
        reason: 'one ask, one answer — not two ways to grant the same minutes',
      );
    });
  });

  group('app rules', () {
    testWidgets('the list is read when the parent opens it, and a decision writes once', (
      tester,
    ) async {
      final transport = ScreenTimeFakeTransport({
        '/rule': const FoundationGateHttpResponse(
          statusCode: 200,
          body: _ruleJson,
        ),
        '/apps': FoundationGateHttpResponse(
          statusCode: 200,
          body: _appsJson(),
        ),
        '/screen-time': FoundationGateHttpResponse(
          statusCode: 200,
          body: screenTimeSnapshotJson(kind: 'limited', reason: null),
        ),
      });
      await _pump(tester, authority: screenTimeAuthorityFor(transport));

      expect(
        transport.calls.any((call) => call.contains('/apps')),
        isFalse,
        reason: 'the panel does not fetch a list nobody asked to see',
      );

      final open = find.byKey(const Key('screen_time_server_apps_open'));
      await tester.ensureVisible(open);
      await tester.pumpAndSettle();
      await tester.tap(open);
      await tester.pumpAndSettle();

      expect(
        transport.calls,
        contains(
          'GET /v1/families/$screenTimeFamilyId/children/$screenTimeChildId/apps',
        ),
      );
      expect(find.text('Puzzle'), findsOneWidget);
      expect(
        find.text('ألعاب'),
        findsWidgets,
        reason: 'the category the app reports',
      );

      final expand = find.byKey(
        const Key('screen_time_server_app_expand_com.example.puzzle'),
      );
      await tester.ensureVisible(expand);
      await tester.pumpAndSettle();
      await tester.tap(expand);
      await tester.pumpAndSettle();

      final block = find.byKey(
        const Key('screen_time_server_app_block_com.example.puzzle'),
      );
      await tester.ensureVisible(block);
      await tester.pumpAndSettle();
      await tester.tap(block);
      await tester.pumpAndSettle();

      expect(
        transport.calls,
        contains(
          'PUT /v1/families/$screenTimeFamilyId/children/$screenTimeChildId'
          '/apps/com.example.puzzle/rule',
        ),
      );
      expect(
        jsonDecode(transport.bodies.last) as Map<String, Object?>,
        <String, Object?>{'status': 'blocked'},
      );
    });

    testWidgets('a category action says how many rules it wrote', (tester) async {
      final transport = ScreenTimeFakeTransport({
        '/rule': const FoundationGateHttpResponse(
          statusCode: 200,
          body: _ruleJson,
        ),
        '/apps': FoundationGateHttpResponse(
          statusCode: 200,
          body: _appsJson(),
        ),
        '/screen-time': FoundationGateHttpResponse(
          statusCode: 200,
          body: screenTimeSnapshotJson(kind: 'limited', reason: null),
        ),
      });
      await _pump(tester, authority: screenTimeAuthorityFor(transport));

      final open = find.byKey(const Key('screen_time_server_apps_open'));
      await tester.ensureVisible(open);
      await tester.pumpAndSettle();
      await tester.tap(open);
      await tester.pumpAndSettle();

      final blockCategory = find.byKey(
        const Key('screen_time_server_category_block_games'),
      );
      await tester.ensureVisible(blockCategory);
      await tester.pumpAndSettle();
      await tester.tap(blockCategory);
      await tester.pumpAndSettle();

      expect(find.text('طبق على 1 تطبيق'), findsOneWidget);
      expect(
        transport.calls.where((call) => call.startsWith('PUT')).length,
        1,
        reason: 'one app in the category means one write, not a write per label',
      );
    });
  });

  group('a viewer', () {
    testWidgets('sees every number and can write none of them', (tester) async {
      final transport = ScreenTimeFakeTransport({
        '/screen-time': FoundationGateHttpResponse(
          statusCode: 200,
          body: screenTimeSnapshotJson(kind: 'limited', reason: null),
        ),
      });
      await _pump(tester, authority: screenTimeAuthorityFor(transport), canEdit: false);

      expect(
        tester
            .widget<PrimaryBtn>(
              find.byKey(const Key('screen_time_server_apps_open')),
            )
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<OutlinedButton>(
              find.byKey(const Key('screen_time_server_custom_grant')),
            )
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<TextButton>(
              find.byKey(const Key('screen_time_server_bedtime_start')),
            )
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<SwitchListTile>(
              find.byKey(const Key('screen_time_server_earned_minutes_toggle')),
            )
            .onChanged,
        isNull,
      );
      expect(find.text('تحليل استهلاك اليوم'), findsOneWidget);
    });
  });

  group('the contract layer', () {
    test('the extension reads and writes the fields the base policy has no room for', () {
      final extension = ScreenTimePolicyExtension.fromJson(<String, Object?>{
        'bedtimeWindows': <Object?>[
          <String, Object?>{
            'weekPart': 'weekend',
            'startMinute': 1320,
            'endMinute': 420,
          },
        ],
        'dailyMinutesByCategory': <Object?>[
          <String, Object?>{
            'category': 'games',
            'minutes': 45,
            'enabled': true,
          },
        ],
      });
      expect(
        extension.bedtimeWindows[ScreenTimeWeekPart.weekend],
        const ScreenTimeBedtimeWindow(
          weekPart: ScreenTimeWeekPart.weekend,
          startMinute: 1320,
          endMinute: 420,
        ),
      );
      expect(extension.categoryBudgets[ScreenTimeAppCategory.games]!.minutes, 45);
      expect(extension.isEmpty, isFalse);

      final roundTripped = ScreenTimePolicyExtension.fromJson(
        extension.toJson(),
      );
      expect(roundTripped.bedtimeWindows, extension.bedtimeWindows);
      expect(roundTripped.categoryBudgets, extension.categoryBudgets);
      expect(ScreenTimePolicyExtension.none.isEmpty, isTrue);
    });

    test('a category the phone reports in its own words still lands in a bucket', () {
      expect(ScreenTimeAppCategory.fromWire('games'), ScreenTimeAppCategory.games);
      expect(
        ScreenTimeAppCategory.fromWire('YouTube'),
        ScreenTimeAppCategory.video,
      );
      expect(
        ScreenTimeAppCategory.fromWire('messaging'),
        ScreenTimeAppCategory.social,
      );
      expect(
        ScreenTimeAppCategory.fromWire('school'),
        ScreenTimeAppCategory.education,
      );
      expect(ScreenTimeAppCategory.fromWire('solitaire'), ScreenTimeAppCategory.other);
      expect(ScreenTimeAppCategory.fromWire(null), ScreenTimeAppCategory.other);
    });

    test('an unbound extension source answers honestly and does nothing else', () async {
      const source = UnconfiguredScreenTimePolicyExtensionSource();
      final read = await source.read(screenTimeChildId);
      expect(read.status, ScreenTimeExtensionStatus.notConfigured);
      expect(read.isReady, isFalse);
      expect(read.value, isNull);
      final written = await source.write(
        screenTimeChildId,
        policyExtension: ScreenTimePolicyExtension.none,
        idempotencyKey: () => 'k',
      );
      expect(written.status, ScreenTimeExtensionStatus.notConfigured);
      expect(
        screenTimePolicyExtensionSource,
        isA<UnconfiguredScreenTimePolicyExtensionSource>(),
      );
    });

    test('a refused write is not reported as a saved one', () {
      const answer = ScreenTimeExtensionAnswer.unavailable(
        ScreenTimeExtensionStatus.refused,
      );
      expect(answer.isReady, isFalse);
      expect(answer.status, ScreenTimeExtensionStatus.refused);
      const ready = ScreenTimeExtensionAnswer.ready(
        ScreenTimePolicyExtension.none,
      );
      expect(ready.isReady, isTrue);
    });
  });
}
