import 'dart:convert';

import 'package:family_os/foundation_gate/foundation_gate_configuration.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';
import 'package:http/http.dart' as http;

/// The server's record of one guardian handset that may receive a content-free chat nudge.
final class FamilyPushRegistration {
  const FamilyPushRegistration({
    required this.id,
    required this.platform,
    required this.locale,
  });

  final String id;
  final String platform;
  final String locale;

  static FamilyPushRegistration fromJson(Object? json) {
    if (json is! Map<String, Object?>) {
      throw const FoundationGateApiException(FoundationGateApiFailure.invalidResponse);
    }
    final id = json['id'];
    final platform = json['platform'];
    final locale = json['locale'];
    if (id is! String ||
        !FamilyPushClient._uuid.hasMatch(id) ||
        !FamilyPushClient._platforms.contains(platform) ||
        !FamilyPushClient._locales.contains(locale)) {
      throw const FoundationGateApiException(FoundationGateApiFailure.invalidResponse);
    }
    return FamilyPushRegistration(id: id, platform: platform as String, locale: locale as String);
  }
}

/// Registers and removes this handset's push token for a guardian, over the same origin and
/// bearer credential as every other chat call. The server decides who may register; this client
/// only refuses input that the server would refuse anyway, so no malformed request leaves the app.
final class FamilyPushClient {
  FamilyPushClient({
    required FoundationGateConfiguration configuration,
    http.Client? client,
  }) : _configuration = configuration,
       _client = client ?? http.Client();

  final FoundationGateConfiguration _configuration;
  final http.Client _client;

  static final RegExp _uuid = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  /// Firebase registration tokens: letters, digits, colon, underscore, hyphen.
  static final RegExp _token = RegExp(r'^[A-Za-z0-9:_-]{32,4096}$');

  static const Set<String> _platforms = <String>{'android', 'ios'};
  static const Set<String> _locales = <String>{'ar', 'en'};

  /// Registers [token] for the guardian in [familyId]. A token that was registered before moves
  /// to this guardian, so the previous owner stops receiving nudges on this handset.
  Future<FamilyPushRegistration> register({
    required String familyId,
    required String token,
    required String platform,
    required String locale,
    required String idToken,
  }) async {
    if (!_uuid.hasMatch(familyId) ||
        !_token.hasMatch(token) ||
        !_platforms.contains(platform) ||
        !_locales.contains(locale)) {
      throw const FoundationGateApiException(FoundationGateApiFailure.invalidInput);
    }
    _requireCredential(idToken);
    final uri = _configuration.stagingApiOrigin.replace(
      path: '/v1/families/$familyId/push/registrations',
    );
    final response = await _send(
      () => _client.post(
        uri,
        headers: _headers(idToken, json: true),
        body: jsonEncode(<String, Object?>{
          'token': token,
          'platform': platform,
          'locale': locale,
        }),
      ),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw _failure(response);
    }
    final decoded = _decodeObject(response.body);
    return FamilyPushRegistration.fromJson(decoded['registration']);
  }

  /// Removes one of the caller's own registrations (sign-out on this handset).
  Future<void> unregister({
    required String familyId,
    required String registrationId,
    required String idToken,
  }) async {
    if (!_uuid.hasMatch(familyId) || !_uuid.hasMatch(registrationId)) {
      throw const FoundationGateApiException(FoundationGateApiFailure.invalidInput);
    }
    _requireCredential(idToken);
    final uri = _configuration.stagingApiOrigin.replace(
      path: '/v1/families/$familyId/push/registrations/$registrationId',
    );
    final response = await _send(
      () => _client.delete(uri, headers: _headers(idToken, json: false)),
    );
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw _failure(response);
    }
  }

  static void _requireCredential(String idToken) {
    if (idToken.trim().isEmpty) {
      throw const FoundationGateApiException(FoundationGateApiFailure.unauthenticated);
    }
  }

  static Map<String, String> _headers(String idToken, {required bool json}) => <String, String>{
    'authorization': 'Bearer $idToken',
    'accept': 'application/json',
    if (json) 'content-type': 'application/json',
  };

  static Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request();
    } on Object {
      throw const FoundationGateApiException(FoundationGateApiFailure.networkUnavailable);
    }
  }

  static FoundationGateApiException _failure(http.Response response) {
    final code = response.statusCode;
    final failure = switch (code) {
      400 => FoundationGateApiFailure.invalidInput,
      401 => FoundationGateApiFailure.unauthenticated,
      403 => FoundationGateApiFailure.accessDenied,
      404 => FoundationGateApiFailure.notFound,
      409 => FoundationGateApiFailure.conflict,
      503 => FoundationGateApiFailure.serviceUnavailable,
      _ => FoundationGateApiFailure.invalidResponse,
    };
    return FoundationGateApiException(failure, statusCode: code);
  }

  static Map<String, Object?> _decodeObject(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, Object?>) return decoded;
    } on FormatException {
      // Fall through to the single refusal below.
    }
    throw const FoundationGateApiException(FoundationGateApiFailure.invalidResponse);
  }
}
