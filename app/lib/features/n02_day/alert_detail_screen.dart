import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/app_error_state.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/components/row_tile.dart';
import 'package:family_os/core/design/components/tag.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/features/n02_day/alert_detail_repository.dart';
import 'package:family_os/features/n02_day/alerts_hub_repository.dart';

/// Widget keys for SCR-FAT-020 acceptance.
abstract final class AlertDetailKeys {
  static const screen = Key('alert_detail_screen');
  static const loading = Key('alert_detail_loading');
  static const empty = Key('alert_detail_empty');
  static const notFound = Key('alert_detail_not_found');
  static const error = Key('alert_detail_error');
  static const body = Key('alert_detail_body');
  static const honestyBanner = Key('alert_detail_honesty');
  static const p4Banner = Key('alert_detail_p4');
  static const sosCta = Key('alert_detail_sos');
  static const childLean = Key('alert_detail_child_lean');
  static const urgencyTag = Key('alert_detail_urgency');
  static const categoryTag = Key('alert_detail_category');
  static const title = Key('alert_detail_title');
  static const bodyText = Key('alert_detail_body_text');
  static const advice = Key('alert_detail_advice');
  static const toneSection = Key('alert_detail_tone_section');
  static const primaryAction = Key('alert_detail_primary');
  static const primaryDone = Key('alert_detail_primary_done');
  static const secondaryAction = Key('alert_detail_secondary');
  static const requestBlock = Key('alert_detail_request_block');

  static Key toneReply(String id) => Key('alert_detail_tone_$id');
}

/// SCR-FAT-020 — تفصيل التنبيه (parent alert detail).
///
/// Opened from FAT-019 only (`noHub:true`). Four kind templates (stranger /
/// battery / games / arrive). Bark honesty: category + severity + advice —
/// never raw message text. P-4 SOS ungated. Mother OK; child lean. Rules
/// actions (block) require father or [MotherLevel.full]. Mock-first Rule 23/25.
class AlertDetailScreen extends StatefulWidget {
  const AlertDetailScreen({
    super.key,
    this.alertId,
    this.alertKind,
    this.repository,
    this.roleOverride,
    this.motherLevel = MotherLevel.partner,
    this.sosFire,
    this.onSos,
    this.onOpenChat,
    this.onOpenScreenTime,
    this.onOpenMap,
    this.onToneReply,
  });

  /// From route `?alertId=` (preferred).
  final String? alertId;

  /// From route `?alertKind=` (fallback when id missing).
  final String? alertKind;

  /// Null → [stage1AlertDetailRepository].
  final AlertDetailRepository? repository;

  /// Test seam — when set, ignores [CurrentRole].
  final AppRole? roleOverride;

  /// Mother authority — block needs [MotherLevel.full] (prototype `rules`).
  final MotherLevel motherLevel;

  /// P-4 SOS seam — null → [stage1SosFireService].
  final SosFireService? sosFire;

  final VoidCallback? onSos;
  final void Function(String childId)? onOpenChat;
  final void Function(String childId)? onOpenScreenTime;
  final void Function(String childId)? onOpenMap;
  final void Function(AlertToneReply reply, String childId)? onToneReply;

  @override
  AlertDetailScreenState createState() => AlertDetailScreenState();
}

class AlertDetailScreenState extends State<AlertDetailScreen> {
  late final AlertDetailRepository _repo;
  var _loading = true;
  var _loadFailed = false;
  var _busy = false;
  AlertDetail? _detail;

  AppRole get _role =>
      widget.roleOverride ??
      CurrentRole.maybeNotifierOf(context)?.value ??
      AppRole.father;

  bool get _isParent => _role == AppRole.father || _role == AppRole.mother;

  /// Father always; mother only at full (prototype `can('rules')`).
  bool get _canEditRules {
    if (_role == AppRole.father) return true;
    if (_role == AppRole.mother) {
      return widget.motherLevel == MotherLevel.full;
    }
    return false;
  }

  String? get _resolvedAlertId {
    final raw = widget.alertId?.trim();
    if (raw == null || raw.isEmpty) return null;
    return raw;
  }

