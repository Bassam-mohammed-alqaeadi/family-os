import 'dart:convert';

import 'foundation_gate_configuration.dart';
import 'foundation_gate_http.dart';
import 'foundation_gate_models.dart';

/// One membership of the family, as the server describes it to its caller.
///
/// Deliberately not the database row: the invitee's subject is absent, and `isSelf` is
/// present. The server decides which row belongs to the caller because only the server
/// knows who is asking; a client that guessed from an identifier would be inventing a fact
/// it was never given.
class FoundationGateMembership {
  const FoundationGateMembership({
    required this.id,
    required this.role,
    required this.status,
    required this.statusReasonCode,
    required this.version,
    required this.isSelf,
    required this.joinedAt,
    required this.statusChangedAt,
    required this.createdAt,
  });

  final String id;

  /// `primary_guardian` | `co_guardian` | `child`. The client renders these with its own
  /// vocabulary and never translates them into permissions of its own.
  final String role;

  /// `invited` | `active` | `revoked` | `removed`. A membership that is `invited` is an
  /// offer, not access.
  final String status;
  final String? statusReasonCode;
  final int version;
  final bool isSelf;
  final DateTime? joinedAt;
  final DateTime? statusChangedAt;
  final DateTime createdAt;

  bool get isPending => status == 'invited';
}

/// Typed client for the family membership lifecycle: read the roster, invite, accept,
/// revoke.
///
/// Every method maps the server's status codes onto the shared failure vocabulary rather
/// than throwing raw exceptions, because the screens above it decide what to say from a
/// named failure - and a 403 on an invitation acceptance means something different from a
/// 403 on a roster read.
class FamilyMembershipApiClient {
  FamilyMembershipApiClient({
    required FoundationGateConfiguration configuration,
    required FoundationGateHttpTransport transport,
  }) : _configuration = configuration,
       _transport = transport;

  final FoundationGateConfiguration _configuration;
  final FoundationGateHttpTransport _transport;

