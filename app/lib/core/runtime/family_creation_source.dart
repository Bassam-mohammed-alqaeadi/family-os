import 'package:flutter/foundation.dart';

/// Honest outcome of a real family-creation attempt.
///
/// There is deliberately no `createdLocally`/mock outcome: a family exists
/// only when the server confirmed it.
enum FamilyCreationOutcome {
  /// The server confirmed the family and returned its identifier.
  created,

  /// No real family-creation source is configured for this composition.
  unavailable,

  /// The principal is not authenticated (or its session ended).
  unauthenticated,

  /// The server denied this principal family creation.
  denied,

  /// The request body failed server validation.
  validation,

  /// The idempotency key was replayed with a different family name.
  conflict,

  /// The server is temporarily unable to create families.
  serviceUnavailable,

  /// The server could not be reached.
  networkUnavailable,

  /// The server response could not be understood.
  invalidResponse,
}

/// Result of a family-creation attempt. [isCreated] is true only for a
/// server-confirmed family.
@immutable
final class FamilyCreationResult {
  const FamilyCreationResult._(this.outcome, {this.familyId, this.displayName});

  const FamilyCreationResult.created({
    required String familyId,
    required String displayName,
  }) : this._(
         FamilyCreationOutcome.created,
         familyId: familyId,
         displayName: displayName,
       );

  const FamilyCreationResult.failed(FamilyCreationOutcome outcome)
    : this._(outcome);

  final FamilyCreationOutcome outcome;

  /// Server-assigned family identifier — present only when [isCreated].
  final String? familyId;

  /// The confirmed family display name — present only when [isCreated].
  final String? displayName;

  bool get isCreated => outcome == FamilyCreationOutcome.created;
}

/// Typed source boundary for real family creation (SCR-FAT-001).
///
/// The main app must never fall back to a local/mock family: an unconfigured
/// composition fails closed through [UnavailableFamilyCreationSource].
abstract interface class FamilyCreationSource {
  Future<FamilyCreationResult> create({
    required String displayName,
    required String idempotencyKey,
  });
}

/// Honest default while a composition root has no family-creation source
/// configured. It reports [FamilyCreationOutcome.unavailable] instead of
/// manufacturing a family.
final class UnavailableFamilyCreationSource implements FamilyCreationSource {
  const UnavailableFamilyCreationSource();

  @override
  Future<FamilyCreationResult> create({
    required String displayName,
    required String idempotencyKey,
  }) async => const FamilyCreationResult.failed(
    FamilyCreationOutcome.unavailable,
  );
}
