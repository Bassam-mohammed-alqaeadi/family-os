import 'package:flutter/foundation.dart';

import 'package:family_os/core/domain/identity_ids.dart';

/// Minimal durable profile data admitted to the real Family Entry slice.
@immutable
final class FamilyChildProfileDraft {
  const FamilyChildProfileDraft({
    required this.displayName,
    required this.ageYears,
    required this.avatarEmoji,
    required this.themeColor,
  });

  final String displayName;
  final int ageYears;
  final String avatarEmoji;
  final String themeColor;
}

enum FamilyChildProfileCreateFailure {
  invalidInput,
  conflict,
  accessDenied,
  sessionInvalid,
  serviceUnavailable,
  networkUnavailable,
  rosterRefreshUnavailable,
  unavailable,
}

@immutable
final class FamilyChildProfileCreateResult {
  const FamilyChildProfileCreateResult.created({required this.childId})
    : failure = null;

  const FamilyChildProfileCreateResult.failed(this.failure) : childId = null;

  final String? childId;
  final FamilyChildProfileCreateFailure? failure;

  bool get isCreated => childId != null;
}

/// Main-app mutation boundary. It deliberately has no local persistence
/// fallback: a normal route either receives a configured remote capability or
/// communicates that creation is unavailable.
abstract interface class FamilyChildProfileSource {
  Future<FamilyChildProfileCreateResult> create({
    required FamilyId familyId,
    required FamilyChildProfileDraft draft,
    required String idempotencyKey,
  });

  void dispose();
}

final class UnavailableFamilyChildProfileSource
    implements FamilyChildProfileSource {
  @override
  Future<FamilyChildProfileCreateResult> create({
    required FamilyId familyId,
    required FamilyChildProfileDraft draft,
    required String idempotencyKey,
  }) async => const FamilyChildProfileCreateResult.failed(
    FamilyChildProfileCreateFailure.unavailable,
  );

  @override
  void dispose() {}
}
