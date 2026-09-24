import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/family_ui_mode.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/sos_alert_repository.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/core/policy/sos_settings.dart';
import 'package:family_os/core/sos_final/sos_final.dart';

/// Widget keys for SCR-CHD-005 acceptance.
abstract final class ChildSosButtonKeys {
  static const screen = Key('child_sos_button_screen');
  static const holdButton = Key('child_sos_hold_button');
  static const statusMessage = Key('child_sos_status_message');
  static const alwaysOnBanner = Key('child_sos_always_on_banner');
  static const parentLean = Key('child_sos_parent_lean');
}

/// Hold duration before SOS fires (prototype CHD-005 · ~٣ ثوانٍ).
const Duration kChildSosHoldDuration = Duration(seconds: 3);

/// Tick used for countdown UI (1s steps → ٣ · ٢ · ١).
const Duration kChildSosHoldTick = Duration(seconds: 1);

/// SCR-CHD-005 — زر الاستغاثة (bare child, mock-first).
///
/// Prototype CHD-005: long-press ٣ ثوانٍ → fire → CHD-006.
/// P-4: always available — no entitlement / network / time-cap gate.
/// Rule 23: parametric [childId]; no planted person name.
class ChildSosButtonScreen extends StatefulWidget {
  const ChildSosButtonScreen({
    super.key,
    this.childId = 'child_local',
    this.roleOverride,
    this.sosFire,
    this.alerts,
    this.holdDuration = kChildSosHoldDuration,
    this.holdTick = kChildSosHoldTick,
    this.onFired,
  });

  /// Parametric child id for [SosFireService.fire] (Rule 23).
  final String childId;

  /// Test seam — when set, ignores [CurrentRole].
  final AppRole? roleOverride;

  /// P-4 SOS seam — null → [stage1SosFireService].
  final SosFireService? sosFire;

  /// Alert store for CHD-006 handoff — null → sos_final Domain fire (Slice 01).
  /// Inject [InMemorySosAlertRepository] in tests with [fireAndSeedSosAlert].
  final InMemorySosAlertRepository? alerts;

  /// Test seam — shorter hold in widget tests.
  final Duration holdDuration;

  /// Test seam — countdown step.
  final Duration holdTick;

  /// Test seam — when null, navigates to `/scr-chd-006?alertId=&childId=` after fire.
  final VoidCallback? onFired;

  @override
  State<ChildSosButtonScreen> createState() => _ChildSosButtonScreenState();
}

