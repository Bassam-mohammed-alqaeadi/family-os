import 'package:flutter/foundation.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/runtime/family_child_profile_source.dart';
import 'package:family_os/core/runtime/family_roster_source.dart';
import 'package:family_os/core/runtime/identity_source.dart';
import 'package:family_os/core/runtime/runtime_data_origin.dart';

import 'foundation_gate_identity.dart';
import 'foundation_gate_models.dart';
import 'foundation_gate_session_controller.dart';

/// Main-app orchestration for the admitted Family Entry capability.
///
/// It owns no local roster fallback. A family context becomes usable only after
/// a Firebase-authenticated principal has discovered and selected an authorized
/// server family. Until a dedicated multi-family picker is admitted, a build
/// with multiple families needs an owner-provided preferred family UUID.
final class MainAppFoundationRuntime extends ChangeNotifier {
  MainAppFoundationRuntime({
    required FoundationGateSessionController controller,
    required FoundationGateIdentity identity,
    String? preferredFamilyId,
  }) : _controller = controller,
       _identity = identity,
       _preferredFamilyId = preferredFamilyId?.trim(),
       _identityValue = const IdentitySnapshot.unavailable(),
       _rosterValue = const FamilyRosterSnapshot.unavailable() {
    _controller.addListener(_synchronizeControllerState);
  }

  final FoundationGateSessionController _controller;
  final FoundationGateIdentity _identity;
  final String? _preferredFamilyId;
  IdentitySnapshot _identityValue;
  FamilyRosterSnapshot _rosterValue;

  IdentitySnapshot get identityValue => _identityValue;
  FamilyRosterSnapshot get rosterValue => _rosterValue;
  FoundationGatePhase get phase => _controller.phase;

  Future<IdentitySnapshot> signIn({
    required String email,
    required String password,
  }) async {
    await _controller.signIn(email: email, password: password);
    await _selectConfiguredFamily();
    return _refreshIdentitySnapshot();
  }

  Future<void> signOut() async {
    await _controller.signOut();
    _identityValue = const IdentitySnapshot.unavailable();
    _rosterValue = const FamilyRosterSnapshot.unavailable();
    notifyListeners();
  }

  Future<IdentitySnapshot> refreshIdentity() async {
    final phase = _controller.phase;
    if (_controller.selectedFamily == null ||
        (phase != FoundationGatePhase.childrenAvailable &&
            phase != FoundationGatePhase.noChildren &&
            phase != FoundationGatePhase.familiesAvailable)) {
      await _controller.restoreCurrentSession();
      await _selectConfiguredFamily();
    }
    return _refreshIdentitySnapshot();
  }

  Future<void> _selectConfiguredFamily() async {
    if (_controller.phase != FoundationGatePhase.familiesAvailable) return;
    final families = _controller.families;
    FoundationGateFamily? selected;
    final preferred = _preferredFamilyId;
    if (preferred != null && preferred.isNotEmpty) {
      for (final family in families) {
        if (family.id == preferred) {
          selected = family;
          break;
        }
      }
    } else if (families.length == 1) {
      selected = families.single;
    }
    if (selected != null) {
      await _controller.selectFamily(selected);
    }
  }

  Future<IdentitySnapshot> _refreshIdentitySnapshot() async {
    final family = _controller.selectedFamily;
    if (family == null ||
        (_controller.phase != FoundationGatePhase.childrenAvailable &&
            _controller.phase != FoundationGatePhase.noChildren)) {
      _identityValue = const IdentitySnapshot.unavailable();
      notifyListeners();
      return _identityValue;
    }

    try {
      final subject = await _identity.currentSubject();
      _identityValue = IdentitySnapshot(
        authority: IdentityAuthority.remoteAuthoritative,
        accountId: AccountId(subject),
        familyId: FamilyId(family.id),
        role: _appRole(family.role),
        motherLevel: MotherLevel.full,
        isPrimaryOwner: family.role == 'primary_guardian',
      );
    } on FoundationGateIdentityException {
      _identityValue = const IdentitySnapshot.unavailable();
    }
    notifyListeners();
    return _identityValue;
  }

  Future<FamilyRosterSnapshot> loadRoster(FamilyId familyId) async {
    await refreshIdentity();
    final selected = _controller.selectedFamily;
    if (!_identityValue.isRemoteAuthoritative || selected == null || selected.id != familyId.value) {
      return _publishRoster(const FamilyRosterSnapshot.unavailable());
    }

    await _controller.retryRoster();
    if (_controller.phase != FoundationGatePhase.childrenAvailable &&
        _controller.phase != FoundationGatePhase.noChildren) {
      return _publishRoster(const FamilyRosterSnapshot.unavailable());
    }

    return _publishCurrentRemoteRoster(familyId);
  }

