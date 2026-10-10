import 'package:flutter/foundation.dart';

/// Why a real family creation did not produce a server family.
///
/// The vocabulary is closed on purpose: a screen maps each refusal to an honest
/// state instead of inventing copy from a raw error body.
enum FamilyCreateFailure {
  invalidInput,
  conflict,
  accessDenied,
  sessionInvalid,
  serviceUnavailable,
  networkUnavailable,
  unavailable,
}

/// The server-confirmed fact of a created family.
///
/// [familyId] is the durable server identifier the next onboarding steps
/// (add child, device pairing) are addressed with. It is produced only by the
/// server's 201 response — never minted locally — so a later step cannot build
/// a path around an identifier the server never issued.
@immutable
final class FamilyCreateResult {
  const FamilyCreateResult.created({
    required this.familyId,
    required this.displayName,
  }) : failure = null;

  const FamilyCreateResult.failed(this.failure)
    : familyId = null,
      displayName = null;

  final String? familyId;
  final String? displayName;
  final FamilyCreateFailure? failure;

  bool get isCreated => familyId != null;
}

/// Main-app family-creation boundary.
///
/// Like [FamilyChildProfileSource], it deliberately has no local persistence
/// fallback: the normal route either receives a configured remote capability or
/// communicates that creation is unavailable. The mock seam lives in the
/// feature's test helpers only.
abstract interface class FamilyCreationSource {
  Future<FamilyCreateResult> createFamily({
    required String displayName,
    required String idempotencyKey,
  });

  void dispose();
}

final class UnavailableFamilyCreationSource implements FamilyCreationSource {
  @override
  Future<FamilyCreateResult> createFamily({
    required String displayName,
    required String idempotencyKey,
  }) async =>
      const FamilyCreateResult.failed(FamilyCreateFailure.unavailable);

  @override
  void dispose() {}
}
