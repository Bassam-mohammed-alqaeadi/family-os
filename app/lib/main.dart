import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/audit_population.dart';
import 'package:family_os/app/dev_screen_gallery.dart';
import 'package:family_os/app/family_shell.dart';
import 'package:family_os/app/role_controller.dart';
import 'package:family_os/app/router.dart';
import 'package:family_os/app/showcase_policy.dart';
import 'package:family_os/app/ux_local_seed.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/education/education_local_persistence.dart';
import 'package:family_os/core/events/local_event_policy_bridge.dart';
import 'package:family_os/core/family_ops/family_ops_local_persistence.dart';
import 'package:family_os/core/fs_foundation/fs_composition_runtime.dart';
import 'package:family_os/core/fs_foundation/fs_session_kernel.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/i18n/locale_controller.dart';
import 'package:family_os/core/identity/identity_local_persistence.dart';
import 'package:family_os/core/identity/identity_runtime.dart';
import 'package:family_os/core/identity/identity_scope.dart';
import 'package:family_os/core/policy/advisor_repository.dart';
import 'package:family_os/core/prefs_misc/prefs_misc_runtime.dart';
import 'package:family_os/core/runtime/app_runtime.dart';
import 'package:family_os/core/runtime/app_scope.dart';
import 'package:family_os/core/runtime/family_device_source.dart';
import 'package:family_os/core/runtime/family_policy_source.dart';
import 'package:family_os/core/runtime/family_roster_source.dart';
import 'package:family_os/core/runtime/identity_source.dart';
import 'package:family_os/core/screen_time/screen_time_runtime.dart';
import 'package:family_os/core/sos_final/sos_prefs_local_persistence.dart';
import 'package:family_os/features/n02_day/alert_detail_local_projection.dart';
import 'package:family_os/features/n02_day/alerts_hub_local_projection.dart';
import 'package:family_os/features/n02_day/child_profile_repository.dart';
import 'package:family_os/features/n02_day/children_list_repository.dart';
import 'package:family_os/features/n02_day/family_chat_local_persistence.dart';
import 'package:family_os/features/n02_day/location_server_authority.dart';
import 'package:family_os/features/n03_screen_time/screen_time_server_authority.dart';
import 'package:family_os/features/n04_web_filter/web_filter_server_authority.dart';
import 'package:family_os/features/n16_tasks/tasks_server_authority.dart';
import 'package:family_os/features/n10_emergency/sos_server_authority.dart';
import 'package:family_os/features/n02_day/location_ux_bridge.dart';
import 'package:family_os/features/n03_screen_time/child_apps_local_persistence.dart';
import 'package:family_os/features/n07_privacy/audit_log_local_persistence.dart';
import 'package:family_os/features/n12_devices/mother_permission_level_identity_repository.dart';
import 'package:family_os/features/n12_devices/family_members_remote_repository.dart';
import 'package:family_os/features/n12_devices/family_members_repository.dart';
import 'package:family_os/features/n12_devices/family_members_role_labels.dart';
import 'package:family_os/features/n12_devices/mother_permission_level_repository.dart';
import 'package:family_os/features/n16_tasks/family_tasks_local_persistence.dart';
import 'package:family_os/features/quran/quran_local_bridge.dart';
import 'package:family_os/features/shared_onboarding/device_user_switch_identity_repository.dart';
import 'package:family_os/features/shared_onboarding/device_user_switch_repository.dart';
import 'package:family_os/foundation_gate/children_roster_api_client.dart';
import 'package:family_os/foundation_gate/family_device_api_client.dart';
import 'package:family_os/foundation_gate/family_location_api_client.dart';
import 'package:family_os/foundation_gate/family_discovery_api_client.dart';
import 'package:family_os/foundation_gate/family_membership_api_client.dart';
import 'package:family_os/foundation_gate/family_screen_time_api_client.dart';
import 'package:family_os/foundation_gate/family_tasks_api_client.dart';
import 'package:family_os/foundation_gate/family_web_filter_api_client.dart';
import 'package:family_os/foundation_gate/family_sos_api_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_configuration.dart';
import 'package:family_os/foundation_gate/foundation_gate_http.dart';
import 'package:family_os/foundation_gate/foundation_gate_identity.dart';
import 'package:family_os/foundation_gate/foundation_gate_session_controller.dart';
import 'package:family_os/foundation_gate/main_app_foundation_runtime.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Which build this is, recorded once so the route policy can refuse the design
  // showcase in a release build. A quarantined showcase must not depend on a
  // caller remembering to pass a flag.
  bindReleaseMode(kReleaseMode);
  // Phase 1.5 — shared FS SQLite session (Memory fallback is honest DEGRADED).
  await FsSessionKernel.ensureOpen(preferSqlite: true);
  // DOM-IDENTITY-A — active family context → Local KV when SQLite honest.
  await IdentityLocalPersistence.tryBindStage1FamilyContext();
  // DOM-IDENTITY-B — children display roster REAL_LOCAL seed → Local KV.
  await IdentityLocalPersistence.tryBindStage1ChildrenList();
  // LDR-B1 — child profile ← roster (explicit bind after Identity).
  rebindStage1ChildProfileRepository(
    InMemoryChildProfileRepository(childrenList: stage1ChildrenListRepository),
  );
  // FE-W1-FAT-027 — family members roster ← Identity + Local children.
  await IdentityLocalPersistence.tryBindStage1FamilyMembers();
  // VX-B6 / SHR-008 — device user switch ← Identity + Local children.
  rebindStage1DeviceUserSwitchRepository(IdentityDeviceUserSwitchRepository());
  // FE-W1-FAT-031 — mother permission level ← Identity membership.
  rebindStage1MotherPermissionLevelRepository(
    IdentityMotherPermissionLevelRepository(),
  );
  // HOST-ROUTER-A — Prefs-misc Domain boot-once (NOTIF/PRIVACY/AT/LOCK/MON).
  await PrefsMiscRuntime.tryBind();
  // VX-B3 · D1 — AR/EN locale from Local KV.
  final localeController = await LocaleController.open();
  // HOST-ROUTER-B — Screen Time Domain boot-once (policy/schedule/time-request).
  await ScreenTimeRuntime.tryBind();
  // DOM-EDU-LOCAL-A — LearningAssignment Local KV (P12 hub metadata only).
  await EducationLocalPersistence.tryBindStage1Assignments();
  // DOM-EDU-LOCAL-B — LearningResult Local KV (child→father metadata only).
  await EducationLocalPersistence.tryBindStage1Results();
  // CE-B1 — Family Tasks Local KV (Minutes VO + father↔child loop).
  await FamilyTasksLocalPersistence.tryBindStage1();
  // CE-B1 — Calendar / Outer Circle / Media / Arrival / Focus Local KV.
  await FamilyOpsLocalPersistence.tryBindStage1();
  // VX-B6 / OD-09 — Family chat Local KV (seed family thread, no messages).
  await FamilyChatLocalPersistence.tryBindStage1();
  // DOM-SOS-SETTINGS / LADDER + AUTH-FS002-UNLOCK-B residual Local KV.
  await SosPrefsRuntime.tryBind();
  // DOM-AUDIT-LOCAL — FAT-060 AuditLog → Local KV (append-only).
  await AuditLogLocalPersistence.tryBindStage1();
  // VX-B5 / FVX-S-02 — Alerts hub ← local SOS/tamper/time/app/friend producers.
  tryBindStage1AlertsHubProjection();
  // Notifications core — FAT-020 ← local SOS/tamper projection.
  tryBindStage1AlertDetailProjection();
  // HOST-ROUTER-C — FS Domain runtimes boot-once (SOS/AC/Loc/Modes/WF/SC/AI).
  // Also binds AUTH-FS006-BG Local break-glass via SosFinalRuntime.
  await FsCompositionRuntime.tryBind();
  // LDR-B1 — Location map/history UX ← loc_* domain + roster.
  await tryBindStage1LocationUx();
  // LDR-B2 — Child apps ← AC/ST axes + REAL_LOCAL managed catalog (usedMins=0).
  await ChildAppsLocalPersistence.tryBindStage1();
  // LDR-B1 — Quran local KV hydrate.
  await QuranLocalPersistence.tryBindStage1();
  // LDR-B1 / 1C — Advisor empty at boot (no planted AI as live).
  rebindStage1AdvisorRepository(const EmptyAdvisorRepository());
  // UX-LOCAL-SEED — fill projecting-hub producers (app install, prefs, …).
  // Idempotent; debug/profile only.
  await applyUxLocalSeed();
  // Debug populate fixtures (Advisor mock, studio, …). Does NOT hide shell tabs.
  if (resolveAuditPopulated()) {
    rebindStage1AdvisorRepository(const MockAdvisorRepository());
    await applyAuditPopulation(enabled: true);
  }
  // Chrome-free audit vision host — only when route/intent asks (not default).
  auditHostActive = resolveAuditVisionHost();
  // EVT-01-B — PolicySyncBus + AuditAppend → Local Event Journal (enqueue ≠ deliver).
  await LocalEventPolicyBridge.tryBind();
  final familyEntryRuntime = await _tryCreateMainAppFoundationRuntime();
  // Restore only a provider-managed session; no local family/roster fallback is
  // consulted when this remote capability has not been configured.
  if (familyEntryRuntime != null) {
    await familyEntryRuntime.refreshIdentity();
    // FE-W1-FAT-027 — the members roster and its three commands come from the server when
    // a server is configured. Without this, the screen keeps the local projection: it can
    // show who this device recorded and cannot invite, accept or revoke anything.
    rebindStage1FamilyMembersRepository(
      RemoteFamilyMembersRepository(
        loadMemberships: familyEntryRuntime.listMemberships,
      ),
    );
    rebindStage1MembershipCommands(
      RemoteFamilyMembershipCommands(familyEntryRuntime),
    );
    // W3 — safe zones and the live location picture come from the server when a server is
    // configured. Until this binding existed, a zone the mother drew lived in her own
    // handset's store: the father could not see the boundary, and no arrival could be
    // detected, because detection needs one shared answer to "where is the boundary".
    final locationApi = familyEntryRuntime.locationApi;
    if (locationApi != null) {
      bindLocationServerAuthority(
        LocationServerAuthority(
          api: locationApi,
          idToken: familyEntryRuntime.currentIdToken,
          familyId: () => familyEntryRuntime.selectedFamilyId,
        ),
      );
    }
    // W4 — the child's button, the escalation and the arrival receipt are server facts when
    // a server is configured. Before this binding, pressing the alarm ran a simulated service
    // that always succeeded: no guardian was told, and the screen said otherwise. A build
    // without this binding now says the alarm did not reach anyone rather than pretending.
    // W5 - the minutes a child has, the apps they belong to and the instant lock are server
    // facts when a server is configured. Before this binding the screen-time screens read a
    // local sample: a bedtime nobody enforced and a cap the phone could forget. A build
    // without this binding now says the server did not answer rather than drawing a clock.
    final screenTimeApi = familyEntryRuntime.screenTimeApi;
    if (screenTimeApi != null) {
      bindScreenTimeServerAuthority(
        ScreenTimeServerAuthority(
          api: screenTimeApi,
          idToken: familyEntryRuntime.currentIdToken,
          familyId: () => familyEntryRuntime.selectedFamilyId,
        ),
      );
    }
    // W6 — the filter a family set, whether it is actually running, and the honest answer
    // when nobody has said anything lately. Before this binding the filter screens read a
    // local policy and a shield nobody had checked: a family could see "protected" on a
    // phone that had last spoken days ago. A build without this binding now says the server
    // did not answer rather than drawing a green dot.
    final webFilterApi = familyEntryRuntime.webFilterApi;
    if (webFilterApi != null) {
      bindWebFilterServerAuthority(
        WebFilterServerAuthority(
          api: webFilterApi,
          idToken: familyEntryRuntime.currentIdToken,
          familyId: () => familyEntryRuntime.selectedFamilyId,
        ),
      );
    }
    // W7 — the tasks a child has to do, the word of the guardian who confirms them, and the
    // points that follow. Before this binding the tasks screens read a local board and a
    // points number nobody had confirmed: a family could see a reward that only one phone
    // knew about. A build without this binding now says the server did not answer rather
    // than counting points locally.
    final tasksApi = familyEntryRuntime.tasksApi;
    if (tasksApi != null) {
      bindTasksServerAuthority(
        TasksServerAuthority(
          api: tasksApi,
          idToken: familyEntryRuntime.currentIdToken,
          familyId: () => familyEntryRuntime.selectedFamilyId,
        ),
      );
    }
    final sosApi = familyEntryRuntime.sosApi;
    if (sosApi != null) {
      bindSosServerAuthority(
        SosServerAuthority(
          api: sosApi,
          idToken: familyEntryRuntime.currentIdToken,
          familyId: () => familyEntryRuntime.selectedFamilyId,
          memberLabelSource: () => _memberRoleLabels(familyEntryRuntime),
          childNameOf: (childId) => _rosterChildOf(familyEntryRuntime, childId).displayName ?? '',
          childEmojiOf: (childId) => _rosterChildOf(familyEntryRuntime, childId).avatarEmoji ?? '',
        ),
      );
    }
  }
  runApp(
    FamilyOsApp(
      localeController: localeController,
      foundationRuntime: familyEntryRuntime,
    ),
  );
}

