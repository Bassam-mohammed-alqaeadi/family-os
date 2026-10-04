import 'package:firebase_auth/firebase_auth.dart';

import 'foundation_gate_models.dart';

abstract interface class FoundationGateIdentity {
  Future<String> signIn({required String email, required String password});

  /// Returns a provider-managed token only for the immediate authorized request.
  /// Callers must not retain it in controller or UI state.
  Future<String> currentIdToken();

  /// Returns the provider's stable subject without exposing a token.
  Future<String> currentSubject();

  Future<void> signOut();
}

class FirebaseEmailPasswordIdentity implements FoundationGateIdentity {
  FirebaseEmailPasswordIdentity(this._auth);

  final FirebaseAuth _auth;

  @override
  Future<String> signIn({required String email, required String password}) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return _tokenFromUser(credential.user);
    } catch (_) {
      throw const FoundationGateIdentityException();
    }
  }

  @override
  Future<String> currentIdToken() async {
    try {
      return _tokenFromUser(_auth.currentUser);
    } catch (_) {
      throw const FoundationGateIdentityException();
    }
  }

  @override
  Future<String> currentSubject() async {
    try {
      final uid = _auth.currentUser?.uid.trim();
      if (uid == null || uid.isEmpty) {
        throw const FoundationGateIdentityException();
      }
      return uid;
    } catch (_) {
      throw const FoundationGateIdentityException();
    }
  }

  Future<String> _tokenFromUser(User? user) async {
    final token = await user?.getIdToken();
    if (token == null || token.trim().isEmpty) {
      throw const FoundationGateIdentityException();
    }
    return token;
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (_) {
      throw const FoundationGateIdentityException();
    }
  }
}
