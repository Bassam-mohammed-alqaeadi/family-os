import 'package:flutter/foundation.dart';

import 'family_discovery_api_client.dart';
import 'foundation_gate_identity.dart';
import 'foundation_gate_models.dart';

class FoundationGateSessionController extends ChangeNotifier {
  FoundationGateSessionController({
    required FoundationGateIdentity identity,
    required FamilyDiscoveryApiClient discoveryApi,
  }) : _identity = identity,
       _discoveryApi = discoveryApi;

  final FoundationGateIdentity _identity;
  final FamilyDiscoveryApiClient _discoveryApi;
  FoundationGatePhase _phase = FoundationGatePhase.signedOut;
  List<FoundationGateFamily> _families = const [];
  FoundationGateFamily? _selectedFamily;

  FoundationGatePhase get phase => _phase;
  List<FoundationGateFamily> get families => _families;
  FoundationGateFamily? get selectedFamily => _selectedFamily;

  Future<void> signIn({required String email, required String password}) async {
    if (email.trim().isEmpty || password.isEmpty) {
      _setPhase(FoundationGatePhase.signInFailed);
      return;
    }

    _clearVolatileState();
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
      _clearVolatileState();
      _setPhase(FoundationGatePhase.signInFailed);
    } on FoundationGateApiException catch (error) {
      _clearVolatileState();
      switch (error.failure) {
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
          _setPhase(FoundationGatePhase.networkUnavailable);
          break;
        case FoundationGateApiFailure.invalidResponse:
          _setPhase(FoundationGatePhase.networkUnavailable);
          break;
      }
    } finally {
      idToken = null;
    }
  }

  void selectFamily(FoundationGateFamily family) {
    if (_phase != FoundationGatePhase.familiesAvailable || !_families.any((item) => item.id == family.id)) {
      return;
    }
    _selectedFamily = family;
    notifyListeners();
  }

  Future<void> signOut() async {
    await _signOutProviderSilently();
    _clearVolatileState();
    _setPhase(FoundationGatePhase.signedOut);
  }

  void _clearVolatileState() {
    _families = const [];
    _selectedFamily = null;
  }

  Future<void> _signOutProviderSilently() async {
    try {
      await _identity.signOut();
    } on FoundationGateIdentityException {
      // Provider errors are intentionally not surfaced or retained by this first slice.
    }
  }

  void _setPhase(FoundationGatePhase phase) {
    _phase = phase;
    notifyListeners();
  }
}
