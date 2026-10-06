import 'dart:convert';

import 'foundation_gate_configuration.dart';
import 'foundation_gate_http.dart';
import 'foundation_gate_models.dart';

/// Server representation of one linked child device and its latest known fact.
///
/// This is deliberately not a historical location stream. A nullable telemetry
/// value means the device has not supplied that fact through Phase 1 yet.
class FoundationGateFamilyDevice {
  const FoundationGateFamilyDevice({
    required this.id,
    required this.childId,
    required this.deviceLabel,
    required this.batteryLevel,
    required this.batteryStatus,
    required this.locationLat,
    required this.locationLng,
    required this.locationLabel,
    required this.lastSeenAt,
    required this.linkedAt,
    required this.version,
  });

  final String id;
  final String childId;
  final String deviceLabel;
  final int? batteryLevel;
  final String? batteryStatus;
  final double? locationLat;
  final double? locationLng;
  final String? locationLabel;
  final DateTime? lastSeenAt;
  final DateTime linkedAt;
  final int version;
}

/// A one-time server-issued child-device pairing capability.
///
/// The code is deliberately held in widget memory only. The server stores only
/// its digest and invalidates it after a successful claim or expiry.
class FoundationGateDevicePairing {
  const FoundationGateDevicePairing({
    required this.id,
    required this.childId,
    required this.deviceLabel,
    required this.pairingCode,
    required this.expiresAt,
  });

  final String id;
  final String childId;
  final String deviceLabel;
  final String pairingCode;
  final DateTime expiresAt;
}

/// Returned once to the child-device hand-off. Flutter passes the credential
/// straight to Android Keystore storage and does not persist it itself.
enum FoundationGateDevicePairingCreateFailure {
  sessionInvalid,
  emailVerificationRequired,
  accessDenied,
  invalidInput,
  childNotFound,
  pairingCodeNotReplayable,
  conflict,
  serviceUnavailable,
  networkUnavailable,
  unavailable,
}

/// A safe, pairing-specific API rejection.
///
/// The server's human-readable response is deliberately not retained: only
/// reviewed machine outcomes may cross into UI control flow.
class FoundationGateDevicePairingCreateException implements Exception {
  const FoundationGateDevicePairingCreateException(this.failure);

  final FoundationGateDevicePairingCreateFailure failure;
}

class FoundationGateDevicePairingCreateResult {
  const FoundationGateDevicePairingCreateResult.created(this.pairing)
    : failure = null;

  const FoundationGateDevicePairingCreateResult.failed(this.failure)
    : pairing = null;

  final FoundationGateDevicePairing? pairing;
  final FoundationGateDevicePairingCreateFailure? failure;

  bool get isCreated => pairing != null;
}

class FoundationGateClaimedDevice {
  const FoundationGateClaimedDevice({
    required this.device,
    required this.deviceCredential,
  });

  final FoundationGateFamilyDevice device;
  final String deviceCredential;
}

/// Narrow client for device telemetry and server-authoritative native pairing.
///
/// Guardian bearer writes remain a transitional support path. Child-device
/// telemetry is authorized by the separate device-scoped credential returned
/// only after a successful one-time pairing claim.
class FamilyDeviceApiClient {
  FamilyDeviceApiClient({
    required FoundationGateConfiguration configuration,
    required FoundationGateHttpTransport transport,
  }) : _configuration = configuration,
       _transport = transport;

  final FoundationGateConfiguration _configuration;
  final FoundationGateHttpTransport _transport;

