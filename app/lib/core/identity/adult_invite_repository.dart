import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/identity/identity_models.dart';
import 'package:family_os/core/identity/identity_runtime.dart';

class InviteMutationDenied implements Exception {
  InviteMutationDenied(this.message);
  final String message;
  @override
  String toString() => 'InviteMutationDenied($message)';
}

abstract class AdultInviteRepository {
  List<AdultInvite> listByFamily(FamilyId familyId);
  AdultInvite? latestForTarget(FamilyId familyId, String target);
  AdultInvite? findByToken(InviteTokenId tokenId);
  List<InviteAuditEntry> auditLog();
  AdultInvite createInvite({
    required FamilyId familyId,
    required String target,
    required MotherLevel level,
    required MemberId actorMemberId,
  });
  AdultInvite resendInvite({
    required InviteId inviteId,
    required MemberId actorMemberId,
  });
  AdultInvite acceptInvite({
    required InviteTokenId tokenId,
    required AccountId acceptedByAccountId,
    required MemberId actorMemberId,
  });
  bool revokeInvite({
    required InviteId inviteId,
    required MemberId actorMemberId,
  });
  int expireStale({DateTime? now});
  void resetForTests();
}

final class InMemoryAdultInviteRepository implements AdultInviteRepository {
  InMemoryAdultInviteRepository({
    required IdentityRuntime runtime,
    DateTime Function()? nowProvider,
    this.online = true,
  }) : _runtime = runtime,
       _nowProvider = nowProvider ?? _defaultNow;

  final IdentityRuntime _runtime;
  final DateTime Function() _nowProvider;
  final List<AdultInvite> _invites = <AdultInvite>[];
  final List<InviteAuditEntry> _audit = <InviteAuditEntry>[];
  var _sequence = 0;

  /// High-risk invite mutations are online-authority semantics, even on mocks.
  bool online;

  @override
  List<AdultInvite> listByFamily(FamilyId familyId) {
    final now = _nowProvider().toUtc();
    return _invites
        .where((i) => i.familyId == familyId)
        .map((i) => _markExpiredIfNeeded(i, now))
        .toList(growable: false);
  }

  @override
  AdultInvite? latestForTarget(FamilyId familyId, String target) {
    final normalized = target.trim().toLowerCase();
    AdultInvite? latest;
    for (final invite in _invites) {
      if (invite.familyId != familyId) continue;
      if (invite.target != normalized) continue;
      if (latest == null || invite.createdAt.isAfter(latest.createdAt)) {
        latest = invite;
      }
    }
    return latest;
  }

  @override
  AdultInvite? findByToken(InviteTokenId tokenId) => _findByToken(tokenId);

  @override
  List<InviteAuditEntry> auditLog() =>
      List<InviteAuditEntry>.unmodifiable(_audit);

  @override
  AdultInvite createInvite({
    required FamilyId familyId,
    required String target,
    required MotherLevel level,
    required MemberId actorMemberId,
  }) {
    _requireOnline();
    _assertPrimaryFatherCanInvite(familyId);
    final now = _nowProvider().toUtc();
    _expireStaleInternal(now);
    final normalized = target.trim().toLowerCase();
    if (normalized.isEmpty) {
      throw InviteMutationDenied('invite target cannot be empty');
    }
    _invalidateActiveByTarget(
      familyId: familyId,
      target: normalized,
      actorMemberId: actorMemberId,
      now: now,
      reason: 'replaced',
    );
    final invite = AdultInvite(
      id: _nextInviteId(now),
      tokenId: _nextInviteTokenId(now),
      familyId: familyId,
      target: normalized,
      level: level,
      createdByMemberId: actorMemberId,
      createdAt: now,
      expiresAt: now.add(const Duration(days: 7)),
    );
    _invites.add(invite);
    _audit.add(
      InviteAuditEntry(
        inviteId: invite.id,
        familyId: familyId,
        mutation: InviteAuditMutation.created,
        actorMemberId: actorMemberId,
        at: now,
      ),
    );
    return invite;
  }

  @override
  AdultInvite resendInvite({
    required InviteId inviteId,
    required MemberId actorMemberId,
  }) {
    _requireOnline();
    final current = _findById(inviteId);
    if (current == null) {
      throw InviteMutationDenied('invite not found');
    }
    _assertPrimaryFatherCanInvite(current.familyId);
    final now = _nowProvider().toUtc();
    final replacementId = _nextInviteId(now);
    _setInvite(
      current.copyWith(revokedAt: now, replacedByInviteId: replacementId),
    );
    _audit.add(
      InviteAuditEntry(
        inviteId: current.id,
        familyId: current.familyId,
        mutation: InviteAuditMutation.resent,
        actorMemberId: actorMemberId,
        at: now,
      ),
    );
    return createInvite(
      familyId: current.familyId,
      target: current.target,
      level: current.level,
      actorMemberId: actorMemberId,
    );
  }

