import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/identity/child_device_management_repository.dart';
import 'package:family_os/core/identity/identity_models.dart';
import 'package:family_os/core/identity/identity_runtime.dart';
import 'package:family_os/core/identity/identity_scope.dart';
import 'package:family_os/core/i18n/app_localizations.dart';

/// Default pairing_token window (prototype `startQR` / data contracts).
const int kLinkQrDefaultSeconds = 299;

/// Widget keys for SCR-FAT-004 managed pairing.
abstract final class LinkQrKeys {
  static const instruction = Key('link_qr_instruction');
  static const visual = Key('link_qr_visual');
  static const timer = Key('link_qr_timer');
  static const token = Key('link_qr_token');
  static const expired = Key('link_qr_expired');
  static const continueBtn = Key('link_qr_continue');
  static const renew = Key('link_qr_renew');
  static const trial = Key('link_qr_trial');
  static const awaitingClaim = Key('link_qr_awaiting_claim');
  static const maxDevices = Key('link_qr_max_devices');
  static const selectChild = Key('link_qr_select_child');
  static const enrollmentId = Key('link_qr_enrollment_id');
  static Key childOption(String id) => Key('link_qr_child_$id');
}

/// Mock pairing token: `pair_` + 8 hex chars.
String generateMockPairToken([Random? random]) {
  final r = random ?? Random();
  final hex = List.generate(8, (_) => r.nextInt(16).toRadixString(16)).join();
  return 'pair_$hex';
}

/// Formats remaining seconds as `m:ss` (Eastern digits when [eastern] is true).
String formatLinkQrCountdown(int totalSeconds, {required bool eastern}) {
  final safe = totalSeconds < 0 ? 0 : totalSeconds;
  final minutes = safe ~/ 60;
  final seconds = safe % 60;
  final raw = '$minutes:${seconds.toString().padLeft(2, '0')}';
  if (!eastern) return raw;
  return raw.split('').map((ch) {
    const western = '0123456789';
    const easternDigits = '٠١٢٣٤٥٦٧٨٩';
    final i = western.indexOf(ch);
    return i < 0 ? ch : easternDigits[i];
  }).join();
}

/// SCR-FAT-004 — رمز الربط QR.
///
/// When [childId] + identity management are available, issues a real
/// [PairingTokenId] via [ChildDeviceManagementRepository.startPairing] and
/// keeps enrollment pending until CHD-002 claims it. Without child context,
/// preserves the onboarding mock timer flow (FAT-005 / trial).
class LinkQrScreen extends StatefulWidget {
  const LinkQrScreen({
    super.key,
    this.childId,
    this.deviceId,
    this.enrollmentId,
    this.initialSeconds = kLinkQrDefaultSeconds,
    this.tickInterval = const Duration(seconds: 1),
    this.onContinue,
    this.onTrial,
    this.mockToken,
    this.managementRepository,
  });

  /// Active child for managed pairing (`?childId=`).
  final String? childId;

  /// Optional device to bind (`?deviceId=`).
  final String? deviceId;

  /// Resume an existing pairing-pending enrollment.
  final String? enrollmentId;

  /// Test seam — remaining seconds at first paint (prototype starts at 299).
  final int initialSeconds;

  /// Test seam — countdown tick period (default 1s).
  final Duration tickInterval;

  /// Test seam — when null, navigates to `/scr-fat-005` (mock) or profile
  /// (managed — does **not** finalize enrollment).
  final VoidCallback? onContinue;

  /// Test seam — when null, navigates to `/scr-fat-007`.
  final VoidCallback? onTrial;

  /// Optional stable token for tests; otherwise generated on init / renew.
  final String? mockToken;

  final ChildDeviceManagementRepository? managementRepository;

  @override
  State<LinkQrScreen> createState() => _LinkQrScreenState();
}

class _LinkQrScreenState extends State<LinkQrScreen> {
  late int _secondsLeft;
  late String _token;
  Timer? _timer;
  bool _expired = false;
  late final ChildDeviceManagementRepository _managementRepo;
  EnrollmentId? _enrollmentId;
  String? _boundChildId;
  var _maxDevicesBlocked = false;
  var _bootstrapped = false;
  List<ManagedChildRecord> _pickerChildren = const [];

