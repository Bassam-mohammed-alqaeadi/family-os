import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_guard.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/identity/identity_scope.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/core/policy/time_request_service.dart';
import 'package:family_os/features/n03_screen_time/child_time_request_models.dart';
import 'package:family_os/features/n03_screen_time/child_time_request_repository.dart';
import 'package:family_os/features/n03_screen_time/stage1_child_scope.dart';

/// Widget keys for SCR-CHD-020 acceptance.
abstract final class ChildTimeRequestKeys {
  static const screen = Key('child_time_request_screen');
  static const loading = Key('child_time_request_loading');
  static const empty = Key('child_time_request_empty');
  static const body = Key('child_time_request_body');
  static const statusBanner = Key('child_time_request_status');
  static const mins15 = Key('child_time_request_mins_15');
  static const mins30 = Key('child_time_request_mins_30');
  static const mins60 = Key('child_time_request_mins_60');
  static const tradeWird = Key('child_time_request_trade_wird');
  static const tradeTidy = Key('child_time_request_trade_tidy');
  static const tradeMath = Key('child_time_request_trade_math');
  static const tradeDirect = Key('child_time_request_trade_direct');
  static const submitCta = Key('child_time_request_submit');
  static const tasksCta = Key('child_time_request_tasks');
  static const parentLean = Key('child_time_request_parent_lean');
  static const sosIconCta = Key('child_time_request_sos_icon');
}

/// SCR-CHD-020 — طلب وقت إضافي (polite minutes request + trade).
///
/// Prototype CHD-020 · RoleGuard child · minutes-only · trade wheel ·
/// submit→004 · tasked→022 · P-4 SOS · Rule 12/23.
class ChildTimeRequestScreen extends StatefulWidget {
  const ChildTimeRequestScreen({
    super.key,
    this.repository,
    this.sosFire,
    this.roleOverride,
    this.onSos,
    this.onNavigate,
  });

  final ChildTimeRequestRepository? repository;
  final SosFireService? sosFire;
  final AppRole? roleOverride;
  final VoidCallback? onSos;
  final void Function(String screenId)? onNavigate;

  @override
  State<ChildTimeRequestScreen> createState() => _ChildTimeRequestScreenState();
}

class _ChildTimeRequestScreenState extends State<ChildTimeRequestScreen> {
  late ChildTimeRequestRepository _repo;
  late final SosFireService _sos;
  TimeRequestDecisionBus? _bus;
  var _sosBusy = false;
  var _loading = true;
  var _busy = false;
  ChildTimeRequestSnapshot _snap = const ChildTimeRequestSnapshot();
  var _scopedRepoBound = false;

  AppRole get _role {
    final override = widget.roleOverride;
    if (override != null) return override;
    return resolveAuthorizationContext(
      context,
      fallbackRole: AppRole.child,
    ).role;
  }

  bool get _isChild => _role == AppRole.child;

