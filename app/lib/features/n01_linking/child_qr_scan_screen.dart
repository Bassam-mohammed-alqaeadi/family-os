import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/identity/child_device_management_repository.dart';
import 'package:family_os/core/identity/identity_runtime.dart';
import 'package:family_os/core/identity/identity_scope.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n01_linking/camera_permission_seam.dart';

/// Widget keys for SCR-CHD-002 / UI-003 acceptance.
abstract final class ChildQrScanKeys {
  static const scanFrame = Key('child_qr_scan_frame');
  static const repairPanel = Key('child_qr_repair_panel');
  static const openSettings = Key('child_qr_open_settings');
  static const permanentPanel = Key('child_qr_permanent_panel');
  static const manualCode = Key('child_qr_manual_code');
  static const manualSubmit = Key('child_qr_manual_submit');
  static const simulateScan = Key('child_qr_simulate_scan');
  static const manualLink = Key('child_qr_manual_link');
  static const verifying = Key('child_qr_verifying');
  static const progress = Key('child_qr_enrollment_progress');
  static const failure = Key('child_qr_enrollment_failure');
}

enum _ClaimPhase { idle, verifying, progress, failure }

/// UF-01 lean token + System #3 pairing tokens (`pair_…`).
final _tokenPattern = RegExp(
  r'^(?:pair_[A-Za-z0-9]+|[A-Za-z0-9]{8}|[A-Za-z0-9]{4}-[A-Za-z0-9]{4})$',
);

bool isValidLinkToken(String raw) {
  final cleaned = raw.trim().replaceAll(' ', '');
  return _tokenPattern.hasMatch(cleaned);
}

/// SCR-CHD-002 — مسح رمز الربط (child claims father QR token).
///
/// Camera permission is local (`device_permission`). Father QR stays valid
/// until TTL (FAT-004) — this screen never invalidates it.
/// When [managementRepository] can resolve a pending [PairingTokenId], claim
/// finalizes that enrollment (honest — never fakes success).
class ChildQrScanScreen extends StatefulWidget {
  const ChildQrScanScreen({
    super.key,
    this.permissionSeam,
    this.initialStatus,
    this.onClaimed,
    this.onOpenSettingsToast = true,
    this.claimToken,
    this.managementRepository,
  });

  /// Injectable camera permission — null → [FakeCameraPermissionSeam] granted.
  final CameraPermissionSeam? permissionSeam;

  /// Optional override used before first [CameraPermissionSeam.check].
  final CameraPermissionStatus? initialStatus;

  /// Test seam — when null, navigates to `/scr-chd-003` after successful claim.
  final VoidCallback? onClaimed;

  /// Show toast when settings deep-link is invoked (demo honesty).
  final bool onOpenSettingsToast;

  /// Optional token from route / simulated scan (`?token=`).
  final String? claimToken;

  final ChildDeviceManagementRepository? managementRepository;

  @override
  State<ChildQrScanScreen> createState() => _ChildQrScanScreenState();
}

class _ChildQrScanScreenState extends State<ChildQrScanScreen> {
  late final CameraPermissionSeam _seam;
  late final ChildDeviceManagementRepository _managementRepo;
  CameraPermissionStatus? _status;
  var _loading = true;
  final _manualController = TextEditingController();
  String? _manualError;
  _ClaimPhase _phase = _ClaimPhase.idle;
  String? _failureMessage;

  @override
  void initState() {
    super.initState();
    _managementRepo =
        widget.managementRepository ?? stage1ChildDeviceManagementRepository;
    _seam = widget.permissionSeam ?? FakeCameraPermissionSeam();
    final initial = widget.initialStatus;
    if (initial != null) {
      final seam = _seam;
      if (seam is FakeCameraPermissionSeam) {
        seam.status = initial;
      }
    }
    final seeded = widget.claimToken?.trim();
    if (seeded != null && seeded.isNotEmpty) {
      _manualController.text = seeded;
    }
    _refreshPermission();
  }

  @override
  void dispose() {
    _manualController.dispose();
    super.dispose();
  }

  Future<void> _refreshPermission() async {
    setState(() => _loading = true);
    final next = await _seam.check();
    if (!mounted) return;
    setState(() {
      _status = next;
      _loading = false;
    });
  }

  Future<void> _onOpenSettings() async {
    final l10n = AppLocalizations.of(context);
    await _seam.openSettings();
    if (widget.onOpenSettingsToast && mounted) {
      AppToast.show(context, message: l10n.childQrOpenSettingsToast);
    }
    await _refreshPermission();
  }

  Future<void> _onRequestThenRefresh() async {
    await _seam.request();
    await _refreshPermission();
  }

