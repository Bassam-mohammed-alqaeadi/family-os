import 'dart:convert';

import 'package:family_os/foundation_gate/foundation_gate_configuration.dart';
import 'package:family_os/foundation_gate/foundation_gate_http.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';

/// One reading of the child handset's own screen-time state (S3-E1).
///
/// Read-only by construction: nothing in this class mutates server state.
final class DeviceScreenTimeReading {
  const DeviceScreenTimeReading({
    required this.remainingMinutes,
    required this.countableUsedMinutes,
    required this.grantedMinutes,
    required this.capMinutes,
    required this.kind,
    required this.reasonCode,
    required this.earnedMinutesExtendLimit,
    required this.serverDate,
  });

  /// Remaining minutes under the daily cap, or null when no daily limit is active.
  /// Never coerced to zero when absent.
  final int? remainingMinutes;

  /// Measured countable usage today in minutes.
  final int countableUsedMinutes;

  /// Extra minutes granted by guardians today.
  final int grantedMinutes;

  /// The daily cap in minutes, or null when no limit is configured.
  final int? capMinutes;

  /// High-level screen state ('free', 'limited', 'blocked').
  final String kind;

  /// The reason why kind is what it is (e.g. 'daily_limit', 'bedtime', null).
  final String? reasonCode;

  /// True when the guardian allows earned minutes to extend the daily phone limit.
  final bool earnedMinutesExtendLimit;

  /// Today's date on the server in the family's timezone (YYYY-MM-DD).
  final String serverDate;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceScreenTimeReading &&
          runtimeType == other.runtimeType &&
          remainingMinutes == other.remainingMinutes &&
          countableUsedMinutes == other.countableUsedMinutes &&
          grantedMinutes == other.grantedMinutes &&
          capMinutes == other.capMinutes &&
          kind == other.kind &&
          reasonCode == other.reasonCode &&
          earnedMinutesExtendLimit == other.earnedMinutesExtendLimit &&
          serverDate == other.serverDate;

  @override
  int get hashCode => Object.hash(
        remainingMinutes,
        countableUsedMinutes,
        grantedMinutes,
        capMinutes,
        kind,
        reasonCode,
        earnedMinutesExtendLimit,
        serverDate,
      );

  @override
  String toString() =>
      'DeviceScreenTimeReading(remaining: $remainingMinutes, used: $countableUsedMinutes, granted: $grantedMinutes, cap: $capMinutes, kind: $kind, reason: $reasonCode, earnedExtends: $earnedMinutesExtendLimit, serverDate: $serverDate)';
}

/// The API client used by a child device to read its own screen-time state (GET /v1/devices/:deviceId/screen-time).
final class DeviceScreenTimeClient {
  const DeviceScreenTimeClient({
    required FoundationGateConfiguration configuration,
    required FoundationGateHttpTransport transport,
  })  : _configuration = configuration,
        _transport = transport;

  final FoundationGateConfiguration _configuration;
  final FoundationGateHttpTransport _transport;

  /// Reads the handset's own screen-time state from the server.
  ///
  /// Authenticates using the device credential: `Authorization: Device <deviceCredential>`.
  Future<DeviceScreenTimeReading> read({
    required String deviceId,
    required String deviceCredential,
  }) async {
    final uri = _configuration.deviceScreenTimeUri(deviceId);
    final FoundationGateHttpResponse response;
    try {
      response = await _transport.get(
        uri,
        headers: {
          'accept': 'application/json',
          'authorization': 'Device $deviceCredential',
        },
      );
    } on FoundationGateApiException {
      rethrow;
    } catch (_) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.networkUnavailable,
      );
    }

    return switch (response.statusCode) {
      200 => _parse(response.body),
      401 => throw const FoundationGateApiException(
          FoundationGateApiFailure.unauthenticated,
        ),
      403 => throw const FoundationGateApiException(
          FoundationGateApiFailure.accessDenied,
        ),
      404 => throw const FoundationGateApiException(
          FoundationGateApiFailure.notFound,
        ),
      429 || 503 => throw const FoundationGateApiException(
          FoundationGateApiFailure.serviceUnavailable,
        ),
      _ => throw const FoundationGateApiException(
          FoundationGateApiFailure.invalidResponse,
        ),
    };
  }

  /// Parses the DeviceScreenTimeResponse wire JSON into a [DeviceScreenTimeReading].
  static DeviceScreenTimeReading parseBody(String body) => _parse(body);

  static DeviceScreenTimeReading _parse(String body) {
    final Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      );
    }

    if (decoded is! Map<String, Object?>) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      );
    }

    final serverDate = decoded['date'];
    if (serverDate is! String || serverDate.isEmpty) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      );
    }

    final policyRaw = decoded['policy'];
    final bool earnedMinutesExtendLimit;
    if (policyRaw is Map<String, Object?>) {
      earnedMinutesExtendLimit = policyRaw['earnedMinutesExtendLimit'] == true;
    } else {
      earnedMinutesExtendLimit = false;
    }

    final state = decoded['state'];
    if (state is! Map<String, Object?>) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      );
    }

    final kind = state['kind'];
    if (kind is! String || kind.isEmpty) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      );
    }

    final rawReason = state['reasonCode'];
    final String? reasonCode;
    if (rawReason == null) {
      reasonCode = null;
    } else if (rawReason is String) {
      reasonCode = rawReason;
    } else {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      );
    }

    final rawRemaining = state['remainingMinutes'];
    final int? remainingMinutes;
    if (rawRemaining == null) {
      remainingMinutes = null;
    } else if (rawRemaining is int) {
      remainingMinutes = rawRemaining;
    } else {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      );
    }

    final rawCap = state['capMinutes'];
    final int? capMinutes;
    if (rawCap == null) {
      capMinutes = null;
    } else if (rawCap is int) {
      capMinutes = rawCap;
    } else {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      );
    }

    final countableUsedMinutes = state['countableUsedMinutes'];
    if (countableUsedMinutes is! int) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      );
    }

    final grantedMinutes = state['grantedMinutes'];
    if (grantedMinutes is! int) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      );
    }

    return DeviceScreenTimeReading(
      remainingMinutes: remainingMinutes,
      countableUsedMinutes: countableUsedMinutes,
      grantedMinutes: grantedMinutes,
      capMinutes: capMinutes,
      kind: kind,
      reasonCode: reasonCode,
      earnedMinutesExtendLimit: earnedMinutesExtendLimit,
      serverDate: serverDate,
    );
  }
}
