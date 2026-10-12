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

  /// The token for creating a registration. This may request notification permission.
  Future<String?> currentToken();

  /// Best-effort token retrieval without requesting notification permission. Used only to remove
  /// an old registration; a null result means that the server state remains unknown.
  Future<String?> currentTokenForCleanup();
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
      final messaging = await _messaging();
      final permission = await messaging.requestPermission();
      if (permission.authorizationStatus == AuthorizationStatus.denied) {
        return null;
      }
      return await _tokenFrom(messaging);
    } on Object {
      return null;
    }
  }

  @override
  Future<String?> currentTokenForCleanup() async {
    if (platform == null) return null;
    try {
      // getToken does not itself display the notification-permission prompt. On platforms where
      // the OS withholds a token without permission, null leaves cleanup explicitly unresolved.
      return await _tokenFrom(await _messaging());
    } on Object {
      return null;
    }
  }

  Future<FirebaseMessaging> _messaging() async {
    if (Firebase.apps.isEmpty) await Firebase.initializeApp();
    return FirebaseMessaging.instance;
  }

  Future<String?> _tokenFrom(FirebaseMessaging messaging) async {
    final token = await messaging.getToken();
    return token == null || token.isEmpty ? null : token;
  }
}

/// Keeps the server's record of this guardian's handset current.
///
/// The persisted ledger distinguishes three facts: a known UUID, a server-confirmed empty state,
/// and unknown legacy state (including an absent ledger written by a pre-ledger app). Registration
/// writes an "untracked may exist" marker before its network request, so a timeout cannot be
/// mistaken for no server row. Failed sign-out deletion retains known UUIDs for a restart retry.
/// FCM tokens and bearer credentials are transient request data and are never stored.
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
  FamilyPushRegistrationSnapshot _snapshot =
      FamilyPushRegistrationSnapshot.unknown;
  String? _registeredToken;
  var _loaded = false;

  /// Clears process-local state after sign-out; durable pending/unknown state is not erased.
  void reset() {
    _snapshot = FamilyPushRegistrationSnapshot.unknown;
    _registeredToken = null;
    _loaded = false;
  }

  /// Attempts cleanup before the provider session is cleared.
  ///
  /// A legacy-unknown state is reconciled by revoking only the exact current FCM token, without
  /// prompting for permission. If no token is available, it remains unknown and the caller gets
  /// a post-logout warning. A failed UUID deletion is retained durably and retried next time.
  Future<void> unregister({
    required Future<String> Function() idToken,
  }) =>
      _unregister(idToken: idToken);

  Future<void> _unregister({
    required Future<String> Function() idToken,
    String? tokenOverride,
  }) async {
    try {
      await _loadRegistration();
    } on Object {
      // If storage cannot be read, do not interpret that as known-empty. Best-effort cleanup
      // with the current token, then warn so a later authenticated start retries safely.
      final cleanupToken = tokenOverride ?? await _cleanupToken();
      if (cleanupToken != null) {
        try {
          await _client.unregisterCurrentToken(
            token: cleanupToken,
            idToken: await idToken(),
          );
        } on Object {
          // The durable row remains untouched; logout still proceeds with a warning.
        }
      }
      throw StateError(
        'Push registration storage is unreadable; cleanup cannot be confirmed.',
      );
    }
    var snapshot = _snapshot;
    if (!snapshot.hasAnythingToClean) return;

    Future<String>? liveIdToken;
    Future<String> currentIdToken() => liveIdToken ??= idToken();
    var unresolvedLegacy = snapshot.hasUntrackedRegistration;
    final remaining = <FamilyPushRegistrationRecord>[];

    final cleanupToken = tokenOverride ?? await _cleanupToken();
    if (cleanupToken != null) {
      try {
        await _client.unregisterCurrentToken(
          token: cleanupToken,
          idToken: await currentIdToken(),
        );
        // This confirms the current FCM address is absent at the server, without revealing
        // whether a row existed. Known UUIDs are still deleted individually below.
        unresolvedLegacy = false;
      } on Object {
        // Keep the unknown marker. UUID cleanup below can still succeed independently.
      }
    }

    for (final registration in snapshot.registrations) {
      try {
        await _client.unregister(
          familyId: registration.familyId,
          registrationId: registration.registrationId,
          idToken: await currentIdToken(),
        );
      } on Object {
        remaining.add(registration);
      }
    }

    snapshot = snapshot.copyWith(
      hasUntrackedRegistration: unresolvedLegacy,
      registrations: List<FamilyPushRegistrationRecord>.unmodifiable(remaining),
    );
    await _persist(snapshot);
    if (snapshot.hasAnythingToClean) {
      throw StateError(
        'A push registration may still exist; cleanup state was retained for retry.',
      );
    }
  }

  /// Returns true when the server holds this handset's registration for [familyId].
  Future<bool> ensureRegistered({
    required String familyId,
    required String idToken,
  }) async {
    await _loadRegistration();
    // Never create server state that cannot be found or reconciled after this process exits.
    if (!_store.isRestartSafe) return false;
    final platform = _tokens.platform;
    if (platform == null) return false;

    // A previous process may have left a known row (or a failed-delete retry). Try to remove
    // it before this process creates a new row; failure is retained but never blocks sign-in.
    if (_registeredToken == null && _snapshot.hasAnythingToClean) {
      try {
        await _unregister(idToken: () async => idToken);
      } on Object {
        // The state remains durable and the next cleanup attempt will retry it.
      }
    }

    final token = await _tokens.currentToken();
    if (token == null) return false;

    // If the permission-free token lookup was unavailable, permission approval may have made
    // the token visible. Resolve the old current-token row before registering the signed-in owner.
    if (_registeredToken == null && _snapshot.hasAnythingToClean) {
      try {
        await _unregister(
          idToken: () async => idToken,
          tokenOverride: token,
        );
      } on Object {
        // Do not block sign-in; any unresolved UUID/legacy marker remains for logout retry.
      }
    }
    final snapshot = _snapshot;
    final current = snapshot.registrations.where(
      (record) => record.familyId == familyId,
    );
    if (!snapshot.hasUntrackedRegistration &&
        _registeredToken == token &&
        current.isNotEmpty) {
      return true;
    }

    // The registration POST can commit remotely and still lose its response. Persist uncertainty
    // before making that side effect, so a restart retries exact-token cleanup rather than claiming
    // an empty server state. Do not send the POST if this durable write fails.
    final inFlight = snapshot.copyWith(
      hasUntrackedRegistration: true,
    );
    await _persist(inFlight);

    final registration = await _client.register(
      familyId: familyId,
      token: token,
      platform: platform,
      locale: _localeCode(),
      idToken: idToken,
    );
    final updatedRecords = List<FamilyPushRegistrationRecord>.of(
      inFlight.registrations,
    );
    final existingIndex = updatedRecords.indexWhere(
      (record) => record.registrationId == registration.id,
    );
    final saved = FamilyPushRegistrationRecord(
      familyId: familyId,
      registrationId: registration.id,
    );
    if (existingIndex == -1) {
      updatedRecords.add(saved);
    } else {
      // A unique FCM token can move to another family/guardian while keeping the same UUID.
      updatedRecords[existingIndex] = saved;
    }
    final confirmed = FamilyPushRegistrationSnapshot(
      hasUntrackedRegistration: false,
      registrations: List<FamilyPushRegistrationRecord>.unmodifiable(
        updatedRecords,
      ),
    );
    try {
      await _persist(confirmed);
    } on Object {
      // The on-disk in-flight marker remains recoverable. Best-effort compensation removes the
      // current token without persisting it; if this also fails, a later sign-out retries it.
      try {
        await _client.unregisterCurrentToken(token: token, idToken: idToken);
      } on Object {
        // Keep the in-flight unknown marker in process state and on disk for cleanup retry.
      }
      rethrow;
    }
    _registeredToken = token;
    return true;
  }

  Future<String?> _cleanupToken() async {
    try {
      return await _tokens
          .currentTokenForCleanup()
          .timeout(const Duration(seconds: 3));
    } on Object {
      return null;
    }
  }

  Future<void> _loadRegistration() async {
    if (_loaded) return;
    _snapshot = await _store.read();
    _loaded = true;
  }

  Future<void> _persist(FamilyPushRegistrationSnapshot snapshot) async {
    await _store.save(snapshot);
    _snapshot = snapshot;
    _loaded = true;
  }

  /// The nudge's words follow the phone's language: Arabic when the phone is in Arabic, otherwise English.
  static String _localeCode() =>
      PlatformDispatcher.instance.locale.languageCode == 'ar' ? 'ar' : 'en';
}
