import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/app_error_state.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/components/tag.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/identity/child_device_management_repository.dart';
import 'package:family_os/core/identity/identity_scope.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n01_linking/add_child_screen.dart';
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
    this.roleOverride,
    this.onAddChild,
    this.onOpenChildProfile,
  });

  /// Null → [stage1ChildrenListRepository].
  final ChildrenListRepository? repository;
  final ChildDeviceManagementRepository? managementRepository;

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
  SharedChildrenPolicies _policies = const SharedChildrenPolicies();

  AppRole get _role =>
      widget.roleOverride ??
      CurrentRole.maybeNotifierOf(context)?.value ??
      AppRole.father;

  bool get _isParent => _role == AppRole.father || _role == AppRole.mother;

  bool get _canEditShared => _role == AppRole.father;
  bool get _canCreateChild {
    final runtime = CurrentIdentity.maybeOf(context);
    if (runtime == null) return _role == AppRole.father;
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
      final familyId = CurrentIdentity.maybeOf(context)?.activeFamilyId;
      final kids = await _repo.listChildren(familyId: familyId);
      final managed = familyId == null
          ? const <ManagedChildRecord>[]
          : _managementRepo.listChildren(familyId);
      final merged = _mergeChildren(kids, managed);
      final policies = await _repo.loadSharedPolicies();
      if (!mounted) return;
      setState(() {
        _children = merged;
        _policies = policies;
        _loading = false;
        _loadFailed = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _children = const [];
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  List<ChildrenListEntry> _mergeChildren(
    List<ChildrenListEntry> fromRepo,
    List<ManagedChildRecord> managed,
  ) {
    if (managed.isEmpty) return fromRepo;
    final byId = <String, ChildrenListEntry>{
      for (final item in fromRepo) item.id: item,
    };
    final next = <ChildrenListEntry>[];
    for (final child in managed) {
      final record = byId[child.childId.value];
      if (record != null) {
        next.add(record);
        continue;
      }
      next.add(
        ChildrenListEntry(
          id: child.childId.value,
          displayName: child.childId.value,
          emoji: '🧒',
          swatch: DayChildSwatch.purple,
          ageYears: 0,
          locationLabel: '',
          lastSeenLabel: '',
          batteryLabel: '',
          timeLeftLabel: '',
          health: ChildListHealth.excellent,
        ),
      );
    }
    return next;
  }

  void _goAddChild() {
    if (!_canCreateChild) {
      final l10n = AppLocalizations.of(context);
      AppToast.show(context, message: l10n.childScreenTimeReadOnly);
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
      AppToast.show(context, message: l10n.childScreenTimeReadOnly);
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
                    if (_canEditShared) ...[
                      const SizedBox(height: 14),
                      PrimaryBtn(
                        key: ChildrenListKeys.sharedApply,
                        label: l10n.childrenListSharedApply,
                        variant: PrimaryBtnVariant.mint,
                        onPressed: () async {
                          await _repo.saveSharedPolicies(draft);
                          if (!mounted) return;
                          setState(() => _policies = draft);
                          if (sheetContext.mounted) {
                            Navigator.of(sheetContext).pop();
                          }
                        },
                      ),
                    ],
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
          ? Center(
              key: ChildrenListKeys.loading,
              child: Semantics(
                label: l10n.childrenListLoadingSemantics,
                child: const CircularProgressIndicator(),
              ),
            )
          : _loadFailed
          ? AppErrorState(
              key: ChildrenListKeys.error,
              kind: AppErrorKind.network,
              onRetry: _load,
            )
          : _children.isEmpty
          ? AppEmptyState(
              key: ChildrenListKeys.empty,
              title: l10n.childrenListEmptyTitle,
              message: l10n.childrenListEmptyMessage,
              actionLabel: l10n.childrenListAddChild,
              onAction: _goAddChild,
            )
          : ListView(
              key: ChildrenListKeys.list,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: TextButton(
                      key: ChildrenListKeys.addChild,
                      onPressed: _goAddChild,
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
                              Icon(Icons.chevron_left, color: colors.ink2),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
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
    final ageText = l10n.addChildAgeYears(toEasternDigits(entry.ageYears));
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
                        Text(
                          '📍 ${entry.locationLabel} · ${entry.lastSeenLabel}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: colors.ink2,
                          ),
                        ),
                        Text(
                          '🔋 ${entry.batteryLabel} · ⏱ ${l10n.childrenListTimeLeft(entry.timeLeftLabel)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: colors.ink2,
                          ),
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
