import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/app/role_guard.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/features/n14_studio/attribution_reward_models.dart';
import 'package:family_os/features/n14_studio/attribution_reward_repository.dart';
import 'package:family_os/features/n14_studio/studio_ux_bridge.dart';

/// Widget keys for SCR-FAT-045 acceptance.
abstract final class AttributionRewardKeys {
  static const screen = Key('attribution_reward_screen');
  static const loading = Key('attribution_reward_loading');
  static const empty = Key('attribution_reward_empty');
  static const body = Key('attribution_reward_body');
  static const whoCard = Key('attribution_reward_who');
  static const scheduleField = Key('attribution_reward_schedule');
  static const rewardsCard = Key('attribution_reward_rewards');
  static const masteryBanner = Key('attribution_reward_mastery');
  static const assignCta = Key('attribution_reward_assign');
  static const libraryCta = Key('attribution_reward_library');
  static const observerHint = Key('attribution_reward_observer');
  static const childLean = Key('attribution_reward_child_lean');
  static const sosCta = Key('attribution_reward_sos');
  static const sosIconCta = Key('attribution_reward_sos_icon');

  static Key childChip(String id) => Key('attribution_reward_child_$id');
  static Key rewardSwitch(String id) => Key('attribution_reward_swt_$id');
}

/// SCR-FAT-045 — الإسناد والمكافأة (attribution and reward).
///
/// Prototype FAT-045 · studio wave · Rule 12/23 · mother levels · mock-first ·
/// ARB · P-4 SOS · minutes-only rewards (ع-١) · CTA → FAT-046 community library.
class AttributionRewardScreen extends StatefulWidget {
  const AttributionRewardScreen({
    super.key,
    this.repository,
    this.sosFire,
    this.roleOverride,
    this.motherLevel = MotherLevel.partner,
    this.onSos,
    this.onNavigate,
  });

  /// Rule 25 seam — null → [stage1AttributionRewardRepository].
  final AttributionRewardRepository? repository;

  /// P-4 SOS seam — null → [stage1SosFireService].
  final SosFireService? sosFire;

  /// Test seam — when set, ignores [CurrentRole].
  final AppRole? roleOverride;

  /// Mother authority — observer view-only; partner/full assign like father.
  final MotherLevel motherLevel;

  final VoidCallback? onSos;

  /// Test seam — intercepts navigation by screen id.
  final void Function(String screenId)? onNavigate;

  @override
  State<AttributionRewardScreen> createState() =>
      _AttributionRewardScreenState();
}

class _AttributionRewardScreenState extends State<AttributionRewardScreen> {
  late AttributionRewardRepository _repo;
  late final SosFireService _sos;
  var _sosBusy = false;
  var _loading = true;
  AttributionRewardSnapshot _snap = const AttributionRewardSnapshot();

  AppRole get _role {
    final override = widget.roleOverride;
    if (override != null) return override;
    return CurrentRole.maybeNotifierOf(context)?.value ?? AppRole.father;
  }

  bool get _isChild => _role == AppRole.child;

  bool get _isParent => _role == AppRole.father || _role == AppRole.mother;

  bool get _isObserverMother =>
      _role == AppRole.mother && widget.motherLevel == MotherLevel.observer;

