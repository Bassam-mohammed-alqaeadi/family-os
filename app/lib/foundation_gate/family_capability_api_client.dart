import 'dart:convert';

import 'foundation_gate_configuration.dart';
import 'foundation_gate_http.dart';
import 'foundation_gate_models.dart';

/// Closed vocabulary of capability keys a child's handset may report (S0 spine).
///
/// Only keys this slice actually ships are accepted; new keys are added by the
/// slice that introduces them, so a misspelling fails loudly instead of being
/// silently stored.
enum FoundationGateCapabilityKey {
  usageMetering('usage_metering'),
  appInventory('app_inventory'),
  appBlockOverlay('app_block_overlay'),
  accessibilityEnforcement('accessibility_enforcement'),
  instantLock('instant_lock'),
  webFilterVpn('web_filter_vpn'),
  backgroundLocation('background_location'),
  bootPersistence('boot_persistence'),
  pushDelivery('push_delivery'),
  batteryReporting('battery_reporting'),
  tamperSignals('tamper_signals');

  const FoundationGateCapabilityKey(this.wire);
  final String wire;

  static FoundationGateCapabilityKey? fromWire(String wire) {
    for (final key in values) {
      if (key.wire == wire) return key;
    }
    return null;
  }
}

/// Honest state of one capability on the device.
enum FoundationGateCapabilityState {
  confirmed('confirmed'),
  awaitingSetup('awaiting_setup'),
  permissionNeeded('permission_needed'),
  unsupported('unsupported'),
  revoked('revoked'),
  unknown('unknown');

  const FoundationGateCapabilityState(this.wire);
  final String wire;

  static FoundationGateCapabilityState? fromWire(String wire) {
    for (final state in values) {
      if (state.wire == wire) return state;
    }
    return null;
  }
}

/// One capability entry as returned by the server.
class FoundationGateCapabilityRecord {
  const FoundationGateCapabilityRecord({
    required this.capabilityKey,
    required this.state,
    required this.reportedAt,
    this.evidence,
    this.appVersion,
    this.osVersion,
    this.confirmedAt,
  });

  final FoundationGateCapabilityKey capabilityKey;
  final FoundationGateCapabilityState state;
  final DateTime reportedAt;
  final String? evidence;
  final String? appVersion;
  final String? osVersion;
  final DateTime? confirmedAt;
}

/// One device's capability map.
class FoundationGateDeviceCapabilities {
  const FoundationGateDeviceCapabilities({
    required this.deviceId,
    required this.capabilities,
  });

  final String deviceId;
  final Map<FoundationGateCapabilityKey, FoundationGateCapabilityRecord>
      capabilities;
}

/// Guardian-scoped response: capabilities grouped per device for one child.
class FoundationGateChildCapabilitiesView {
  const FoundationGateChildCapabilitiesView({
    required this.familyId,
    required this.childId,
    required this.devices,
  });

  final String familyId;
  final String childId;
  final List<FoundationGateDeviceCapabilities> devices;
}

/// Client for the S0 capability-ledger endpoints.
///
/// Two paths:
///   * [reportSnapshot] — device credential; the handset reports what it can do.
///   * [readForChild] — guardian bearer; what the honest state looks like now.
///
/// The handset decides the facts; UI renders them with `CapabilityHonestyBadge`,
/// never with a toggle that lies (R4 / Principle 2).
class FamilyCapabilityApiClient {
  FamilyCapabilityApiClient({
    required FoundationGateConfiguration configuration,
    required FoundationGateHttpTransport transport,
  })  : _configuration = configuration,
        _transport = transport;

  final FoundationGateConfiguration _configuration;
  final FoundationGateHttpTransport _transport;