  Future<FamilyChildProfileCreateResult> createChild({
    required FamilyId familyId,
    required FamilyChildProfileDraft draft,
    required String idempotencyKey,
  }) async {
    await refreshIdentity();
    final selected = _controller.selectedFamily;
    if (!_identityValue.isRemoteAuthoritative || selected == null || selected.id != familyId.value) {
      return const FamilyChildProfileCreateResult.failed(
        FamilyChildProfileCreateFailure.unavailable,
      );
    }

    final result = await _controller.createChild(
      displayName: draft.displayName,
      ageYears: draft.ageYears,
      avatarEmoji: draft.avatarEmoji,
      themeColor: draft.themeColor,
      idempotencyKey: idempotencyKey,
    );
    if (result == FoundationGateChildCreateResult.created) {
      final childId = _controller.lastCreatedChildId;
      if (childId != null) {
        // The controller has already refreshed the server roster before it
        // reports `created`; do not issue a second read that could turn an
        // acknowledged 201 into a misleading failure.
        _publishCurrentRemoteRoster(familyId);
        return FamilyChildProfileCreateResult.created(childId: childId);
      }
    }
    return FamilyChildProfileCreateResult.failed(_mapCreateFailure(result));
  }

  FamilyRosterSnapshot _publishCurrentRemoteRoster(FamilyId familyId) {
    return _publishRoster(
      FamilyRosterSnapshot(
        familyId: familyId,
        origin: RuntimeDataOrigin.remoteAuthoritative,
        children: List.unmodifiable(
          _controller.children.map(
            (child) => FamilyRosterChild(
              childId: ChildId(child.id),
              displayName: child.displayName,
              ageYears: child.ageYears,
              avatarEmoji: child.avatarEmoji,
              themeColor: child.themeColor,
            ),
          ),
        ),
        observedAt: DateTime.now().toUtc(),
      ),
    );
  }

  FamilyChildProfileCreateFailure _mapCreateFailure(
    FoundationGateChildCreateResult result,
  ) {
    return switch (result) {
      FoundationGateChildCreateResult.created =>
        FamilyChildProfileCreateFailure.rosterRefreshUnavailable,
      FoundationGateChildCreateResult.createdRosterRefreshUnavailable =>
        FamilyChildProfileCreateFailure.rosterRefreshUnavailable,
      FoundationGateChildCreateResult.invalidInput =>
        FamilyChildProfileCreateFailure.invalidInput,
      FoundationGateChildCreateResult.conflict => FamilyChildProfileCreateFailure.conflict,
      FoundationGateChildCreateResult.accessDenied =>
        FamilyChildProfileCreateFailure.accessDenied,
      FoundationGateChildCreateResult.sessionInvalid =>
        FamilyChildProfileCreateFailure.sessionInvalid,
      FoundationGateChildCreateResult.serviceUnavailable =>
        FamilyChildProfileCreateFailure.serviceUnavailable,
      FoundationGateChildCreateResult.networkUnavailable =>
        FamilyChildProfileCreateFailure.networkUnavailable,
    };
  }

  AppRole _appRole(String role) {
    return switch (role) {
      'primary_guardian' => AppRole.father,
      'co_guardian' => AppRole.mother,
      _ => AppRole.child,
    };
  }

  FamilyRosterSnapshot _publishRoster(FamilyRosterSnapshot value) {
    _rosterValue = value;
    notifyListeners();
    return value;
  }

  void _synchronizeControllerState() {
    // Explicit refresh/load operations publish source values. This listener only
    // propagates pending, denied and session-invalid transitions to the shell.
    notifyListeners();
  }

  @override
  void dispose() {
    _controller.removeListener(_synchronizeControllerState);
    _controller.dispose();
    super.dispose();
  }
}

final class MainAppFoundationIdentitySource extends ChangeNotifier
    implements IdentitySource {
  MainAppFoundationIdentitySource(this._runtime) {
    _runtime.addListener(notifyListeners);
  }

  final MainAppFoundationRuntime _runtime;

  @override
  IdentitySnapshot get value => _runtime.identityValue;

  @override
  Future<IdentitySnapshot> refresh() => _runtime.refreshIdentity();

  Future<IdentitySnapshot> signIn({
    required String email,
    required String password,
  }) => _runtime.signIn(email: email, password: password);

  FoundationGatePhase get phase => _runtime.phase;

  @override
  void dispose() {
    _runtime.removeListener(notifyListeners);
    super.dispose();
  }
}

final class RemoteFamilyRosterSource extends ChangeNotifier
    implements FamilyRosterSource {
  RemoteFamilyRosterSource(this._runtime) {
    _runtime.addListener(notifyListeners);
  }

  final MainAppFoundationRuntime _runtime;

  @override
  FamilyRosterSnapshot get value => _runtime.rosterValue;

  @override
  Future<FamilyRosterSnapshot> load(FamilyId familyId) => _runtime.loadRoster(familyId);

  @override
  void dispose() {
    _runtime.removeListener(notifyListeners);
    super.dispose();
  }
}

final class RemoteFamilyChildProfileSource
    implements FamilyChildProfileSource {
  RemoteFamilyChildProfileSource(this._runtime);

  final MainAppFoundationRuntime _runtime;

  @override
  Future<FamilyChildProfileCreateResult> create({
    required FamilyId familyId,
    required FamilyChildProfileDraft draft,
    required String idempotencyKey,
  }) => _runtime.createChild(
    familyId: familyId,
    draft: draft,
    idempotencyKey: idempotencyKey,
  );

  @override
  void dispose() => _runtime.dispose();
}