  @override
  AdultInvite acceptInvite({
    required InviteTokenId tokenId,
    required AccountId acceptedByAccountId,
    required MemberId actorMemberId,
  }) {
    _requireOnline();
    final now = _nowProvider().toUtc();
    _expireStaleInternal(now);
    final invite = _findByToken(tokenId);
    if (invite == null) {
      throw InviteMutationDenied('invite token not found');
    }
    if (!invite.isActiveAt(now)) {
      throw InviteMutationDenied('invite is not active');
    }
    final accepted = invite.copyWith(
      acceptedByAccountId: acceptedByAccountId,
      acceptedAt: now,
    );
    _setInvite(accepted);
    _runtime.acceptInviteAsMembership(
      accountId: acceptedByAccountId,
      familyId: invite.familyId,
      motherLevel: invite.level,
      memberId: MemberId(
        'mem_${acceptedByAccountId.value}_${now.microsecondsSinceEpoch}',
      ),
    );
    _audit.add(
      InviteAuditEntry(
        inviteId: invite.id,
        familyId: invite.familyId,
        mutation: InviteAuditMutation.accepted,
        actorMemberId: actorMemberId,
        at: now,
      ),
    );
    return accepted;
  }

  @override
  bool revokeInvite({
    required InviteId inviteId,
    required MemberId actorMemberId,
  }) {
    _requireOnline();
    final invite = _findById(inviteId);
    if (invite == null) return false;
    _assertPrimaryFatherCanInvite(invite.familyId);
    final now = _nowProvider().toUtc();
    final next = invite.copyWith(revokedAt: now);
    _setInvite(next);
    _audit.add(
      InviteAuditEntry(
        inviteId: invite.id,
        familyId: invite.familyId,
        mutation: InviteAuditMutation.revoked,
        actorMemberId: actorMemberId,
        at: now,
      ),
    );
    return true;
  }

  @override
  int expireStale({DateTime? now}) =>
      _expireStaleInternal((now ?? _nowProvider()).toUtc());

  @override
  void resetForTests() {
    _invites.clear();
    _audit.clear();
    _sequence = 0;
    online = true;
  }

  int _expireStaleInternal(DateTime now) {
    var count = 0;
    for (var i = 0; i < _invites.length; i++) {
      final current = _invites[i];
      if (current.stateAt(now) == InviteLifecycleState.expired) {
        count++;
        _audit.add(
          InviteAuditEntry(
            inviteId: current.id,
            familyId: current.familyId,
            mutation: InviteAuditMutation.expired,
            actorMemberId: current.createdByMemberId,
            at: now,
          ),
        );
      }
    }
    return count;
  }

  AdultInvite? _findById(InviteId id) {
    for (final invite in _invites) {
      if (invite.id == id) return invite;
    }
    return null;
  }

  AdultInvite? _findByToken(InviteTokenId tokenId) {
    for (final invite in _invites) {
      if (invite.tokenId == tokenId) return invite;
    }
    return null;
  }

  void _setInvite(AdultInvite next) {
    for (var i = 0; i < _invites.length; i++) {
      if (_invites[i].id == next.id) {
        _invites[i] = next;
        return;
      }
    }
    _invites.add(next);
  }

  AdultInvite _markExpiredIfNeeded(AdultInvite invite, DateTime now) {
    if (invite.stateAt(now) == InviteLifecycleState.expired) {
      return invite;
    }
    return invite;
  }

  void _invalidateActiveByTarget({
    required FamilyId familyId,
    required String target,
    required MemberId actorMemberId,
    required DateTime now,
    required String reason,
  }) {
    for (var i = 0; i < _invites.length; i++) {
      final invite = _invites[i];
      if (invite.familyId != familyId) continue;
      if (invite.target != target) continue;
      if (!invite.isActiveAt(now)) continue;
      final replacementId = _nextInviteId(now);
      _invites[i] = invite.copyWith(
        revokedAt: now,
        replacedByInviteId: replacementId,
      );
      _audit.add(
        InviteAuditEntry(
          inviteId: invite.id,
          familyId: familyId,
          mutation: InviteAuditMutation.revoked,
          actorMemberId: actorMemberId,
          at: now,
          note: reason,
        ),
      );
    }
  }

  /// Primary father only — invite/resend/revoke are nuclear membership actions.
  void _assertPrimaryFatherCanInvite(FamilyId familyId) {
    final memberships = _runtime.membershipsForAccount(_runtime.account.id);
    FamilyMembership? membership;
    for (final candidate in memberships) {
      if (candidate.familyId == familyId) {
        membership = candidate;
        break;
      }
    }
    if (membership == null ||
        !membership.isPrimaryOwner ||
        membership.role != AppRole.father) {
      throw InviteMutationDenied(
        'only primary father can invite adults for ${familyId.value}',
      );
    }
  }

  void _requireOnline() {
    if (online) return;
    throw InviteMutationDenied(
      'high-risk invite mutation requires online authority',
    );
  }

  InviteId _nextInviteId(DateTime now) {
    _sequence++;
    return InviteId('inv_${now.microsecondsSinceEpoch}_$_sequence');
  }

  InviteTokenId _nextInviteTokenId(DateTime now) {
    _sequence++;
    return InviteTokenId('tok_${now.microsecondsSinceEpoch}_$_sequence');
  }
}

DateTime _defaultNow() => DateTime.now().toUtc();

final InMemoryAdultInviteRepository stage1AdultInviteRepository =
    InMemoryAdultInviteRepository(runtime: stage1IdentityRuntime);