/// The role words for the family's memberships, keyed by membership id.
///
/// The membership contract publishes a role and not a person's name, so this is the most a
/// recipient row may honestly say. An unknown role is left out rather than shown under the
/// nearest-looking word, and a failed read throws to the caller's own catch.
Future<Map<String, String>> _memberRoleLabels(
  MainAppFoundationRuntime runtime,
) async {
  final familyId = runtime.selectedFamilyId;
  if (familyId == null || familyId.isEmpty) return const {};
  final memberships = await runtime.listMemberships(FamilyId(familyId));
  final labels = <String, String>{};
  for (final membership in memberships) {
    final label = FamilyMembersRoleLabels.forRole(membership.role);
    if (label == null) continue;
    labels[membership.id] = label.$2;
  }
  return labels;
}

/// The roster row for one child, or an empty row when the roster does not have them.
FamilyRosterChild _rosterChildOf(MainAppFoundationRuntime runtime, String childId) {
  for (final child in runtime.rosterValue.children) {
    if (child.childId.value == childId) return child;
  }
  return FamilyRosterChild(childId: ChildId(childId));
}

/// Initializes the real Family Entry port only when the owner provides a
/// credential-free HTTPS API origin and the platform Firebase configuration is
/// present. Any setup failure leaves the production route unavailable rather
/// than falling back to seeded/local roster authority.
Future<MainAppFoundationRuntime?> _tryCreateMainAppFoundationRuntime() async {
  const apiOrigin = String.fromEnvironment('FAMILY_OS_API_ORIGIN');
  const preferredFamilyId = String.fromEnvironment(
    'FAMILY_OS_ACTIVE_FAMILY_ID',
  );
  if (apiOrigin.trim().isEmpty) return null;
  try {
    await Firebase.initializeApp();
    final configuration = FoundationGateConfiguration.fromStagingApiOrigin(
      Uri.parse(apiOrigin),
    );
    final identity = FirebaseEmailPasswordIdentity(FirebaseAuth.instance);
    return MainAppFoundationRuntime(
      controller: FoundationGateSessionController(
        identity: identity,
        discoveryApi: FamilyDiscoveryApiClient(
          configuration: configuration,
          transport: PackageFoundationGateHttpTransport(),
        ),
        rosterApi: ChildrenRosterApiClient(
          configuration: configuration,
          transport: PackageFoundationGateHttpTransport(),
        ),
      ),
      identity: identity,
      deviceApi: FamilyDeviceApiClient(
        configuration: configuration,
        transport: PackageFoundationGateHttpTransport(),
      ),
      membershipApi: FamilyMembershipApiClient(
        configuration: configuration,
        transport: PackageFoundationGateHttpTransport(),
      ),
      locationApi: FamilyLocationApiClient(
        configuration: configuration,
        transport: PackageFoundationGateHttpTransport(),
      ),
      sosApi: FamilySosApiClient(
        configuration: configuration,
        transport: PackageFoundationGateHttpTransport(),
      ),
      screenTimeApi: FamilyScreenTimeApiClient(
        configuration: configuration,
        transport: PackageFoundationGateHttpTransport(),
      ),
      webFilterApi: FamilyWebFilterApiClient(
        configuration: configuration,
        transport: PackageFoundationGateHttpTransport(),
      ),
      tasksApi: FamilyTasksApiClient(
        configuration: configuration,
        transport: PackageFoundationGateHttpTransport(),
      ),
      preferredFamilyId: preferredFamilyId,
    );
  } on Object {
    return null;
  }
}

