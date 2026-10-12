import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:family_os/foundation_gate/family_push_client.dart';

/// Where this handset's push token comes from. The Firebase implementation is [FirebasePushTokenSource];
/// tests supply their own.
abstract interface class PushTokenSource {
  /// 'android' or 'ios' on a platform that can receive pushes, otherwise null.
  String? get platform;

  /// This handset's token. Null means push is not available here: Firebase is not configured on
  /// this build, or the person refused notifications. Chat works without it.
  Future<String?> currentToken();
}

/// The real token source, through Firebase Cloud Messaging.
///
/// It needs the Firebase configuration files the owner adds to the app (google-services.json for
/// Android, GoogleService-Info.plist for iOS). Without them, Firebase cannot start, this returns
/// null, and nothing is registered. It never throws into the chat screens.
final class FirebasePushTokenSource implements PushTokenSource {
  @override
  String? get platform => switch (defaultTargetPlatform) {
        TargetPlatform.android => 'android',
        TargetPlatform.iOS => 'ios',
        _ => null,
      };

  @override
  Future<String?> currentToken() async {
    if (platform == null) return null;
    try {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp();
      final messaging = FirebaseMessaging.instance;
      final permission = await messaging.requestPermission();
      if (permission.authorizationStatus == AuthorizationStatus.denied) return null;
      final token = await messaging.getToken();
      return token == null || token.isEmpty ? null : token;
    } on Object {
      return null;
    }
  }
}

/// Keeps the server's record of this guardian's handset current.
///
/// Called every time a guardian's chat list loads. It registers at most once per (family, token):
/// a token that changes (Firebase rotates it) is registered again on the next load, and the
/// server treats a repeat as a no-op.
final class FamilyPushRegistrar {
  FamilyPushRegistrar({
    required FamilyPushClient client,
    required PushTokenSource tokens,
  }) : _client = client,
       _tokens = tokens;

  final FamilyPushClient _client;
  final PushTokenSource _tokens;
  String? _registeredFamilyId;
  String? _registeredToken;
  String? _registeredRegistrationId;

  /// Clears the process-local cache after sign-out so a shared handset registers for its next owner.
  void reset() {
    _registeredFamilyId = null;
    _registeredToken = null;
    _registeredRegistrationId = null;
  }

  /// Removes this handset's saved server registration before sign-out.
  ///
  /// Local state is cleared even when the server cannot be reached, so a later account
  /// cannot be suppressed by a stale cache entry. The caller remains responsible for
  /// reporting the propagated deletion failure to the person signing out.
  Future<void> unregister({required String idToken}) async {
    final familyId = _registeredFamilyId;
    final registrationId = _registeredRegistrationId;
    try {
      if (familyId == null || registrationId == null) return;
      await _client.unregister(
        familyId: familyId,
        registrationId: registrationId,
        idToken: idToken,
      );
    } finally {
      reset();
    }
  }

  /// Returns true when the server holds this handset's registration for [familyId].
  Future<bool> ensureRegistered({
    required String familyId,
    required String idToken,
  }) async {
    final platform = _tokens.platform;
    if (platform == null) return false;
    final token = await _tokens.currentToken();
    if (token == null) return false;
    if (_registeredFamilyId == familyId &&
        _registeredToken == token &&
        _registeredRegistrationId != null) {
      return true;
    }
    final registration = await _client.register(
      familyId: familyId,
      token: token,
      platform: platform,
      locale: _localeCode(),
      idToken: idToken,
    );
    _registeredFamilyId = familyId;
    _registeredToken = token;
    _registeredRegistrationId = registration.id;
    return true;
  }

  /// The nudge's words follow the phone's language: Arabic when the phone is in Arabic, otherwise English.
  static String _localeCode() =>
      PlatformDispatcher.instance.locale.languageCode == 'ar' ? 'ar' : 'en';
}
