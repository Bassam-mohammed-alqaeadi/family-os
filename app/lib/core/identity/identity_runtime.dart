import 'package:flutter/foundation.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/identity/family_context_store.dart';
import 'package:family_os/core/identity/identity_models.dart';

class IdentityInvariantViolation implements Exception {
  IdentityInvariantViolation(this.message);
  final String message;
  @override
  String toString() => 'IdentityInvariantViolation($message)';
}

/// Local identity authority chain for System #3.
///
/// Session -> Account -> FamilyMembership -> Role -> MotherLevel ->
/// AuthorizationContext
class IdentityRuntime extends ChangeNotifier {
  IdentityRuntime({
    required Account account,
    required Session session,
    required List<Family> families,
    required List<FamilyMembership> memberships,
    required FamilyId activeFamilyId,
    required ChildScope activeChildScope,
    List<ChildIdentity> children = const [],
    List<DeviceIdentity> devices = const [],
    List<Enrollment> enrollments = const [],
    List<Account>? accounts,
    List<Session>? sessions,
    SessionId? activeSessionId,
    FamilyContextStore? familyContextStore,
    DateTime Function()? nowProvider,
  }) : _account = account,
       _session = session,
       _accounts = List<Account>.from(accounts ?? [account]),
       _sessions = List<Session>.from(sessions ?? [session]),
       _families = List<Family>.from(families),
       _memberships = List<FamilyMembership>.from(memberships),
       _children = List<ChildIdentity>.from(children),
       _devices = List<DeviceIdentity>.from(devices),
       _enrollments = List<Enrollment>.from(enrollments),
       _activeSessionId = activeSessionId ?? session.id,
       _familyContextStore = familyContextStore,
       _nowProvider = nowProvider ?? _defaultNow,
       _activeFamilyId = activeFamilyId,
       _activeChildScope = activeChildScope {
    _syncActiveAccountFromSession();
    _activeFamilyId = _resolveInitialFamily(activeFamilyId);
    _activeChildScope = _resolveInitialChildScope(activeChildScope);
    _assertActiveMembershipForFamily(_activeFamilyId);
    _assertChildInFamily(_activeChildScope.childId, _activeChildScope.familyId);
  }

  Account _account;
  Session _session;
  final List<Account> _accounts;
  final List<Session> _sessions;
  final List<Family> _families;
  final List<FamilyMembership> _memberships;
  final List<ChildIdentity> _children;
  final List<DeviceIdentity> _devices;
  final List<Enrollment> _enrollments;
  final Set<String> _endedChildSessions = <String>{};
  final FamilyContextStore? _familyContextStore;
  final DateTime Function() _nowProvider;

  SessionId _activeSessionId;
  FamilyId _activeFamilyId;
  ChildScope _activeChildScope;
  AppRole? _legacyRoleFallback;

  Account get account => _account;
  Session get session => _session;
  List<Account> get accounts => List<Account>.unmodifiable(_accounts);
  List<Session> get sessions => List<Session>.unmodifiable(_sessions);
  Session get activeSession => _sessionById(_activeSessionId);
  SessionId get activeSessionId => _activeSessionId;
  bool get hasActiveSession => _isSessionUsable(activeSession);
  bool get needsFamilySelector => _membershipsForActiveAccount().length > 1;

  List<Session> get adultSessions {
    final adultAccountIds = _memberships
        .where((m) => m.role == AppRole.father || m.role == AppRole.mother)
        .map((m) => m.accountId)
        .toSet();
    return _sessions
        .where((s) => adultAccountIds.contains(s.accountId))
        .toList();
  }

  List<FamilyMembership> membershipsForAccount(AccountId accountId) {
    return _memberships.where((m) => m.accountId == accountId).toList();
  }

  List<FamilyMembership> adultMembershipsForFamily(FamilyId familyId) {
    return _memberships
        .where(
          (membership) =>
              membership.familyId == familyId &&
              (membership.role == AppRole.father ||
                  membership.role == AppRole.mother),
        )
        .toList(growable: false);
  }

