import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/components/tag.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/anti_tamper_permission.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/features/n05_lock/tamper_alerts_models.dart';
import 'package:family_os/features/n05_lock/tamper_alerts_repository.dart';

/// Widget keys for SCR-FAT-038 acceptance.
abstract final class TamperAlertsKeys {
  static const screen = Key('tamper_alerts_screen');
  static const empty = Key('tamper_alerts_empty');
  static const body = Key('tamper_alerts_body');
  static const pedagogyBanner = Key('tamper_alerts_pedagogy');
  static const honestyBanner = Key('tamper_alerts_honesty');
  static const activeSection = Key('tamper_alerts_active');
  static const historySection = Key('tamper_alerts_history');
  static const settingsCta = Key('tamper_alerts_settings');
  static const observerHint = Key('tamper_alerts_observer');
  static const childLean = Key('tamper_alerts_child_lean');
  static const sosCta = Key('tamper_alerts_sos');
  static const sosIconCta = Key('tamper_alerts_sos_icon');
  static const backButton = Key('tamper_alerts_back');
  static const loading = Key('tamper_alerts_loading');

  static Key row(String id) => Key('tamper_alerts_row_$id');
  static Key tip(String id) => Key('tamper_alerts_tip_$id');
}

/// SCR-FAT-038 — تنبيهات التحايل (tamper / bypass alerts).
///
/// Prototype FAT-038 · SET-007/008 anti-tamper · Rule 12/23 · mother levels ·
/// mock-first · ARB · P-4 SOS · Bark alert-first honesty · dialogue not judgment.
/// Settings live on SCR-FAT-037 — this screen links when father can configure.
class TamperAlertsScreen extends StatefulWidget {
  const TamperAlertsScreen({
    super.key,
    this.childId,
    this.repository,
    this.sosFire,
    this.roleOverride,
    this.motherLevel = MotherLevel.partner,
    this.onBack,
    this.onSos,
    this.onOpenAntiTamperSettings,
  });

  /// Stage-1 demo child when null / empty query.
  final String? childId;

  /// Rule 25 seam — null → [stage1TamperAlertsRepository].
  final TamperAlertsRepository? repository;

  /// P-4 SOS seam — null → [stage1SosFireService].
  final SosFireService? sosFire;

  /// Test seam — when set, ignores [CurrentRole].
  final AppRole? roleOverride;

  /// Mother authority (observer = view-only hint; partner/full view alerts).
  final MotherLevel motherLevel;

  final VoidCallback? onBack;
  final VoidCallback? onSos;

  /// Test seam — when null, navigates to /scr-fat-037.
  final VoidCallback? onOpenAntiTamperSettings;

  @override
  State<TamperAlertsScreen> createState() => _TamperAlertsScreenState();
}

class _TamperAlertsScreenState extends State<TamperAlertsScreen> {
  late ChildId _childId;
  late TamperAlertsRepository _repo;
  late final SosFireService _sos;
  var _sosBusy = false;
  var _loading = true;
  TamperAlertsSnapshot _snap = const TamperAlertsSnapshot();

  AppRole get _role {
    final override = widget.roleOverride;
    if (override != null) return override;
    return CurrentRole.maybeNotifierOf(context)?.value ?? AppRole.father;
  }

  bool get _isChild => _role == AppRole.child;

  bool get _isParent => _role == AppRole.father || _role == AppRole.mother;

  bool get _isObserverMother =>
      _role == AppRole.mother && widget.motherLevel == MotherLevel.observer;

  bool get _showSettingsLink => canConfigureAntiTamper(_role);

