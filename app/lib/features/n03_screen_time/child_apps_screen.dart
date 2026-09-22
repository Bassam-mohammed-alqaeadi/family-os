import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/components/tag.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/features/n03_screen_time/child_apps_models.dart';
import 'package:family_os/features/n03_screen_time/child_apps_repository.dart';

/// Widget keys for SCR-FAT-034 acceptance.
abstract final class ChildAppsKeys {
  static const screen = Key('child_apps_screen');
  static const empty = Key('child_apps_empty');
  static const list = Key('child_apps_list');
  static const tipBanner = Key('child_apps_tip');
  static const pendingCta = Key('child_apps_pending_cta');
  static const sharedNote = Key('child_apps_shared_note');
  static const observerHint = Key('child_apps_observer_hint');
  static const childLean = Key('child_apps_child_lean');
  static const controlSheet = Key('child_apps_control_sheet');
  static const sosCta = Key('child_apps_sos');
  static const sosIconCta = Key('child_apps_sos_icon');
  static const backButton = Key('child_apps_back');

  static Key category(ChildAppCategory cat) => Key('child_apps_cat_${cat.name}');
  static Key appTile(String id) => Key('child_apps_tile_$id');
  static Key allow(String id) => Key('child_apps_allow_$id');
  static Key block(String id) => Key('child_apps_block_$id');
  static Key statusToggle(String id) => Key('child_apps_toggle_$id');
}

/// SCR-FAT-034 — تطبيقات الابن (child apps list).
///
/// Prototype FAT-034 · parametric [ChildId] · pending → FAT-035 · mother OK
/// per [MotherLevel] (partner/full decide; observer view) · mock-first ·
/// ARB · P-4 SOS · Rule 12/23 · Family Link / Qustodio list honesty.
class ChildAppsScreen extends StatefulWidget {
  const ChildAppsScreen({
    super.key,
    this.childId,
    this.repository,
    this.sosFire,
    this.roleOverride,
    this.motherLevel = MotherLevel.partner,
    this.onBack,
    this.onSos,
    this.onOpenNewAppApprove,
  });

  /// Stage-1 demo child when null / empty query.
  final String? childId;

  /// Rule 25 seam — null → [stage1ChildAppsRepository].
  final ChildAppsRepository? repository;

  /// P-4 SOS seam — null → [stage1SosFireService].
  final SosFireService? sosFire;

  /// Test seam — when set, ignores [CurrentRole].
  final AppRole? roleOverride;

  /// Mother authority for allow/block (ignored for father/child).
  final MotherLevel motherLevel;

  final VoidCallback? onBack;
  final VoidCallback? onSos;

  /// Test seam — when null, navigates to /scr-fat-035?childId=&appId=.
  final void Function(String childId, String? pendingAppId)? onOpenNewAppApprove;

  @override
  State<ChildAppsScreen> createState() => _ChildAppsScreenState();
}

class _ChildAppsScreenState extends State<ChildAppsScreen> {
  late ChildId _childId;
  late ChildAppsRepository _repo;
  late final SosFireService _sos;
  var _sosBusy = false;
  Listenable? _listenable;

  AppRole get _role {
    final override = widget.roleOverride;
    if (override != null) return override;
    return CurrentRole.maybeNotifierOf(context)?.value ?? AppRole.father;
  }

  bool get _isChild => _role == AppRole.child;

  bool get _canControl {
    if (_role == AppRole.father) return true;
    if (_role == AppRole.mother) {
      return widget.motherLevel == MotherLevel.partner ||
          widget.motherLevel == MotherLevel.full;
    }
    return false;
  }

  bool get _isObserverMother =>
      _role == AppRole.mother && widget.motherLevel == MotherLevel.observer;

  @override
  void initState() {
    super.initState();
    _childId = _resolveChildId(widget.childId);
    _repo = widget.repository ?? stage1ChildAppsRepository;
    _sos = widget.sosFire ?? stage1SosFireService;
    _bindRepo(_repo);
  }

