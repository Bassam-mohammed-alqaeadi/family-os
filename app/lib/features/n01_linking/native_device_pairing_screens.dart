import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/app/child_device_mode.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
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

class _NativeParentPairingScreenState extends State<NativeParentPairingScreen> {
  final _label = TextEditingController();
  FoundationGateDevicePairing? _pairing;
  var _loading = false;
  String? _error;

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final copy = NativeChildPairingCopy.of(context);
    final childRaw = widget.childId?.trim();
    final deviceLabel = _label.text.trim();
    final runtime = AppScope.maybeOf(context);
    final familyId = runtime?.identity.value.familyId;
    final source = runtime?.devices;
    if (childRaw == null ||
        childRaw.isEmpty ||
        familyId == null ||
        source is! RemoteFamilyDeviceSource) {
      setState(() => _error = copy.parentAccessRequired);
      return;
    }
    if (deviceLabel.isEmpty) {
      setState(() => _error = copy.deviceNameRequired);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final pairing = await source.createPairing(
      familyId: familyId,
      childId: ChildId(childRaw),
      deviceLabel: deviceLabel,
      idempotencyKey: newFoundationGateIdempotencyKey(),
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _pairing = pairing;
      _error = pairing == null ? copy.pairingUnavailable : null;
    });
  }

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
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () =>
                    context.go('/scr-fat-002'), // Go to dashboard safely
              ),
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
            const SizedBox(height: 16),
            TextField(
              controller: _label,
              maxLength: 80,
              decoration: InputDecoration(
                labelText: copy.deviceNameLabel,
                hintText: copy.deviceNameHint,
                border: const OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...[
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
            PrimaryBtn(
              label: _loading ? copy.creatingPairing : copy.createPairing,
              onPressed: _loading ? null : _create,
            ),

            // ── QR Code + manual code display ─────────────────────────────
            if (pairing != null) ...[
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),

              // Title
              Text(
                copy.oneTimePairingCode,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                copy.pairingExpiresAt(pairing.expiresAt),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 20),

              // QR Code — child scans this with their phone camera
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
              const SizedBox(height: 20),

              // Divider between QR and manual code
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
              const SizedBox(height: 12),

              // Manual code — large, selectable, copyable
              Center(
                child: SelectableText(
                  _formatPairingCode(pairing.pairingCode),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    letterSpacing: 6,
                    fontWeight: FontWeight.w800,
                    color: colors.tealDeep,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: () => Clipboard.setData(
                    ClipboardData(text: pairing.pairingCode),
                  ),
                  icon: const Icon(Icons.copy_outlined, size: 18),
                  label: Text(copy.copyCode),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Formats "ABCDEF" → "ABC DEF" for readability.
  String _formatPairingCode(String raw) {
    if (raw.length == 6) return '${raw.substring(0, 3)} ${raw.substring(3)}';
    return raw;
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

class _ChildModePairingScreenState extends State<ChildModePairingScreen> {
  final _code = TextEditingController();
  var _loading = false;
  String? _message;
  NativeTelemetryStatus? _serviceStatus;

  // QR scanner state
  bool _showScanner = false;
  MobileScannerController? _scannerController;

  @override
  void initState() {
    super.initState();
    _refreshServiceStatus();
  }

  @override
  void dispose() {
    _code.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  Future<void> _refreshServiceStatus() async {
    final status = await NativeChildTelemetryBridge.status();
    if (mounted) setState(() => _serviceStatus = status);
  }

  FamilyDeviceApiClient? _client() {
    if (widget.apiClient != null) return widget.apiClient;
    const origin = String.fromEnvironment('FAMILY_OS_API_ORIGIN');
    if (origin.trim().isEmpty) return null;
    try {
      return FamilyDeviceApiClient(
        configuration: FoundationGateConfiguration.fromStagingApiOrigin(
          Uri.parse(origin),
        ),
        transport: PackageFoundationGateHttpTransport(),
      );
    } on Object {
      return null;
    }
  }

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
    if (raw != null && raw.isNotEmpty) {
      _stopScanner();
      _code.text = raw.trim();
      // Auto-submit after scanning
      _claimAndStart();
    }
  }

  Future<void> _claimAndStart() async {
    final copy = NativeChildPairingCopy.of(context);
    final client = _client();
    final pairingCode = _code.text.trim().replaceAll(' ', '');
    if (client == null || pairingCode.isEmpty) {
      setState(() => _message = copy.secureOriginAndCodeRequired);
      return;
    }
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      final permissions =
          await NativeChildTelemetryBridge.requestLocationPermissions();
      if (!permissions.available ||
          !permissions.fineLocationGranted ||
          !permissions.backgroundLocationGranted) {
        if (!mounted) return;
        setState(() => _message = copy.locationPermissionNotGranted);
        return;
      }
      final claimed = await client.claimPairing(pairingCode: pairingCode);
      const origin = String.fromEnvironment('FAMILY_OS_API_ORIGIN');
      final result = await NativeChildTelemetryBridge.configureAndStart(
        apiOrigin: origin,
        deviceId: claimed.device.id,
        deviceCredential: claimed.deviceCredential,
      );
      if (!mounted) return;
      if (!result.started) {
        setState(() => _message = copy.childModeStartFailed(result.reason));
        await _refreshServiceStatus();
        return;
      }
      // Pairing is real and the native service is running: this handset is
      // now the child's device. Remember that (UUIDs only — never the
      // credential), switch the in-app role and land on the child home.
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
    } on FoundationGateApiException {
      if (mounted) setState(() => _message = copy.pairingClaimFailed);
    } on Object {
      // Native bridge / platform failures must surface as an honest state
      // instead of an unhandled error; the credential (if any) stays in the
      // Keystore-backed store and is never echoed here.
      if (mounted) {
        setState(() => _message = copy.childModeStartFailed('unavailable'));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

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
          // Toggle between scanner and manual entry
          if (!_showScanner)
            IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              tooltip: copy.scanQrCode,
              onPressed: _loading ? null : _startScanner,
            )
          else
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
            : _buildManualEntry(colors, copy),
      ),
    );
  }

  Widget _buildScanner(FamilyColors colors, NativeChildPairingCopy copy) {
    return Stack(
      children: [
        // Full-screen camera preview
        MobileScanner(controller: _scannerController!, onDetect: _onQrDetected),

        // Scan frame overlay
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

        // Instruction text at the bottom
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

  Widget _buildManualEntry(FamilyColors colors, NativeChildPairingCopy copy) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Scan QR button — primary CTA
        OutlinedButton.icon(
          onPressed: _loading ? null : _startScanner,
          icon: const Icon(Icons.qr_code_scanner_outlined, size: 22),
          label: Text(copy.scanQrCode),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: BorderSide(color: colors.tealDeep, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Divider
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
        const SizedBox(height: 16),

        TextField(
          controller: _code,
          autocorrect: false,
          enableSuggestions: false,
          textCapitalization: TextCapitalization.characters,
          keyboardType: TextInputType.visiblePassword,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            letterSpacing: 6,
            fontWeight: FontWeight.w800,
            color: colors.tealDeep,
          ),
          maxLength: 10,
          decoration: InputDecoration(
            labelText: copy.pairingCodeLabel,
            hintText: copy.pairingCodeHint,
            border: const OutlineInputBorder(),
            counterText: '',
          ),
          onSubmitted: (_) => _claimAndStart(),
        ),
        if (_message != null) ...[
          const SizedBox(height: 12),
          Text(
            _message!,
            style: TextStyle(
              color: colors.ink,
              fontWeight: FontWeight.w700,
              height: 1.45,
            ),
          ),
        ],
        const SizedBox(height: 12),
        PrimaryBtn(
          label: _loading ? copy.settingUpChildMode : copy.enterChildMode,
          onPressed: _loading ? null : _claimAndStart,
        ),
        if (_serviceStatus?.running == true)
          TextButton.icon(
            onPressed: () async {
              final stopped = await NativeChildTelemetryBridge.stop();
              await _refreshServiceStatus();
              if (mounted) {
                setState(
                  () => _message = stopped
                      ? copy.childModeStopped
                      : copy.childModeStopFailed,
                );
              }
            },
            icon: const Icon(Icons.stop_circle_outlined),
            label: Text(copy.stopChildMode),
          ),
      ],
    );
  }
}
