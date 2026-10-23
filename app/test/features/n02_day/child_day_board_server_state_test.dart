import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/policy_sync_bus.dart';
import 'package:family_os/core/policy/screen_time_policy.dart';
import 'package:family_os/features/n02_day/child_day_board_screen.dart';
import 'package:family_os/foundation_gate/child_screen_time_state_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_http.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';

final class _FakeChildScreenTimeTransport
    implements ChildScreenTimeStateTransport {
  _FakeChildScreenTimeTransport(this.response);

  FoundationGateHttpResponse response;
  bool shouldThrow = false;
  FoundationGateApiFailure failure = FoundationGateApiFailure.networkUnavailable;

  @override
  Future<FoundationGateHttpResponse> readState() async {
    if (shouldThrow) {
      throw FoundationGateApiException(failure);
    }
    return response;
  }
}

String _screenTimePayload({
  int? remainingMinutes = 60,
  int capMinutes = 120,
  int usedMinutes = 30,
  bool earnedMinutesExtendLimit = false,
  String kind = 'limited',
}) {
  return jsonEncode(<String, Object?>{
    'childId': '22222222-2222-4222-8222-222222222222',
    'date': '2026-10-23',
    'policy': <String, Object?>{
      'childId': '22222222-2222-4222-8222-222222222222',
      'configured': true,
      'dailyLimitMinutes': capMinutes,
      'earnedMinutesExtendLimit': earnedMinutesExtendLimit,
    },
    'state': <String, Object?>{
      'kind': kind,
      'reasonCode': null,
      'remainingMinutes': remainingMinutes,
      'capMinutes': capMinutes,
      'countableUsedMinutes': usedMinutes,
      'grantedMinutes': 0,
    },
  });
}

Widget _wrap(Widget home) {
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

void main() {
  tearDown(AppToast.dismiss);

  final testChildId = ChildId('child-1234');

  testWidgets(
    'the server answer is the number the child sees',
    (tester) async {
      final transport = _FakeChildScreenTimeTransport(
        FoundationGateHttpResponse(
          statusCode: 200,
          body: _screenTimePayload(remainingMinutes: 45),
        ),
      );
      final client = ChildScreenTimeStateClient(transport: transport);

      await tester.pumpWidget(
        _wrap(
          ChildDayBoardScreen(
            childId: testChildId,
            serverScreenTime: client,
            showModeNotices: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final remainingFinder = find.byKey(ChildDayBoardKeys.remainingMinutes);
      expect(remainingFinder, findsOneWidget);
      final textWidget = tester.widget<Text>(remainingFinder);
      expect(textWidget.data, 'متبقي 45 دقيقة');
    },
  );

  testWidgets(
    'no limit is said in words and never drawn as zero',
    (tester) async {
      final transport = _FakeChildScreenTimeTransport(
        FoundationGateHttpResponse(
          statusCode: 200,
          body: _screenTimePayload(remainingMinutes: null),
        ),
      );
      final client = ChildScreenTimeStateClient(transport: transport);

      await tester.pumpWidget(
        _wrap(
          ChildDayBoardScreen(
            childId: testChildId,
            serverScreenTime: client,
            showModeNotices: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final remainingFinder = find.byKey(ChildDayBoardKeys.remainingMinutes);
      expect(remainingFinder, findsOneWidget);
      final textWidget = tester.widget<Text>(remainingFinder);
      expect(textWidget.data, 'بلا حد يومي الآن');

      expect(find.text('0'), findsNothing);
      expect(find.text('0 دقيقة متبقية'), findsNothing);
      expect(find.byKey(ChildDayBoardKeys.warningBanner), findsNothing);
    },
  );

  testWidgets(
    'a failed refresh keeps the last answer and says it is the last one',
    (tester) async {
      final transport = _FakeChildScreenTimeTransport(
        FoundationGateHttpResponse(
          statusCode: 200,
          body: _screenTimePayload(remainingMinutes: 45),
        ),
      );
      final client = ChildScreenTimeStateClient(transport: transport);

      await tester.pumpWidget(
        _wrap(
          ChildDayBoardScreen(
            childId: testChildId,
            serverScreenTime: client,
            showModeNotices: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('متبقي 45 دقيقة'), findsOneWidget);
      expect(find.byKey(ChildDayBoardKeys.serverStale), findsNothing);

      transport.shouldThrow = true;
      final state = tester.state(find.byType(ChildDayBoardScreen));
      await (state as dynamic).loadServerState();
      await tester.pumpAndSettle();

      expect(find.text('متبقي 45 دقيقة'), findsOneWidget);
      expect(find.byKey(ChildDayBoardKeys.serverStale), findsOneWidget);
      expect(
        find.text('لم يستجب الخادم — ما تراه آخر جواب صحيح، ولم يتغيّر شيء.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'an unpaired handset behaves exactly as before and shows no error',
    (tester) async {
      final syncBus = PolicySyncBus();
      final transport = _FakeChildScreenTimeTransport(
        FoundationGateHttpResponse(statusCode: 401, body: ''),
      )
        ..shouldThrow = true
        ..failure = FoundationGateApiFailure.unauthenticated;
      final client = ChildScreenTimeStateClient(transport: transport);

      await tester.pumpWidget(
        _wrap(
          ChildDayBoardScreen(
            childId: testChildId,
            serverScreenTime: client,
            syncBus: syncBus,
            showModeNotices: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(ChildDayBoardKeys.serverStale), findsNothing);
      expect(find.byKey(ChildDayBoardKeys.remainingMinutes), findsNothing);

      syncBus.hydrate(
        testChildId,
        policy: ScreenTimePolicy(dailyCapMinutes: 60),
      );
      await tester.pumpWidget(
        _wrap(
          ChildDayBoardScreen(
            childId: testChildId,
            serverScreenTime: client,
            syncBus: syncBus,
            showModeNotices: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(ChildDayBoardKeys.serverStale), findsNothing);
      expect(find.byKey(ChildDayBoardKeys.remainingMinutes), findsOneWidget);
      expect(find.text('متبقي 60 دقيقة'), findsOneWidget);
    },
  );
}

// Lack of pairing (401 / unauthenticated) is not an error shown to the child.
// An unpaired handset silently falls back to local policy mirror behavior
// without presenting any error or stale warning banner on the child board.

