import 'package:firebase_auth/firebase_auth.dart';

import 'foundation_gate_models.dart';

abstract interface class FoundationGateIdentity {
  Future<String> signIn({required String email, required String password});

  Future<void> signOut();
}

class FirebaseEmailPasswordIdentity implements FoundationGateIdentity {
  FirebaseEmailPasswordIdentity(this._auth);

  final FirebaseAuth _auth;

  @override
  Future<String> signIn({required String email, required String password}) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      final token = await credential.user?.getIdToken();
      if (token == null || token.trim().isEmpty) {
        throw const FoundationGateIdentityException();
      }
      return token;
    } catch (_) {
      throw const FoundationGateIdentityException();
    }
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
