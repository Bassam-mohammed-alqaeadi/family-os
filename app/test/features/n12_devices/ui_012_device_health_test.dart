import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/tag.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n12_devices/device_health_detail_screen.dart';
import 'package:family_os/features/n12_devices/device_health_list_screen.dart';
import 'package:family_os/features/n12_devices/device_health_seam.dart';
import 'package:family_os/features/n12_devices/settings_hub_screen.dart';

void main() {
  tearDown(AppToast.dismiss);

  group('UI-012 DeviceHealthSeam', () {
    test('grantOnOpenSettings flips denied → healthy level', () async {
      final seam = FakeDeviceHealthSeam.atRiskBattery(
        grantOnOpenSettings: true,
      );
      addTearDown(seam.dispose);

      expect(seam.devices.first.level, DeviceHealthLevel.atRisk);

      await seam.openSettings(
        deviceId: 'dev_ac',
        kind: DevicePermissionKind.batteryExemption,
      );
      await seam.recheck('dev_ac');

      expect(seam.openSettingsCount, 1);
      expect(seam.recheckCount, 1);
      expect(seam.devices.first.level, DeviceHealthLevel.healthy);
      expect(
        seam.devices.first.permissions
            .firstWhere((p) => p.kind == DevicePermissionKind.batteryExemption)
            .status,
        DevicePermissionStatus.granted,
      );
    });

    test('offline keeps last permissions + offline level', () {
      final seam = FakeDeviceHealthSeam.atRiskBattery();
      addTearDown(seam.dispose);
      seam.setOffline('dev_ac', offline: true);
      expect(seam.devices.first.level, DeviceHealthLevel.offline);
      expect(seam.devices.first.offline, isTrue);
      expect(seam.devices.first.hasRepairableDeny, isTrue);
    });
  });

  group('UI-012 SCR-FAT-025/026 widgets', () {
    testWidgets('AC1: deny → repair → grant updates UI green', (tester) async {
      final seam = FakeDeviceHealthSeam.atRiskBattery(
        grantOnOpenSettings: true,
      );
      addTearDown(seam.dispose);

      await _pumpDetail(tester, seam: seam, deviceId: 'dev_ac');

      expect(find.byKey(DeviceHealthDetailKeys.repairCta), findsOneWidget);
      expect(find.text('قد ينقطع الاتصال'), findsOneWidget);
      expect(find.text('مرفوض'), findsOneWidget);

      await tester.ensureVisible(find.byKey(DeviceHealthDetailKeys.repairCta));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(DeviceHealthDetailKeys.repairCta));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      expect(seam.openSettingsCount, 1);
      expect(seam.recheckCount, 1);
      expect(find.text('سليم'), findsOneWidget);
      expect(find.byKey(DeviceHealthDetailKeys.repairCta), findsNothing);
      expect(find.text('مرفوض'), findsNothing);
    });

    testWidgets(
      'AC2: list card turns green same session (no reinstall)',
      (tester) async {
        final seam = FakeDeviceHealthSeam.atRiskBattery(
          grantOnOpenSettings: true,
        );
        addTearDown(seam.dispose);

        final router = GoRouter(
          initialLocation: '/scr-fat-025',
          routes: [
            GoRoute(
              path: '/scr-fat-025',
              builder: (context, state) => SettingsHubScreen(
                healthSeam: seam,
                roleOverride: AppRole.father,
                onSos: () {},
              ),
            ),
            GoRoute(
              path: '/scr-fat-026',
              builder: (context, state) => DeviceHealthDetailScreen(
                deviceId: state.uri.queryParameters['deviceId'],
                healthSeam: seam,
                onOpenSettingsToast: false,
              ),
            ),
          ],
        );
        addTearDown(router.dispose);

        await tester.pumpWidget(
          MaterialApp.router(
            theme: buildFamilyTheme(),
            locale: const Locale('ar'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            routerConfig: router,
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(DeviceHealthListKeys.healthTag('dev_ac')),
          findsOneWidget,
        );
        expect(find.text('قد ينقطع الاتصال'), findsWidgets);

        await tester.tap(find.byKey(DeviceHealthListKeys.deviceCard('dev_ac')));
        await tester.pumpAndSettle();

        expect(router.state.uri.path, '/scr-fat-026');
        await tester.ensureVisible(find.byKey(DeviceHealthDetailKeys.repairCta));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(DeviceHealthDetailKeys.repairCta));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pumpAndSettle();

        // Pop back — same process, stream already updated.
        router.pop();
        await tester.pumpAndSettle();

        expect(router.state.uri.path, '/scr-fat-025');
        expect(find.text('سليم'), findsOneWidget);
        expect(find.text('قد ينقطع الاتصال'), findsNothing);
        expect(seam.devices.first.level, DeviceHealthLevel.healthy);
      },
    );

    testWidgets('permanently denied shows OS-blocked edge + repair', (
      tester,
    ) async {
      final seam = FakeDeviceHealthSeam(
        initial: [
          DeviceHealthSnapshot(
            deviceId: 'dev_perm',
            childId: 'child_p',
            displayLabel: 'ابن ١',
            modelLabel: 'OEM device',
            level: DeviceHealthLevel.atRisk,
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

      await _pumpDetail(tester, seam: seam, deviceId: 'dev_perm');

      expect(find.byKey(DeviceHealthDetailKeys.permanentBanner), findsOneWidget);
      expect(find.text('منعه النظام'), findsOneWidget);
      expect(find.byKey(DeviceHealthDetailKeys.repairCta), findsOneWidget);
    });

    testWidgets('offline shows last health banner', (tester) async {
      final seam = FakeDeviceHealthSeam.atRiskBattery();
      addTearDown(seam.dispose);
      seam.setOffline('dev_ac', offline: true);

      await _pumpDetail(tester, seam: seam, deviceId: 'dev_ac');

      expect(find.byKey(DeviceHealthDetailKeys.offlineBanner), findsOneWidget);
      expect(find.text('غير متصل'), findsOneWidget);
    });

    testWidgets('repair CTA min height ≥48dp', (tester) async {
      final seam = FakeDeviceHealthSeam.atRiskBattery();
      addTearDown(seam.dispose);
      await _pumpDetail(tester, seam: seam, deviceId: 'dev_ac');

      final box = tester.renderObject<RenderBox>(
        find.byKey(DeviceHealthDetailKeys.repairCta),
      );
      expect(box.size.height, greaterThanOrEqualTo(48));
    });

    test('Rule 23 — no planted names in feature sources or new ARB', () {
      final files = [
        'lib/features/n12_devices/device_health_seam.dart',
        'lib/features/n12_devices/device_health_list_screen.dart',
        'lib/features/n12_devices/device_health_detail_screen.dart',
      ];
      for (final path in files) {
        final src = File(path).readAsStringSync();
        expect(src.contains('خالد'), isFalse, reason: path);
        expect(src.contains('نورة'), isFalse, reason: path);
        expect(src.contains('عبدالله'), isFalse, reason: path);
      }

      final arArb = File('lib/core/i18n/app_ar.arb').readAsStringSync();
      final enArb = File('lib/core/i18n/app_en.arb').readAsStringSync();
      final arKeys = _deviceHealthValues(arArb);
      final enKeys = _deviceHealthValues(enArb);
      expect(arKeys, isNotEmpty);
      expect(enKeys, isNotEmpty);
      for (final value in [...arKeys, ...enKeys]) {
        expect(value.contains('خالد'), isFalse, reason: value);
        expect(value.contains('نورة'), isFalse, reason: value);
      }
    });

    testWidgets('healthy Tag uses mint (green) variant', (tester) async {
      final seam = FakeDeviceHealthSeam(
        initial: [
          DeviceHealthSnapshot(
            deviceId: 'dev_ok',
            childId: 'child_ok',
            displayLabel: 'ابن ١',
            modelLabel: 'OK',
            level: DeviceHealthLevel.healthy,
            permissions: const [
              DevicePermissionRow(
                kind: DevicePermissionKind.batteryExemption,
                status: DevicePermissionStatus.granted,
              ),
            ],
          ),
        ],
      );
      addTearDown(seam.dispose);
      await _pumpDetail(tester, seam: seam, deviceId: 'dev_ok');

      final tag = tester.widget<Tag>(
        find.byKey(DeviceHealthDetailKeys.healthTag),
      );
      expect(tag.variant, TagVariant.g);
      expect(tag.label, 'سليم');
    });
  });
}

List<String> _deviceHealthValues(String arb) {
  final re = RegExp(r'"deviceHealth[^"]*"\s*:\s*"((?:\\.|[^"\\])*)"');
  return re.allMatches(arb).map((m) => m.group(1)!).toList();
}

Future<void> _pumpDetail(
  WidgetTester tester, {
  required DeviceHealthSeam seam,
  required String deviceId,
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
        onOpenSettingsToast: false,
      ),
    ),
  );
  await tester.pumpAndSettle();
}
