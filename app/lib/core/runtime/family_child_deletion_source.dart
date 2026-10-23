import 'package:flutter/foundation.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/identity/identity_runtime.dart';

/// Why the child deletion could not be completed.
enum FamilyChildDeleteFailure {
  invalidInput,
  notFound,
  conflict,
  accessDenied,
  sessionInvalid,
  serviceUnavailable,
  networkUnavailable,
  unavailable,
}

@immutable
final class FamilyChildDeleteResult {
  const FamilyChildDeleteResult.success() : failure = null;

  const FamilyChildDeleteResult.failed(this.failure);

  final FamilyChildDeleteFailure? failure;

  bool get isSuccess => failure == null;
}

abstract interface class FamilyChildDeletionSource {
  Future<FamilyChildDeleteResult> deleteChild({
    required FamilyId familyId,
    required ChildId childId,
    String? idempotencyKey,
  });

  void dispose();
}

final class UnavailableFamilyChildDeletionSource
    implements FamilyChildDeletionSource {
  @override
  Future<FamilyChildDeleteResult> deleteChild({
    required FamilyId familyId,
    required ChildId childId,
    String? idempotencyKey,
  }) async => const FamilyChildDeleteResult.failed(
    FamilyChildDeleteFailure.unavailable,
  );

  @override
  void dispose() {}
}

final class LocalFamilyChildDeletionSource implements FamilyChildDeletionSource {
  LocalFamilyChildDeletionSource(this._runtime);

  final IdentityRuntime _runtime;

  @override
  Future<FamilyChildDeleteResult> deleteChild({
    required FamilyId familyId,
    required ChildId childId,
    String? idempotencyKey,
  }) async {
    final deleted = _runtime.deleteChild(
      familyId: familyId,
      childId: childId,
    );
    if (deleted) {
      return const FamilyChildDeleteResult.success();
    }
    return const FamilyChildDeleteResult.failed(
      FamilyChildDeleteFailure.notFound,
    );
  }

  @override
  void dispose() {}
}

