// ignore_for_file: avoid_print

import 'dart:io';

/// Generates `lib/app/router.dart` and `lib/app/shell_config.dart`
/// from `prototype/_REGISTRY/screens.csv`.
///
/// Run from `app/`:
///   dart run tool/gen_routes.dart
///
/// Special-case screens (survive regenerate) live in [screenBuilders].
void main(List<String> args) {
  final csvFile = _resolveScreensCsv();
  if (!csvFile.existsSync()) {
    stderr.writeln('screens.csv not found. Looked for: ${csvFile.path}');
    exit(1);
  }

  final rows = _parseScreensCsv(csvFile.readAsStringSync());
  if (rows.isEmpty) {
    stderr.writeln('No screen rows parsed from ${csvFile.path}');
    exit(1);
  }

  final outFile = File(
    '${Directory.current.path}${Platform.pathSeparator}lib'
    '${Platform.pathSeparator}app${Platform.pathSeparator}router.dart',
  );
  outFile.parent.createSync(recursive: true);
  final activeCount = rows.where((r) => !r.isTombstone).length;
  final tombstoneCount = rows.length - activeCount;
  outFile.writeAsStringSync(_generateRouterDart(rows));
  stdout.writeln(
    'Wrote ${outFile.path} ($activeCount active routes + /gallery'
    '${tombstoneCount > 0 ? '; skipped $tombstoneCount tombstone(s)' : ''})',
  );

  final shellFile = File(
    '${Directory.current.path}${Platform.pathSeparator}lib'
    '${Platform.pathSeparator}app${Platform.pathSeparator}shell_config.dart',
  );
  shellFile.writeAsStringSync(_generateShellConfigDart(rows));
  stdout.writeln('Wrote ${shellFile.path}');
}

File _resolveScreensCsv() {
  final cwd = Directory.current;
  final candidates = <File>[
    File(
      '${cwd.path}${Platform.pathSeparator}..'
      '${Platform.pathSeparator}prototype${Platform.pathSeparator}'
      '_REGISTRY${Platform.pathSeparator}screens.csv',
    ),
    File(
      '${cwd.path}${Platform.pathSeparator}prototype'
      '${Platform.pathSeparator}_REGISTRY${Platform.pathSeparator}'
      'screens.csv',
    ),
  ];

  // Walk up a few parents (repo root discovery).
  var dir = cwd;
  for (var i = 0; i < 4; i++) {
    candidates.add(
      File(
        '${dir.path}${Platform.pathSeparator}prototype'
        '${Platform.pathSeparator}_REGISTRY${Platform.pathSeparator}'
        'screens.csv',
      ),
    );
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }

  for (final f in candidates) {
    if (f.existsSync()) return f;
  }
  return candidates.first;
}

class _ScreenRow {
  _ScreenRow({
    required this.screenId,
    required this.app,
    required this.tab,
    required this.name,
    required this.journey,
    required this.services,
    required this.wave,
    required this.type,
    required this.notes,
  });

  final String screenId;
  final String app;
  final String tab;
  final String name;
  final String journey;
  final String services;
  final String wave;
  final String type;
  final String notes;

  bool get isTombstone {
    final hay = '$name $notes'.toLowerCase();
    return hay.contains('tombstone') ||
        name.contains('محذوفة') ||
        notes.toLowerCase().contains('tombstone');
  }

  String get path => '/${screenId.toLowerCase().replaceAll('_', '-')}';
}

List<_ScreenRow> _parseScreensCsv(String raw) {
  final lines = raw
      .split(RegExp(r'\r?\n'))
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();
  if (lines.isEmpty) return [];

  final header = lines.first.toLowerCase();
  if (!header.startsWith('screen_id')) {
    stderr.writeln('Unexpected CSV header: ${lines.first}');
  }

  final rows = <_ScreenRow>[];
  for (var i = 1; i < lines.length; i++) {
    final cols = _splitCsvLine(lines[i]);
    if (cols.isEmpty) continue;
    final id = cols[0].trim();
    if (id.isEmpty || !id.startsWith('SCR-')) continue;
    if (cols.length != 9) {
      stderr.writeln(
        'screens.csv line ${i + 1}: expected exactly 9 columns, '
        'got ${cols.length} for $id',
      );
      exit(1);
    }
    rows.add(
      _ScreenRow(
        screenId: id,
        app: cols[1].trim(),
        tab: cols[2].trim(),
        name: cols[3].trim(),
        journey: cols[4].trim(),
        services: cols[5].trim(),
        wave: cols[6].trim(),
        type: cols[7].trim(),
        notes: cols[8].trim(),
      ),
    );
  }
  return rows;
}

