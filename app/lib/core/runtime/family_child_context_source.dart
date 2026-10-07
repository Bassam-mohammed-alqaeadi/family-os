import 'package:flutter/foundation.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';

/// Server-owned presentation scope. Every operation is still authorized again
/// by the API when it is requested.
abstract final class FamilyChildPermissionScope {
  static const read = 'child.context.read';
  static const createDevicePairing = 'child.device_pairing.create';

  static const known = <String>{read, createDevicePairing};
}

enum FamilyChildContextRole { primaryGuardian, coGuardian }

enum FamilyChildDeviceSetupState {
  notLinked,
  linkedAwaitingTelemetry,
  linked,
}

enum FamilyChildContextFailure {
  notFound,
  accessDenied,
  sessionInvalid,
  serviceUnavailable,
  networkUnavailable,
  invalidResponse,
  unavailable,
}

@immutable
final class PermissionSnapshotV1 {
  const PermissionSnapshotV1({
    required this.policyVersion,
    required this.role,
    required this.scopes,
    required this.observedAt,
    required DateTime expiresAt,
    DateTime? presentationExpiresAt,
  }) : expiresAt = expiresAt,
       presentationExpiresAt = presentationExpiresAt ?? expiresAt;

  final int policyVersion;
  final FamilyChildContextRole role;
  final Set<String> scopes;
  final DateTime observedAt;

  /// Raw server-authoritative expiry supplied by PermissionSnapshot v1.
  final DateTime expiresAt;

  /// Local presentation deadline, never later than five minutes after receipt.
  ///
  /// A device clock can lag the server without turning the server's five-minute
  /// snapshot into a longer-lived local permission hint. API actions remain
  /// independently reauthorized by the server.
  final DateTime presentationExpiresAt;

  bool allows(String scope, {DateTime? at}) =>
      (at ?? DateTime.now()).toUtc().isBefore(presentationExpiresAt) &&
      scopes.contains(scope);
}

@immutable
final class FamilyChildContext {
  const FamilyChildContext({
    required this.familyId,
    required this.childId,
    required this.displayName,
    required this.ageYears,
    required this.avatarEmoji,
    required this.themeColor,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
    required this.deviceState,
    required this.deviceCount,
    required this.observedAt,
    required this.permissionSnapshot,
  });

  final FamilyId familyId;
  final ChildId childId;
  final String displayName;
  final int ageYears;
  final String avatarEmoji;
  final String themeColor;
  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;
  final FamilyChildDeviceSetupState deviceState;
  final int deviceCount;
  final DateTime observedAt;
  final PermissionSnapshotV1 permissionSnapshot;
}

@immutable
final class FamilyChildContextResult {
  const FamilyChildContextResult.ready(FamilyChildContext context)
    : this._(context: context);

  const FamilyChildContextResult.failed(FamilyChildContextFailure failure)
    : this._(failure: failure);

  const FamilyChildContextResult._({this.context, this.failure});

  final FamilyChildContext? context;
  final FamilyChildContextFailure? failure;

  bool get isReady => context != null;
}

/// Read-only child context boundary. Implementations must never synthesize a
/// context when the remote authority is missing or returns malformed data.
abstract interface class FamilyChildContextSource {
  Future<FamilyChildContextResult> load({
    required FamilyId familyId,
    required ChildId childId,
  });

  void dispose();
}

final class UnavailableFamilyChildContextSource
    implements FamilyChildContextSource {
  const UnavailableFamilyChildContextSource();

  @override
  Future<FamilyChildContextResult> load({
    required FamilyId familyId,
    required ChildId childId,
  }) async => const FamilyChildContextResult.failed(
    FamilyChildContextFailure.unavailable,
  );

  @override
  void dispose() {}
}