  List<Family> get families => List<Family>.unmodifiable(_families);
  List<ChildIdentity> get children =>
      List<ChildIdentity>.unmodifiable(_children);
  List<DeviceIdentity> get devices =>
      List<DeviceIdentity>.unmodifiable(_devices);
  List<Enrollment> get enrollments =>
      List<Enrollment>.unmodifiable(_enrollments);

  FamilyId get activeFamilyId => _activeFamilyId;
  ChildScope get activeChildScope => _activeChildScope;
  ChildId get activeChildId => _activeChildScope.childId;

  FamilyMembership get activeMembership =>
      _membershipForFamily(_activeFamilyId);

  ActiveFamilyContext get activeFamilyContext => ActiveFamilyContext(
    sessionId: _session.id,
    accountId: _account.id,
    membershipId: activeMembership.id,
    familyId: _activeFamilyId,
  );

  AuthorizationContext get authorizationContext {
    final membership = activeMembership;
    final role = _legacyRoleFallback ?? membership.role;
    final motherLevel = role == AppRole.mother
        ? (membership.motherLevel ?? MotherLevel.observer)
        : MotherLevel.full;
    return AuthorizationContext(
      activeFamily: activeFamilyContext,
      role: role,
      motherLevel: motherLevel,
      membershipTier: membership.tier,
      isPrimaryOwner: membership.isPrimaryOwner,
    );
  }

  void switchActiveFamily(FamilyId familyId) {
    _assertActiveMembershipForFamily(familyId);
    _activeFamilyId = familyId;
    final childInFamily = _children
        .where((c) => c.familyId == familyId)
        .toList();
    if (childInFamily.isNotEmpty) {
      _activeChildScope = ChildScope(
        familyId: familyId,
        childId: childInFamily.first.id,
      );
    }
    _persistActiveFamily();
    notifyListeners();
  }

  void setActiveChild(ChildId childId) {
    _assertChildInFamily(childId, _activeFamilyId);
    _activeChildScope = ChildScope(familyId: _activeFamilyId, childId: childId);
    notifyListeners();
  }

  /// Temporary compatibility hook for role-picker flows.
  void setLegacyRoleFallback(AppRole? role) {
    _legacyRoleFallback = role;
    notifyListeners();
  }

  SessionId startSession({
    required AccountId accountId,
    Duration ttl = const Duration(days: 30),
    DateTime? now,
  }) {
    final stamp = (now ?? _nowProvider()).toUtc();
    final id = SessionId('sess_${stamp.microsecondsSinceEpoch}');
    _sessions.add(
      Session(
        id: id,
        accountId: accountId,
        startedAt: stamp,
        expiresAt: stamp.add(ttl),
      ),
    );
    _activeSessionId = id;
    _syncActiveAccountFromSession();
    _activeFamilyId = _resolveInitialFamily(_activeFamilyId);
    _activeChildScope = _resolveInitialChildScope(_activeChildScope);
    _persistActiveFamily();
    notifyListeners();
    return id;
  }

  void switchSession(SessionId sessionId) {
    final target = _sessionById(sessionId);
    if (!_isSessionUsable(target)) {
      throw IdentityInvariantViolation(
        'session ${sessionId.value} is not usable',
      );
    }
    _activeSessionId = sessionId;
    _syncActiveAccountFromSession();
    _activeFamilyId = _resolveInitialFamily(_activeFamilyId);
    _activeChildScope = _resolveInitialChildScope(_activeChildScope);
    _persistActiveFamily();
    notifyListeners();
  }

  bool logoutCurrentSession({DateTime? at}) {
    final idx = _sessions.indexWhere((s) => s.id == _activeSessionId);
    if (idx < 0) return false;
    final stamp = (at ?? _nowProvider()).toUtc();
    _sessions[idx] = _sessions[idx].copyWith(endedAt: stamp);
    final replacement = _sessions.firstWhere(
      _isSessionUsable,
      orElse: () => _sessions[idx],
    );
    _activeSessionId = replacement.id;
    _syncActiveAccountFromSession();
    _activeFamilyId = _resolveInitialFamily(_activeFamilyId);
    _activeChildScope = _resolveInitialChildScope(_activeChildScope);
    _persistActiveFamily();
    notifyListeners();
    return true;
  }

