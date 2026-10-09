import 'package:flutter/services.dart';

import 'package:family_os/foundation_gate/family_chat_api_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_http.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';

/// Keeps the paired-device credential in Android's protected store while allowing the child
/// surface to use the same typed chat contract as the guardian surface.
final class NativeFamilyChatDeviceTransport
    implements FamilyChatDeviceTransport {
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
  Future<FoundationGateHttpResponse> send(
    FamilyChatDeviceRequest request,
  ) async {
    try {
      final response = await _channel.invokeMapMethod<String, dynamic>(
        'chatRequest',
        <String, Object?>{
          'operation': request.operation,
          'deviceId': request.deviceId,
          if (request.threadId != null) 'threadId': request.threadId,
          if (request.messageId != null) 'messageId': request.messageId,
          'queryParameters': request.queryParameters,
          if (request.body != null) 'body': request.body,
          if (request.idempotencyKey != null)
            'idempotencyKey': request.idempotencyKey,
        },
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
    } on PlatformException {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.networkUnavailable,
      );
    } on Object {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.networkUnavailable,
      );
    }
  }
}