  @override
  void initState() {
    super.initState();
    _childId = _resolveChildId(widget.childId);
    _repo = widget.repository ?? stage1TamperAlertsRepository;
    _sos = widget.sosFire ?? stage1SosFireService;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
    });
  }

  @override
  void didUpdateWidget(covariant TamperAlertsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.childId != widget.childId) {
      _childId = _resolveChildId(widget.childId);
      _load();
    }
    if (oldWidget.repository != widget.repository) {
      _repo = widget.repository ?? stage1TamperAlertsRepository;
      _load();
    }
  }

  ChildId _resolveChildId(String? raw) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return ChildId(kDefaultTamperAlertsChildKey);
    }
    return ChildId(trimmed);
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _repo.load(_childId);
    if (!mounted) return;
    setState(() {
      _snap = TamperAlertsSnapshot.fromList(list);
      _loading = false;
    });
  }

  void _goBack() {
    if (widget.onBack != null) {
      widget.onBack!();
      return;
    }
    if (context.canPop()) context.pop();
  }

  Future<void> _openSos() async {
    if (_sosBusy) return;
    if (widget.onSos != null) {
      widget.onSos!();
      return;
    }
    setState(() => _sosBusy = true);
    await _sos.fire(childId: _childId.value);
    if (mounted) setState(() => _sosBusy = false);
  }

  void _openSettings() {
    if (!_showSettingsLink) return;
    if (widget.onOpenAntiTamperSettings != null) {
      widget.onOpenAntiTamperSettings!();
      return;
    }
    context.go('/scr-fat-037');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;

    return Scaffold(
      key: TamperAlertsKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        elevation: 0,
        leading: IconButton(
          key: TamperAlertsKeys.backButton,
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: _goBack,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          style: const ButtonStyle(
            tapTargetSize: MaterialTapTargetSize.padded,
            minimumSize: WidgetStatePropertyAll(Size(48, 48)),
          ),
          icon: Icon(Icons.arrow_back, color: colors.ink),
        ),
        title: Text(
          l10n.tamperAlertsTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          IconButton(
            key: TamperAlertsKeys.sosIconCta,
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
        key: TamperAlertsKeys.childLean,
        title: l10n.tamperAlertsChildLeanTitle,
        message: l10n.tamperAlertsChildLeanMessage,
        actionLabel: l10n.tamperAlertsSosCta,
        onAction: _sosBusy ? null : _openSos,
      );
    }

    if (!_isParent) {
      return AppEmptyState(
        key: TamperAlertsKeys.childLean,
        title: l10n.tamperAlertsChildLeanTitle,
        message: l10n.tamperAlertsChildLeanMessage,
      );
    }

    if (_loading) {
      return Semantics(
        key: TamperAlertsKeys.loading,
        label: l10n.tamperAlertsLoadingSemantics,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_snap.isEmpty) {
      return _EmptyBody(
        l10n: l10n,
        showSettings: _showSettingsLink,
        onSettings: _openSettings,
        onSos: _sosBusy ? null : _openSos,
      );
    }

    return SingleChildScrollView(
      key: TamperAlertsKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BannerNote(
            key: TamperAlertsKeys.pedagogyBanner,
            variant: BannerVariant.p,
            message: l10n.tamperAlertsPedagogyBanner,
          ),
          const SizedBox(height: 10),
          BannerNote(
            key: TamperAlertsKeys.honestyBanner,
            variant: BannerVariant.t,
            message: l10n.tamperAlertsHonestyBanner,
          ),
          if (_isObserverMother) ...[
            const SizedBox(height: 10),
            BannerNote(
              key: TamperAlertsKeys.observerHint,
              variant: BannerVariant.a,
              message: l10n.tamperAlertsObserverHint,
            ),
          ],
          if (_snap.active.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionHeader(
              sectionKey: TamperAlertsKeys.activeSection,
              title: l10n.tamperAlertsActiveHeading,
              colors: colors,
            ),
            const SizedBox(height: 8),
            for (final alert in _snap.active) ...[
              _AlertCard(alert: alert, l10n: l10n, colors: colors),
              const SizedBox(height: 10),
            ],
          ],
          if (_snap.handled.isNotEmpty) ...[
            const SizedBox(height: 8),
            _SectionHeader(
              sectionKey: TamperAlertsKeys.historySection,
              title: l10n.tamperAlertsHistoryHeading,
              colors: colors,
            ),
            const SizedBox(height: 8),
            for (final alert in _snap.handled) ...[
              _AlertCard(alert: alert, l10n: l10n, colors: colors),
              const SizedBox(height: 10),
            ],
          ],
          if (_showSettingsLink) ...[
            const SizedBox(height: 8),
            PrimaryBtn(
              key: TamperAlertsKeys.settingsCta,
              label: l10n.tamperAlertsSettingsCta,
              onPressed: _openSettings,
            ),
          ],
          const SizedBox(height: 12),
          PrimaryBtn(
            key: TamperAlertsKeys.sosCta,
            label: l10n.tamperAlertsSosCta,
            onPressed: _sosBusy ? null : _openSos,
            variant: PrimaryBtnVariant.coral,
          ),
        ],
      ),
    );
  }
}

class _EmptyBody extends StatelessWidget {
  const _EmptyBody({
    required this.l10n,
    required this.showSettings,
    required this.onSettings,
    required this.onSos,
  });