  void logoutAll({DateTime? at}) {
    final stamp = (at ?? _nowProvider()).toUtc();
    for (var i = 0; i < _sessions.length; i++) {
      _sessions[i] = _sessions[i].copyWith(endedAt: stamp);
    }
    _syncActiveAccountFromSession();
    notifyListeners();
  }

  void deactivateAccount({DateTime? at}) {
    final stamp = (at ?? _nowProvider()).toUtc();
    final accountId = _account.id;
    for (var i = 0; i < _sessions.length; i++) {
      if (_sessions[i].accountId == accountId) {
        _sessions[i] = _sessions[i].copyWith(endedAt: stamp, revokedAt: stamp);
      }
    }
    final accountIndex = _accounts.indexWhere((a) => a.id == accountId);
    _account = _account.copyWith(deactivatedAt: stamp);
    if (accountIndex >= 0) {
      _accounts[accountIndex] = _account;
    }
    _session = _sessionById(_activeSessionId);
    notifyListeners();
  }

  bool expireSession(SessionId sessionId, {DateTime? at}) {
    final idx = _sessions.indexWhere((s) => s.id == sessionId);
    if (idx < 0) return false;
    final stamp = (at ?? _nowProvider()).toUtc();
    final current = _sessions[idx];
    _sessions[idx] = current.copyWith(expiresAt: stamp);
    notifyListeners();
    return true;
  }

  bool restoreSession(
    SessionId sessionId, {
    Duration ttl = const Duration(days: 30),
  }) {
    final idx = _sessions.indexWhere((s) => s.id == sessionId);
    if (idx < 0) return false;
    final current = _sessions[idx];
    if (current.isRevoked || current.endedAt != null) return false;
    final now = _nowProvider().toUtc();
    if (!current.isExpiredAt(now)) return true;
    _sessions[idx] = current.copyWith(expiresAt: now.add(ttl), restoredAt: now);
    notifyListeners();
    return true;
  }

  bool revokeSession(SessionId sessionId, {DateTime? at}) {
    final idx = _sessions.indexWhere((s) => s.id == sessionId);
    if (idx < 0) return false;
    final stamp = (at ?? _nowProvider()).toUtc();
    _sessions[idx] = _sessions[idx].copyWith(revokedAt: stamp);
    if (_activeSessionId == sessionId) {
      final replacement = _sessions.firstWhere(
        _isSessionUsable,
        orElse: () => _sessions[idx],
      );
      _activeSessionId = replacement.id;
      _syncActiveAccountFromSession();
      _activeFamilyId = _resolveInitialFamily(_activeFamilyId);
      _activeChildScope = _resolveInitialChildScope(_activeChildScope);
      _persistActiveFamily();
    }
    notifyListeners();
    return true;
  }

  bool acceptInviteAsMembership({
    required AccountId accountId,
    required FamilyId familyId,
    required MotherLevel motherLevel,
    required MemberId memberId,
    bool isPrimaryOwner = false,
  }) {
    final exists = _memberships.any(
      (m) => m.accountId == accountId && m.familyId == familyId,
    );
    if (exists) return false;
    _memberships.add(
      FamilyMembership(
        id: memberId,
        accountId: accountId,
        familyId: familyId,
        role: AppRole.mother,
        tier: MembershipTier.coParent,
        motherLevel: motherLevel,
        isPrimaryOwner: isPrimaryOwner,
      ),
    );
    if (_accounts.every((a) => a.id != accountId)) {
      _accounts.add(Account(id: accountId));
    }
    notifyListeners();
    return true;
  }

  bool leaveFamily({required AccountId accountId, required FamilyId familyId}) {
    final idx = _memberships.indexWhere(
      (m) => m.accountId == accountId && m.familyId == familyId,
    );
    if (idx < 0) return false;
    if (_memberships[idx].isPrimaryOwner) return false;
    _memberships.removeAt(idx);
    if (_activeFamilyId == familyId && _account.id == accountId) {
      _activeFamilyId = _resolveInitialFamily(_activeFamilyId);
      _activeChildScope = _resolveInitialChildScope(_activeChildScope);
      _persistActiveFamily();
    }
    notifyListeners();
    return true;
  }

