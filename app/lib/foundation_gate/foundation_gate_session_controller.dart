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

  FoundationGatePhase get phase => _phase;
  List<FoundationGateFamily> get families => _families;
  FoundationGateFamily? get selectedFamily => _selectedFamily;
  List<FoundationGateChild> get children => _children;

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

  void returnToFamilySelection() {
    if (_families.isEmpty) {
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
      case FoundationGateApiFailure.networkUnavailable:
      case FoundationGateApiFailure.invalidResponse:
        _setPhase(FoundationGatePhase.networkUnavailable);
        break;
    }
  }

  Future<void> signOut() async {
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