  Future<List<FoundationGateFamilyDevice>> list({
    required String familyId,
    required String idToken,
  }) async {
    final uri = _familyDevicesUri(familyId);
    final response = await _get(uri, idToken);
    switch (response.statusCode) {
      case 200:
        return _parseDeviceList(response.body);
      case 401:
        throw const FoundationGateApiException(
          FoundationGateApiFailure.unauthenticated,
        );
      case 403:
        throw const FoundationGateApiException(
          FoundationGateApiFailure.accessDenied,
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

  Future<FoundationGateFamilyDevice> register({
    required String familyId,
    required String childId,
    required String deviceLabel,
    required String idempotencyKey,
    required String idToken,
  }) async {
    if (!isFoundationGateUuid(childId) ||
        !_validText(deviceLabel, 80) ||
        !_validText(idempotencyKey, 128)) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidInput,
      );
    }
    final response = await _post(
      _configuration.familyChildDevicesUri(familyId, childId),
      idToken,
      {'deviceLabel': deviceLabel.trim()},
      idempotencyKey: idempotencyKey,
    );
    switch (response.statusCode) {
      case 201:
        return _parseDeviceResponse(response.body);
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
          FoundationGateApiFailure.invalidResponse,
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

  Future<FoundationGateDevicePairing> createPairing({
    required String familyId,
    required String childId,
    required String deviceLabel,
    required String idempotencyKey,
    required String idToken,
  }) async {
    if (!isFoundationGateUuid(childId) ||
        !_validText(deviceLabel, 80) ||
        !_validText(idempotencyKey, 128)) {
      throw const FoundationGateDevicePairingCreateException(
        FoundationGateDevicePairingCreateFailure.invalidInput,
      );
    }
    Uri uri;
    try {
      uri = _configuration.familyChildDevicePairingsUri(familyId, childId);
    } on ArgumentError {
      throw const FoundationGateDevicePairingCreateException(
        FoundationGateDevicePairingCreateFailure.invalidInput,
      );
    }
    final response = await _post(uri, idToken, {
      'deviceLabel': deviceLabel.trim(),
    }, idempotencyKey: idempotencyKey);
    switch (response.statusCode) {
      case 201:
        return _parsePairing(response.body);
      case 400:
        throw const FoundationGateDevicePairingCreateException(
          FoundationGateDevicePairingCreateFailure.invalidInput,
        );
      case 401:
        throw const FoundationGateDevicePairingCreateException(
          FoundationGateDevicePairingCreateFailure.sessionInvalid,
        );
      case 403:
        throw FoundationGateDevicePairingCreateException(
          _hasErrorCode(response.body, 'email_verification_required')
              ? FoundationGateDevicePairingCreateFailure
                    .emailVerificationRequired
              : FoundationGateDevicePairingCreateFailure.accessDenied,
        );
      case 404:
        throw FoundationGateDevicePairingCreateException(
          _hasErrorCode(response.body, 'family_child_not_found') ||
                  _hasErrorCode(response.body, 'family_not_found')
              ? FoundationGateDevicePairingCreateFailure.childNotFound
              : FoundationGateDevicePairingCreateFailure.unavailable,
        );
      case 409:
        throw FoundationGateDevicePairingCreateException(
          _hasErrorCode(response.body, 'pairing_code_not_replayable')
              ? FoundationGateDevicePairingCreateFailure
                    .pairingCodeNotReplayable
              : FoundationGateDevicePairingCreateFailure.conflict,
        );
      case 429:
      case 500:
      case 502:
      case 503:
      case 504:
        throw const FoundationGateDevicePairingCreateException(
          FoundationGateDevicePairingCreateFailure.serviceUnavailable,
        );
      default:
        throw const FoundationGateDevicePairingCreateException(
          FoundationGateDevicePairingCreateFailure.unavailable,
        );
    }
  }

  /// Server contract (backend migration 009): pairing codes are exactly six
  /// decimal digits, single-use, and expire ten minutes after issue.
  static final RegExp pairingCodePattern = RegExp(r'^[0-9]{6}$');
  static const int pairingCodeLength = 6;

  Future<FoundationGateClaimedDevice> claimPairing({
    required String pairingCode,
  }) async {
    if (!pairingCodePattern.hasMatch(pairingCode)) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidInput,
      );
    }
    final response = await _postUnauthenticated(
      _configuration.devicePairingClaimUri,
      {'pairingCode': pairingCode},
    );
    switch (response.statusCode) {
      case 201:
        return _parseClaimedDevice(response.body);
      case 400:
        throw const FoundationGateApiException(
          FoundationGateApiFailure.invalidInput,
        );
      case 429:
        // Brute-force guard: 5 failed claims per 10 minutes per peer.
        throw const FoundationGateApiException(
          FoundationGateApiFailure.tooManyAttempts,
        );
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

  Future<FoundationGateFamilyDevice> ingestTelemetry({
    required String deviceId,
    required int batteryLevel,
    required String batteryStatus,
    required double locationLat,
    required double locationLng,
    required String locationLabel,
    required String idToken,
  }) async {
    if (!isFoundationGateUuid(deviceId) ||
        batteryLevel < 0 ||
        batteryLevel > 100 ||
        (batteryStatus != 'charging' && batteryStatus != 'unplugged') ||
        locationLat < -90 ||
        locationLat > 90 ||
        locationLng < -180 ||
        locationLng > 180 ||
        !_validText(locationLabel, 160)) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidInput,
      );
    }
    final response =
        await _post(_configuration.deviceTelemetryUri(deviceId), idToken, {
          'batteryLevel': batteryLevel,
          'batteryStatus': batteryStatus,
          'locationLat': locationLat,
          'locationLng': locationLng,
          'locationLabel': locationLabel.trim(),
        });
    switch (response.statusCode) {
      case 200:
        return _parseDeviceResponse(response.body);
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
          FoundationGateApiFailure.invalidResponse,
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

  Uri _familyDevicesUri(String familyId) {
    try {
      return _configuration.familyDevicesUri(familyId);
    } on ArgumentError {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      );
    }
  }

  Future<FoundationGateHttpResponse> _get(Uri uri, String idToken) async {
    try {
      return await _transport.get(uri, headers: _headers(idToken));
    } on FoundationGateApiException {
      rethrow;
    } catch (_) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.networkUnavailable,
      );
    }
  }

