import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/placeholder_screen.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n01_linking/camera_permission_seam.dart';
import 'package:family_os/features/n01_linking/child_qr_scan_screen.dart';

void main() {
  tearDown(AppToast.dismiss);

  test('UF-01 token shape accepts 8 chars / hyphen group', () {
    expect(isValidLinkToken('A1B2C3D4'), isTrue);
    expect(isValidLinkToken('A1B2-C3D4'), isTrue);
    expect(isValidLinkToken('short'), isFalse);
    expect(isValidLinkToken('TOO-LONG12'), isFalse);
  });

  testWidgets('AC1 — deny camera → repair CTA visible', (tester) async {
    final seam = FakeCameraPermissionSeam(
      status: CameraPermissionStatus.denied,
    );
    await _pumpScreen(tester, seam: seam);

    expect(find.byKey(ChildQrScanKeys.repairPanel), findsOneWidget);
    expect(find.byKey(ChildQrScanKeys.openSettings), findsOneWidget);
    expect(find.text('نحتاج إذن الكاميرا'), findsOneWidget);
    expect(find.text('فتح إعدادات الكاميرا'), findsOneWidget);
    expect(find.byKey(ChildQrScanKeys.scanFrame), findsNothing);
  });

  testWidgets('AC2 — after grant, scan resumes', (tester) async {
    final seam = FakeCameraPermissionSeam(
      status: CameraPermissionStatus.denied,
      grantOnOpenSettings: true,
    );
    await _pumpScreen(tester, seam: seam);

    expect(find.byKey(ChildQrScanKeys.repairPanel), findsOneWidget);

    await tester.tap(find.byKey(ChildQrScanKeys.openSettings));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();

    expect(seam.openSettingsCount, 1);
    expect(seam.status, CameraPermissionStatus.granted);
    expect(find.byKey(ChildQrScanKeys.scanFrame), findsOneWidget);
    expect(find.byKey(ChildQrScanKeys.repairPanel), findsNothing);
  });

  testWidgets('AC3 — repair CTA min height ≥48dp', (tester) async {
    final seam = FakeCameraPermissionSeam(
      status: CameraPermissionStatus.denied,
    );
    await _pumpScreen(tester, seam: seam);

    final box = tester.renderObject<RenderBox>(
      find.byKey(ChildQrScanKeys.openSettings),
    );
    expect(box.size.height, greaterThanOrEqualTo(48));
  });

  testWidgets('permanently denied → manual instructions + code field', (
    tester,
  ) async {
    final seam = FakeCameraPermissionSeam(
      status: CameraPermissionStatus.permanentlyDenied,
    );
    await _pumpScreen(tester, seam: seam);

    expect(find.byKey(ChildQrScanKeys.permanentPanel), findsOneWidget);
    expect(find.byKey(ChildQrScanKeys.manualCode), findsOneWidget);
    expect(
      find.textContaining('أدخل الرمز يدويًا'),
      findsWidgets,
    );
    expect(find.byKey(ChildQrScanKeys.openSettings), findsNothing);
    expect(find.byKey(ChildQrScanKeys.scanFrame), findsNothing);
  });

  testWidgets('granted → scan frame + simulate navigates CHD-003', (
    tester,
  ) async {
    final seam = FakeCameraPermissionSeam(
      status: CameraPermissionStatus.granted,
    );
    final router = GoRouter(
      initialLocation: '/scr-chd-002',
      routes: [
        GoRoute(
          path: '/scr-chd-002',
          builder: (context, state) => ChildQrScanScreen(permissionSeam: seam),
        ),
        GoRoute(
          path: '/scr-chd-003',
          builder: (context, state) => const PlaceholderScreen(
            screenId: 'SCR-CHD-003',
            title: 'إقرار الشفافية',
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

    expect(find.byKey(ChildQrScanKeys.scanFrame), findsOneWidget);
    await tester.tap(find.byKey(ChildQrScanKeys.simulateScan));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/scr-chd-003');
  });

  test('Rule 23 — no خالد in screen source or new ARB keys', () {
    final screen = File(
      'lib/features/n01_linking/child_qr_scan_screen.dart',
    ).readAsStringSync();
    expect(screen.contains('خالد'), isFalse);

    final arArb = File('lib/core/i18n/app_ar.arb').readAsStringSync();
    final enArb = File('lib/core/i18n/app_en.arb').readAsStringSync();
    final arKeys = _childQrValues(arArb);
    final enKeys = _childQrValues(enArb);
    expect(arKeys, isNotEmpty);
    expect(enKeys, isNotEmpty);
    for (final value in [...arKeys, ...enKeys]) {
      expect(value.contains('خالد'), isFalse, reason: value);
    }
  });
}

List<String> _childQrValues(String arb) {
  final re = RegExp(r'"childQr[^"]*"\s*:\s*"((?:\\.|[^"\\])*)"');
  return re.allMatches(arb).map((m) => m.group(1)!).toList();
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  required CameraPermissionSeam seam,
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
      home: ChildQrScanScreen(
        permissionSeam: seam,
        onOpenSettingsToast: false,
      ),
    ),
  );
  await tester.pumpAndSettle();
}
