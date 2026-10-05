import 'package:flutter/foundation.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/runtime/family_child_profile_source.dart';
import 'package:family_os/core/runtime/family_creation_source.dart';
import 'package:family_os/core/runtime/family_device_source.dart';
import 'package:family_os/core/runtime/family_roster_source.dart';
import 'package:family_os/core/runtime/identity_source.dart';
import 'package:family_os/core/runtime/runtime_data_origin.dart';

import 'family_creation_api_client.dart';
import 'family_device_api_client.dart';
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
    required FamilyDeviceApiClient deviceApi,
    required FamilyCreationApiClient familyCreationApi,
    String? preferredFamilyId,
  }) : _controller = controller,
       _identity = identity,
       _deviceApi = deviceApi,
       _familyCreationApi = familyCreationApi,
       _preferredFamilyId = preferredFamilyId?.trim(),
       _identityValue = const IdentitySnapshot.unavailable(),
       _rosterValue = const FamilyRosterSnapshot.unavailable(),
       _deviceValue = const FamilyDeviceSnapshot.unavailable() {
    _controller.addListener(_synchronizeControllerState);
  }

  final FoundationGateSessionController _controller;
  final FoundationGateIdentity _identity;
  final FamilyDeviceApiClient _deviceApi;
  final FamilyCreationApiClient _familyCreationApi;
  final String? _preferredFamilyId;
  IdentitySnapshot _identityValue;
  FamilyRosterSnapshot _rosterValue;
  FamilyDeviceSnapshot _deviceValue;

  IdentitySnapshot get identityValue => _identityValue;
  FamilyRosterSnapshot get rosterValue => _rosterValue;
  FamilyDeviceSnapshot get deviceValue => _deviceValue;
  FoundationGatePhase get phase => _controller.phase;

  /// Presentation-safe reason for the most recent failed sign-in / sign-up.
  FoundationGateIdentityFailure? get lastIdentityFailure =>
      _controller.lastIdentityFailure;

  /// The provider holds an authenticated principal (family may not exist yet).
  bool get hasAuthenticatedPrincipal => _controller.hasAuthenticatedPrincipal;

  /// Signed in, discovery succeeded, and the server returned zero families —
  /// the exact state in which the user must create (or be invited to) one.
  bool get needsFamilyCreation =>
      _controller.phase == FoundationGatePhase.noActiveFamily;

  /// Signed in and the server returned several families but none matched the
  /// configured preferred family — a picker is required before any roster.
  bool get needsFamilySelection =>
      _controller.phase == FoundationGatePhase.familiesAvailable &&
      _controller.selectedFamily == null;

  Future<IdentitySnapshot> signIn({
    required String email,
    required String password,
  }) async {
    await _controller.signIn(email: email, password: password);
    await _selectConfiguredFamily();
    return _refreshIdentitySnapshot();
  }

  Future<IdentitySnapshot> signUp({
    required String email,
    required String password,
  }) async {
    await _controller.signUp(email: email, password: password);
    await _selectConfiguredFamily();
    return _refreshIdentitySnapshot();
  }

  /// Sends a password-reset e-mail. Returns `null` when the provider accepted
  /// the request (including unknown addresses, which are never revealed) or
  /// the presentation-safe failure reason otherwise.
  Future<FoundationGateIdentityFailure?> sendPasswordReset({
    required String email,
  }) async {
    try {
      await _identity.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FoundationGateIdentityException catch (error) {
      return error.failure;
    } catch (_) {
      return FoundationGateIdentityFailure.unknown;
    }
  }

  Future<void> signOut() async {
    await _controller.signOut();
    _identityValue = const IdentitySnapshot.unavailable();
    _rosterValue = const FamilyRosterSnapshot.unavailable();
    _deviceValue = const FamilyDeviceSnapshot.unavailable();
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

  Future<void> _selectConfiguredFamily({String? preferCreatedId}) async {
    if (_controller.phase != FoundationGatePhase.familiesAvailable) return;
    final families = _controller.families;
    FoundationGateFamily? selected;
    // A family the user just created wins over any build-time preference so
    // onboarding continues inside the family that was actually confirmed.
    if (preferCreatedId != null && preferCreatedId.isNotEmpty) {
      for (final family in families) {
        if (family.id == preferCreatedId) {
          selected = family;
          break;
        }
      }
    }
    final preferred = _preferredFamilyId;
    if (selected == null && preferred != null && preferred.isNotEmpty) {
      for (final family in families) {
        if (family.id == preferred) {
          selected = family;
          break;
        }
      }
    }
    if (selected == null && families.length == 1) {
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
    if (!_identityValue.isRemoteAuthoritative ||
        selected == null ||
        selected.id != familyId.value) {
      return _publishRoster(const FamilyRosterSnapshot.unavailable());
    }

    await _controller.retryRoster();
    if (_controller.phase != FoundationGatePhase.childrenAvailable &&
        _controller.phase != FoundationGatePhase.noChildren) {
      return _publishRoster(const FamilyRosterSnapshot.unavailable());
    }

    return _publishCurrentRemoteRoster(familyId);
  }

  /// Loads the family-scoped latest device facts from the Node/Express API.
  /// It never falls back to the local demo/device registry.
  Future<FamilyDeviceSnapshot> loadDevices(FamilyId familyId) async {
    await refreshIdentity();
    final selected = _controller.selectedFamily;
    if (!_identityValue.isRemoteAuthoritative ||
        selected == null ||
        selected.id != familyId.value) {
      return _publishDevices(const FamilyDeviceSnapshot.unavailable());
    }
    try {
      final devices = await _deviceApi.list(
        familyId: familyId.value,
        idToken: await _identity.currentIdToken(),
      );
      final byChild = <String, List<FoundationGateFamilyDevice>>{};
      for (final device in devices) {
        (byChild[device.childId] ??= []).add(device);
      }
      final children =
          byChild.entries
              .map((entry) {
                final candidates = entry.value
                  ..sort((left, right) {
                    final leftTime = left.lastSeenAt ?? left.linkedAt;
                    final rightTime = right.lastSeenAt ?? right.linkedAt;
                    return rightTime.compareTo(leftTime);
                  });
                final latest = candidates.first;
                return FamilyChildDeviceSummary(
                  childId: ChildId(entry.key),
                  connectionState: _connectionStateOf(latest),
                  deviceCount: candidates.length,
                  deviceLabel: latest.deviceLabel,
                  batteryLevel: latest.batteryLevel,
                  batteryStatus: latest.batteryStatus,
                  locationLabel: latest.locationLabel,
                  lastSeenAt: latest.lastSeenAt,
                );
              })
              .toList(growable: false)
            ..sort(
              (left, right) =>
                  left.childId.value.compareTo(right.childId.value),
            );
      return _publishDevices(
        FamilyDeviceSnapshot(
          familyId: familyId,
          origin: RuntimeDataOrigin.remoteAuthoritative,
          children: List.unmodifiable(children),
          observedAt: DateTime.now().toUtc(),
        ),
      );
    } on FoundationGateIdentityException {
      return _publishDevices(const FamilyDeviceSnapshot.unavailable());
    } on FoundationGateApiException {
      return _publishDevices(const FamilyDeviceSnapshot.unavailable());
    }
  }

  /// Creates a family through the real Node/Express contract. The server
  /// assigns the identifier; a failure is reported as an outcome, never as a
  /// locally invented family.
  Future<FamilyCreationResult> createFamily({
    required String displayName,
    required String idempotencyKey,
  }) async {
    // A brand-new account has no family yet, so a selected family context
    // cannot be the precondition here. The precondition is an authenticated
    // provider principal; the server enforces everything else on the bearer.
    if (!_controller.hasAuthenticatedPrincipal) {
      await _controller.restoreCurrentSession();
      await _selectConfiguredFamily();
      await _refreshIdentitySnapshot();
    }
    if (!_controller.hasAuthenticatedPrincipal) {
      return const FamilyCreationResult.failed(
        FamilyCreationOutcome.unauthenticated,
      );
    }
    try {
      final created = await _familyCreationApi.create(
        idToken: await _identity.currentIdToken(),
        idempotencyKey: idempotencyKey,
        displayName: displayName,
      );
      // Re-discover so the newly created family becomes the selected family
      // context. A discovery failure must not rewrite a confirmed 201 into a
      // failure, so it is swallowed here and retried on the next refresh.
      try {
        await _controller.restoreCurrentSession();
        await _selectConfiguredFamily(preferCreatedId: created.id);
        await _refreshIdentitySnapshot();
      } on Object {
        // The family exists on the server; selection recovers on next refresh.
      }
      return FamilyCreationResult.created(
        familyId: created.id,
        displayName: created.displayName,
      );
    } on FoundationGateIdentityException {
      return const FamilyCreationResult.failed(
        FamilyCreationOutcome.unauthenticated,
      );
    } on FoundationGateApiException catch (error) {
      return FamilyCreationResult.failed(_mapFamilyCreationFailure(error));
    }
  }

  static FamilyCreationOutcome _mapFamilyCreationFailure(
    FoundationGateApiException error,
  ) {
    return switch (error.failure) {
      FoundationGateApiFailure.unauthenticated =>
        FamilyCreationOutcome.unauthenticated,
      FoundationGateApiFailure.accessDenied => FamilyCreationOutcome.denied,
      FoundationGateApiFailure.invalidInput => FamilyCreationOutcome.validation,
      FoundationGateApiFailure.conflict => FamilyCreationOutcome.conflict,
      FoundationGateApiFailure.serviceUnavailable =>
        FamilyCreationOutcome.serviceUnavailable,
      FoundationGateApiFailure.networkUnavailable =>
        FamilyCreationOutcome.networkUnavailable,
      FoundationGateApiFailure.invalidResponse =>
        FamilyCreationOutcome.invalidResponse,
    };
  }

  /// Owner decision C1: the guardian may create a family and children before
  /// verifying the account e-mail, but may not mint a child-device pairing
  /// code until it is verified. The server enforces the same rule (403
  /// `email_verification_required`); this is the UX-side mirror.
  Future<bool> isEmailVerified({bool reload = false}) async {
    try {
      return await _identity.isEmailVerified(reload: reload);
    } on FoundationGateIdentityException {
      return false;
    }
  }

  /// Returns true when the provider accepted the send request.
  Future<bool> sendEmailVerification() async {
    try {
      await _identity.sendEmailVerification();
      return true;
    } on FoundationGateIdentityException {
      return false;
    }
  }

  Future<FoundationGateDevicePairing?> createDevicePairing({
    required FamilyId familyId,
    required ChildId childId,
    required String deviceLabel,
    required String idempotencyKey,
  }) async {
    await refreshIdentity();
    final selected = _controller.selectedFamily;
    if (!_identityValue.isRemoteAuthoritative ||
        !_identityValue.isPrimaryOwner ||
        selected == null ||
        selected.id != familyId.value) {
      return null;
    }
    try {
      return await _deviceApi.createPairing(
        familyId: familyId.value,
        childId: childId.value,
        deviceLabel: deviceLabel,
        idempotencyKey: idempotencyKey,
        idToken: await _identity.currentIdToken(),
      );
    } on FoundationGateIdentityException {
      return null;
    } on FoundationGateApiException {
      return null;
    }
  }

  ChildDeviceConnectionState _connectionStateOf(
    FoundationGateFamilyDevice device,
  ) {
    if (device.lastSeenAt == null) return ChildDeviceConnectionState.pairing;
    if (device.batteryLevel != null && device.batteryLevel! <= 15) {
      return ChildDeviceConnectionState.needsAttention;
    }
    return ChildDeviceConnectionState.active;
  }

  FamilyDeviceSnapshot _publishDevices(FamilyDeviceSnapshot value) {
    _deviceValue = value;
    notifyListeners();
    return value;
  }

  Future<FamilyChildProfileCreateResult> createChild({
    required FamilyId familyId,
    required FamilyChildProfileDraft draft,
    required String idempotencyKey,
  }) async {
    await refreshIdentity();
    final selected = _controller.selectedFamily;
    if (!_identityValue.isRemoteAuthoritative ||
        selected == null ||
        selected.id != familyId.value) {
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
      FoundationGateChildCreateResult.conflict =>
        FamilyChildProfileCreateFailure.conflict,
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

  Future<IdentitySnapshot> signUp({
    required String email,
    required String password,
  }) => _runtime.signUp(email: email, password: password);

  Future<FoundationGateIdentityFailure?> sendPasswordReset({
    required String email,
  }) => _runtime.sendPasswordReset(email: email);

  FoundationGatePhase get phase => _runtime.phase;

  FoundationGateIdentityFailure? get lastIdentityFailure =>
      _runtime.lastIdentityFailure;

  bool get hasAuthenticatedPrincipal => _runtime.hasAuthenticatedPrincipal;

  bool get needsFamilyCreation => _runtime.needsFamilyCreation;

  bool get needsFamilySelection => _runtime.needsFamilySelection;

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
  Future<FamilyRosterSnapshot> load(FamilyId familyId) =>
      _runtime.loadRoster(familyId);

  @override
  void dispose() {
    _runtime.removeListener(notifyListeners);
    super.dispose();
  }
}

final class RemoteFamilyDeviceSource extends ChangeNotifier
    implements FamilyDeviceSource {
  RemoteFamilyDeviceSource(this._runtime) {
    _runtime.addListener(notifyListeners);
  }

  final MainAppFoundationRuntime _runtime;

  @override
  FamilyDeviceSnapshot get value => _runtime.deviceValue;

  @override
  Future<FamilyDeviceSnapshot> load(FamilyId familyId) =>
      _runtime.loadDevices(familyId);

  Future<FoundationGateDevicePairing?> createPairing({
    required FamilyId familyId,
    required ChildId childId,
    required String deviceLabel,
    required String idempotencyKey,
  }) => _runtime.createDevicePairing(
    familyId: familyId,
    childId: childId,
    deviceLabel: deviceLabel,
    idempotencyKey: idempotencyKey,
  );

  Future<bool> isEmailVerified({bool reload = false}) =>
      _runtime.isEmailVerified(reload: reload);

  Future<bool> sendEmailVerification() => _runtime.sendEmailVerification();

  @override
  void dispose() {
    _runtime.removeListener(notifyListeners);
    super.dispose();
  }
}

final class RemoteFamilyChildProfileSource implements FamilyChildProfileSource {
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

/// Remote family-creation port for the main app composition root.
final class RemoteFamilyCreationSource implements FamilyCreationSource {
  RemoteFamilyCreationSource(this._runtime);

  final MainAppFoundationRuntime _runtime;

  @override
  Future<FamilyCreationResult> create({
    required String displayName,
    required String idempotencyKey,
  }) => _runtime.createFamily(
    displayName: displayName,
    idempotencyKey: idempotencyKey,
  );
}