  bool removeAdultMember({
    required FamilyId familyId,
    required MemberId targetMemberId,
  }) {
    final actor = _membershipForFamily(familyId);
    if (!actor.isPrimaryOwner) return false;
    final targetIndex = _memberships.indexWhere(
      (membership) =>
          membership.familyId == familyId &&
          membership.id == targetMemberId &&
          (membership.role == AppRole.father ||
              membership.role == AppRole.mother),
    );
    if (targetIndex < 0) return false;
    final target = _memberships[targetIndex];
    if (target.isPrimaryOwner || target.id == actor.id) return false;
    _memberships.removeAt(targetIndex);
    notifyListeners();
    return true;
  }

  OwnershipTransferResult transferOwnership({
    required FamilyId familyId,
    required MemberId toMemberId,
  }) {
    final actor = _membershipForFamily(familyId);
    if (!actor.isPrimaryOwner) return OwnershipTransferResult.denied;
    final targetIndex = _memberships.indexWhere(
      (membership) =>
          membership.familyId == familyId && membership.id == toMemberId,
    );
    if (targetIndex < 0) return OwnershipTransferResult.ineligible;
    final target = _memberships[targetIndex];
    final isAdult =
        target.role == AppRole.father || target.role == AppRole.mother;
    if (!isAdult || target.isPrimaryOwner || target.id == actor.id) {
      return OwnershipTransferResult.ineligible;
    }
    final actorIndex = _memberships.indexWhere((m) => m.id == actor.id);
    final familyIndex = _families.indexWhere((f) => f.id == familyId);
    if (actorIndex < 0 || familyIndex < 0) {
      return OwnershipTransferResult.ineligible;
    }
    _memberships[actorIndex] = actor.copyWith(
      tier: MembershipTier.coParent,
      isPrimaryOwner: false,
    );
    _memberships[targetIndex] = target.copyWith(
      tier: MembershipTier.primary,
      isPrimaryOwner: true,
    );
    _families[familyIndex] = _families[familyIndex].copyWith(
      ownerMemberId: target.id,
    );
    notifyListeners();
    return OwnershipTransferResult.success;
  }

  bool canAccessChild(ChildScope scope) {
    if (scope.familyId != _activeFamilyId) return false;
    return _children.any(
      (c) => c.id == scope.childId && c.familyId == scope.familyId,
    );
  }

  bool childLogoutAllowed(ChildScope scope) {
    for (final enrollment in _enrollments) {
      if (!enrollment.isActive) continue;
      if (enrollment.familyId != scope.familyId) continue;
      if (enrollment.childId != scope.childId) continue;
      if (enrollment.childLogoutAllowed) return true;
    }
    return _children.any(
      (child) =>
          child.id == scope.childId &&
          child.familyId == scope.familyId &&
          child.childLogoutAllowed,
    );
  }

  void setChildLogoutAllowed({
    required ChildId childId,
    required FamilyId familyId,
    required bool allowed,
  }) {
    _assertChildInFamily(childId, familyId);
    for (var i = 0; i < _enrollments.length; i++) {
      final current = _enrollments[i];
      if (current.familyId != familyId || current.childId != childId) continue;
      _enrollments[i] = current.copyWith(childLogoutAllowed: allowed);
    }
    notifyListeners();
  }

  bool childLogoutAllowedForEnrollment(EnrollmentId enrollmentId) {
    final enrollment = _findEnrollment(enrollmentId);
    return enrollment?.childLogoutAllowed ?? false;
  }

  bool setChildLogoutAllowedForEnrollment({
    required EnrollmentId enrollmentId,
    required bool allowed,
  }) {
    final idx = _enrollments.indexWhere((e) => e.id == enrollmentId);
    if (idx < 0) return false;
    if (!activeMembership.isPrimaryOwner) {
      throw IdentityInvariantViolation(
        'only primary owner can change child logout permission',
      );
    }
    _enrollments[idx] = _enrollments[idx].copyWith(childLogoutAllowed: allowed);
    notifyListeners();
    return true;
  }

