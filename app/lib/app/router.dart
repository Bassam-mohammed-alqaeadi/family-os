// GENERATED — do not edit by hand. Run: dart run tool/gen_routes.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:family_os/app/gallery_screen.dart';
import 'package:family_os/app/placeholder_screen.dart';
import 'package:family_os/app/role_guard.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/shared_onboarding/welcome_screen.dart';
import 'package:family_os/features/shared_onboarding/create_account_screen.dart';
import 'package:family_os/features/shared_onboarding/login_screen.dart';
import 'package:family_os/features/shared_onboarding/device_mode_screen.dart';
import 'package:family_os/features/shared_onboarding/device_user_switch_screen.dart';
import 'package:family_os/features/n05_lock/child_mode_lock_screen.dart';
import 'package:family_os/features/n05_lock/parent_second_key_screen.dart';
import 'package:family_os/features/shared_templates/network_error_template_screen.dart';
import 'package:family_os/features/shared_templates/empty_state_template_screen.dart';
import 'package:family_os/features/n01_linking/create_family_screen.dart';
import 'package:family_os/features/n01_linking/setup_wizard_screen.dart';
import 'package:family_os/features/n01_linking/add_child_screen.dart';
import 'package:family_os/features/n01_linking/link_qr_screen.dart';
import 'package:family_os/features/n01_linking/permissions_explainer_screen.dart';
import 'package:family_os/features/n01_linking/link_success_screen.dart';
import 'package:family_os/features/n01_linking/trial_mode_screen.dart';
import 'package:family_os/features/n01_linking/invite_mother_screen.dart';
import 'package:family_os/features/n01_linking/accept_mother_invite_screen.dart';
import 'package:family_os/features/n01_linking/child_welcome_screen.dart';
import 'package:family_os/features/n01_linking/child_qr_scan_screen.dart';
import 'package:family_os/features/n01_linking/transparency_consent_screen.dart';
import 'package:family_os/features/n02_day/day_board_screen.dart';
import 'package:family_os/features/n02_day/children_list_screen.dart';
import 'package:family_os/features/n02_day/child_profile_screen.dart';
import 'package:family_os/features/n02_day/location_map_screen.dart';
import 'package:family_os/features/n02_day/location_history_screen.dart';
import 'package:family_os/features/n02_day/safe_zones_screen.dart';
import 'package:family_os/features/n02_day/create_safe_zone_screen.dart';
import 'package:family_os/features/n02_day/alerts_hub_screen.dart';
import 'package:family_os/features/n02_day/alert_detail_screen.dart';
import 'package:family_os/features/n02_day/conversations_list_screen.dart';
import 'package:family_os/features/n02_day/child_chats_screen.dart';
import 'package:family_os/features/n02_day/child_conversation_screen.dart';
import 'package:family_os/features/n02_day/child_active_call_screen.dart';
import 'package:family_os/features/n02_day/conversation_screen.dart';
import 'package:family_os/features/n02_day/active_call_screen.dart';
import 'package:family_os/features/n02_day/call_history_screen.dart';
import 'package:family_os/features/n02_day/child_day_board_screen.dart';
import 'package:family_os/features/n02_day/request_inbox_screen.dart';
import 'package:family_os/features/n03_screen_time/child_screen_time_screen.dart';
import 'package:family_os/features/n03_screen_time/child_apps_screen.dart';
import 'package:family_os/features/n03_screen_time/new_app_approval_screen.dart';
import 'package:family_os/features/n03_screen_time/time_expiry_screen.dart';
import 'package:family_os/features/n12_devices/settings_hub_screen.dart';
import 'package:family_os/features/n12_devices/device_health_detail_screen.dart';
import 'package:family_os/features/n12_devices/family_members_screen.dart';
import 'package:family_os/features/n12_devices/mother_permission_level_screen.dart';
import 'package:family_os/features/n12_devices/language_help_screen.dart';
import 'package:family_os/features/n04_web_filter/web_filter_screen.dart';
import 'package:family_os/features/n05_lock/instant_lock_screen.dart';
import 'package:family_os/features/n05_lock/tamper_alerts_screen.dart';
import 'package:family_os/features/n14_studio/studio_board_screen.dart';
import 'package:family_os/features/n14_studio/add_from_source_screen.dart';
import 'package:family_os/features/n14_studio/studio_camera_capture_screen.dart';
import 'package:family_os/features/n14_studio/generation_outputs_screen.dart';
import 'package:family_os/features/n14_studio/preview_approve_screen.dart';
import 'package:family_os/features/n14_studio/attribution_reward_screen.dart';
import 'package:family_os/features/n14_studio/community_library_screen.dart';
import 'package:family_os/features/n14_studio/learning_path_screen.dart';
import 'package:family_os/features/n14_studio/materials_lessons_screen.dart';
import 'package:family_os/features/n14_studio/create_assignment_screen.dart';
import 'package:family_os/features/n14_studio/results_followup_screen.dart';
import 'package:family_os/features/n14_studio/focus_report_screen.dart';
import 'package:family_os/features/n15_calendar/family_calendar_screen.dart';
import 'package:family_os/features/n15_calendar/add_event_screen.dart';
import 'package:family_os/features/n16_tasks/family_tasks_screen.dart';
import 'package:family_os/features/n16_tasks/create_task_screen.dart';
import 'package:family_os/features/n06_notifications/notification_prefs_screen.dart';
import 'package:family_os/features/n07_privacy/privacy_data_screen.dart';
import 'package:family_os/features/n07_privacy/audit_log_screen.dart';
import 'package:family_os/features/n07_advisor/brain_control_screen.dart';
import 'package:family_os/features/n07_advisor/advisor_suggestions_screen.dart';
import 'package:family_os/features/n07_advisor/my_advisor_screen.dart';
import 'package:family_os/features/n07_advisor/family_patterns_screen.dart';
import 'package:family_os/features/n07_advisor/individual_timeline_screen.dart';
import 'package:family_os/features/n08_platform/smart_supervision_screen.dart';
import 'package:family_os/features/n08_platform/platform_monitoring_screen.dart';
import 'package:family_os/features/n09_smart_modes/smart_modes_screen.dart';
import 'package:family_os/features/n10_emergency/emergency_setup_screen.dart';
import 'package:family_os/features/n10_emergency/sos_alert_screen.dart';
import 'package:family_os/features/n10_emergency/child_sos_button_screen.dart';
import 'package:family_os/features/n10_emergency/child_sos_in_progress_screen.dart';
import 'package:family_os/features/n11_billing/plans_screen.dart';
import 'package:family_os/features/n11_billing/manage_subscription_screen.dart';
import 'package:family_os/features/n07_privacy/what_is_collected_screen.dart';
import 'package:family_os/features/n13_coming_soon/coming_soon_screen.dart';

