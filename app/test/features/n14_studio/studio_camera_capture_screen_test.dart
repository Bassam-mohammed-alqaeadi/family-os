import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n01_linking/camera_permission_seam.dart';
import 'package:family_os/features/n14_studio/studio_camera_capture_screen.dart';

void main() {
  tearDown(AppToast.dismiss);

  testWidgets('father granted: viewfinder + capture → FAT-043', (tester) async {
    final nav = <String>[];
    await _pump(tester, onNavigate: nav.add);

    expect(find.byKey(StudioCameraCaptureKeys.body), findsOneWidget);
    expect(find.byKey(StudioCameraCaptureKeys.viewfinder), findsOneWidget);
    expect(find.byKey(StudioCameraCaptureKeys.captureCta), findsOneWidget);

    await tester.tap(find.byKey(StudioCameraCaptureKeys.captureCta));
    await tester.pump();
    AppToast.dismiss();
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-043'));
  });

  testWidgets('camera denied → repair CTA; grant resumes capture', (tester) async {
    final seam = FakeCameraPermissionSeam(
      status: CameraPermissionStatus.denied,
      grantOnOpenSettings: true,
    );
    await _pump(tester, permissionSeam: seam);

    expect(find.byKey(StudioCameraCaptureKeys.repairPanel), findsOneWidget);
    expect(find.byKey(StudioCameraCaptureKeys.openSettings), findsOneWidget);
    expect(find.byKey(StudioCameraCaptureKeys.viewfinder), findsNothing);

    final settingsBox = tester.getSize(
      find.byKey(StudioCameraCaptureKeys.openSettings),
    );
    expect(settingsBox.height, greaterThanOrEqualTo(48));

    await tester.tap(find.byKey(StudioCameraCaptureKeys.openSettings));
    await tester.pump();
    AppToast.dismiss();
    await tester.pumpAndSettle();

    expect(seam.status, CameraPermissionStatus.granted);
    expect(find.byKey(StudioCameraCaptureKeys.viewfinder), findsOneWidget);
    expect(find.byKey(StudioCameraCaptureKeys.captureCta), findsOneWidget);
  });

  testWidgets('denied retry request can grant', (tester) async {
    final seam = FakeCameraPermissionSeam(
      status: CameraPermissionStatus.denied,
      grantOnRequest: true,
    );
    await _pump(tester, permissionSeam: seam);

    await tester.tap(find.byKey(StudioCameraCaptureKeys.retryPermission));
    await tester.pumpAndSettle();
    expect(seam.status, CameraPermissionStatus.granted);
    expect(find.byKey(StudioCameraCaptureKeys.viewfinder), findsOneWidget);
  });

  testWidgets('permanently denied shows instructions + settings', (tester) async {
    final seam = FakeCameraPermissionSeam(
      status: CameraPermissionStatus.permanentlyDenied,
    );
    await _pump(tester, permissionSeam: seam);

    expect(find.byKey(StudioCameraCaptureKeys.permanentPanel), findsOneWidget);
    expect(find.byKey(StudioCameraCaptureKeys.openSettings), findsOneWidget);
    expect(find.byKey(StudioCameraCaptureKeys.viewfinder), findsNothing);
  });

  testWidgets('mother observer view-only — capture blocked', (tester) async {
    final nav = <String>[];
    await _pump(
      tester,
      role: AppRole.mother,
      motherLevel: MotherLevel.observer,
      onNavigate: nav.add,
    );

    expect(find.byKey(StudioCameraCaptureKeys.observerHint), findsOneWidget);
    await tester.tap(find.byKey(StudioCameraCaptureKeys.captureCta));
    await tester.pump();
    AppToast.dismiss();
    await tester.pumpAndSettle();
    expect(nav, isEmpty);
  });

  testWidgets('mother partner can capture → FAT-043', (tester) async {
    final nav = <String>[];
    await _pump(
      tester,
      role: AppRole.mother,
      motherLevel: MotherLevel.partner,
      onNavigate: nav.add,
    );

    expect(find.byKey(StudioCameraCaptureKeys.observerHint), findsNothing);
    await tester.tap(find.byKey(StudioCameraCaptureKeys.captureCta));
    await tester.pump();
    AppToast.dismiss();
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-043'));
  });

  testWidgets('child RoleGuard lean + SOS', (tester) async {
    var sos = false;
    await _pump(
      tester,
      role: AppRole.child,
      onSos: () => sos = true,
    );

    expect(find.byKey(StudioCameraCaptureKeys.childLean), findsOneWidget);
    expect(find.byKey(StudioCameraCaptureKeys.body), findsNothing);
    expect(find.byKey(StudioCameraCaptureKeys.sosIconCta), findsOneWidget);

    await tester.tap(find.byKey(StudioCameraCaptureKeys.sosIconCta));
    await tester.pumpAndSettle();
    expect(sos, isTrue);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  AppRole role = AppRole.father,
  MotherLevel motherLevel = MotherLevel.partner,
  CameraPermissionSeam? permissionSeam,
  CameraPermissionStatus? initialStatus,
  VoidCallback? onSos,
  void Function(String screenId)? onNavigate,
}) async {
  final roleCtrl = RoleController(role);
  addTearDown(roleCtrl.dispose);
  await tester.pumpWidget(
    CurrentRole(
      notifier: roleCtrl,
      child: MaterialApp(
        theme: buildFamilyTheme(),
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: StudioCameraCaptureScreen(
          roleOverride: role,
          motherLevel: motherLevel,
          permissionSeam: permissionSeam,
          initialStatus: initialStatus,
          onSos: onSos,
          onNavigate: onNavigate,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
