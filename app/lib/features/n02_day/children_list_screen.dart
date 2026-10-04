import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/app/shell_tab_more_tools.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/app_error_state.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/components/role_gate.dart';
import 'package:family_os/core/design/components/tag.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/identity/child_device_management_repository.dart';
import 'package:family_os/core/identity/identity_scope.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/runtime/app_scope.dart';
import 'package:family_os/core/runtime/family_device_source.dart';
import 'package:family_os/core/runtime/family_policy_source.dart';
import 'package:family_os/core/runtime/family_roster_source.dart';
import 'package:family_os/core/runtime/permission_matrix.dart';
import 'package:family_os/core/runtime/runtime_data_origin.dart';
import 'package:family_os/features/n01_linking/add_child_screen.dart';
import 'package:family_os/features/n02_day/children_list_local_repository.dart';
import 'package:family_os/features/n02_day/children_list_repository.dart';
import 'package:family_os/features/n02_day/day_child_mock.dart';

/// Widget keys for SCR-FAT-012 acceptance.
abstract final class ChildrenListKeys {
  static const screen = Key('children_list_screen');
  static const loading = Key('children_list_loading');
  static const empty = Key('children_list_empty');
  static const error = Key('children_list_error');
  static const list = Key('children_list_list');
  static const addChild = Key('children_list_add_child');
  static const sharedPoliciesCard = Key('children_list_shared_policies');
  static const sharedPoliciesSheet = Key('children_list_shared_policies_sheet');
  static const sharedApply = Key('children_list_shared_apply');
  static const childLean = Key('children_list_child_lean');
  static const localDemoBanner = Key('children_list_local_demo_banner');
  static const sharedEnforceHonesty = Key(
    'children_list_shared_enforce_honesty',
  );
  static const localOnlyBanner = Key('children_list_local_only_banner');

  static Key profileRepair(String id) =>
      Key('children_list_profile_repair_$id');

  static Key childRow(String id) => Key('children_list_row_$id');
}

/// SCR-FAT-012 — قائمة الأبناء (parent kids roster).
///
/// Mock-first Rule 23/25: empty until [ChildrenListRepository] seeds rows.
/// Competitive light (Family Link / Qustodio): shared rules for all kids with
/// honest individual-override wins. Profile / add-child navigate to registry
/// routes (FAT-013 child profile hub). No Firebase.
class ChildrenListScreen extends StatefulWidget {
  const ChildrenListScreen({
    super.key,
    this.repository,
    this.managementRepository,
    this.rosterSource,
    this.deviceSource,
    this.policySource,
    this.roleOverride,
    this.onAddChild,
    this.onOpenChildProfile,
  });

  /// Null → [stage1ChildrenListRepository].
  final ChildrenListRepository? repository;
  final ChildDeviceManagementRepository? managementRepository;

  /// Explicit runtime sources for the real Children Control Centre slice.
  /// Product routes receive these from [AppScope]; direct injection is kept
  /// for isolated tests and preview hosts.
  final FamilyRosterSource? rosterSource;
  final FamilyDeviceSource? deviceSource;
  final FamilyPolicySource? policySource;

  /// Test seam — when set, ignores [CurrentRole].
  final AppRole? roleOverride;

  /// Test seam — when null, navigates to `/scr-fat-003`.
  final VoidCallback? onAddChild;

  /// Test seam — when null, navigates to `/scr-fat-013?childId=…`.
  final void Function(String childId)? onOpenChildProfile;

  @override
  ChildrenListScreenState createState() => ChildrenListScreenState();
}

class ChildrenListScreenState extends State<ChildrenListScreen> {
  late final ChildrenListRepository _repo;
  late final ChildDeviceManagementRepository _managementRepo;
  var _loading = true;
  var _loadFailed = false;
  List<ChildrenListEntry> _children = const [];
  List<FamilyRosterChild> _runtimeRoster = const [];
  List<ManagedChildRecord> _profileRepairs = const [];
  FamilyDeviceSnapshot _deviceSnapshot =
      const FamilyDeviceSnapshot.unavailable();
  RuntimeDataOrigin _rosterOrigin = RuntimeDataOrigin.unavailable;
  RuntimeDataOrigin _policyOrigin = RuntimeDataOrigin.unavailable;
  FamilyId? _loadedFamilyId;
  bool _usesRuntimeSources = false;
  SharedChildrenPolicies _policies = const SharedChildrenPolicies();
  String? _rosterProvenance;