  /// Report a capability snapshot from this device. Returns only entries whose
  /// state actually changed (heartbeat duplicates are not echoed).
  Future<List<FoundationGateCapabilityRecord>> reportSnapshot({
    required String deviceId,
    required List<FoundationGateCapabilitySnapshotEntry> entries,
    required String idempotencyKey,
    String? deviceCredential,
    String? idToken,
  }) async {
    if (!isFoundationGateUuid(deviceId) ||
        !_validText(idempotencyKey, 128) ||
        entries.isEmpty ||
        entries.length > 32 ||
        (deviceCredential == null && idToken == null) ||
        (deviceCredential != null &&
            !RegExp(r'^[A-Za-z0-9_-]{32,128}$').hasMatch(deviceCredential))) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidInput,
      );
    }
    final seen = <FoundationGateCapabilityKey>{};
    for (final e in entries) {
      if (!seen.add(e.capabilityKey)) {
        throw const FoundationGateApiException(
          FoundationGateApiFailure.invalidInput,
        );
      }
    }
    final uri = _configuration.deviceCapabilitiesUri(deviceId);
    final response = await _post(
      uri,
      {
        'capabilities': entries
            .map((e) => {
                  'capabilityKey': e.capabilityKey.wire,
                  'state': e.state.wire,
                  if (e.evidence != null) 'evidence': e.evidence,
                  if (e.confirmedAt != null)
                    'confirmedAt': e.confirmedAt!.toUtc().toIso8601String(),
                })
            .toList(),
      },
      idempotencyKey: idempotencyKey,
      idToken: idToken,
      deviceCredential: deviceCredential,
    );
    switch (response.statusCode) {
      case 201:
        return _parseSnapshotResponse(response.body);
      case 400:
        throw const FoundationGateApiException(
          FoundationGateApiFailure.invalidInput,
        );
      case 401:
        throw const FoundationGateApiException(
          FoundationGateApiFailure.unauthenticated,
        );
      case 403:
        throw const FoundationGateApiException(
          FoundationGateApiFailure.accessDenied,
        );
      case 404:
        throw const FoundationGateApiException(
          FoundationGateApiFailure.notFound,
        );
      case 409:
        throw const FoundationGateApiException(
          FoundationGateApiFailure.conflict,
        );
      case 429:
      case 503:
        throw const FoundationGateApiException(
          FoundationGateApiFailure.serviceUnavailable,
        );
      default:
        throw const FoundationGateApiException(
          FoundationGateApiFailure.invalidResponse,
        );
    }
  }

  Future<FoundationGateChildCapabilitiesView> readForChild({
    required String familyId,
    required String childId,
    required String idToken,
  }) async {
    if (!isFoundationGateUuid(familyId) || !isFoundationGateUuid(childId)) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidInput,
      );
    }
    final uri =
        _configuration.familyChildDeviceCapabilitiesUri(familyId, childId);
    final response = await _get(uri, idToken);
    switch (response.statusCode) {
      case 200:
        return _parseChildView(response.body);
      case 401:
        throw const FoundationGateApiException(
          FoundationGateApiFailure.unauthenticated,
        );
      case 403:
        throw const FoundationGateApiException(
          FoundationGateApiFailure.accessDenied,
        );
      case 404:
        throw const FoundationGateApiException(
          FoundationGateApiFailure.notFound,
        );
      case 429:
      case 503:
        throw const FoundationGateApiException(
          FoundationGateApiFailure.serviceUnavailable,
        );
      default:
        throw const FoundationGateApiException(
          FoundationGateApiFailure.invalidResponse,
        );
    }
  }

  // ── HTTP helpers ──────────────────────────────────────────────────────

  Future<FoundationGateHttpResponse> _get(Uri uri, String idToken) async {
    try {
      return await _transport.get(uri, headers: _bearerHeaders(idToken));
    } on FoundationGateApiException {
      rethrow;
    } catch (_) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.networkUnavailable,
      );
    }
  }

  Future<FoundationGateHttpResponse> _post(
    Uri uri,
    Map<String, Object> body, {
    required String idempotencyKey,
    String? idToken,
    String? deviceCredential,
  }) async {
    try {
      return await _transport.post(
        uri,
        headers: {
          'accept': 'application/json',
          'content-type': 'application/json',
          'idempotency-key': idempotencyKey,
          if (idToken != null) 'authorization': 'Bearer $idToken',
          if (deviceCredential != null)
            'authorization': 'Device $deviceCredential',
        },
        body: jsonEncode(body),
      );
    } on FoundationGateApiException {
      rethrow;
    } catch (_) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.networkUnavailable,
      );
    }
  }

  Map<String, String> _bearerHeaders(String idToken) => {
        'accept': 'application/json',
        'authorization': 'Bearer $idToken',
      };

  // ── Parsing ──────────────────────────────────────────────────────────

  List<FoundationGateCapabilityRecord> _parseSnapshotResponse(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, Object?>) throw const FormatException();
      final raw = decoded['capabilities'];
      if (raw is! List) throw const FormatException();
      return raw
          .map((v) => _parseRecord(v as Map<String, Object?>))
          .toList(growable: false);
    } catch (_) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      );
    }
  }

  FoundationGateChildCapabilitiesView _parseChildView(String body) {
    try {
      final decoded = jsonDecode(body) as Map<String, Object?>;
      final familyId = decoded['familyId'] as String;
      final childId = decoded['childId'] as String;
      final rawDevices = decoded['devices'] as List<Object?>;
      final devices = rawDevices.map((d) {
        final m = d as Map<String, Object?>;
        final deviceId = m['deviceId'] as String;
        final caps = m['capabilities'] as Map<String, Object?>;
        final parsed = <FoundationGateCapabilityKey,
            FoundationGateCapabilityRecord>{};
        for (final entry in caps.entries) {
          final key = FoundationGateCapabilityKey.fromWire(entry.key);
          if (key == null) continue;
          final rec = _parseRecord(entry.value as Map<String, Object?>);
          parsed[key] = rec;
        }
        return FoundationGateDeviceCapabilities(
          deviceId: deviceId,
          capabilities: parsed,
        );
      }).toList(growable: false);
      return FoundationGateChildCapabilitiesView(
        familyId: familyId,
        childId: childId,
        devices: devices,
      );
    } catch (_) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      );
    }
  }

  FoundationGateCapabilityRecord _parseRecord(Map<String, Object?> m) {
    final key = FoundationGateCapabilityKey.fromWire(m['capabilityKey'] as String);
    final state =
        FoundationGateCapabilityState.fromWire(m['state'] as String);
    if (key == null || state == null) throw const FormatException();
    final reportedAt = DateTime.tryParse(m['reportedAt'] as String)?.toUtc();
    if (reportedAt == null) throw const FormatException();
    final confirmedAtRaw = m['confirmedAt'];
    final confirmedAt = confirmedAtRaw is String
        ? DateTime.tryParse(confirmedAtRaw)?.toUtc()
        : null;
    return FoundationGateCapabilityRecord(
      capabilityKey: key,
      state: state,
      reportedAt: reportedAt,
      evidence: m['evidence'] as String?,
      appVersion: m['appVersion'] as String?,
      osVersion: m['osVersion'] as String?,
      confirmedAt: confirmedAt,
    );
  }

  bool _validText(String value, int maxLength) =>
      value.trim().isNotEmpty &&
      value.trim().length <= maxLength &&
      !RegExp(r'[\u0000-\u001F\u007F]').hasMatch(value);
}

/// One entry in a device snapshot, before transmission.
class FoundationGateCapabilitySnapshotEntry {
  const FoundationGateCapabilitySnapshotEntry({
    required this.capabilityKey,
    required this.state,
    this.evidence,
    this.confirmedAt,
  });

  final FoundationGateCapabilityKey capabilityKey;
  final FoundationGateCapabilityState state;
  final String? evidence;
  final DateTime? confirmedAt;
}
