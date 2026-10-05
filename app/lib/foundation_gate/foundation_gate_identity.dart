import 'package:firebase_auth/firebase_auth.dart';

import 'foundation_gate_models.dart';

abstract interface class FoundationGateIdentity {
  Future<String> signIn({required String email, required String password});
  Future<String> signUp({required String email, required String password});

  /// Returns a provider-managed token only for the immediate authorized request.
  /// Callers must not retain it in controller or UI state.
  Future<String> currentIdToken();

  /// Returns the provider's stable subject without exposing a token.
  Future<String> currentSubject();

  /// Whether the provider has verified the account e-mail. With [reload] the
  /// provider record is refreshed first (after the user clicked the link).
  Future<bool> isEmailVerified({bool reload = false});

  /// Asks the provider to send (or re-send) the verification e-mail.
  Future<void> sendEmailVerification();

  Future<void> signOut();
}

class FirebaseEmailPasswordIdentity implements FoundationGateIdentity {
  FirebaseEmailPasswordIdentity(this._auth);

  final FirebaseAuth _auth;

  @override
  Future<String> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _tokenFromUser(credential.user);
    } on FirebaseAuthException catch (error) {
      throw FoundationGateIdentityException(_mapSignInCode(error.code));
    } on FoundationGateIdentityException {
      rethrow;
    } catch (_) {
      throw const FoundationGateIdentityException();
    }
  }

  @override
  Future<String> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _tokenFromUser(credential.user);
    } on FirebaseAuthException catch (error) {
      throw FoundationGateIdentityException(_mapSignUpCode(error.code));
    } on FoundationGateIdentityException {
      rethrow;
    } catch (_) {
      throw const FoundationGateIdentityException();
    }
  }

  @override
  Future<String> currentIdToken() async {
    try {
      return await _tokenFromUser(_auth.currentUser);
    } on FirebaseAuthException catch (error) {
      throw FoundationGateIdentityException(_mapSessionCode(error.code));
    } on FoundationGateIdentityException {
      rethrow;
    } catch (_) {
      throw const FoundationGateIdentityException();
    }
  }

  @override
  Future<String> currentSubject() async {
    try {
      final uid = _auth.currentUser?.uid.trim();
      if (uid == null || uid.isEmpty) {
        throw const FoundationGateIdentityException(
          FoundationGateIdentityFailure.noSession,
        );
      }
      return uid;
    } on FoundationGateIdentityException {
      rethrow;
    } catch (_) {
      throw const FoundationGateIdentityException();
    }
  }

  Future<String> _tokenFromUser(User? user) async {
    if (user == null) {
      throw const FoundationGateIdentityException(
        FoundationGateIdentityFailure.noSession,
      );
    }
    final token = await user.getIdToken();
    if (token == null || token.trim().isEmpty) {
      throw const FoundationGateIdentityException(
        FoundationGateIdentityFailure.noSession,
      );
    }
    return token;
  }

  /// Sign-in codes. `user-not-found`, `wrong-password`, `invalid-credential`
  /// and `INVALID_LOGIN_CREDENTIALS` all collapse into one outcome so the UI
  /// cannot reveal whether an e-mail has an account.
  static FoundationGateIdentityFailure _mapSignInCode(String code) {
    return switch (code) {
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' ||
      'INVALID_LOGIN_CREDENTIALS' ||
      'invalid-login-credentials' =>
        FoundationGateIdentityFailure.invalidCredentials,
      'invalid-email' => FoundationGateIdentityFailure.invalidEmail,
      'user-disabled' => FoundationGateIdentityFailure.accountDisabled,
      _ => _mapCommonCode(code),
    };
  }

  static FoundationGateIdentityFailure _mapSignUpCode(String code) {
    return switch (code) {
      'email-already-in-use' => FoundationGateIdentityFailure.emailAlreadyInUse,
      'weak-password' => FoundationGateIdentityFailure.weakPassword,
      'invalid-email' => FoundationGateIdentityFailure.invalidEmail,
      _ => _mapCommonCode(code),
    };
  }

  static FoundationGateIdentityFailure _mapSessionCode(String code) {
    return switch (code) {
      'user-token-expired' ||
      'user-not-found' ||
      'user-disabled' ||
      'null-user' ||
      'no-current-user' => FoundationGateIdentityFailure.noSession,
      _ => _mapCommonCode(code),
    };
  }

  static FoundationGateIdentityFailure _mapCommonCode(String code) {
    return switch (code) {
      'network-request-failed' =>
        FoundationGateIdentityFailure.networkUnavailable,
      'too-many-requests' => FoundationGateIdentityFailure.tooManyAttempts,
      _ => FoundationGateIdentityFailure.unknown,
    };
  }

  @override
  Future<bool> isEmailVerified({bool reload = false}) async {
    try {
      var user = _auth.currentUser;
      if (user == null) {
        throw const FoundationGateIdentityException(
          FoundationGateIdentityFailure.noSession,
        );
      }
      if (reload) {
        await user.reload();
        user = _auth.currentUser ?? user;
      }
      return user.emailVerified;
    } on FirebaseAuthException catch (error) {
      throw FoundationGateIdentityException(_mapSessionCode(error.code));
    } on FoundationGateIdentityException {
      rethrow;
    } catch (_) {
      throw const FoundationGateIdentityException();
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw const FoundationGateIdentityException(
          FoundationGateIdentityFailure.noSession,
        );
      }
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (error) {
      throw FoundationGateIdentityException(_mapCommonCode(error.code));
    } on FoundationGateIdentityException {
      rethrow;
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