  AppRole get _role =>
      widget.roleOverride ??
      AppScope.maybeOf(context)?.identity.value.role ??
      CurrentRole.maybeNotifierOf(context)?.value ??
      AppRole.father;

  PanelProfile get _panelProfile {
    final identity = AppScope.maybeOf(context)?.identity.value;
    return PanelProfile.fromRole(
      _role,
      motherLevel: identity?.motherLevel ?? MotherLevel.observer,
    );
  }

  bool get _isParent => _role == AppRole.father || _role == AppRole.mother;

  bool get _canEditShared =>
      PermissionMatrix.dispositionFor(
            _panelProfile,
            PanelCapability.editChildRules,
          ) ==
          PermissionDisposition.allow &&
      (!_usesRuntimeSources ||
          _policyOrigin == RuntimeDataOrigin.localOnly ||
          _policyOrigin == RuntimeDataOrigin.remoteAuthoritative);
  bool get _canCreateChild {
    if (PermissionMatrix.dispositionFor(
          _panelProfile,
          PanelCapability.manageFamily,
        ) !=
        PermissionDisposition.allow) {
      return false;
    }
    final scopedIdentity = AppScope.maybeOf(context)?.identity.value;
    if (scopedIdentity != null) {
      // Child creation is intentionally admitted only for the server-confirmed
      // primary guardian. Co-guardian presentation is not mistaken for create
      // authority while this limited capability is rolled out.
      return scopedIdentity.isRemoteAuthoritative &&
          scopedIdentity.isPrimaryOwner;
    }
    final runtime = CurrentIdentity.maybeOf(context);
    if (runtime == null) return true;
    return _managementRepo
        .capabilitiesFor(runtime.activeFamilyId)
        .canCreateChild;
  }

  bool get _canDeleteChild {
    final runtime = CurrentIdentity.maybeOf(context);
    if (runtime == null) return _role == AppRole.father;
    return _managementRepo
        .capabilitiesFor(runtime.activeFamilyId)
        .canDeleteChild;
  }

