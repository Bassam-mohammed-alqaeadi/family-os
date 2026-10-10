import 'dart:convert';

import 'foundation_gate_configuration.dart';
import 'foundation_gate_http.dart';
import 'foundation_gate_models.dart';

/// An invite code exactly as the server issued it — returned once, never again.
///
/// [code] is the display form (`ABCDE-FGHJK`). The server keeps only its digest, so a
/// screen that loses this value cannot ask for it back; it revokes and issues a new one.
class FoundationGateIssuedInviteCode {
  const FoundationGateIssuedInviteCode({
    required this.id,
    required this.role,
    required this.code,
    required this.expiresAt,
  });

  final String id;

  /// `co_guardian` | `child` — the role the invitee will hold once they redeem.
  final String role;
  final String code;
  final DateTime expiresAt;
}

/// What redeeming a code did: the family joined and the membership the server created.
class FoundationGateRedeemedInvite {
  const FoundationGateRedeemedInvite({
    required this.familyId,
    required this.familyDisplayName,
    required this.membershipId,
    required this.role,
  });

  final String familyId;
  final String familyDisplayName;
  final String membershipId;
  final String role;
}

/// Thrown when the server's rate limit refused a redemption attempt.
///
/// Kept apart from [FoundationGateApiFailure.serviceUnavailable] on purpose: "try again in a
/// few minutes because you typed too many codes" and "the service is down" are different
/// sentences for the person holding the phone.
class FamilyInviteCodeRateLimited implements Exception {
  const FamilyInviteCodeRateLimited();
}

/// Typed client for invites by code (owner decision 2026-10-10).
///
/// The guardian issues a code for a role and revokes it if it was shared by mistake; the
/// invitee, signed in with their own account, redeems it. No call carries the invitee's
/// account identifier — the server binds the membership to the verified token.
class FamilyInviteCodeApiClient {
  FamilyInviteCodeApiClient({
    required FoundationGateConfiguration configuration,
    required FoundationGateHttpTransport transport,
  }) : _configuration = configuration,
       _transport = transport;

  final FoundationGateConfiguration _configuration;
  final FoundationGateHttpTransport _transport;

  static final RegExp _displayCode = RegExp(
    r'^[A-HJKMNP-Z2-9]{5}-[A-HJKMNP-Z2-9]{5}$',
  );
  static final RegExp _codeLetters = RegExp(r'^[A-HJKMNP-Z2-9]{10}$');

  /// Normalises what a person typed or pasted, or returns null when it cannot be a code.
  /// Case, spaces and the display hyphen are forgiven — the same rule the server applies.
  static String? normalizeCode(String value) {
    final compact = value.replaceAll(RegExp(r'[\s-]'), '').toUpperCase();
    return _codeLetters.hasMatch(compact) ? compact : null;
  }

