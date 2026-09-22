import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/app_error_state.dart';
import 'package:family_os/core/design/components/family_ui_mode.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/sos_alert.dart';
import 'package:family_os/core/policy/sos_alert_repository.dart';

/// Widget keys for SCR-CHD-006 acceptance.
abstract final class ChildSosInProgressKeys {
  static const screen = Key('child_sos_in_progress_screen');
  static const loading = Key('child_sos_in_progress_loading');
  static const empty = Key('child_sos_in_progress_empty');
  static const error = Key('child_sos_in_progress_error');
  static const body = Key('child_sos_in_progress_body');
  static const headline = Key('child_sos_in_progress_headline');
  static const broadcast = Key('child_sos_in_progress_broadcast');
  static const statusCard = Key('child_sos_in_progress_status');
  static const p4Banner = Key('child_sos_in_progress_p4');
  static const callFather = Key('child_sos_in_progress_call_father');
  static const cancelCta = Key('child_sos_in_progress_cancel');
  static const cancelSheet = Key('child_sos_in_progress_cancel_sheet');
  static const confirmSafe = Key('child_sos_in_progress_confirm_safe');
  static const cancelBack = Key('child_sos_in_progress_cancel_back');
  static const parentLean = Key('child_sos_in_progress_parent_lean');
  static const openButtonCta = Key('child_sos_in_progress_open_button');
}

/// SCR-CHD-006 — الاستغاثة جارية (child SOS in progress, mock-first).
///
/// Prototype CHD-006: coral full-bleed board after CHD-005 fire —
/// family notified + live location broadcast + who saw the alert +
/// call father + safe cancel with confirmation → resolve → CHD-004.
///
/// P-4 / UI-007: in-progress SOS is never muted or paywalled.
/// RoleGuard: child body; parent lean. Rule 23: parametric ids only.
class ChildSosInProgressScreen extends StatefulWidget {
  const ChildSosInProgressScreen({
    super.key,
    this.alertId,
    this.childId,
    this.repository,
    this.roleOverride,
    this.onCallFather,
    this.onResolved,
    this.onOpenSosButton,
  });

  /// Deep-link `?alertId=` from CHD-005 handoff.
  final String? alertId;

  /// Deep-link `?childId=` (Rule 23 parametric).
  final String? childId;

  /// Null → [stage1SosAlertRepository].
  final SosAlertRepository? repository;

  /// Test seam — when set, ignores [CurrentRole].
  final AppRole? roleOverride;

  /// Test seam — when null, navigates to `/scr-chd-007`.
  final VoidCallback? onCallFather;

  /// Test seam — when null, navigates to `/scr-chd-004` after resolve.
  final VoidCallback? onResolved;

  /// Test seam — when null, navigates to `/scr-chd-005` from empty.
  final VoidCallback? onOpenSosButton;

  @override
  State<ChildSosInProgressScreen> createState() =>
      _ChildSosInProgressScreenState();
}

