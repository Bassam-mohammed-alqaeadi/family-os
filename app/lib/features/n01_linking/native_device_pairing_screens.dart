import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:family_os/core/design/components/primary_btn.dart';
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

/// Parent side of Phase 2 pairing. The code exists only in this widget's
/// memory and is backed by a server-side hashed, expiring one-time capability.
class NativeParentPairingScreen extends StatefulWidget {
  const NativeParentPairingScreen({super.key, this.childId});

  final String? childId;

  @override
  State<NativeParentPairingScreen> createState() => _NativeParentPairingScreenState();
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
    if (childRaw == null || childRaw.isEmpty || familyId == null || source is! RemoteFamilyDeviceSource) {
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
      appBar: AppBar(backgroundColor: colors.surface, title: Text(copy.parentTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              copy.parentIntro,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.5),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _label,
              maxLength: 80,
              decoration: InputDecoration(
                labelText: copy.deviceNameLabel,
                hintText: copy.deviceNameHint,
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: colors.coral, fontWeight: FontWeight.w700)),
            ],
            const SizedBox(height: 8),
            PrimaryBtn(
              label: _loading ? copy.creatingPairing : copy.createPairing,
              onPressed: _loading ? null : _create,
            ),
            if (pairing != null) ...[
              const SizedBox(height: 24),
              Text(copy.oneTimePairingCode, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              SelectableText(
                pairing.pairingCode,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, letterSpacing: 1.2, fontWeight: FontWeight.w800, color: colors.tealDeep),
              ),
              const SizedBox(height: 8),
              Text(copy.pairingExpiresAt(pairing.expiresAt)),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => Clipboard.setData(ClipboardData(text: pairing.pairingCode)),
                icon: const Icon(Icons.copy_outlined),
                label: Text(copy.copyCode),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Child-device hand-off. It accepts a real server pairing code, receives a
/// one-time device credential, passes it to Android Keystore storage, requests
/// actual OS permissions, and starts the native foreground service.
class ChildModePairingScreen extends StatefulWidget {
  const ChildModePairingScreen({super.key, this.apiClient});

  final FamilyDeviceApiClient? apiClient;

  @override
  State<ChildModePairingScreen> createState() => _ChildModePairingScreenState();
}

class _ChildModePairingScreenState extends State<ChildModePairingScreen> {
  final _code = TextEditingController();
  var _loading = false;
  String? _message;
  NativeTelemetryStatus? _serviceStatus;

  @override
  void initState() {
    super.initState();
    _refreshServiceStatus();
  }

  Future<void> _refreshServiceStatus() async {
    final status = await NativeChildTelemetryBridge.status();
    if (mounted) setState(() => _serviceStatus = status);
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  FamilyDeviceApiClient? _client() {
    if (widget.apiClient != null) return widget.apiClient;
    const origin = String.fromEnvironment('FAMILY_OS_API_ORIGIN');
    if (origin.trim().isEmpty) return null;
    try {
      return FamilyDeviceApiClient(
        configuration: FoundationGateConfiguration.fromStagingApiOrigin(Uri.parse(origin)),
        transport: PackageFoundationGateHttpTransport(),
      );
    } on Object {
      return null;
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
      final permissions = await NativeChildTelemetryBridge.requestLocationPermissions();
      if (!permissions.available || !permissions.fineLocationGranted || !permissions.backgroundLocationGranted) {
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
      setState(() => _message = result.started
          ? copy.childModeActive
          : copy.childModeStartFailed(result.reason));
      await _refreshServiceStatus();
    } on FoundationGateApiException {
      if (mounted) setState(() => _message = copy.pairingClaimFailed);
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
      appBar: AppBar(backgroundColor: colors.surface, title: Text(copy.childTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              copy.childIntro,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.5),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _code,
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: TextCapitalization.none,
              decoration: InputDecoration(labelText: copy.pairingCodeLabel, border: const OutlineInputBorder()),
            ),
            if (_message != null) ...[
              const SizedBox(height: 12),
              Text(_message!, style: TextStyle(color: colors.ink, fontWeight: FontWeight.w700, height: 1.45)),
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
                    setState(() => _message = stopped
                        ? copy.childModeStopped
                        : copy.childModeStopFailed);
                  }
                },
                icon: const Icon(Icons.stop_circle_outlined),
                label: Text(copy.stopChildMode),
              ),
          ],
        ),
      ),
    );
  }
}
