import 'dart:convert';

import 'foundation_gate_configuration.dart';
import 'foundation_gate_http.dart';
import 'foundation_gate_models.dart';

class FamilyDiscoveryApiClient {
  FamilyDiscoveryApiClient({
    required FoundationGateConfiguration configuration,
    required FoundationGateHttpTransport transport,
  }) : _configuration = configuration,
       _transport = transport;

  final FoundationGateConfiguration _configuration;
  final FoundationGateHttpTransport _transport;

  Future<List<FoundationGateFamily>> discover({required String idToken}) async {
    FoundationGateHttpResponse response;
    try {
      response = await _transport.get(
        _configuration.familyDiscoveryUri,
        headers: {
          'accept': 'application/json',
          'authorization': 'Bearer $idToken',
        },
      );
    } on FoundationGateApiException {
      rethrow;
    } catch (_) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.networkUnavailable,
      );
    }

    switch (response.statusCode) {
      case 200:
        return _parseFamilies(response.body);
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

  List<FoundationGateFamily> _parseFamilies(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, Object?> || decoded.keys.length != 1) {
        throw const FormatException();
      }
      final rawFamilies = decoded['families'];
      if (rawFamilies is! List<Object?> || rawFamilies.length > 20) {
        throw const FormatException();
      }
      return List.unmodifiable(rawFamilies.map(_parseFamily));
    } catch (_) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      );
    }
  }

  FoundationGateFamily _parseFamily(Object? value) {
    if (value is! Map<String, Object?> || value.keys.length != 3) {
      throw const FormatException();
    }
    final id = value['id'];
    final displayName = value['displayName'];
    final role = value['role'];
    if (id is! String ||
        !isFoundationGateUuid(id) ||
        displayName is! String ||
        displayName.trim().isEmpty ||
        role is! String ||
        !{'primary_guardian', 'co_guardian', 'child'}.contains(role)) {
      throw const FormatException();
    }
    return FoundationGateFamily(id: id, displayName: displayName, role: role);
  }
}