  Future<FoundationGateHttpResponse> _postUnauthenticated(
    Uri uri,
    Map<String, Object> body,
  ) async {
    try {
      return await _transport.post(
        uri,
        headers: const {
          'accept': 'application/json',
          'content-type': 'application/json',
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

  Future<FoundationGateHttpResponse> _post(
    Uri uri,
    String idToken,
    Map<String, Object> body, {
    String? idempotencyKey,
  }) async {
    try {
      return await _transport.post(
        uri,
        headers: {
          ..._headers(idToken),
          'content-type': 'application/json',
          if (idempotencyKey != null) 'idempotency-key': idempotencyKey,
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

  Map<String, String> _headers(String idToken) => {
    'accept': 'application/json',
    'authorization': 'Bearer $idToken',
  };

  List<FoundationGateFamilyDevice> _parseDeviceList(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, Object?> || decoded.keys.length != 1) {
        throw const FormatException();
      }
      final rawDevices = decoded['devices'];
      if (rawDevices is! List<Object?>) throw const FormatException();
      return List.unmodifiable(rawDevices.map(_parseDevice));
    } catch (_) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      );
    }
  }

  FoundationGateDevicePairing _parsePairing(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, Object?> || decoded.keys.length != 1) {
        throw const FormatException();
      }
      final pairing = decoded['pairing'];
      if (pairing is! Map<String, Object?> || pairing.keys.length != 5) {
        throw const FormatException();
      }
      final id = pairing['id'];
      final childId = pairing['childId'];
      final deviceLabel = pairing['deviceLabel'];
      final pairingCode = pairing['pairingCode'];
      final expiresAt = pairing['expiresAt'];
      final parsedExpiry = expiresAt is String
          ? DateTime.tryParse(expiresAt)?.toUtc()
          : null;
      if (id is! String ||
          !isFoundationGateUuid(id) ||
          childId is! String ||
          !isFoundationGateUuid(childId) ||
          deviceLabel is! String ||
          !_validText(deviceLabel, 80) ||
          pairingCode is! String ||
          !pairingCodePattern.hasMatch(pairingCode) ||
          parsedExpiry == null) {
        throw const FormatException();
      }
      return FoundationGateDevicePairing(
        id: id,
        childId: childId,
        deviceLabel: deviceLabel,
        pairingCode: pairingCode,
        expiresAt: parsedExpiry,
      );
    } catch (_) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      );
    }
  }

