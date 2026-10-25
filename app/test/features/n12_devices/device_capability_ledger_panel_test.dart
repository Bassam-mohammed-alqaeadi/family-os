// SCR-FAT-026 · the capability ledger, on a real phone at large text, doing its job.
//
// Three things are asserted here, and each one is a defect this screen could have shipped with:
//
//   * Every line a parent came for is in the tree on a 320×600 surface at textScaler 2.0 — built,
//     not "below the fold". A capability row that only exists after scrolling is invisible to a
//     screen reader and to the parent who arrived from a notification.
//   * The words on screen are the phone's, with the timestamp the phone gave and the order state the
//     server returned. Nothing here is inferred from a health badge or a green switch.
//   * The one thing a guardian may do from this screen — ask the phone to take the stored settings
//     again — is one write, and what comes back on success is the server's own state, not the
//     screen's hope. The stop and lift buttons deliberately are not here: they belong to the
//     screen-time panel, and a second button for one power gives a family two truths.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n12_devices/device_capability_ledger_panel.dart';
import 'package:family_os/features/n12_devices/device_ledger_server_authority.dart';

import 'support/device_ledger_fake_server.dart';

const _ledgerKeys = <String>[
  'device_ledger_capabilities_card',
  'device_ledger_orders_card',
  'device_ledger_summary',
  'device_ledger_refresh_cta',
  'device_ledger_lock_hint',
];

String _facts(WidgetTester tester) {
  final missing = <String>[
    for (final key in _ledgerKeys)
      if (find.byKey(Key(key)).evaluate().isEmpty) key,
  ];
  return 'cards=${find.byKey(const Key('device_ledger_panel')).evaluate().length} '
      'rows=${find.byType(Scrollable).evaluate().length} '
      'missing=${missing.isEmpty ? 'none' : missing.join(',')}';
}

