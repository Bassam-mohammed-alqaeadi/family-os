import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/app/role_guard.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/features/n05_lock/child_mode_lock_service.dart';

/// Widget keys for SCR-CHD-011 acceptance.
abstract final class ChildModeLockKeys {
  static const screen = Key('child_mode_lock_screen');
  static const dualKeyBanner = Key('child_mode_lock_dual_key_banner');
  static const secretStep = Key('child_mode_lock_secret_step');
  static const logoHold = Key('child_mode_lock_logo_hold');
  static const secretOpened = Key('child_mode_lock_secret_opened');
  static const passwordStep = Key('child_mode_lock_password_step');
  static const passwordField = Key('child_mode_lock_password_field');
  static const verifyCta = Key('child_mode_lock_verify_cta');
  static const awaitingBanner = Key('child_mode_lock_awaiting_banner');
  static const viewFatherCta = Key('child_mode_lock_view_father_cta');
  static const attemptsBanner = Key('child_mode_lock_attempts_banner');
  static const lockoutBanner = Key('child_mode_lock_lockout_banner');
  static const entertainmentLocked = Key('child_mode_lock_entertainment_locked');
  static const sosCta = Key('child_mode_lock_sos_cta');
  static const sosIconCta = Key('child_mode_lock_sos_icon_cta');
  static const parentLean = Key('child_mode_lock_parent_lean');
}

/// Secret-entry hold (prototype CHD-011 · ١٠ ثوانٍ on the logo).
const Duration kChildModeLockSecretHoldDuration = Duration(seconds: 10);

/// Tick used for hold countdown UI.
const Duration kChildModeLockSecretHoldTick = Duration(seconds: 1);

/// SCR-CHD-011 — قفل وضع الابن + المدخل السري.
///
/// Prototype CHD-011 · ADR-017 triple-lock: secret hold → account password
/// (not PIN / MDM) → awaiting second key (FAT-030). P-4 SOS always reachable;
/// entertainment stays locked. RoleGuard lean for parent. Rule 12/23.
class ChildModeLockScreen extends StatefulWidget {
  const ChildModeLockScreen({
    super.key,
    this.lockService,
    this.sosFire,
    this.roleOverride,
    this.childId = 'child_local',
    this.secretHoldDuration = kChildModeLockSecretHoldDuration,
    this.secretHoldTick = kChildModeLockSecretHoldTick,
    this.onSos,
    this.onViewFatherRequest,
  });

  /// Rule 25 seam — null → [stage1ChildModeLockService].
  final ChildModeLockService? lockService;

  /// P-4 SOS seam — null → [stage1SosFireService].
  final SosFireService? sosFire;

  /// Test seam — when set, ignores [CurrentRole].
  final AppRole? roleOverride;

  /// Parametric child id for SOS fire (Rule 23).
  final String childId;

  /// Test seam — shorter secret hold in widget tests.
  final Duration secretHoldDuration;

  /// Test seam — countdown step.
  final Duration secretHoldTick;

  /// Test seam — when null, navigates to `/scr-chd-005`.
  final VoidCallback? onSos;

  /// Test seam — when null, navigates to `/scr-fat-030` (second key).
  final VoidCallback? onViewFatherRequest;

  @override
  State<ChildModeLockScreen> createState() => _ChildModeLockScreenState();
}