  bool get _managedMode =>
      (_boundChildId ?? widget.childId)?.trim().isNotEmpty == true;

  @override
  void initState() {
    super.initState();
    _managementRepo =
        widget.managementRepository ?? stage1ChildDeviceManagementRepository;
    _token = widget.mockToken ?? generateMockPairToken();
    _secondsLeft = widget.initialSeconds;
    _expired = _secondsLeft <= 0;
    _boundChildId = widget.childId?.trim();
    if (!_expired) {
      _startTicker();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bootstrapped) return;
    _bootstrapped = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _bootstrapManaged();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _bootstrapManaged() {
    final resumeId = widget.enrollmentId?.trim();
    if (resumeId != null && resumeId.isNotEmpty) {
      final existing = _managementRepo.findEnrollment(EnrollmentId(resumeId));
      if (existing != null &&
          existing.state == EnrollmentState.pairingPending &&
          existing.pairingTokenId != null) {
        setState(() {
          _enrollmentId = existing.id;
          _boundChildId = existing.childId.value;
          _token = existing.pairingTokenId!.value;
          _maxDevicesBlocked = false;
        });
        return;
      }
    }

    final childId = _boundChildId;
    if (childId == null || childId.isEmpty) {
      final familyId = CurrentIdentity.maybeOf(context)?.activeFamilyId;
      if (familyId != null) {
        setState(() {
          _pickerChildren = _managementRepo.listChildren(familyId);
        });
      }
      return;
    }

    _issuePairing(ChildId(childId));
  }

  int _activeEnrollmentCount(FamilyId familyId, ChildId childId) {
    return _managementRepo
        .listDevices(familyId: familyId, childId: childId)
        .expand((d) => d.enrollments)
        .where((e) => e.state == EnrollmentState.enrolled)
        .length;
  }

  void _issuePairing(ChildId childId) {
    final runtime = CurrentIdentity.maybeOf(context);
    final familyId = runtime?.activeFamilyId;
    if (familyId == null) {
      // Onboarding without identity — keep mock token UI.
      return;
    }
    if (_activeEnrollmentCount(familyId, childId) >= 3) {
      setState(() {
        _maxDevicesBlocked = true;
        _boundChildId = childId.value;
      });
      return;
    }
    try {
      final stamp = DateTime.now().microsecondsSinceEpoch;
      final deviceRaw = widget.deviceId?.trim();
      final deviceId = DeviceId(
        (deviceRaw == null || deviceRaw.isEmpty) ? 'dev_$stamp' : deviceRaw,
      );
      final enrollment = _managementRepo.startPairing(
        familyId: familyId,
        childId: childId,
        deviceId: deviceId,
      );
      setState(() {
        _enrollmentId = enrollment.id;
        _boundChildId = childId.value;
        _token = enrollment.pairingTokenId?.value ?? generateMockPairToken();
        _maxDevicesBlocked = false;
        _secondsLeft = kLinkQrDefaultSeconds;
        _expired = false;
      });
      _startTicker();
    } on IdentityInvariantViolation {
      setState(() => _maxDevicesBlocked = true);
    }
  }

  void _selectChild(ManagedChildRecord child) {
    setState(() {
      _boundChildId = child.childId.value;
      _pickerChildren = const [];
    });
    _issuePairing(child.childId);
  }

  void _startTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(widget.tickInterval, (_) {
      if (!mounted) return;
      setState(() {
        if (_secondsLeft <= 1) {
          _secondsLeft = 0;
          _expired = true;
          _timer?.cancel();
          _timer = null;
        } else {
          _secondsLeft -= 1;
        }
      });
    });
  }

