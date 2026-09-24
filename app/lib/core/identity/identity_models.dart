import 'package:flutter/foundation.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';

@immutable
final class Account {
  const Account({required this.id, this.email, this.deactivatedAt});
  final AccountId id;
  final String? email;
  final DateTime? deactivatedAt;

  bool get isDeactivated => deactivatedAt != null;

  Account copyWith({String? email, DateTime? deactivatedAt}) {
    return Account(
      id: id,
      email: email ?? this.email,
      deactivatedAt: deactivatedAt ?? this.deactivatedAt,
    );
  }
}

@immutable
final class Family {
  const Family({required this.id, required this.name, required this.ownerMemberId});
  final FamilyId id;
  final String name;
  final MemberId ownerMemberId;

  Family copyWith({String? name, MemberId? ownerMemberId}) {
    return Family(
      id: id,
      name: name ?? this.name,
      ownerMemberId: ownerMemberId ?? this.ownerMemberId,
    );
  }
}

@immutable
final class FamilyMembership {
  const FamilyMembership({
    required this.id,
    required this.accountId,
    required this.familyId,
    required this.role,
    this.tier = MembershipTier.coParent,
    this.motherLevel,
    this.isPrimaryOwner = false,
  });

  final MemberId id;
  final AccountId accountId;
  final FamilyId familyId;
  final AppRole role;
  final MembershipTier tier;
  final MotherLevel? motherLevel;
  final bool isPrimaryOwner;

  FamilyMembership copyWith({
    MembershipTier? tier,
    MotherLevel? motherLevel,
    bool? isPrimaryOwner,
  }) {
    return FamilyMembership(
      id: id,
      accountId: accountId,
      familyId: familyId,
      role: role,
      tier: tier ?? this.tier,
      motherLevel: motherLevel ?? this.motherLevel,
      isPrimaryOwner: isPrimaryOwner ?? this.isPrimaryOwner,
    );
  }
}

enum MembershipTier { primary, coParent }

enum OwnershipTransferResult { success, denied, ineligible }

@immutable
final class ChildIdentity {
  const ChildIdentity({
    required this.id,
    required this.familyId,
    this.childLogoutAllowed = false,
  });

  final ChildId id;
  final FamilyId familyId;
  final bool childLogoutAllowed;

  ChildIdentity copyWith({bool? childLogoutAllowed}) {
    return ChildIdentity(
      id: id,
      familyId: familyId,
      childLogoutAllowed: childLogoutAllowed ?? this.childLogoutAllowed,
    );
  }
}

@immutable
final class DeviceIdentity {
  const DeviceIdentity({
    required this.id,
    required this.familyId,
    required this.childId,
  });

  final DeviceId id;
  final FamilyId familyId;
  final ChildId childId;
}

@immutable
final class Enrollment {
  const Enrollment({
    required this.id,
    required this.deviceId,
    required this.familyId,
    required this.childId,
    required this.createdAt,
    this.state = EnrollmentState.enrolled,
    this.pairingTokenId,
    this.endedAt,
    this.childLogoutAllowed = false,
  });

  final EnrollmentId id;
  final DeviceId deviceId;
  final FamilyId familyId;
  final ChildId childId;
  final DateTime createdAt;
  final EnrollmentState state;
  final PairingTokenId? pairingTokenId;
  final DateTime? endedAt;
  final bool childLogoutAllowed;

  bool get isActive => state == EnrollmentState.enrolled;
  bool get isPairingPending => state == EnrollmentState.pairingPending;
  bool get isClosed =>
      state == EnrollmentState.revoked ||
      state == EnrollmentState.lost ||
      state == EnrollmentState.decommissioned;

  Enrollment copyWith({
    EnrollmentState? state,
    PairingTokenId? pairingTokenId,
    DateTime? endedAt,
    bool? childLogoutAllowed,
  }) {
    return Enrollment(
      id: id,
      deviceId: deviceId,
      familyId: familyId,
      childId: childId,
      createdAt: createdAt,
      state: state ?? this.state,
      pairingTokenId: pairingTokenId ?? this.pairingTokenId,
      endedAt: endedAt ?? this.endedAt,
      childLogoutAllowed: childLogoutAllowed ?? this.childLogoutAllowed,
    );
  }
}

enum EnrollmentState {
  unenrolled,
  pairingPending,
  enrolled,
  revoked,
  lost,
  decommissioned,
}

@immutable
final class Session {
  const Session({
    required this.id,
    required this.accountId,
    required this.startedAt,
    this.endedAt,
    this.expiresAt,
    this.revokedAt,
    this.restoredAt,
  });

  final SessionId id;
  final AccountId accountId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final DateTime? expiresAt;
  final DateTime? revokedAt;
  final DateTime? restoredAt;

  bool get isActive => endedAt == null;
  bool get isRevoked => revokedAt != null;
  bool isExpiredAt(DateTime nowUtc) =>
      expiresAt != null && !nowUtc.isBefore(expiresAt!.toUtc());

