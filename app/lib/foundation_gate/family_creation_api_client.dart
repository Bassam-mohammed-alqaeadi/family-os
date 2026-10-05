import 'dart:convert';

import 'foundation_gate_configuration.dart';
import 'foundation_gate_http.dart';
import 'foundation_gate_models.dart';

/// Server-confirmed family created by the verified principal.
class FoundationGateCreatedFamily {
  const FoundationGateCreatedFamily({required this.id, required this.displayName});

  final String id;
  final String displayName;
}

/// Typed client for real family creation and discovery replenishment.
///
/// Family creation intentionally precedes the narrower admitted child-profile
/// slice in the onboarding journey. It uses the implemented Node.js/Express
/// contract only: bearer identity, UUID-shaped idempotency key and exactly
/// `{ "displayName" }`, with 201-or-idempotent-replay handling delegated to
/// the durable server response.
class FamilyCreationApiClient {
  FamilyCreationApiClient({
    required FoundationGateConfiguration configuration,
    required FoundationGateHttpTransport transport,
  })  : _configuration = configuration,
        _transport = transport;

  final FoundationGateConfiguration _configuration;
  final FoundationGateHttpTransport _transport;

  Future<FoundationGateCreatedFamily> create({
    required String idToken,
    required String idempotencyKey,
    required String displayName,
  }) async {
    final normalizedName = displayName.trim();
    if (!_isValidDisplayName(normalizedName) ||
        !_isValidIdempotencyKey(idempotencyKey) ||
        idToken.trim().isEmpty) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidInput,
      );
    }

    FoundationGateHttpResponse response;
    try {
      response = await _transport.post(
        _configuration.stagingApiOrigin.replace(path: '/v1/families'),
        headers: {
          'accept': 'application/json',
          'content-type': 'application/json',
          'authorization': 'Bearer $idToken',
          'idempotency-key': idempotencyKey,
        },
        body: jsonEncode({'displayName': normalizedName}),
      );
    } on FoundationGateApiException {
      rethrow;
    } catch (_) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.networkUnavailable,
      );
    }

    switch (response.statusCode) {
      case 201:
        return _parseCreatedFamily(response.body);
      case 400:
        throw const FoundationGateApiException(
          FoundationGateApiFailure.invalidInput,
        );
      case 401:
        throw const FoundationGateApiException(
          FoundationGateApiFailure.unauthenticated,
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

  FoundationGateCreatedFamily _parseCreatedFamily(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, Object?> || decoded.keys.length != 1) {
        throw const FormatException();
      }
      final raw = decoded['family'];
      if (raw is! Map<String, Object?>) throw const FormatException();
      final id = raw['id'];
      final displayName = raw['displayName'];
      if (id is! String ||
          !isFoundationGateUuid(id) ||
          displayName is! String ||
          !_isValidDisplayName(displayName)) {
        throw const FormatException();
      }
      return FoundationGateCreatedFamily(
        id: id,
        displayName: displayName,
      );
    } catch (_) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      );
    }
  }

  bool _isValidDisplayName(String value) {
    return value.isNotEmpty &&
        value.length <= 120 &&
        !RegExp(r'[\u0000-\u001F\u007F]').hasMatch(value);
  }

  bool _isValidIdempotencyKey(String value) {
    return value.trim().isNotEmpty &&
        value.length <= 128 &&
        !RegExp(r'[\u0000-\u001F\u007F]').hasMatch(value);
  }
}