  Future<FoundationGateIssuedInviteCode> issue({
    required String familyId,
    required String role,
    required String idempotencyKey,
    required String idToken,
  }) async {
    if (!_isInvitableRole(role) ||
        !_validText(idempotencyKey, 128) ||
        !_validToken(idToken)) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidInput,
      );
    }
    final response = await _post(
      _configuration.familyInviteCodesUri(familyId),
      idToken,
      {'role': role},
      idempotencyKey: idempotencyKey,
    );
    if (response.statusCode == 201) return _parseIssued(response.body);
    throw _failureFor(response.statusCode);
  }

  Future<void> revoke({
    required String familyId,
    required String inviteId,
    required String idempotencyKey,
    required String idToken,
  }) async {
    if (!_validText(idempotencyKey, 128) || !_validToken(idToken)) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidInput,
      );
    }
    final response = await _post(
      _configuration.familyInviteCodeRevokeUri(familyId, inviteId),
      idToken,
      null,
      idempotencyKey: idempotencyKey,
    );
    if (response.statusCode == 200) {
      _parseRevoked(response.body);
      return;
    }
    throw _failureFor(response.statusCode);
  }

  Future<FoundationGateRedeemedInvite> redeem({
    required String code,
    required String idempotencyKey,
    required String idToken,
  }) async {
    final normalized = normalizeCode(code);
    if (normalized == null ||
        !_validText(idempotencyKey, 128) ||
        !_validToken(idToken)) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidInput,
      );
    }
    final response = await _post(_configuration.inviteCodeRedeemUri, idToken, {
      'code': normalized,
    }, idempotencyKey: idempotencyKey);
    if (response.statusCode == 200) return _parseRedeemed(response.body);
    if (response.statusCode == 429) throw const FamilyInviteCodeRateLimited();
    throw _failureFor(response.statusCode);
  }

  Exception _failureFor(int statusCode) {
    return FoundationGateApiException(switch (statusCode) {
      400 => FoundationGateApiFailure.invalidInput,
      401 => FoundationGateApiFailure.unauthenticated,
      403 => FoundationGateApiFailure.accessDenied,
      404 => FoundationGateApiFailure.notFound,
      409 => FoundationGateApiFailure.conflict,
      429 || 503 => FoundationGateApiFailure.serviceUnavailable,
      _ => FoundationGateApiFailure.invalidResponse,
    });
  }

  Future<FoundationGateHttpResponse> _post(
    Uri uri,
    String idToken,
    Map<String, Object>? body, {
    required String idempotencyKey,
  }) async {
    try {
      return await _transport.post(
        uri,
        headers: {
          'accept': 'application/json',
          'content-type': 'application/json',
          'authorization': 'Bearer ${idToken.trim()}',
          'idempotency-key': idempotencyKey,
        },
        body: jsonEncode(body ?? const <String, Object>{}),
      );
    } on FoundationGateApiException {
      rethrow;
    } catch (_) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.networkUnavailable,
      );
    }
  }

  FoundationGateIssuedInviteCode _parseIssued(String body) {
    try {
      final invite = _envelope(body, 'invite');
      final id = invite['id'];
      final role = invite['role'];
      final code = invite['code'];
      final status = invite['status'];
      final expiresAt = DateTime.tryParse('${invite['expiresAt']}');
      if (id is! String ||
          !isFoundationGateUuid(id) ||
          role is! String ||
          !_isInvitableRole(role) ||
          code is! String ||
          !_displayCode.hasMatch(code) ||
          status != 'open' ||
          expiresAt == null) {
        throw const FormatException();
      }
      return FoundationGateIssuedInviteCode(
        id: id,
        role: role,
        code: code,
        expiresAt: expiresAt.toUtc(),
      );
    } catch (_) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      );
    }
  }

  void _parseRevoked(String body) {
    try {
      final invite = _envelope(body, 'invite');
      if (invite['status'] != 'revoked') throw const FormatException();
    } catch (_) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      );
    }
  }

  FoundationGateRedeemedInvite _parseRedeemed(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, Object?>) throw const FormatException();
      final family = decoded['family'];
      final membership = decoded['membership'];
      if (family is! Map<String, Object?> ||
          membership is! Map<String, Object?>) {
        throw const FormatException();
      }
      final familyId = family['id'];
      final displayName = family['displayName'];
      final membershipId = membership['id'];
      final role = membership['role'];
      if (familyId is! String ||
          !isFoundationGateUuid(familyId) ||
          displayName is! String ||
          displayName.trim().isEmpty ||
          membershipId is! String ||
          !isFoundationGateUuid(membershipId) ||
          role is! String ||
          !_isInvitableRole(role) ||
          membership['status'] != 'active') {
        throw const FormatException();
      }
      return FoundationGateRedeemedInvite(
        familyId: familyId,
        familyDisplayName: displayName,
        membershipId: membershipId,
        role: role,
      );
    } catch (_) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      );
    }
  }

  Map<String, Object?> _envelope(String body, String key) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, Object?> || decoded.keys.length != 1) {
      throw const FormatException();
    }
    final value = decoded[key];
    if (value is! Map<String, Object?>) throw const FormatException();
    return value;
  }

  bool _isInvitableRole(String role) =>
      role == 'co_guardian' || role == 'child';

  bool _validText(String value, int maxLength) {
    final trimmed = value.trim();
    return trimmed.isNotEmpty &&
        trimmed.length <= maxLength &&
        !RegExp(r'[\u0000-\u001F\u007F]').hasMatch(trimmed);
  }

  bool _validToken(String value) => value.trim().isNotEmpty;
}