/// Minimal CSV split — registry rows do not quote commas in name fields.
List<String> _splitCsvLine(String line) {
  return line.split(',');
}

String _escapeDart(String s) {
  return s
      .replaceAll(r'\', r'\\')
      .replaceAll("'", r"\'")
      .replaceAll('\n', r'\n')
      .replaceAll('\r', '');
}

/// Feature screen builders that replace [PlaceholderScreen] on regenerate.
///
/// Key = registry screen_id · Value = const widget constructor expression.
const Map<String, String> screenBuilders = {
  'SCR-SHR-001': 'WelcomeScreen()',
  'SCR-SHR-002': 'CreateAccountScreen()',
  'SCR-SHR-003': 'LoginScreen()',
  'SCR-SHR-005': 'NetworkErrorTemplateScreen()',
  'SCR-SHR-006': 'EmptyStateTemplateScreen()',
  'SCR-SHR-007': 'DeviceModeScreen()',
  'SCR-SHR-008': 'DeviceUserSwitchScreen()',
  'SCR-CHD-011': 'ChildModeLockScreen()',
  'SCR-FAT-030': 'ParentSecondKeyScreen()',
  'SCR-FAT-031': 'MotherPermissionLevelScreen()',
  'SCR-FAT-001': 'CreateFamilyScreen()',
  'SCR-FAT-002': 'SetupWizardScreen()',
  'SCR-FAT-003': 'AddChildScreen()',
  'SCR-FAT-004': 'LinkQrScreen()',
  'SCR-FAT-005': 'PermissionsExplainerScreen()',
  'SCR-FAT-006': 'LinkSuccessScreen()',
  'SCR-FAT-007': 'TrialModeScreen()',
  'SCR-FAT-008': 'InviteMotherScreen()',
  'SCR-FAT-009': 'AcceptMotherInviteScreen()',
  'SCR-FAT-010': 'DayBoardScreen()',
  'SCR-FAT-011': 'AdvisorSuggestionsScreen()',
  'SCR-FAT-012': 'ChildrenListScreen()',
  'SCR-FAT-013':
      "ChildProfileScreen(childId: state.uri.queryParameters['childId'])",
  'SCR-FAT-014':
      "LocationMapScreen(childId: state.uri.queryParameters['childId'])",
  'SCR-FAT-015':
      "LocationHistoryScreen(childId: state.uri.queryParameters['childId'])",
  'SCR-FAT-016':
      "SafeZonesScreen(childId: state.uri.queryParameters['childId'])",
  'SCR-FAT-017':
      "CreateSafeZoneScreen(childId: state.uri.queryParameters['childId'])",
  'SCR-FAT-018':
      "SosAlertScreen(alertId: state.uri.queryParameters['alertId'], childId: state.uri.queryParameters['childId'])",
  'SCR-FAT-019': 'AlertsHubScreen()',
  'SCR-FAT-020':
      "AlertDetailScreen(alertId: state.uri.queryParameters['alertId'], alertKind: state.uri.queryParameters['alertKind'] ?? state.uri.queryParameters['kind'])",
  'SCR-FAT-021': 'ConversationsListScreen()',
  'SCR-FAT-022':
      "ConversationScreen(chatWith: state.uri.queryParameters['chatWith'])",
  'SCR-FAT-023':
      "ActiveCallScreen(callId: state.uri.queryParameters['callId'])",
  'SCR-FAT-024': 'CallHistoryScreen()',
  'SCR-FAT-032': 'ChildScreenTimeScreen()',
  'SCR-FAT-033': 'RequestInboxScreen()',
  'SCR-FAT-034':
      "ChildAppsScreen(childId: state.uri.queryParameters['childId'])",
  'SCR-FAT-035':
      "NewAppApprovalScreen(childId: state.uri.queryParameters['childId'], appId: state.uri.queryParameters['appId'])",
  'SCR-FAT-036': 'WebFilterScreen()',
  'SCR-FAT-037': 'InstantLockScreen()',
  'SCR-FAT-038':
      "TamperAlertsScreen(childId: state.uri.queryParameters['childId'])",
  'SCR-FAT-040': 'StudioBoardScreen()',
  'SCR-FAT-041': 'AddFromSourceScreen()',
  'SCR-FAT-042': 'StudioCameraCaptureScreen()',
  'SCR-FAT-043': 'GenerationOutputsScreen()',
  'SCR-FAT-044': 'PreviewApproveScreen()',
  'SCR-FAT-045': 'AttributionRewardScreen()',
  'SCR-FAT-046': 'CommunityLibraryScreen()',
  'SCR-FAT-047': 'LearningPathScreen()',
  'SCR-FAT-048': 'MaterialsLessonsScreen()',
  'SCR-FAT-049': 'CreateAssignmentScreen()',
  'SCR-FAT-050': 'ResultsFollowupScreen()',
  'SCR-FAT-051': 'FocusReportScreen()',
  'SCR-FAT-052': 'FamilyCalendarScreen()',
  'SCR-FAT-053': 'AddEventScreen()',
  'SCR-FAT-054': 'FamilyTasksScreen()',
  'SCR-FAT-055': 'CreateTaskScreen()',
  'SCR-FAT-058': 'NotificationPrefsScreen()',
  'SCR-FAT-059': 'PrivacyDataScreen()',
  'SCR-FAT-060': 'AuditLogScreen()',
  'SCR-FAT-061': 'LanguageHelpScreen()',
  'SCR-FAT-062': 'FamilyPatternsScreen()',
  'SCR-FAT-063': 'IndividualTimelineScreen()',
  'SCR-FAT-029': 'BrainControlScreen()',
  'SCR-FAT-067': 'SmartSupervisionScreen()',
  'SCR-FAT-068': 'PlatformMonitoringScreen()',
  'SCR-FAT-079': 'MyAdvisorScreen()',
  'SCR-FAT-085': 'SmartModesScreen()',
  'SCR-FAT-028': 'EmergencySetupScreen()',
  'SCR-FAT-056': 'PlansScreen()',
  'SCR-FAT-057': 'ManageSubscriptionScreen()',
  'SCR-CHD-001': 'ChildWelcomeScreen()',
  'SCR-CHD-002': 'ChildQrScanScreen()',
  'SCR-CHD-003': 'TransparencyConsentScreen()',
  'SCR-CHD-004': 'ChildDayBoardScreen()',
  'SCR-CHD-005': 'ChildSosButtonScreen()',
  'SCR-CHD-006':
      "ChildSosInProgressScreen(alertId: state.uri.queryParameters['alertId'], childId: state.uri.queryParameters['childId'])",
  'SCR-CHD-007': 'ChildChatsScreen()',
  'SCR-CHD-008':
      "ChildConversationScreen(chatWith: state.uri.queryParameters['chatWith'])",
  'SCR-CHD-009':
      "ChildActiveCallScreen(callId: state.uri.queryParameters['callId'])",
  'SCR-CHD-010': 'WhatIsCollectedScreen()',
  'SCR-CHD-021': 'TimeExpiryScreen()',
  'SCR-FAT-025': 'SettingsHubScreen()',
  'SCR-FAT-026':
      "DeviceHealthDetailScreen(deviceId: state.uri.queryParameters['deviceId'])",
  'SCR-FAT-027': 'FamilyMembersScreen()',
  'SCR-FAT-075': 'ComingSoonScreen()',
};

/// Extra imports required by [screenBuilders] values.
const List<String> screenBuilderImports = [
  "import 'package:family_os/features/shared_onboarding/welcome_screen.dart';",
  "import 'package:family_os/features/shared_onboarding/create_account_screen.dart';",
  "import 'package:family_os/features/shared_onboarding/login_screen.dart';",
  "import 'package:family_os/features/shared_onboarding/device_mode_screen.dart';",
  "import 'package:family_os/features/shared_onboarding/device_user_switch_screen.dart';",
  "import 'package:family_os/features/n05_lock/child_mode_lock_screen.dart';",
  "import 'package:family_os/features/n05_lock/parent_second_key_screen.dart';",
  "import 'package:family_os/features/shared_templates/network_error_template_screen.dart';",
  "import 'package:family_os/features/shared_templates/empty_state_template_screen.dart';",
  "import 'package:family_os/features/n01_linking/create_family_screen.dart';",
  "import 'package:family_os/features/n01_linking/setup_wizard_screen.dart';",
  "import 'package:family_os/features/n01_linking/add_child_screen.dart';",
  "import 'package:family_os/features/n01_linking/link_qr_screen.dart';",
  "import 'package:family_os/features/n01_linking/permissions_explainer_screen.dart';",
  "import 'package:family_os/features/n01_linking/link_success_screen.dart';",
  "import 'package:family_os/features/n01_linking/trial_mode_screen.dart';",
  "import 'package:family_os/features/n01_linking/invite_mother_screen.dart';",
  "import 'package:family_os/features/n01_linking/accept_mother_invite_screen.dart';",
  "import 'package:family_os/features/n01_linking/child_welcome_screen.dart';",
  "import 'package:family_os/features/n01_linking/child_qr_scan_screen.dart';",
  "import 'package:family_os/features/n01_linking/transparency_consent_screen.dart';",
  "import 'package:family_os/features/n02_day/day_board_screen.dart';",
  "import 'package:family_os/features/n02_day/children_list_screen.dart';",
  "import 'package:family_os/features/n02_day/child_profile_screen.dart';",
  "import 'package:family_os/features/n02_day/location_map_screen.dart';",
  "import 'package:family_os/features/n02_day/location_history_screen.dart';",
  "import 'package:family_os/features/n02_day/safe_zones_screen.dart';",
  "import 'package:family_os/features/n02_day/create_safe_zone_screen.dart';",
  "import 'package:family_os/features/n02_day/alerts_hub_screen.dart';",
  "import 'package:family_os/features/n02_day/alert_detail_screen.dart';",
  "import 'package:family_os/features/n02_day/conversations_list_screen.dart';",
  "import 'package:family_os/features/n02_day/child_chats_screen.dart';",
  "import 'package:family_os/features/n02_day/child_conversation_screen.dart';",
  "import 'package:family_os/features/n02_day/child_active_call_screen.dart';",
  "import 'package:family_os/features/n02_day/conversation_screen.dart';",
  "import 'package:family_os/features/n02_day/active_call_screen.dart';",
  "import 'package:family_os/features/n02_day/call_history_screen.dart';",
  "import 'package:family_os/features/n02_day/child_day_board_screen.dart';",
  "import 'package:family_os/features/n02_day/request_inbox_screen.dart';",
  "import 'package:family_os/features/n03_screen_time/child_screen_time_screen.dart';",
  "import 'package:family_os/features/n03_screen_time/child_apps_screen.dart';",
  "import 'package:family_os/features/n03_screen_time/new_app_approval_screen.dart';",
  "import 'package:family_os/features/n03_screen_time/time_expiry_screen.dart';",
  "import 'package:family_os/features/n12_devices/settings_hub_screen.dart';",
  "import 'package:family_os/features/n12_devices/device_health_detail_screen.dart';",
  "import 'package:family_os/features/n12_devices/family_members_screen.dart';",
  "import 'package:family_os/features/n12_devices/mother_permission_level_screen.dart';",
  "import 'package:family_os/features/n12_devices/language_help_screen.dart';",
  "import 'package:family_os/features/n04_web_filter/web_filter_screen.dart';",
  "import 'package:family_os/features/n05_lock/instant_lock_screen.dart';",
  "import 'package:family_os/features/n05_lock/tamper_alerts_screen.dart';",
  "import 'package:family_os/features/n14_studio/studio_board_screen.dart';",
  "import 'package:family_os/features/n14_studio/add_from_source_screen.dart';",
  "import 'package:family_os/features/n14_studio/studio_camera_capture_screen.dart';",
  "import 'package:family_os/features/n14_studio/generation_outputs_screen.dart';",
  "import 'package:family_os/features/n14_studio/preview_approve_screen.dart';",
  "import 'package:family_os/features/n14_studio/attribution_reward_screen.dart';",
  "import 'package:family_os/features/n14_studio/community_library_screen.dart';",
  "import 'package:family_os/features/n14_studio/learning_path_screen.dart';",
  "import 'package:family_os/features/n14_studio/materials_lessons_screen.dart';",
  "import 'package:family_os/features/n14_studio/create_assignment_screen.dart';",
  "import 'package:family_os/features/n14_studio/results_followup_screen.dart';",
  "import 'package:family_os/features/n14_studio/focus_report_screen.dart';",
  "import 'package:family_os/features/n15_calendar/family_calendar_screen.dart';",
  "import 'package:family_os/features/n15_calendar/add_event_screen.dart';",
  "import 'package:family_os/features/n16_tasks/family_tasks_screen.dart';",
  "import 'package:family_os/features/n16_tasks/create_task_screen.dart';",
  "import 'package:family_os/features/n06_notifications/notification_prefs_screen.dart';",
  "import 'package:family_os/features/n07_privacy/privacy_data_screen.dart';",
  "import 'package:family_os/features/n07_privacy/audit_log_screen.dart';",
  "import 'package:family_os/features/n07_advisor/brain_control_screen.dart';",
  "import 'package:family_os/features/n07_advisor/advisor_suggestions_screen.dart';",
  "import 'package:family_os/features/n07_advisor/my_advisor_screen.dart';",
  "import 'package:family_os/features/n07_advisor/family_patterns_screen.dart';",
  "import 'package:family_os/features/n07_advisor/individual_timeline_screen.dart';",
  "import 'package:family_os/features/n08_platform/smart_supervision_screen.dart';",
  "import 'package:family_os/features/n08_platform/platform_monitoring_screen.dart';",
  "import 'package:family_os/features/n09_smart_modes/smart_modes_screen.dart';",
  "import 'package:family_os/features/n10_emergency/emergency_setup_screen.dart';",
  "import 'package:family_os/features/n10_emergency/sos_alert_screen.dart';",
  "import 'package:family_os/features/n10_emergency/child_sos_button_screen.dart';",
  "import 'package:family_os/features/n10_emergency/child_sos_in_progress_screen.dart';",
  "import 'package:family_os/features/n11_billing/plans_screen.dart';",
  "import 'package:family_os/features/n11_billing/manage_subscription_screen.dart';",
  "import 'package:family_os/features/n07_privacy/what_is_collected_screen.dart';",
  "import 'package:family_os/features/n13_coming_soon/coming_soon_screen.dart';",
];

String _builderExpression(_ScreenRow r) {
  final custom = screenBuilders[r.screenId];
  if (custom != null) {
    // Do not force `const` — many feature screens use injectable / late defaults.
    return custom;
  }
  return '''const PlaceholderScreen(
        screenId: '${r.screenId}',
        title: '${_escapeDart(r.name)}',
      )''';
}

String _generateRouterDart(List<_ScreenRow> rows) {
  // ADR-034 / SET-018: tombstones are never emitted as real screen routes.
  final active = rows.where((r) => !r.isTombstone).toList();
  final tombstones = rows.where((r) => r.isTombstone).toList();

  final idsLiteral = active.map((r) => "  '${r.screenId}',").join('\n');
  final tombstoneIdsLiteral = tombstones
      .map((r) => "  '${r.screenId}',")
      .join('\n');
  final tombstonePathsLiteral = tombstones
      .map((r) => "  '${r.path}',")
      .join('\n');
  final routeBlocks = StringBuffer();
  final extraImports = screenBuilderImports.join('\n');

  for (final r in active) {
    routeBlocks.writeln('''
    GoRoute(
      path: '${r.path}',
      name: '${r.screenId}',
      builder: (context, state) => ${_builderExpression(r)},
    ),''');
  }

  return '''
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
$extraImports

/// Active registry screen_ids mirrored as routes (${active.length} rows).
/// Tombstones (ADR-034) are excluded — see [tombstoneScreenIds].
const List<String> generatedScreenIds = [
$idsLiteral
];

/// Tombstone screen_ids kept in CSV historically but never routed (ADR-034).
const List<String> tombstoneScreenIds = [
$tombstoneIdsLiteral
];

/// Deep-link paths for tombstones — redirect only, never a screen builder.
const List<String> tombstonePaths = [
$tombstonePathsLiteral
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
${routeBlocks.toString()}    ],
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
''';
}

// ─── Shell / hub config (PRT-1) ─────────────────────────────────────────────

/// Parent/child Arabic tab label → shell tab definition (frozen prototype).
class _TabDef {
  const _TabDef({
    required this.arabicTab,
    required this.tabId,
    required this.rootScreenId,
    required this.icon,
    required this.arbLabelKey,
  });

  final String arabicTab;
  final String tabId;
  final String rootScreenId;
  final String icon;
  final String arbLabelKey;
}

const List<_TabDef> _parentTabDefs = [
  _TabDef(
    arabicTab: 'اليوم',
    tabId: 'today',
    rootScreenId: 'SCR-FAT-010',
    icon: '🏠',
    arbLabelKey: 'tabParentToday',
  ),
  _TabDef(
    arabicTab: 'أبنائي',
    tabId: 'kids',
    rootScreenId: 'SCR-FAT-012',
    icon: '👦',
    arbLabelKey: 'tabParentKids',
  ),
  _TabDef(
    arabicTab: 'العائلة',
    tabId: 'family',
    rootScreenId: 'SCR-FAT-021',
    icon: '💬',
    arbLabelKey: 'tabParentFamily',
  ),
  _TabDef(
    arabicTab: 'التعليم',
    tabId: 'studio',
    rootScreenId: 'SCR-FAT-040',
    icon: '📚',
    arbLabelKey: 'tabParentStudio',
  ),
  _TabDef(
    arabicTab: 'الإعدادات',
    tabId: 'settings',
    rootScreenId: 'SCR-FAT-025',
    icon: '⚙️',
    arbLabelKey: 'tabParentSettings',
  ),
];

const List<_TabDef> _childTabDefs = [
  _TabDef(
    arabicTab: 'يومي',
    tabId: 'myday',
    rootScreenId: 'SCR-CHD-004',
    icon: '🏠',
    arbLabelKey: 'tabChildMyDay',
  ),
  _TabDef(
    arabicTab: 'تعلّمي',
    tabId: 'learn',
    rootScreenId: 'SCR-CHD-012',
    icon: '📚',
    arbLabelKey: 'tabChildLearn',
  ),
  _TabDef(
    arabicTab: 'عائلتي',
    tabId: 'cfam',
    rootScreenId: 'SCR-CHD-007',
    icon: '💬',
    arbLabelKey: 'tabChildFamily',
  ),
  _TabDef(
    arabicTab: 'أنا',
    tabId: 'me',
    rootScreenId: 'SCR-CHD-010',
    icon: '👤',
    arbLabelKey: 'tabChildMe',
  ),
];

/// Type → hub icon from frozen prototype injection
/// (لوحة📊 قائمة📋 إعدادات⚙️ محادثة💬 … — see design integrity plan).
const Map<String, String> _typeToHubIcon = {
  'إجراء': '⚡',
  'إعدادات': '⚙️',
  'إقرار': '✍️',
  'التقاط': '📷',
  'تأكيد': '✅',
  'تعليمي': '📚',
  'تفصيل': '🔎',
  'خريطة': '🗺',
  'خطأ': '📡',
  'شفافية': '👁',
  'طارئة': '🚨',
  'عرض': '👁',
  'فارغة': '🌤',
  'قائمة': '📋',
  'كاميرا': '📷',
  'لوحة': '📊',
  'محادثة': '💬',
  'مدخل': '🚪',
  'معالج': '🪄',
  'مكالمة': '📞',
  'نموذج': '📝',
};

String _hubIconForType(String type) {
  final icon = _typeToHubIcon[type];
  if (icon == null) {
    stderr.writeln(
      'Unknown screen type "$type" — no hub icon in frozen prototype map. '
      'STOP: add a QUESTIONS.md entry; do not invent an emoji.',
    );
    exit(1);
  }
  return icon;
}

_TabDef? _tabDefForArabic(String arabicTab) {
  for (final d in _parentTabDefs) {
    if (d.arabicTab == arabicTab) return d;
  }
  for (final d in _childTabDefs) {
    if (d.arabicTab == arabicTab) return d;
  }
  return null;
}

/// Registry-order ids for a tab; [rootScreenId] forced to index 0, no dupes.
List<String> _screenIdsForTab(List<_ScreenRow> active, _TabDef def) {
  final inTab = active.where((r) => r.tab == def.arabicTab).toList();
  if (!inTab.any((r) => r.screenId == def.rootScreenId)) {
    stderr.writeln(
      'Tab "${def.tabId}" root ${def.rootScreenId} not found under '
      'Arabic tab "${def.arabicTab}" in screens.csv',
    );
    exit(1);
  }
  final ids = <String>[def.rootScreenId];
  for (final r in inTab) {
    if (r.screenId == def.rootScreenId) continue;
    ids.add(r.screenId);
  }
  return ids;
}

String _generateShellConfigDart(List<_ScreenRow> rows) {
  final active = rows.where((r) => !r.isTombstone).toList();

  for (final r in active) {
    if (r.tab == '-') continue;
    if (_tabDefForArabic(r.tab) == null) {
      stderr.writeln(
        'Unknown tab value "${r.tab}" on ${r.screenId} — '
        'expected a frozen parent/child tab or "-"',
      );
      exit(1);
    }
  }

  for (final r in active) {
    _hubIconForType(r.type);
  }

  final parentTabless = <String>[];
  final childTabless = <String>[];
  for (final r in active) {
    if (r.tab != '-') continue;
    if (r.app == 'الابن') {
      childTabless.add(r.screenId);
    } else if (r.app == 'الوالدان' || r.app == 'مشترك') {
      parentTabless.add(r.screenId);
    } else {
      stderr.writeln('Tabless screen ${r.screenId} has unknown app "${r.app}"');
      exit(1);
    }
  }

  String shellTabLiteral(_TabDef def, List<String> screenIds) {
    final idsLit = screenIds.map((id) => "    '$id',").join('\n');
    return '''
  ShellTab(
    tabId: '${def.tabId}',
    arbLabelKey: '${def.arbLabelKey}',
    rootScreenId: '${def.rootScreenId}',
    icon: '${def.icon}',
    screenIds: <String>[
$idsLit
    ],
  )''';
  }

  final parentTabs = _parentTabDefs
      .map((d) => MapEntry(d, _screenIdsForTab(active, d)))
      .toList();
  final childTabs = _childTabDefs
      .map((d) => MapEntry(d, _screenIdsForTab(active, d)))
      .toList();

  final parentTabsLit = parentTabs
      .map((e) => shellTabLiteral(e.key, e.value))
      .join(',\n');
  final childTabsLit = childTabs
      .map((e) => shellTabLiteral(e.key, e.value))
      .join(',\n');

  final parentTablessLit = parentTabless.map((id) => "  '$id',").join('\n');
  final childTablessLit = childTabless.map((id) => "  '$id',").join('\n');

  final allTabDefs = [..._parentTabDefs, ..._childTabDefs];
  final hubBlocks = StringBuffer();
  for (final def in allTabDefs) {
    final screenIds = _screenIdsForTab(active, def);
    final byId = {for (final r in active) r.screenId: r};
    final entries = StringBuffer();
    for (final id in screenIds) {
      final r = byId[id]!;
      final icon = _hubIconForType(r.type);
      entries.writeln('''
    HubEntry(
      screenId: '${r.screenId}',
      name: '${_escapeDart(r.name)}',
      icon: '$icon',
      type: '${_escapeDart(r.type)}',
    ),''');
    }
    hubBlocks.writeln("  '${def.tabId}': <HubEntry>[");
    hubBlocks.write(entries);
    hubBlocks.writeln('  ],');
  }

  final routesByRoot = StringBuffer();
  for (final def in allTabDefs) {
    final path = '/${def.rootScreenId.toLowerCase().replaceAll('_', '-')}';
    routesByRoot.writeln("  '${def.tabId}': '$path',");
  }

  return '''
// GENERATED — do not edit by hand. Run: dart run tool/gen_routes.dart

/// Shell tab branch derived from screens.csv (PRT-1 groundwork).
class ShellTab {
  const ShellTab({
    required this.tabId,
    required this.arbLabelKey,
    required this.rootScreenId,
    required this.icon,
    required this.screenIds,
  });

  final String tabId;
  final String arbLabelKey;
  final String rootScreenId;
  final String icon;
  final List<String> screenIds;
}

/// Hub tile for a screen inside a shell tab.
class HubEntry {
  const HubEntry({
    required this.screenId,
    required this.name,
    required this.icon,
    required this.type,
  });

  final String screenId;
  final String name;
  final String icon;
  final String type;
}

/// Parent shell tabs (exactly 5) — frozen prototype order.
const List<ShellTab> parentShellTabs = <ShellTab>[
$parentTabsLit
];

/// Child shell tabs (exactly 4) — frozen prototype order.
const List<ShellTab> childShellTabs = <ShellTab>[
$childTabsLit
];

/// Parent + shared onboarding/templates screens with tab == '-'.
const List<String> parentTablessScreenIds = <String>[
$parentTablessLit
];

/// Child screens with tab == '-'.
const List<String> childTablessScreenIds = <String>[
$childTablessLit
];

/// Hub index keyed by tabId — registry order, type→icon from frozen prototype.
const Map<String, List<HubEntry>> hubIndex = <String, List<HubEntry>>{
$hubBlocks};

/// Deep-link path for each tab root screen.
const Map<String, String> shellRoutesByTabRoot = <String, String>{
$routesByRoot};
''';
}
