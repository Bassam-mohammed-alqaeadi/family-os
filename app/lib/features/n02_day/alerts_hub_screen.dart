import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/app_error_state.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/row_tile.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/features/n02_day/alerts_hub_repository.dart';
import 'package:family_os/features/n02_day/day_child_mock.dart';

Color _swatchColor(DayChildSwatch swatch, FamilyColors colors) =>
    switch (swatch) {
      DayChildSwatch.purple => colors.p500,
      DayChildSwatch.sky => colors.sky,
      DayChildSwatch.amber => colors.amber,
    };

/// Widget keys for SCR-FAT-019 acceptance.
abstract final class AlertsHubKeys {
  static const screen = Key('alerts_hub_screen');
  static const loading = Key('alerts_hub_loading');
  static const empty = Key('alerts_hub_empty');
  static const error = Key('alerts_hub_error');
  static const body = Key('alerts_hub_body');
  static const honestyBanner = Key('alerts_hub_honesty');
  static const p4Banner = Key('alerts_hub_p4');
  static const sosCta = Key('alerts_hub_sos');
  static const childLean = Key('alerts_hub_child_lean');
  static const sectionCritical = Key('alerts_hub_section_critical');
  static const sectionAttention = Key('alerts_hub_section_attention');
  static const sectionReassurance = Key('alerts_hub_section_reassurance');
  static const countCritical = Key('alerts_hub_count_critical');
  static const countAttention = Key('alerts_hub_count_attention');
  static const countReassurance = Key('alerts_hub_count_reassurance');

  static Key row(String id) => Key('alerts_hub_row_$id');
}

/// SCR-FAT-019 — مركز التنبيهات (parent alerts hub).
///
/// Three urgency groups (S-ADM-028) with counters — importance ladder.
/// Rows open FAT-020 (kind), FAT-033 (time), or FAT-035 (app) per prototype.
/// Excerpt titles only (S-AIC-006). P-4 SOS ungated. RoleGuard lean for child.
/// Mock-first — no Firebase. Rule 23: default empty until repo seed.
class AlertsHubScreen extends StatefulWidget {
  const AlertsHubScreen({
    super.key,
    this.repository,
    this.roleOverride,
    this.sosFire,
    this.onSos,
    this.onOpenAlert,
    this.onOpenTimeRequests,
    this.onOpenAppApproval,
  });

  /// Null → [stage1AlertsHubRepository].
  final AlertsHubRepository? repository;

  /// Test seam — when set, ignores [CurrentRole].
  final AppRole? roleOverride;

  /// P-4 SOS seam — null → [stage1SosFireService].
  final SosFireService? sosFire;

  /// Test seam — SOS fire / navigate.
  final VoidCallback? onSos;

  /// Test seam — FAT-020 open with alertKind.
  final void Function(HubAlert alert)? onOpenAlert;

  /// Test seam — FAT-033.
  final VoidCallback? onOpenTimeRequests;

  /// Test seam — FAT-035.
  final VoidCallback? onOpenAppApproval;

  @override
  AlertsHubScreenState createState() => AlertsHubScreenState();
}

class AlertsHubScreenState extends State<AlertsHubScreen> {
  late final AlertsHubRepository _repo;
  var _loading = true;
  var _loadFailed = false;
  var _sosBusy = false;
  AlertsHubSnapshot? _snapshot;

  AppRole get _role =>
      widget.roleOverride ??
      CurrentRole.maybeNotifierOf(context)?.value ??
      AppRole.father;