  void _continue() {
    if (_expired || _maxDevicesBlocked) return;
    if (widget.onContinue != null) {
      widget.onContinue!();
      return;
    }
    if (_managedMode) {
      final childId = _boundChildId;
      if (childId == null) return;
      // Honest: pairing stays pending until CHD-002 claim/finalize.
      context.go('/scr-fat-013?childId=${Uri.encodeComponent(childId)}');
      return;
    }
    context.go('/scr-fat-005');
  }

  void _trial() {
    if (widget.onTrial != null) {
      widget.onTrial!();
      return;
    }
    context.go('/scr-fat-007');
  }

  void _renew(AppLocalizations l10n) {
    if (_managedMode) {
      final childId = _boundChildId;
      if (childId == null) return;
      final pending = _enrollmentId;
      if (pending != null) {
        try {
          _managementRepo.closeEnrollment(
            enrollmentId: pending,
            reason: EnrollmentCloseReason.revoked,
          );
        } on Object {
          // Best-effort revoke of expired pending before new EnrollmentId.
        }
      }
      _issuePairing(ChildId(childId));
      AppToast.show(context, message: l10n.linkQrRenewToast);
      return;
    }
    setState(() {
      _token = generateMockPairToken();
      _secondsLeft = kLinkQrDefaultSeconds;
      _expired = false;
    });
    _startTicker();
    AppToast.show(context, message: l10n.linkQrRenewToast);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final shadows = Theme.of(context).extension<FamilyShadows>()!;
    final eastern = l10n.localeName.startsWith('ar');
    final warning = _secondsLeft < 60 && !_expired;

    if (!_managedMode &&
        (widget.childId == null || widget.childId!.trim().isEmpty) &&
        CurrentIdentity.maybeOf(context) != null) {
      return Scaffold(
        backgroundColor: colors.bg,
        appBar: AppBar(
          backgroundColor: colors.surface,
          title: Text(
            l10n.linkQrTitle,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: colors.ink,
            ),
          ),
        ),
        body: SafeArea(
          child: _pickerChildren.isEmpty
              ? AppEmptyState(
                  key: LinkQrKeys.selectChild,
                  title: l10n.linkQrSelectChildTitle,
                  message: l10n.childProfileSelectChildEmpty,
                )
              : ListView(
                  key: LinkQrKeys.selectChild,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  children: [
                    Text(
                      l10n.linkQrSelectChildTitle,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: colors.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.linkQrSelectChildMessage,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.ink2,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final child in _pickerChildren)
                      ListTile(
                        key: LinkQrKeys.childOption(child.childId.value),
                        title: Text(child.childId.value),
                        trailing: const Icon(Icons.chevron_left),
                        onTap: () => _selectChild(child),
                      ),
                  ],
                ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.linkQrTitle,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: colors.ink,
              ),
            ),
            Text(
              l10n.linkQrStep,
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
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
          children: [
            Text.rich(
              TextSpan(
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: colors.ink2,
                  height: 1.55,
                ),
                children: [
                  TextSpan(text: l10n.linkQrInstructionPrefix),
                  TextSpan(
                    text: l10n.linkQrInstructionBold,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: colors.ink,
                    ),
                  ),
                ],
              ),
              key: LinkQrKeys.instruction,
              textAlign: TextAlign.center,
            ),
            if (_managedMode) ...[
              const SizedBox(height: 10),
              BannerNote(
                key: LinkQrKeys.awaitingClaim,
                variant: BannerVariant.p,
                message: l10n.linkQrAwaitingClaim,
              ),
            ],
            if (_maxDevicesBlocked) ...[
              const SizedBox(height: 10),
              Text(
                key: LinkQrKeys.maxDevices,
                l10n.childProfileMaxDevicesBlock,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: colors.coral,
                ),
              ),
            ],
            const SizedBox(height: 14),
            Center(
              child: Semantics(
                label: l10n.linkQrSemantics,
                image: true,
                child: DecoratedBox(
                  key: LinkQrKeys.visual,
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: colors.surface, width: 10),
                    boxShadow: [shadows.shCard],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(radii.tcardIcon),
                    child: SizedBox(
                      width: 170,
                      height: 170,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(170, 170),
                            painter: _MockQrPainter(
                              moduleColor: colors.ink,
                              bgColor: colors.surface,
                              seed: _token.hashCode,
                            ),
                          ),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: colors.surface,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const ExcludeSemantics(
                              child: SizedBox(
                                width: 44,
                                height: 44,
                                child: Center(
                                  child: Text(
                                    '🦁',
                                    style: TextStyle(fontSize: 24),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_expired)
              Text(
                l10n.linkQrExpired,
                key: LinkQrKeys.expired,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: colors.coral,
                ),
              )
            else if (!_maxDevicesBlocked)
              Text.rich(
                TextSpan(
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: warning ? colors.coral : colors.ink2,
                  ),
                  children: [
                    TextSpan(text: l10n.linkQrTimerLead),
                    TextSpan(
                      text: formatLinkQrCountdown(
                        _secondsLeft,
                        eastern: eastern,
                      ),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    TextSpan(text: l10n.linkQrTimerTrail),
                  ],
                ),
                key: LinkQrKeys.timer,
                textAlign: TextAlign.center,
              ),
            // Keep token off UI chrome; available for tests / wire-up.
            Opacity(opacity: 0, child: Text(_token, key: LinkQrKeys.token)),
            if (_enrollmentId != null)
              Opacity(
                opacity: 0,
                child: Text(_enrollmentId!.value, key: LinkQrKeys.enrollmentId),
              ),
            const SizedBox(height: 14),
            PrimaryBtn(
              key: LinkQrKeys.continueBtn,
              label: _managedMode
                  ? l10n.linkQrReturnToProfile
                  : l10n.linkQrContinue,
              onPressed: (_expired || _maxDevicesBlocked) ? null : _continue,
            ),
            const SizedBox(height: 10),
            PrimaryBtn(
              key: LinkQrKeys.renew,
              label: l10n.linkQrRenew,
              variant: _expired
                  ? PrimaryBtnVariant.primary
                  : PrimaryBtnVariant.sec,
              onPressed: _maxDevicesBlocked ? null : () => _renew(l10n),
            ),
            if (!_managedMode) ...[
              const SizedBox(height: 10),
              PrimaryBtn(
                key: LinkQrKeys.trial,
                label: l10n.linkQrTrial,
                variant: PrimaryBtnVariant.ghost,
                onPressed: _trial,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Fake QR module grid (no real encoding).
class _MockQrPainter extends CustomPainter {
  _MockQrPainter({
    required this.moduleColor,
    required this.bgColor,
    required this.seed,
  });

  final Color moduleColor;
  final Color bgColor;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = bgColor;
    canvas.drawRect(Offset.zero & size, bg);

    const modules = 21;
    final cell = size.width / modules;
    final paint = Paint()..color = moduleColor;
    final rng = Random(seed);

    for (var y = 0; y < modules; y++) {
      for (var x = 0; x < modules; x++) {
        final inFinder = _inFinderPattern(x, y, modules);
        final filled = inFinder || rng.nextBool();
        if (!filled) continue;
        // Clear center logo pocket.
        if (x >= 8 && x <= 12 && y >= 8 && y <= 12) continue;
        canvas.drawRect(
          Rect.fromLTWH(x * cell, y * cell, cell + 0.5, cell + 0.5),
          paint,
        );
      }
    }
  }

  bool _inFinderPattern(int x, int y, int n) {
    bool corner(int ox, int oy) {
      final dx = x - ox;
      final dy = y - oy;
      if (dx < 0 || dy < 0 || dx > 6 || dy > 6) return false;
      if (dx == 0 || dy == 0 || dx == 6 || dy == 6) return true;
      if (dx >= 2 && dx <= 4 && dy >= 2 && dy <= 4) return true;
      return false;
    }

    return corner(0, 0) || corner(n - 7, 0) || corner(0, n - 7);
  }

  @override
  bool shouldRepaint(covariant _MockQrPainter oldDelegate) {
    return oldDelegate.seed != seed ||
        oldDelegate.moduleColor != moduleColor ||
        oldDelegate.bgColor != bgColor;
  }
}