  Future<void> _claimWithToken(String raw) async {
    final l10n = AppLocalizations.of(context);
    final cleaned = raw.trim().replaceAll(' ', '');
    if (!isValidLinkToken(cleaned)) {
      setState(() {
        _phase = _ClaimPhase.failure;
        _failureMessage = l10n.enrollmentFailureInvalidToken;
      });
      return;
    }

    // Test seam bypasses enrollment authority.
    if (widget.onClaimed != null) {
      widget.onClaimed!();
      return;
    }

    setState(() {
      _phase = _ClaimPhase.verifying;
      _failureMessage = null;
    });
    await Future<void>.delayed(const Duration(milliseconds: 40));
    if (!mounted) return;

    final pending = _managementRepo.findPendingByPairingToken(
      PairingTokenId(cleaned),
    );
    if (pending == null) {
      // Legacy onboarding without pending enrollment in identity runtime.
      if (CurrentIdentity.maybeOf(context) == null) {
        context.go('/scr-chd-003');
        return;
      }
      setState(() {
        _phase = _ClaimPhase.failure;
        _failureMessage = l10n.enrollmentFailureInvalidToken;
      });
      return;
    }

    setState(() => _phase = _ClaimPhase.progress);
    await Future<void>.delayed(const Duration(milliseconds: 40));
    if (!mounted) return;

    try {
      _managementRepo.finalizeEnrollment(pending.id);
      context.go('/scr-chd-003');
    } on IdentityInvariantViolation catch (error) {
      final maxBlocked = error.message.contains('max 3');
      setState(() {
        _phase = _ClaimPhase.failure;
        _failureMessage = maxBlocked
            ? l10n.enrollmentFailureMaxDevices
            : l10n.enrollmentFailureGeneric;
      });
    } on Object {
      setState(() {
        _phase = _ClaimPhase.failure;
        _failureMessage = l10n.enrollmentFailureGeneric;
      });
    }
  }

  void _onSimulateScan() {
    final token = widget.claimToken?.trim();
    if (token != null && token.isNotEmpty) {
      _claimWithToken(token);
      return;
    }
    if (widget.onClaimed != null) {
      widget.onClaimed!();
      return;
    }
    // Simulate without a concrete token cannot honestly enroll.
    if (CurrentIdentity.maybeOf(context) != null) {
      final l10n = AppLocalizations.of(context);
      setState(() {
        _phase = _ClaimPhase.failure;
        _failureMessage = l10n.enrollmentFailureInvalidToken;
      });
      return;
    }
    context.go('/scr-chd-003');
  }

  void _onManualSubmit() {
    final l10n = AppLocalizations.of(context);
    final raw = _manualController.text;
    if (!isValidLinkToken(raw)) {
      setState(() => _manualError = l10n.childQrTokenInvalid);
      return;
    }
    setState(() => _manualError = null);
    _claimWithToken(raw);
  }

  void _onManualLinkTap() {
    final l10n = AppLocalizations.of(context);
    AppToast.show(context, message: l10n.childQrManualHintToast);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.childQrTitle,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: colors.ink,
              ),
            ),
            Text(
              l10n.childQrSubtitle,
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
        child: _phase != _ClaimPhase.idle
            ? _ClaimStatusBody(
                phase: _phase,
                failureMessage: _failureMessage,
                onRetry: () => setState(() {
                  _phase = _ClaimPhase.idle;
                  _failureMessage = null;
                }),
              )
            : _loading || _status == null
            ? const Center(child: CircularProgressIndicator())
            : switch (_status!) {
                CameraPermissionStatus.granted => _ScanBody(
                  onSimulate: _onSimulateScan,
                  onManualLink: _onManualLinkTap,
                ),
                CameraPermissionStatus.denied => _RepairBody(
                  onOpenSettings: _onOpenSettings,
                  onRetryRequest: _onRequestThenRefresh,
                ),
                CameraPermissionStatus.permanentlyDenied => _PermanentBody(
                  controller: _manualController,
                  error: _manualError,
                  onSubmit: _onManualSubmit,
                ),
              },
      ),
    );
  }
}

class _ClaimStatusBody extends StatelessWidget {
  const _ClaimStatusBody({
    required this.phase,
    required this.failureMessage,
    required this.onRetry,
  });

