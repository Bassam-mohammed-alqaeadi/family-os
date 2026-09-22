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

/// Widget keys for SCR-FAT-035 acceptance.
abstract final class NewAppApprovalKeys {
  static const screen = Key('new_app_approval_screen');
  static const empty = Key('new_app_approval_empty');
  static const body = Key('new_app_approval_body');
  static const hero = Key('new_app_approval_hero');
  static const infoCard = Key('new_app_approval_info');
  static const advisor = Key('new_app_approval_advisor');
  static const approve = Key('new_app_approval_approve');
  static const deny = Key('new_app_approval_deny');
  static const doneBanner = Key('new_app_approval_done');
  static const backToApps = Key('new_app_approval_back_apps');
  static const observerHint = Key('new_app_approval_observer');
  static const toneNote = Key('new_app_approval_tone');
  static const childLean = Key('new_app_approval_child_lean');
  static const sosCta = Key('new_app_approval_sos');
  static const sosIconCta = Key('new_app_approval_sos_icon');
  static const backButton = Key('new_app_approval_back');
}

enum _DecisionOutcome { none, allowed, blocked }

/// Default daily cap when approving (prototype FAT-035 · 30 د).
const int kNewAppApprovalDefaultAllowMins = 30;

/// SCR-FAT-035 — موافقة تطبيق جديد (new app install approval).
///
/// Prototype FAT-035 · ChildApps repository from FAT-034 · Rule 12/23 ·
/// mother levels (partner/full decide; observer view) · mock-first · ARB ·
/// P-4 SOS · Family Link–style allow-with-limit / deny-with-alternative.
class NewAppApprovalScreen extends StatefulWidget {
  const NewAppApprovalScreen({
    super.key,
    this.childId,
    this.appId,
    this.repository,
    this.sosFire,
    this.roleOverride,
    this.motherLevel = MotherLevel.partner,
    this.onBack,
    this.onSos,
    this.onBackToApps,
  });

  /// Stage-1 demo child when null / empty query.
  final String? childId;

  /// Optional pending app id from FAT-034 / alerts hub.
  final String? appId;

  /// Rule 25 seam — null → [stage1ChildAppsRepository].
  final ChildAppsRepository? repository;

  /// P-4 SOS seam — null → [stage1SosFireService].
  final SosFireService? sosFire;

  /// Test seam — when set, ignores [CurrentRole].
  final AppRole? roleOverride;

  /// Mother authority for approve/deny (ignored for father/child).
  final MotherLevel motherLevel;

  final VoidCallback? onBack;
  final VoidCallback? onSos;

  /// Test seam — when null, navigates to /scr-fat-034?childId=.
  final VoidCallback? onBackToApps;

  @override
  State<NewAppApprovalScreen> createState() => _NewAppApprovalScreenState();
}

class _NewAppApprovalScreenState extends State<NewAppApprovalScreen> {
  late ChildId _childId;
  late ChildAppsRepository _repo;
  late final SosFireService _sos;
  var _sosBusy = false;
  Listenable? _listenable;
  _DecisionOutcome _outcome = _DecisionOutcome.none;
  String? _decidedAppName;

  AppRole get _role {
    final override = widget.roleOverride;
    if (override != null) return override;
    return CurrentRole.maybeNotifierOf(context)?.value ?? AppRole.father;
  }

  bool get _isChild => _role == AppRole.child;

