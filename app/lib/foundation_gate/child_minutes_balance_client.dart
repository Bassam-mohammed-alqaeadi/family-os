import 'dart:convert';

import 'package:flutter/services.dart';

import 'package:family_os/foundation_gate/foundation_gate_http.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';

/// One wallet of the child, as the server states it.
final class ChildMinutesBalanceApp {
  const ChildMinutesBalanceApp({required this.appId, required this.minutes});

  final String appId;
  final int minutes;
}

/// The child's own balance, as the server states it (S3 · CHD-019).
///
/// Read-only by construction: nothing in this file writes minutes.
final class ChildMinutesBalance {
  const ChildMinutesBalance({
    required this.total,
    required this.daily,
    required this.temporary,
    required this.free,
    required this.apps,
    required this.asOf,
  });

  final int total;
  final int daily;
  final int temporary;
  final int free;
  final List<ChildMinutesBalanceApp> apps;
  final DateTime asOf;
}

/// The seam between Dart and the native layer. The device credential never reaches Dart:
/// the native side holds it and answers by device id only.
abstract interface class ChildMinutesBalanceTransport {
  /// The paired device id, or null when this handset is not paired.
  Future<String?> configuredDeviceId();

  Future<FoundationGateHttpResponse> readBalance(String deviceId);
}

final class NativeChildMinutesBalanceTransport
    implements ChildMinutesBalanceTransport {
  static const MethodChannel _channel = MethodChannel(
    'com.familyos.family_os/native_child_telemetry',
  );

  @override
  Future<String?> configuredDeviceId() async {
    try {
      final state = await _channel.invokeMapMethod<String, dynamic>('status');
      if (state?['configured'] != true) return null;
      final id = state?['deviceId'];
      return id is String ? id : null;
    } on MissingPluginException {
      return null;
    } on PlatformException {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.networkUnavailable,
      );
    }
  }

  @override
  Future<FoundationGateHttpResponse> readBalance(String deviceId) async {
    try {
      final response = await _channel.invokeMapMethod<String, dynamic>(
        'minutesBalanceRequest',
        <String, Object?>{'deviceId': deviceId},
      );
      final statusCode = response?['statusCode'];
      final body = response?['body'];
      if (statusCode is! int || body is! String) {
        throw const FoundationGateApiException(
          FoundationGateApiFailure.invalidResponse,
        );
      }
      return FoundationGateHttpResponse(statusCode: statusCode, body: body);
    } on FoundationGateApiException {
      rethrow;
    } on MissingPluginException {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.networkUnavailable,
      );
    } on PlatformException catch (e) {
      throw FoundationGateApiException(_failureFor(e.code));
    }
  }

  /// The native side refuses about the pairing, which is not a network fault: a handset that is
  /// not (or no longer) the paired device must not look merely offline.
  static FoundationGateApiFailure _failureFor(String code) => switch (code) {
    'device_minutes_not_configured' ||
    'device_minutes_scope_mismatch' => FoundationGateApiFailure.unauthenticated,
    _ => FoundationGateApiFailure.networkUnavailable,
  };
}

final class ChildMinutesBalanceClient {
  ChildMinutesBalanceClient({required ChildMinutesBalanceTransport transport})
    : _transport = transport;

  final ChildMinutesBalanceTransport _transport;

  /// The paired device id this handset reads under, or null when unpaired. The cache's pairing key.
  Future<String?> pairedDeviceId() => _transport.configuredDeviceId();

  Future<ChildMinutesBalance> read() async {
    final deviceId = await _transport.configuredDeviceId();
    if (deviceId == null) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.unauthenticated,
      );
    }
    final response = await _transport.readBalance(deviceId);
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

  /// The one reader of the balance wire shape, shared with the guardian's read.
  static ChildMinutesBalance parseBody(String body) => _parse(body);

  static ChildMinutesBalance _parse(String body) {
    final Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException {
      throw _invalid();
    }
    if (decoded is! Map<String, Object?>) throw _invalid();
    final rawApps = decoded['apps'];
    if (rawApps is! List<Object?>) throw _invalid();
    final apps = rawApps
        .map((entry) {
          if (entry is! Map<String, Object?>) throw _invalid();
          final appId = entry['appId'];
          if (appId is! String || appId.isEmpty) throw _invalid();
          return ChildMinutesBalanceApp(
            appId: appId,
            minutes: _minutes(entry['minutes']),
          );
        })
        .toList(growable: false);
    final asOf = decoded['asOf'];
    if (asOf is! String) throw _invalid();
    final parsedAsOf = DateTime.tryParse(asOf);
    if (parsedAsOf == null) throw _invalid();
    return ChildMinutesBalance(
      total: _minutes(decoded['total']),
      daily: _minutes(decoded['daily']),
      temporary: _minutes(decoded['temporary']),
      free: _minutes(decoded['free']),
      apps: apps,
      asOf: parsedAsOf,
    );
  }

  /// A balance that is not a non-negative whole number is a server this build cannot read.
  static int _minutes(Object? value) {
    if (value is! int || value < 0) throw _invalid();
    return value;
  }

  static FoundationGateApiException _invalid() =>
      const FoundationGateApiException(FoundationGateApiFailure.invalidResponse);
}

/// The one production reader of the handset's own balance (CHD-019 and the screen-time view).
final ChildMinutesBalanceClient stage1ChildMinutesBalanceClient =
    ChildMinutesBalanceClient(transport: NativeChildMinutesBalanceTransport());
