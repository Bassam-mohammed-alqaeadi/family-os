import 'dart:convert';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/runtime/family_child_context_source.dart';

import 'foundation_gate_configuration.dart';
import 'foundation_gate_http.dart';
import 'foundation_gate_models.dart';

final class FamilyChildContextApiException implements Exception {
  const FamilyChildContextApiException(this.failure);

  final FamilyChildContextFailure failure;
}

/// Strict client for the narrow child-context read model.
///
/// Unknown, missing or inconsistent fields fail closed. In particular this
/// parser cannot accidentally promote device telemetry or other prototype facts
/// into the production child screen.
final class ChildContextApiClient {
  ChildContextApiClient({
    required FoundationGateConfiguration configuration,
    required FoundationGateHttpTransport transport,
    DateTime Function()? clock,
  }) : _configuration = configuration,
       _transport = transport,
       _clock = clock ?? DateTime.now;

  final FoundationGateConfiguration _configuration;
  final FoundationGateHttpTransport _transport;
  final DateTime Function() _clock;

  Future<FamilyChildContext> get({
    required String familyId,
    required String childId,
    required String idToken,
  }) async {
    final uri = _contextUri(familyId, childId);
    FoundationGateHttpResponse response;
    try {
      response = await _transport.get(
        uri,
        headers: {
          'accept': 'application/json',
          'authorization': 'Bearer $idToken',
        },
      );
    } on FamilyChildContextApiException {
      rethrow;
    } on FoundationGateApiException catch (error) {
      throw FamilyChildContextApiException(_mapTransportFailure(error.failure));
    } catch (_) {
      throw const FamilyChildContextApiException(
        FamilyChildContextFailure.networkUnavailable,
      );
    }

    switch (response.statusCode) {
      case 200:
        return _parse(
          response.body,
          expectedFamilyId: familyId,
          expectedChildId: childId,
        );
      case 401:
        throw const FamilyChildContextApiException(
          FamilyChildContextFailure.sessionInvalid,
        );
      case 403:
        throw const FamilyChildContextApiException(
          FamilyChildContextFailure.accessDenied,
        );
      case 404:
        // Only the resource-specific server code proves that the scoped child
        // does not exist. A proxy/server route miss is not child truth and must
        // never be rendered as “Child not found”.
        throw FamilyChildContextApiException(
          _errorCode(response.body) == 'family_child_not_found'
              ? FamilyChildContextFailure.notFound
              : FamilyChildContextFailure.invalidResponse,
        );
      case 429:
      case 503:
        throw const FamilyChildContextApiException(
          FamilyChildContextFailure.serviceUnavailable,
        );
      default:
        throw const FamilyChildContextApiException(
          FamilyChildContextFailure.invalidResponse,
        );
    }
  }

  Uri _contextUri(String familyId, String childId) {
    try {
      return _configuration.familyChildContextUri(familyId, childId);
    } on ArgumentError {
      throw const FamilyChildContextApiException(
        FamilyChildContextFailure.invalidResponse,
      );
    }
  }

