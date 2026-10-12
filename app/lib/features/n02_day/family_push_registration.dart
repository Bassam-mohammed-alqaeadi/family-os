import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:family_os/foundation_gate/family_push_client.dart';
import 'package:family_os/features/n02_day/family_push_registration_store.dart';

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
/// The family and server registration id are persisted locally so sign-out can still remove the
/// exact row after process death, a denied notification permission, or a failed refresh request.
/// The FCM token and account credential are never written to that store.
final class FamilyPushRegistrar {
  FamilyPushRegistrar({
    required FamilyPushClient client,
    required PushTokenSource tokens,
    required FamilyPushRegistrationStore store,
  }) : _client = client,
       _tokens = tokens,
       _store = store;

  final FamilyPushClient _client;
  final PushTokenSource _tokens;
  final FamilyPushRegistrationStore _store;
  FamilyPushRegistrationRecord? _registration;
  String? _registeredToken;
  var _loaded = false;

  /// Clears process-local state after the durable registration has been cleared by sign-out.
  void reset() {
    _registration = null;
    _registeredToken = null;
    _loaded = false;
  }

  /// Deletes the persisted registration before the provider session is cleared.
  ///
  /// The account token is requested only when a stored registration exists. Regardless of a
  /// server deletion error, the local record is cleared so the next account can register. A
  /// non-durable fallback is treated as uncertain, not as proof that no old server row exists.
  Future<void> unregister({
    required Future<String> Function() idToken,
  }) async {
    try {
      await _loadRegistration();
      final registration = _registration;
      if (!_store.isRestartSafe && registration == null) {
        throw StateError(
          'Cannot verify an older push registration without durable local storage.',
        );
      }
      if (registration == null) return;
      await _client.unregister(
        familyId: registration.familyId,
        registrationId: registration.registrationId,
        idToken: await idToken(),
      );
    } finally {
      try {
        await _store.clear();
      } finally {
        reset();
      }
    }
  }

  /// Returns true when the server holds this handset's registration for [familyId].
  Future<bool> ensureRegistered({
    required String familyId,
    required String idToken,
  }) async {
    await _loadRegistration();
    // Never create a server row that cannot be found after this process exits.
    if (!_store.isRestartSafe) return false;
    final platform = _tokens.platform;
    if (platform == null) return false;
    final token = await _tokens.currentToken();
    if (token == null) return false;
    final current = _registration;
    if (current?.familyId == familyId &&
        _registeredToken == token &&
        current?.registrationId.isNotEmpty == true) {
      return true;
    }
    final registration = await _client.register(
      familyId: familyId,
      token: token,
      platform: platform,
      locale: _localeCode(),
      idToken: idToken,
    );
    final saved = FamilyPushRegistrationRecord(
      familyId: familyId,
      registrationId: registration.id,
    );
    try {
      await _store.save(saved);
    } on Object {
      // Avoid leaving an untracked server row if durable persistence fails after POST succeeds.
      _registration = saved;
      _registeredToken = token;
      _loaded = true;
      try {
        await _client.unregister(
          familyId: saved.familyId,
          registrationId: saved.registrationId,
          idToken: idToken,
        );
        reset();
      } on Object {
        // Keep the in-process id available for a sign-out retry; the failure remains visible to
        // the best-effort caller, and no credential is retained.
      }
      rethrow;
    }
    _registration = saved;
    _registeredToken = token;
    _loaded = true;
    return true;
  }

  Future<void> _loadRegistration() async {
    if (_loaded) return;
    _registration = await _store.read();
    _registeredToken = null;
    _loaded = true;
  }

  /// The nudge's words follow the phone's language: Arabic when the phone is in Arabic, otherwise English.
  static String _localeCode() =>
      PlatformDispatcher.instance.locale.languageCode == 'ar' ? 'ar' : 'en';
}