/// Active registry screen_ids mirrored as routes (129 rows).
/// Tombstones (ADR-034) are excluded — see [tombstoneScreenIds].
const List<String> generatedScreenIds = [
  'SCR-SHR-001',
  'SCR-SHR-002',
  'SCR-SHR-003',
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
  'SCR-FAT-015',
  'SCR-FAT-016',
  'SCR-FAT-017',
  'SCR-FAT-018',
  'SCR-FAT-028',
  'SCR-FAT-019',
  'SCR-FAT-020',
  'SCR-FAT-021',
  'SCR-FAT-022',
  'SCR-FAT-023',
  'SCR-FAT-024',
  'SCR-FAT-025',
  'SCR-FAT-026',
  'SCR-FAT-027',
  'SCR-FAT-029',
  'SCR-CHD-001',
  'SCR-CHD-002',
  'SCR-CHD-003',
  'SCR-CHD-004',
  'SCR-CHD-005',
  'SCR-CHD-006',
  'SCR-CHD-007',
  'SCR-CHD-008',
  'SCR-CHD-009',
  'SCR-CHD-010',
  'SCR-SHR-005',
  'SCR-SHR-006',
  'SCR-SHR-007',
  'SCR-SHR-008',
  'SCR-CHD-011',
  'SCR-FAT-030',
  'SCR-FAT-031',
  'SCR-FAT-032',
  'SCR-FAT-033',
  'SCR-FAT-034',
  'SCR-FAT-035',
  'SCR-FAT-036',
  'SCR-FAT-037',
  'SCR-FAT-038',
  'SCR-FAT-040',
  'SCR-FAT-041',
  'SCR-FAT-042',
  'SCR-FAT-043',
  'SCR-FAT-044',
  'SCR-FAT-045',
  'SCR-FAT-046',
  'SCR-FAT-047',
  'SCR-FAT-048',
  'SCR-FAT-049',
  'SCR-FAT-050',
  'SCR-FAT-051',
  'SCR-FAT-052',
  'SCR-FAT-053',
  'SCR-FAT-054',
  'SCR-FAT-055',
  'SCR-FAT-056',
  'SCR-FAT-057',
  'SCR-FAT-058',
  'SCR-FAT-059',
  'SCR-FAT-060',
  'SCR-FAT-061',
  'SCR-FAT-062',
  'SCR-FAT-063',
  'SCR-FAT-064',
  'SCR-CHD-012',
  'SCR-CHD-013',
  'SCR-CHD-014',
  'SCR-CHD-015',
  'SCR-CHD-016',
  'SCR-CHD-017',
  'SCR-CHD-018',
  'SCR-CHD-019',
  'SCR-CHD-020',
  'SCR-CHD-021',
  'SCR-CHD-022',
  'SCR-CHD-023',
  'SCR-CHD-024',
  'SCR-FAT-065',
  'SCR-FAT-066',
  'SCR-FAT-067',
  'SCR-FAT-068',
  'SCR-FAT-069',
  'SCR-FAT-070',
  'SCR-FAT-071',
  'SCR-FAT-072',
  'SCR-FAT-073',
  'SCR-FAT-074',
  'SCR-FAT-076',
  'SCR-FAT-075',
  'SCR-CHD-025',
  'SCR-CHD-026',
  'SCR-CHD-027',
  'SCR-CHD-028',
  'SCR-CHD-029',
  'SCR-CHD-030',
  'SCR-CHD-031',
  'SCR-FAT-077',
  'SCR-FAT-078',
  'SCR-FAT-079',
  'SCR-FAT-080',
  'SCR-FAT-081',
  'SCR-FAT-082',
  'SCR-FAT-083',
  'SCR-FAT-084',
  'SCR-CHD-032',
  'SCR-CHD-033',
  'SCR-CHD-034',
  'SCR-CHD-035',
  'SCR-CHD-036',
  'SCR-CHD-037',
  'SCR-FAT-085',
  'SCR-FAT-086',
];