class _ChildSosInProgressScreenState extends State<ChildSosInProgressScreen>
    with SingleTickerProviderStateMixin {
  late final SosAlertRepository _repo;
  late final AnimationController _pulse;
  var _loading = true;
  var _loadFailed = false;
  var _busy = false;
  SosAlert? _alert;

  AppRole _role(BuildContext context) =>
      widget.roleOverride ??
      CurrentRole.maybeNotifierOf(context)?.value ??
      AppRole.child;

  String? get _resolvedAlertId {
    final raw = widget.alertId?.trim();
    if (raw == null || raw.isEmpty) return null;
    return raw;
  }

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? stage1SosAlertRepository;
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
    });
  }

  @override
  void didUpdateWidget(covariant ChildSosInProgressScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.alertId != widget.alertId ||
        oldWidget.repository != widget.repository) {
      _load();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      var alert = await _repo.loadActive(alertId: _resolvedAlertId);
      final wantChild = widget.childId?.trim();
      if (alert != null &&
          wantChild != null &&
          wantChild.isNotEmpty &&
          alert.childId != wantChild) {
        alert = null;
      }
      if (!mounted) return;
      setState(() {
        _alert = alert;
        _loading = false;
        _loadFailed = false;
      });
      final reduceMotion = MediaQuery.disableAnimationsOf(context);
      final isChild = _role(context) == AppRole.child;
      if (isChild && alert != null && alert.isActive && !reduceMotion) {
        _pulse.repeat(reverse: true);
      } else {
        _stopPulse();
      }
    } on Object {
      if (!mounted) return;
      _stopPulse();
      setState(() {
        _alert = null;
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  void _stopPulse() {
    if (_pulse.isAnimating) {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  void _callFather() {
    if (widget.onCallFather != null) {
      widget.onCallFather!();
      return;
    }
    context.go('/scr-chd-007');
  }

  void _openSosButton() {
    if (widget.onOpenSosButton != null) {
      widget.onOpenSosButton!();
      return;
    }
    context.go('/scr-chd-005');
  }

  Future<void> _openCancelSheet(AppLocalizations l10n, Color coral) async {
    if (_busy || _alert == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          key: ChildSosInProgressKeys.cancelSheet,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.childSosInProgressCancelSheetTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: coral,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.childSosInProgressCancelSheetBody,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                  color: Color(0xFF3D3D3D),
                ),
              ),
              const SizedBox(height: 16),
              Semantics(
                button: true,
                label: l10n.childSosInProgressConfirmSafeSemantics,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Material(
                    color: const Color(0xFF1FA97A),
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      key: ChildSosInProgressKeys.confirmSafe,
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        _confirmSafe();
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        child: Text(
                          l10n.childSosInProgressConfirmSafeCta,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Semantics(
                button: true,
                label: l10n.childSosInProgressCancelBackCta,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: TextButton(
                    key: ChildSosInProgressKeys.cancelBack,
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: Text(l10n.childSosInProgressCancelBackCta),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmSafe() async {
    final alert = _alert;
    if (alert == null || _busy) return;
    setState(() => _busy = true);
    try {
      await _repo.resolve(alert.id);
      if (!mounted) return;
      _stopPulse();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).childSosInProgressResolvedToast,
          ),
        ),
      );
      if (widget.onResolved != null) {
        widget.onResolved!();
        return;
      }
      context.go('/scr-chd-004');
    } on Object {
      if (!mounted) return;
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final role = _role(context);
    final active =
        role == AppRole.child && _alert != null && _alert!.isActive;

    return FamilyUiModeScope(
      mode: FamilyUiMode.child,
      child: Scaffold(
        key: ChildSosInProgressKeys.screen,
        backgroundColor: active ? colors.coral : colors.bg,
        appBar: active
            ? null
            : AppBar(
                backgroundColor: colors.surface,
                foregroundColor: colors.ink,
                title: Text(l10n.childSosInProgressHeadline),
              ),
        body: SafeArea(child: _buildBody(l10n, colors, role)),
      ),
    );
  }

  Widget _buildBody(
    AppLocalizations l10n,
    FamilyColors colors,
    AppRole role,
  ) {
    if (role != AppRole.child) {
      return AppEmptyState(
        key: ChildSosInProgressKeys.parentLean,
        title: l10n.childSosInProgressParentLeanTitle,
        message: l10n.childSosInProgressParentLeanMessage,
      );
    }

    if (_loading) {
      return const Center(
        key: ChildSosInProgressKeys.loading,
        child: CircularProgressIndicator(),
      );
    }

    if (_loadFailed) {
      return AppErrorState(
        key: ChildSosInProgressKeys.error,
        kind: AppErrorKind.network,
        title: l10n.childSosInProgressErrorTitle,
        message: l10n.childSosInProgressErrorMessage,
      );
    }

    final alert = _alert;
    if (alert == null || !alert.isActive) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppEmptyState(
                key: ChildSosInProgressKeys.empty,
                title: l10n.childSosInProgressEmptyTitle,
                message: l10n.childSosInProgressEmptyMessage,
              ),
              const SizedBox(height: 12),
              Semantics(
                button: true,
                label: l10n.childSosInProgressOpenButtonSemantics,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: FilledButton(
                    key: ChildSosInProgressKeys.openButtonCta,
                    onPressed: _openSosButton,
                    child: Text(l10n.childSosInProgressOpenButtonCta),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _InProgressBody(
      l10n: l10n,
      colors: colors,
      pulse: _pulse,
      busy: _busy,
      onCallFather: _callFather,
      onCancel: () => _openCancelSheet(l10n, colors.coral),
    );
  }
}

class _InProgressBody extends StatelessWidget {
  const _InProgressBody({
    required this.l10n,
    required this.colors,
    required this.pulse,
    required this.busy,
    required this.onCallFather,
    required this.onCancel,
  });

  final AppLocalizations l10n;
  final FamilyColors colors;
  final AnimationController pulse;
  final bool busy;
  final VoidCallback onCallFather;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final deepCoral = Color.lerp(colors.coral, colors.ink, 0.18)!;
    final onCoral = colors.surface;

    return DecoratedBox(
      key: ChildSosInProgressKeys.body,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colors.coral, deepCoral],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 30, 18, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DecoratedBox(
              key: ChildSosInProgressKeys.p4Banner,
              decoration: BoxDecoration(
                color: onCoral.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Text(
                  l10n.childSosInProgressP4Banner,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: onCoral,
                    height: 1.4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            ScaleTransition(
              scale: Tween<double>(begin: 1, end: 1.08).animate(pulse),
              child: const Text(
                '📡',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 50),
              ),
            ),
            const SizedBox(height: 10),
            Semantics(
              header: true,
              liveRegion: true,
              label: l10n.childSosInProgressHeadline,
              child: Text(
                key: ChildSosInProgressKeys.headline,
                l10n.childSosInProgressHeadline,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: onCoral,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              key: ChildSosInProgressKeys.broadcast,
              l10n.childSosInProgressBroadcast,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: onCoral.withValues(alpha: 0.92),
              ),
            ),
            const SizedBox(height: 20),
            Semantics(
              label: l10n.childSosInProgressBroadcastSemantics,
              child: DecoratedBox(
                key: ChildSosInProgressKeys.statusCard,
                decoration: BoxDecoration(
                  color: onCoral.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.childSosInProgressFatherSeen,
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: onCoral,
                          height: 2,
                        ),
                      ),
                      Text(
                        l10n.childSosInProgressMotherSeen,
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: onCoral,
                          height: 2,
                        ),
                      ),
                      Text(
                        l10n.childSosInProgressBackupStandby,
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: onCoral,
                          height: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            _ChildSosAction(
              key: ChildSosInProgressKeys.callFather,
              label: l10n.childSosInProgressCallFatherCta,
              semanticsLabel: l10n.childSosInProgressCallFatherSemantics,
              filled: true,
              coral: deepCoral,
              onCoral: onCoral,
              onPressed: busy ? null : onCallFather,
            ),
            const SizedBox(height: 10),
            _ChildSosAction(
              key: ChildSosInProgressKeys.cancelCta,
              label: l10n.childSosInProgressCancelCta,
              semanticsLabel: l10n.childSosInProgressCancelSemantics,
              filled: false,
              coral: deepCoral,
              onCoral: onCoral,
              onPressed: busy ? null : onCancel,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChildSosAction extends StatelessWidget {
  const _ChildSosAction({
    super.key,
    required this.label,
    required this.semanticsLabel,
    required this.filled,
    required this.coral,
    required this.onCoral,
    required this.onPressed,
  });

  final String label;
  final String semanticsLabel;
  final bool filled;
  final Color coral;
  final Color onCoral;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticsLabel,
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(14),
            child: Ink(
              decoration: BoxDecoration(
                color: filled
                    ? onCoral
                    : onCoral.withValues(alpha: enabled ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: filled ? coral : onCoral,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