  /// Father always; mother partner/full (prototype §7 — mother can create).
  bool get _canEdit {
    if (_role == AppRole.father) return true;
    if (_role == AppRole.mother) {
      return widget.motherLevel == MotherLevel.partner ||
          widget.motherLevel == MotherLevel.full;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? Stage1StudioRuntime.attribution;
    _sos = widget.sosFire ?? stage1SosFireService;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
    });
  }

  @override
  void didUpdateWidget(covariant AttributionRewardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      _repo = widget.repository ?? Stage1StudioRuntime.attribution;
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final snap = await _repo.load();
    if (!mounted) return;
    setState(() {
      _snap = snap;
      _loading = false;
    });
  }

  Future<void> _openSos() async {
    if (_sosBusy) return;
    if (widget.onSos != null) {
      widget.onSos!();
      return;
    }
    setState(() => _sosBusy = true);
    await _sos.fire(childId: 'family');
    if (!mounted) return;
    setState(() => _sosBusy = false);
    context.push(screenPath('SCR-FAT-018'));
  }

  void _go(String screenId) {
    if (widget.onNavigate != null) {
      widget.onNavigate!(screenId);
      return;
    }
    context.push(screenPath(screenId));
  }

  void _blockedToast(AppLocalizations l10n) {
    AppToast.show(context, message: l10n.attributionRewardObserverBlocked);
  }

  String _childName(AppLocalizations l10n, AttributionChild child) {
    return switch (child.nameKey) {
      'one' => l10n.attributionRewardChildOne,
      'two' => l10n.attributionRewardChildTwo,
      'three' => l10n.attributionRewardChildThree,
      _ => l10n.attributionRewardChildOne,
    };
  }

  String _scheduleLabel(AppLocalizations l10n, AttributionSchedule s) {
    return switch (s) {
      AttributionSchedule.tomorrowAfterSchool =>
        l10n.attributionRewardScheduleTomorrow,
      AttributionSchedule.today => l10n.attributionRewardScheduleToday,
      AttributionSchedule.weekend => l10n.attributionRewardScheduleWeekend,
    };
  }

  String _rewardTitle(AppLocalizations l10n, AttributionRewardToggle reward) {
    return switch (reward.kind) {
      AttributionRewardKind.wallet => l10n.attributionRewardWalletMinutes(
        reward.minutes,
      ),
      AttributionRewardKind.play => l10n.attributionRewardPlayMinutes(
        reward.minutes,
      ),
    };
  }

  void _onSelectChild(String childId) {
    final l10n = AppLocalizations.of(context);
    if (!_canEdit) {
      _blockedToast(l10n);
      return;
    }
    setState(() => _snap = _snap.withSelectedChild(childId));
  }

  void _onSchedule(AttributionSchedule next) {
    final l10n = AppLocalizations.of(context);
    if (!_canEdit) {
      _blockedToast(l10n);
      return;
    }
    setState(() => _snap = _snap.withSchedule(next));
  }

  void _onToggleReward(String rewardId, bool enabled) {
    final l10n = AppLocalizations.of(context);
    if (!_canEdit) {
      _blockedToast(l10n);
      return;
    }
    setState(() => _snap = _snap.withRewardEnabled(rewardId, enabled));
  }

  void _onAssign() async {
    final l10n = AppLocalizations.of(context);
    if (!_canEdit) {
      _blockedToast(l10n);
      return;
    }
    if (!_snap.canAssign) {
      AppToast.show(context, message: l10n.attributionRewardCannotAssignToast);
      return;
    }
    final child = _snap.selectedChild!;
    final name = _childName(l10n, child);
    final minutes = _snap.totalEnabledMinutes;
    final snap = await _repo.assign();
    if (!mounted) return;
    setState(() => _snap = snap);
    AppToast.show(
      context,
      message: l10n.attributionRewardAssignedToast(name, minutes),
    );
    _go('SCR-FAT-046');
  }

  void _onLibrary() {
    _go('SCR-FAT-046');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;

    return Scaffold(
      key: AttributionRewardKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.ink,
        title: Text(
          l10n.attributionRewardTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          IconButton(
            key: AttributionRewardKeys.sosIconCta,
            tooltip: l10n.spineCtaSosSemantics,
            onPressed: _sosBusy ? null : _openSos,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            style: const ButtonStyle(
              tapTargetSize: MaterialTapTargetSize.padded,
              minimumSize: WidgetStatePropertyAll(Size(48, 48)),
            ),
            icon: Icon(Icons.sos, color: colors.coral),
          ),
        ],
      ),
      body: SafeArea(child: _buildBody(context, l10n, colors)),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n,
    FamilyColors colors,
  ) {
    if (_isChild) {
      return AppEmptyState(
        key: AttributionRewardKeys.childLean,
        title: l10n.attributionRewardChildLeanTitle,
        message: l10n.attributionRewardChildLeanMessage,
        actionLabel: l10n.attributionRewardSosCta,
        onAction: _sosBusy ? null : _openSos,
      );
    }

    if (!_isParent) {
      return AppEmptyState(
        key: AttributionRewardKeys.childLean,
        title: l10n.attributionRewardChildLeanTitle,
        message: l10n.attributionRewardChildLeanMessage,
      );
    }

    if (_loading) {
      return Center(
        key: AttributionRewardKeys.loading,
        child: Semantics(
          label: l10n.attributionRewardLoadingSemantics,
          child: const CircularProgressIndicator(),
        ),
      );
    }

    if (_snap.isEmpty) {
      return AppEmptyState(
        key: AttributionRewardKeys.empty,
        title: l10n.attributionRewardEmptyTitle,
        message: l10n.attributionRewardEmptyMessage,
        actionLabel: l10n.attributionRewardSosCta,
        onAction: _sosBusy ? null : _openSos,
      );
    }

    final radii = Theme.of(context).extension<FamilyRadii>()!;

    return SingleChildScrollView(
      key: AttributionRewardKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isObserverMother) ...[
            BannerNote(
              key: AttributionRewardKeys.observerHint,
              variant: BannerVariant.a,
              message: l10n.attributionRewardObserverHint,
            ),
            const SizedBox(height: 12),
          ],
          BannerNote(
            key: AttributionRewardKeys.masteryBanner,
            variant: BannerVariant.t,
            leading: Icon(
              Icons.emoji_events_outlined,
              color: colors.tealDeep,
              size: 20,
            ),
            message: l10n.attributionRewardMasteryBanner(_snap.masteryPercent),
          ),
          const SizedBox(height: 12),
          _WhoCard(
            snap: _snap,
            colors: colors,
            radii: radii,
            l10n: l10n,
            canEdit: _canEdit,
            nameOf: (c) => _childName(l10n, c),
            onSelect: _onSelectChild,
          ),
          const SizedBox(height: 12),
          _ScheduleField(
            schedule: _snap.schedule,
            colors: colors,
            radii: radii,
            l10n: l10n,
            canEdit: _canEdit,
            labelOf: (s) => _scheduleLabel(l10n, s),
            onChanged: _onSchedule,
          ),
          const SizedBox(height: 12),
          _RewardsCard(
            snap: _snap,
            colors: colors,
            radii: radii,
            l10n: l10n,
            canEdit: _canEdit,
            titleOf: (r) => _rewardTitle(l10n, r),
            onToggle: _onToggleReward,
          ),
          const SizedBox(height: 16),
          PrimaryBtn(
            key: AttributionRewardKeys.assignCta,
            label: l10n.attributionRewardAssignCta,
            variant: PrimaryBtnVariant.primary,
            onPressed: (_canEdit && _snap.canAssign) ? _onAssign : null,
          ),
          const SizedBox(height: 10),
          PrimaryBtn(
            key: AttributionRewardKeys.libraryCta,
            label: l10n.attributionRewardLibraryCta,
            variant: PrimaryBtnVariant.sec,
            onPressed: _onLibrary,
          ),
          const SizedBox(height: 12),
          PrimaryBtn(
            key: AttributionRewardKeys.sosCta,
            label: l10n.attributionRewardSosCta,
            variant: PrimaryBtnVariant.coral,
            onPressed: _sosBusy ? null : _openSos,
          ),
        ],
      ),
    );
  }
}