  final AppLocalizations l10n;
  final bool showSettings;
  final VoidCallback onSettings;
  final VoidCallback? onSos;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BannerNote(
            key: TamperAlertsKeys.pedagogyBanner,
            variant: BannerVariant.p,
            message: l10n.tamperAlertsPedagogyBanner,
          ),
          const SizedBox(height: 10),
          BannerNote(
            key: TamperAlertsKeys.honestyBanner,
            variant: BannerVariant.t,
            message: l10n.tamperAlertsHonestyBanner,
          ),
          const SizedBox(height: 16),
          AppEmptyState(
            key: TamperAlertsKeys.empty,
            title: l10n.tamperAlertsEmptyTitle,
            message: l10n.tamperAlertsEmptyMessage,
          ),
          if (showSettings) ...[
            const SizedBox(height: 8),
            PrimaryBtn(
              key: TamperAlertsKeys.settingsCta,
              label: l10n.tamperAlertsSettingsCta,
              onPressed: onSettings,
            ),
          ],
          const SizedBox(height: 12),
          PrimaryBtn(
            key: TamperAlertsKeys.sosCta,
            label: l10n.tamperAlertsSosCta,
            onPressed: onSos,
            variant: PrimaryBtnVariant.coral,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.sectionKey,
    required this.title,
    required this.colors,
  });

  final Key sectionKey;
  final String title;
  final FamilyColors colors;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        key: sectionKey,
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: colors.ink,
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.alert,
    required this.l10n,
    required this.colors,
  });

  final TamperAlertEntry alert;
  final AppLocalizations l10n;
  final FamilyColors colors;

  @override
  Widget build(BuildContext context) {
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final title = _titleFor(alert.kind, l10n);
    final subtitle = _subtitleFor(alert, l10n);
    final tip = alert.isActive ? _tipFor(alert.kind, l10n) : null;

    return DecoratedBox(
      key: TamperAlertsKeys.row(alert.id),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radii.card),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _emojiFor(alert.kind),
                  style: const TextStyle(fontSize: 22),
                ),
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
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.ink2,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Tag(
                  label: alert.isActive
                      ? l10n.tamperAlertsStatusActive
                      : l10n.tamperAlertsStatusHandled,
                  variant: alert.isActive ? TagVariant.a : TagVariant.g,
                ),
              ],
            ),
            if (tip != null) ...[
              const SizedBox(height: 10),
              DecoratedBox(
                key: TamperAlertsKeys.tip(alert.id),
                decoration: BoxDecoration(
                  color: colors.p50,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    tip,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colors.p700,
                      height: 1.55,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _emojiFor(TamperAlertKind kind) => switch (kind) {
    TamperAlertKind.vpn => '🛡',
    TamperAlertKind.permissionDisable => '🔓',
    TamperAlertKind.clockChange => '🕐',
    TamperAlertKind.safeMode => '⚠️',
    TamperAlertKind.bypass => '🚨',
    TamperAlertKind.simChange => '📶',
  };

  static String _titleFor(TamperAlertKind kind, AppLocalizations l10n) =>
      switch (kind) {
        TamperAlertKind.vpn => l10n.tamperAlertsKindVpn,
        TamperAlertKind.permissionDisable => l10n.tamperAlertsKindPermission,
        TamperAlertKind.clockChange => l10n.tamperAlertsKindClock,
        TamperAlertKind.safeMode => l10n.tamperAlertsKindSafeMode,
        TamperAlertKind.bypass => l10n.tamperAlertsKindBypass,
        TamperAlertKind.simChange => l10n.tamperAlertsKindSim,
      };

  static String _subtitleFor(TamperAlertEntry alert, AppLocalizations l10n) {
    final detail = alert.detailKey;
    final base = switch (alert.kind) {
      TamperAlertKind.vpn => l10n.tamperAlertsKindVpnDetail,
      TamperAlertKind.permissionDisable =>
        l10n.tamperAlertsKindPermissionDetail,
      TamperAlertKind.clockChange => l10n.tamperAlertsKindClockDetail,
      TamperAlertKind.safeMode => l10n.tamperAlertsKindSafeModeDetail,
      TamperAlertKind.bypass => l10n.tamperAlertsKindBypassDetail,
      TamperAlertKind.simChange => l10n.tamperAlertsKindSimDetail,
    };
    if (detail == null || detail.isEmpty) return base;
    return '$base · $detail';
  }

  static String _tipFor(TamperAlertKind kind, AppLocalizations l10n) =>
      switch (kind) {
        TamperAlertKind.vpn => l10n.tamperAlertsTipVpn,
        TamperAlertKind.permissionDisable => l10n.tamperAlertsTipPermission,
        TamperAlertKind.clockChange => l10n.tamperAlertsTipClock,
        TamperAlertKind.safeMode => l10n.tamperAlertsTipSafeMode,
        TamperAlertKind.bypass => l10n.tamperAlertsTipBypass,
        TamperAlertKind.simChange => l10n.tamperAlertsTipSim,
      };
}
