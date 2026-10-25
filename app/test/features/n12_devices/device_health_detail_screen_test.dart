import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/identity/identity_runtime.dart';
import 'package:family_os/core/identity/identity_scope.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n12_devices/device_health_detail_screen.dart';
import 'package:family_os/features/n12_devices/device_health_seam.dart';
import 'package:family_os/features/n12_devices/device_capability_ledger_panel.dart';
import 'package:family_os/features/n12_devices/device_ledger_server_authority.dart';

import 'support/device_ledger_fake_server.dart';

void main() {
  tearDown(AppToast.dismiss);

  testWidgets('SCR-FAT-026 mounts health + permissions + SOS', (tester) async {
    var sos = false;
    final seam = FakeDeviceHealthSeam.atRiskBattery();
    addTearDown(seam.dispose);

    await _pumpDetail(
      tester,
      seam: seam,
      deviceId: 'dev_ac',
      role: AppRole.father,
      onSos: () => sos = true,
    );

    expect(find.byKey(DeviceHealthDetailKeys.screen), findsOneWidget);
    expect(find.byKey(DeviceHealthDetailKeys.body), findsOneWidget);
    expect(find.byKey(DeviceHealthDetailKeys.healthCard), findsOneWidget);
    expect(
      find.byKey(DeviceHealthDetailKeys.permissionsSection),
      findsOneWidget,
    );
    expect(find.byKey(DeviceHealthDetailKeys.sosCta), findsOneWidget);
    expect(find.text('قد ينقطع الاتصال'), findsOneWidget);

    await tester.tap(find.byKey(DeviceHealthDetailKeys.sosCta));
    await tester.pumpAndSettle();
    expect(sos, isTrue);
  });

  testWidgets('SCR-FAT-026 OEM guide + open-settings CTA', (tester) async {
    final seam = FakeDeviceHealthSeam.atRiskBattery();
    addTearDown(seam.dispose);

    await _pumpDetail(
      tester,
      seam: seam,
      deviceId: 'dev_ac',
      role: AppRole.father,
    );

    expect(find.byKey(DeviceHealthDetailKeys.oemBanner), findsOneWidget);
    expect(find.byKey(DeviceHealthDetailKeys.oemGuide), findsOneWidget);
    expect(find.textContaining('Xiaomi'), findsOneWidget);
    expect(find.text('لكي لا ينقطع الجهاز عنك'), findsOneWidget);
    expect(
      find.byKey(DeviceHealthDetailKeys.openSettingsNowCta),
      findsOneWidget,
    );
    expect(find.byKey(DeviceHealthDetailKeys.repairCta), findsOneWidget);
  });

  testWidgets('SCR-FAT-026 open-settings-now deny→repair→grant (UI-012 AC1)', (
    tester,
  ) async {
    final seam = FakeDeviceHealthSeam.atRiskBattery(grantOnOpenSettings: true);
    addTearDown(seam.dispose);

    await _pumpDetail(
      tester,
      seam: seam,
      deviceId: 'dev_ac',
      role: AppRole.father,
    );

    expect(find.byKey(DeviceHealthDetailKeys.repairCta), findsOneWidget);

    await tester.tap(find.byKey(DeviceHealthDetailKeys.openSettingsNowCta));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();

    expect(seam.openSettingsCount, 1);
    expect(seam.recheckCount, 1);
    expect(find.text('سليم'), findsOneWidget);
    expect(find.byKey(DeviceHealthDetailKeys.repairCta), findsNothing);
    expect(find.byKey(DeviceHealthDetailKeys.oemGuide), findsNothing);
  });

  testWidgets('SCR-FAT-026 mother OK — full detail + SOS', (tester) async {
    var sos = false;
    final seam = FakeDeviceHealthSeam.atRiskBattery();
    addTearDown(seam.dispose);

    await _pumpDetail(
      tester,
      seam: seam,
      deviceId: 'dev_ac',
      role: AppRole.mother,
      onSos: () => sos = true,
    );

    expect(find.byKey(DeviceHealthDetailKeys.body), findsOneWidget);
    expect(find.byKey(DeviceHealthDetailKeys.childLean), findsNothing);
    expect(
      find.byKey(DeviceHealthDetailKeys.permissionsSection),
      findsOneWidget,
    );
    expect(find.byKey(DeviceHealthDetailKeys.sosCta), findsOneWidget);

    await tester.tap(find.byKey(DeviceHealthDetailKeys.sosCta));
    await tester.pumpAndSettle();
    expect(sos, isTrue);
  });

  testWidgets('SCR-FAT-026 child lean — SOS still ungated', (tester) async {
    var sos = false;
    final seam = FakeDeviceHealthSeam.atRiskBattery();
    addTearDown(seam.dispose);

    await _pumpDetail(
      tester,
      seam: seam,
      deviceId: 'dev_ac',
      role: AppRole.child,
      onSos: () => sos = true,
    );

    expect(find.byKey(DeviceHealthDetailKeys.childLean), findsOneWidget);
    expect(find.byKey(DeviceHealthDetailKeys.body), findsNothing);
    expect(find.byKey(DeviceHealthDetailKeys.sosCta), findsOneWidget);

    await tester.tap(find.byKey(DeviceHealthDetailKeys.sosCta));
    await tester.pumpAndSettle();
    expect(sos, isTrue);
  });

  testWidgets('SCR-FAT-026 permanently denied + offline edges', (tester) async {
    final seam = FakeDeviceHealthSeam(
      initial: [
        DeviceHealthSnapshot(
          deviceId: 'dev_edge',
          childId: 'child_e',
          displayLabel: 'ابن 1',
          modelLabel: 'OEM device',
          level: DeviceHealthLevel.atRisk,
          oemFamily: 'Xiaomi',
          permissions: const [
            DevicePermissionRow(
              kind: DevicePermissionKind.autoStart,
              status: DevicePermissionStatus.permanentlyDenied,
            ),
          ],
        ),
      ],
    );
    addTearDown(seam.dispose);
    seam.setOffline('dev_edge', offline: true);

    await _pumpDetail(
      tester,
      seam: seam,
      deviceId: 'dev_edge',
      role: AppRole.father,
    );

    expect(find.byKey(DeviceHealthDetailKeys.offlineBanner), findsOneWidget);
    expect(find.byKey(DeviceHealthDetailKeys.permanentBanner), findsOneWidget);
    expect(
      find.byKey(
        DeviceHealthDetailKeys.permissionRow(DevicePermissionKind.autoStart),
      ),
      findsOneWidget,
    );
    expect(find.byKey(DeviceHealthDetailKeys.repairCta), findsOneWidget);
    expect(find.text('غير متصل'), findsOneWidget);
  });

  test('Rule 23 — no planted person names in FAT-026 sources/ARB', () {
    final files = [
      'lib/features/n12_devices/device_health_detail_screen.dart',
      'lib/features/n12_devices/device_health_seam.dart',
    ];
    for (final path in files) {
      final src = File(path).readAsStringSync();
      expect(src.contains('خالد'), isFalse, reason: path);
      expect(src.contains('نورة'), isFalse, reason: path);
      expect(src.contains('عبدالله'), isFalse, reason: path);
    }

    final arArb = File('lib/core/i18n/app_ar.arb').readAsStringSync();
    final enArb = File('lib/core/i18n/app_en.arb').readAsStringSync();
    final re = RegExp(r'"deviceHealth[^"]*"\s*:\s*"((?:\\.|[^"\\])*)"');
    for (final value in [
      ...re.allMatches(arArb).map((m) => m.group(1)!),
      ...re.allMatches(enArb).map((m) => m.group(1)!),
    ]) {
      expect(value.contains('خالد'), isFalse, reason: value);
      expect(value.contains('نورة'), isFalse, reason: value);
      expect(value.contains('عبدالله'), isFalse, reason: value);
    }
  });

  testWidgets('SCR-FAT-026 without Identity → missing (no fam_stage1 leak)', (
    tester,
  ) async {
    final seam = FakeDeviceHealthSeam.atRiskBattery();
    addTearDown(seam.dispose);

    await _pumpDetail(
      tester,
      seam: seam,
      deviceId: 'dev_ac',
      role: AppRole.father,
      withIdentity: false,
    );

    expect(find.byKey(DeviceHealthDetailKeys.missing), findsOneWidget);
    expect(find.byKey(DeviceHealthDetailKeys.body), findsNothing);
  });
  testWidgets('SCR-FAT-026 · the capability ledger is on this screen, and speaks for the phone', (
    tester,
  ) async {
    // The column this slice exists to close: the spine's two endpoints already had typed clients,
    // and no screen imported them. So the proof is not that a panel can render a fixture — it is
    // that a parent who opens a device from the real route meets the phone's own account there, and
    // that the numbers on it came from the server rather than from this handset's health record.
    final transport = DeviceLedgerFakeTransport();
    transport.answer(
      deviceLedgerCapabilitiesPath,
      200,
      deviceLedgerCapabilitiesJson(),
    );
    transport.answer(deviceLedgerCommandsPath, 200, deviceLedgerCommandsJson([]));
    DeviceLedgerAuthority.bind(deviceLedgerAuthorityFor(transport));
    addTearDown(() => DeviceLedgerAuthority.bind(null));

    final seam = FakeDeviceHealthSeam(
      initial: const [
        DeviceHealthSnapshot(
          deviceId: deviceLedgerDeviceId,
          familyId: deviceLedgerFamilyId,
          childId: deviceLedgerChildId,
          displayLabel: 'ابن ١',
          modelLabel: 'Redmi Note 13',
          level: DeviceHealthLevel.atRisk,
          permissions: [],
          lastHeartbeatAgoLabel: '٩ د',
        ),
      ],
    );
    addTearDown(seam.dispose);

    await _pumpDetail(
      tester,
      seam: seam,
      deviceId: deviceLedgerDeviceId,
      role: AppRole.father,
    );

    expect(find.byKey(DeviceHealthDetailKeys.capabilityLedger), findsOneWidget);
    expect(find.byKey(DeviceLedgerKeys.panel), findsOneWidget);
    expect(find.byKey(DeviceLedgerKeys.capabilitiesCard), findsOneWidget);
    expect(find.text('1 تعمل، و2 تنتظر إعدادك'), findsOneWidget);
    expect(find.text('يعمل على الهاتف'), findsOneWidget);
    // Two reads, both of them the server's, in the order the contract defines — and no third
    // request invented by the screen.
    expect(transport.calls, const [
      'GET $deviceLedgerCapabilitiesPath',
      'GET $deviceLedgerCommandsPath',
    ]);
    expect(find.text('إيقاف الهاتف فوراً بأمرك'), findsOneWidget);
  });

  testWidgets('SCR-FAT-026 · the ledger says so when the record is a stage-one placeholder', (
    tester,
  ) async {
    // The demo seam keys devices `dev_a`/`child_a`. Handing that to the spine would produce a 404
    // the screen would have to dress up as a finding about the child's phone, so it is refused
    // before it is sent — and the screen says what is actually true: no linked child record.
    final transport = DeviceLedgerFakeTransport();
    DeviceLedgerAuthority.bind(deviceLedgerAuthorityFor(transport));
    addTearDown(() => DeviceLedgerAuthority.bind(null));

    final seam = FakeDeviceHealthSeam.demo();
    addTearDown(seam.dispose);

    await _pumpDetail(
      tester,
      seam: seam,
      deviceId: 'dev_a',
      role: AppRole.father,
    );

    expect(find.byKey(DeviceHealthDetailKeys.capabilityLedger), findsOneWidget);
    expect(find.text('هذا السجل غير مربوط بابن على الخادم'), findsOneWidget);
    expect(find.byKey(DeviceLedgerKeys.capabilitiesCard), findsNothing);
    expect(transport.calls, isEmpty);
  });

}

Future<void> _pumpDetail(
  WidgetTester tester, {
  required DeviceHealthSeam seam,
  required String deviceId,
  required AppRole role,
  VoidCallback? onSos,
  bool withIdentity = true,
}) async {
  final home = DeviceHealthDetailScreen(
    deviceId: deviceId,
    healthSeam: seam,
    roleOverride: role,
    onSos: onSos ?? () {},
    onOpenSettingsToast: false,
  );
  final app = MaterialApp(
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
  await tester.pumpWidget(
    withIdentity
        ? CurrentIdentity(runtime: createStage1IdentityRuntime(), child: app)
        : app,
  );
  await tester.pumpAndSettle();
}
