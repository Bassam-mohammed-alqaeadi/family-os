import 'dart:convert';

import 'foundation_gate_configuration.dart';
import 'foundation_gate_http.dart';

/// Closed vocabulary of command types enabled in S0.
enum FoundationGateCommandType {
  lockNow('lock_now'),
  releaseLock('release_lock'),
  refreshPolicy('refresh_policy');

  const FoundationGateCommandType(this.wire);
  final String wire;
}

/// Lifecycle state of a command.
enum FoundationGateCommandState {
  accepted('accepted'),
  dispatched('dispatched'),
  received('received'),
  applied('applied'),
  limited('limited'),
  rejected('rejected'),
  expired('expired'),
  failed('failed');

  const FoundationGateCommandState(this.wire);
  final String wire;

  static FoundationGateCommandState? fromWire(String wire) {
    for (final s in values) {
      if (s.wire == wire) return s;
    }
    return null;
  }
}

enum FoundationGateCommandReceiptKind {
  applied('applied'),
  limited('limited'),
  failed('failed');

  const FoundationGateCommandReceiptKind(this.wire);
  final String wire;
}

class FoundationGateCommandReceipt {
  const FoundationGateCommandReceipt({
    required this.commandId,
    required this.receiptKind,
    required this.effectiveState,
    required this.observedAtDevice,
    required this.receivedAtServer,
    this.failureReason,
  });

  final String commandId;
  final FoundationGateCommandReceiptKind receiptKind;
  final Map<String, Object?> effectiveState;
  final DateTime observedAtDevice;
  final DateTime receivedAtServer;
  final String? failureReason;
}

class FoundationGateCommand {
  const FoundationGateCommand({
    required this.id,
    required this.familyId,
    required this.childId,
    required this.deviceId,
    required this.commandType,
    required this.idempotencyKey,
    required this.priority,
    required this.expiresAt,
    required this.state,
    required this.createdAt,
    this.policyId,
    this.policyVersion,
    this.payload = const {},
    this.actorMembershipId,
    this.dispatchedAt,
    this.receivedAt,
    this.appliedAt,
    this.failureReason,
    this.receipt,
  });

  final String id;
  final String familyId;
  final String childId;
  final String deviceId;
  final FoundationGateCommandType commandType;
  final String idempotencyKey;
  final int priority;
  final DateTime expiresAt;
  final FoundationGateCommandState state;
  final DateTime createdAt;
  final String? policyId;
  final int? policyVersion;
  final Map<String, Object?> payload;
  final String? actorMembershipId;
  final DateTime? dispatchedAt;
  final DateTime? receivedAt;
  final DateTime? appliedAt;
  final String? failureReason;
  final FoundationGateCommandReceipt? receipt;
}

/// Client for the S0 command-lifecycle endpoints.
///
/// Guardians create commands and list them; devices pull pending commands and
/// submit receipts. A late device never applies an expired command (the server
/// answers 410). Replaying an Idempotency-Key returns the existing row.
class FamilyCommandApiClient {
  FamilyCommandApiClient({
    required FoundationGateConfiguration configuration,
    required FoundationGateHttpTransport transport,
  })  : _configuration = configuration,
        _transport = transport;

  final FoundationGateConfiguration _configuration;
  final FoundationGateHttpTransport _transport;