  Session copyWith({
    DateTime? endedAt,
    DateTime? expiresAt,
    DateTime? revokedAt,
    DateTime? restoredAt,
  }) {
    return Session(
      id: id,
      accountId: accountId,
      startedAt: startedAt,
      endedAt: endedAt ?? this.endedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      revokedAt: revokedAt ?? this.revokedAt,
      restoredAt: restoredAt ?? this.restoredAt,
    );
  }
}

@immutable
final class ActiveFamilyContext {
  const ActiveFamilyContext({
    required this.sessionId,
    required this.accountId,
    required this.membershipId,
    required this.familyId,
  });

  final SessionId sessionId;
  final AccountId accountId;
  final MemberId membershipId;
  final FamilyId familyId;
}

@immutable
final class AuthorizationContext {
  const AuthorizationContext({
    required this.activeFamily,
    required this.role,
    required this.motherLevel,
    required this.membershipTier,
    required this.isPrimaryOwner,
  });

  final ActiveFamilyContext activeFamily;
  final AppRole role;
  final MotherLevel motherLevel;
  final MembershipTier membershipTier;
  final bool isPrimaryOwner;

  bool get isFather => role == AppRole.father;
  bool get isMother => role == AppRole.mother;
  bool get isChild => role == AppRole.child;

  bool get canSetFamilyRules {
    if (isFather) return true;
    if (isMother) return motherLevel == MotherLevel.full;
    return false;
  }

  bool get canApproveChildRequests {
    if (isFather) return true;
    if (isMother) {
      return motherLevel == MotherLevel.partner || motherLevel == MotherLevel.full;
    }
    return false;
  }

  bool get canInviteAdults => isPrimaryOwner && isFather;
  bool get canLeaveFamily => !isPrimaryOwner;
}

@immutable
final class ChildScope {
  const ChildScope({required this.familyId, required this.childId});
  final FamilyId familyId;
  final ChildId childId;
}

@immutable
final class DeviceScope {
  const DeviceScope({
    required this.familyId,
    required this.childId,
    required this.deviceId,
    required this.enrollmentId,
  });

  final FamilyId familyId;
  final ChildId childId;
  final DeviceId deviceId;
  final EnrollmentId enrollmentId;
}

enum InviteLifecycleState { created, active, accepted, expired, revoked }

@immutable
final class AdultInvite {
  const AdultInvite({
    required this.id,
    required this.tokenId,
    required this.familyId,
    required this.target,
    required this.level,
    required this.createdByMemberId,
    required this.createdAt,
    required this.expiresAt,
    this.acceptedByAccountId,
    this.acceptedAt,
    this.revokedAt,
    this.replacedByInviteId,
  });

  final InviteId id;
  final InviteTokenId tokenId;
  final FamilyId familyId;
  final String target;
  final MotherLevel level;
  final MemberId createdByMemberId;
  final DateTime createdAt;
  final DateTime expiresAt;
  final AccountId? acceptedByAccountId;
  final DateTime? acceptedAt;
  final DateTime? revokedAt;
  final InviteId? replacedByInviteId;

  InviteLifecycleState stateAt(DateTime nowUtc) {
    if (acceptedAt != null) return InviteLifecycleState.accepted;
    if (revokedAt != null || replacedByInviteId != null) {
      return InviteLifecycleState.revoked;
    }
    if (!nowUtc.isBefore(expiresAt.toUtc())) return InviteLifecycleState.expired;
    if (nowUtc.isBefore(createdAt.toUtc())) return InviteLifecycleState.created;
    return InviteLifecycleState.active;
  }

  bool isActiveAt(DateTime nowUtc) => stateAt(nowUtc) == InviteLifecycleState.active;

  AdultInvite copyWith({
    MotherLevel? level,
    AccountId? acceptedByAccountId,
    DateTime? acceptedAt,
    DateTime? revokedAt,
    InviteId? replacedByInviteId,
    InviteTokenId? tokenId,
    DateTime? expiresAt,
  }) {
    return AdultInvite(
      id: id,
      tokenId: tokenId ?? this.tokenId,
      familyId: familyId,
      target: target,
      level: level ?? this.level,
      createdByMemberId: createdByMemberId,
      createdAt: createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      acceptedByAccountId: acceptedByAccountId ?? this.acceptedByAccountId,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      revokedAt: revokedAt ?? this.revokedAt,
      replacedByInviteId: replacedByInviteId ?? this.replacedByInviteId,
    );
  }
}

enum InviteAuditMutation { created, resent, accepted, expired, revoked }

@immutable
final class InviteAuditEntry {
  const InviteAuditEntry({
    required this.inviteId,
    required this.familyId,
    required this.mutation,
    required this.actorMemberId,
    required this.at,
    this.note,
  });

  final InviteId inviteId;
  final FamilyId familyId;
  final InviteAuditMutation mutation;
  final MemberId actorMemberId;
  final DateTime at;
  final String? note;
}
