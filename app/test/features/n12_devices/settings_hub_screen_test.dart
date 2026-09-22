import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n12_devices/device_health_detail_screen.dart';
import 'package:family_os/features/n12_devices/device_health_list_screen.dart';
import 'package:family_os/features/n12_devices/device_health_seam.dart';
import 'package:family_os/features/n12_devices/settings_hub_screen.dart';

void main() {
  tearDown(AppToast.dismiss);

  testWidgets('SCR-FAT-025 hub mounts sections + SOS ungated', (tester) async {
    var sos = false;
    await tester.pumpWidget(
      _app(
        child: SettingsHubScreen(
          roleOverride: AppRole.father,
          onSos: () => sos = true,
          healthSeam: FakeDeviceHealthSeam.atRiskBattery(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(SettingsHubKeys.screen), findsOneWidget);
    expect(find.byKey(SettingsHubKeys.body), findsOneWidget);
    expect(find.byKey(SettingsHubKeys.familySection), findsOneWidget);
    expect(find.byKey(SettingsHubKeys.devicesSection), findsOneWidget);
    expect(find.byKey(DeviceHealthListKeys.devicesSection), findsOneWidget);
    expect(find.byKey(SettingsHubKeys.sosCta), findsOneWidget);

    await tester.tap(find.byKey(SettingsHubKeys.sosCta));
    await tester.pumpAndSettle();
    expect(sos, isTrue);
  });

  testWidgets('SCR-FAT-025 mother OK — hides father-only rows', (tester) async {
    await tester.pumpWidget(
      _app(
        child: SettingsHubScreen(
          roleOverride: AppRole.mother,
          onSos: () {},
          healthSeam: FakeDeviceHealthSeam.atRiskBattery(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(SettingsHubKeys.body), findsOneWidget);
    expect(find.byKey(SettingsHubKeys.motherShareRow), findsNothing);
    expect(find.byKey(SettingsHubKeys.brainRow), findsNothing);
    expect(find.byKey(SettingsHubKeys.billingRow), findsNothing);
    expect(find.byKey(SettingsHubKeys.navRow('SCR-FAT-058')), findsOneWidget);
    expect(find.byKey(SettingsHubKeys.navRow('SCR-FAT-027')), findsOneWidget);
  });

  testWidgets('SCR-FAT-025 father shows father-only rows', (tester) async {
    await tester.pumpWidget(
      _app(
        child: SettingsHubScreen(
          roleOverride: AppRole.father,
          onSos: () {},
          healthSeam: FakeDeviceHealthSeam.atRiskBattery(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(SettingsHubKeys.motherShareRow), findsOneWidget);
    expect(find.byKey(SettingsHubKeys.brainRow), findsOneWidget);
    expect(find.byKey(SettingsHubKeys.billingRow), findsOneWidget);
  });

  testWidgets('SCR-FAT-025 child lean', (tester) async {
    await tester.pumpWidget(
      _app(
        child: SettingsHubScreen(
          roleOverride: AppRole.child,
          onSos: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(SettingsHubKeys.childLean), findsOneWidget);
    expect(find.byKey(SettingsHubKeys.body), findsNothing);
    expect(find.byKey(SettingsHubKeys.sosCta), findsOneWidget);
  });

  testWidgets('SCR-FAT-025 nav rows fire screen ids', (tester) async {
    final opened = <String>[];
    await tester.pumpWidget(
      _app(
        child: SettingsHubScreen(
          roleOverride: AppRole.father,
          onSos: () {},
          healthSeam: FakeDeviceHealthSeam.atRiskBattery(),
          onNavigate: opened.add,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(SettingsHubKeys.linkDeviceRow));
    await tester.tap(find.byKey(SettingsHubKeys.linkDeviceRow));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(SettingsHubKeys.navRow('SCR-FAT-058')));
    await tester.tap(find.byKey(SettingsHubKeys.navRow('SCR-FAT-058')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(SettingsHubKeys.billingRow));
    await tester.tap(find.byKey(SettingsHubKeys.billingRow));
    await tester.pumpAndSettle();

    expect(opened, containsAll(['SCR-FAT-058', 'SCR-FAT-004', 'SCR-FAT-056']));
  });

  testWidgets(
    'SCR-FAT-025 UI-012 AC2: hub card greens after FAT-026 repair',
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

      router.pop();
      await tester.pumpAndSettle();

      expect(router.state.uri.path, '/scr-fat-025');
      expect(find.text('سليم'), findsOneWidget);
      expect(find.text('قد ينقطع الاتصال'), findsNothing);
      expect(seam.devices.first.level, DeviceHealthLevel.healthy);
    },
  );

  test('Rule 23 — no planted names in settings hub / devices sources', () {
    final files = [
      'lib/features/n12_devices/settings_hub_screen.dart',
      'lib/features/n12_devices/device_health_list_screen.dart',
      'lib/features/n12_devices/device_health_detail_screen.dart',
      'lib/features/n12_devices/device_health_seam.dart',
    ];
    for (final path in files) {
      final src = File(path).readAsStringSync();
      expect(src.contains('خالد'), isFalse, reason: path);
      expect(src.contains('نورة'), isFalse, reason: path);
      expect(src.contains('عبدالله'), isFalse, reason: path);
      expect(src.contains('نوال'), isFalse, reason: path);
    }

    final arArb = File('lib/core/i18n/app_ar.arb').readAsStringSync();
    final enArb = File('lib/core/i18n/app_en.arb').readAsStringSync();
    for (final key in [
      'settingsHub',
      'deviceHealth',
    ]) {
      final re = RegExp('"$key[^"]*"\\s*:\\s*"((?:\\\\.|[^"\\\\])*)"');
      for (final value in [
        ...re.allMatches(arArb).map((m) => m.group(1)!),
        ...re.allMatches(enArb).map((m) => m.group(1)!),
      ]) {
        expect(value.contains('خالد'), isFalse, reason: value);
        expect(value.contains('نورة'), isFalse, reason: value);
        expect(value.contains('نوال'), isFalse, reason: value);
      }
    }
  });
}

Widget _app({required Widget child}) {
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
    home: child,
  );
}
