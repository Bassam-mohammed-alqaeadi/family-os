import 'package:flutter/foundation.dart';

import 'children_roster_api_client.dart';
import 'family_discovery_api_client.dart';
import 'foundation_gate_identity.dart';
import 'foundation_gate_models.dart';

class FoundationGateSessionController extends ChangeNotifier {
  FoundationGateSessionController({
    required FoundationGateIdentity identity,
    required FamilyDiscoveryApiClient discoveryApi,
    required ChildrenRosterApiClient rosterApi,
  }) : _identity = identity,
       _discoveryApi = discoveryApi,
       _rosterApi = rosterApi;

  final FoundationGateIdentity _identity;
  final FamilyDiscoveryApiClient _discoveryApi;
  final ChildrenRosterApiClient _rosterApi;
  FoundationGatePhase _phase = FoundationGatePhase.signedOut;
  List<FoundationGateFamily> _families = const [];
  FoundationGateFamily? _selectedFamily;
  List<FoundationGateChild> _children = const [];
  bool _creatingChild = false;

  FoundationGatePhase get phase => _phase;
  List<FoundationGateFamily> get families => _families;
  FoundationGateFamily? get selectedFamily => _selectedFamily;
  List<FoundationGateChild> get children => _children;
  bool get isCreatingChild => _creatingChild;

  Future<void> signIn({required String email, required String password}) async {
    if (email.trim().isEmpty || password.isEmpty) {
      _setPhase(FoundationGatePhase.signInFailed);
      return;
    }

    _clearAllVolatileState();
    _setPhase(FoundationGatePhase.signingIn);
    String? idToken;
    try {
      idToken = await _identity.signIn(email: email, password: password);
      _setPhase(FoundationGatePhase.loadingFamilies);
      final discovered = await _discoveryApi.discover(idToken: idToken);
      _families = discovered;
      _phase = discovered.isEmpty ? FoundationGatePhase.noActiveFamily : FoundationGatePhase.familiesAvailable;
      notifyListeners();
    } on FoundationGateIdentityException {
      _clearAllVolatileState();
      _setPhase(FoundationGatePhase.signInFailed);
    } on FoundationGateApiException catch (error) {
      await _handleDiscoveryFailure(error.failure);
    } finally {
      idToken = null;
    }
  }

  /// Requests the roster only after family discovery returned this exact family.
  /// The role returned by discovery is display context, never local authorization.
  Future<void> selectFamily(FoundationGateFamily family) async {
    if (_phase != FoundationGatePhase.familiesAvailable || !_families.any((item) => item.id == family.id)) {
      return;
    }

    _selectedFamily = family;
    _clearRoster();
    _setPhase(FoundationGatePhase.loadingRoster);
    await _loadSelectedRoster();
  }

  Future<void> retryRoster() async {
    if (_selectedFamily == null) {
      return;
    }
    _clearRoster();
    _setPhase(FoundationGatePhase.loadingRoster);
    await _loadSelectedRoster();
  }

  /// Creates a minimal child profile only after server authorization succeeds.
  ///
  /// The same idempotency key must accompany sheet-level retries. The returned
  /// result is presentation-safe; no API error body, token or identifier is
  /// retained in controller state or exposed to the UI.
  Future<FoundationGateChildCreateResult> createChild({
    required String displayName,
    required int ageYears,
    required String idempotencyKey,
  }) async {
    final family = _selectedFamily;
    if (family == null ||
        (_phase != FoundationGatePhase.childrenAvailable &&
            _phase != FoundationGatePhase.noChildren &&
            _phase != FoundationGatePhase.serviceUnavailable &&
            _phase != FoundationGatePhase.networkUnavailable) ||
        _creatingChild) {
      return FoundationGateChildCreateResult.invalidInput;
    }

    _creatingChild = true;
    notifyListeners();
    String? idToken;
    try {
      idToken = await _identity.currentIdToken();
      await _rosterApi.create(
        familyId: family.id,
        idToken: idToken,
        idempotencyKey: idempotencyKey,
        displayName: displayName,
        ageYears: ageYears,
      );

      // A POST response confirms the mutation, but the roster shown to the
      // user is always refreshed from the collection source of truth.
      try {
        final roster = await _rosterApi.list(familyId: family.id, idToken: idToken);
        _children = roster;
        _phase = roster.isEmpty ? FoundationGatePhase.noChildren : FoundationGatePhase.childrenAvailable;
        notifyListeners();
        return FoundationGateChildCreateResult.created;
      } on FoundationGateApiException catch (error) {
        await _handleRosterFailure(error.failure);
        return switch (error.failure) {
          FoundationGateApiFailure.unauthenticated => FoundationGateChildCreateResult.sessionInvalid,
          FoundationGateApiFailure.accessDenied => FoundationGateChildCreateResult.accessDenied,
          FoundationGateApiFailure.invalidInput ||
          FoundationGateApiFailure.conflict ||
          FoundationGateApiFailure.serviceUnavailable ||
          FoundationGateApiFailure.networkUnavailable ||
          FoundationGateApiFailure.invalidResponse => FoundationGateChildCreateResult.createdRosterRefreshUnavailable,
        };
      }
    } on FoundationGateIdentityException {
      _clearAllVolatileState();
      await _signOutProviderSilently();
      _setPhase(FoundationGatePhase.sessionInvalid);
      return FoundationGateChildCreateResult.sessionInvalid;
    } on FoundationGateApiException catch (error) {
      switch (error.failure) {
        case FoundationGateApiFailure.invalidInput:
          return FoundationGateChildCreateResult.invalidInput;
        case FoundationGateApiFailure.conflict:
          return FoundationGateChildCreateResult.conflict;
        case FoundationGateApiFailure.unauthenticated:
          _clearAllVolatileState();
          await _signOutProviderSilently();
          _setPhase(FoundationGatePhase.sessionInvalid);
          return FoundationGateChildCreateResult.sessionInvalid;
        case FoundationGateApiFailure.accessDenied:
          _clearRoster();
          _setPhase(FoundationGatePhase.rosterAccessDenied);
          return FoundationGateChildCreateResult.accessDenied;
        case FoundationGateApiFailure.serviceUnavailable:
          // The outcome may be ambiguous. Remove the prior collection instead
          // of presenting it as the current roster while the form retries.
          await _handleRosterFailure(error.failure);
          return FoundationGateChildCreateResult.serviceUnavailable;
        case FoundationGateApiFailure.networkUnavailable:
        case FoundationGateApiFailure.invalidResponse:
          // A malformed or lost response cannot prove that no write happened.
          await _handleRosterFailure(error.failure);
          return FoundationGateChildCreateResult.networkUnavailable;
      }
    } finally {
      idToken = null;
      _creatingChild = false;
      notifyListeners();
    }
  }