  String? get _resolvedKind {
    final raw = widget.alertKind?.trim();
    if (raw == null || raw.isEmpty) return null;
    return raw;
  }

  bool get _hasLookup =>
      _resolvedAlertId != null || _resolvedKind != null;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? stage1AlertDetailRepository;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
    });
  }

  @override
  void didUpdateWidget(covariant AlertDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.alertId != widget.alertId ||
        oldWidget.alertKind != widget.alertKind ||
        oldWidget.repository != widget.repository) {
      _load();
    }
  }

  Future<void> _load() async {
    if (!_hasLookup) {
      setState(() {
        _detail = null;
        _loading = false;
        _loadFailed = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final detail = await _repo.load(
        alertId: _resolvedAlertId,
        alertKind: _resolvedKind,
      );
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loading = false;
        _loadFailed = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _detail = null;
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  Future<void> _openSos() async {
    if (_busy) return;
    if (widget.onSos != null) {
      widget.onSos!();
      return;
    }
    setState(() => _busy = true);
    final fire = widget.sosFire ?? stage1SosFireService;
    await fire.fire(childId: _detail?.childId ?? 'family');
    if (!mounted) return;
    setState(() => _busy = false);
    context.push('/scr-fat-018');
  }

  Future<void> _markPrimaryDone() async {
    final detail = _detail;
    if (detail == null || _busy || detail.primaryDone) return;
    setState(() => _busy = true);
    try {
      final updated = await _repo.markPrimaryDone(detail.id);
      if (!mounted) return;
      setState(() {
        _detail = updated;
        _busy = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() => _busy = false);
    }
  }

  void _openChat() {
    final id = _detail?.childId ?? '';
    if (widget.onOpenChat != null) {
      widget.onOpenChat!(id);
      return;
    }
    final path = id.isEmpty
        ? '/scr-fat-022'
        : '/scr-fat-022?childId=${Uri.encodeComponent(id)}';
    context.push(path);
  }

  void _openScreenTime() {
    final id = _detail?.childId ?? '';
    if (widget.onOpenScreenTime != null) {
      widget.onOpenScreenTime!(id);
      return;
    }
    final path = id.isEmpty
        ? '/scr-fat-032'
        : '/scr-fat-032?childId=${Uri.encodeComponent(id)}';
    context.push(path);
  }

  void _openMap() {
    final id = _detail?.childId ?? '';
    if (widget.onOpenMap != null) {
      widget.onOpenMap!(id);
      return;
    }
    final path = id.isEmpty
        ? '/scr-fat-014'
        : '/scr-fat-014?childId=${Uri.encodeComponent(id)}';
    context.push(path);
  }

  void _onTone(AlertToneReply reply) {
    final id = _detail?.childId ?? '';
    if (widget.onToneReply != null) {
      widget.onToneReply!(reply, id);
      return;
    }
    _openChat();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;

    return Scaffold(
      key: AlertDetailKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.ink,
        title: Text(
          l10n.alertDetailTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          // P-4 — SOS never gated by empty/loading/error/not-found.
          IconButton(
            key: AlertDetailKeys.sosCta,
            tooltip: l10n.spineCtaSosSemantics,
            onPressed: _busy ? null : _openSos,
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
        key: AlertDetailKeys.childLean,
        title: l10n.alertDetailChildLeanTitle,
        message: l10n.alertDetailChildLeanMessage,
      );
    }

    if (_loading) {
      return Semantics(
        key: AlertDetailKeys.loading,
        label: l10n.alertDetailLoadingSemantics,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadFailed) {
      return AppErrorState(
        key: AlertDetailKeys.error,
        kind: AppErrorKind.network,
        onRetry: _load,
      );
    }

    if (!_hasLookup) {
      return AppEmptyState(
        key: AlertDetailKeys.empty,
        title: l10n.alertDetailEmptyTitle,
        message: l10n.alertDetailEmptyMessage,
      );
    }

    final detail = _detail;
    if (detail == null) {
      return AppEmptyState(
        key: AlertDetailKeys.notFound,
        title: l10n.alertDetailNotFoundTitle,
        message: l10n.alertDetailNotFoundMessage,
      );
    }

    return SingleChildScrollView(
      key: AlertDetailKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BannerNote(
            key: AlertDetailKeys.honestyBanner,
            variant: BannerVariant.p,
            message: l10n.alertDetailHonestyBanner,
          ),
          const SizedBox(height: 10),
          BannerNote(
            key: AlertDetailKeys.p4Banner,
            variant: BannerVariant.a,
            message: l10n.alertDetailP4Banner,
          ),
          const SizedBox(height: 14),
          _DetailCard(detail: detail, l10n: l10n, colors: colors),
          if (detail.kind == AlertDetailKind.stranger &&
              detail.toneReplies.isNotEmpty) ...[
            const SizedBox(height: 12),
            _ToneSection(
              replies: detail.toneReplies,
              l10n: l10n,
              onTap: _onTone,
            ),
          ],
          const SizedBox(height: 16),
          ..._actionWidgets(detail, l10n),
        ],
      ),
    );
  }

  List<Widget> _actionWidgets(AlertDetail detail, AppLocalizations l10n) {
    switch (detail.kind) {
      case AlertDetailKind.stranger:
        return [
          if (detail.primaryDone)
            BannerNote(
              key: AlertDetailKeys.primaryDone,
              variant: BannerVariant.t,
              message: l10n.alertDetailBlockDoneBanner,
            )
          else if (_canEditRules)
            PrimaryBtn(
              key: AlertDetailKeys.primaryAction,
              label: l10n.alertDetailBlockCta,
              onPressed: _busy ? null : _markPrimaryDone,
            )
          else
            PrimaryBtn(
              key: AlertDetailKeys.requestBlock,
              label: l10n.alertDetailRequestBlockCta,
              variant: PrimaryBtnVariant.sec,
              onPressed: _busy
                  ? null
                  : () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.alertDetailRequestBlockToast),
                        ),
                      );
                    },
            ),
          const SizedBox(height: 10),
          PrimaryBtn(
            key: AlertDetailKeys.secondaryAction,
            label: l10n.alertDetailOpenChatCta,
            variant: PrimaryBtnVariant.sec,
            onPressed: _openChat,
          ),
        ];
      case AlertDetailKind.battery:
        return [
          if (detail.primaryDone)
            BannerNote(
              key: AlertDetailKeys.primaryDone,
              variant: BannerVariant.t,
              message: l10n.alertDetailReminderDoneBanner,
            )
          else
            PrimaryBtn(
              key: AlertDetailKeys.primaryAction,
              label: l10n.alertDetailSendReminderCta,
              onPressed: _busy ? null : _markPrimaryDone,
            ),
          const SizedBox(height: 10),
          PrimaryBtn(
            key: AlertDetailKeys.secondaryAction,
            label: l10n.alertDetailOpenChatCta,
            variant: PrimaryBtnVariant.sec,
            onPressed: _openChat,
          ),
        ];
      case AlertDetailKind.games:
        return [
          PrimaryBtn(
            key: AlertDetailKeys.secondaryAction,
            label: l10n.alertDetailReviewScreenTimeCta,
            variant: PrimaryBtnVariant.sec,
            onPressed: _openScreenTime,
          ),
          const SizedBox(height: 10),
          if (detail.primaryDone)
            BannerNote(
              key: AlertDetailKeys.primaryDone,
              variant: BannerVariant.t,
              message: l10n.alertDetailDismissDoneBanner,
            )
          else
            PrimaryBtn(
              key: AlertDetailKeys.primaryAction,
              label: l10n.alertDetailDismissCta,
              variant: PrimaryBtnVariant.ghost,
              onPressed: _busy ? null : _markPrimaryDone,
            ),
        ];
      case AlertDetailKind.arrive:
        return [
          if (detail.primaryDone)
            BannerNote(
              key: AlertDetailKeys.primaryDone,
              variant: BannerVariant.t,
              message: l10n.alertDetailHeartDoneBanner,
            )
          else
            PrimaryBtn(
              key: AlertDetailKeys.primaryAction,
              label: l10n.alertDetailSendHeartCta,
              variant: PrimaryBtnVariant.mint,
              onPressed: _busy ? null : _markPrimaryDone,
            ),
          const SizedBox(height: 10),
          PrimaryBtn(
            key: AlertDetailKeys.secondaryAction,
            label: l10n.alertDetailShowOnMapCta,
            variant: PrimaryBtnVariant.sec,
            onPressed: _openMap,
          ),
        ];
    }
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({
    required this.detail,
    required this.l10n,
    required this.colors,
  });

  final AlertDetail detail;
  final AppLocalizations l10n;
  final FamilyColors colors;

  @override
  Widget build(BuildContext context) {
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radii.card),
        boxShadow: [
          BoxShadow(
            color: colors.ink.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _UrgencyChip(
                  key: AlertDetailKeys.urgencyTag,
                  urgency: detail.urgency,
                  l10n: l10n,
                  colors: colors,
                ),
                Tag(
                  key: AlertDetailKeys.categoryTag,
                  label: _categoryLabel(detail.kind, l10n),
                  variant: TagVariant.p,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              detail.title,
              key: AlertDetailKeys.title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: colors.ink,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              detail.body,
              key: AlertDetailKeys.bodyText,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colors.ink2,
                height: 1.65,
              ),
            ),
            if (detail.advice != null && detail.advice!.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              DecoratedBox(
                key: AlertDetailKeys.advice,
                decoration: BoxDecoration(
                  color: colors.bg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    '${l10n.alertDetailAdvicePrefix} ${detail.advice}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.ink,
                      height: 1.6,
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

  static String _categoryLabel(AlertDetailKind kind, AppLocalizations l10n) {
    return switch (kind) {
      AlertDetailKind.stranger => l10n.alertDetailCategoryStranger,
      AlertDetailKind.battery => l10n.alertDetailCategoryDevice,
      AlertDetailKind.games => l10n.alertDetailCategoryScreenTime,
      AlertDetailKind.arrive => l10n.alertDetailCategorySafeArrival,
    };
  }
}

class _UrgencyChip extends StatelessWidget {
  const _UrgencyChip({
    super.key,
    required this.urgency,
    required this.l10n,
    required this.colors,
  });

  final AlertUrgency urgency;
  final AppLocalizations l10n;
  final FamilyColors colors;

  @override
  Widget build(BuildContext context) {
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final (label, bg, fg) = switch (urgency) {
      AlertUrgency.critical => (
          l10n.alertDetailUrgencyCritical,
          colors.coral100,
          colors.coral,
        ),
      AlertUrgency.attention => (
          l10n.alertDetailUrgencyAttention,
          colors.amber100,
          colors.amberInk,
        ),
      AlertUrgency.reassurance => (
          l10n.alertDetailUrgencyReassurance,
          colors.mint100,
          colors.mintInk,
        ),
    };

    return Semantics(
      label: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(radii.pill),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: fg,
              height: 1.3,
            ),
          ),
        ),
      ),
    );
  }
}

class _ToneSection extends StatelessWidget {
  const _ToneSection({
    required this.replies,
    required this.l10n,
    required this.onTap,
  });

  final List<AlertToneReply> replies;
  final AppLocalizations l10n;
  final void Function(AlertToneReply reply) onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    return DecoratedBox(
      key: AlertDetailKeys.toneSection,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radii.card),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                l10n.alertDetailToneSectionTitle,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: colors.ink,
                ),
              ),
            ),
            const SizedBox(height: 6),
            for (final r in replies)
              RowTile(
                key: AlertDetailKeys.toneReply(r.id),
                leading: const Text('💬', style: TextStyle(fontSize: 18)),
                title: r.text,
                subtitle: r.hint,
                onTap: () => onTap(r),
                showDivider: r != replies.last,
              ),
          ],
        ),
      ),
    );
  }
}