class _WhoCard extends StatelessWidget {
  const _WhoCard({
    required this.snap,
    required this.colors,
    required this.radii,
    required this.l10n,
    required this.canEdit,
    required this.nameOf,
    required this.onSelect,
  });

  final AttributionRewardSnapshot snap;
  final FamilyColors colors;
  final FamilyRadii radii;
  final AppLocalizations l10n;
  final bool canEdit;
  final String Function(AttributionChild) nameOf;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: AttributionRewardKeys.whoCard,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radii.card),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.attributionRewardWhoHeading,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final child in snap.children)
                  _ChildChip(
                    child: child,
                    selected: child.id == snap.selectedChildId,
                    colors: colors,
                    name: nameOf(child),
                    enabled: canEdit,
                    onTap: () => onSelect(child.id),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChildChip extends StatelessWidget {
  const _ChildChip({
    required this.child,
    required this.selected,
    required this.colors,
    required this.name,
    required this.enabled,
    required this.onTap,
  });

  final AttributionChild child;
  final bool selected;
  final FamilyColors colors;
  final String name;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final avatarColor = child.resolveColor(colors);
    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: name,
      child: Opacity(
        opacity: selected ? 1 : 0.4,
        child: InkWell(
          key: AttributionRewardKeys.childChip(child.id),
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(40),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? colors.p500 : colors.border,
                      width: selected ? 2.5 : 1.5,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: avatarColor,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          child.emoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: colors.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScheduleField extends StatelessWidget {
  const _ScheduleField({
    required this.schedule,
    required this.colors,
    required this.radii,
    required this.l10n,
    required this.canEdit,
    required this.labelOf,
    required this.onChanged,
  });

  final AttributionSchedule schedule;
  final FamilyColors colors;
  final FamilyRadii radii;
  final AppLocalizations l10n;
  final bool canEdit;
  final String Function(AttributionSchedule) labelOf;
  final ValueChanged<AttributionSchedule> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: AttributionRewardKeys.scheduleField,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radii.card),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.attributionRewardScheduleLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: colors.ink2,
              ),
            ),
            const SizedBox(height: 4),
            DropdownButtonHideUnderline(
              child: DropdownButton<AttributionSchedule>(
                value: schedule,
                isExpanded: true,
                onChanged: canEdit
                    ? (v) {
                        if (v != null) onChanged(v);
                      }
                    : null,
                items: [
                  for (final s in AttributionSchedule.values)
                    DropdownMenuItem(
                      value: s,
                      child: Text(
                        labelOf(s),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: colors.ink,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardsCard extends StatelessWidget {
  const _RewardsCard({
    required this.snap,
    required this.colors,
    required this.radii,
    required this.l10n,
    required this.canEdit,
    required this.titleOf,
    required this.onToggle,
  });

  final AttributionRewardSnapshot snap;
  final FamilyColors colors;
  final FamilyRadii radii;
  final AppLocalizations l10n;
  final bool canEdit;
  final String Function(AttributionRewardToggle) titleOf;
  final void Function(String id, bool enabled) onToggle;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: AttributionRewardKeys.rewardsCard,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radii.card),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.attributionRewardRewardsHeading(snap.masteryPercent),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 8),
            for (final reward in snap.rewards)
              _RewardRow(
                reward: reward,
                colors: colors,
                title: titleOf(reward),
                subtitle: reward.autoAdded
                    ? l10n.attributionRewardAutoAdded
                    : null,
                enabled: canEdit,
                onChanged: (v) => onToggle(reward.id, v),
              ),
          ],
        ),
      ),
    );
  }
}

class _RewardRow extends StatelessWidget {
  const _RewardRow({
    required this.reward,
    required this.colors,
    required this.title,
    required this.enabled,
    required this.onChanged,
    this.subtitle,
  });

  final AttributionRewardToggle reward;
  final FamilyColors colors;
  final String title;
  final String? subtitle;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, color: colors.tealDeep, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: colors.ink,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.ink2,
                    ),
                  ),
              ],
            ),
          ),
          Switch.adaptive(
            key: AttributionRewardKeys.rewardSwitch(reward.id),
            value: reward.enabled,
            onChanged: enabled ? onChanged : null,
          ),
        ],
      ),
    );
  }
}
