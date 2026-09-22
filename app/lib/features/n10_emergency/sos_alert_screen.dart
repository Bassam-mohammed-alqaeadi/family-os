import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/app_error_state.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/sos_alert.dart';
import 'package:family_os/core/policy/sos_alert_repository.dart';
import 'package:family_os/core/policy/sos_fire.dart';

/// Widget keys for SCR-FAT-018 acceptance.
abstract final class SosAlertKeys {
  static const screen = Key('sos_alert_screen');
  static const loading = Key('sos_alert_loading');
  static const empty = Key('sos_alert_empty');
  static const error = Key('sos_alert_error');
  static const body = Key('sos_alert_body');
  static const sirenBanner = Key('sos_alert_siren_banner');
  static const headline = Key('sos_alert_headline');
  static const liveNote = Key('sos_alert_live_note');
  static const map = Key('sos_alert_map');
  static const pin = Key('sos_alert_pin');
  static const metaCard = Key('sos_alert_meta');
  static const callNow = Key('sos_alert_call_now');
  static const liveMap = Key('sos_alert_live_map');
  static const resolve = Key('sos_alert_resolve');
  static const escalate = Key('sos_alert_escalate');
  static const recipients = Key('sos_alert_recipients');
  static const autoCallNote = Key('sos_alert_auto_call');
  static const childLean = Key('sos_alert_child_lean');
  static const p4Banner = Key('sos_alert_p4_banner');
  static const setupCta = Key('sos_alert_setup_cta');
}

/// SCR-FAT-018 — بلاغ استغاثة (parent active SOS alert board).
///
/// Coral full-bleed board: piercing-siren copy, live map (S-SEC-027),
/// auto-call after [autoCallDelay] (S-SEC-028), call / map / resolve /
/// escalate CTAs, recipients footer (SET-020 ladder). Mother **any**
/// [MotherLevel] (including observer) can act — SOS is ungraded (SET-021 / P-4).
/// RoleGuard lean for child. Entitlement never gates this surface (UI-007).
/// Mock-first — no Firebase / no real GPS or dialer.
class SosAlertScreen extends StatefulWidget {
  const SosAlertScreen({
    super.key,
    this.alertId,
    this.childId,
    this.repository,
    this.roleOverride,
    this.motherLevel = MotherLevel.partner,
    this.sosFire,
    this.autoCallDelay = const Duration(seconds: 5),
    this.onCallNow,
    this.onOpenLiveMap,
    this.onResolved,
    this.onEscalate,
    this.onOpenSetup,
  });

  /// Optional deep-link `?alertId=`.
  final String? alertId;

  /// Optional `?childId=` forwarded to live map.
  final String? childId;

  /// Null → [stage1SosAlertRepository].
  final SosAlertRepository? repository;

  /// Test seam — when set, ignores [CurrentRole].
  final AppRole? roleOverride;

  /// Mother authority — observer still receives + acts on SOS (P-4 / SET-021).
  final MotherLevel motherLevel;

  /// P-4 SOS seam — retained for parity with sibling screens (unused for fire).
  final SosFireService? sosFire;

  /// S-SEC-028 auto-call delay — shorten in widget tests.
  final Duration autoCallDelay;

  final VoidCallback? onCallNow;
  final void Function(String childId)? onOpenLiveMap;
  final VoidCallback? onResolved;
  final VoidCallback? onEscalate;
  final VoidCallback? onOpenSetup;

  @override
  SosAlertScreenState createState() => SosAlertScreenState();
}

class SosAlertScreenState extends State<SosAlertScreen> {
  late final SosAlertRepository _repo;
  var _loading = true;
  var _loadFailed = false;
  var _busy = false;
  var _autoCallFired = false;
  SosAlert? _alert;
  Timer? _autoCallTimer;

  AppRole get _role =>
      widget.roleOverride ??
      CurrentRole.maybeNotifierOf(context)?.value ??
      AppRole.father;

  bool get _isParent => _role == AppRole.father || _role == AppRole.mother;