/// Tombstone screen_ids kept in CSV historically but never routed (ADR-034).
const List<String> tombstoneScreenIds = [
  'SCR-FAT-039',
];

/// Deep-link paths for tombstones — redirect only, never a screen builder.
const List<String> tombstonePaths = [
  '/scr-fat-039',
];

/// SET-018 / ADR-034: school lives on FAT-085; FAT-039 deep links land here.
const String tombstoneSchoolRedirectTarget = '/scr-fat-085';

/// Builds the app [GoRouter] with gallery + every **active** CSV screen route.
///
/// Product entry is welcome (`/scr-shr-001`); gallery remains at `/gallery`.
/// Tombstone deep links (e.g. `/scr-fat-039`) redirect to [tombstoneSchoolRedirectTarget].
GoRouter createAppRouter({
  required ValueListenable<AppRole> roleListenable,
  String initialLocation = '/scr-shr-001',
}) {
  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: roleListenable,
    redirect: (context, state) {
      final path = state.uri.path;
      if (tombstonePaths.contains(path)) {
        return tombstoneSchoolRedirectTarget;
      }
      return roleGuardRedirect(state, roleListenable.value);
    },
    routes: [
      GoRoute(
        path: '/gallery',
        name: 'gallery',
        builder: (context, state) => const GalleryScreen(),
      ),
    GoRoute(
      path: '/scr-shr-001',
      name: 'SCR-SHR-001',
      builder: (context, state) => WelcomeScreen(),
    ),
    GoRoute(
      path: '/scr-shr-002',
      name: 'SCR-SHR-002',
      builder: (context, state) => CreateAccountScreen(),
    ),
    GoRoute(
      path: '/scr-shr-003',
      name: 'SCR-SHR-003',
      builder: (context, state) => LoginScreen(),
    ),
    GoRoute(
      path: '/scr-fat-001',
      name: 'SCR-FAT-001',
      builder: (context, state) => CreateFamilyScreen(),
    ),
    GoRoute(
      path: '/scr-fat-002',
      name: 'SCR-FAT-002',
      builder: (context, state) => SetupWizardScreen(),
    ),
    GoRoute(
      path: '/scr-fat-003',
      name: 'SCR-FAT-003',
      builder: (context, state) => AddChildScreen(),
    ),
    GoRoute(
      path: '/scr-fat-004',
      name: 'SCR-FAT-004',
      builder: (context, state) => LinkQrScreen(),
    ),
    GoRoute(
      path: '/scr-fat-005',
      name: 'SCR-FAT-005',
      builder: (context, state) => PermissionsExplainerScreen(),
    ),
    GoRoute(
      path: '/scr-fat-006',
      name: 'SCR-FAT-006',
      builder: (context, state) => LinkSuccessScreen(),
    ),
    GoRoute(
      path: '/scr-fat-007',
      name: 'SCR-FAT-007',
      builder: (context, state) => TrialModeScreen(),
    ),
    GoRoute(
      path: '/scr-fat-008',
      name: 'SCR-FAT-008',
      builder: (context, state) => InviteMotherScreen(),
    ),
    GoRoute(
      path: '/scr-fat-009',
      name: 'SCR-FAT-009',
      builder: (context, state) => AcceptMotherInviteScreen(),
    ),
    GoRoute(
      path: '/scr-fat-010',
      name: 'SCR-FAT-010',
      builder: (context, state) => DayBoardScreen(),
    ),
    GoRoute(
      path: '/scr-fat-011',
      name: 'SCR-FAT-011',
      builder: (context, state) => AdvisorSuggestionsScreen(),
    ),
    GoRoute(
      path: '/scr-fat-012',
      name: 'SCR-FAT-012',
      builder: (context, state) => ChildrenListScreen(),
    ),
    GoRoute(
      path: '/scr-fat-013',
      name: 'SCR-FAT-013',
      builder: (context, state) => ChildProfileScreen(childId: state.uri.queryParameters['childId']),
    ),
    GoRoute(
      path: '/scr-fat-014',
      name: 'SCR-FAT-014',
      builder: (context, state) => LocationMapScreen(childId: state.uri.queryParameters['childId']),
    ),
    GoRoute(
      path: '/scr-fat-015',
      name: 'SCR-FAT-015',
      builder: (context, state) => LocationHistoryScreen(childId: state.uri.queryParameters['childId']),
    ),
    GoRoute(
      path: '/scr-fat-016',
      name: 'SCR-FAT-016',
      builder: (context, state) => SafeZonesScreen(childId: state.uri.queryParameters['childId']),
    ),
    GoRoute(
      path: '/scr-fat-017',
      name: 'SCR-FAT-017',
      builder: (context, state) => CreateSafeZoneScreen(childId: state.uri.queryParameters['childId']),
    ),
    GoRoute(
      path: '/scr-fat-018',
      name: 'SCR-FAT-018',
      builder: (context, state) => SosAlertScreen(alertId: state.uri.queryParameters['alertId'], childId: state.uri.queryParameters['childId']),
    ),
    GoRoute(
      path: '/scr-fat-028',
      name: 'SCR-FAT-028',
      builder: (context, state) => EmergencySetupScreen(),
    ),
    GoRoute(
      path: '/scr-fat-019',
      name: 'SCR-FAT-019',
      builder: (context, state) => AlertsHubScreen(),
    ),
    GoRoute(
      path: '/scr-fat-020',
      name: 'SCR-FAT-020',
      builder: (context, state) => AlertDetailScreen(alertId: state.uri.queryParameters['alertId'], alertKind: state.uri.queryParameters['alertKind'] ?? state.uri.queryParameters['kind']),
    ),
    GoRoute(
      path: '/scr-fat-021',
      name: 'SCR-FAT-021',
      builder: (context, state) => ConversationsListScreen(),
    ),
    GoRoute(
      path: '/scr-fat-022',
      name: 'SCR-FAT-022',
      builder: (context, state) => ConversationScreen(chatWith: state.uri.queryParameters['chatWith']),
    ),
    GoRoute(
      path: '/scr-fat-023',
      name: 'SCR-FAT-023',
      builder: (context, state) => ActiveCallScreen(callId: state.uri.queryParameters['callId']),
    ),
    GoRoute(
      path: '/scr-fat-024',
      name: 'SCR-FAT-024',
      builder: (context, state) => CallHistoryScreen(),
    ),
    GoRoute(
      path: '/scr-fat-025',
      name: 'SCR-FAT-025',
      builder: (context, state) => SettingsHubScreen(),
    ),
    GoRoute(
      path: '/scr-fat-026',
      name: 'SCR-FAT-026',
      builder: (context, state) => DeviceHealthDetailScreen(deviceId: state.uri.queryParameters['deviceId']),
    ),
    GoRoute(
      path: '/scr-fat-027',
      name: 'SCR-FAT-027',
      builder: (context, state) => FamilyMembersScreen(),
    ),
    GoRoute(
      path: '/scr-fat-029',
      name: 'SCR-FAT-029',
      builder: (context, state) => BrainControlScreen(),
    ),
    GoRoute(
      path: '/scr-chd-001',
      name: 'SCR-CHD-001',
      builder: (context, state) => ChildWelcomeScreen(),
    ),
    GoRoute(
      path: '/scr-chd-002',
      name: 'SCR-CHD-002',
      builder: (context, state) => ChildQrScanScreen(),
    ),
    GoRoute(
      path: '/scr-chd-003',
      name: 'SCR-CHD-003',
      builder: (context, state) => TransparencyConsentScreen(),
    ),
    GoRoute(
      path: '/scr-chd-004',
      name: 'SCR-CHD-004',
      builder: (context, state) => ChildDayBoardScreen(),
    ),
    GoRoute(
      path: '/scr-chd-005',
      name: 'SCR-CHD-005',
      builder: (context, state) => ChildSosButtonScreen(),
    ),
    GoRoute(
      path: '/scr-chd-006',
      name: 'SCR-CHD-006',
      builder: (context, state) => ChildSosInProgressScreen(alertId: state.uri.queryParameters['alertId'], childId: state.uri.queryParameters['childId']),
    ),
    GoRoute(
      path: '/scr-chd-007',
      name: 'SCR-CHD-007',
      builder: (context, state) => ChildChatsScreen(),
    ),
    GoRoute(
      path: '/scr-chd-008',
      name: 'SCR-CHD-008',
      builder: (context, state) => ChildConversationScreen(chatWith: state.uri.queryParameters['chatWith']),
    ),
    GoRoute(
      path: '/scr-chd-009',
      name: 'SCR-CHD-009',
      builder: (context, state) => ChildActiveCallScreen(callId: state.uri.queryParameters['callId']),
    ),
    GoRoute(
      path: '/scr-chd-010',
      name: 'SCR-CHD-010',
      builder: (context, state) => WhatIsCollectedScreen(),
    ),
    GoRoute(
      path: '/scr-shr-005',
      name: 'SCR-SHR-005',
      builder: (context, state) => NetworkErrorTemplateScreen(),
    ),
    GoRoute(
      path: '/scr-shr-006',
      name: 'SCR-SHR-006',
      builder: (context, state) => EmptyStateTemplateScreen(),
    ),
    GoRoute(
      path: '/scr-shr-007',
      name: 'SCR-SHR-007',
      builder: (context, state) => DeviceModeScreen(),
    ),
    GoRoute(
      path: '/scr-shr-008',
      name: 'SCR-SHR-008',
      builder: (context, state) => DeviceUserSwitchScreen(),
    ),
    GoRoute(
      path: '/scr-chd-011',
      name: 'SCR-CHD-011',
      builder: (context, state) => ChildModeLockScreen(),
    ),
    GoRoute(
      path: '/scr-fat-030',
      name: 'SCR-FAT-030',
      builder: (context, state) => ParentSecondKeyScreen(),
    ),
    GoRoute(
      path: '/scr-fat-031',
      name: 'SCR-FAT-031',
      builder: (context, state) => MotherPermissionLevelScreen(),
    ),
    GoRoute(
      path: '/scr-fat-032',
      name: 'SCR-FAT-032',
      builder: (context, state) => ChildScreenTimeScreen(),
    ),
    GoRoute(
      path: '/scr-fat-033',
      name: 'SCR-FAT-033',
      builder: (context, state) => RequestInboxScreen(),
    ),
    GoRoute(
      path: '/scr-fat-034',
      name: 'SCR-FAT-034',
      builder: (context, state) => ChildAppsScreen(childId: state.uri.queryParameters['childId']),
    ),
    GoRoute(
      path: '/scr-fat-035',
      name: 'SCR-FAT-035',
      builder: (context, state) => NewAppApprovalScreen(childId: state.uri.queryParameters['childId'], appId: state.uri.queryParameters['appId']),
    ),
    GoRoute(
      path: '/scr-fat-036',
      name: 'SCR-FAT-036',
      builder: (context, state) => WebFilterScreen(),
    ),
    GoRoute(
      path: '/scr-fat-037',
      name: 'SCR-FAT-037',
      builder: (context, state) => InstantLockScreen(),
    ),
    GoRoute(
      path: '/scr-fat-038',
      name: 'SCR-FAT-038',
      builder: (context, state) => TamperAlertsScreen(childId: state.uri.queryParameters['childId']),
    ),
    GoRoute(
      path: '/scr-fat-040',
      name: 'SCR-FAT-040',
      builder: (context, state) => StudioBoardScreen(),
    ),
    GoRoute(
      path: '/scr-fat-041',
      name: 'SCR-FAT-041',
      builder: (context, state) => AddFromSourceScreen(),
    ),
    GoRoute(
      path: '/scr-fat-042',
      name: 'SCR-FAT-042',
      builder: (context, state) => StudioCameraCaptureScreen(),
    ),
    GoRoute(
      path: '/scr-fat-043',
      name: 'SCR-FAT-043',
      builder: (context, state) => GenerationOutputsScreen(),
    ),
    GoRoute(
      path: '/scr-fat-044',
      name: 'SCR-FAT-044',
      builder: (context, state) => PreviewApproveScreen(),
    ),
    GoRoute(
      path: '/scr-fat-045',
      name: 'SCR-FAT-045',
      builder: (context, state) => AttributionRewardScreen(),
    ),
    GoRoute(
      path: '/scr-fat-046',
      name: 'SCR-FAT-046',
      builder: (context, state) => CommunityLibraryScreen(),
    ),
    GoRoute(
      path: '/scr-fat-047',
      name: 'SCR-FAT-047',
      builder: (context, state) => LearningPathScreen(),
    ),
    GoRoute(
      path: '/scr-fat-048',
      name: 'SCR-FAT-048',
      builder: (context, state) => MaterialsLessonsScreen(),
    ),
    GoRoute(
      path: '/scr-fat-049',
      name: 'SCR-FAT-049',
      builder: (context, state) => CreateAssignmentScreen(),
    ),
    GoRoute(
      path: '/scr-fat-050',
      name: 'SCR-FAT-050',
      builder: (context, state) => ResultsFollowupScreen(),
    ),
    GoRoute(
      path: '/scr-fat-051',
      name: 'SCR-FAT-051',
      builder: (context, state) => FocusReportScreen(),
    ),
    GoRoute(
      path: '/scr-fat-052',
      name: 'SCR-FAT-052',
      builder: (context, state) => FamilyCalendarScreen(),
    ),
    GoRoute(
      path: '/scr-fat-053',
      name: 'SCR-FAT-053',
      builder: (context, state) => AddEventScreen(),
    ),
    GoRoute(
      path: '/scr-fat-054',
      name: 'SCR-FAT-054',
      builder: (context, state) => FamilyTasksScreen(),
    ),
    GoRoute(
      path: '/scr-fat-055',
      name: 'SCR-FAT-055',
      builder: (context, state) => CreateTaskScreen(),
    ),
    GoRoute(
      path: '/scr-fat-056',
      name: 'SCR-FAT-056',
      builder: (context, state) => PlansScreen(),
    ),
    GoRoute(
      path: '/scr-fat-057',
      name: 'SCR-FAT-057',
      builder: (context, state) => ManageSubscriptionScreen(),
    ),
    GoRoute(
      path: '/scr-fat-058',
      name: 'SCR-FAT-058',
      builder: (context, state) => NotificationPrefsScreen(),
    ),
    GoRoute(
      path: '/scr-fat-059',
      name: 'SCR-FAT-059',
      builder: (context, state) => PrivacyDataScreen(),
    ),
    GoRoute(
      path: '/scr-fat-060',
      name: 'SCR-FAT-060',
      builder: (context, state) => AuditLogScreen(),
    ),
    GoRoute(
      path: '/scr-fat-061',
      name: 'SCR-FAT-061',
      builder: (context, state) => LanguageHelpScreen(),
    ),
    GoRoute(
      path: '/scr-fat-062',
      name: 'SCR-FAT-062',
      builder: (context, state) => FamilyPatternsScreen(),
    ),
    GoRoute(
      path: '/scr-fat-063',
      name: 'SCR-FAT-063',
      builder: (context, state) => IndividualTimelineScreen(),
    ),
    GoRoute(
      path: '/scr-fat-064',
      name: 'SCR-FAT-064',
      builder: (context, state) => const PlaceholderScreen(
        screenId: 'SCR-FAT-064',
        title: 'خرائط المعرفة',
      ),
    ),
    GoRoute(
      path: '/scr-chd-012',
      name: 'SCR-CHD-012',
      builder: (context, state) => const PlaceholderScreen(
        screenId: 'SCR-CHD-012',
        title: 'تعلّمي — الرئيسة',
      ),
    ),
    GoRoute(
      path: '/scr-chd-013',
      name: 'SCR-CHD-013',
      builder: (context, state) => const PlaceholderScreen(
        screenId: 'SCR-CHD-013',
        title: 'الدرس',
      ),
    ),
    GoRoute(
      path: '/scr-chd-014',
      name: 'SCR-CHD-014',
      builder: (context, state) => const PlaceholderScreen(
        screenId: 'SCR-CHD-014',
        title: 'واجبي',
      ),
    ),
    GoRoute(
      path: '/scr-chd-015',
      name: 'SCR-CHD-015',
      builder: (context, state) => const PlaceholderScreen(
        screenId: 'SCR-CHD-015',
        title: 'الاختبار',
      ),
    ),
    GoRoute(
      path: '/scr-chd-016',
      name: 'SCR-CHD-016',
      builder: (context, state) => const PlaceholderScreen(
        screenId: 'SCR-CHD-016',
        title: 'نتيجتي',
      ),
    ),
    GoRoute(
      path: '/scr-chd-017',
      name: 'SCR-CHD-017',
      builder: (context, state) => const PlaceholderScreen(
        screenId: 'SCR-CHD-017',
        title: 'معلمي الذكي',
      ),
    ),
    GoRoute(
      path: '/scr-chd-018',
      name: 'SCR-CHD-018',
      builder: (context, state) => const PlaceholderScreen(
        screenId: 'SCR-CHD-018',
        title: 'وضع التركيز',
      ),
    ),
    GoRoute(
      path: '/scr-chd-019',
      name: 'SCR-CHD-019',
      builder: (context, state) => const PlaceholderScreen(
        screenId: 'SCR-CHD-019',
        title: 'نقاطي وشاراتي',
      ),
    ),
    GoRoute(
      path: '/scr-chd-020',
      name: 'SCR-CHD-020',
      builder: (context, state) => const PlaceholderScreen(
        screenId: 'SCR-CHD-020',
        title: 'طلب وقت إضافي',
      ),
    ),
    GoRoute(
      path: '/scr-chd-021',
      name: 'SCR-CHD-021',
      builder: (context, state) => TimeExpiryScreen(),
    ),
    GoRoute(
      path: '/scr-chd-022',
      name: 'SCR-CHD-022',
      builder: (context, state) => const PlaceholderScreen(
        screenId: 'SCR-CHD-022',
        title: 'مهامي',
      ),
    ),
    GoRoute(
      path: '/scr-chd-023',
      name: 'SCR-CHD-023',
      builder: (context, state) => const PlaceholderScreen(
        screenId: 'SCR-CHD-023',
        title: 'مشاركة وسائط',
      ),
    ),
    GoRoute(
      path: '/scr-chd-024',
      name: 'SCR-CHD-024',
      builder: (context, state) => const PlaceholderScreen(
        screenId: 'SCR-CHD-024',
        title: 'أنا وصلت + موقعي',
      ),
    ),
    GoRoute(
      path: '/scr-fat-065',
      name: 'SCR-FAT-065',
      builder: (context, state) => const PlaceholderScreen(
        screenId: 'SCR-FAT-065',
        title: 'التنبيهات الذكية',
      ),
    ),
    GoRoute(
      path: '/scr-fat-066',
      name: 'SCR-FAT-066',
      builder: (context, state) => const PlaceholderScreen(
        screenId: 'SCR-FAT-066',
        title: 'تفصيل التنبيه وخطوة الحوار',
      ),
    ),
    GoRoute(
      path: '/scr-fat-067',
      name: 'SCR-FAT-067',
      builder: (context, state) => SmartSupervisionScreen(),
    ),
    GoRoute(
      path: '/scr-fat-068',
      name: 'SCR-FAT-068',
      builder: (context, state) => PlatformMonitoringScreen(),
    ),
    GoRoute(
      path: '/scr-fat-069',
      name: 'SCR-FAT-069',
      builder: (context, state) => const PlaceholderScreen(
        screenId: 'SCR-FAT-069',
        title: 'تقرير استخدام الابن',
      ),
    ),
    GoRoute(
      path: '/scr-fat-070',
      name: 'SCR-FAT-070',
      builder: (context, state) => const PlaceholderScreen(
        screenId: 'SCR-FAT-070',
        title: 'الدائرة الخارجية',
      ),
    ),
    GoRoute(
      path: '/scr-fat-071',
      name: 'SCR-FAT-071',
      builder: (context, state) => const PlaceholderScreen(
        screenId: 'SCR-FAT-071',
        title: 'موافقة طلب صديق',
      ),
    ),
    GoRoute(
      path: '/scr-fat-072',
      name: 'SCR-FAT-072',
      builder: (context, state) => const PlaceholderScreen(
        screenId: 'SCR-FAT-072',
        title: 'متابعة حفظ القرآن',
      ),
    ),
    GoRoute(
      path: '/scr-fat-073',
      name: 'SCR-FAT-073',
      builder: (context, state) => const PlaceholderScreen(
        screenId: 'SCR-FAT-073',
        title: 'التقرير الأسبوعي بتوصية',
      ),
    ),
    GoRoute(
      path: '/scr-fat-074',
      name: 'SCR-FAT-074',
      builder: (context, state) => const PlaceholderScreen(
        screenId: 'SCR-FAT-074',
        title: 'عقل عائلتي (المساعد الذكي)',
      ),
    ),
    GoRoute(
      path: '/scr-fat-076',
      name: 'SCR-FAT-076',
      builder: (context, state) => const PlaceholderScreen(
        screenId: 'SCR-FAT-076',
        title: 'إخطارات الذكاء للأم',
      ),
    ),
    GoRoute(
      path: '/scr-fat-075',
      name: 'SCR-FAT-075',
      builder: (context, state) => ComingSoonScreen(),
    ),
    GoRoute(
      path: '/scr-chd-025',
      name: 'SCR-CHD-025',
      builder: (context, state) => const PlaceholderScreen(
        screenId: 'SCR-CHD-025',
        title: 'وردي — حفظ وتلاوة',
      ),
    ),
    GoRoute(
      path: '/scr-chd-026',
      name: 'SCR-CHD-026',
      builder: (context, state) => const PlaceholderScreen(
        screenId: 'SCR-CHD-026',
        title: 'حفظي وتقدمي',
      ),
    ),
    GoRoute(
      path: '/scr-chd-027',
      name: 'SCR-CHD-027',
      builder: (context, state) => const PlaceholderScreen(
        screenId: 'SCR-CHD-027',
        title: 'أذكاري اليومية',
      ),
    ),
    GoRoute(
      path: '/scr-chd-028',
      name: 'SCR-CHD-028',
      builder: (context, state) => const PlaceholderScreen(
        screenId: 'SCR-CHD-028',
        title: 'خطتي الذكية',
      ),
    ),
    GoRoute(
      path: '/scr-chd-029',
      name: 'SCR-CHD-029',
      builder: (context, state) => const PlaceholderScreen(
        screenId: 'SCR-CHD-029',
        title: 'مراجعة اليوم',
      ),
    ),
    GoRoute(
      path: '/scr-chd-030',
      name: 'SCR-CHD-030',
      builder: (context, state) => const PlaceholderScreen(
        screenId: 'SCR-CHD-030',
        title: 'أصدقائي',
      ),
    ),
    GoRoute(
      path: '/scr-chd-031',
      name: 'SCR-CHD-031',
      builder: (context, state) => const PlaceholderScreen(
        screenId: 'SCR-CHD-031',
        title: 'قادم لك 🎁',
      ),
    ),
    GoRoute(
      path: '/scr-fat-077',
      name: 'SCR-FAT-077',
      builder: (context, state) => const PlaceholderScreen(
        screenId: 'SCR-FAT-077',
        title: 'السلامة على الطريق',
      ),
    ),
    GoRoute(
      path: '/scr-fat-078',
      name: 'SCR-FAT-078',
      builder: (context, state) => const PlaceholderScreen(
        screenId: 'SCR-FAT-078',
        title: 'فلترة الراوتر المنزلي',
      ),
    ),
    GoRoute(
      path: '/scr-fat-079',
      name: 'SCR-FAT-079',
      builder: (context, state) => MyAdvisorScreen(),
    ),
    GoRoute(
      path: '/scr-fat-080',
      name: 'SCR-FAT-080',
      builder: (context, state) => const PlaceholderScreen(
        screenId: 'SCR-FAT-080',
        title: 'ماذا فعل المساعد',
      ),
    ),
    GoRoute(
      path: '/scr-fat-081',
      name: 'SCR-FAT-081',
      builder: (context, state) => const PlaceholderScreen(
        screenId: 'SCR-FAT-081',
        title: 'مقارنة الأقران',
      ),
    ),
    GoRoute(
      path: '/scr-fat-082',
      name: 'SCR-FAT-082',
      builder: (context, state) => const PlaceholderScreen(
        screenId: 'SCR-FAT-082',
        title: 'موزع المهام الذكي',
      ),
    ),
    GoRoute(
      path: '/scr-fat-083',
      name: 'SCR-FAT-083',
      builder: (context, state) => const PlaceholderScreen(
        screenId: 'SCR-FAT-083',
        title: 'المحادثة الصوتية مع العقل',
      ),
    ),
    GoRoute(
      path: '/scr-fat-084',
      name: 'SCR-FAT-084',
      builder: (context, state) => const PlaceholderScreen(
        screenId: 'SCR-FAT-084',
        title: 'مشروع بمراحل',
      ),
    ),
    GoRoute(
      path: '/scr-chd-032',
      name: 'SCR-CHD-032',
      builder: (context, state) => const PlaceholderScreen(
        screenId: 'SCR-CHD-032',
        title: 'تلاوتي الذكية',
      ),
    ),
    GoRoute(
      path: '/scr-chd-033',
      name: 'SCR-CHD-033',
      builder: (context, state) => const PlaceholderScreen(
        screenId: 'SCR-CHD-033',
        title: 'قصصي التفاعلية',
      ),
    ),
    GoRoute(
      path: '/scr-chd-034',
      name: 'SCR-CHD-034',
      builder: (context, state) => const PlaceholderScreen(
        screenId: 'SCR-CHD-034',
        title: 'التحديات العائلية',
      ),
    ),
    GoRoute(
      path: '/scr-chd-035',
      name: 'SCR-CHD-035',
      builder: (context, state) => const PlaceholderScreen(
        screenId: 'SCR-CHD-035',
        title: 'أصوات التركيز',
      ),
    ),
    GoRoute(
      path: '/scr-chd-036',
      name: 'SCR-CHD-036',
      builder: (context, state) => const PlaceholderScreen(
        screenId: 'SCR-CHD-036',
        title: 'مرح المكالمة',
      ),
    ),
    GoRoute(
      path: '/scr-chd-037',
      name: 'SCR-CHD-037',
      builder: (context, state) => const PlaceholderScreen(
        screenId: 'SCR-CHD-037',
        title: 'ملصقاتي وخلفياتي',
      ),
    ),
    GoRoute(
      path: '/scr-fat-085',
      name: 'SCR-FAT-085',
      builder: (context, state) => SmartModesScreen(),
    ),
    GoRoute(
      path: '/scr-fat-086',
      name: 'SCR-FAT-086',
      builder: (context, state) => const PlaceholderScreen(
        screenId: 'SCR-FAT-086',
        title: 'لحظات عائلتنا',
      ),
    ),
    ],
  );
}

/// Shared localization delegates for [MaterialApp.router].
List<LocalizationsDelegate<dynamic>> get appLocalizationsDelegates =>
    const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ];