  bool canChildLogout(EnrollmentId enrollmentId) {
    final enrollment = _findEnrollment(enrollmentId);
    if (enrollment == null || !enrollment.isActive) return false;
    return enrollment.childLogoutAllowed;
  }

  bool endChildSessionRemotely(EnrollmentId enrollmentId) {
    if (!activeMembership.isPrimaryOwner) {
      throw IdentityInvariantViolation(
        'only primary owner can end a child session remotely',
      );
    }
    final enrollment = _findEnrollment(enrollmentId);
    if (enrollment == null) return false;
    _endedChildSessions.add(enrollment.id.value);
    notifyListeners();
    return true;
  }

  bool isChildSessionEnded(EnrollmentId enrollmentId) =>
      _endedChildSessions.contains(enrollmentId.value);

  ChildIdentity createChild({
    required FamilyId familyId,
    required ChildId childId,
  }) {
    final membership = _membershipForFamily(familyId);
    final canCreate =
        membership.isPrimaryOwner ||
        (membership.role == AppRole.mother &&
            membership.motherLevel == MotherLevel.full);
    if (!canCreate) {
      throw IdentityInvariantViolation(
        'only primary or mother full can create child',
      );
    }
    if (_children.any((c) => c.id == childId)) {
      throw IdentityInvariantViolation(
        'child ${childId.value} already exists in another family',
      );
    }
    final child = ChildIdentity(id: childId, familyId: familyId);
    _children.add(child);
    if (_activeFamilyId == familyId) {
      _activeChildScope = ChildScope(familyId: familyId, childId: childId);
    }
    notifyListeners();
    return child;
  }

  bool deleteChild({required FamilyId familyId, required ChildId childId}) {
    final membership = _membershipForFamily(familyId);
    if (!membership.isPrimaryOwner) {
      throw IdentityInvariantViolation('only primary can delete child');
    }
    final hasActiveEnrollment = _enrollments.any(
      (e) => e.familyId == familyId && e.childId == childId && e.isActive,
    );
    if (hasActiveEnrollment) {
      throw IdentityInvariantViolation(
        'revoke active enrollments before deleting child',
      );
    }
    final idx = _children.indexWhere(
      (c) => c.id == childId && c.familyId == familyId,
    );
    if (idx < 0) return false;
    _children.removeAt(idx);
    _devices.removeWhere((d) => d.familyId == familyId && d.childId == childId);
    _enrollments.removeWhere(
      (e) => e.familyId == familyId && e.childId == childId,
    );
    if (_activeChildScope.childId == childId && _activeFamilyId == familyId) {
      final fallback = _children.where((c) => c.familyId == familyId).toList();
      if (fallback.isNotEmpty) {
        _activeChildScope = ChildScope(
          familyId: familyId,
          childId: fallback.first.id,
        );
      }
    }
    notifyListeners();
    return true;
  }

  Enrollment startPairing({
    required FamilyId familyId,
    required ChildId childId,
    required DeviceId deviceId,
    EnrollmentId? enrollmentId,
    PairingTokenId? pairingTokenId,
    DateTime? at,
  }) {
    _assertChildInFamily(childId, familyId);
    _assertDeviceTransferRequirement(deviceId);
    final now = (at ?? DateTime.now()).toUtc();
    final next = Enrollment(
      id: enrollmentId ?? EnrollmentId('enr_${now.microsecondsSinceEpoch}'),
      deviceId: deviceId,
      familyId: familyId,
      childId: childId,
      createdAt: now,
      state: EnrollmentState.pairingPending,
      pairingTokenId:
          pairingTokenId ??
          PairingTokenId('pair_${now.microsecondsSinceEpoch}'),
    );
    _enrollments.add(next);
    _registerDeviceIfMissing(
      DeviceIdentity(id: deviceId, familyId: familyId, childId: childId),
    );
    notifyListeners();
    return next;
  }