  @override
  void didUpdateWidget(covariant ChildAppsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.childId != widget.childId) {
      _childId = _resolveChildId(widget.childId);
    }
    if (oldWidget.repository != widget.repository) {
      _unbindRepo();
      _repo = widget.repository ?? stage1ChildAppsRepository;
      _bindRepo(_repo);
    }
  }

  @override
  void dispose() {
    _unbindRepo();
    super.dispose();
  }

  ChildId _resolveChildId(String? raw) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return ChildId('demo-child');
    }
    return ChildId(trimmed);
  }

  void _bindRepo(ChildAppsRepository repo) {
    if (repo is Listenable) {
      _listenable = repo as Listenable;
      _listenable!.addListener(_onRepo);
    } else {
      _listenable = null;
    }
  }

  void _unbindRepo() {
    _listenable?.removeListener(_onRepo);
    _listenable = null;
  }

  void _onRepo() {
    if (mounted) setState(() {});
  }

  void _goBack() {
    if (widget.onBack != null) {
      widget.onBack!();
      return;
    }
    if (context.canPop()) context.pop();
  }

  Future<void> _fireSos() async {
    if (_sosBusy) return;
    setState(() => _sosBusy = true);
    try {
      if (widget.onSos != null) {
        widget.onSos!();
        return;
      }
      await _sos.fire(childId: _childId.value);
      if (!mounted) return;
      context.go('/scr-fat-018');
    } finally {
      if (mounted) setState(() => _sosBusy = false);
    }
  }

  void _openPendingApprove({String? appId}) {
    if (widget.onOpenNewAppApprove != null) {
      widget.onOpenNewAppApprove!(_childId.value, appId);
      return;
    }
    final params = <String, String>{'childId': _childId.value};
    if (appId != null && appId.isNotEmpty) {
      params['appId'] = appId;
    }
    context.push(
      Uri(path: '/scr-fat-035', queryParameters: params).toString(),
    );
  }

  Future<void> _onAppTap(ChildAppEntry app) async {
    if (app.status == ChildAppStatus.pending) {
      _openPendingApprove(appId: app.id);
      return;
    }
    if (!_canControl) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => _AppControlSheet(
        app: app,
        canControl: _canControl,
        onAllow: () {
          _repo.setStatus(_childId, app.id, ChildAppStatus.allowed);
          Navigator.of(ctx).pop();
          AppToast.show(
            context,
            message: AppLocalizations.of(context).childAppsStatusUpdated(app.name),
          );
        },
        onBlock: () {
          _repo.setStatus(_childId, app.id, ChildAppStatus.blocked);
          Navigator.of(ctx).pop();
          AppToast.show(
            context,
            message: AppLocalizations.of(context).childAppsStatusUpdated(app.name),
          );
        },
      ),
    );
  }

  void _onToggle(ChildAppEntry app, bool allowed) {
    if (!_canControl || app.status == ChildAppStatus.pending) return;
    if (app.status == ChildAppStatus.free) return;
    _repo.setStatus(
      _childId,
      app.id,
      allowed ? ChildAppStatus.allowed : ChildAppStatus.blocked,
    );
    AppToast.show(
      context,
      message: AppLocalizations.of(context).childAppsStatusUpdated(app.name),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final apps = _repo.appsFor(_childId);
    final pending = apps.where((a) => a.status == ChildAppStatus.pending).toList();

    return Scaffold(
      key: ChildAppsKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        leading: IconButton(
          key: ChildAppsKeys.backButton,
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: _goBack,
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(
          l10n.childAppsTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          IconButton(
            key: ChildAppsKeys.sosIconCta,
            tooltip: l10n.childAppsSosCta,
            onPressed: _sosBusy ? null : _fireSos,
            icon: const Icon(Icons.sos_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: _isChild
            ? AppEmptyState(
                key: ChildAppsKeys.childLean,
                title: l10n.childAppsChildLeanTitle,
                message: l10n.childAppsChildLeanMessage,
              )
            : _buildBody(context, l10n, colors, apps, pending),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n,
    FamilyColors colors,
    List<ChildAppEntry> apps,
    List<ChildAppEntry> pending,
  ) {
    if (apps.isEmpty) {
      return AppEmptyState(
        key: ChildAppsKeys.empty,
        title: l10n.childAppsEmptyTitle,
        message: l10n.childAppsEmptyMessage,
      );
    }

    return ListView(
      key: ChildAppsKeys.list,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        BannerNote(
          key: ChildAppsKeys.tipBanner,
          variant: BannerVariant.p,
          leading: Icon(Icons.touch_app_outlined, size: 18, color: colors.p700),
          message: l10n.childAppsTipBanner,
        ),
        if (_isObserverMother) ...[
          const SizedBox(height: 10),
          BannerNote(
            key: ChildAppsKeys.observerHint,
            variant: BannerVariant.a,
            leading: Icon(Icons.visibility_outlined, size: 18, color: colors.amberDeep),
            message: l10n.childAppsObserverHint,
          ),
        ],
        if (pending.isNotEmpty) ...[
          const SizedBox(height: 10),
          PrimaryBtn(
            key: ChildAppsKeys.pendingCta,
            label: l10n.childAppsPendingCta(pending.length),
            variant: PrimaryBtnVariant.mint,
            onPressed: () => _openPendingApprove(appId: pending.first.id),
          ),
        ],
        const SizedBox(height: 12),
        for (final cat in ChildAppCategory.values)
          _CategorySection(
            category: cat,
            apps: apps.where((a) => a.category == cat).toList(),
            canControl: _canControl,
            l10n: l10n,
            colors: colors,
            onTap: _onAppTap,
            onToggle: _onToggle,
          ),
        BannerNote(
          key: ChildAppsKeys.sharedNote,
          variant: BannerVariant.t,
          leading: Icon(Icons.shield_outlined, size: 18, color: colors.teal),
          message: l10n.childAppsSharedNote,
        ),
        const SizedBox(height: 16),
        PrimaryBtn(
          key: ChildAppsKeys.sosCta,
          label: l10n.childAppsSosCta,
          variant: PrimaryBtnVariant.coral,
          onPressed: _sosBusy ? null : _fireSos,
        ),
      ],
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.category,
    required this.apps,
    required this.canControl,
    required this.l10n,
    required this.colors,
    required this.onTap,
    required this.onToggle,
  });

  final ChildAppCategory category;
  final List<ChildAppEntry> apps;
  final bool canControl;
  final AppLocalizations l10n;
  final FamilyColors colors;
  final void Function(ChildAppEntry) onTap;
  final void Function(ChildAppEntry, bool) onToggle;

  String _title() => switch (category) {
        ChildAppCategory.games => l10n.childAppsCatGames,
        ChildAppCategory.social => l10n.childAppsCatSocial,
        ChildAppCategory.edu => l10n.childAppsCatEdu,
        ChildAppCategory.tools => l10n.childAppsCatTools,
      };

  String _rule() => switch (category) {
        ChildAppCategory.games => l10n.childAppsCatGamesRule,
        ChildAppCategory.social => l10n.childAppsCatSocialRule,
        ChildAppCategory.edu => l10n.childAppsCatEduRule,
        ChildAppCategory.tools => l10n.childAppsCatToolsRule,
      };

  IconData _icon() => switch (category) {
        ChildAppCategory.games => Icons.sports_esports_outlined,
        ChildAppCategory.social => Icons.chat_bubble_outline,
        ChildAppCategory.edu => Icons.school_outlined,
        ChildAppCategory.tools => Icons.build_outlined,
      };

  @override
  Widget build(BuildContext context) {
    if (apps.isEmpty) return const SizedBox.shrink();
    final radii = Theme.of(context).extension<FamilyRadii>()!;

    return Padding(
      key: ChildAppsKeys.category(category),
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(radii.card),
          border: Border.all(color: colors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(_icon(), size: 20, color: colors.p700),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _title(),
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: colors.ink,
                      ),
                    ),
                  ),
                  Tag(
                    label: l10n.childAppsCount(apps.length),
                    variant: TagVariant.t,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _rule(),
                style: TextStyle(fontSize: 11, color: colors.ink2),
              ),
              const SizedBox(height: 8),
              for (final app in apps)
                _AppRow(
                  app: app,
                  canControl: canControl,
                  l10n: l10n,
                  colors: colors,
                  onTap: () => onTap(app),
                  onToggle: (v) => onToggle(app, v),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppRow extends StatelessWidget {
  const _AppRow({
    required this.app,
    required this.canControl,
    required this.l10n,
    required this.colors,
    required this.onTap,
    required this.onToggle,
  });

  final ChildAppEntry app;
  final bool canControl;
  final AppLocalizations l10n;
  final FamilyColors colors;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;

  String _statusLabel() => switch (app.status) {
        ChildAppStatus.allowed =>
          l10n.childAppsRemaining(app.remainingMins, app.limitMins),
        ChildAppStatus.free => l10n.childAppsStatusFree,
        ChildAppStatus.blocked => l10n.childAppsStatusBlocked,
        ChildAppStatus.pending => l10n.childAppsStatusPending,
      };

  Color _statusColor() => switch (app.status) {
        ChildAppStatus.allowed => colors.mintInk,
        ChildAppStatus.free => const Color(0xFF0277BD),
        ChildAppStatus.blocked => colors.coral,
        ChildAppStatus.pending => colors.amberDeep,
      };

  bool get _showToggle =>
      canControl &&
      app.status != ChildAppStatus.pending &&
      app.status != ChildAppStatus.free;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: ChildAppsKeys.appTile(app.id),
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: colors.p50,
              child: Icon(Icons.apps, color: colors.p700, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    app.name,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: colors.ink,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _statusLabel(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _statusColor(),
                    ),
                  ),
                  if (app.walletMins > 0)
                    Text(
                      l10n.childAppsWallet(app.walletMins),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: colors.p700,
                      ),
                    ),
                  if (app.instantLocked)
                    Text(
                      l10n.childAppsInstantLocked,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: colors.coral,
                      ),
                    ),
                ],
              ),
            ),
            if (_showToggle)
              Switch.adaptive(
                key: ChildAppsKeys.statusToggle(app.id),
                value: app.status == ChildAppStatus.allowed,
                onChanged: onToggle,
              )
            else if (app.status == ChildAppStatus.pending)
              Icon(Icons.chevron_left, color: colors.ink2)
            else
              const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

class _AppControlSheet extends StatelessWidget {
  const _AppControlSheet({
    required this.app,
    required this.canControl,
    required this.onAllow,
    required this.onBlock,
  });

  final ChildAppEntry app;
  final bool canControl;
  final VoidCallback onAllow;
  final VoidCallback onBlock;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;

    return SafeArea(
      key: ChildAppsKeys.controlSheet,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              app.name,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.childAppsSheetHint,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: colors.ink2),
            ),
            const SizedBox(height: 14),
            if (canControl) ...[
              PrimaryBtn(
                key: ChildAppsKeys.allow(app.id),
                label: l10n.childAppsAllow,
                variant: PrimaryBtnVariant.mint,
                onPressed: onAllow,
              ),
              const SizedBox(height: 8),
              PrimaryBtn(
                key: ChildAppsKeys.block(app.id),
                label: l10n.childAppsBlock,
                variant: PrimaryBtnVariant.coral,
                onPressed: onBlock,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