  String? get _resolvedAlertId {
    final raw = widget.alertId?.trim();
    if (raw == null || raw.isEmpty) return null;
    return raw;
  }

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? stage1SosAlertRepository;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
    });
  }

  @override
  void didUpdateWidget(covariant SosAlertScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.alertId != widget.alertId ||
        oldWidget.repository != widget.repository) {
      _load();
    }
  }

  @override
  void dispose() {
    _autoCallTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    _autoCallTimer?.cancel();
    setState(() {
      _loading = true;
      _loadFailed = false;
      _autoCallFired = false;
    });
    try {
      final alert = await _repo.loadActive(alertId: _resolvedAlertId);
      if (!mounted) return;
      setState(() {
        _alert = alert;
        _loading = false;
        _loadFailed = false;
      });
      if (alert != null && alert.isActive && _isParent) {
        _armAutoCall();
      }
    } on Object {
      if (!mounted) return;
      setState(() {
        _alert = null;
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  void _armAutoCall() {
    _autoCallTimer?.cancel();
    if (widget.autoCallDelay <= Duration.zero) {
      _fireAutoCall();
      return;
    }
    _autoCallTimer = Timer(widget.autoCallDelay, _fireAutoCall);
  }

  void _fireAutoCall() {
    if (!mounted || _autoCallFired || _alert == null || !_alert!.isActive) {
      return;
    }
    setState(() => _autoCallFired = true);
    _callNow(fromAuto: true);
  }

  void _callNow({bool fromAuto = false}) {
    if (widget.onCallNow != null) {
      widget.onCallNow!();
      return;
    }
    // Stage-1: emergency call surface still placeholder — stay on board.
    if (!fromAuto && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).sosAlertCallStartedToast),
        ),
      );
    }
  }

  void _openLiveMap() {
    final id = widget.childId?.trim().isNotEmpty == true
        ? widget.childId!.trim()
        : _alert?.childId;
    if (widget.onOpenLiveMap != null) {
      widget.onOpenLiveMap!(id ?? '');
      return;
    }
    final path = id == null || id.isEmpty
        ? '/scr-fat-014'
        : '/scr-fat-014?childId=${Uri.encodeComponent(id)}';
    context.push(path);
  }

  Future<void> _resolve() async {
    final alert = _alert;
    if (alert == null || _busy) return;
    setState(() => _busy = true);
    _autoCallTimer?.cancel();
    try {
      await _repo.resolve(alert.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).sosAlertResolvedToast),
        ),
      );
      if (widget.onResolved != null) {
        widget.onResolved!();
        return;
      }
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/scr-fat-010');
      }
    } on Object {
      if (!mounted) return;
      setState(() => _busy = false);
    }
  }

  Future<void> _escalate() async {
    final alert = _alert;
    if (alert == null || _busy) return;
    setState(() => _busy = true);
    try {
      await _repo.escalateEmergencyContacts(alert.id);
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).sosAlertEscalatedToast),
        ),
      );
      widget.onEscalate?.call();
    } on Object {
      if (!mounted) return;
      setState(() => _busy = false);
    }
  }

  void _openSetup() {
    if (widget.onOpenSetup != null) {
      widget.onOpenSetup!();
      return;
    }
    context.push('/scr-fat-028');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;

    return Scaffold(
      key: SosAlertKeys.screen,
      backgroundColor: _isParent && _alert != null && _alert!.isActive
          ? colors.coral
          : colors.bg,
      appBar: _isParent && _alert != null && _alert!.isActive
          ? null
          : AppBar(
              backgroundColor: colors.surface,
              foregroundColor: colors.ink,
              title: Text(l10n.sosAlertTitle),
            ),
      body: SafeArea(child: _buildBody(l10n, colors)),
    );
  }

  Widget _buildBody(
    AppLocalizations l10n,
    FamilyColors colors,
  ) {
    if (!_isParent) {
      return AppEmptyState(
        key: SosAlertKeys.childLean,
        title: l10n.sosAlertChildLeanTitle,
        message: l10n.sosAlertChildLeanMessage,
      );
    }

    if (_loading) {
      return const Center(
        key: SosAlertKeys.loading,
        child: CircularProgressIndicator(),
      );
    }

    if (_loadFailed) {
      return AppErrorState(
        key: SosAlertKeys.error,
        kind: AppErrorKind.network,
        title: l10n.sosAlertErrorTitle,
        message: l10n.sosAlertErrorMessage,
        onRetry: _load,
      );
    }

    final alert = _alert;
    if (alert == null || !alert.isActive) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: AppEmptyState(
                key: SosAlertKeys.empty,
                title: l10n.sosAlertEmptyTitle,
                message: l10n.sosAlertEmptyMessage,
              ),
            ),
            Semantics(
              button: true,
              label: l10n.sosAlertSetupSemantics,
              child: TextButton(
                key: SosAlertKeys.setupCta,
                onPressed: _openSetup,
                child: Text(l10n.sosAlertSetupCta),
              ),
            ),
          ],
        ),
      );
    }

    return _ActiveBoard(
      alert: alert,
      l10n: l10n,
      colors: colors,
      autoCallFired: _autoCallFired,
      busy: _busy,
      onCallNow: () => _callNow(),
      onLiveMap: _openLiveMap,
      onResolve: _resolve,
      onEscalate: _escalate,
    );
  }
}