class _ChildModeLockScreenState extends State<ChildModeLockScreen> {
  late final ChildModeLockService _lock;
  final _passwordController = TextEditingController();
  Timer? _holdTimer;
  Timer? _tickTimer;
  var _holding = false;
  var _holdSecondsLeft = 0;
  var _sosBusy = false;
  var _verifying = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _lock = widget.lockService ?? stage1ChildModeLockService;
    _lock.addListener(_onLockChanged);
  }

  @override
  void didUpdateWidget(covariant ChildModeLockScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lockService != widget.lockService) {
      _lock.removeListener(_onLockChanged);
      _lock = widget.lockService ?? stage1ChildModeLockService;
      _lock.addListener(_onLockChanged);
    }
  }

  @override
  void dispose() {
    _cancelHold();
    _lock.removeListener(_onLockChanged);
    _passwordController.dispose();
    super.dispose();
  }

  void _onLockChanged() {
    if (mounted) setState(() {});
  }

  AppRole get _role =>
      widget.roleOverride ??
      CurrentRole.maybeNotifierOf(context)?.value ??
      AppRole.child;

  bool get _isChild => _role == AppRole.child;

  void _cancelHold() {
    _holdTimer?.cancel();
    _holdTimer = null;
    _tickTimer?.cancel();
    _tickTimer = null;
  }

  void _onLogoPointerDown() {
    if (_lock.isLockedOut || _lock.secretEntryOpen || _holding) return;
    final tickMs = widget.secretHoldTick.inMilliseconds.clamp(1, 60000);
    final totalSeconds = widget.secretHoldDuration.inMilliseconds <= 0
        ? 1
        : (widget.secretHoldDuration.inMilliseconds / tickMs).ceil().clamp(1, 99);
    setState(() {
      _holding = true;
      _holdSecondsLeft = totalSeconds;
      _statusMessage = null;
    });
    _tickTimer = Timer.periodic(widget.secretHoldTick, (_) {
      if (!mounted) return;
      setState(() {
        _holdSecondsLeft = (_holdSecondsLeft - 1).clamp(0, 99);
      });
    });
    _holdTimer = Timer(widget.secretHoldDuration, _completeSecretHold);
  }

  void _onLogoPointerUp() {
    if (!_holding) return;
    if (_lock.secretEntryOpen) return;
    _cancelHold();
    setState(() {
      _holding = false;
      _holdSecondsLeft = 0;
      _statusMessage = null;
    });
  }

  void _completeSecretHold() {
    _cancelHold();
    if (!mounted) return;
    _lock.openSecretEntry();
    setState(() {
      _holding = false;
      _holdSecondsLeft = 0;
    });
  }

  Future<void> _verifyPassword() async {
    if (_verifying || _lock.isLockedOut || !_lock.secretEntryOpen) return;
    setState(() => _verifying = true);
    final result = _lock.verifyAccountPassword(_passwordController.text);
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _verifying = false;
      switch (result.outcome) {
        case ChildModeUnlockOutcome.failed:
          _passwordController.clear();
          _statusMessage = l10n.childModeLockPasswordFailed(
            result.failedAttempts,
            kChildModeLockMaxFailedAttempts,
          );
        case ChildModeUnlockOutcome.lockout:
          _passwordController.clear();
          _statusMessage = null;
        case ChildModeUnlockOutcome.awaitingSecondKey:
          _passwordController.clear();
          _statusMessage = null;
      }
    });
    if (!mounted) return;
    if (result.outcome == ChildModeUnlockOutcome.awaitingSecondKey) {
      AppToast.show(context, message: l10n.childModeLockRequestSentToast);
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
    await fire.fire(childId: widget.childId);
    if (!mounted) return;
    setState(() => _sosBusy = false);
    context.go(screenPath('SCR-CHD-005'));
  }

  void _viewFatherRequest() {
    if (widget.onViewFatherRequest != null) {
      widget.onViewFatherRequest!();
      return;
    }
    context.go(screenPath('SCR-FAT-030'));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;

    return Scaffold(
      key: ChildModeLockKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.ink,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.childModeLockTitle,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: colors.ink,
              ),
            ),
            Text(
              l10n.childModeLockSubtitle,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.ink2,
              ),
            ),
          ],
        ),
        actions: [
          // P-4 — SOS never gated by lock / lockout / entertainment.
          IconButton(
            key: ChildModeLockKeys.sosIconCta,
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
      body: SafeArea(
        child: !_isChild
            ? AppEmptyState(
                key: ChildModeLockKeys.parentLean,
                title: l10n.childModeLockParentLeanTitle,
                message: l10n.childModeLockParentLeanMessage,
              )
            : _buildChildBody(context, l10n, colors),
      ),
    );
  }

  Widget _buildChildBody(
    BuildContext context,
    AppLocalizations l10n,
    FamilyColors colors,
  ) {
    final awaiting = _lock.pendingRequest != null &&
        !(_lock.pendingRequest?.isApproved ?? false);
    final radii = Theme.of(context).extension<FamilyRadii>()!;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        BannerNote(
          key: ChildModeLockKeys.dualKeyBanner,
          variant: BannerVariant.t,
          message: l10n.childModeLockDualKeyBanner,
        ),
        const SizedBox(height: 12),
        if (_lock.isLockedOut) ...[
          BannerNote(
            key: ChildModeLockKeys.lockoutBanner,
            variant: BannerVariant.a,
            message: l10n.childModeLockLockoutBanner,
          ),
          const SizedBox(height: 12),
        ],
        _SecretEntryCard(
          colors: colors,
          radii: radii,
          l10n: l10n,
          lockedOut: _lock.isLockedOut,
          secretOpen: _lock.secretEntryOpen,
          holding: _holding,
          holdSecondsLeft: _holdSecondsLeft,
          onPointerDown: _onLogoPointerDown,
          onPointerUp: _onLogoPointerUp,
          onPointerCancel: _onLogoPointerUp,
        ),
        if (_lock.secretEntryOpen && !_lock.isLockedOut) ...[
          const SizedBox(height: 12),
          _PasswordStepCard(
            colors: colors,
            radii: radii,
            l10n: l10n,
            controller: _passwordController,
            verifying: _verifying,
            statusMessage: _statusMessage,
            onVerify: (awaiting || _verifying) ? null : _verifyPassword,
          ),
        ],
        if (awaiting) ...[
          const SizedBox(height: 12),
          BannerNote(
            key: ChildModeLockKeys.awaitingBanner,
            variant: BannerVariant.p,
            message: l10n.childModeLockAwaitingBanner,
          ),
          const SizedBox(height: 10),
          PrimaryBtn(
            key: ChildModeLockKeys.viewFatherCta,
            label: l10n.childModeLockViewFatherCta,
            variant: PrimaryBtnVariant.sec,
            onPressed: _viewFatherRequest,
            semanticsLabel: l10n.childModeLockViewFatherSemantics,
          ),
        ],
        const SizedBox(height: 12),
        BannerNote(
          key: ChildModeLockKeys.attemptsBanner,
          variant: BannerVariant.a,
          message: l10n.childModeLockAttemptsWarning,
        ),
        const SizedBox(height: 16),
        DecoratedBox(
          key: ChildModeLockKeys.entertainmentLocked,
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(radii.card),
            border: Border.all(color: colors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(Icons.lock_outline, color: colors.ink2),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.childModeLockEntertainmentLocked,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: colors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        PrimaryBtn(
          key: ChildModeLockKeys.sosCta,
          label: l10n.childModeLockSosCta,
          variant: PrimaryBtnVariant.coral,
          onPressed: _sosBusy ? null : _openSos,
          semanticsLabel: l10n.spineCtaSosSemantics,
        ),
        ],
      ),
    );
  }
}