  FoundationGateClaimedDevice _parseClaimedDevice(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, Object?> || decoded.keys.length != 2) {
        throw const FormatException();
      }
      final credential = decoded['deviceCredential'];
      if (credential is! String ||
          !RegExp(r'^[A-Za-z0-9_-]{32,128}$').hasMatch(credential)) {
        throw const FormatException();
      }
      return FoundationGateClaimedDevice(
        device: _parseDevice(decoded['device']),
        deviceCredential: credential,
      );
    } catch (_) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      );
    }
  }

  FoundationGateFamilyDevice _parseDeviceResponse(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, Object?> || decoded.keys.length != 1) {
        throw const FormatException();
      }
      return _parseDevice(decoded['device']);
    } catch (_) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      );
    }
  }

  FoundationGateFamilyDevice _parseDevice(Object? value) {
    if (value is! Map<String, Object?> || value.keys.length != 11) {
      throw const FormatException();
    }
    final id = value['id'];
    final childId = value['childId'];
    final deviceLabel = value['deviceLabel'];
    final batteryLevel = value['batteryLevel'];
    final batteryStatus = value['batteryStatus'];
    final locationLat = value['locationLat'];
    final locationLng = value['locationLng'];
    final locationLabel = value['locationLabel'];
    final lastSeenAt = value['lastSeenAt'];
    final linkedAt = value['linkedAt'];
    final version = value['version'];
    final parsedLastSeen = lastSeenAt is String
        ? DateTime.tryParse(lastSeenAt)?.toUtc()
        : null;
    final parsedLinkedAt = linkedAt is String
        ? DateTime.tryParse(linkedAt)?.toUtc()
        : null;
    final numericLat = locationLat is num ? locationLat.toDouble() : null;
    final numericLng = locationLng is num ? locationLng.toDouble() : null;
    if (id is! String ||
        !isFoundationGateUuid(id) ||
        childId is! String ||
        !isFoundationGateUuid(childId) ||
        deviceLabel is! String ||
        !_validText(deviceLabel, 80) ||
        (batteryLevel != null &&
            (batteryLevel is! int || batteryLevel < 0 || batteryLevel > 100)) ||
        (batteryStatus != null &&
            batteryStatus != 'charging' &&
            batteryStatus != 'unplugged') ||
        (numericLat != null && (numericLat < -90 || numericLat > 90)) ||
        (numericLng != null && (numericLng < -180 || numericLng > 180)) ||
        (locationLabel != null &&
            (locationLabel is! String || !_validText(locationLabel, 160))) ||
        (lastSeenAt != null && parsedLastSeen == null) ||
        parsedLinkedAt == null ||
        version is! int ||
        version < 1) {
      throw const FormatException();
    }
    return FoundationGateFamilyDevice(
      id: id,
      childId: childId,
      deviceLabel: deviceLabel,
      batteryLevel: batteryLevel as int?,
      batteryStatus: batteryStatus as String?,
      locationLat: numericLat,
      locationLng: numericLng,
      locationLabel: locationLabel as String?,
      lastSeenAt: parsedLastSeen,
      linkedAt: parsedLinkedAt,
      version: version,
    );
  }

  bool _hasErrorCode(String body, String expected) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, Object?>) return false;
      final error = decoded['error'];
      return error is Map<String, Object?> && error['code'] == expected;
    } catch (_) {
      return false;
    }
  }

  bool _validText(String value, int maxLength) =>
      value.trim().isNotEmpty &&
      value.trim().length <= maxLength &&
      !RegExp(r'[\u0000-\u001F\u007F]').hasMatch(value);
}