class _ActiveBoard extends StatelessWidget {
  const _ActiveBoard({
    required this.alert,
    required this.l10n,
    required this.colors,
    required this.autoCallFired,
    required this.busy,
    required this.onCallNow,
    required this.onLiveMap,
    required this.onResolve,
    required this.onEscalate,
  });

  final SosAlert alert;
  final AppLocalizations l10n;
  final FamilyColors colors;
  final bool autoCallFired;
  final bool busy;
  final VoidCallback onCallNow;
  final VoidCallback onLiveMap;
  final VoidCallback onResolve;
  final VoidCallback onEscalate;

  @override
  Widget build(BuildContext context) {
    final deepCoral = Color.lerp(colors.coral, colors.ink, 0.22)!;
    final onCoral = colors.surface;

    return DecoratedBox(
      key: SosAlertKeys.body,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colors.coral, deepCoral],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 26, 18, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DecoratedBox(
              key: SosAlertKeys.p4Banner,
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
                  l10n.sosAlertP4NeverGated,
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
            const SizedBox(height: 10),
            Semantics(
              header: true,
              liveRegion: true,
              label: l10n.sosAlertHeadline(alert.childDisplayName),
              child: Column(
                children: [
                  Text(
                    alert.childEmoji,
                    style: const TextStyle(fontSize: 46),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    key: SosAlertKeys.headline,
                    l10n.sosAlertHeadline(alert.childDisplayName),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: onCoral,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              key: SosAlertKeys.sirenBanner,
              l10n.sosAlertSirenBanner,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: onCoral.withValues(alpha: 0.92),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              key: SosAlertKeys.liveNote,
              l10n.sosAlertLiveBroadcastNote,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: onCoral.withValues(alpha: 0.9),
                height: 1.4,
              ),
            ),
            if (!autoCallFired) ...[
              const SizedBox(height: 6),
              Text(
                key: SosAlertKeys.autoCallNote,
                l10n.sosAlertAutoCallPending,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: onCoral.withValues(alpha: 0.88),
                ),
              ),
            ],
            const SizedBox(height: 16),
            _LiveMap(
              alert: alert,
              l10n: l10n,
              colors: colors,
            ),
            const SizedBox(height: 14),
            DecoratedBox(
              key: SosAlertKeys.metaCard,
              decoration: BoxDecoration(
                color: onCoral.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Text(
                  l10n.sosAlertMetaLine(
                    alert.locationLabel,
                    '${alert.batteryPercent}',
                    alert.movementLabel,
                    '${alert.accuracyMeters}',
                  ),
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.8,
                    color: onCoral,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _CoralAction(
              key: SosAlertKeys.callNow,
              label: l10n.sosAlertCallNowCta(alert.childDisplayName),
              semanticsLabel: l10n.sosAlertCallNowSemantics,
              filled: true,
              coral: colors.coral,
              onCoral: onCoral,
              onPressed: busy ? null : onCallNow,
            ),
            const SizedBox(height: 8),
            _CoralAction(
              key: SosAlertKeys.liveMap,
              label: l10n.sosAlertLiveMapCta,
              semanticsLabel: l10n.sosAlertLiveMapSemantics,
              filled: false,
              coral: colors.coral,
              onCoral: onCoral,
              onPressed: busy ? null : onLiveMap,
            ),
            const SizedBox(height: 8),
            _CoralAction(
              key: SosAlertKeys.resolve,
              label: l10n.sosAlertResolveCta,
              semanticsLabel: l10n.sosAlertResolveSemantics,
              filled: false,
              coral: colors.coral,
              onCoral: onCoral,
              onPressed: busy ? null : onResolve,
            ),
            const SizedBox(height: 8),
            _CoralAction(
              key: SosAlertKeys.escalate,
              label: l10n.sosAlertEscalateCta,
              semanticsLabel: l10n.sosAlertEscalateSemantics,
              filled: false,
              coral: colors.coral,
              onCoral: onCoral,
              onPressed: busy ? null : onEscalate,
            ),
            const SizedBox(height: 14),
            Text(
              key: SosAlertKeys.recipients,
              l10n.sosAlertRecipientsFooter(alert.recipientLabels.join(' · ')),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: onCoral.withValues(alpha: 0.85),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoralAction extends StatelessWidget {
  const _CoralAction({
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

class _LiveMap extends StatelessWidget {
  const _LiveMap({
    required this.alert,
    required this.l10n,
    required this.colors,
  });

  final SosAlert alert;
  final AppLocalizations l10n;
  final FamilyColors colors;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: l10n.sosAlertMapSemantics,
      child: DecoratedBox(
        key: SosAlertKeys.map,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colors.surface.withValues(alpha: 0.4),
            width: 3,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: SizedBox(
            height: 180,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final pinLeft =
                    (alert.pinFracX * constraints.maxWidth) - 22;
                final pinTop =
                    (alert.pinFracY * constraints.maxHeight) - 22;
                return Stack(
                  children: [
                    Positioned.fill(
                      child: ColoredBox(
                        color: Color.lerp(colors.bg, colors.mint100, 0.4)!,
                      ),
                    ),
                    Positioned(
                      left: 12,
                      top: 10,
                      child: _Block(
                        label: l10n.locationMapLandmarkPark,
                        fill: Color.lerp(colors.mint100, colors.mint, 0.2)!,
                      ),
                    ),
                    Positioned(
                      right: 16,
                      top: 14,
                      child: _Block(
                        label: l10n.locationMapLandmarkHome,
                        fill:
                            Color.lerp(colors.border, colors.amber100, 0.4)!,
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 78,
                      child: ColoredBox(
                        color: colors.surface,
                        child: SizedBox(
                          height: 22,
                          child: Center(
                            child: Text(
                              l10n.locationMapLandmarkStreet,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: colors.ink2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: pinLeft.clamp(4.0, constraints.maxWidth - 48),
                      top: pinTop.clamp(4.0, constraints.maxHeight - 48),
                      child: Semantics(
                        label: l10n.sosAlertPinSemantics(
                          alert.childDisplayName,
                        ),
                        child: DecoratedBox(
                          key: SosAlertKeys.pin,
                          decoration: BoxDecoration(
                            color: colors.surface,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: colors.ink.withValues(alpha: 0.18),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: SizedBox(
                            width: 44,
                            height: 44,
                            child: Center(
                              child: Text(
                                alert.childEmoji,
                                style: const TextStyle(fontSize: 22),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.label, required this.fill});

  final String label;
  final Color fill;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