  @override
  void initState() {
    super.initState();
    // The repository paths below remain isolated preview/test seams. Normal
    // routed screens obtain their data ports from AppScope in [_load].
    _repo = widget.repository ?? stage1ChildrenListRepository;
    _managementRepo =
        widget.managementRepository ?? stage1ChildDeviceManagementRepository;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final scope = AppScope.maybeOf(context);
      final familyId =
          scope?.identity.value.familyId ??
          CurrentIdentity.maybeOf(context)?.activeFamilyId;
      final rosterSource = widget.rosterSource ?? scope?.roster;
      final deviceSource = widget.deviceSource ?? scope?.devices;
      final policySource = widget.policySource ?? scope?.policies;

      // A scoped runtime source is the only production roster path. Once an
      // AppScope is composed, an absent remote family is an unavailable state,
      // not permission to read a seeded/local roster.
      if (scope != null || widget.rosterSource != null) {
        if (familyId == null || rosterSource == null) {
          if (!mounted) return;
          setState(() {
            _children = const [];
            _runtimeRoster = const [];
            _profileRepairs = const [];
            _deviceSnapshot = const FamilyDeviceSnapshot.unavailable();
            _rosterOrigin = RuntimeDataOrigin.unavailable;
            _policyOrigin = RuntimeDataOrigin.unavailable;
            _loadedFamilyId = null;
            _usesRuntimeSources = true;
            _rosterProvenance = null;
            _loading = false;
            _loadFailed = false;
          });
          return;
        }
        final roster = await rosterSource.load(familyId);
        final devices = deviceSource == null
            ? const FamilyDeviceSnapshot.unavailable()
            : await deviceSource.load(familyId);
        final policy = policySource == null
            ? const FamilyPolicySnapshot.unavailable()
            : await policySource.load(familyId);
        if (!mounted) return;
        setState(() {
          _children = const [];
          _runtimeRoster = roster.children;
          _profileRepairs = const [];
          _deviceSnapshot = devices;
          _rosterOrigin = roster.origin;
          _policyOrigin = policy.origin;
          _loadedFamilyId = familyId;
          _usesRuntimeSources = true;
          _policies = _legacyPolicyOf(policy.sharedPolicy);
          _rosterProvenance = null;
          _loading = false;
          _loadFailed = false;
        });
        return;
      }

      // Explicit legacy seam only. This cannot run for the normal app route,
      // because FamilyOsApp supplies AppScope and an active family context.
      final kids = await _repo.listChildren(familyId: familyId);
      final managed = familyId == null
          ? const <ManagedChildRecord>[]
          : _managementRepo.listChildren(familyId);
      final repairs = managed
          .where(
            (managedChild) =>
                !kids.any((it) => it.id == managedChild.childId.value),
          )
          .toList(growable: false);
      final policies = await _repo.loadSharedPolicies(familyId: familyId);
      final provenance = await _repo.loadProvenance(familyId: familyId);
      if (!mounted) return;
      setState(() {
        _children = kids;
        _runtimeRoster = const [];
        _profileRepairs = repairs;
        _deviceSnapshot = const FamilyDeviceSnapshot.unavailable();
        _rosterOrigin = RuntimeDataOrigin.localOnly;
        _policyOrigin = RuntimeDataOrigin.localOnly;
        _loadedFamilyId = familyId;
        _usesRuntimeSources = false;
        _policies = policies;
        _rosterProvenance = provenance;
        _loading = false;
        _loadFailed = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _children = const [];
        _runtimeRoster = const [];
        _profileRepairs = const [];
        _deviceSnapshot = const FamilyDeviceSnapshot.unavailable();
        _rosterOrigin = RuntimeDataOrigin.unavailable;
        _policyOrigin = RuntimeDataOrigin.unavailable;
        _loadedFamilyId = null;
        _rosterProvenance = null;
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  SharedChildrenPolicies _legacyPolicyOf(FamilySharedPolicy? policy) {
    if (policy == null) return const SharedChildrenPolicies();
    return SharedChildrenPolicies(
      scopeAll: policy.scopeAll,
      selectedChildIds: policy.selectedChildIds,
      dailyCapHours: policy.dailyCapHours,
      bedtimeLabel: policy.bedtimeLabel,
      webFilterOn: policy.webFilterOn,
    );
  }

  FamilySharedPolicy _runtimePolicyOf(SharedChildrenPolicies policy) =>
      FamilySharedPolicy(
        scopeAll: policy.scopeAll,
        selectedChildIds: policy.selectedChildIds,
        dailyCapHours: policy.dailyCapHours,
        bedtimeLabel: policy.bedtimeLabel,
        webFilterOn: policy.webFilterOn,
      );

  bool get _hasVisibleRoster =>
      _children.isNotEmpty ||
      _runtimeRoster.isNotEmpty ||
      _profileRepairs.isNotEmpty;

  void _goAddChild() {
    if (!_canCreateChild) {
      final l10n = AppLocalizations.of(context);
      AppToast.show(context, message: l10n.childrenListAddBlocked);
      return;
    }
    if (widget.onAddChild != null) {
      widget.onAddChild!();
      return;
    }
    context.push('/scr-fat-003');
  }

  void _goProfile(String childId) {
    if (widget.onOpenChildProfile != null) {
      widget.onOpenChildProfile!(childId);
      return;
    }
    context.push('/scr-fat-013?childId=${Uri.encodeComponent(childId)}');
  }

  Future<void> _deleteChild(String childId) async {
    if (!_canDeleteChild) {
      final l10n = AppLocalizations.of(context);
      AppToast.show(context, message: l10n.childrenListAddBlocked);
      return;
    }
    final runtime = CurrentIdentity.maybeOf(context);
    if (runtime == null) return;
    final ok = _managementRepo.deleteChild(
      familyId: runtime.activeFamilyId,
      childId: ChildId(childId),
    );
    if (!ok) return;
    await _load();
  }

  Future<void> _openSharedPolicies() async {
    final l10n = AppLocalizations.of(context);
    var draft = _policies;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).extension<FamilyColors>()!.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(
            Theme.of(context).extension<FamilyRadii>()!.sheetTop,
          ),
        ),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheet) {
            final colors = Theme.of(context).extension<FamilyColors>()!;
            final radii = Theme.of(context).extension<FamilyRadii>()!;
            return Padding(
              key: ChildrenListKeys.sharedPoliciesSheet,
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                16 + MediaQuery.paddingOf(context).bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.childrenListSharedSheetTitle,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: colors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.childrenListSharedHonesty,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.ink2,
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 8),
                    BannerNote(
                      key: ChildrenListKeys.sharedEnforceHonesty,
                      message: l10n.childrenListSharedEnforceHonesty,
                      variant: BannerVariant.a,
                      leading: Text(
                        'ℹ',
                        style: TextStyle(fontSize: 18, color: colors.ink),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.childrenListSharedScopeLabel,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: colors.ink2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: PrimaryBtn(
                            label: l10n.childrenListSharedScopeAll,
                            variant: draft.scopeAll
                                ? PrimaryBtnVariant.teal
                                : PrimaryBtnVariant.sec,
                            onPressed: _canEditShared
                                ? () => setSheet(() {
                                    draft = draft.copyWith(scopeAll: true);
                                  })
                                : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: PrimaryBtn(
                            label: l10n.childrenListSharedScopeSome,
                            variant: !draft.scopeAll
                                ? PrimaryBtnVariant.teal
                                : PrimaryBtnVariant.sec,
                            onPressed: _canEditShared
                                ? () => setSheet(() {
                                    draft = draft.copyWith(scopeAll: false);
                                  })
                                : null,
                          ),
                        ),
                      ],
                    ),
                    if (!draft.scopeAll && _children.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final kid in _children)
                            FilterChip(
                              label: Text(kid.displayName),
                              selected: draft.selectedChildIds.contains(kid.id),
                              onSelected: _canEditShared
                                  ? (selected) {
                                      setSheet(() {
                                        final next = List<String>.of(
                                          draft.selectedChildIds,
                                        );
                                        if (selected) {
                                          next.add(kid.id);
                                        } else {
                                          next.remove(kid.id);
                                        }
                                        draft = draft.copyWith(
                                          selectedChildIds: next,
                                        );
                                      });
                                    }
                                  : null,
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    _SharedPolicyRow(
                      icon: Icons.timer_outlined,
                      title: l10n.childrenListSharedDailyCap,
                      subtitle: l10n.childrenListSharedDailyCapValue(
                        draft.dailyCapHours,
                      ),
                      trailing: _canEditShared
                          ? DropdownButton<int>(
                              value: draft.dailyCapHours,
                              underline: const SizedBox.shrink(),
                              items: const [2, 3, 4, 5, 6]
                                  .map(
                                    (h) => DropdownMenuItem(
                                      value: h,
                                      child: Text('$h'),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (h) {
                                if (h == null) return;
                                setSheet(() {
                                  draft = draft.copyWith(dailyCapHours: h);
                                });
                              },
                            )
                          : null,
                    ),
                    _SharedPolicyRow(
                      icon: Icons.nightlight_round,
                      title: l10n.childrenListSharedBedtime,
                      subtitle: draft.bedtimeLabel,
                    ),
                    _SharedPolicyRow(
                      icon: Icons.language,
                      title: l10n.childrenListSharedWebFilter,
                      subtitle: l10n.childrenListSharedWebFilterHint,
                      trailing: Switch(
                        value: draft.webFilterOn,
                        onChanged: _canEditShared
                            ? (v) => setSheet(() {
                                draft = draft.copyWith(webFilterOn: v);
                              })
                            : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.p50,
                        borderRadius: BorderRadius.circular(radii.card),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.childrenListSharedExceptionsTitle,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: colors.ink,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.childrenListSharedExceptionsBody,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: colors.ink2,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    RoleGate(
                      profile: _panelProfile,
                      capability: PanelCapability.editChildRules,
                      builder: (context, disposition) {
                        if (disposition != PermissionDisposition.allow ||
                            !_canEditShared) {
                          return const SizedBox.shrink();
                        }
                        return Column(
                          children: [
                            const SizedBox(height: 14),
                            PrimaryBtn(
                              key: ChildrenListKeys.sharedApply,
                              label: l10n.childrenListSharedApply,
                              variant: PrimaryBtnVariant.mint,
                              onPressed: () async {
                                final source =
                                    widget.policySource ??
                                    AppScope.maybeOf(context)?.policies;
                                if (_usesRuntimeSources &&
                                    _loadedFamilyId != null &&
                                    source != null) {
                                  final saved = await source.saveSharedPolicy(
                                    _loadedFamilyId!,
                                    _runtimePolicyOf(draft),
                                  );
                                  if (!mounted) return;
                                  setState(() {
                                    _policies = _legacyPolicyOf(
                                      saved.sharedPolicy,
                                    );
                                  });
                                } else {
                                  await _repo.saveSharedPolicies(
                                    draft,
                                    familyId: _loadedFamilyId,
                                  );
                                  if (!mounted) return;
                                  setState(() => _policies = draft);
                                }
                                if (sheetContext.mounted) {
                                  Navigator.of(sheetContext).pop();
                                }
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;

    return Scaffold(
      key: ChildrenListKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        title: Text(
          l10n.childrenListTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
      ),
      body: !_isParent
          ? AppEmptyState(
              key: ChildrenListKeys.childLean,
              title: l10n.childrenListChildLeanTitle,
              message: l10n.childrenListChildLeanMessage,
            )
          : _loading
          ? ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                SizedBox(
                  height: 180,
                  child: Center(
                    key: ChildrenListKeys.loading,
                    child: Semantics(
                      label: l10n.childrenListLoadingSemantics,
                      child: const CircularProgressIndicator(),
                    ),
                  ),
                ),
                const ShellTabMoreTools(tabId: 'kids'),
              ],
            )
          : _loadFailed
          ? ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                AppErrorState(
                  key: ChildrenListKeys.error,
                  kind: AppErrorKind.network,
                  onRetry: _load,
                ),
                const ShellTabMoreTools(tabId: 'kids'),
              ],
            )
          : !_hasVisibleRoster
          ? ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                AppEmptyState(
                  key: ChildrenListKeys.empty,
                  title: l10n.childrenListEmptyTitle,
                  message: l10n.childrenListEmptyMessage,
                  actionLabel: l10n.childrenListAddChild,
                  onAction: _goAddChild,
                ),
                const ShellTabMoreTools(tabId: 'kids'),
              ],
            )
          : ListView(
              key: ChildrenListKeys.list,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                if (isChildrenListSeededProvenance(_rosterProvenance)) ...[
                  BannerNote(
                    key: ChildrenListKeys.localDemoBanner,
                    message: l10n.childrenListLocalDemoBanner,
                    variant: BannerVariant.a,
                    leading: Text(
                      'ℹ',
                      style: TextStyle(fontSize: 18, color: colors.ink),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (_usesRuntimeSources &&
                    _rosterOrigin == RuntimeDataOrigin.localOnly) ...[
                  BannerNote(
                    key: ChildrenListKeys.localOnlyBanner,
                    message: l10n.childrenListLocalOnlyBanner,
                    variant: BannerVariant.a,
                    leading: Icon(Icons.info_outline, color: colors.ink),
                  ),
                  const SizedBox(height: 8),
                ],
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: RoleGate(
                    profile: _panelProfile,
                    capability: PanelCapability.manageFamily,
                    builder: (context, disposition) => ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48),
                      child: TextButton(
                        key: ChildrenListKeys.addChild,
                        onPressed:
                            disposition == PermissionDisposition.allow &&
                                _canCreateChild
                            ? _goAddChild
                            : null,
                        style: TextButton.styleFrom(
                          foregroundColor: colors.tealDeep,
                          backgroundColor: colors.teal100,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(radii.btn),
                          ),
                        ),
                        child: Text(
                          l10n.childrenListAddChild,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Semantics(
                  container: true,
                  label: l10n.childrenListListSemantics,
                  child: Column(
                    children: [
                      for (final kid in _children) ...[
                        _ChildRosterCard(
                          entry: kid,
                          onTap: () => _goProfile(kid.id),
                          onDelete: _canDeleteChild
                              ? () => _deleteChild(kid.id)
                              : null,
                        ),
                        const SizedBox(height: 10),
                      ],
                      for (final child in _runtimeRoster) ...[
                        if (child.hasCompleteDisplayProfile)
                          _RuntimeChildRosterCard(
                            child: child,
                            device: _deviceSnapshot.forChild(child.childId),
                            onTap: () => _goProfile(child.childId.value),
                          )
                        else
                          _ProfileRepairCard(
                            childId: child.childId.value,
                            onRepair: () => _goProfile(child.childId.value),
                          ),
                        const SizedBox(height: 10),
                      ],
                      for (final child in _profileRepairs) ...[
                        _ProfileRepairCard(
                          childId: child.childId.value,
                          onRepair: () => _goProfile(child.childId.value),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
                ),
                Semantics(
                  button: true,
                  label: l10n.childrenListSharedPoliciesTitle,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      key: ChildrenListKeys.sharedPoliciesCard,
                      onTap: _openSharedPolicies,
                      borderRadius: BorderRadius.circular(radii.card),
                      child: Ink(
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(radii.card),
                          border: Border.all(color: colors.p400, width: 1.5),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.settings_outlined,
                                color: colors.p600,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.childrenListSharedPoliciesTitle,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                        color: colors.ink,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      l10n.childrenListSharedPoliciesSubtitle,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: colors.ink2,
                                        height: 1.45,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right, color: colors.ink2),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const ShellTabMoreTools(tabId: 'kids'),
              ],
            ),
    );
  }
}

class _SharedPolicyRow extends StatelessWidget {
  const _SharedPolicyRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 22, color: colors.p600),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: colors.ink,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: colors.ink2,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _RuntimeChildRosterCard extends StatelessWidget {
  const _RuntimeChildRosterCard({
    required this.child,
    required this.device,
    required this.onTap,
  });

  final FamilyRosterChild child;
  final FamilyChildDeviceSummary? device;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final name = child.displayName!;
    final age = l10n.addChildAgeYears(formatAppInt(child.ageYears!));
    final deviceStateLabel = _deviceStateLabel(l10n, device);
    final healthLabel = _healthLabel(l10n, device);
    final locationLabel =
        device?.locationLabel ?? l10n.childrenListDeviceStateUnavailable;
    final batteryLabel = _batteryLabel(l10n, device);
    final deviceVariant = _deviceVariant(device);

    return Semantics(
      button: true,
      label: l10n.childrenListRuntimeRowSemantics(
        name,
        age,
        '$locationLabel; $batteryLabel; $healthLabel',
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ChildrenListKeys.childRow(child.childId.value),
          onTap: onTap,
          borderRadius: BorderRadius.circular(radii.card),
          child: Ink(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(radii.card),
              boxShadow: [Theme.of(context).extension<FamilyShadows>()!.shCard],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  _StatusAvatar(
                    emoji: child.avatarEmoji ?? '🧒',
                    color: _themeColor(colors, child.themeColor),
                    warnRing:
                        device?.connectionState ==
                        ChildDeviceConnectionState.needsAttention,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$name — $age',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: colors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        _runtimeMetaLine(
                          icon: Icons.location_on_outlined,
                          label: locationLabel,
                          colors: colors,
                        ),
                        _runtimeMetaLine(
                          icon: _batteryIcon(device),
                          label: batteryLabel,
                          colors: colors,
                        ),
                        _runtimeMetaLine(
                          icon: Icons.devices_other_outlined,
                          label:
                              '${device?.deviceLabel ?? deviceStateLabel} · $deviceStateLabel',
                          colors: colors,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tag(label: healthLabel, variant: deviceVariant),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _themeColor(FamilyColors colors, String? themeColor) =>
      switch (themeColor) {
        'sky' => colors.sky,
        'amber' => colors.amber,
        'coral' => colors.coral,
        'mint' => colors.mint,
        'teal' => colors.teal600,
        _ => colors.p500,
      };

  TagVariant _deviceVariant(FamilyChildDeviceSummary? device) =>
      switch (device?.connectionState) {
        ChildDeviceConnectionState.active => TagVariant.g,
        ChildDeviceConnectionState.needsAttention => TagVariant.a,
        ChildDeviceConnectionState.pairing => TagVariant.p,
        ChildDeviceConnectionState.noDevice => TagVariant.p,
        ChildDeviceConnectionState.unavailable || null => TagVariant.p,
      };

  String _deviceStateLabel(
    AppLocalizations l10n,
    FamilyChildDeviceSummary? device,
  ) {
    if (device == null) return l10n.childrenListDeviceStateUnavailable;
    return switch (device.connectionState) {
      ChildDeviceConnectionState.unavailable =>
        l10n.childrenListDeviceStateUnavailable,
      ChildDeviceConnectionState.noDevice => l10n.childrenListDeviceNotLinked,
      ChildDeviceConnectionState.pairing => l10n.childrenListDevicePairing,
      ChildDeviceConnectionState.active => l10n.childrenListDeviceActive,
      ChildDeviceConnectionState.needsAttention =>
        l10n.childrenListDeviceNeedsAttention,
    };
  }

  String _batteryLabel(
    AppLocalizations l10n,
    FamilyChildDeviceSummary? device,
  ) {
    final level = device?.batteryLevel;
    if (level == null) return l10n.childrenListDeviceStateUnavailable;
    final status = device?.batteryStatus == 'charging'
        ? 'charging'
        : 'unplugged';
    return '$level% · $status';
  }

  String _healthLabel(AppLocalizations l10n, FamilyChildDeviceSummary? device) {
    if (device == null || !device.hasTelemetry) {
      return _deviceStateLabel(l10n, device);
    }
    if (device.connectionState == ChildDeviceConnectionState.needsAttention) {
      return 'Battery low';
    }
    if (device.batteryStatus == 'charging') return 'Charging';
    return 'Healthy';
  }

  IconData _batteryIcon(FamilyChildDeviceSummary? device) {
    if (device?.batteryLevel == null) return Icons.battery_unknown_outlined;
    if (device?.batteryStatus == 'charging') return Icons.battery_charging_full;
    if (device!.batteryLevel! <= 15) return Icons.battery_alert_outlined;
    if (device.batteryLevel! <= 45) return Icons.battery_3_bar_outlined;
    return Icons.battery_full_outlined;
  }
}

Widget _runtimeMetaLine({
  required IconData icon,
  required String label,
  required FamilyColors colors,
}) => Padding(
  padding: const EdgeInsets.only(top: 2),
  child: Row(
    children: [
      Icon(icon, size: 14, color: colors.ink2),
      const SizedBox(width: 3),
      Expanded(
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: colors.ink2,
          ),
        ),
      ),
    ],
  ),
);

class _ProfileRepairCard extends StatelessWidget {
  const _ProfileRepairCard({required this.childId, required this.onRepair});

  final String childId;
  final VoidCallback onRepair;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    return Semantics(
      container: true,
      label: l10n.childrenListProfileRepairMessage,
      child: DecoratedBox(
        key: ChildrenListKeys.profileRepair(childId),
        decoration: BoxDecoration(
          color: colors.amber100,
          borderRadius: BorderRadius.circular(radii.card),
          border: Border.all(color: colors.amber),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(Icons.assignment_late_outlined, color: colors.ink),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.childrenListProfileRepairTitle,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: colors.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      l10n.childrenListProfileRepairMessage,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: colors.ink2,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: onRepair,
                child: Text(l10n.childrenListProfileRepairCta),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final initial = name.trim().isEmpty
        ? '?'
        : String.fromCharCode(name.trim().runes.first);
    return Semantics(
      excludeSemantics: true,
      child: Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: colors.p100, shape: BoxShape.circle),
        child: Text(
          initial,
          style: TextStyle(
            color: colors.p700,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}

class _ChildRosterCard extends StatelessWidget {
  const _ChildRosterCard({
    required this.entry,
    required this.onTap,
    this.onDelete,
  });

  final ChildrenListEntry entry;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final ageText = l10n.addChildAgeYears(formatAppInt(entry.ageYears));
    final healthLabel = switch (entry.health) {
      ChildListHealth.excellent => l10n.childrenListHealthExcellent,
      ChildListHealth.atRisk => l10n.childrenListHealthAtRisk,
    };
    final healthVariant = switch (entry.health) {
      ChildListHealth.excellent => TagVariant.g,
      ChildListHealth.atRisk => TagVariant.a,
    };
    final semantics = l10n.childrenListRowSemantics(
      entry.displayName,
      ageText,
      entry.locationLabel,
      entry.batteryLabel,
      healthLabel,
    );

    return Semantics(
      button: true,
      label: semantics,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ChildrenListKeys.childRow(entry.id),
          onTap: onTap,
          borderRadius: BorderRadius.circular(radii.card),
          child: Ink(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(radii.card),
              boxShadow: [Theme.of(context).extension<FamilyShadows>()!.shCard],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  _StatusAvatar(
                    emoji: entry.emoji,
                    color: entry.resolveColor(colors),
                    warnRing: entry.warnRing,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${entry.displayName} — $ageText',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: colors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        ..._childMetaLines(
                          l10n: l10n,
                          colors: colors,
                          entry: entry,
                        ),
                      ],
                    ),
                  ),
                  if (onDelete != null)
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline),
                    ),
                  const SizedBox(width: 8),
                  Tag(label: healthLabel, variant: healthVariant),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

extension on ChildrenListEntry {
  Color resolveColor(FamilyColors colors) => switch (swatch) {
    DayChildSwatch.purple => colors.p500,
    DayChildSwatch.sky => colors.sky,
    DayChildSwatch.amber => colors.amber,
  };

  bool get hasLocationMeta =>
      locationLabel.trim().isNotEmpty || lastSeenLabel.trim().isNotEmpty;

  bool get hasDeviceMeta =>
      batteryLabel.trim().isNotEmpty || timeLeftLabel.trim().isNotEmpty;
}

List<Widget> _childMetaLines({
  required AppLocalizations l10n,
  required FamilyColors colors,
  required ChildrenListEntry entry,
}) {
  final style = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w600,
    color: colors.ink2,
  );
  if (!entry.hasLocationMeta && !entry.hasDeviceMeta) {
    return [
      Text(
        l10n.childrenListDeviceNotLinked,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      ),
    ];
  }
  final lines = <Widget>[];
  if (entry.hasLocationMeta) {
    final parts = <String>[
      if (entry.locationLabel.trim().isNotEmpty) '📍 ${entry.locationLabel}',
      if (entry.lastSeenLabel.trim().isNotEmpty) entry.lastSeenLabel,
    ];
    lines.add(
      Text(
        parts.join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      ),
    );
  }
  if (entry.hasDeviceMeta) {
    final parts = <String>[
      if (entry.batteryLabel.trim().isNotEmpty) '🔋 ${entry.batteryLabel}',
      if (entry.timeLeftLabel.trim().isNotEmpty)
        '⏱ ${l10n.childrenListTimeLeft(entry.timeLeftLabel)}',
    ];
    lines.add(
      Text(
        parts.join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      ),
    );
  }
  return lines;
}

class _StatusAvatar extends StatelessWidget {
  const _StatusAvatar({
    required this.emoji,
    required this.color,
    required this.warnRing,
  });

  final String emoji;
  final Color color;
  final bool warnRing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final ringColor = warnRing ? colors.amber : colors.mint;

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ringColor, width: 2.5),
      ),
      padding: const EdgeInsets.all(2),
      child: DecoratedBox(
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
      ),
    );
  }
}