  Enrollment finalizeEnrollment(EnrollmentId enrollmentId, {DateTime? at}) {
    final idx = _enrollments.indexWhere((e) => e.id == enrollmentId);
    if (idx < 0) {
      throw IdentityInvariantViolation(
        'unknown enrollment ${enrollmentId.value}',
      );
    }
    final current = _enrollments[idx];
    if (current.state != EnrollmentState.pairingPending) {
      throw IdentityInvariantViolation(
        'only pairing-pending enrollment can become enrolled',
      );
    }
    _assertMaxActiveDevicesNotExceeded(current.familyId, current.childId);
    final next = current.copyWith(
      state: EnrollmentState.enrolled,
      endedAt: at?.toUtc(),
    );
    _enrollments[idx] = next;
    notifyListeners();
    return next;
  }

  Enrollment createEnrollment({
    required FamilyId familyId,
    required ChildId childId,
    required DeviceId deviceId,
    EnrollmentId? enrollmentId,
    DateTime? at,
  }) {
    final pending = startPairing(
      familyId: familyId,
      childId: childId,
      deviceId: deviceId,
      enrollmentId: enrollmentId,
      at: at,
    );
    return finalizeEnrollment(pending.id, at: at);
  }

  void revokeEnrollment(EnrollmentId enrollmentId, {DateTime? at}) {
    final idx = _enrollments.indexWhere((e) => e.id == enrollmentId);
    if (idx < 0) return;
    final current = _enrollments[idx];
    if (current.isClosed) return;
    // Enrolled devices: Primary-only. Pending pairing cancel is allowed for
    // managers (asserted at repository) so Mother Full can renew tokens.
    if (current.state == EnrollmentState.enrolled &&
        !activeMembership.isPrimaryOwner) {
      throw IdentityInvariantViolation(
        'only primary owner can revoke an enrolled device',
      );
    }
    _enrollments[idx] = current.copyWith(
      state: EnrollmentState.revoked,
      endedAt: (at ?? DateTime.now()).toUtc(),
    );
    notifyListeners();
  }

  void markEnrollmentLost(EnrollmentId enrollmentId, {DateTime? at}) {
    if (!activeMembership.isPrimaryOwner) {
      throw IdentityInvariantViolation(
        'only primary owner can mark an enrollment lost',
      );
    }
    _closeEnrollment(enrollmentId, EnrollmentState.lost, at: at);
  }

  void decommissionEnrollment(EnrollmentId enrollmentId, {DateTime? at}) {
    if (!activeMembership.isPrimaryOwner) {
      throw IdentityInvariantViolation(
        'only primary owner can decommission an enrollment',
      );
    }
    _closeEnrollment(enrollmentId, EnrollmentState.decommissioned, at: at);
  }

  Enrollment? activeEnrollmentForDevice(DeviceId deviceId) {
    for (final enrollment in _enrollments) {
      if (enrollment.deviceId == deviceId && enrollment.isActive) {
        return enrollment;
      }
    }
    return null;
  }

  List<Enrollment> enrollmentsForChild(ChildScope scope) {
    return _enrollments
        .where(
          (e) => e.familyId == scope.familyId && e.childId == scope.childId,
        )
        .toList(growable: false);
  }

  void _closeEnrollment(
    EnrollmentId enrollmentId,
    EnrollmentState state, {
    DateTime? at,
  }) {
    final idx = _enrollments.indexWhere((e) => e.id == enrollmentId);
    if (idx < 0) return;
    final current = _enrollments[idx];
    if (current.isClosed) return;
    _enrollments[idx] = current.copyWith(
      state: state,
      endedAt: (at ?? DateTime.now()).toUtc(),
    );
    notifyListeners();
  }

  void _registerDeviceIfMissing(DeviceIdentity device) {
    final idx = _devices.indexWhere((d) => d.id == device.id);
    if (idx < 0) {
      _devices.add(device);
    }
  }