/// Cold-start route from Android `flutter_route` intent extra (via
/// [MainActivity.getInitialRoute] → platform defaultRouteName), else father Today.
String resolveAppInitialLocation({String fallback = '/scr-shr-001'}) {
  final fromPlatform = auditRoutePath(
    WidgetsBinding.instance.platformDispatcher.defaultRouteName,
  );
  if (fromPlatform.isNotEmpty &&
      fromPlatform != '/' &&
      (fromPlatform == DevScreenGallery.routePath ||
          fromPlatform.startsWith('/scr-') ||
          fromPlatform == '/gallery' ||
          fromPlatform.startsWith('/sys3-'))) {
    return fromPlatform;
  }
  return fallback;
}

/// Family OS root — Arabic-first RTL, IBM Plex Sans Arabic, go_router.
class FamilyOsApp extends StatefulWidget {
  const FamilyOsApp({
    super.key,
    this.roleController,
    this.localeController,
    this.foundationRuntime,
  });

  /// Optional override for tests / gallery role switching.
  final RoleController? roleController;

  /// VX-B3 · D1 — when null, Arabic default (tests).
  final LocaleController? localeController;

  /// Null means the required remote Family Entry configuration is unavailable.
  final MainAppFoundationRuntime? foundationRuntime;

  @override
  State<FamilyOsApp> createState() => _FamilyOsAppState();
}