  Future<List<FoundationGateMembership>> list({
    required String familyId,
    required String idToken,
  }) async {
    if (!_validToken(idToken)) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.unauthenticated,
      );
    }
    final response = await _get(
      _configuration.familyMembershipsUri(familyId),
      idToken,
    );
    switch (response.statusCode) {
      case 200:
        return _parseMembershipList(response.body);
      case 400:
        throw const FoundationGateApiException(
          FoundationGateApiFailure.invalidInput,
        );
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

  Future<FoundationGateMembership> invite({
    required String familyId,
    required String role,
    required String targetSubject,
    required String idempotencyKey,
    required String idToken,
  }) async {
    if (!_isInvitableRole(role) ||
        !_validText(targetSubject, 255) ||
        !_validText(idempotencyKey, 128) ||
        !_validToken(idToken)) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidInput,
      );
    }
    final response = await _post(
      _configuration.familyMembershipsUri(familyId),
      idToken,
      {'role': role, 'targetSubject': targetSubject.trim()},
      idempotencyKey: idempotencyKey,
    );
    return _membershipFrom(response, successStatus: 201);
  }

  Future<FoundationGateMembership> accept({
    required String familyId,
    required String membershipId,
    required String idempotencyKey,
    required String idToken,
  }) async {
    if (!_validText(idempotencyKey, 128) || !_validToken(idToken)) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidInput,
      );
    }
    final response = await _post(
      _configuration.membershipCommandUri(familyId, membershipId, 'accept'),
      idToken,
      const <String, Object>{},
      idempotencyKey: idempotencyKey,
    );
    return _membershipFrom(response, successStatus: 200);
  }

  Future<FoundationGateMembership> revoke({
    required String familyId,
    required String membershipId,
    required String reasonCode,
    required String idempotencyKey,
    required String idToken,
  }) async {
    if (!_isReasonCode(reasonCode) ||
        !_validText(idempotencyKey, 128) ||
        !_validToken(idToken)) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidInput,
      );
    }
    final response = await _post(
      _configuration.membershipCommandUri(familyId, membershipId, 'revoke'),
      idToken,
      {'reasonCode': reasonCode},
      idempotencyKey: idempotencyKey,
    );
    return _membershipFrom(response, successStatus: 200);
  }

  /// The failure vocabulary, shared by all three write operations.
  ///
  /// `conflict` is the one worth naming: it is what the server answers when a membership
  /// is already gone, already accepted, or already the caller's own - states where a retry
  /// would never succeed and the screen should refresh rather than repeat.
  FoundationGateMembership _membershipFrom(
    FoundationGateHttpResponse response, {
    required int successStatus,
  }) {
    if (response.statusCode == successStatus) {
      return _parseMembershipResponse(response.body);
    }
    switch (response.statusCode) {
      case 400:
        throw const FoundationGateApiException(
          FoundationGateApiFailure.invalidInput,
        );
      case 401:
        throw const FoundationGateApiException(
          FoundationGateApiFailure.unauthenticated,
        );
      case 403:
        throw const FoundationGateApiException(
          FoundationGateApiFailure.accessDenied,
        );
      case 404:
        throw const FoundationGateApiException(
          FoundationGateApiFailure.notFound,
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

  Future<FoundationGateHttpResponse> _get(Uri uri, String idToken) async {
    try {
      return await _transport.get(
        uri,
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
  }

  Future<FoundationGateHttpResponse> _post(
    Uri uri,
    String idToken,
    Map<String, Object> body, {
    String? idempotencyKey,
  }) async {
    try {
      return await _transport.post(
        uri,
        headers: {
          'accept': 'application/json',
          'authorization': 'Bearer $idToken',
          'content-type': 'application/json',
          if (idempotencyKey != null) 'idempotency-key': idempotencyKey,
        },
        body: jsonEncode(body),
      );
    } on FoundationGateApiException {
      rethrow;
    } catch (_) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.networkUnavailable,
      );
    }
  }

  List<FoundationGateMembership> _parseMembershipList(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, Object?>) throw const FormatException();
      final raw = decoded['memberships'];
      if (raw is! List<Object?>) throw const FormatException();
      return List.unmodifiable(raw.map(_parseMembership));
    } catch (_) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      );
    }
  }

  FoundationGateMembership _parseMembershipResponse(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, Object?>) throw const FormatException();
      return _parseMembership(decoded['membership']);
    } catch (_) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      );
    }
  }

  /// Parses one membership, or refuses it.
  ///
  /// Additive server changes are tolerated: a field this client does not know is ignored,
  /// which is the lesson from the device surface, where a key-count check turned three new
  /// lifecycle fields into a corrupt device. A field this client NEEDS, or a status it does
  /// not understand, still drops the row rather than being rendered with a guessed meaning.
  FoundationGateMembership _parseMembership(Object? value) {
    if (value is! Map<String, Object?>) throw const FormatException();
    final id = value['id'];
    final role = value['role'];
    final status = value['status'];
    final version = value['version'];
    final isSelf = value['isSelf'];
    final createdAt = value['createdAt'];
    if (id is! String || !isFoundationGateUuid(id)) throw const FormatException();
    if (role is! String || !_knownRoles.contains(role)) {
      throw const FormatException();
    }
    if (status is! String || !_knownStatuses.contains(status)) {
      throw const FormatException();
    }
    if (version is! int || version < 1) throw const FormatException();
    if (isSelf is! bool) throw const FormatException();
    if (createdAt is! String) throw const FormatException();
    final parsedCreatedAt = DateTime.tryParse(createdAt)?.toUtc();
    if (parsedCreatedAt == null) throw const FormatException();
    final reasonCode = value['statusReasonCode'];
    if (reasonCode != null &&
        (reasonCode is! String || !_isReasonCode(reasonCode))) {
      throw const FormatException();
    }
    return FoundationGateMembership(
      id: id,
      role: role,
      status: status,
      statusReasonCode: reasonCode as String?,
      version: version,
      isSelf: isSelf,
      joinedAt: _parseTimestamp(value['joinedAt']),
      statusChangedAt: _parseTimestamp(value['statusChangedAt']),
      createdAt: parsedCreatedAt,
    );
  }

  DateTime? _parseTimestamp(Object? value) {
    if (value == null) return null;
    if (value is! String) throw const FormatException();
    final parsed = DateTime.tryParse(value)?.toUtc();
    if (parsed == null) throw const FormatException();
    return parsed;
  }

  static const Set<String> _knownRoles = {
    'primary_guardian',
    'co_guardian',
    'child',
  };

  static const Set<String> _knownStatuses = {
    'invited',
    'active',
    'revoked',
    'removed',
  };

  bool _isInvitableRole(String role) =>
      role == 'co_guardian' || role == 'child';

  bool _isReasonCode(String value) =>
      RegExp(r'^[a-z][a-z0-9_]{2,63}$').hasMatch(value);

  bool _validToken(String value) => value.trim().isNotEmpty;

  bool _validText(String value, int maxLength) =>
      value.trim().isNotEmpty &&
      value.trim().length <= maxLength &&
      !RegExp(r'[\u0000-\u001F\u007F]').hasMatch(value);
}
