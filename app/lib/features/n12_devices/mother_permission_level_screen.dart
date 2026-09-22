import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/components/tag.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/features/n12_devices/mother_permission_level_repository.dart';

/// Widget keys for SCR-FAT-031 acceptance.
abstract final class MotherPermissionLevelKeys {
  static const screen = Key('mother_permission_level_screen');
  static const ownerOnly = Key('mother_permission_level_owner_only');
  static const childLean = Key('mother_permission_level_child_lean');
  static const fixedRightsBanner =
      Key('mother_permission_level_fixed_rights');
  static const auditSection = Key('mother_permission_level_audit');
  static const auditEmpty = Key('mother_permission_level_audit_empty');
  static const sosCta = Key('mother_permission_level_sos');
  static const sosIconCta = Key('mother_permission_level_sos_icon');
  static const backButton = Key('mother_permission_level_back');
  static const downgradeDialog = Key('mother_permission_level_downgrade_dialog');
  static const upgradeDialog = Key('mother_permission_level_upgrade_dialog');
  static const downgradeConfirm =
      Key('mother_permission_level_downgrade_confirm');
  static const upgradeConfirm = Key('mother_permission_level_upgrade_confirm');
  static const dialogCancel = Key('mother_permission_level_dialog_cancel');

  static Key levelRow(MotherLevel level) =>
      Key('mother_permission_level_${level.name}');

  static Key auditRow(int index) =>
      Key('mother_permission_level_audit_$index');
}

/// SCR-FAT-031 — مستوى صلاحية الأم.
///
/// Prototype FAT-031 · ADR-035 / doc 20: three levels (observer / partner /
/// full). Father-owner only may change. Downgrade needs double-confirm;
/// upgrade uses trust framing. Fixed rights banner (SOS · call · location)
/// never removed (P-4). Audit log immutable. Mock-first · Rule 12/23.
class MotherPermissionLevelScreen extends StatefulWidget {
  const MotherPermissionLevelScreen({
    super.key,
    this.repository,
    this.sosFire,
    this.roleOverride,
    this.onBack,
    this.onSos,
  });

  /// Rule 25 seam — null → [stage1MotherPermissionLevelRepository].
  final MotherPermissionLevelRepository? repository;

  /// P-4 SOS seam — null → [stage1SosFireService].
  final SosFireService? sosFire;

  /// Test seam — when set, ignores [CurrentRole].
  final AppRole? roleOverride;

  final VoidCallback? onBack;
  final VoidCallback? onSos;

  @override
  State<MotherPermissionLevelScreen> createState() =>
      _MotherPermissionLevelScreenState();
}