  bool get _isParent => _role == AppRole.father || _role == AppRole.mother;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? stage1AlertsHubRepository;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
    });
  }

  @override
  void didUpdateWidget(covariant AlertsHubScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final snap = await _repo.load();
      if (!mounted) return;
      setState(() {
        _snapshot = snap;
        _loading = false;
        _loadFailed = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _snapshot = null;
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  Future<void> _openSos() async {
    if (_sosBusy) return;
    if (widget.onSos != null) {
      widget.onSos!();
      return;
    }
    setState(() => _sosBusy = true);
    final fire = widget.sosFire ?? stage1SosFireService;
    await fire.fire(childId: 'family');
    if (!mounted) return;
    setState(() => _sosBusy = false);
    context.push('/scr-fat-018');
  }

  void _onRowTap(HubAlert alert) {
    if (!alert.isTappable) return;
    switch (alert.target) {
      case HubAlertTarget.alertDetail:
        if (widget.onOpenAlert != null) {
          widget.onOpenAlert!(alert);
          return;
        }
        final kind = alert.alertKind?.trim();
        final params = <String, String>{'alertId': alert.id};
        if (kind != null && kind.isNotEmpty) {
          params['alertKind'] = kind;
        }
        context.push(
          Uri(path: '/scr-fat-020', queryParameters: params).toString(),
        );
      case HubAlertTarget.timeRequests:
        if (widget.onOpenTimeRequests != null) {
          widget.onOpenTimeRequests!();
          return;
        }
        context.push('/scr-fat-033');
      case HubAlertTarget.appApproval:
        if (widget.onOpenAppApproval != null) {
          widget.onOpenAppApproval!();
          return;
        }
        context.push('/scr-fat-035');
      case HubAlertTarget.none:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;

    return Scaffold(
      key: AlertsHubKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.ink,
        title: Text(
          l10n.alertsHubTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          // P-4 — SOS never gated by empty/loading/error.
          IconButton(
            key: AlertsHubKeys.sosCta,
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
    if (!_isParent) {
      return AppEmptyState(
        key: AlertsHubKeys.childLean,
        title: l10n.alertsHubChildLeanTitle,
        message: l10n.alertsHubChildLeanMessage,
      );
    }

    if (_loading) {
      return Semantics(
        key: AlertsHubKeys.loading,
        label: l10n.alertsHubLoadingSemantics,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadFailed) {
      return AppErrorState(
        key: AlertsHubKeys.error,
        kind: AppErrorKind.network,
        onRetry: _load,
      );
    }

    final snap = _snapshot ?? const AlertsHubSnapshot();
    if (snap.isEmpty) {
      return AppEmptyState(
        key: AlertsHubKeys.empty,
        title: l10n.alertsHubEmptyTitle,
        message: l10n.alertsHubEmptyMessage,
      );
    }

    return SingleChildScrollView(
      key: AlertsHubKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BannerNote(
            key: AlertsHubKeys.honestyBanner,
            variant: BannerVariant.p,
            message: l10n.alertsHubHonestyBanner,
          ),
          const SizedBox(height: 10),
          BannerNote(
            key: AlertsHubKeys.p4Banner,
            variant: BannerVariant.a,
            message: l10n.alertsHubP4Banner,
          ),
          if (snap.critical.isNotEmpty) ...[
            const SizedBox(height: 14),
            _UrgencySection(
              sectionKey: AlertsHubKeys.sectionCritical,
              countKey: AlertsHubKeys.countCritical,
              title: l10n.alertsHubSectionCritical,
              countLabel: l10n.alertsHubCount(snap.criticalCount),
              tone: _UrgencyTone.critical,
              alerts: snap.critical,
              onTap: _onRowTap,
            ),
          ],
          if (snap.attention.isNotEmpty) ...[
            const SizedBox(height: 14),
            _UrgencySection(
              sectionKey: AlertsHubKeys.sectionAttention,
              countKey: AlertsHubKeys.countAttention,
              title: l10n.alertsHubSectionAttention,
              countLabel: l10n.alertsHubCount(snap.attentionCount),
              tone: _UrgencyTone.attention,
              alerts: snap.attention,
              onTap: _onRowTap,
            ),
          ],
          if (snap.reassurance.isNotEmpty) ...[
            const SizedBox(height: 14),
            _UrgencySection(
              sectionKey: AlertsHubKeys.sectionReassurance,
              countKey: AlertsHubKeys.countReassurance,
              title: l10n.alertsHubSectionReassurance,
              countLabel: l10n.alertsHubCount(snap.reassuranceCount),
              tone: _UrgencyTone.reassurance,
              alerts: snap.reassurance,
              onTap: _onRowTap,
            ),
          ],
        ],
      ),
    );
  }
}

enum _UrgencyTone { critical, attention, reassurance }

class _UrgencySection extends StatelessWidget {
  const _UrgencySection({
    required this.sectionKey,
    required this.countKey,
    required this.title,
    required this.countLabel,
    required this.tone,
    required this.alerts,
    required this.onTap,
  });

  final Key sectionKey;
  final Key countKey;
  final String title;
  final String countLabel;
  final _UrgencyTone tone;
  final List<HubAlert> alerts;
  final void Function(HubAlert alert) onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final shadows = Theme.of(context).extension<FamilyShadows>()!;
    final (pillBg, pillFg) = switch (tone) {
      _UrgencyTone.critical => (colors.coral100, colors.coral),
      _UrgencyTone.attention => (colors.amber100, colors.amberInk),
      _UrgencyTone.reassurance => (colors.mint100, colors.mintInk),
    };

    return Semantics(
      container: true,
      label: '$title · $countLabel',
      child: DecoratedBox(
        key: sectionKey,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(radii.card),
          border: Border.all(color: colors.border.withValues(alpha: 0.85)),
          boxShadow: [shadows.shCard],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: pillBg,
                        borderRadius: BorderRadius.circular(radii.pill),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: pillFg,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    key: countKey,
                    countLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: colors.ink2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              for (var i = 0; i < alerts.length; i++)
                _AlertRow(
                  alert: alerts[i],
                  showDivider: i < alerts.length - 1,
                  onTap: () => onTap(alerts[i]),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  const _AlertRow({
    required this.alert,
    required this.showDivider,
    required this.onTap,
  });

  final HubAlert alert;
  final bool showDivider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final avatarColor = _swatchColor(alert.swatch, colors);

    return RowTile(
      key: AlertsHubKeys.row(alert.id),
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: avatarColor,
        child: Text(alert.emoji, style: const TextStyle(fontSize: 18)),
      ),
      title: alert.title,
      subtitle: alert.subtitle,
      trailing: alert.isTappable
          ? Icon(Icons.chevron_left, color: colors.ink2, size: 20)
          : null,
      onTap: alert.isTappable ? onTap : null,
      showDivider: showDivider,
    );
  }
}
