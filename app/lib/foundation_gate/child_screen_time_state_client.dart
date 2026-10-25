import 'package:flutter/services.dart';

import 'package:family_os/foundation_gate/device_screen_time_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_http.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';

/// The seam between Dart and the native layer for reading the paired device's own
/// screen-time state. The device credential never reaches Dart: the native layer
/// holds it and makes the authenticated GET request on the device's behalf.
abstract interface class ChildScreenTimeStateTransport {
  Future<FoundationGateHttpResponse> readState();
}

final class NativeChildScreenTimeStateTransport
    implements ChildScreenTimeStateTransport {
  const NativeChildScreenTimeStateTransport();

  static const MethodChannel _channel = MethodChannel(
    'com.familyos.family_os/native_child_telemetry',
  );

  @override
  Future<FoundationGateHttpResponse> readState() async {
    try {
      final response = await _channel.invokeMapMethod<String, dynamic>(
        'screenTimeStateRequest',
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

  static FoundationGateApiFailure _failureFor(String code) => switch (code) {
    'device_screen_time_not_configured' =>
      FoundationGateApiFailure.unauthenticated,
    'device_screen_time_unreachable' =>
      FoundationGateApiFailure.networkUnavailable,
    _ => FoundationGateApiFailure.networkUnavailable,
  };
}

final class ChildScreenTimeStateClient {
  const ChildScreenTimeStateClient({
    required ChildScreenTimeStateTransport transport,
  }) : _transport = transport;

  final ChildScreenTimeStateTransport _transport;

  Future<DeviceScreenTimeReading> read() async {
    final response = await _transport.readState();
    return switch (response.statusCode) {
      200 => DeviceScreenTimeClient.parseBody(response.body),
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
}

/// The production reader of the paired handset's own screen-time state via the native proxy.
ChildScreenTimeStateClient childScreenTimeState() =>
    const ChildScreenTimeStateClient(
      transport: NativeChildScreenTimeStateTransport(),
    );