class _ChildSosButtonScreenState extends State<ChildSosButtonScreen>
    with SingleTickerProviderStateMixin {
  Timer? _holdTimer;
  Timer? _tickTimer;
  int _secondsLeft = 0;
  bool _holding = false;
  bool _cancelledEarly = false;
  bool _firing = false;
  bool _holdCompleted = false;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _cancelHoldTimers();
    _pulse.dispose();
    super.dispose();
  }

  AppRole _role(BuildContext context) =>
      widget.roleOverride ??
      CurrentRole.maybeNotifierOf(context)?.value ??
      AppRole.child;

  void _cancelHoldTimers() {
    _holdTimer?.cancel();
    _holdTimer = null;
    _tickTimer?.cancel();
    _tickTimer = null;
  }

  void _onPointerDown() {
    if (_firing || _holdCompleted) return;
    final tickMs = widget.holdTick.inMilliseconds.clamp(1, 60000);
    final totalSeconds = widget.holdDuration.inMilliseconds <= 0
        ? 1
        : (widget.holdDuration.inMilliseconds / tickMs).ceil().clamp(1, 99);
    setState(() {
      _holding = true;
      _cancelledEarly = false;
      _holdCompleted = false;
      _secondsLeft = totalSeconds;
    });
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (!reduceMotion) {
      _pulse.repeat(reverse: true);
    }
    _tickTimer = Timer.periodic(widget.holdTick, (_) {
      if (!mounted || !_holding) return;
      setState(() {
        if (_secondsLeft > 1) {
          _secondsLeft -= 1;
        }
      });
    });
    _holdTimer = Timer(widget.holdDuration, _completeHold);
  }

  void _stopPulse() {
    if (_pulse.isAnimating) {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  void _onPointerUpOrCancel() {
    if (_firing || _holdCompleted) return;
    if (!_holding) return;
    _cancelHoldTimers();
    _stopPulse();
    if (mounted) {
      setState(() {
        _holding = false;
        _cancelledEarly = true;
        _secondsLeft = 0;
      });
    }
  }

  Future<void> _completeHold() async {
    _cancelHoldTimers();
    _stopPulse();
    if (!mounted || _holdCompleted) return;
    setState(() {
      _holding = false;
      _holdCompleted = true;
      _firing = true;
      _secondsLeft = 0;
    });
    final fire = widget.sosFire ?? stage1SosFireService;
    final injected = widget.alerts;
    late final String? alertId;
    if (injected != null) {
      await fireAndSeedSosAlert(
        childId: widget.childId,
        sosFire: fire,
        alerts: injected,
        settings: stage1SosSettingsStore,
      );
      if (!mounted) return;
      if (widget.onFired != null) {
        widget.onFired!();
        return;
      }
      final seeded = await injected.loadActive();
      alertId = seeded?.id;
    } else {
      // Production: durable sos_final lifecycle (AUTH-FS006).
      await Stage1SosFinalRuntime.ensureOpen();
      final panicQuiet =
          stage1SosSettingsStore.settings.panicQuietPreferred;
      final incident = await Stage1SosFinalRuntime.crossSystem.fireChildHold(
        childId: ChildId(widget.childId),
        deviceId: const DeviceId('dev_stage1'),
        panicQuietAtTrigger: panicQuiet,
      );
      // Keep fire service audit path for P-4 parity (no entitlement).
      await fire.fire(childId: widget.childId);
      alertId = incident.id;
      if (!mounted) return;
      if (widget.onFired != null) {
        widget.onFired!();
        return;
      }
    }
    if (!mounted) return;
    final params = <String, String>{
      'childId': widget.childId,
      if (alertId != null) 'alertId': alertId,
    };
    context.go(
      Uri(path: '/scr-chd-006', queryParameters: params).toString(),
    );
  }

  String _statusText(AppLocalizations l10n) {
    if (_firing) return l10n.childSosStatusFiring;
    if (_holding) {
      return l10n.childSosStatusHolding(_secondsLeft);
    }
    if (_cancelledEarly) return l10n.childSosStatusCancelled;
    return l10n.childSosStatusIdle;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final gradients = Theme.of(context).extension<FamilyGradients>()!;
    final shadows = Theme.of(context).extension<FamilyShadows>()!;
    final role = _role(context);

    return FamilyUiModeScope(
      mode: FamilyUiMode.child,
      child: Scaffold(
        key: ChildSosButtonKeys.screen,
        backgroundColor: colors.bg,
        appBar: AppBar(
          backgroundColor: colors.surface,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.childSosTitle,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: colors.ink,
                ),
              ),
              Text(
                l10n.childSosSubtitle,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: colors.ink2,
                ),
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: role == AppRole.child
              ? ListView(
                  padding: const EdgeInsets.fromLTRB(18, 26, 18, 24),
                  children: [
                    Text(
                      l10n.childSosHint,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colors.ink2,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Semantics(
                        button: true,
                        label: l10n.childSosHoldSemantics,
                        child: Listener(
                          onPointerDown: (_) => _onPointerDown(),
                          onPointerUp: (_) => _onPointerUpOrCancel(),
                          onPointerCancel: (_) => _onPointerUpOrCancel(),
                          child: ScaleTransition(
                            scale: Tween<double>(
                              begin: 1,
                              end: 1.04,
                            ).animate(_pulse),
                            child: Container(
                              key: ChildSosButtonKeys.holdButton,
                              width: 190,
                              height: 190,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: gradients.gradCoral,
                                border: Border.all(
                                  color: const Color(0xFFFFD3D4),
                                  width: 10,
                                ),
                                boxShadow: [shadows.shCoral],
                              ),
                              child: Text(
                                l10n.childSosHoldLabel,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  height: 1.25,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      key: ChildSosButtonKeys.statusMessage,
                      _statusText(l10n),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: colors.ink2,
                      ),
                    ),
                    const SizedBox(height: 18),
                    BannerNote(
                      key: ChildSosButtonKeys.alwaysOnBanner,
                      message: l10n.childSosAlwaysOnBanner,
                      variant: BannerVariant.t,
                    ),
                  ],
                )
              : AppEmptyState(
                  key: ChildSosButtonKeys.parentLean,
                  title: l10n.childSosParentLeanTitle,
                  message: l10n.childSosParentLeanMessage,
                ),
        ),
      ),
    );
  }
}
