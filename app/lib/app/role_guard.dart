import 'package:go_router/go_router.dart';
import 'package:family_os/core/domain/role.dart';

/// Converts a registry [screenId] to its go_router path
/// (e.g. `SCR-FAT-056` → `/scr-fat-056`).
String screenPath(String screenId) =>
    '/${screenId.toLowerCase().replaceAll('_', '-')}';

/// Owner-only screen IDs (constitution rule 8 — **child** blocked; mother OK).
///
/// Privacy / audit remain open to mother (read or shared parent surfaces).
/// Billing moved to [fatherOnlyScreenIds] (UI-007 — Father OWNER only).
///
/// Explicitly **not** owner-only (never block SOS / location / chat):
/// - SCR-CHD-005 notes mention «اشتراك» but is SOS — allowed for child
/// - SCR-FAT-014/015 location, SCR-FAT-021/022 chat, SCR-CHD-007/008 chat, etc.
const Set<String> ownerOnlyScreenIds = {
  'SCR-FAT-059',
  'SCR-FAT-060',
};

/// Paths derived from [ownerOnlyScreenIds] for redirect matching.
final Set<String> ownerOnlyPaths = ownerOnlyScreenIds.map(screenPath).toSet();

/// Father-only screen IDs (S-ADM-033 / SET-015 / UI-007 / ADR-035).
///
/// Mother at any level + child blocked.
/// - SCR-FAT-029 — لوحة تحكم العقل (brain control)
/// - SCR-FAT-031 — مستوى صلاحية الأم (owner-only DELEGATION_EDIT)
/// - SCR-FAT-056 — الباقات والاشتراك (billing plans)
/// - SCR-FAT-057 — إدارة الاشتراك (manage subscription)
const Set<String> fatherOnlyScreenIds = {
  'SCR-FAT-029',
  'SCR-FAT-031',
  'SCR-FAT-056',
  'SCR-FAT-057',
};

/// Paths derived from [fatherOnlyScreenIds] for redirect matching.
final Set<String> fatherOnlyPaths = fatherOnlyScreenIds.map(screenPath).toSet();

/// Safe landing when a non-allowed role hits a guarded route.
const String roleGuardSafeLocation = '/gallery';

/// True only for [AppRole.father] (doc 20 / S-ADM-033).
bool canOpenBrainControl(AppRole role) => role == AppRole.father;

/// UI-007 / Rule 9 — Father OWNER only may open billing screens.
bool canOpenBilling(AppRole role) => role == AppRole.father;

/// SET-022 / A-5 — only father may approve suggestions into RulesEngine.
///
/// Mother may view SCR-FAT-079 read-only; child likewise (lean — no authoring).
bool canApproveAdvisorRules(AppRole role) => role == AppRole.father;

/// SET-021 / P-4 — no role may see or configure an SOS-mute control.
///
/// RoleGuard / UI composition **omits** mute-SOS surfaces for mother/guardian
/// (and every other role). Always `false`.
bool canShowSosMuteControl(AppRole role) {
  switch (role) {
    case AppRole.father:
    case AppRole.mother:
    case AppRole.child:
      return false;
  }
}

/// Father-only path redirect (SET-015 / UI-007). Mother / child → safe location.
String? fatherOnlyRedirect(String path, AppRole role) {
  if (!fatherOnlyPaths.contains(path)) return null;
  if (role == AppRole.father) return null;
  return roleGuardSafeLocation;
}

/// Path-level RoleGuard (testable without a full [GoRouterState]).
String? roleGuardRedirectForPath(String path, AppRole role) {
  final fatherDeny = fatherOnlyRedirect(path, role);
  if (fatherDeny != null) return fatherDeny;

  if (role != AppRole.child) return null;
  if (ownerOnlyPaths.contains(path)) {
    return roleGuardSafeLocation;
  }
  return null;
}

/// go_router [redirect]: child cannot open privacy/audit;
/// mother/child cannot open father-only brain control or billing (UI-007).
///
/// Returns a new location, or `null` to allow navigation.
String? roleGuardRedirect(GoRouterState state, AppRole role) {
  return roleGuardRedirectForPath(state.uri.path, role);
}