  /// Guardian creates a command (lock_now / release_lock / refresh_policy).
  Future<FoundationGateCommand> createCommand({
    required String familyId,
    required String childId,
    required String deviceId,
    required FoundationGateCommandType commandType,
    required String idempotencyKey,
    required String idToken,
    Map<String, Object?> payload = const {},
    int priority = 100,
    int ttlSeconds = 120,
    String? policyId,
    int? policyVersion,
  }) async {
    if (!isFoundationGateUuid(familyId) ||
        !isFoundationGateUuid(childId) ||
        !isFoundationGateUuid(deviceId) ||
        !_validText(idempotencyKey, 128) ||
        priority < 0 || priority > 1000 ||
        ttlSeconds < 5 || ttlSeconds > 3600 ||
        (policyId != null && !isFoundationGateUuid(policyId))) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidInput,
      );
    }
    final uri = _configuration.familyChildDeviceCommandsUri(
      familyId,
      childId,
      deviceId,
    );
    final response = await _postBearer(
      uri,
      idToken,
      {
        'commandType': commandType.wire,
        'deviceId': deviceId,
        'payload': payload,
        'priority': priority,
        'ttlSeconds': ttlSeconds,
        if (policyId != null) 'policyId': policyId,
        if (policyVersion != null) 'policyVersion': policyVersion,
      },
      idempotencyKey: idempotencyKey,
    );
    switch (response.statusCode) {
      case 201:
        return _parseCommandResponse(response.body);
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
      case 410:
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

  /// Device pulls pending commands (marks them dispatched on the server).
  Future<List<FoundationGateCommand>> pullPending({
    required String deviceId,
    required String deviceCredential,
    int limit = 20,
  }) async {
    if (!isFoundationGateUuid(deviceId) ||
        !RegExp(r'^[A-Za-z0-9_-]{32,128}$').hasMatch(deviceCredential) ||
        limit < 1 || limit > 100) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidInput,
      );
    }
    final uri = _configuration.devicePendingCommandsUri(deviceId, limit: limit);
    final response = await _getDevice(uri, deviceCredential);
    switch (response.statusCode) {
      case 200:
        return _parsePendingResponse(response.body);
      case 401:
        throw const FoundationGateApiException(
          FoundationGateApiFailure.unauthenticated,
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

  /// Device submits a receipt for one command.
  Future<FoundationGateCommand> submitReceipt({
    required String deviceId,
    required String commandId,
    required FoundationGateCommandReceiptKind receiptKind,
    required DateTime observedAtDevice,
    required String deviceCredential,
    required String idempotencyKey,
    Map<String, Object?> effectiveState = const {},
    String? failureReason,
  }) async {
    if (!isFoundationGateUuid(deviceId) ||
        !isFoundationGateUuid(commandId) ||
        !RegExp(r'^[A-Za-z0-9_-]{32,128}$').hasMatch(deviceCredential) ||
        !_validText(idempotencyKey, 128) ||
        (receiptKind == FoundationGateCommandReceiptKind.failed &&
            (failureReason == null || failureReason.trim().isEmpty))) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidInput,
      );
    }
    final uri = _configuration.deviceCommandReceiptsUri(deviceId);
    final response = await _postDevice(
      uri,
      deviceCredential,
      {
        'commandId': commandId,
        'receiptKind': receiptKind.wire,
        'effectiveState': effectiveState,
        'observedAtDevice': observedAtDevice.toUtc().toIso8601String(),
        if (failureReason != null) 'failureReason': failureReason,
      },
      idempotencyKey: idempotencyKey,
    );
    switch (response.statusCode) {
      case 200:
        return _parseReceiptSubmitResponse(response.body);
      case 400:
        throw const FoundationGateApiException(
          FoundationGateApiFailure.invalidInput,
        );
      case 401:
        throw const FoundationGateApiException(
          FoundationGateApiFailure.unauthenticated,
        );
      case 404:
        throw const FoundationGateApiException(
          FoundationGateApiFailure.notFound,
        );
      case 410:
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

  /// Guardian lists commands for a family.
  Future<List<FoundationGateCommand>> listForFamily({
    required String familyId,
    required String idToken,
    int limit = 50,
    FoundationGateCommandState? state,
    String? childId,
    String? deviceId,
  }) async {
    if (!isFoundationGateUuid(familyId) || limit < 1 || limit > 200) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidInput,
      );
    }
    final uri = _configuration.familyCommandsUri(
      familyId,
      limit: limit,
      state: state?.wire,
      childId: childId,
      deviceId: deviceId,
    );
    final response = await _getBearer(uri, idToken);
    switch (response.statusCode) {
      case 200:
        return _parseCommandList(response.body);
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

  // ── HTTP ─────────────────────────────────────────────────────────────

  Future<FoundationGateHttpResponse> _getBearer(Uri uri, String idToken) async {
    try {
      return await _transport.get(uri, headers: _bearerHeaders(idToken));
    } catch (_) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.networkUnavailable,
      );
    }
  }

  Future<FoundationGateHttpResponse> _getDevice(
      Uri uri, String deviceCredential) async {
    try {
      return await _transport.get(uri, headers: _deviceHeaders(deviceCredential));
    } catch (_) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.networkUnavailable,
      );
    }
  }

  Future<FoundationGateHttpResponse> _postBearer(
    Uri uri,
    String idToken,
    Map<String, Object> body, {
    required String idempotencyKey,
  }) async {
    try {
      return await _transport.post(
        uri,
        headers: {
          ..._bearerHeaders(idToken),
          'content-type': 'application/json',
          'idempotency-key': idempotencyKey,
        },
        body: jsonEncode(body),
      );
    } catch (_) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.networkUnavailable,
      );
    }
  }

  Future<FoundationGateHttpResponse> _postDevice(
    Uri uri,
    String deviceCredential,
    Map<String, Object> body, {
    required String idempotencyKey,
  }) async {
    try {
      return await _transport.post(
        uri,
        headers: {
          ..._deviceHeaders(deviceCredential),
          'content-type': 'application/json',
          'idempotency-key': idempotencyKey,
        },
        body: jsonEncode(body),
      );
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

  Map<String, String> _deviceHeaders(String credential) => {
        'accept': 'application/json',
        'authorization': 'Device $credential',
      };

  // ── Parsing ─────────────────────────────────────────────────────────

  FoundationGateCommand _parseCommandResponse(String body) {
    final decoded = jsonDecode(body) as Map<String, Object?>;
    return _parseCommand(decoded['command'] as Map<String, Object?>);
  }

  List<FoundationGateCommand> _parsePendingResponse(String body) {
    final decoded = jsonDecode(body) as Map<String, Object?>;
    final list = decoded['commands'] as List<Object?>;
    return list
        .map((c) => _parseCommand(c as Map<String, Object?>))
        .toList(growable: false);
  }

  FoundationGateCommand _parseReceiptSubmitResponse(String body) {
    final decoded = jsonDecode(body) as Map<String, Object?>;
    return _parseCommand(decoded['command'] as Map<String, Object?>);
  }

  List<FoundationGateCommand> _parseCommandList(String body) {
    final decoded = jsonDecode(body) as Map<String, Object?>;
    final list = decoded['commands'] as List<Object?>;
    return list
        .map((c) => _parseCommand(c as Map<String, Object?>))
        .toList(growable: false);
  }

  FoundationGateCommand _parseCommand(Map<String, Object?> m) {
    final commandType = _parseCommandType(m['commandType'] as String);
    final state = FoundationGateCommandState.fromWire(m['state'] as String);
    if (commandType == null || state == null) throw const FormatException();
    final createdAt = _parseDate(m['createdAt']);
    final expiresAt = _parseDate(m['expiresAt']);
    if (createdAt == null || expiresAt == null) throw const FormatException();
    final rawReceipt = m['receipt'];
    return FoundationGateCommand(
      id: m['id'] as String,
      familyId: m['familyId'] as String,
      childId: m['childId'] as String,
      deviceId: m['deviceId'] as String,
      commandType: commandType,
      idempotencyKey: m['idempotencyKey'] as String,
      priority: (m['priority'] as num).toInt(),
      expiresAt: expiresAt,
      state: state,
      createdAt: createdAt,
      policyId: m['policyId'] as String?,
      policyVersion: (m['policyVersion'] as num?)?.toInt(),
      payload: (m['payload'] as Map<String, Object?>?) ?? const {},
      actorMembershipId: m['actorMembershipId'] as String?,
      dispatchedAt: _parseDate(m['dispatchedAt']),
      receivedAt: _parseDate(m['receivedAt']),
      appliedAt: _parseDate(m['appliedAt']),
      failureReason: m['failureReason'] as String?,
      receipt: rawReceipt is Map<String, Object?>
          ? _parseReceipt(rawReceipt)
          : null,
    );
  }

  FoundationGateCommandReceipt _parseReceipt(Map<String, Object?> m) {
    final kind = FoundationGateCommandReceiptKind.values
        .where((k) => k.wire == m['receiptKind'])
        .cast<FoundationGateCommandReceiptKind?>()
        .firstWhere((_) => true, orElse: () => null);
    if (kind == null) throw const FormatException();
    final observed = _parseDate(m['observedAtDevice']);
    final received = _parseDate(m['receivedAtServer']);
    if (observed == null || received == null) throw const FormatException();
    return FoundationGateCommandReceipt(
      commandId: m['commandId'] as String,
      receiptKind: kind,
      effectiveState:
          (m['effectiveState'] as Map<String, Object?>?) ?? const {},
      observedAtDevice: observed,
      receivedAtServer: received,
      failureReason: m['failureReason'] as String?,
    );
  }

  FoundationGateCommandType? _parseCommandType(String wire) {
    for (final t in FoundationGateCommandType.values) {
      if (t.wire == wire) return t;
    }
    return null;
  }

  DateTime? _parseDate(Object? value) {
    if (value == null) return null;
    if (value is! String) return null;
    return DateTime.tryParse(value)?.toUtc();
  }

  bool _validText(String value, int maxLength) =>
      value.trim().isNotEmpty &&
      value.trim().length <= maxLength &&
      !RegExp(r'[\u0000-\u001F\u007F]').hasMatch(value);
}
