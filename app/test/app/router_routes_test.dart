import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:family_os/app/placeholder_screen.dart';
import 'package:family_os/app/role_controller.dart';
import 'package:family_os/app/role_guard.dart';
import 'package:family_os/app/router.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n01_linking/add_child_screen.dart';
import 'package:family_os/features/n01_linking/create_family_screen.dart';
import 'package:family_os/features/n01_linking/link_qr_screen.dart';
import 'package:family_os/features/n01_linking/link_success_screen.dart';
import 'package:family_os/features/n01_linking/permissions_explainer_screen.dart';
import 'package:family_os/features/n01_linking/setup_wizard_screen.dart';
import 'package:family_os/features/n01_linking/trial_mode_screen.dart';
import 'package:family_os/features/n01_linking/invite_mother_screen.dart';
import 'package:family_os/features/n01_linking/accept_mother_invite_screen.dart';
import 'package:family_os/features/n01_linking/child_qr_scan_screen.dart';
import 'package:family_os/features/n01_linking/transparency_consent_screen.dart';
import 'package:family_os/features/n02_day/day_board_screen.dart';
import 'package:family_os/features/n02_day/children_list_screen.dart';
import 'package:family_os/features/n02_day/child_profile_screen.dart';
import 'package:family_os/features/n02_day/location_map_screen.dart';
import 'package:family_os/features/n02_day/child_day_board_screen.dart';
import 'package:family_os/features/n02_day/child_chats_screen.dart';
import 'package:family_os/features/n03_screen_time/child_screen_time_screen.dart';
import 'package:family_os/features/n03_screen_time/child_apps_screen.dart';
import 'package:family_os/features/n03_screen_time/new_app_approval_screen.dart';
import 'package:family_os/features/n04_web_filter/web_filter_screen.dart';
import 'package:family_os/features/n05_lock/instant_lock_screen.dart';
import 'package:family_os/features/n05_lock/tamper_alerts_screen.dart';
import 'package:family_os/features/n14_studio/studio_board_screen.dart';
import 'package:family_os/features/n06_notifications/notification_prefs_screen.dart';
import 'package:family_os/features/n07_privacy/privacy_data_screen.dart';
import 'package:family_os/features/n07_privacy/audit_log_screen.dart';
import 'package:family_os/features/n07_advisor/brain_control_screen.dart';
import 'package:family_os/features/n12_devices/mother_permission_level_screen.dart';
import 'package:family_os/features/n07_advisor/advisor_suggestions_screen.dart';
import 'package:family_os/features/n07_privacy/what_is_collected_screen.dart';
import 'package:family_os/features/n08_platform/smart_supervision_screen.dart';
import 'package:family_os/features/n08_platform/platform_monitoring_screen.dart';
import 'package:family_os/features/n09_smart_modes/smart_modes_screen.dart';
import 'package:family_os/features/n10_emergency/child_sos_in_progress_screen.dart';
import 'package:family_os/features/n11_billing/plans_screen.dart';
import 'package:family_os/features/n11_billing/manage_subscription_screen.dart';
import 'package:family_os/features/n16_tasks/create_task_screen.dart';
import 'package:family_os/features/shared_onboarding/create_account_screen.dart';
import 'package:family_os/features/shared_onboarding/device_mode_screen.dart';
import 'package:family_os/features/shared_onboarding/device_user_switch_screen.dart';
import 'package:family_os/features/shared_onboarding/login_screen.dart';
import 'package:family_os/features/shared_onboarding/welcome_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  late final List<String> csvIds;
  late final List<String> activeCsvIds;

  setUpAll(() {
    csvIds = _readCsvScreenIds();
    activeCsvIds = csvIds.where((id) => id != 'SCR-FAT-039').toList();
  });

  test('generatedScreenIds covers every active CSV screen_id (no tombstones)', () {
    expect(generatedScreenIds.length, activeCsvIds.length);
    expect(generatedScreenIds.toSet(), activeCsvIds.toSet());
    expect(generatedScreenIds, isNot(contains('SCR-FAT-039')));
    expect(tombstoneScreenIds, contains('SCR-FAT-039'));
  });

  test('route table length matches active screens (+ gallery)', () {
    final role = RoleController(AppRole.father);
    final router = createAppRouter(roleListenable: role);
    addTearDown(() {
      router.dispose();
      role.dispose();
    });

    // Top-level GoRoutes: gallery + one per active CSV row (tombstones skipped).
    expect(router.configuration.routes.length, activeCsvIds.length + 1);

    final named = router.configuration.routes.whereType<GoRoute>().map((r) => r.name);
    expect(named, isNot(contains('SCR-FAT-039')));
    final paths = router.configuration.routes.whereType<GoRoute>().map((r) => r.path);
    expect(paths, isNot(contains('/scr-fat-039')));
  });

  testWidgets(
    'SCR-SHR-001/002/003/007 + SCR-FAT-001…010 build feature screens; others PlaceholderScreen',
    (tester) async {
      final role = RoleController(AppRole.father);
      final router = createAppRouter(roleListenable: role);
      addTearDown(() {
        router.dispose();
        role.dispose();
      });

      await tester.pumpWidget(_RouterApp(router: router, role: role));
      await tester.pumpAndSettle();

      // Product entry is welcome.
      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(find.textContaining('عائلتي'), findsWidgets);

      router.go('/gallery');
      await tester.pumpAndSettle();
      expect(find.textContaining('عائلتي'), findsWidgets);

      // Pump a representative sample + all owner-only + last to keep CI fast.
      // Wired screens are excluded from PlaceholderScreen assertions.
      const wired = {
        'SCR-SHR-001',
        'SCR-SHR-002',
        'SCR-SHR-003',
        'SCR-SHR-007',
        'SCR-SHR-008',
        'SCR-FAT-001',
        'SCR-FAT-002',
        'SCR-FAT-003',
        'SCR-FAT-004',
        'SCR-FAT-005',
        'SCR-FAT-006',
        'SCR-FAT-007',
        'SCR-FAT-008',
        'SCR-FAT-009',
        'SCR-FAT-010',
        'SCR-FAT-011',
        'SCR-FAT-012',
        'SCR-FAT-013',
        'SCR-FAT-014',
        'SCR-FAT-032',
        'SCR-FAT-034',
        'SCR-FAT-035',
        'SCR-FAT-036',
        'SCR-FAT-037',
        'SCR-FAT-038',
        'SCR-FAT-056',
        'SCR-FAT-057',
        'SCR-FAT-058',
        'SCR-FAT-059',
        'SCR-FAT-060',
        'SCR-FAT-029',
        'SCR-FAT-031',
        'SCR-FAT-067',
        'SCR-FAT-068',
        'SCR-FAT-085',
        'SCR-CHD-001',
        'SCR-CHD-002',
        'SCR-CHD-003',
        'SCR-CHD-004',
        'SCR-CHD-005',
        'SCR-CHD-006',
        'SCR-CHD-007',
        'SCR-CHD-010',
      };
      final sample = <String>{
        csvIds.last,
        'SCR-FAT-011',
        ...ownerOnlyScreenIds,
        ...fatherOnlyScreenIds,
      }.where(activeCsvIds.contains).where((id) => !wired.contains(id));

      for (final id in sample) {
        final path = screenPath(id);
        router.go(path);
        await tester.pumpAndSettle();
        expect(find.byType(PlaceholderScreen), findsOneWidget, reason: path);
        expect(find.text(id), findsWidgets, reason: path);
      }

      router.go(screenPath('SCR-SHR-001'));
      await tester.pumpAndSettle();
      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(find.byType(PlaceholderScreen), findsNothing);

      router.go(screenPath('SCR-SHR-002'));
      await tester.pumpAndSettle();
      expect(find.byType(CreateAccountScreen), findsOneWidget);
      expect(find.byType(PlaceholderScreen), findsNothing);

      router.go(screenPath('SCR-SHR-003'));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(PlaceholderScreen), findsNothing);

      router.go(screenPath('SCR-SHR-007'));
      await tester.pumpAndSettle();
      expect(find.byType(DeviceModeScreen), findsOneWidget);
      expect(find.byType(PlaceholderScreen), findsNothing);

      router.go(screenPath('SCR-SHR-008'));
      await tester.pumpAndSettle();
      expect(find.byType(DeviceUserSwitchScreen), findsOneWidget);
      expect(find.byType(PlaceholderScreen), findsNothing);

      router.go(screenPath('SCR-FAT-001'));
      await tester.pumpAndSettle();
      expect(find.byType(CreateFamilyScreen), findsOneWidget);
      expect(find.byType(PlaceholderScreen), findsNothing);

      router.go(screenPath('SCR-FAT-002'));
      await tester.pumpAndSettle();
      expect(find.byType(SetupWizardScreen), findsOneWidget);
      expect(find.byType(PlaceholderScreen), findsNothing);

      router.go(screenPath('SCR-FAT-003'));
      await tester.pumpAndSettle();
      expect(find.byType(AddChildScreen), findsOneWidget);
      expect(find.byType(PlaceholderScreen), findsNothing);

      // LinkQrScreen owns a periodic timer — avoid pumpAndSettle while it is up.
      router.go(screenPath('SCR-FAT-004'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(LinkQrScreen), findsOneWidget);
      expect(find.byType(PlaceholderScreen), findsNothing);
      router.go(screenPath('SCR-FAT-003'));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.byType(AddChildScreen), findsOneWidget);

      router.go(screenPath('SCR-FAT-005'));
      await tester.pumpAndSettle();
      expect(find.byType(PermissionsExplainerScreen), findsOneWidget);
      expect(find.byType(PlaceholderScreen), findsNothing);

      router.go(screenPath('SCR-FAT-006'));
      await tester.pumpAndSettle();
      expect(find.byType(LinkSuccessScreen), findsOneWidget);
      expect(find.byType(PlaceholderScreen), findsNothing);

      router.go(screenPath('SCR-FAT-007'));
      await tester.pumpAndSettle();
      expect(find.byType(TrialModeScreen), findsOneWidget);
      expect(find.byType(PlaceholderScreen), findsNothing);

      router.go(screenPath('SCR-FAT-008'));
      await tester.pumpAndSettle();
      expect(find.byType(InviteMotherScreen), findsOneWidget);
      expect(find.byType(PlaceholderScreen), findsNothing);

      router.go(screenPath('SCR-FAT-009'));
      await tester.pumpAndSettle();
      expect(find.byType(AcceptMotherInviteScreen), findsOneWidget);
      expect(find.byType(PlaceholderScreen), findsNothing);

      router.go(screenPath('SCR-FAT-010'));
      await tester.pumpAndSettle();
      expect(find.byType(DayBoardScreen), findsOneWidget);
      expect(find.byType(PlaceholderScreen), findsNothing);

      router.go(screenPath('SCR-FAT-011'));
      await tester.pumpAndSettle();
      expect(find.byType(AdvisorSuggestionsScreen), findsOneWidget);
      expect(find.byType(PlaceholderScreen), findsNothing);

      router.go(screenPath('SCR-FAT-012'));
      await tester.pumpAndSettle();
      expect(find.byType(ChildrenListScreen), findsOneWidget);
      expect(find.byType(PlaceholderScreen), findsNothing);

      router.go(screenPath('SCR-FAT-013'));
      await tester.pumpAndSettle();
      expect(find.byType(ChildProfileScreen), findsOneWidget);
      expect(find.byType(PlaceholderScreen), findsNothing);

      router.go(screenPath('SCR-FAT-014'));
      await tester.pumpAndSettle();
      expect(find.byType(LocationMapScreen), findsOneWidget);
      expect(find.byType(PlaceholderScreen), findsNothing);

      router.go(screenPath('SCR-FAT-032'));
      await tester.pumpAndSettle();
      expect(find.byType(ChildScreenTimeScreen), findsOneWidget);
      expect(find.byType(PlaceholderScreen), findsNothing);

      router.go(screenPath('SCR-FAT-034'));
      await tester.pumpAndSettle();
      expect(find.byType(ChildAppsScreen), findsOneWidget);
      expect(find.byType(PlaceholderScreen), findsNothing);

      router.go(screenPath('SCR-FAT-035'));
      await tester.pumpAndSettle();
      expect(find.byType(NewAppApprovalScreen), findsOneWidget);
      expect(find.byType(PlaceholderScreen), findsNothing);

      router.go(screenPath('SCR-FAT-036'));
      await tester.pumpAndSettle();
      expect(find.byType(WebFilterScreen), findsOneWidget);
      expect(find.byType(PlaceholderScreen), findsNothing);

      router.go(screenPath('SCR-FAT-037'));
      await tester.pumpAndSettle();
      expect(find.byType(InstantLockScreen), findsOneWidget);
      expect(find.byType(PlaceholderScreen), findsNothing);

      router.go(screenPath('SCR-FAT-038'));
      await tester.pumpAndSettle();
      expect(find.byType(TamperAlertsScreen), findsOneWidget);
      expect(find.byType(PlaceholderScreen), findsNothing);

      router.go(screenPath('SCR-FAT-040'));
      await tester.pumpAndSettle();
      expect(find.byType(StudioBoardScreen), findsOneWidget);
      expect(find.byType(PlaceholderScreen), findsNothing);

      router.go(screenPath('SCR-FAT-058'));
      await tester.pumpAndSettle();
      expect(find.byType(NotificationPrefsScreen), findsOneWidget);
      expect(find.byType(PlaceholderScreen), findsNothing);

      router.go(screenPath('SCR-FAT-059'));
      await tester.pumpAndSettle();
      expect(find.byType(PrivacyDataScreen), findsOneWidget);
      expect(find.byType(PlaceholderScreen), findsNothing);

      router.go(screenPath('SCR-FAT-029'));
      await tester.pumpAndSettle();
      expect(find.byType(BrainControlScreen), findsOneWidget);
      expect(find.byType(PlaceholderScreen), findsNothing);

      router.go(screenPath('SCR-FAT-031'));
      await tester.pumpAndSettle();
      expect(find.byType(MotherPermissionLevelScreen), findsOneWidget);
      expect(find.byType(PlaceholderScreen), findsNothing);

      router.go(screenPath('SCR-FAT-067'));
      await tester.pumpAndSettle();
      expect(find.byType(SmartSupervisionScreen), findsOneWidget);
      expect(find.byType(PlaceholderScreen), findsNothing);

      router.go(screenPath('SCR-FAT-068'));
      await tester.pumpAndSettle();
      expect(find.byType(PlatformMonitoringScreen), findsOneWidget);
      expect(find.byType(PlaceholderScreen), findsNothing);

      router.go(screenPath('SCR-FAT-085'));
      await tester.pumpAndSettle();
      expect(find.byType(SmartModesScreen), findsOneWidget);
      expect(find.byType(PlaceholderScreen), findsNothing);

      router.go(screenPath('SCR-CHD-002'));
      await tester.pumpAndSettle();
      expect(find.byType(ChildQrScanScreen), findsOneWidget);
      expect(find.byType(PlaceholderScreen), findsNothing);

      router.go(screenPath('SCR-CHD-003'));
      await tester.pumpAndSettle();
      expect(find.byType(TransparencyConsentScreen), findsOneWidget);
      expect(find.byType(PlaceholderScreen), findsNothing);

      router.go(screenPath('SCR-CHD-004'));
      await tester.pumpAndSettle();
      expect(find.byType(ChildDayBoardScreen), findsOneWidget);
      expect(find.byType(PlaceholderScreen), findsNothing);

      router.go(screenPath('SCR-CHD-006'));
      await tester.pumpAndSettle();
      expect(find.byType(ChildSosInProgressScreen), findsOneWidget);
      expect(find.byType(PlaceholderScreen), findsNothing);

      router.go(screenPath('SCR-CHD-007'));
      await tester.pumpAndSettle();
      expect(find.byType(ChildChatsScreen), findsOneWidget);
      expect(find.byType(PlaceholderScreen), findsNothing);

      router.go(screenPath('SCR-CHD-010'));
      await tester.pumpAndSettle();
      expect(find.byType(WhatIsCollectedScreen), findsOneWidget);
      expect(find.byType(PlaceholderScreen), findsNothing);

      router.go(screenPath('SCR-FAT-055'));
      await tester.pumpAndSettle();
      expect(find.byType(CreateTaskScreen), findsOneWidget);
      expect(find.byType(PlaceholderScreen), findsNothing);

      router.go(screenPath('SCR-FAT-060'));
      await tester.pumpAndSettle();
      expect(find.byType(AuditLogScreen), findsOneWidget);
      expect(find.byType(PlaceholderScreen), findsNothing);

      router.go(screenPath('SCR-FAT-056'));
      await tester.pumpAndSettle();
      expect(find.byType(PlansScreen), findsOneWidget);
      expect(find.byType(PlaceholderScreen), findsNothing);

      router.go(screenPath('SCR-FAT-057'));
      await tester.pumpAndSettle();
      expect(find.byType(ManageSubscriptionScreen), findsOneWidget);
      expect(find.byType(PlaceholderScreen), findsNothing);

      // Full table: every active CSV id resolves to a named route.
      for (final id in activeCsvIds) {
        final match = router.configuration.routes.whereType<GoRoute>().any(
          (r) => r.name == id || r.path == screenPath(id),
        );
        expect(match, isTrue, reason: 'missing route for $id');
      }
    },
  );

  testWidgets(
    'SET-018 SCR-FAT-039 deep link redirects to FAT-085 (never a tombstone screen)',
    (tester) async {
      final role = RoleController(AppRole.father);
      final router = createAppRouter(roleListenable: role);
      addTearDown(() {
        router.dispose();
        role.dispose();
      });

      await tester.pumpWidget(_RouterApp(router: router, role: role));
      router.go('/scr-fat-039');
      await tester.pumpAndSettle();

      expect(router.state.uri.path, tombstoneSchoolRedirectTarget);
      expect(find.byType(SmartModesScreen), findsOneWidget);
      expect(find.text('TOMBSTONE'), findsNothing);
      expect(find.byType(PlaceholderScreen), findsNothing);
    },
  );
}

class _RouterApp extends StatelessWidget {
  const _RouterApp({required this.router, required this.role});

  final GoRouter router;
  final RoleController role;

  @override
  Widget build(BuildContext context) {
    return CurrentRole(
      notifier: role,
      child: MaterialApp.router(
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
  }
}

List<String> _readCsvScreenIds() {
  final candidates = [
    File('../prototype/_REGISTRY/screens.csv'),
    File('prototype/_REGISTRY/screens.csv'),
  ];
  File? csv;
  for (final f in candidates) {
    if (f.existsSync()) {
      csv = f;
      break;
    }
  }
  if (csv == null) {
    throw StateError('screens.csv must exist for route tests');
  }
  final lines = csv
      .readAsStringSync()
      .split(RegExp(r'\r?\n'))
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .skip(1);
  return [
    for (final line in lines)
      if (line.startsWith('SCR-')) line.split(',').first.trim(),
  ];
}