class _MotherPermissionLevelScreenState
    extends State<MotherPermissionLevelScreen> {
  late MotherPermissionLevelRepository _repo;
  late final SosFireService _sos;
  var _sosBusy = false;

  AppRole get _role {
    final override = widget.roleOverride;
    if (override != null) return override;
    return CurrentRole.of(context);
  }

  bool get _isChild => _role == AppRole.child;
  bool get _isOwner => _role == AppRole.father;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? stage1MotherPermissionLevelRepository;
    _sos = widget.sosFire ?? stage1SosFireService;
    _repo.addListener(_onRepo);
  }

  @override
  void didUpdateWidget(covariant MotherPermissionLevelScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      _repo.removeListener(_onRepo);
      _repo = widget.repository ?? stage1MotherPermissionLevelRepository;
      _repo.addListener(_onRepo);
    }
  }

  @override
  void dispose() {
    _repo.removeListener(_onRepo);
    super.dispose();
  }

  void _onRepo() {
    if (mounted) setState(() {});
  }

  void _goBack() {
    if (widget.onBack != null) {
      widget.onBack!();
      return;
    }
    if (context.canPop()) {
      context.pop();
    }
  }

  Future<void> _fireSos() async {
    if (_sosBusy) return;
    setState(() => _sosBusy = true);
    try {
      if (widget.onSos != null) {
        widget.onSos!();
        return;
      }
      await _sos.fire(childId: 'parent_local');
      if (!mounted) return;
      context.go('/scr-fat-018');
    } finally {
      if (mounted) setState(() => _sosBusy = false);
    }
  }

  String _levelTitle(AppLocalizations l10n, MotherLevel level) {
    return switch (level) {
      MotherLevel.observer => l10n.inviteMotherLevelObserverTitle,
      MotherLevel.partner => l10n.inviteMotherLevelPartnerTitle,
      MotherLevel.full => l10n.inviteMotherLevelFullTitle,
    };
  }

  String _levelDesc(AppLocalizations l10n, MotherLevel level) {
    return switch (level) {
      MotherLevel.observer => l10n.motherPermissionLevelObserverDesc,
      MotherLevel.partner => l10n.motherPermissionLevelPartnerDesc,
      MotherLevel.full => l10n.motherPermissionLevelFullDesc,
    };
  }

  String _auditTransition(AppLocalizations l10n, MotherLevelAuditEntry e) {
    return l10n.motherPermissionLevelAuditTransition(
      _levelTitle(l10n, e.from),
      _levelTitle(l10n, e.to),
    );
  }

  String _formatAuditWhen(DateTime at) {
    final d = at.day.toString().padLeft(2, '0');
    final m = at.month.toString().padLeft(2, '0');
    return '$d/$m/${at.year}';
  }

  Future<void> _onSelectLevel(MotherLevel next) async {
    if (!_isOwner) return;
    final current = _repo.level;
    if (next == current) return;

    final l10n = AppLocalizations.of(context);
    final nextName = _levelTitle(l10n, next);

    if (isMotherLevelDowngrade(current, next)) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          key: MotherPermissionLevelKeys.downgradeDialog,
          title: Text(l10n.motherPermissionLevelDowngradeTitle),
          content: Text(l10n.motherPermissionLevelDowngradeBody(nextName)),
          actions: [
            TextButton(
              key: MotherPermissionLevelKeys.dialogCancel,
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.motherPermissionLevelDialogCancel),
            ),
            TextButton(
              key: MotherPermissionLevelKeys.downgradeConfirm,
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.motherPermissionLevelDowngradeConfirm(nextName)),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      _applyLevel(next, toast: l10n.motherPermissionLevelDowngradedToast(nextName));
      return;
    }

    if (isMotherLevelUpgrade(current, next)) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          key: MotherPermissionLevelKeys.upgradeDialog,
          title: Text(l10n.motherPermissionLevelUpgradeTitle(nextName)),
          content: Text(l10n.motherPermissionLevelUpgradeBody(nextName)),
          actions: [
            TextButton(
              key: MotherPermissionLevelKeys.dialogCancel,
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.motherPermissionLevelDialogCancel),
            ),
            TextButton(
              key: MotherPermissionLevelKeys.upgradeConfirm,
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.motherPermissionLevelUpgradeConfirm(nextName)),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      _applyLevel(next, toast: l10n.motherPermissionLevelUpgradedToast(nextName));
      return;
    }
  }

  void _applyLevel(MotherLevel next, {required String toast}) {
    final changed = _repo.setLevel(next);
    if (!changed || !mounted) return;
    AppToast.show(context, message: toast);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;

    return Scaffold(
      key: MotherPermissionLevelKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        leading: IconButton(
          key: MotherPermissionLevelKeys.backButton,
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: _goBack,
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(
          l10n.motherPermissionLevelTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          IconButton(
            key: MotherPermissionLevelKeys.sosIconCta,
            tooltip: l10n.motherPermissionLevelSosCta,
            onPressed: _sosBusy ? null : _fireSos,
            icon: const Icon(Icons.sos_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: _isChild
            ? AppEmptyState(
                key: MotherPermissionLevelKeys.childLean,
                title: l10n.motherPermissionLevelChildLeanTitle,
                message: l10n.motherPermissionLevelChildLeanMessage,
              )
            : !_isOwner
                ? _buildOwnerOnly(context, l10n, colors)
                : _buildOwnerBody(context, l10n, colors),
      ),
    );
  }

  Widget _buildOwnerOnly(
    BuildContext context,
    AppLocalizations l10n,
    FamilyColors colors,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        BannerNote(
          key: MotherPermissionLevelKeys.ownerOnly,
          variant: BannerVariant.a,
          leading: Text(
            '🔒',
            style: TextStyle(fontSize: 14, color: colors.amberDeep),
          ),
          message: l10n.motherPermissionLevelOwnerOnlyBanner,
        ),
        const SizedBox(height: 16),
        BannerNote(
          key: MotherPermissionLevelKeys.fixedRightsBanner,
          variant: BannerVariant.p,
          leading: Text(
            '🔴',
            style: TextStyle(fontSize: 14, color: colors.p700),
          ),
          message: l10n.motherPermissionLevelFixedRightsBanner,
        ),
        const SizedBox(height: 16),
        PrimaryBtn(
          key: MotherPermissionLevelKeys.sosCta,
          label: l10n.motherPermissionLevelSosCta,
          variant: PrimaryBtnVariant.coral,
          onPressed: _sosBusy ? null : _fireSos,
        ),
      ],
    );
  }

  Widget _buildOwnerBody(
    BuildContext context,
    AppLocalizations l10n,
    FamilyColors colors,
  ) {
    final current = _repo.level;
    final audit = _repo.auditLog;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      children: [
        for (final level in MotherLevel.values)
          _LevelRow(
            key: MotherPermissionLevelKeys.levelRow(level),
            selected: current == level,
            title: current == level
                ? l10n.motherPermissionLevelCurrentTitle(
                    _levelTitle(l10n, level),
                  )
                : _levelTitle(l10n, level),
            description: _levelDesc(l10n, level),
            recommendedTag: level == MotherLevel.partner && current != level
                ? l10n.inviteMotherRecommendedTag
                : null,
            onTap: () => _onSelectLevel(level),
          ),
        const SizedBox(height: 4),
        BannerNote(
          key: MotherPermissionLevelKeys.fixedRightsBanner,
          variant: BannerVariant.p,
          leading: Text(
            '🔴',
            style: TextStyle(fontSize: 14, color: colors.p700),
          ),
          message: l10n.motherPermissionLevelFixedRightsBanner,
        ),
        const SizedBox(height: 14),
        _AuditCard(
          entries: audit,
          l10n: l10n,
          colors: colors,
          transitionLabel: _auditTransition,
          formatWhen: _formatAuditWhen,
        ),
        const SizedBox(height: 16),
        PrimaryBtn(
          key: MotherPermissionLevelKeys.sosCta,
          label: l10n.motherPermissionLevelSosCta,
          variant: PrimaryBtnVariant.coral,
          onPressed: _sosBusy ? null : _fireSos,
        ),
      ],
    );
  }
}