class _FamilyOsAppState extends State<FamilyOsApp> {
  late final RoleController _role;
  late final GoRouter _router;
  late final IdentityRuntime _identity;
  late final LocaleController _locale;
  late final AppRuntime _runtime;
  var _ownsRole = false;
  var _ownsLocale = false;

  @override
  void initState() {
    super.initState();
    _identity = stage1IdentityRuntime;
    final foundationRuntime = widget.foundationRuntime;
    _runtime = AppRuntime(
      identity: foundationRuntime == null
          ? RuntimeIdentitySource(
              _identity,
              authority: IdentityAuthority.unavailable,
            )
          : MainAppFoundationIdentitySource(foundationRuntime),
      roster: foundationRuntime == null
          ? UnavailableFamilyRosterSource()
          : RemoteFamilyRosterSource(foundationRuntime),
      childProfiles: foundationRuntime == null
          ? null
          : RemoteFamilyChildProfileSource(foundationRuntime),
      devices: foundationRuntime == null
          ? UnavailableFamilyDeviceSource()
          : RemoteFamilyDeviceSource(foundationRuntime),
      policies: UnavailableFamilyPolicySource(),
    );
    if (widget.roleController != null) {
      _role = widget.roleController!;
    } else {
      _role = RoleController(AppRole.father);
      _ownsRole = true;
    }
    if (widget.localeController != null) {
      _locale = widget.localeController!;
    } else {
      _locale = LocaleController();
      _ownsLocale = true;
    }
    _role.addListener(_syncLegacyRoleFallback);
    _syncLegacyRoleFallback();
    _router = createAppRouter(
      roleListenable: _role,
      initialLocation: resolveAppInitialLocation(),
    );
  }

  void _syncLegacyRoleFallback() {
    // Temporary bridge: role picker remains for stage-1 compatibility only.
    _identity.setLegacyRoleFallback(_role.value);
  }

  @override
  void dispose() {
    _role.removeListener(_syncLegacyRoleFallback);
    if (_ownsRole) {
      _role.dispose();
    }
    if (_ownsLocale) {
      _locale.dispose();
    }
    _router.dispose();
    _runtime.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      runtime: _runtime,
      child: CurrentLocale(
        controller: _locale,
        child: CurrentIdentity(
          runtime: _identity,
          child: CurrentRole(
            notifier: _role,
            child: ListenableBuilder(
              listenable: _locale,
              builder: (context, _) {
                return MaterialApp.router(
                  onGenerateTitle: (context) =>
                      AppLocalizations.of(context).appTitle,
                  theme: buildFamilyTheme(),
                  locale: _locale.locale,
                  supportedLocales: AppLocalizations.supportedLocales,
                  localizationsDelegates: const [
                    AppLocalizations.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  routerConfig: _router,
                  builder: (context, child) => FamilyShellHost(
                    router: _router,
                    child: child ?? const SizedBox.shrink(),
                  ),
                  debugShowCheckedModeBanner: false,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