  void _assertMaxActiveDevicesNotExceeded(FamilyId familyId, ChildId childId) {
    final activeCount = _enrollments
        .where(
          (e) =>
              e.familyId == familyId &&
              e.childId == childId &&
              e.state == EnrollmentState.enrolled,
        )
        .length;
    if (activeCount >= 3) {
      throw IdentityInvariantViolation('max 3 active devices per child');
    }
  }

  /// Device transfer: active enrollment must be revoked (or otherwise closed)
  /// before a new enrollment may bind the same device. Closed terminal states
  /// (`revoked` / `lost` / `decommissioned`) unlock re-enroll; `unenrolled` is
  /// the initial unbound state, not a post-revoke step.
  void _assertDeviceTransferRequirement(DeviceId deviceId) {
    final hasActiveEnrollment = _enrollments.any(
      (e) => e.deviceId == deviceId && e.state == EnrollmentState.enrolled,
    );
    if (hasActiveEnrollment) {
      throw IdentityInvariantViolation(
        'device transfer requires revoke + re-enroll',
      );
    }
  }

  Enrollment? _findEnrollment(EnrollmentId id) {
    for (final enrollment in _enrollments) {
      if (enrollment.id == id) return enrollment;
    }
    return null;
  }

  void _assertChildInFamily(ChildId childId, FamilyId familyId) {
    final matches = _children.where((c) => c.id == childId).toList();
    if (matches.isEmpty) {
      throw IdentityInvariantViolation('unknown child ${childId.value}');
    }
    if (matches.length > 1) {
      throw IdentityInvariantViolation(
        'child ${childId.value} appears in multiple families',
      );
    }
    if (matches.first.familyId != familyId) {
      throw IdentityInvariantViolation(
        'child ${childId.value} is not in family ${familyId.value}',
      );
    }
  }

  FamilyMembership _membershipForFamily(FamilyId familyId) {
    for (final membership in _membershipsForActiveAccount()) {
      if (membership.familyId == familyId) {
        return membership;
      }
    }
    throw IdentityInvariantViolation(
      'missing family membership for ${familyId.value}',
    );
  }

  void _assertActiveMembershipForFamily(FamilyId familyId) {
    _membershipForFamily(familyId);
  }

  List<FamilyMembership> _membershipsForActiveAccount() {
    return _memberships.where((m) => m.accountId == _account.id).toList();
  }

  Session _sessionById(SessionId id) {
    for (final session in _sessions) {
      if (session.id == id) return session;
    }
    throw IdentityInvariantViolation('unknown session ${id.value}');
  }

  bool _isSessionUsable(Session session) {
    final now = _nowProvider().toUtc();
    if (session.isRevoked) return false;
    if (session.endedAt != null) return false;
    if (session.isExpiredAt(now)) return false;
    return true;
  }

  void _syncActiveAccountFromSession() {
    final current = _sessionById(_activeSessionId);
    _session = current;
    for (final account in _accounts) {
      if (account.id == current.accountId) {
        _account = account;
        return;
      }
    }
    _account = Account(id: current.accountId);
    _accounts.add(_account);
  }

  FamilyId _resolveInitialFamily(FamilyId fallback) {
    final memberships = _membershipsForActiveAccount();
    if (memberships.isEmpty) return fallback;
    if (memberships.length == 1) return memberships.first.familyId;
    final stored = _familyContextStore?.loadActiveFamily(_account.id);
    if (stored != null && memberships.any((m) => m.familyId == stored)) {
      return stored;
    }
    if (memberships.any((m) => m.familyId == fallback)) return fallback;
    return memberships.first.familyId;
  }

  ChildScope _resolveInitialChildScope(ChildScope fallback) {
    final candidates = _children
        .where((c) => c.familyId == _activeFamilyId)
        .toList();
    if (candidates.isEmpty) {
      return ChildScope(familyId: _activeFamilyId, childId: fallback.childId);
    }
    for (final candidate in candidates) {
      if (candidate.id == fallback.childId) {
        return ChildScope(familyId: _activeFamilyId, childId: fallback.childId);
      }
    }
    return ChildScope(familyId: _activeFamilyId, childId: candidates.first.id);
  }

  void _persistActiveFamily() {
    _familyContextStore?.saveActiveFamily(_account.id, _activeFamilyId);
  }
}