class _SecretEntryCard extends StatelessWidget {
  const _SecretEntryCard({
    required this.colors,
    required this.radii,
    required this.l10n,
    required this.lockedOut,
    required this.secretOpen,
    required this.holding,
    required this.holdSecondsLeft,
    required this.onPointerDown,
    required this.onPointerUp,
    required this.onPointerCancel,
  });

  final FamilyColors colors;
  final FamilyRadii radii;
  final AppLocalizations l10n;
  final bool lockedOut;
  final bool secretOpen;
  final bool holding;
  final int holdSecondsLeft;
  final VoidCallback onPointerDown;
  final VoidCallback onPointerUp;
  final VoidCallback onPointerCancel;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: ChildModeLockKeys.secretStep,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radii.card),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.childModeLockSecretStepTitle,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.childModeLockSecretStepHint,
              style: TextStyle(
                fontSize: 13,
                color: colors.ink2,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: Listener(
                onPointerDown:
                    lockedOut || secretOpen ? null : (_) => onPointerDown(),
                onPointerUp: lockedOut || secretOpen ? null : (_) => onPointerUp(),
                onPointerCancel:
                    lockedOut || secretOpen ? null : (_) => onPointerCancel(),
                child: Semantics(
                  key: ChildModeLockKeys.logoHold,
                  button: true,
                  enabled: !lockedOut && !secretOpen,
                  label: l10n.childModeLockLogoHoldSemantics,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 88,
                    height: 88,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: holding ? colors.teal100 : colors.p50,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: holding ? colors.tealDeep : colors.p400,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      holding ? '$holdSecondsLeft' : '🦁',
                      style: TextStyle(
                        fontSize: holding ? 28 : 40,
                        fontWeight: FontWeight.w800,
                        color: colors.ink,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (secretOpen) ...[
              const SizedBox(height: 10),
              Text(
                key: ChildModeLockKeys.secretOpened,
                l10n.childModeLockSecretOpened,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: colors.tealDeep,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PasswordStepCard extends StatelessWidget {
  const _PasswordStepCard({
    required this.colors,
    required this.radii,
    required this.l10n,
    required this.controller,
    required this.verifying,
    required this.statusMessage,
    required this.onVerify,
  });

  final FamilyColors colors;
  final FamilyRadii radii;
  final AppLocalizations l10n;
  final TextEditingController controller;
  final bool verifying;
  final String? statusMessage;
  final VoidCallback? onVerify;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: ChildModeLockKeys.passwordStep,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radii.card),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.childModeLockPasswordStepTitle,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.childModeLockPasswordStepHint,
              style: TextStyle(
                fontSize: 13,
                color: colors.ink2,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: ChildModeLockKeys.passwordField,
              controller: controller,
              obscureText: true,
              enabled: onVerify != null,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onVerify?.call(),
              decoration: InputDecoration(
                labelText: l10n.childModeLockPasswordLabel,
                hintText: l10n.childModeLockPasswordHint,
              ),
            ),
            if (statusMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                statusMessage!,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: colors.coral,
                ),
              ),
            ],
            const SizedBox(height: 12),
            PrimaryBtn(
              key: ChildModeLockKeys.verifyCta,
              label: verifying
                  ? l10n.childModeLockVerifying
                  : l10n.childModeLockVerifyCta,
              onPressed: verifying ? null : onVerify,
              semanticsLabel: l10n.childModeLockVerifySemantics,
            ),
          ],
        ),
      ),
    );
  }
}
