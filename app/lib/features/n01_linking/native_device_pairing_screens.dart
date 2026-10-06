import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/app/child_device_mode.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/features/shared_onboarding/session_recovery.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/runtime/app_scope.dart';
import 'package:family_os/foundation_gate/family_device_api_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_configuration.dart';
import 'package:family_os/foundation_gate/foundation_gate_http.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';
import 'package:family_os/foundation_gate/main_app_foundation_runtime.dart';
import 'package:family_os/foundation_gate/native_child_pairing_copy.dart';
import 'package:family_os/foundation_gate/native_child_telemetry_bridge.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PARENT SIDE — issues a one-time pairing code and shows a scannable QR.
// The code is backed by a server-side SHA-256 hashed, expiring capability.
// ─────────────────────────────────────────────────────────────────────────────

class NativeParentPairingScreen extends StatefulWidget {
  const NativeParentPairingScreen({super.key, this.childId});

  final String? childId;

  @override
  State<NativeParentPairingScreen> createState() =>
      _NativeParentPairingScreenState();
}

enum _VerificationState { checking, verified, unverified }

class _NativeParentPairingScreenState extends State<NativeParentPairingScreen>
    with WidgetsBindingObserver {
  static const _devicePollInterval = Duration(seconds: 5);
  static const _verificationPollInterval = Duration(seconds: 3);

  final _label = TextEditingController();
  FoundationGateDevicePairing? _pairing;
  String? _pairingIdempotencyKey;
  String? _submittedDeviceLabel;
  var _loading = false;
  String? _error;
  var _sessionInvalid = false;

  _VerificationState _verification = _VerificationState.checking;
  var _verificationBusy = false;
  String? _verificationNote;

  Timer? _ticker;
  Timer? _devicePoll;
  Timer? _verificationPoll;
  var _autoContinuing = false;
  Duration _remaining = Duration.zero;
  int _baselineDeviceCount = 0;
  var _childConnected = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _label.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Sensible default so the flow can continue hands-free after the
      // e-mail is verified; the guardian may still rename it.
      if (_label.text.trim().isEmpty) {
        _label.text = NativeChildPairingCopy.of(context).defaultDeviceLabel;
      }
      // Do not trust the Firebase user's cached verification bit here. This
      // flow immediately calls a verified-email-only server endpoint, so the
      // screen begins with a provider reload and fresh ID-token claim.
      _checkVerification(reload: true);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _devicePoll?.cancel();
    _verificationPoll?.cancel();
    _label.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The guardian typically leaves to the mail app to click the link and
    // comes back: re-check silently on resume.
    if (state == AppLifecycleState.resumed &&
        _verification == _VerificationState.unverified) {
      _checkVerification(reload: true, silent: true);
    }
  }

  RemoteFamilyDeviceSource? get _deviceSource {
    final source = AppScope.maybeOf(context)?.devices;
    return source is RemoteFamilyDeviceSource ? source : null;
  }

  // ── E-mail verification gate (Owner decision C1) ───────────────────────

  Future<void> _checkVerification({
    bool reload = false,
    bool silent = false,
  }) async {
    final copy = NativeChildPairingCopy.of(context);
    final source = _deviceSource;
    if (source == null) {
      setState(() => _verification = _VerificationState.unverified);
      return;
    }
    if (!silent) setState(() => _verificationBusy = true);
    final verified = await source.isEmailVerified(reload: reload);
    if (!mounted) return;
    if (source.sessionInvalid) {
      _showSessionExpired();
      return;
    }
    final wasUnverified = _verification == _VerificationState.unverified;
    setState(() {
      _verificationBusy = false;
      _verification = verified
          ? _VerificationState.verified
          : _VerificationState.unverified;
      if (!silent) {
        _verificationNote = verified
            ? null
            : (reload ? copy.stillNotVerified : null);
      }
      if (verified) _verificationNote = null;
    });
    if (verified) {
      _stopVerificationPoll();
      if (wasUnverified) {
        HapticFeedback.mediumImpact();
        AppToast.show(context, message: copy.emailVerificationSuccess);
      }
      // The link was clicked (on this phone or any other device): continue
      // hands-free — no tap required.
      if (wasUnverified && _pairing == null && !_loading) {
        setState(() => _autoContinuing = true);
        await _create();
        if (mounted) setState(() => _autoContinuing = false);
      }
    } else {
      _startVerificationPoll();
    }
  }

  /// Silent background sensor: reloads the provider user every few seconds
  /// while the e-mail is unverified and stops the moment it becomes verified.
  void _startVerificationPoll() {
    if (_verificationPoll != null) return;
    _verificationPoll = Timer.periodic(_verificationPollInterval, (_) {
      if (!mounted || _verification != _VerificationState.unverified) {
        _stopVerificationPoll();
        return;
      }
      if (_verificationBusy) return;
      _checkVerification(reload: true, silent: true);
    });
  }

  void _stopVerificationPoll() {
    _verificationPoll?.cancel();
    _verificationPoll = null;
  }

  Future<void> _sendVerification() async {
    final copy = NativeChildPairingCopy.of(context);
    final source = _deviceSource;
    if (source == null) return;
    setState(() => _verificationBusy = true);
    final sent = await source.sendEmailVerification();
    if (!mounted) return;
    if (source.sessionInvalid) {
      _showSessionExpired();
      return;
    }
    setState(() {
      _verificationBusy = false;
      _verificationNote = sent
          ? copy.verificationEmailSent
          : copy.verificationEmailSendFailed;
    });
  }

  // ── Pairing code lifecycle ─────────────────────────────────────────────

  bool get _canCreate =>
      !_loading &&
      _verification == _VerificationState.verified &&
      _label.text.trim().isNotEmpty;

  Future<void> _create() async {
    final copy = NativeChildPairingCopy.of(context);
    final childRaw = widget.childId?.trim();
    final deviceLabel = _label.text.trim();
    final runtime = AppScope.maybeOf(context);
    final familyId = runtime?.identity.value.familyId;
    final source = _deviceSource;
    if (childRaw == null ||
        childRaw.isEmpty ||
        familyId == null ||
        source == null) {
      setState(() => _error = copy.parentAccessRequired);
      return;
    }
    if (deviceLabel.isEmpty) {
      setState(() => _error = copy.deviceNameRequired);
      return;
    }
    if (_verification != _VerificationState.verified) {
      setState(() => _error = copy.emailVerificationRequiredTitle);
      return;
    }
    _stopTimers();
    if (_pairingIdempotencyKey == null ||
        _submittedDeviceLabel != deviceLabel ||
        _pairing != null) {
      _pairingIdempotencyKey = newFoundationGateIdempotencyKey();
      _submittedDeviceLabel = deviceLabel;
    }
    setState(() {
      _loading = true;
      _error = null;
      _sessionInvalid = false;
      _pairing = null;
      _childConnected = false;
    });

    // Baseline: how many devices this child already has, so a *new* device
    // appearing is the only thing that counts as "connected".
    _baselineDeviceCount = await _currentDeviceCount(
      source,
      familyId,
      childRaw,
    );
    if (!mounted) return;
    if (source.sessionInvalid) {
      _showSessionExpired();
      return;
    }

    final result = await source.createPairing(
      familyId: familyId,
      childId: ChildId(childRaw),
      deviceLabel: deviceLabel,
      idempotencyKey: _pairingIdempotencyKey!,
    );
    if (!mounted) return;
    if (result.failure ==
        FoundationGateDevicePairingCreateFailure.sessionInvalid) {
      _showSessionExpired();
      return;
    }
    final pairing = result.pairing;
    final failure = result.failure;
    if (failure == FoundationGateDevicePairingCreateFailure.conflict) {
      // The server never replays the raw one-time code for a repeated key.
      // The next explicit attempt must therefore represent a new issuance.
      _pairingIdempotencyKey = null;
    }
    setState(() {
      _loading = false;
      _pairing = pairing;
      _error = pairing == null ? _messageForPairingFailure(copy, failure) : null;
      _sessionInvalid = false;
      if (failure ==
          FoundationGateDevicePairingCreateFailure
              .emailVerificationRequired) {
        _verification = _VerificationState.unverified;
        _verificationNote = copy.emailVerificationRefreshRequired;
      }
    });
    if (failure ==
        FoundationGateDevicePairingCreateFailure.emailVerificationRequired) {
      _startVerificationPoll();
    }
    if (pairing != null) _startTimers(pairing, source, familyId, childRaw);
  }

  String _messageForPairingFailure(
    NativeChildPairingCopy copy,
    FoundationGateDevicePairingCreateFailure? failure,
  ) => switch (failure) {
    FoundationGateDevicePairingCreateFailure.emailVerificationRequired =>
      copy.emailVerificationRefreshRequired,
    FoundationGateDevicePairingCreateFailure.accessDenied =>
      copy.pairingAccessDenied,
    FoundationGateDevicePairingCreateFailure.invalidInput =>
      copy.pairingInvalidChild,
    FoundationGateDevicePairingCreateFailure.childNotFound =>
      copy.pairingChildNotFound,
    FoundationGateDevicePairingCreateFailure.conflict =>
      copy.pairingConflict,
    FoundationGateDevicePairingCreateFailure.serviceUnavailable =>
      copy.pairingServiceUnavailable,
    FoundationGateDevicePairingCreateFailure.networkUnavailable =>
      copy.pairingNetworkUnavailable,
    FoundationGateDevicePairingCreateFailure.unavailable ||
    FoundationGateDevicePairingCreateFailure.sessionInvalid ||
    null => copy.pairingUnavailable,
  };

  Future<int> _currentDeviceCount(
    RemoteFamilyDeviceSource source,
    FamilyId familyId,
    String childId,
  ) async {
    final snapshot = await source.load(familyId);
    for (final child in snapshot.children) {
      if (child.childId.value == childId) return child.deviceCount;
    }
    return 0;
  }

  void _startTimers(
    FoundationGateDevicePairing pairing,
    RemoteFamilyDeviceSource source,
    FamilyId familyId,
    String childId,
  ) {
    _tick(pairing);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick(pairing));
    _devicePoll = Timer.periodic(_devicePollInterval, (_) async {
      final count = await _currentDeviceCount(source, familyId, childId);
      if (!mounted) return;
      if (source.sessionInvalid) {
        _showSessionExpired();
        return;
      }
      if (count > _baselineDeviceCount) {
        _stopTimers();
        setState(() => _childConnected = true);
      }
    });
  }

  void _tick(FoundationGateDevicePairing pairing) {
    final remaining = pairing.expiresAt.difference(DateTime.now().toUtc());
    if (!mounted) return;
    setState(
      () => _remaining = remaining.isNegative ? Duration.zero : remaining,
    );
    if (remaining.isNegative) _stopTimers();
  }

  void _stopTimers() {
    _ticker?.cancel();
    _ticker = null;
    _devicePoll?.cancel();
    _devicePoll = null;
  }

  void _showSessionExpired() {
    _stopTimers();
    _stopVerificationPoll();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _verificationBusy = false;
      _verification = _VerificationState.checking;
      _pairing = null;
      _sessionInvalid = true;
      _error = null;
    });
  }

  Future<void> _recoverSession() async {
    final recovered = await pushGuardianSessionRecovery(context);
    if (!mounted || recovered != true) return;
    setState(() {
      _sessionInvalid = false;
      _error = null;
      _verification = _VerificationState.checking;
    });
    await _checkVerification(reload: true);
  }

  bool get _expired =>
      _pairing != null && _remaining == Duration.zero && !_childConnected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final copy = NativeChildPairingCopy.of(context);
    final pairing = _pairing;
    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        title: Text(copy.parentTitle),
        leading: ModalRoute.of(context)?.canPop == true
            ? const BackButton()
            : BackButton(onPressed: () => context.go('/scr-fat-002')),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              copy.parentIntro,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
            if (!_sessionInvalid) ...[
              const SizedBox(height: 16),
              _verificationCard(colors, copy),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _label,
              maxLength: 80,
              enabled: !_loading && !_childConnected,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                if (_canCreate) _create();
              },
              decoration: InputDecoration(
                labelText: copy.deviceNameLabel,
                hintText: copy.deviceNameHint,
                border: const OutlineInputBorder(),
              ),
            ),
            if (_sessionInvalid) ...[
              const SizedBox(height: 8),
              Text(
                copy.sessionExpiredBody,
                style: TextStyle(
                  color: colors.coral,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  key: const ValueKey('parent-pairing-sign-in-again'),
                  onPressed: _recoverSession,
                  icon: const Icon(Icons.login_rounded),
                  label: Text(copy.signInAgain),
                ),
              ),
            ] else if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(
                  color: colors.coral,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 8),
            if (!_childConnected)
              PrimaryBtn(
                label: _loading
                    ? copy.creatingPairing
                    : (pairing == null
                          ? copy.createPairing
                          : copy.regenerateCode),
                onPressed: _canCreate ? _create : null,
              ),
            if (pairing != null) ...[
              const SizedBox(height: 28),
              const Divider(),
              const SizedBox(height: 16),
              if (_childConnected)
                _connectedCard(colors, copy)
              else if (_expired)
                BannerNote(
                  message: copy.pairingExpired,
                  variant: BannerVariant.a,
                  leading: Icon(
                    Icons.timer_off_outlined,
                    color: colors.amberDeep,
                  ),
                )
              else
                _codeSection(colors, copy, pairing),
            ],
          ],
        ),
      ),
    );
  }

  Widget _verificationCard(FamilyColors colors, NativeChildPairingCopy copy) {
    switch (_verification) {
      case _VerificationState.checking:
        return BannerNote(
          message: copy.checkingVerification,
          leading: const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      case _VerificationState.verified:
        return BannerNote(
          message: _autoContinuing
              ? copy.verifiedAutoContinue
              : copy.emailVerified,
          variant: BannerVariant.g,
          leading: Icon(Icons.verified_outlined, color: colors.mintInk),
        );
      case _VerificationState.unverified:
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.amber100,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.mark_email_unread_outlined,
                    color: colors.amberDeep,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      copy.emailVerificationRequiredTitle,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: colors.amberDeep,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                copy.emailVerificationRequiredBody,
                style: const TextStyle(height: 1.5, fontSize: 13),
              ),
              if (_verificationNote != null) ...[
                const SizedBox(height: 8),
                Text(
                  _verificationNote!,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  // Spinner only while the background sensor is live; an
                  // unconfigured host shows a static icon (nothing to poll).
                  if (_verificationPoll != null)
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.amberDeep,
                      ),
                    )
                  else
                    Icon(
                      Icons.mark_email_unread_outlined,
                      size: 18,
                      color: colors.amberDeep,
                    ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      copy.waitingForVerification,
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _verificationBusy ? null : _sendVerification,
                  icon: const Icon(Icons.send_outlined, size: 18),
                  label: Text(copy.sendVerificationEmail),
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _connectedCard(FamilyColors colors, NativeChildPairingCopy copy) {
    return Column(
      children: [
        Icon(Icons.check_circle, color: colors.mint, size: 64),
        const SizedBox(height: 12),
        Text(
          copy.childDeviceConnected,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        PrimaryBtn(
          label: copy.backToChildren,
          onPressed: () => context.go('/scr-fat-002'),
        ),
      ],
    );
  }

  Widget _codeSection(
    FamilyColors colors,
    NativeChildPairingCopy copy,
    FoundationGateDevicePairing pairing,
  ) {
    final urgent = _remaining < const Duration(minutes: 2);
    return Column(
      children: [
        Text(
          copy.oneTimePairingCode,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          copy.expiresIn(_remaining),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: urgent ? colors.coral : colors.ink2,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 16),
        // The six digits are the primary artefact: large, bold, LTR, tabular,
        // so the guardian can read them aloud and the child can type them.
        SelectableText(
          pairing.pairingCode,
          key: const ValueKey('pairing-code-digits'),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
          style: TextStyle(
            fontSize: 48,
            letterSpacing: 10,
            height: 1.1,
            fontWeight: FontWeight.w900,
            color: colors.tealDeep,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          copy.readCodeAloudHint,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: colors.ink2),
        ),
        TextButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: pairing.pairingCode));
            if (!mounted) return;
            // ignore: use_build_context_synchronously
            AppToast.show(context, message: copy.codeCopied);
          },
          icon: const Icon(Icons.copy_outlined, size: 18),
          label: Text(copy.copyCode),
        ),
        const SizedBox(height: 12),
        Center(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: QrImageView(
              data: pairing.pairingCode,
              version: QrVersions.auto,
              size: 220,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Colors.black,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Colors.black,
              ),
              errorCorrectionLevel: QrErrorCorrectLevel.M,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                copy.waitingForChildDevice,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          copy.keepScreenOpen,
          style: TextStyle(fontSize: 12, color: colors.ink2),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CHILD SIDE — scans the parent's QR or enters the code manually.
// On success: receives a one-time device credential, stores it in Android
// Keystore, requests OS permissions, and starts the native foreground service.
// ─────────────────────────────────────────────────────────────────────────────

class ChildModePairingScreen extends StatefulWidget {
  const ChildModePairingScreen({super.key, this.apiClient, this.onPaired});

  final FamilyDeviceApiClient? apiClient;

  /// Test seam — when null a successful pairing switches the role to child
  /// and navigates to the child home (`/scr-chd-004?childId=…`).
  final void Function(String childId)? onPaired;

  @override
  State<ChildModePairingScreen> createState() => _ChildModePairingScreenState();
}

/// Where the child hand-off currently is. Drives the step header and which
/// controls are enabled; nothing here holds a code or credential.
enum _ChildStep { permissions, code, activating }

enum _ActivatePhase { idle, verifyingCode, starting }

class _ChildModePairingScreenState extends State<ChildModePairingScreen>
    with WidgetsBindingObserver {
  final _code = TextEditingController();
  var _loading = false;
  String? _message;
  var _messageIsError = false;
  NativeTelemetryStatus? _serviceStatus;
  NativeTelemetryPermissionState? _permissions;
  var _permissionsBusy = false;
  _ActivatePhase _phase = _ActivatePhase.idle;

  // QR scanner state
  bool _showScanner = false;
  MobileScannerController? _scannerController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _code.addListener(_onCodeChanged);
    _refreshNative();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _code.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Returning from the OS settings screen: re-read permission state.
    if (state == AppLifecycleState.resumed) _refreshNative();
  }

  Future<void> _refreshNative() async {
    final status = await NativeChildTelemetryBridge.status();
    if (!mounted) return;
    setState(() {
      _serviceStatus = status;
      _permissions = NativeTelemetryPermissionState(
        available: status.available,
        fineLocationGranted: status.fineLocationGranted,
        backgroundLocationGranted: status.backgroundLocationGranted,
      );
    });
  }

  Future<void> _refreshServiceStatus() => _refreshNative();

  // ── Pre-flight ─────────────────────────────────────────────────────────

  static const _origin = String.fromEnvironment('FAMILY_OS_API_ORIGIN');

  /// The native side only accepts HTTPS origins. Decide that *before* a code
  /// is claimed, so a misconfigured build can never burn a pairing code.
  bool get _originSecure {
    final uri = Uri.tryParse(_origin.trim());
    return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;
  }

  bool get _permissionsReady =>
      (_permissions?.available ?? false) &&
      (_permissions?.fineLocationGranted ?? false) &&
      (_permissions?.backgroundLocationGranted ?? false);

  _ChildStep get _step {
    if (_loading) return _ChildStep.activating;
    if (!_permissionsReady) return _ChildStep.permissions;
    return _ChildStep.code;
  }

  Future<void> _grantPermissions() async {
    setState(() {
      _permissionsBusy = true;
      _message = null;
    });
    final granted =
        await NativeChildTelemetryBridge.requestLocationPermissions();
    if (!mounted) return;
    setState(() {
      _permissionsBusy = false;
      _permissions = granted;
    });
  }

  FamilyDeviceApiClient? _client() {
    if (widget.apiClient != null) return widget.apiClient;
    if (!_originSecure) return null;
    try {
      return FamilyDeviceApiClient(
        configuration: FoundationGateConfiguration.fromStagingApiOrigin(
          Uri.parse(_origin),
        ),
        transport: PackageFoundationGateHttpTransport(),
      );
    } on Object {
      return null;
    }
  }

  // ── Scanner ────────────────────────────────────────────────────────────

  void _startScanner() {
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      formats: [BarcodeFormat.qrCode],
    );
    setState(() => _showScanner = true);
  }

  void _stopScanner() {
    _scannerController?.dispose();
    _scannerController = null;
    setState(() => _showScanner = false);
  }

  void _onQrDetected(BarcodeCapture capture) {
    final barcode = capture.barcodes.firstOrNull;
    final raw = barcode?.rawValue;
    final digits = raw?.trim();
    if (digits != null &&
        FamilyDeviceApiClient.pairingCodePattern.hasMatch(digits)) {
      _stopScanner();
      // Setting the text triggers _onCodeChanged, which submits the claim.
      _code.text = digits;
    }
  }

  /// OTP-style: the sixth digit submits automatically — no extra tap for the
  /// child. Server-side the claim is single-use and brute-force limited, so a
  /// mistyped code costs one of five attempts, exactly like pressing Submit.
  void _onCodeChanged() {
    if (!mounted) return;
    setState(() {});
    if (_loading) return;
    if (FamilyDeviceApiClient.pairingCodePattern.hasMatch(_code.text)) {
      _claimAndStart();
    }
  }

  // ── Claim + activate ───────────────────────────────────────────────────

  Future<void> _claimAndStart() async {
    final copy = NativeChildPairingCopy.of(context);
    final pairingCode = _code.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (!FamilyDeviceApiClient.pairingCodePattern.hasMatch(pairingCode)) {
      _fail(copy.pairingCodeHint);
      return;
    }
    if (widget.apiClient == null && !_originSecure) {
      _fail(copy.secureOriginRequired);
      return;
    }
    final client = _client();
    if (client == null || pairingCode.isEmpty) {
      _fail(copy.secureOriginAndCodeRequired);
      return;
    }
    // Permissions are a hard pre-condition of the *claim*, never an
    // afterthought: a denied permission must leave the code unused.
    if (!_permissionsReady) {
      final granted =
          await NativeChildTelemetryBridge.requestLocationPermissions();
      if (!mounted) return;
      setState(() => _permissions = granted);
      if (!_permissionsReady) {
        _fail(copy.locationPermissionNotGranted);
        return;
      }
    }
    setState(() {
      _loading = true;
      _message = null;
      _messageIsError = false;
      _phase = _ActivatePhase.verifyingCode;
    });
    try {
      final claimed = await client.claimPairing(pairingCode: pairingCode);
      if (!mounted) return;
      setState(() => _phase = _ActivatePhase.starting);
      final result = await NativeChildTelemetryBridge.configureAndStart(
        apiOrigin: _origin,
        deviceId: claimed.device.id,
        deviceCredential: claimed.deviceCredential,
      );
      if (!mounted) return;
      if (!result.started) {
        // The code is consumed server-side at this point; say so honestly.
        _fail(
          '${copy.codeConsumedStartFailed}\n${copy.startFailureReason(result.reason)}',
        );
        await _refreshServiceStatus();
        return;
      }
      await ChildDeviceMode.markPaired(
        childId: claimed.device.childId,
        deviceId: claimed.device.id,
      );
      if (!mounted) return;
      final roleNotifier = CurrentRole.maybeNotifierOf(context);
      if (roleNotifier != null) roleNotifier.value = AppRole.child;
      final onPaired = widget.onPaired;
      if (onPaired != null) {
        onPaired(claimed.device.childId);
        return;
      }
      AppToast.show(context, message: copy.childModeActive);
      context.go('/scr-chd-004?childId=${claimed.device.childId}');
      return;
    } on FoundationGateApiException catch (error) {
      _fail(
        error.failure == FoundationGateApiFailure.tooManyAttempts
            ? copy.pairingAttemptsExceeded
            : copy.pairingClaimFailed,
      );
    } on Object {
      _fail(copy.startFailureReason('native_telemetry_start_failed'));
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _phase = _ActivatePhase.idle;
        });
      }
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _message = message;
      _messageIsError = true;
    });
  }

  // ── UI ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final copy = NativeChildPairingCopy.of(context);
    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        title: Text(copy.childTitle),
        actions: [
          if (_showScanner)
            IconButton(
              icon: const Icon(Icons.keyboard_outlined),
              tooltip: copy.enterCodeManually,
              onPressed: _stopScanner,
            ),
        ],
      ),
      body: SafeArea(
        child: _showScanner
            ? _buildScanner(colors, copy)
            : _buildSteps(colors, copy),
      ),
    );
  }

  Widget _buildScanner(FamilyColors colors, NativeChildPairingCopy copy) {
    return Stack(
      children: [
        MobileScanner(controller: _scannerController!, onDetect: _onQrDetected),
        Center(
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              border: Border.all(color: colors.tealDeep, width: 3),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 40,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              copy.scanQrInstruction,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSteps(FamilyColors colors, NativeChildPairingCopy copy) {
    final step = _step;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StepHeader(
          current: step,
          labels: [copy.stepPermissions, copy.stepScan, copy.stepActivate],
        ),
        const SizedBox(height: 20),
        if (!(_permissions?.available ?? true))
          BannerNote(message: copy.nativeUnavailable, variant: BannerVariant.a)
        else if (!_originSecure && widget.apiClient == null)
          BannerNote(
            message: copy.secureOriginRequired,
            variant: BannerVariant.a,
            leading: Icon(Icons.lock_outline, color: colors.amberDeep),
          ),
        if (step == _ChildStep.permissions) _permissionsSection(colors, copy),
        if (step == _ChildStep.code) _codeSection(colors, copy),
        if (step == _ChildStep.activating) _activatingSection(colors, copy),
        if (_message != null) ...[
          const SizedBox(height: 14),
          Text(
            _message!,
            style: TextStyle(
              color: _messageIsError ? colors.coral : colors.ink,
              fontWeight: FontWeight.w700,
              height: 1.45,
            ),
          ),
        ],
        if (_serviceStatus?.running == true && step != _ChildStep.activating)
          TextButton.icon(
            onPressed: () async {
              final stopped = await NativeChildTelemetryBridge.stop();
              await _refreshServiceStatus();
              if (mounted) {
                setState(() {
                  _message = stopped
                      ? copy.childModeStopped
                      : copy.childModeStopFailed;
                  _messageIsError = !stopped;
                });
              }
            },
            icon: const Icon(Icons.stop_circle_outlined),
            label: Text(copy.stopChildMode),
          ),
      ],
    );
  }

  Widget _permissionsSection(FamilyColors colors, NativeChildPairingCopy copy) {
    final p = _permissions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          copy.permissionsIntro,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 14),
        _PermissionRow(
          label: copy.permissionLocation,
          granted: p?.fineLocationGranted ?? false,
          grantedText: copy.granted,
          notGrantedText: copy.notGranted,
        ),
        const SizedBox(height: 8),
        _PermissionRow(
          label: copy.permissionBackground,
          granted: p?.backgroundLocationGranted ?? false,
          grantedText: copy.granted,
          notGrantedText: copy.notGranted,
        ),
        const SizedBox(height: 16),
        PrimaryBtn(
          label: copy.grantPermissions,
          onPressed: _permissionsBusy || !(p?.available ?? false)
              ? null
              : _grantPermissions,
        ),
        const SizedBox(height: 10),
        Text(
          copy.permissionsHelp,
          style: TextStyle(fontSize: 12, color: colors.ink2, height: 1.5),
        ),
      ],
    );
  }

  Widget _codeSection(FamilyColors colors, NativeChildPairingCopy copy) {
    final canSubmit =
        FamilyDeviceApiClient.pairingCodePattern.hasMatch(_code.text) &&
        !_loading;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PrimaryBtn(
          label: copy.scanQrCode,
          onPressed: _loading ? null : _startScanner,
        ),
        const SizedBox(height: 8),
        Text(
          copy.codeFormatHint,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: colors.ink2),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                copy.orEnterManually,
                style: TextStyle(
                  color: colors.ink.withValues(alpha: 0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          copy.childIntro,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _code,
          autocorrect: false,
          enableSuggestions: false,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(
              FamilyDeviceApiClient.pairingCodeLength,
            ),
          ],
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 32,
            letterSpacing: 8,
            fontWeight: FontWeight.w900,
            color: colors.tealDeep,
          ),
          maxLength: FamilyDeviceApiClient.pairingCodeLength,
          decoration: InputDecoration(
            labelText: copy.pairingCodeLabel,
            hintText: copy.pairingCodeHint,
            border: const OutlineInputBorder(),
            counterText: '',
          ),
          onSubmitted: (_) => _claimAndStart(),
        ),
        const SizedBox(height: 12),
        PrimaryBtn(
          label: copy.enterChildMode,
          onPressed: canSubmit ? _claimAndStart : null,
        ),
      ],
    );
  }

  Widget _activatingSection(FamilyColors colors, NativeChildPairingCopy copy) {
    final label = switch (_phase) {
      _ActivatePhase.starting => copy.activatingProtection,
      _ => copy.verifyingCode,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.current, required this.labels});

  final _ChildStep current;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final index = _ChildStep.values.indexOf(current);
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          Expanded(
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < index
                        ? colors.mint
                        : (i == index ? colors.tealDeep : colors.surface),
                    border: Border.all(
                      color: i <= index ? Colors.transparent : colors.border,
                    ),
                  ),
                  child: i < index
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: i == index ? Colors.white : colors.ink2,
                          ),
                        ),
                ),
                const SizedBox(height: 6),
                Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: i == index ? FontWeight.w800 : FontWeight.w600,
                    color: i == index ? colors.ink : colors.ink2,
                  ),
                ),
              ],
            ),
          ),
          if (i < labels.length - 1)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.only(bottom: 22),
                color: i < index ? colors.mint : colors.border,
              ),
            ),
        ],
      ],
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.label,
    required this.granted,
    required this.grantedText,
    required this.notGrantedText,
  });

  final String label;
  final bool granted;
  final String grantedText;
  final String notGrantedText;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(
            granted ? Icons.check_circle : Icons.radio_button_unchecked,
            color: granted ? colors.mint : colors.ink2,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            granted ? grantedText : notGrantedText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: granted ? colors.mintInk : colors.ink2,
            ),
          ),
        ],
      ),
    );
  }
}