  bool get _formInteractive =>
      !_busy &&
      !_snap.formLocked &&
      _snap.status != ChildTimeRequestStatus.pending;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? stage1ChildTimeRequestRepository;
    _sos = widget.sosFire ?? stage1SosFireService;
    if (widget.repository == null) {
      _bus = stage1TimeRequestDecisionBus..addListener(_onDecision);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.repository != null || _scopedRepoBound) return;
    final runtime = CurrentIdentity.maybeOf(context);
    final childId = runtime == null
        ? kStage1CanonicalChildId
        : familyScopedChildId(
            familyId: runtime.activeFamilyId,
            childId: runtime.activeChildId,
          );
    _repo = ServiceChildTimeRequestRepository(
      service: stage1TimeRequestService,
      childId: childId,
    );
    _scopedRepoBound = true;
    _load();
  }

  @override
  void dispose() {
    _bus?.removeListener(_onDecision);
    super.dispose();
  }

  void _onDecision() {
    if (!mounted) return;
    _load();
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
    final childId =
        CurrentIdentity.maybeOf(context)?.activeChildId.value ?? 'self';
    await _sos.fire(childId: childId);
    if (!mounted) return;
    setState(() => _sosBusy = false);
    context.push(screenPath('SCR-CHD-005'));
  }

  void _go(String screenId) {
    if (widget.onNavigate != null) {
      widget.onNavigate!(screenId);
      return;
    }
    context.push(screenPath(screenId));
  }

  Future<void> _selectMins(int m) async {
    if (!_formInteractive) return;
    setState(() => _busy = true);
    final snap = await _repo.selectMinutes(m);
    if (!mounted) return;
    setState(() {
      _snap = snap;
      _busy = false;
    });
  }

  Future<void> _selectTrade(String key) async {
    if (!_formInteractive) return;
    setState(() => _busy = true);
    final snap = await _repo.selectTrade(key);
    if (!mounted) return;
    setState(() {
      _snap = snap;
      _busy = false;
    });
  }

  Future<void> _submit() async {
    if (!_formInteractive) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    final snap = await _repo.submit();
    if (!mounted) return;
    setState(() {
      _snap = snap;
      _busy = false;
    });
    if (snap.submitErrorKey == 'duplicatePending') {
      AppToast.show(context, message: l10n.childTimeRequestDuplicateError);
      return;
    }
    AppToast.show(context, message: l10n.childTimeRequestSubmitToast);
    _go('SCR-CHD-004');
  }

  String _taskTitle(AppLocalizations l10n) {
    return switch (_snap.taskTitleKey) {
      'tidyDesk' => l10n.childTimeRequestTaskTidyDesk,
      _ => l10n.childTimeRequestTaskTidyDesk,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;

    return Scaffold(
      key: ChildTimeRequestKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        elevation: 0,
        foregroundColor: colors.ink,
        title: Text(
          l10n.childTimeRequestTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          IconButton(
            key: ChildTimeRequestKeys.sosIconCta,
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
      body: SafeArea(child: _buildBody(l10n, colors)),
    );
  }

  Widget _buildBody(AppLocalizations l10n, FamilyColors colors) {
    if (!_isChild) {
      return AppEmptyState(
        key: ChildTimeRequestKeys.parentLean,
        title: l10n.childTimeRequestParentLeanTitle,
        message: l10n.childTimeRequestParentLeanMessage,
      );
    }
    if (_loading) {
      return Center(
        key: ChildTimeRequestKeys.loading,
        child: Semantics(
          label: l10n.childTimeRequestLoadingSemantics,
          child: const CircularProgressIndicator(),
        ),
      );
    }
    if (_snap.isEmpty) {
      return AppEmptyState(
        key: ChildTimeRequestKeys.empty,
        title: l10n.childTimeRequestEmptyTitle,
        message: l10n.childTimeRequestEmptyMessage,
        actionLabel: l10n.childTimeRequestEmptyCta,
        onAction: () => _go('SCR-CHD-004'),
      );
    }

    final radii = Theme.of(context).extension<FamilyRadii>()!;

    return SingleChildScrollView(
      key: ChildTimeRequestKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_snap.status != ChildTimeRequestStatus.none) ...[
            _statusCard(l10n, colors, radii),
            const SizedBox(height: 12),
          ],
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(radii.card),
              border: Border.all(color: colors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.childTimeRequestHowMuch,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: colors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: PrimaryBtn(
                          key: ChildTimeRequestKeys.mins15,
                          label: l10n.childTimeRequestMins15,
                          variant: _snap.selectedMinutes == 15
                              ? PrimaryBtnVariant.teal
                              : PrimaryBtnVariant.sec,
                          onPressed: _formInteractive
                              ? () => _selectMins(15)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: PrimaryBtn(
                          key: ChildTimeRequestKeys.mins30,
                          label: l10n.childTimeRequestMins30,
                          variant: _snap.selectedMinutes == 30
                              ? PrimaryBtnVariant.teal
                              : PrimaryBtnVariant.sec,
                          onPressed: _formInteractive
                              ? () => _selectMins(30)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: PrimaryBtn(
                          key: ChildTimeRequestKeys.mins60,
                          label: l10n.childTimeRequestMins60,
                          variant: _snap.selectedMinutes == 60
                              ? PrimaryBtnVariant.teal
                              : PrimaryBtnVariant.sec,
                          onPressed: _formInteractive
                              ? () => _selectMins(60)
                              : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.childTimeRequestReasonLabel,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: colors.ink2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.childTimeRequestReasonFinishedHomework,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: colors.ink,
            ),
          ),
          const SizedBox(height: 12),
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(radii.card),
              border: Border.all(color: colors.teal, width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.childTimeRequestTradeHeading,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: colors.teal600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.childTimeRequestTradeCaption,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.ink2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _tradeBtn(
                    key: ChildTimeRequestKeys.tradeWird,
                    label: l10n.childTimeRequestTradeWird,
                    tradeKey: 'wirdMulk',
                    l10n: l10n,
                  ),
                  _tradeBtn(
                    key: ChildTimeRequestKeys.tradeTidy,
                    label: l10n.childTimeRequestTradeTidy,
                    tradeKey: 'tidyRoom',
                    l10n: l10n,
                  ),
                  _tradeBtn(
                    key: ChildTimeRequestKeys.tradeMath,
                    label: l10n.childTimeRequestTradeMath,
                    tradeKey: 'mathReview',
                    l10n: l10n,
                  ),
                  _tradeBtn(
                    key: ChildTimeRequestKeys.tradeDirect,
                    label: l10n.childTimeRequestTradeDirect,
                    tradeKey: 'direct',
                    l10n: l10n,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          PrimaryBtn(
            key: ChildTimeRequestKeys.submitCta,
            label: l10n.childTimeRequestSubmitCta,
            onPressed: _formInteractive ? _submit : null,
          ),
        ],
      ),
    );
  }

  Widget _tradeBtn({
    required Key key,
    required String label,
    required String tradeKey,
    required AppLocalizations l10n,
  }) {
    final selected = _snap.tradeKey == tradeKey;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: PrimaryBtn(
        key: key,
        label: label,
        variant: selected ? PrimaryBtnVariant.teal : PrimaryBtnVariant.sec,
        onPressed: _formInteractive ? () => _selectTrade(tradeKey) : null,
      ),
    );
  }

  Widget _statusCard(
    AppLocalizations l10n,
    FamilyColors colors,
    FamilyRadii radii,
  ) {
    final rejectedBody = _snap.decisionReason?.trim().isNotEmpty == true
        ? _snap.decisionReason!
        : l10n.childTimeRequestStatusRejectedBody;
    final (title, body, Color border) = switch (_snap.status) {
      ChildTimeRequestStatus.pending => (
        l10n.childTimeRequestStatusPendingTitle,
        l10n.childTimeRequestStatusPendingBody(_snap.requestedMinutes),
        colors.amber,
      ),
      ChildTimeRequestStatus.approved => (
        l10n.childTimeRequestStatusApprovedTitle(
          _snap.grantedMinutes ?? _snap.requestedMinutes,
        ),
        l10n.childTimeRequestStatusApprovedBody,
        colors.mint,
      ),
      ChildTimeRequestStatus.tasked => (
        l10n.childTimeRequestStatusTaskedTitle,
        l10n.childTimeRequestStatusTaskedBody(
          _taskTitle(l10n),
          _snap.taskMins ?? 0,
        ),
        colors.p400,
      ),
      ChildTimeRequestStatus.rejected => (
        l10n.childTimeRequestStatusRejectedTitle,
        rejectedBody,
        colors.coral,
      ),
      ChildTimeRequestStatus.expired => (
        l10n.childTimeRequestStatusExpiredTitle,
        l10n.childTimeRequestStatusExpiredBody,
        colors.ink2,
      ),
      ChildTimeRequestStatus.none => ('', '', colors.border),
    };

    return DecoratedBox(
      key: ChildTimeRequestKeys.statusBanner,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radii.card),
        border: Border.all(color: border, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
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
            const SizedBox(height: 4),
            Text(
              body,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.ink2,
              ),
            ),
            if (_snap.status == ChildTimeRequestStatus.tasked) ...[
              const SizedBox(height: 8),
              PrimaryBtn(
                key: ChildTimeRequestKeys.tasksCta,
                label: l10n.childTimeRequestGoTasksCta,
                onPressed: () => _go('SCR-CHD-022'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
