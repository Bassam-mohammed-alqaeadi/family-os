import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n12_devices/device_health_detail_screen.dart';
import 'package:family_os/features/n12_devices/device_health_seam.dart';

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
    expect(find.byKey(DeviceHealthDetailKeys.permissionsSection), findsOneWidget);
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
    expect(find.byKey(DeviceHealthDetailKeys.openSettingsNowCta), findsOneWidget);
    expect(find.byKey(DeviceHealthDetailKeys.repairCta), findsOneWidget);
  });

  testWidgets(
    'SCR-FAT-026 open-settings-now deny→repair→grant (UI-012 AC1)',
    (tester) async {
      final seam = FakeDeviceHealthSeam.atRiskBattery(
        grantOnOpenSettings: true,
      );
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
    },
  );

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
    expect(find.byKey(DeviceHealthDetailKeys.permissionsSection), findsOneWidget);
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
          displayLabel: 'ابن ١',
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
}

Future<void> _pumpDetail(
  WidgetTester tester, {
  required DeviceHealthSeam seam,
  required String deviceId,
  required AppRole role,
  VoidCallback? onSos,
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
      home: DeviceHealthDetailScreen(
        deviceId: deviceId,
        healthSeam: seam,
        roleOverride: role,
        onSos: onSos ?? () {},
        onOpenSettingsToast: false,
      ),
    ),
  );
  await tester.pumpAndSettle();
}