  final _ClaimPhase phase;
  final String? failureMessage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        children: [
          if (phase == _ClaimPhase.verifying) ...[
            const CircularProgressIndicator(),
            const SizedBox(height: 18),
            Text(
              key: ChildQrScanKeys.verifying,
              l10n.pairingVerificationTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.pairingVerificationMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.ink2,
                height: 1.5,
              ),
            ),
          ] else if (phase == _ClaimPhase.progress) ...[
            const CircularProgressIndicator(),
            const SizedBox(height: 18),
            Text(
              key: ChildQrScanKeys.progress,
              l10n.enrollmentProgressTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.enrollmentProgressMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.ink2,
                height: 1.5,
              ),
            ),
          ] else ...[
            Text(
              key: ChildQrScanKeys.failure,
              failureMessage ?? l10n.enrollmentFailureGeneric,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: colors.coral,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            PrimaryBtn(
              label: l10n.linkQrRenew,
              variant: PrimaryBtnVariant.sec,
              onPressed: onRetry,
            ),
          ],
        ],
      ),
    );
  }
}

class _ScanBody extends StatelessWidget {
  const _ScanBody({required this.onSimulate, required this.onManualLink});

  final VoidCallback onSimulate;
  final VoidCallback onManualLink;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Text(
          l10n.childQrInstruction,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colors.ink2,
            height: 1.55,
          ),
        ),
        const SizedBox(height: 18),
        Center(
          child: Semantics(
            label: l10n.childQrScanSemantics,
            child: Container(
              key: ChildQrScanKeys.scanFrame,
              width: 230,
              height: 230,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1D2E),
                borderRadius: BorderRadius.circular(radii.card),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 34,
                    right: 34,
                    top: 34,
                    bottom: 34,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(color: colors.teal, width: 3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 34,
                    right: 34,
                    top: 110,
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: colors.teal,
                        boxShadow: [
                          BoxShadow(
                            color: colors.teal.withValues(alpha: 0.55),
                            blurRadius: 14,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        BannerNote(
          message: l10n.childQrFatherTokenNote,
          variant: BannerVariant.t,
        ),
        const SizedBox(height: 14),
        PrimaryBtn(
          key: ChildQrScanKeys.simulateScan,
          label: l10n.childQrSimulateScan,
          variant: PrimaryBtnVariant.teal,
          onPressed: onSimulate,
        ),
        const SizedBox(height: 8),
        PrimaryBtn(
          key: ChildQrScanKeys.manualLink,
          label: l10n.childQrManualLink,
          variant: PrimaryBtnVariant.ghost,
          onPressed: onManualLink,
        ),
      ],
    );
  }
}

class _RepairBody extends StatelessWidget {
  const _RepairBody({
    required this.onOpenSettings,
    required this.onRetryRequest,
  });

  final VoidCallback onOpenSettings;
  final VoidCallback onRetryRequest;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        DecoratedBox(
          key: ChildQrScanKeys.repairPanel,
          decoration: BoxDecoration(
            color: colors.amber100,
            borderRadius: BorderRadius.circular(radii.card),
            border: Border.all(
              color: colors.amber.withValues(alpha: 0.55),
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 24, 18, 22),
            child: Column(
              children: [
                Icon(
                  Icons.photo_camera_outlined,
                  size: 44,
                  color: colors.amberDeep,
                ),
                const SizedBox(height: 14),
                Text(
                  l10n.childQrRepairTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: colors.amberDeep,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.childQrRepairBody,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: colors.amberInk,
                    height: 1.65,
                  ),
                ),
                const SizedBox(height: 20),
                PrimaryBtn(
                  key: ChildQrScanKeys.openSettings,
                  label: l10n.childQrOpenSettings,
                  variant: PrimaryBtnVariant.sec,
                  onPressed: onOpenSettings,
                ),
                const SizedBox(height: 8),
                PrimaryBtn(
                  label: l10n.childQrRetryPermission,
                  variant: PrimaryBtnVariant.ghost,
                  onPressed: onRetryRequest,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PermanentBody extends StatelessWidget {
  const _PermanentBody({
    required this.controller,
    required this.error,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final String? error;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        DecoratedBox(
          key: ChildQrScanKeys.permanentPanel,
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(radii.card),
            border: Border.all(color: colors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.childQrPermanentTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: colors.ink,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.childQrPermanentBody,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: colors.ink2,
                    height: 1.65,
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  key: ChildQrScanKeys.manualCode,
                  controller: controller,
                  textAlign: TextAlign.center,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'[A-Za-z0-9_\-]'),
                    ),
                    LengthLimitingTextInputFormatter(24),
                  ],
                  decoration: InputDecoration(
                    hintText: l10n.childQrManualPlaceholder,
                    errorText: error,
                  ),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3,
                    color: colors.ink,
                  ),
                ),
                const SizedBox(height: 14),
                PrimaryBtn(
                  key: ChildQrScanKeys.manualSubmit,
                  label: l10n.childQrManualSubmit,
                  variant: PrimaryBtnVariant.teal,
                  onPressed: onSubmit,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
