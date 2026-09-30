import 'dart:convert';
import 'dart:io';

import 'foundation_gate_configuration.dart';
import 'foundation_gate_models.dart';

class FoundationGateHttpResponse {
  const FoundationGateHttpResponse({required this.statusCode, required this.body});

  final int statusCode;
  final String body;
}

abstract interface class FoundationGateHttpTransport {
  Future<FoundationGateHttpResponse> get(Uri uri, {required Map<String, String> headers});
}

class IoFoundationGateHttpTransport implements FoundationGateHttpTransport {
  IoFoundationGateHttpTransport({HttpClient? client}) : _client = client ?? HttpClient();

  final HttpClient _client;

  @override
  Future<FoundationGateHttpResponse> get(Uri uri, {required Map<String, String> headers}) async {
    try {
      final request = await _client.getUrl(uri);
      headers.forEach((name, value) => request.headers.set(name, value));
      final response = await request.close();
      return FoundationGateHttpResponse(
        statusCode: response.statusCode,
        body: await utf8.decodeStream(response),
      );
    } on SocketException {
      throw const FoundationGateApiException(FoundationGateApiFailure.networkUnavailable);
    } on HttpException {
      throw const FoundationGateApiException(FoundationGateApiFailure.networkUnavailable);
    } on HandshakeException {
      throw const FoundationGateApiException(FoundationGateApiFailure.networkUnavailable);
    }
  }
}

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
          HttpHeaders.acceptHeader: ContentType.json.mimeType,
          HttpHeaders.authorizationHeader: 'Bearer $idToken',
        },
      );
    } on FoundationGateApiException {
      rethrow;
    } catch (_) {
      throw const FoundationGateApiException(FoundationGateApiFailure.networkUnavailable);
    }

    switch (response.statusCode) {
      case 200:
        return _parseFamilies(response.body);
      case 401:
        throw const FoundationGateApiException(FoundationGateApiFailure.unauthenticated);
      case 403:
        throw const FoundationGateApiException(FoundationGateApiFailure.accessDenied);
      case 503:
        throw const FoundationGateApiException(FoundationGateApiFailure.serviceUnavailable);
      default:
        throw const FoundationGateApiException(FoundationGateApiFailure.invalidResponse);
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
      throw const FoundationGateApiException(FoundationGateApiFailure.invalidResponse);
    }
  }

  FoundationGateFamily _parseFamily(Object? value) {
    if (value is! Map<String, Object?> || value.keys.length != 3) {
      throw const FormatException();
    }
    final id = value['id'];
    final displayName = value['displayName'];
    final role = value['role'];
    if (
        id is! String ||
        id.isEmpty ||
        displayName is! String ||
        displayName.isEmpty ||
        role is! String ||
        !{'primary_guardian', 'co_guardian', 'child'}.contains(role)) {
      throw const FormatException();
    }
    return FoundationGateFamily(id: id, displayName: displayName, role: role);
  }
}
