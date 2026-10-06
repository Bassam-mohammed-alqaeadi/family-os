import 'dart:convert';

import 'foundation_gate_configuration.dart';
import 'foundation_gate_http.dart';
import 'foundation_gate_models.dart';
import 'device_lifecycle.dart';

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
class FoundationGateClaimedDevice {
  const FoundationGateClaimedDevice({
    required this.device,
    required this.deviceCredential,
  });

  final FoundationGateGuardianDevice device;
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

  Future<List<FoundationGateGuardianDevice>> list({
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

  Future<FoundationGateGuardianDevice> register({
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
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidInput,
      );
    }
    Uri uri;
    try {
      uri = _configuration.familyChildDevicePairingsUri(familyId, childId);
    } on ArgumentError {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidInput,
      );
    }
    final response = await _post(uri, idToken, {
      'deviceLabel': deviceLabel.trim(),
    }, idempotencyKey: idempotencyKey);
    switch (response.statusCode) {
      case 201:
        return _parsePairing(response.body);
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

  Future<FoundationGateClaimedDevice> claimPairing({
    required String pairingCode,
  }) async {
    if (!RegExp(r'^[A-Za-z0-9_-]{32,128}$').hasMatch(pairingCode)) {
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

  Future<FoundationGateGuardianDevice> ingestTelemetry({
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

  List<FoundationGateGuardianDevice> _parseDeviceList(String body) {
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
          !RegExp(r'^[A-Za-z0-9_-]{32,128}$').hasMatch(pairingCode) ||
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

  FoundationGateGuardianDevice _parseDeviceResponse(String body) {
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

  /// Parse one device from its lifecycle payload.
  ///
  /// The contract's own parser reads it, then this client adds the checks that belong to
  /// the wire rather than to the contract: a uuid identifier, coordinate ranges, and the
  /// two legal battery statuses. The previous version of this function also required the
  /// payload to carry exactly eleven keys, which made an additive server change - three
  /// lifecycle fields - look like a corrupt device. Which is exactly what happened when
  /// the lifecycle was added, so the key count is gone: a field the parser does not know
  /// is ignored, while a state it does not understand still drops the device rather than
  /// being rendered with a guessed meaning.
  FoundationGateGuardianDevice _parseDevice(Object? value) {
    final parsed = parseFoundationGateGuardianDevice(value);
    if (parsed == null) {
      throw const FormatException();
    }
    if (!isFoundationGateUuid(parsed.id) || !isFoundationGateUuid(parsed.childId)) {
      throw const FormatException();
    }
    if (parsed.batteryLevel != null &&
        (parsed.batteryLevel! < 0 || parsed.batteryLevel! > 100)) {
      throw const FormatException();
    }
    if (parsed.batteryStatus != null &&
        parsed.batteryStatus != 'charging' &&
        parsed.batteryStatus != 'unplugged') {
      throw const FormatException();
    }
    if (parsed.locationLabel != null && !_validText(parsed.locationLabel!, 160)) {
      throw const FormatException();
    }
    if (value is! Map<String, Object?>) {
      throw const FormatException();
    }
    final lat = value['locationLat'];
    final lng = value['locationLng'];
    if (lat is num && (lat < -90 || lat > 90)) {
      throw const FormatException();
    }
    if (lng is num && (lng < -180 || lng > 180)) {
      throw const FormatException();
    }
    return parsed;
  }

  bool _validText(String value, int maxLength) =>
      value.trim().isNotEmpty &&
      value.trim().length <= maxLength &&
      !RegExp(r'[\u0000-\u001F\u007F]').hasMatch(value);
}