  void returnToFamilySelection() {
    if (_families.isEmpty || _creatingChild) {
      return;
    }
    _clearRoster();
    _selectedFamily = null;
    _setPhase(FoundationGatePhase.familiesAvailable);
  }

  Future<void> _loadSelectedRoster() async {
    final family = _selectedFamily;
    if (family == null) {
      _setPhase(FoundationGatePhase.familiesAvailable);
      return;
    }

    String? idToken;
    try {
      idToken = await _identity.currentIdToken();
      final roster = await _rosterApi.list(familyId: family.id, idToken: idToken);
      _children = roster;
      _phase = roster.isEmpty ? FoundationGatePhase.noChildren : FoundationGatePhase.childrenAvailable;
      notifyListeners();
    } on FoundationGateIdentityException {
      _clearAllVolatileState();
      await _signOutProviderSilently();
      _setPhase(FoundationGatePhase.sessionInvalid);
    } on FoundationGateApiException catch (error) {
      await _handleRosterFailure(error.failure);
    } finally {
      idToken = null;
    }
  }

  Future<void> _handleDiscoveryFailure(FoundationGateApiFailure failure) async {
    _clearAllVolatileState();
    switch (failure) {
      case FoundationGateApiFailure.unauthenticated:
        await _signOutProviderSilently();
        _setPhase(FoundationGatePhase.sessionInvalid);
        break;
      case FoundationGateApiFailure.accessDenied:
        _setPhase(FoundationGatePhase.accessDenied);
        break;
      case FoundationGateApiFailure.serviceUnavailable:
        _setPhase(FoundationGatePhase.serviceUnavailable);
        break;
      case FoundationGateApiFailure.invalidInput:
      case FoundationGateApiFailure.conflict:
      case FoundationGateApiFailure.networkUnavailable:
      case FoundationGateApiFailure.invalidResponse:
        _setPhase(FoundationGatePhase.networkUnavailable);
        break;
    }
  }

  Future<void> _handleRosterFailure(FoundationGateApiFailure failure) async {
    _clearRoster();
    switch (failure) {
      case FoundationGateApiFailure.unauthenticated:
        _clearAllVolatileState();
        await _signOutProviderSilently();
        _setPhase(FoundationGatePhase.sessionInvalid);
        break;
      case FoundationGateApiFailure.accessDenied:
        _setPhase(FoundationGatePhase.rosterAccessDenied);
        break;
      case FoundationGateApiFailure.serviceUnavailable:
        _setPhase(FoundationGatePhase.serviceUnavailable);
        break;
      case FoundationGateApiFailure.invalidInput:
      case FoundationGateApiFailure.conflict:
      case FoundationGateApiFailure.networkUnavailable:
      case FoundationGateApiFailure.invalidResponse:
        _setPhase(FoundationGatePhase.networkUnavailable);
        break;
    }
  }

  Future<void> signOut() async {
    if (_creatingChild) {
      return;
    }
    await _signOutProviderSilently();
    _clearAllVolatileState();
    _setPhase(FoundationGatePhase.signedOut);
  }

  void _clearRoster() {
    _children = const [];
  }

  void _clearAllVolatileState() {
    _families = const [];
    _selectedFamily = null;
    _clearRoster();
  }

  Future<void> _signOutProviderSilently() async {
    try {
      await _identity.signOut();
    } on FoundationGateIdentityException {
      // Provider errors are intentionally not surfaced or retained by this slice.
    }
  }

  void _setPhase(FoundationGatePhase phase) {
    _phase = phase;
    notifyListeners();
  }
}
