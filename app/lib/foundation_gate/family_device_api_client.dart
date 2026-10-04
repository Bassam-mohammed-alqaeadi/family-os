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

/// Narrow client for the device telemetry Phase 1 endpoints.
///
/// The current write calls support only the build-time-gated developer
/// simulation. They do not establish a device credential or claim that a child
/// handset sent the update.
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
        throw const FoundationGateApiException(FoundationGateApiFailure.unauthenticated);
      case 403:
        throw const FoundationGateApiException(FoundationGateApiFailure.accessDenied);
      case 429:
      case 503:
        throw const FoundationGateApiException(FoundationGateApiFailure.serviceUnavailable);
      default:
        throw const FoundationGateApiException(FoundationGateApiFailure.invalidResponse);
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
      throw const FoundationGateApiException(FoundationGateApiFailure.invalidInput);
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
        throw const FoundationGateApiException(FoundationGateApiFailure.invalidInput);
      case 401:
        throw const FoundationGateApiException(FoundationGateApiFailure.unauthenticated);
      case 403:
        throw const FoundationGateApiException(FoundationGateApiFailure.accessDenied);
      case 404:
        throw const FoundationGateApiException(FoundationGateApiFailure.invalidResponse);
      case 409:
        throw const FoundationGateApiException(FoundationGateApiFailure.conflict);
      case 429:
      case 503:
        throw const FoundationGateApiException(FoundationGateApiFailure.serviceUnavailable);
      default:
        throw const FoundationGateApiException(FoundationGateApiFailure.invalidResponse);
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
      throw const FoundationGateApiException(FoundationGateApiFailure.invalidInput);
    }
    final response = await _post(
      _configuration.deviceTelemetryUri(deviceId),
      idToken,
      {
        'batteryLevel': batteryLevel,
        'batteryStatus': batteryStatus,
        'locationLat': locationLat,
        'locationLng': locationLng,
        'locationLabel': locationLabel.trim(),
      },
    );
    switch (response.statusCode) {
      case 200:
        return _parseDeviceResponse(response.body);
      case 400:
        throw const FoundationGateApiException(FoundationGateApiFailure.invalidInput);
      case 401:
        throw const FoundationGateApiException(FoundationGateApiFailure.unauthenticated);
      case 403:
        throw const FoundationGateApiException(FoundationGateApiFailure.accessDenied);
      case 404:
        throw const FoundationGateApiException(FoundationGateApiFailure.invalidResponse);
      case 429:
      case 503:
        throw const FoundationGateApiException(FoundationGateApiFailure.serviceUnavailable);
      default:
        throw const FoundationGateApiException(FoundationGateApiFailure.invalidResponse);
    }
  }

  Uri _familyDevicesUri(String familyId) {
    try {
      return _configuration.familyDevicesUri(familyId);
    } on ArgumentError {
      throw const FoundationGateApiException(FoundationGateApiFailure.invalidResponse);
    }
  }

  Future<FoundationGateHttpResponse> _get(Uri uri, String idToken) async {
    try {
      return await _transport.get(uri, headers: _headers(idToken));
    } on FoundationGateApiException {
      rethrow;
    } catch (_) {
      throw const FoundationGateApiException(FoundationGateApiFailure.networkUnavailable);
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
      throw const FoundationGateApiException(FoundationGateApiFailure.networkUnavailable);
    }
  }

  Map<String, String> _headers(String idToken) => {
    'accept': 'application/json',
    'authorization': 'Bearer $idToken',
  };

  List<FoundationGateFamilyDevice> _parseDeviceList(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, Object?> || decoded.keys.length != 1) throw const FormatException();
      final rawDevices = decoded['devices'];
      if (rawDevices is! List<Object?>) throw const FormatException();
      return List.unmodifiable(rawDevices.map(_parseDevice));
    } catch (_) {
      throw const FoundationGateApiException(FoundationGateApiFailure.invalidResponse);
    }
  }

  FoundationGateFamilyDevice _parseDeviceResponse(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, Object?> || decoded.keys.length != 1) throw const FormatException();
      return _parseDevice(decoded['device']);
    } catch (_) {
      throw const FoundationGateApiException(FoundationGateApiFailure.invalidResponse);
    }
  }

  FoundationGateFamilyDevice _parseDevice(Object? value) {
    if (value is! Map<String, Object?> || value.keys.length != 11) throw const FormatException();
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
    final parsedLastSeen = lastSeenAt is String ? DateTime.tryParse(lastSeenAt)?.toUtc() : null;
    final parsedLinkedAt = linkedAt is String ? DateTime.tryParse(linkedAt)?.toUtc() : null;
    final numericLat = locationLat is num ? locationLat.toDouble() : null;
    final numericLng = locationLng is num ? locationLng.toDouble() : null;
    if (id is! String || !isFoundationGateUuid(id) ||
        childId is! String || !isFoundationGateUuid(childId) ||
        deviceLabel is! String || !_validText(deviceLabel, 80) ||
        (batteryLevel != null && (batteryLevel is! int || batteryLevel < 0 || batteryLevel > 100)) ||
        (batteryStatus != null && batteryStatus != 'charging' && batteryStatus != 'unplugged') ||
        (numericLat != null && (numericLat < -90 || numericLat > 90)) ||
        (numericLng != null && (numericLng < -180 || numericLng > 180)) ||
        (locationLabel != null && (locationLabel is! String || !_validText(locationLabel, 160))) ||
        (lastSeenAt != null && parsedLastSeen == null) ||
        parsedLinkedAt == null || version is! int || version < 1) {
      throw const FormatException();
    }
    return FoundationGateFamilyDevice(
      id: id, childId: childId, deviceLabel: deviceLabel,
      batteryLevel: batteryLevel as int?, batteryStatus: batteryStatus as String?,
      locationLat: numericLat, locationLng: numericLng,
      locationLabel: locationLabel as String?, lastSeenAt: parsedLastSeen,
      linkedAt: parsedLinkedAt, version: version,
    );
  }

  bool _validText(String value, int maxLength) =>
      value.trim().isNotEmpty && value.trim().length <= maxLength &&
      !RegExp(r'[\u0000-\u001F\u007F]').hasMatch(value);
}