  FamilyChildContext _parse(
    String body, {
    required String expectedFamilyId,
    required String expectedChildId,
  }) {
    try {
      final decoded = jsonDecode(body);
      final root = _object(decoded, const {
        'child',
        'setup',
        'permissionSnapshot',
      });
      final child = _object(root['child'], const {
        'id',
        'displayName',
        'ageYears',
        'avatarEmoji',
        'themeColor',
        'version',
        'createdAt',
        'updatedAt',
      });
      final setup = _object(root['setup'], const {
        'deviceState',
        'deviceCount',
        'observedAt',
      });
      final permission = _object(root['permissionSnapshot'], const {
        'policyVersion',
        'role',
        'scopes',
        'observedAt',
        'expiresAt',
      });

      final id = _string(child['id'], min: 36, max: 36);
      final displayName = _string(child['displayName'], min: 1, max: 120);
      final ageYears = _integer(child['ageYears'], min: 0, max: 25);
      final avatarEmoji = _string(child['avatarEmoji'], min: 1, max: 32);
      final themeColor = _enumString(
        child['themeColor'],
        kFoundationGateChildThemeColors,
      );
      final version = _integer(child['version'], min: 1);
      final createdAt = _dateTime(child['createdAt']);
      final updatedAt = _dateTime(child['updatedAt']);
      final deviceCount = _integer(setup['deviceCount'], min: 0);
      final deviceState = switch (setup['deviceState']) {
        'not_linked' => FamilyChildDeviceSetupState.notLinked,
        'linked_awaiting_telemetry' =>
          FamilyChildDeviceSetupState.linkedAwaitingTelemetry,
        'linked' => FamilyChildDeviceSetupState.linked,
        _ => throw const FormatException(),
      };
      final observedAt = _dateTime(setup['observedAt']);
      final permissionObservedAt = _dateTime(permission['observedAt']);
      final expiresAt = _dateTime(permission['expiresAt']);
      final policyVersion = _integer(permission['policyVersion'], min: 1);
      final role = switch (permission['role']) {
        'primary_guardian' => FamilyChildContextRole.primaryGuardian,
        'co_guardian' => FamilyChildContextRole.coGuardian,
        _ => throw const FormatException(),
      };
      final scopes = _scopes(permission['scopes']);

      if (!isFoundationGateUuid(id) ||
          id != expectedChildId ||
          !isFoundationGateUuid(expectedFamilyId) ||
          !RegExp(r'[\u{1F000}-\u{1FAFF}]', unicode: true).hasMatch(avatarEmoji) ||
          RegExp(r'[\u0000-\u001F\u007F]').hasMatch(displayName) ||
          updatedAt.isBefore(createdAt) ||
          observedAt != permissionObservedAt ||
          expiresAt.difference(observedAt) != const Duration(minutes: 5) ||
          observedAt.isAfter(
            _clock().toUtc().add(const Duration(minutes: 30)),
          ) ||
          !_clock().toUtc().isBefore(expiresAt) ||
          (deviceState == FamilyChildDeviceSetupState.notLinked &&
              deviceCount != 0) ||
          (deviceState != FamilyChildDeviceSetupState.notLinked &&
              deviceCount == 0) ||
          !scopes.contains(FamilyChildPermissionScope.read) ||
          (role == FamilyChildContextRole.coGuardian &&
              scopes.contains(FamilyChildPermissionScope.createDevicePairing))) {
        throw const FormatException();
      }

      return FamilyChildContext(
        familyId: FamilyId(expectedFamilyId),
        childId: ChildId(id),
        displayName: displayName,
        ageYears: ageYears,
        avatarEmoji: avatarEmoji,
        themeColor: themeColor,
        version: version,
        createdAt: createdAt,
        updatedAt: updatedAt,
        deviceState: deviceState,
        deviceCount: deviceCount,
        observedAt: observedAt,
        permissionSnapshot: PermissionSnapshotV1(
          policyVersion: policyVersion,
          role: role,
          scopes: Set.unmodifiable(scopes),
          observedAt: permissionObservedAt,
          expiresAt: expiresAt,
        ),
      );
    } on FamilyChildContextApiException {
      rethrow;
    } catch (_) {
      throw const FamilyChildContextApiException(
        FamilyChildContextFailure.invalidResponse,
      );
    }
  }

  Map<String, Object?> _object(Object? value, Set<String> keys) {
    if (value is! Map<String, Object?> ||
        value.length != keys.length ||
        !value.keys.toSet().containsAll(keys)) {
      throw const FormatException();
    }
    return value;
  }

  String _string(Object? value, {required int min, required int max}) {
    if (value is! String || value.length < min || value.length > max) {
      throw const FormatException();
    }
    return value;
  }

  String _enumString(Object? value, Set<String> allowed) {
    if (value is! String || !allowed.contains(value)) {
      throw const FormatException();
    }
    return value;
  }

  int _integer(Object? value, {required int min, int? max}) {
    if (value is! int || value < min || (max != null && value > max)) {
      throw const FormatException();
    }
    return value;
  }

  DateTime _dateTime(Object? value) {
    if (value is! String) throw const FormatException();
    final parsed = DateTime.tryParse(value);
    if (parsed == null || !parsed.isUtc) throw const FormatException();
    return parsed;
  }

  Set<String> _scopes(Object? value) {
    if (value is! List<Object?> || value.isEmpty) {
      throw const FormatException();
    }
    final scopes = <String>{};
    for (final item in value) {
      if (item is! String ||
          !FamilyChildPermissionScope.known.contains(item) ||
          !scopes.add(item)) {
        throw const FormatException();
      }
    }
    return scopes;
  }

  String? _errorCode(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, Object?>) return null;
      final error = decoded['error'];
      if (error is! Map<String, Object?>) return null;
      final code = error['code'];
      return code is String ? code : null;
    } catch (_) {
      return null;
    }
  }

  FamilyChildContextFailure _mapTransportFailure(
    FoundationGateApiFailure failure,
  ) => switch (failure) {
    FoundationGateApiFailure.unauthenticated =>
      FamilyChildContextFailure.sessionInvalid,
    FoundationGateApiFailure.accessDenied =>
      FamilyChildContextFailure.accessDenied,
    FoundationGateApiFailure.serviceUnavailable ||
    FoundationGateApiFailure.tooManyAttempts =>
      FamilyChildContextFailure.serviceUnavailable,
    FoundationGateApiFailure.networkUnavailable =>
      FamilyChildContextFailure.networkUnavailable,
    FoundationGateApiFailure.invalidInput ||
    FoundationGateApiFailure.conflict ||
    FoundationGateApiFailure.invalidResponse =>
      FamilyChildContextFailure.invalidResponse,
  };
}
