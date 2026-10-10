import 'package:flutter/foundation.dart';

import 'package:family_os/core/domain/identity_ids.dart';

/// Why an invite-code operation did not produce a server fact.
///
/// Closed on purpose: the screens map each value to an honest sentence instead of
/// inventing copy from a raw error body.
enum InviteCodeFailure {
  /// The code is unknown, expired, already used or revoked. The server deliberately gives
  /// one answer for all four, so the screen does too.
  notRedeemable,

  /// The signed-in account already belongs to that family.
  alreadyMember,

  /// The family already holds the maximum number of open codes.
  limitReached,

  /// Too many redemption attempts; try again in a few minutes.
  rateLimited,
  invalidInput,
  accessDenied,
  sessionInvalid,
  serviceUnavailable,
  networkUnavailable,

  /// No server session is configured in this build: nothing was issued or redeemed.
  unavailable,
}

/// A code the server issued, exactly once. The phone keeps it only in memory while the
/// screen is open; the server keeps only its digest.
@immutable
final class IssuedInviteCode {
  const IssuedInviteCode({
    required this.inviteId,
    required this.code,
    required this.role,
    required this.expiresAt,
  });

  final String inviteId;

  /// Display form, `ABCDE-FGHJK`.
  final String code;

  /// `co_guardian` | `child`.
  final String role;
  final DateTime expiresAt;
}

@immutable
final class InviteCodeIssueResult {
  const InviteCodeIssueResult.issued(IssuedInviteCode this.invite)
    : failure = null;

  const InviteCodeIssueResult.failed(InviteCodeFailure this.failure)
    : invite = null;

  final IssuedInviteCode? invite;
  final InviteCodeFailure? failure;

  bool get isIssued => invite != null;
}

@immutable
final class InviteCodeRevokeResult {
  const InviteCodeRevokeResult.revoked() : failure = null;

  const InviteCodeRevokeResult.failed(InviteCodeFailure this.failure);

  final InviteCodeFailure? failure;

  bool get isRevoked => failure == null;
}

/// The server-confirmed fact of joining a family with a code.
@immutable
final class InviteCodeRedeemResult {
  const InviteCodeRedeemResult.joined({
    required String this.familyId,
    required String this.familyDisplayName,
    required String this.role,
  }) : failure = null;

  const InviteCodeRedeemResult.failed(InviteCodeFailure this.failure)
    : familyId = null,
      familyDisplayName = null,
      role = null;

  final String? familyId;
  final String? familyDisplayName;
  final String? role;
  final InviteCodeFailure? failure;

  bool get isJoined => familyId != null;
}

/// Main-app invite-code boundary (owner decision 2026-10-10: invites by code).
///
/// Replaces the phone-local invite storage for the real journey: a guardian's code exists
/// only when the server issued it, and joining exists only when the server created the
/// membership. There is no local fallback; an unconfigured build answers `unavailable`.
abstract interface class FamilyInviteCodeSource {
  Future<InviteCodeIssueResult> issue({
    required FamilyId familyId,
    required String role,
    required String idempotencyKey,
  });

  Future<InviteCodeRevokeResult> revoke({
    required FamilyId familyId,
    required String inviteId,
    required String idempotencyKey,
  });

  Future<InviteCodeRedeemResult> redeem({
    required String code,
    required String idempotencyKey,
  });

  void dispose();
}

final class UnavailableFamilyInviteCodeSource
    implements FamilyInviteCodeSource {
  @override
  Future<InviteCodeIssueResult> issue({
    required FamilyId familyId,
    required String role,
    required String idempotencyKey,
  }) async => const InviteCodeIssueResult.failed(InviteCodeFailure.unavailable);

  @override
  Future<InviteCodeRevokeResult> revoke({
    required FamilyId familyId,
    required String inviteId,
    required String idempotencyKey,
  }) async =>
      const InviteCodeRevokeResult.failed(InviteCodeFailure.unavailable);

  @override
  Future<InviteCodeRedeemResult> redeem({
    required String code,
    required String idempotencyKey,
  }) async =>
      const InviteCodeRedeemResult.failed(InviteCodeFailure.unavailable);

  @override
  void dispose() {}
}
