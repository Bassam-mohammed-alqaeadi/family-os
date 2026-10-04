import 'dart:convert';

import 'foundation_gate_configuration.dart';
import 'foundation_gate_http.dart';
import 'foundation_gate_models.dart';

/// Typed client for the Family Entry & Children Control system.
///
/// It accepts only a family identifier previously returned by server-side family
/// discovery. The server remains authoritative for guardian eligibility on both
/// roster reads and child-profile creation.
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
    final rosterUri = _rosterUri(familyId);

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

  /// Sends one idempotent primary-guardian child-profile creation request.
  ///
  /// The returned child is only a server-confirmed response. The controller
  /// subsequently refreshes the roster before presenting it as the current
  /// collection state.
  Future<FoundationGateChild> create({
    required String familyId,
    required String idToken,
    required String idempotencyKey,
    required String displayName,
    required int ageYears,
    required String avatarEmoji,
    required String themeColor,
  }) async {
    final rosterUri = _rosterUri(familyId);
    final normalizedName = displayName.trim();
    final normalizedEmoji = avatarEmoji.trim();
    if (
        !_isValidDisplayName(normalizedName) ||
        !_isValidAvatarEmoji(normalizedEmoji) ||
        !kFoundationGateChildThemeColors.contains(themeColor) ||
        !_isValidIdempotencyKey(idempotencyKey) ||
        ageYears < 0 ||
        ageYears > 25) {
      throw const FoundationGateApiException(FoundationGateApiFailure.invalidInput);
    }

    FoundationGateHttpResponse response;
    try {
      response = await _transport.post(
        rosterUri,
        headers: {
          'accept': 'application/json',
          'content-type': 'application/json',
          'authorization': 'Bearer $idToken',
          'idempotency-key': idempotencyKey,
        },
        body: jsonEncode({
          'displayName': normalizedName,
          'ageYears': ageYears,
          'avatarEmoji': normalizedEmoji,
          'themeColor': themeColor,
        }),
      );
    } on FoundationGateApiException {
      rethrow;
    } catch (_) {
      throw const FoundationGateApiException(FoundationGateApiFailure.networkUnavailable);
    }

    switch (response.statusCode) {
      case 201:
        return _parseCreatedChild(response.body);
      case 400:
        throw const FoundationGateApiException(FoundationGateApiFailure.invalidInput);
      case 401:
        throw const FoundationGateApiException(FoundationGateApiFailure.unauthenticated);
      case 403:
        throw const FoundationGateApiException(FoundationGateApiFailure.accessDenied);
      case 409:
        throw const FoundationGateApiException(FoundationGateApiFailure.conflict);
      case 429:
      case 503:
        throw const FoundationGateApiException(FoundationGateApiFailure.serviceUnavailable);
      default:
        throw const FoundationGateApiException(FoundationGateApiFailure.invalidResponse);
    }
  }

  Uri _rosterUri(String familyId) {
    try {
      return _configuration.childrenRosterUri(familyId);
    } on ArgumentError {
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

  FoundationGateChild _parseCreatedChild(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, Object?> || decoded.keys.length != 1) {
        throw const FormatException();
      }
      return _parseChild(decoded['child']);
    } catch (_) {
      throw const FoundationGateApiException(FoundationGateApiFailure.invalidResponse);
    }
  }

  FoundationGateChild _parseChild(Object? value) {
    if (value is! Map<String, Object?> || value.keys.length != 8) {
      throw const FormatException();
    }
    final id = value['id'];
    final displayName = value['displayName'];
    final ageYears = value['ageYears'];
    final avatarEmoji = value['avatarEmoji'];
    final themeColor = value['themeColor'];
    final version = value['version'];
    final createdAt = value['createdAt'];
    final updatedAt = value['updatedAt'];
    if (
        id is! String ||
        !isFoundationGateUuid(id) ||
        displayName is! String ||
        !_isValidDisplayName(displayName) ||
        ageYears is! int ||
        ageYears < 0 ||
        ageYears > 25 ||
        avatarEmoji is! String ||
        !_isValidAvatarEmoji(avatarEmoji) ||
        themeColor is! String ||
        !kFoundationGateChildThemeColors.contains(themeColor) ||
        version is! int ||
        version < 1 ||
        createdAt is! String ||
        DateTime.tryParse(createdAt) == null ||
        updatedAt is! String ||
        DateTime.tryParse(updatedAt) == null) {
      throw const FormatException();
    }
    return FoundationGateChild(
      id: id,
      displayName: displayName,
      ageYears: ageYears,
      avatarEmoji: avatarEmoji,
      themeColor: themeColor,
    );
  }

  bool _isValidDisplayName(String value) {
    return value.isNotEmpty && value.length <= 120 && !RegExp(r'[\u0000-\u001F\u007F]').hasMatch(value);
  }

  bool _isValidAvatarEmoji(String value) {
    return value.isNotEmpty &&
        value.length <= 32 &&
        !RegExp(r'[\u0000-\u001F\u007F]').hasMatch(value) &&
        RegExp(r'[\u{1F000}-\u{1FAFF}]', unicode: true).hasMatch(value);
  }

  bool _isValidIdempotencyKey(String value) {
    return value.trim().isNotEmpty && value.length <= 128 && !RegExp(r'[\u0000-\u001F\u007F]').hasMatch(value);
  }
}