class _LevelRow extends StatelessWidget {
  const _LevelRow({
    super.key,
    required this.selected,
    required this.title,
    required this.description,
    required this.onTap,
    this.recommendedTag,
  });

  final bool selected;
  final String title;
  final String description;
  final String? recommendedTag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final marker = selected ? '●' : '○';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        button: true,
        selected: selected,
        label: recommendedTag == null
            ? '$title. $description'
            : '$title. $recommendedTag. $description',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(radii.card),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: selected ? colors.p50 : colors.surface,
                borderRadius: BorderRadius.circular(radii.card),
                border: Border.all(
                  color: selected ? colors.p500 : colors.border,
                  width: 2,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(13),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      marker,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.3,
                        color: selected ? colors.p500 : colors.ink2,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: colors.ink,
                                ),
                              ),
                              if (recommendedTag != null)
                                Tag(
                                  label: recommendedTag!,
                                  variant: TagVariant.g,
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            description,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: colors.ink2,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuditCard extends StatelessWidget {
  const _AuditCard({
    required this.entries,
    required this.l10n,
    required this.colors,
    required this.transitionLabel,
    required this.formatWhen,
  });

  final List<MotherLevelAuditEntry> entries;
  final AppLocalizations l10n;
  final FamilyColors colors;
  final String Function(AppLocalizations, MotherLevelAuditEntry) transitionLabel;
  final String Function(DateTime) formatWhen;

  @override
  Widget build(BuildContext context) {
    final radii = Theme.of(context).extension<FamilyRadii>()!;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radii.card),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.motherPermissionLevelAuditTitle,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 8),
            if (entries.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  key: MotherPermissionLevelKeys.auditEmpty,
                  l10n.motherPermissionLevelAuditEmpty,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: colors.ink2,
                    height: 1.5,
                  ),
                ),
              )
            else
              Column(
                key: MotherPermissionLevelKeys.auditSection,
                children: [
                  for (var i = 0; i < entries.length; i++)
                    Padding(
                      key: MotherPermissionLevelKeys.auditRow(i),
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '📜',
                            style: TextStyle(fontSize: 16, color: colors.ink2),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  transitionLabel(l10n, entries[i]),
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: colors.ink,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  l10n.motherPermissionLevelAuditMeta(
                                    formatWhen(entries[i].at),
                                  ),
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
                        ],
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
