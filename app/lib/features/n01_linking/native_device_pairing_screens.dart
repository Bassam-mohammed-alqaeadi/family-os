import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/runtime/app_scope.dart';
import 'package:family_os/foundation_gate/family_device_api_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_configuration.dart';
import 'package:family_os/foundation_gate/foundation_gate_http.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';
import 'package:family_os/foundation_gate/main_app_foundation_runtime.dart';
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
    final childRaw = widget.childId?.trim();
    final deviceLabel = _label.text.trim();
    final runtime = AppScope.maybeOf(context);
    final familyId = runtime?.identity.value.familyId;
    final source = runtime?.devices;
    if (childRaw == null || childRaw.isEmpty || familyId == null || source is! RemoteFamilyDeviceSource) {
      setState(() => _error = 'Pairing is available only to the authenticated primary guardian.');
      return;
    }
    if (deviceLabel.isEmpty) {
      setState(() => _error = 'Enter this child device name first.');
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
      _error = pairing == null ? 'The server could not create a pairing code.' : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final pairing = _pairing;
    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(backgroundColor: colors.surface, title: const Text('Pair child device')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Create a one-time pairing code on the parent device. Give it to the child device only while you are present.',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.5),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _label,
              maxLength: 80,
              decoration: const InputDecoration(
                labelText: 'Child device name',
                hintText: 'For example: Amani’s Android phone',
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: colors.coral, fontWeight: FontWeight.w700)),
            ],
            const SizedBox(height: 8),
            PrimaryBtn(
              label: _loading ? 'Creating secure pairing code…' : 'Create pairing code',
              onPressed: _loading ? null : _create,
            ),
            if (pairing != null) ...[
              const SizedBox(height: 24),
              const Text('One-time child pairing code', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              SelectableText(
                pairing.pairingCode,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, letterSpacing: 1.2, fontWeight: FontWeight.w800, color: colors.tealDeep),
              ),
              const SizedBox(height: 8),
              Text('Expires at ${pairing.expiresAt.toLocal()}. It cannot be used again after a successful child-device claim.'),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => Clipboard.setData(ClipboardData(text: pairing.pairingCode)),
                icon: const Icon(Icons.copy_outlined),
                label: const Text('Copy code'),
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
    final client = _client();
    final pairingCode = _code.text.trim().replaceAll(' ', '');
    if (client == null || pairingCode.isEmpty) {
      setState(() => _message = 'A secure API origin and pairing code are required.');
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
        setState(() => _message = 'Location access was not granted. The pairing code remains unused.');
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
          ? 'Child Mode is active. This device now sends real battery and location telemetry.'
          : 'Child Mode could not start: ${result.reason}');
      await _refreshServiceStatus();
    } on FoundationGateApiException {
      if (mounted) setState(() => _message = 'The pairing code is invalid, expired, already used, or the server is unavailable.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(backgroundColor: colors.surface, title: const Text('Enter Child Mode')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Ask the parent to create a one-time pairing code. To send the device’s real location while this app is not open, Android will ask for precise and background location access. After acceptance, Child Mode starts an always-visible foreground service that you can stop on this device.',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.5),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _code,
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: TextCapitalization.none,
              decoration: const InputDecoration(labelText: 'One-time pairing code', border: OutlineInputBorder()),
            ),
            if (_message != null) ...[
              const SizedBox(height: 12),
              Text(_message!, style: TextStyle(color: colors.ink, fontWeight: FontWeight.w700, height: 1.45)),
            ],
            const SizedBox(height: 12),
            PrimaryBtn(
              label: _loading ? 'Setting up Child Mode…' : 'Enter Child Mode',
              onPressed: _loading ? null : _claimAndStart,
            ),
            if (_serviceStatus?.running == true)
              TextButton.icon(
                onPressed: () async {
                  final stopped = await NativeChildTelemetryBridge.stop();
                  await _refreshServiceStatus();
                  if (mounted) {
                    setState(() => _message = stopped
                        ? 'Child Mode foreground service stopped on this device.'
                        : 'Child Mode service could not be stopped.');
                  }
                },
                icon: const Icon(Icons.stop_circle_outlined),
                label: const Text('Stop Child Mode on this device'),
              ),
          ],
        ),
      ),
    );
  }
}