Future<void> _pumpLedger(
  WidgetTester tester, {
  required DeviceLedgerFakeTransport transport,
  bool withServer = true,
  String childId = deviceLedgerChildId,
  String? deviceId = deviceLedgerDeviceId,
  Size surface = const Size(320, 600),
  double textScale = 2.0,
}) async {
  tester.view.devicePixelRatio = 2.0;
  tester.view.physicalSize = surface * 2.0;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

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
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
      // The panel is mounted inside the same scrolling body the device screen uses, so a layout
      // defect here is a layout defect there.
      home: Scaffold(
        body: SingleChildScrollView(
          child: DeviceCapabilityLedgerPanel(
            childId: childId,
            deviceId: deviceId,
            deviceLabel: 'ابن ١',
            // `withServer: false` is the shape of a build that was never given a server: the panel
            // must show that as its own answer, not as an empty one.
            authority: withServer ? deviceLedgerAuthorityFor(transport) : null,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  tearDown(() => DeviceLedgerAuthority.bind(null));

  testWidgets('a parent reads what the phone claimed, in the order it matters', (
    tester,
  ) async {
    final transport = DeviceLedgerFakeTransport();
    transport.answer(deviceLedgerCapabilitiesPath, 200, deviceLedgerCapabilitiesJson());
    transport.answer(
      deviceLedgerCommandsPath,
      200,
      deviceLedgerCommandsJson([
        deviceLedgerCommandJson(receiptKind: 'applied', receivedAt: '2026-10-07T09:00:30.000Z'),
      ]),
    );

    await _pumpLedger(tester, transport: transport);

    expect(find.byKey(DeviceLedgerKeys.panel), findsOneWidget, reason: _facts(tester));
    for (final key in _ledgerKeys) {
      expect(find.byKey(Key(key)), findsOneWidget, reason: _facts(tester));
    }
    // The capability the family is really asking about, first.
    expect(find.text('إيقاف الهاتف فوراً بأمرك'), findsOneWidget, reason: _facts(tester));
    expect(find.text('يعمل على الهاتف'), findsOneWidget, reason: _facts(tester));
    expect(find.text('يحتاج إذناً من الهاتف'), findsOneWidget, reason: _facts(tester));
    expect(find.text('في انتظار إعدادك'), findsOneWidget, reason: _facts(tester));
    // Counts, and the phone's own clock, on the same line as the claim.
    expect(find.text('1 تعمل، و2 تنتظر إعدادك'), findsOneWidget, reason: _facts(tester));
    expect(find.textContaining('09:00 · 2026-10-07'), findsWidgets);
    expect(find.text('من تطبيق إصدار 1.4.0'), findsWidgets);
    expect(find.text('على نظام Android 15'), findsWidgets);
    // The order, its window, and the receipt that closed it.
    expect(find.textContaining('تحديث الإعدادات · نُفّذ على الهاتف'), findsOneWidget);
    expect(find.textContaining('ردّ الهاتف: نُفّذ على الهاتف'), findsOneWidget);
    expect(
      transport.calls,
      const [
        'GET $deviceLedgerCapabilitiesPath',
        'GET $deviceLedgerCommandsPath',
      ],
      reason: _facts(tester),
    );
    expect(tester.takeException(), isNull, reason: _facts(tester));
  });

  testWidgets('asking the phone again is one write, answered by the server\'s own state', (
    tester,
  ) async {
    final transport = DeviceLedgerFakeTransport();
    transport.answer(deviceLedgerCapabilitiesPath, 200, deviceLedgerCapabilitiesJson());
    transport.answer(deviceLedgerCommandsPath, 200, deviceLedgerCommandsJson([]));
    transport.answer(
      deviceLedgerCommandWritePath,
      201,
      deviceLedgerCreatedCommandJson(),
    );

    await _pumpLedger(tester, transport: transport);
    final before = transport.calls.length;

    final cta = find.byKey(DeviceLedgerKeys.refreshCta);
    await tester.ensureVisible(cta);
    await tester.pump();
    await tester.tap(cta);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      transport.calls.skip(before).toList(),
      const [
        'POST $deviceLedgerCommandWritePath',
        'GET $deviceLedgerCapabilitiesPath',
        'GET $deviceLedgerCommandsPath',
      ],
      reason: _facts(tester),
    );
    expect(transport.lastBody, isNotNull);
    expect(
      find.text('طلب التحديث مسجّل عند الخادم'),
      findsOneWidget,
      reason: _facts(tester),
    );
    // The order the server just created is on screen because the server said it, with its own id.
    expect(find.textContaining('استلمه الخادم'), findsOneWidget, reason: _facts(tester));
    expect(tester.takeException(), isNull, reason: _facts(tester));
  });

  testWidgets('a refused order is said, not smoothed over', (tester) async {
    final transport = DeviceLedgerFakeTransport();
    transport.answer(deviceLedgerCapabilitiesPath, 200, deviceLedgerCapabilitiesJson());
    transport.answer(deviceLedgerCommandsPath, 200, deviceLedgerCommandsJson([]));
    transport.answer(deviceLedgerCommandWritePath, 409, '{}');

    await _pumpLedger(tester, transport: transport);
    final cta = find.byKey(DeviceLedgerKeys.refreshCta);
    await tester.ensureVisible(cta);
    await tester.tap(cta);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.text('رفض الخادم أمرك'),
      findsOneWidget,
      reason: _facts(tester),
    );
    // Nothing was recorded as done: the ledger still holds the phone's last real report.
    expect(find.text('يعمل على الهاتف'), findsOneWidget, reason: _facts(tester));
  });

  testWidgets('a write into silence is reported as silence, not as a broken answer', (
    tester,
  ) async {
    // The distinction is the whole point of this screen. A server that never replied has not
    // produced a bad answer, and telling a parent the reply could not be read invites them to wait
    // for one that will never come. The last true reading stays on screen either way.
    final transport = DeviceLedgerFakeTransport();
    transport.answer(deviceLedgerCapabilitiesPath, 200, deviceLedgerCapabilitiesJson());
    transport.answer(deviceLedgerCommandsPath, 200, deviceLedgerCommandsJson([]));

    await _pumpLedger(tester, transport: transport);
    final cta = find.byKey(DeviceLedgerKeys.refreshCta);
    await tester.ensureVisible(cta);
    await tester.tap(cta);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.text('لم يستجب الخادم — هذه آخر حالة وصلت'),
      findsOneWidget,
      reason: _facts(tester),
    );
    expect(find.text('يعمل على الهاتف'), findsOneWidget, reason: _facts(tester));
  });

  testWidgets('a shortened order list says what it left out', (tester) async {
    // The server caps what it sends and the panel draws eight. Without this line a parent reads the
    // eight newest as the whole history of the device and concludes nothing else was ever asked.
    final transport = DeviceLedgerFakeTransport();
    transport.answer(deviceLedgerCapabilitiesPath, 200, deviceLedgerCapabilitiesJson());
    transport.answer(
      deviceLedgerCommandsPath,
      200,
      deviceLedgerCommandsJson([
        for (var i = 0; i < 9; i++)
          deviceLedgerCommandJson(
            id: '44444444-0000-4000-8000-00000000000$i',
            state: i == 0 ? 'applied' : 'expired',
          ),
      ]),
    );

    await _pumpLedger(tester, transport: transport);

    expect(find.text('يظهر 8 من 9، الأحدث أولاً'), findsOneWidget, reason: _facts(tester));
    expect(find.byKey(DeviceLedgerKeys.ordersCount), findsOneWidget);
  });

  testWidgets('a build with no server says nobody was asked, and offers nothing to tap', (
    tester,
  ) async {
    await _pumpLedger(tester, transport: DeviceLedgerFakeTransport(), withServer: false);

    expect(find.text('لا توجد جلسة خادم — لم نعرض أي قدرة'), findsOneWidget);
    expect(find.byKey(DeviceLedgerKeys.capabilitiesCard), findsNothing);
    expect(find.byKey(DeviceLedgerKeys.refreshCta), findsNothing);
    expect(find.byKey(DeviceLedgerKeys.status), findsOneWidget, reason: _facts(tester));
  });

  testWidgets('a placeholder device record is named, not answered with an empty ledger', (
    tester,
  ) async {
    // The stage-one seam still keys devices `dev_a` / `child_a`. The ledger must not let that look
    // like a finding about the child's phone.
    final transport = DeviceLedgerFakeTransport();

    await _pumpLedger(
      tester,
      transport: transport,
      childId: 'child_a',
      deviceId: 'dev_a',
    );

    expect(find.text('هذا السجل غير مربوط بابن على الخادم'), findsOneWidget);
    expect(find.byKey(DeviceLedgerKeys.capabilitiesCard), findsNothing);
    expect(transport.calls, isEmpty);
  });

  testWidgets('a phone that reported nothing is said plainly', (tester) async {
    final transport = DeviceLedgerFakeTransport();
    transport.answer(
      deviceLedgerCapabilitiesPath,
      200,
      deviceLedgerCapabilitiesJson(devices: const []),
    );
    transport.answer(deviceLedgerCommandsPath, 200, deviceLedgerCommandsJson([]));

    await _pumpLedger(tester, transport: transport);

    expect(find.text('لم يبلّغ هذا الجهاز عن أي قدرة بعد'), findsOneWidget, reason: _facts(tester));
    expect(find.text('0 تعمل، و0 تنتظر إعدادك'), findsOneWidget);
    expect(find.byKey(DeviceLedgerKeys.empty), findsOneWidget);
  });

  testWidgets('the smallest supported surface holds every line without overflow', (
    tester,
  ) async {
    final transport = DeviceLedgerFakeTransport();
    transport.answer(deviceLedgerCapabilitiesPath, 200, deviceLedgerCapabilitiesJson());
    transport.answer(
      deviceLedgerCommandsPath,
      200,
      deviceLedgerCommandsJson([deviceLedgerCommandJson()]),
    );

    await _pumpLedger(
      tester,
      transport: transport,
      surface: const Size(320, 480),
      textScale: 2.0,
    );

    for (final key in _ledgerKeys) {
      expect(find.byKey(Key(key)), findsOneWidget, reason: _facts(tester));
    }
    // No RenderFlex overflow may be swallowed on the way to this line.
    expect(tester.takeException(), isNull, reason: _facts(tester));
  });
}