  bool get _canDecide {
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
  void didUpdateWidget(covariant NewAppApprovalScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.childId != widget.childId) {
      _childId = _resolveChildId(widget.childId);
      _outcome = _DecisionOutcome.none;
      _decidedAppName = null;
    }
    if (oldWidget.appId != widget.appId) {
      _outcome = _DecisionOutcome.none;
      _decidedAppName = null;
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

  void _goBackToApps() {
    if (widget.onBackToApps != null) {
      widget.onBackToApps!();
      return;
    }
    context.go(
      Uri(
        path: '/scr-fat-034',
        queryParameters: {'childId': _childId.value},
      ).toString(),
    );
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

  ChildAppEntry? _resolvePending(List<ChildAppEntry> apps) {
    final pending = apps.where((a) => a.status == ChildAppStatus.pending);
    final want = widget.appId?.trim();
    if (want != null && want.isNotEmpty) {
      for (final a in pending) {
        if (a.id == want) return a;
      }
      return null;
    }
    return pending.isEmpty ? null : pending.first;
  }

  void _approve(ChildAppEntry app) {
    if (!_canDecide) return;
    final ok = _repo.setStatus(_childId, app.id, ChildAppStatus.allowed);
    if (!ok) return;
    setState(() {
      _outcome = _DecisionOutcome.allowed;
      _decidedAppName = app.name;
    });
    AppToast.show(
      context,
      message: AppLocalizations.of(context).newAppApprovalApprovedToast(
        app.name,
        kNewAppApprovalDefaultAllowMins,
      ),
    );
  }

  void _deny(ChildAppEntry app) {
    if (!_canDecide) return;
    final ok = _repo.setStatus(_childId, app.id, ChildAppStatus.blocked);
    if (!ok) return;
    setState(() {
      _outcome = _DecisionOutcome.blocked;
      _decidedAppName = app.name;
    });
    AppToast.show(
      context,
      message: AppLocalizations.of(context).newAppApprovalDeniedToast(app.name),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final apps = _repo.appsFor(_childId);
    final pending = _resolvePending(apps);

    return Scaffold(
      key: NewAppApprovalKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        leading: IconButton(
          key: NewAppApprovalKeys.backButton,
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: _goBack,
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(
          l10n.newAppApprovalTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          IconButton(
            key: NewAppApprovalKeys.sosIconCta,
            tooltip: l10n.newAppApprovalSosCta,
            onPressed: _sosBusy ? null : _fireSos,
            icon: const Icon(Icons.sos_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: _isChild
            ? AppEmptyState(
                key: NewAppApprovalKeys.childLean,
                title: l10n.newAppApprovalChildLeanTitle,
                message: l10n.newAppApprovalChildLeanMessage,
              )
            : _buildBody(context, l10n, colors, pending),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n,
    FamilyColors colors,
    ChildAppEntry? pending,
  ) {
    if (_outcome != _DecisionOutcome.none && _decidedAppName != null) {
      return _DoneView(
        outcome: _outcome,
        appName: _decidedAppName!,
        allowMins: kNewAppApprovalDefaultAllowMins,
        l10n: l10n,
        colors: colors,
        onBackToApps: _goBackToApps,
        onSos: _sosBusy ? null : _fireSos,
      );
    }

    if (pending == null) {
      return AppEmptyState(
        key: NewAppApprovalKeys.empty,
        title: l10n.newAppApprovalEmptyTitle,
        message: l10n.newAppApprovalEmptyMessage,
      );
    }

    return ListView(
      key: NewAppApprovalKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _HeroCard(app: pending, l10n: l10n, colors: colors),
        const SizedBox(height: 12),
        _InfoCard(app: pending, l10n: l10n, colors: colors),
        const SizedBox(height: 12),
        if (_isObserverMother)
          BannerNote(
            key: NewAppApprovalKeys.observerHint,
            variant: BannerVariant.a,
            leading: Icon(Icons.visibility_outlined, size: 18, color: colors.amberDeep),
            message: l10n.newAppApprovalObserverHint,
          )
        else if (_canDecide) ...[
          Row(
            children: [
              Expanded(
                child: PrimaryBtn(
                  key: NewAppApprovalKeys.approve,
                  label: l10n.newAppApprovalApprove(
                    kNewAppApprovalDefaultAllowMins,
                  ),
                  variant: PrimaryBtnVariant.mint,
                  fullWidth: true,
                  onPressed: () => _approve(pending),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PrimaryBtn(
                  key: NewAppApprovalKeys.deny,
                  label: l10n.newAppApprovalDeny,
                  variant: PrimaryBtnVariant.coral,
                  fullWidth: true,
                  onPressed: () => _deny(pending),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            key: NewAppApprovalKeys.toneNote,
            l10n.newAppApprovalToneNote,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: colors.ink2, height: 1.4),
          ),
        ],
        const SizedBox(height: 16),
        PrimaryBtn(
          key: NewAppApprovalKeys.sosCta,
          label: l10n.newAppApprovalSosCta,
          variant: PrimaryBtnVariant.coral,
          onPressed: _sosBusy ? null : _fireSos,
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.app,
    required this.l10n,
    required this.colors,
  });

  final ChildAppEntry app;
  final AppLocalizations l10n;
  final FamilyColors colors;

  @override
  Widget build(BuildContext context) {
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    return DecoratedBox(
      key: NewAppApprovalKeys.hero,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radii.card),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
        child: Column(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: colors.p50,
              child: Icon(Icons.apps, size: 32, color: colors.p700),
            ),
            const SizedBox(height: 10),
            Text(
              app.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.newAppApprovalRequestHint,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: colors.ink2, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.app,
    required this.l10n,
    required this.colors,
  });

  final ChildAppEntry app;
  final AppLocalizations l10n;
  final FamilyColors colors;

  @override
  Widget build(BuildContext context) {
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final age = app.ageRating.isEmpty ? '—' : app.ageRating;
    final showSocialRisks = app.category == ChildAppCategory.social;

    return DecoratedBox(
      key: NewAppApprovalKeys.infoCard,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radii.card),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.newAppApprovalInfoHeading,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 10),
            _InfoRow(
              label: l10n.newAppApprovalAgeLabel,
              trailing: Tag(label: age, variant: TagVariant.a),
            ),
            if (showSocialRisks) ...[
              _InfoRow(
                label: l10n.newAppApprovalStrangersLabel,
                trailing: Text(
                  l10n.newAppApprovalStrangersValue,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: colors.coral,
                  ),
                ),
              ),
              _InfoRow(
                label: l10n.newAppApprovalVanishLabel,
                trailing: Text(
                  l10n.newAppApprovalVanishValue,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: colors.coral,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            DecoratedBox(
              key: NewAppApprovalKeys.advisor,
              decoration: BoxDecoration(
                color: colors.p50,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  l10n.newAppApprovalAdvisorTip(
                    kNewAppApprovalDefaultAllowMins,
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color: colors.ink,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.trailing});

  final String label;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: colors.ink,
              ),
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _DoneView extends StatelessWidget {
  const _DoneView({
    required this.outcome,
    required this.appName,
    required this.allowMins,
    required this.l10n,
    required this.colors,
    required this.onBackToApps,
    required this.onSos,
  });

  final _DecisionOutcome outcome;
  final String appName;
  final int allowMins;
  final AppLocalizations l10n;
  final FamilyColors colors;
  final VoidCallback onBackToApps;
  final VoidCallback? onSos;

  @override
  Widget build(BuildContext context) {
    final message = outcome == _DecisionOutcome.allowed
        ? l10n.newAppApprovalDoneAllowed(appName, allowMins)
        : l10n.newAppApprovalDoneBlocked(appName);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        BannerNote(
          key: NewAppApprovalKeys.doneBanner,
          variant: outcome == _DecisionOutcome.allowed
              ? BannerVariant.t
              : BannerVariant.a,
          leading: Icon(
            outcome == _DecisionOutcome.allowed
                ? Icons.check_circle_outline
                : Icons.block_outlined,
            size: 18,
            color: outcome == _DecisionOutcome.allowed
                ? colors.teal
                : colors.amberDeep,
          ),
          message: message,
        ),
        const SizedBox(height: 14),
        PrimaryBtn(
          key: NewAppApprovalKeys.backToApps,
          label: l10n.newAppApprovalBackToApps,
          variant: PrimaryBtnVariant.sec,
          onPressed: onBackToApps,
        ),
        const SizedBox(height: 16),
        PrimaryBtn(
          key: NewAppApprovalKeys.sosCta,
          label: l10n.newAppApprovalSosCta,
          variant: PrimaryBtnVariant.coral,
          onPressed: onSos,
        ),
      ],
    );
  }
}
