// S3 measurement — the one thing a child's own screen may say about a missing permission.
//
// Two cases, and the difference between them is the whole point: a phone without the
// native bridge has not been refused anything and must stay silent, while a phone that has
// the bridge and lacks the grant is told exactly where to grant it.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/smart_mode_activation_bus.dart';
import 'package:family_os/core/policy/smart_mode_prefs.dart';
import 'package:family_os/core/policy/policy_sync_bus.dart';
import 'package:family_os/features/n02_day/child_day_board_screen.dart';
import 'package:family_os/foundation_gate/child_screen_time_report_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_http.dart';

final _child = ChildId(SmartModePrefs.defaultChildId);

final class _ReportTransport implements ChildScreenTimeReportTransport {
  _ReportTransport({
    this.available = true,
    this.permissionGranted = false,
    this.opened = true,
  });

  final bool available;
  final bool permissionGranted;
  final bool opened;

  int openedSettings = 0;

  @override
  Future<UsageSnapshot> snapshot() async => UsageSnapshot(
    permissionGranted: permissionGranted,
    apps: const <AppUsageSample>[],
    available: available,
  );

  @override
  Future<bool> openUsageAccessSettings() async {
    openedSettings++;
    return opened;
  }

  @override
  Future<FoundationGateHttpResponse> postUsage({
    required String body,
    required String idempotencyKey,
  }) async => const FoundationGateHttpResponse(statusCode: 201, body: '{}');
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

Future<void> _pump(
  WidgetTester tester,
  ChildScreenTimeReportClient reporter,
) async {
  await tester.pumpWidget(
    _wrap(
      ChildDayBoardScreen(
        childId: _child,
        syncBus: PolicySyncBus(),
        activationBus: SmartModeActivationBus(),
        usageReporter: reporter,
        showModeNotices: false,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'a phone that cannot be asked says nothing about access',
    (tester) async {
      await _pump(
        tester,
        ChildScreenTimeReportClient(
          transport: _ReportTransport(available: false),
        ),
      );

      expect(find.byKey(ChildDayBoardKeys.usageAccessNote), findsNothing);
      expect(find.byKey(ChildDayBoardKeys.usageAccessOpen), findsNothing);
    },
  );

  testWidgets(
    'a handset without Usage access is told where to grant it',
    (tester) async {
      final transport = _ReportTransport(permissionGranted: false);
      await _pump(
        tester,
        ChildScreenTimeReportClient(transport: transport),
      );

      expect(find.byKey(ChildDayBoardKeys.usageAccessNote), findsOneWidget);
      expect(
        find.text('لقياس وقت الشاشة يحتاج هذا الهاتف إذن «الوصول إلى الاستخدام».'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(ChildDayBoardKeys.usageAccessOpen));
      await tester.pumpAndSettle();

      expect(
        transport.openedSettings,
        1,
        reason: 'the button must open the system screen, not explain it again',
      );
    },
  );

  testWidgets(
    'a handset that may look is never asked to look again',
    (tester) async {
      await _pump(
        tester,
        ChildScreenTimeReportClient(
          transport: _ReportTransport(permissionGranted: true),
        ),
      );

      expect(find.byKey(ChildDayBoardKeys.usageAccessNote), findsNothing);
    },
  );
}
