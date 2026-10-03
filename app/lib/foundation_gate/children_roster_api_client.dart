import 'dart:convert';

import 'foundation_gate_configuration.dart';
import 'foundation_gate_http.dart';
import 'foundation_gate_models.dart';

/// Typed, read-only client for the narrowly authorized Children Roster slice.
///
/// It accepts only a family identifier previously returned by server-side family
/// discovery. The server remains authoritative for guardian eligibility.
class ChildrenRosterApiClient {
  ChildrenRosterApiClient({
    required FoundationGateConfiguration configuration,
    required FoundationGateHttpTransport transport,
  }) : _configuration = configuration,
       _transport = transport;

  final FoundationGateConfiguration _configuration;
  final FoundationGateHttpTransport _transport;

  Future<List<FoundationGateChild>> list({
    required String familyId,
    required String idToken,
  }) async {
    final Uri rosterUri;
    try {
      rosterUri = _configuration.childrenRosterUri(familyId);
    } on ArgumentError {
      throw const FoundationGateApiException(FoundationGateApiFailure.invalidResponse);
    }

    FoundationGateHttpResponse response;
    try {
      response = await _transport.get(
        rosterUri,
        headers: {
          'accept': 'application/json',
          'authorization': 'Bearer $idToken',
        },
      );
    } on FoundationGateApiException {
      rethrow;
    } catch (_) {
      throw const FoundationGateApiException(FoundationGateApiFailure.networkUnavailable);
    }

    switch (response.statusCode) {
      case 200:
        return _parseChildren(response.body);
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

  List<FoundationGateChild> _parseChildren(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, Object?> || decoded.keys.length != 1) {
        throw const FormatException();
      }
      final rawChildren = decoded['children'];
      if (rawChildren is! List<Object?>) {
        throw const FormatException();
      }
      return List.unmodifiable(rawChildren.map(_parseChild));
    } catch (_) {
      throw const FoundationGateApiException(FoundationGateApiFailure.invalidResponse);
    }
  }

  FoundationGateChild _parseChild(Object? value) {
    if (value is! Map<String, Object?> || value.keys.length != 6) {
      throw const FormatException();
    }
    final id = value['id'];
    final displayName = value['displayName'];
    final ageYears = value['ageYears'];
    final version = value['version'];
    final createdAt = value['createdAt'];
    final updatedAt = value['updatedAt'];
    if (
        id is! String ||
        !isFoundationGateUuid(id) ||
        displayName is! String ||
        displayName.trim().isEmpty ||
        ageYears is! int ||
        ageYears < 0 ||
        ageYears > 25 ||
        version is! int ||
        version < 1 ||
        createdAt is! String ||
        DateTime.tryParse(createdAt) == null ||
        updatedAt is! String ||
        DateTime.tryParse(updatedAt) == null) {
      throw const FormatException();
    }
    return FoundationGateChild(id: id, displayName: displayName, ageYears: ageYears);
  }
}