DateTime _defaultNow() => DateTime.now().toUtc();

IdentityRuntime createStage1IdentityRuntime() {
  final accountId = AccountId('acc_stage1_father');
  final motherAccountId = AccountId('acc_stage1_mother');
  final familyId = FamilyId('fam_stage1');
  final secondFamilyId = FamilyId('fam_stage2');
  final sessionId = SessionId('sess_stage1');
  final motherSessionId = SessionId('sess_stage1_mother');
  return IdentityRuntime(
    account: Account(id: accountId),
    session: Session(
      id: sessionId,
      accountId: accountId,
      startedAt: DateTime.utc(2026, 1, 1),
      expiresAt: DateTime.utc(2030, 1, 1),
    ),
    accounts: [
      Account(id: accountId),
      Account(id: motherAccountId),
    ],
    sessions: [
      Session(
        id: sessionId,
        accountId: accountId,
        startedAt: DateTime.utc(2026, 1, 1),
        expiresAt: DateTime.utc(2030, 1, 1),
      ),
      Session(
        id: motherSessionId,
        accountId: motherAccountId,
        startedAt: DateTime.utc(2026, 1, 2),
        expiresAt: DateTime.utc(2030, 1, 2),
      ),
    ],
    activeSessionId: sessionId,
    families: [
      Family(
        id: familyId,
        name: 'Stage-1 Family',
        ownerMemberId: MemberId('mem_stage1_owner'),
      ),
      Family(
        id: secondFamilyId,
        name: 'Stage-1 Family 2',
        ownerMemberId: MemberId('mem_stage2_owner'),
      ),
    ],
    memberships: [
      FamilyMembership(
        id: MemberId('mem_stage1_owner'),
        accountId: accountId,
        familyId: familyId,
        role: AppRole.father,
        tier: MembershipTier.primary,
        isPrimaryOwner: true,
      ),
      FamilyMembership(
        id: MemberId('mem_stage2_owner'),
        accountId: accountId,
        familyId: secondFamilyId,
        role: AppRole.father,
        tier: MembershipTier.primary,
        isPrimaryOwner: true,
      ),
      FamilyMembership(
        id: MemberId('mem_stage1_mother'),
        accountId: motherAccountId,
        familyId: familyId,
        role: AppRole.mother,
        tier: MembershipTier.coParent,
        motherLevel: MotherLevel.partner,
      ),
    ],
    activeFamilyId: familyId,
    activeChildScope: ChildScope(
      familyId: familyId,
      childId: ChildId('demo-child'),
    ),
    children: [
      ChildIdentity(
        id: ChildId('demo-child'),
        familyId: familyId,
        childLogoutAllowed: false,
      ),
      ChildIdentity(
        id: ChildId('child_b'),
        familyId: familyId,
        childLogoutAllowed: false,
      ),
      ChildIdentity(
        id: ChildId('child_c'),
        familyId: secondFamilyId,
        childLogoutAllowed: false,
      ),
    ],
    devices: [
      DeviceIdentity(
        id: DeviceId('dev_a'),
        familyId: familyId,
        childId: ChildId('demo-child'),
      ),
      DeviceIdentity(
        id: DeviceId('dev_b'),
        familyId: familyId,
        childId: ChildId('child_b'),
      ),
    ],
    enrollments: [
      Enrollment(
        id: EnrollmentId('enr_stage1_a'),
        deviceId: DeviceId('dev_a'),
        familyId: familyId,
        childId: ChildId('demo-child'),
        createdAt: DateTime.utc(2026, 1, 1, 0, 0, 1),
      ),
      Enrollment(
        id: EnrollmentId('enr_stage1_b'),
        deviceId: DeviceId('dev_b'),
        familyId: familyId,
        childId: ChildId('child_b'),
        createdAt: DateTime.utc(2026, 1, 1, 0, 0, 2),
      ),
    ],
    familyContextStore: stage1FamilyContextStore,
  );
}

final IdentityRuntime stage1IdentityRuntime = createStage1IdentityRuntime();
