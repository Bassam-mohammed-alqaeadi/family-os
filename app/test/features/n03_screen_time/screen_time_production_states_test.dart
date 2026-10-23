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

Future<void> _pumpWidget(
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
          idempotencyKey: () => 'w5-production-states-key',
        ),
      ),
    ),
  );
}

Future<void> _pump(
  WidgetTester tester, {
  ScreenTimeServerAuthority? authority,
  bool canEdit = true,
}) async {
  await _pumpWidget(tester, authority: authority, canEdit: canEdit);
  await tester.pumpAndSettle();
}

void main() {
  tearDown(() => bindScreenTimeServerAuthority(null));

  testWidgets(
    'loading is named loading and never claims there is no session',
    (tester) async {
      final transport = ScreenTimeFakeTransport({
        '/screen-time': FoundationGateHttpResponse(
          statusCode: 200,
          body: screenTimeSnapshotJson(),
        ),
      });

      await _pumpWidget(tester, authority: screenTimeAuthorityFor(transport));

      expect(
        find.byKey(const Key('screen_time_server_loading')),
        findsOneWidget,
      );
      expect(
        find.text('لا توجد جلسة خادم في هذا البناء — لا نعرض أرقامًا لا نفرضها.'),
        findsNothing,
      );
      expect(
        find.text('جارٍ تحميل حالة وقت الشاشة من الخادم…'),
        findsOneWidget,
      );

      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'a family with no limits set sees an empty state',
    (tester) async {
      final transport = ScreenTimeFakeTransport({
        '/screen-time': FoundationGateHttpResponse(
          statusCode: 200,
          body: screenTimeSnapshotJson(configured: false),
        ),
      });

      await _pump(tester, authority: screenTimeAuthorityFor(transport));

      expect(
        find.byKey(const Key('screen_time_server_empty')),
        findsOneWidget,
      );
      expect(
        find.text('لم تُضبط حدود وقت الشاشة لهذا الطفل بعد — لا شيء مفروض الآن.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'a refused answer is an error and the panel says so',
    (tester) async {
      final transport = ScreenTimeFakeTransport({
        '/screen-time': const FoundationGateHttpResponse(
          statusCode: 403,
          body: '{"error":{"code":"FORBIDDEN","message":"forbidden"}}',
        ),
      });

      await _pump(tester, authority: screenTimeAuthorityFor(transport));

      expect(
        find.byKey(const Key('screen_time_server_denied')),
        findsOneWidget,
      );
      expect(
        find.text('هذا الحساب لا يملك قراءة وقت شاشة هذا الابن.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'a silent server keeps the last true answer and says it is the last one',
    (tester) async {
      final transport = ScreenTimeFakeTransport({
        '/screen-time': FoundationGateHttpResponse(
          statusCode: 200,
          body: screenTimeSnapshotJson(reason: 'daily_limit', kind: 'blocked'),
        ),
      });

      await _pump(tester, authority: screenTimeAuthorityFor(transport));
      expect(find.text('انتهى وقت اليوم'), findsOneWidget);

      transport.failure = StateError('socket closed');
      await tester.tap(find.byKey(const Key('screen_time_server_lock_button')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('screen_time_server_unreachable')),
        findsOneWidget,
      );
      expect(
        find.text('انتهى وقت اليوم'),
        findsOneWidget,
        reason: 'the last true answer is still true',
      );
    },
  );

  testWidgets(
    'the ready answer is what the screen shows',
    (tester) async {
      final transport = ScreenTimeFakeTransport({
        '/screen-time': FoundationGateHttpResponse(
          statusCode: 200,
          body: screenTimeSnapshotJson(
            kind: 'limited',
            reason: 'bedtime',
            usedMinutes: 30,
            remaining: 30,
            cap: 60,
          ),
        ),
      });

      await _pump(tester, authority: screenTimeAuthorityFor(transport));

      expect(find.text('حان وقت النوم'), findsOneWidget);
      expect(find.text('دقائق اليوم المحتسبة: 30'), findsOneWidget);
      expect(find.text('متبقي 30 دقيقة'), findsOneWidget);
      final field = tester.widget<TextField>(
        find.byKey(const Key('screen_time_server_cap_field')),
      );
      expect(field.controller?.text, '60');
    },
  );
}
