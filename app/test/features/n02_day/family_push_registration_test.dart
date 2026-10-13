import 'dart:async';
import 'dart:convert';

import 'package:family_os/features/n02_day/family_push_registration.dart';
import 'package:family_os/features/n02_day/family_push_registration_store.dart';
import 'package:family_os/foundation_gate/family_push_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_configuration.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _family = '11111111-1111-4111-8111-111111111111';
const _otherFamily = '22222222-2222-4222-8222-222222222222';
const _firstToken = 'fcm-token-aaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _rotatedToken = 'fcm-token-bbbbbbbbbbbbbbbbbbbbbbbbbbbb';
const _legacyToken = 'fcm-token-cccccccccccccccccccccccccccc';
const _registrationId = '44444444-4444-4444-8444-444444444444';

Matcher _knownNone() => isA<FamilyPushRegistrationSnapshot>()
    .having(
      (snapshot) => snapshot.hasUntrackedRegistration,
      'hasUntrackedRegistration',
      isFalse,
    )
    .having((snapshot) => snapshot.registrations, 'registrations', isEmpty);

final class _FakeTokens implements PushTokenSource {
  _FakeTokens({
    this.platform = 'android',
    this.token = _firstToken,
    this.cleanupToken = _firstToken,
  });

  @override
  final String? platform;
  String? token;
  String? cleanupToken;
  var registrationTokenReads = 0;
  var cleanupTokenReads = 0;

  @override
  Future<String?> currentToken() async {
    registrationTokenReads += 1;
    return token;
  }

  @override
  Future<String?> currentTokenForCleanup() async {
    cleanupTokenReads += 1;
    return cleanupToken;
  }

  final refreshes = StreamController<String>();

  @override
  Stream<String> tokenRefreshes() => refreshes.stream;
}

final class _PersistentStore implements FamilyPushRegistrationStore {
  FamilyPushRegistrationSnapshot snapshot =
      FamilyPushRegistrationSnapshot.unknown;

  @override
  bool get isRestartSafe => true;

  @override
  Future<FamilyPushRegistrationSnapshot> read() async => snapshot;

  @override
  Future<void> save(FamilyPushRegistrationSnapshot value) async {
    snapshot = value;
  }
}

final class _NonDurableStore extends _PersistentStore {
  @override
  bool get isRestartSafe => false;
}

void main() {
  late List<Map<String, Object?>> posted;
  late List<http.Request> requests;
  late Map<String, FamilyPushRegistrationRecord> serverRows;
  late bool failRegister;
  late bool failUnregister;
  late bool failTokenUnregister;
  late int nextRegistrationId;
  late _PersistentStore store;
  late FamilyPushClient client;

  String registrationIdFor(int sequence) =>
      '77777777-7777-4777-8777-${sequence.toString().padLeft(12, '0')}';

  setUp(() {
    posted = <Map<String, Object?>>[];
    requests = <http.Request>[];
    serverRows = <String, FamilyPushRegistrationRecord>{};
    failRegister = false;
    failUnregister = false;
    failTokenUnregister = false;
    nextRegistrationId = 0;
    store = _PersistentStore();
    client = FamilyPushClient(
      configuration: FoundationGateConfiguration.fromStagingApiOrigin(
        Uri.parse('https://api.example.test'),
      ),
      client: MockClient((request) async {
        requests.add(request);
        if (request.method == 'DELETE' &&
            request.url.path == '/v1/me/push/registrations/current') {
          if (failTokenUnregister) throw StateError('token cleanup offline');
          // Exercise the opaque no-op branch: 204 does not prove the token was deleted.
          return http.Response('', 204);
        }
        if (request.method == 'DELETE') {
          if (failUnregister) throw StateError('registration cleanup offline');
          final registrationId = request.url.pathSegments.last;
          String? token;
          for (final entry in serverRows.entries) {
            if (entry.value.registrationId == registrationId) {
              token = entry.key;
              break;
            }
          }
          if (token != null) serverRows.remove(token);
          return http.Response('', 204);
        }
        if (failRegister) throw StateError('registration offline');
        final body = jsonDecode(request.body) as Map<String, Object?>;
        posted.add(body);
        final token = body['token']! as String;
        final previous = serverRows[token];
        final pathFamily = request.url.pathSegments[2];
        final saved = FamilyPushRegistrationRecord(
          familyId: pathFamily,
          registrationId: previous?.registrationId ??
              registrationIdFor(++nextRegistrationId),
        );
        serverRows[token] = saved;
        return http.Response(
          jsonEncode({
            'registration': {
              'id': saved.registrationId,
              'platform': body['platform'],
              'locale': body['locale'],
            },
          }),
          previous == null ? 201 : 200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
  });

  test(
    'a handset removes the old UUID before registering a rotated token',
    () async {
      store.snapshot = FamilyPushRegistrationSnapshot.knownNone;
      final tokens = _FakeTokens();
      final registrar = FamilyPushRegistrar(
        client: client,
        tokens: tokens,
        store: store,
      );

      expect(await registrar.ensureRegistered(familyId: _family, idToken: 'id'), isTrue);
      expect(await registrar.ensureRegistered(familyId: _family, idToken: 'id'), isTrue);
      expect(posted, hasLength(1));
      expect(posted.single['token'], _firstToken);
      expect(serverRows, hasLength(1));
      expect(store.snapshot.hasUntrackedRegistration, isFalse);
      expect(store.snapshot.registrations, hasLength(1));

      tokens.token = _rotatedToken;
      await registrar.ensureRegistered(familyId: _family, idToken: 'id');
      expect(posted, hasLength(2));
      expect(posted.last['token'], _rotatedToken);
      expect(store.snapshot.registrations, hasLength(1));
      expect(serverRows, hasLength(1));
      expect(serverRows.containsKey(_firstToken), isFalse);
      expect(serverRows.containsKey(_rotatedToken), isTrue);

      await registrar.unregister(idToken: () async => 'live-owner');
      expect(serverRows, isEmpty);
      expect(store.snapshot, _knownNone());
    },
  );

  test(
    'legacy-unknown state can register the live token but remains unresolved',
    () async {
      store.snapshot = FamilyPushRegistrationSnapshot.unknown;
      serverRows[_legacyToken] = const FamilyPushRegistrationRecord(
        familyId: _otherFamily,
        registrationId: '66666666-6666-4666-8666-666666666666',
      );
      final tokens = _FakeTokens(token: _legacyToken, cleanupToken: _legacyToken);
      final registrar = FamilyPushRegistrar(
        client: client,
        tokens: tokens,
        store: store,
      );

      expect(store.snapshot.hasUntrackedRegistration, isTrue);
      expect(await registrar.ensureRegistered(familyId: _family, idToken: 'new-owner'), isTrue);
      expect(await registrar.ensureRegistered(familyId: _family, idToken: 'new-owner'), isTrue);
      expect(posted, hasLength(1));
      expect(serverRows, hasLength(1));
      expect(serverRows[_legacyToken]?.familyId, _family);
      expect(
        serverRows[_legacyToken]?.registrationId,
        '66666666-6666-4666-8666-666666666666',
      );
      // The POST makes this live token addressable, but local state cannot prove it was
      // the same token used by the pre-ledger registration rather than a rotated one.
      expect(store.snapshot.hasUntrackedRegistration, isTrue);
      expect(store.snapshot.registrations, hasLength(1));
      expect(
        requests.first.url.path,
        '/v1/me/push/registrations/current',
      );
      expect(requests.first.headers['authorization'], 'Bearer new-owner');

      await expectLater(
        registrar.unregister(idToken: () async => 'new-owner'),
        throwsA(isA<StateError>()),
      );
      expect(serverRows, isEmpty);
      expect(store.snapshot.hasUntrackedRegistration, isTrue);
      expect(store.snapshot.registrations, isEmpty);
    },
  );

  test(
    'a successful current-token POST does not claim a rotated legacy token is removed',
    () async {
      store.snapshot = FamilyPushRegistrationSnapshot.unknown;
      serverRows[_legacyToken] = const FamilyPushRegistrationRecord(
        familyId: _otherFamily,
        registrationId: '66666666-6666-4666-8666-666666666666',
      );
      final tokens = _FakeTokens(
        token: _rotatedToken,
        cleanupToken: _rotatedToken,
      );
      final registrar = FamilyPushRegistrar(
        client: client,
        tokens: tokens,
        store: store,
      );

      expect(
        await registrar.ensureRegistered(familyId: _family, idToken: 'owner'),
        isTrue,
      );
      expect(posted.single['token'], _rotatedToken);
      expect(serverRows.keys.toSet(), {_legacyToken, _rotatedToken});
      expect(serverRows[_legacyToken]?.familyId, _otherFamily);
      expect(serverRows[_rotatedToken]?.familyId, _family);
      expect(store.snapshot.hasUntrackedRegistration, isTrue);
      expect(store.snapshot.registrations, hasLength(1));

      await expectLater(
        registrar.unregister(idToken: () async => 'owner'),
        throwsA(isA<StateError>()),
      );
      expect(serverRows.keys.toSet(), {_legacyToken});
      expect(store.snapshot.hasUntrackedRegistration, isTrue);
    },
  );

  test(
    'permission denial keeps legacy state unknown after opaque token cleanup',
    () async {
      store.snapshot = FamilyPushRegistrationSnapshot.unknown;
      serverRows[_legacyToken] = const FamilyPushRegistrationRecord(
        familyId: _family,
        registrationId: '66666666-6666-4666-8666-666666666666',
      );
      final tokens = _FakeTokens(token: null, cleanupToken: _legacyToken);
      final registrar = FamilyPushRegistrar(
        client: client,
        tokens: tokens,
        store: store,
      );

      expect(await registrar.ensureRegistered(familyId: _family, idToken: 'owner'), isFalse);
      expect(tokens.cleanupTokenReads, 1);
      expect(tokens.registrationTokenReads, 1);
      expect(posted, isEmpty);
      // The fake returns the same opaque 204 without removing its row. The app cannot claim
      // whether that response matched an owned token, a foreign token, or no row at all.
      expect(serverRows, hasLength(1));
      // The API intentionally does not reveal whether an absent or foreign-owned row matched.
      // A successful cleanup request therefore cannot promote this legacy state to known-empty.
      expect(store.snapshot.hasUntrackedRegistration, isTrue);
      expect(store.snapshot.registrations, isEmpty);
      await expectLater(
        registrar.unregister(idToken: () async => 'owner'),
        throwsA(isA<StateError>()),
      );
      expect(store.snapshot.hasUntrackedRegistration, isTrue);
    },
  );

  test(
    'permission denial without a recoverable token remains unknown and warns instead of claiming clean',
    () async {
      store.snapshot = FamilyPushRegistrationSnapshot.unknown;
      serverRows[_legacyToken] = const FamilyPushRegistrationRecord(
        familyId: _family,
        registrationId: '66666666-6666-4666-8666-666666666666',
      );
      final registrar = FamilyPushRegistrar(
        client: client,
        tokens: _FakeTokens(token: null, cleanupToken: null),
        store: store,
      );

      expect(await registrar.ensureRegistered(familyId: _family, idToken: 'owner'), isFalse);
      expect(serverRows, hasLength(1));
      expect(store.snapshot.hasUntrackedRegistration, isTrue);
      await expectLater(
        registrar.unregister(idToken: () async => 'owner'),
        throwsA(isA<StateError>()),
      );
      expect(store.snapshot.hasUntrackedRegistration, isTrue);
      expect(serverRows, hasLength(1));
      expect(requests, isEmpty);
    },
  );

  test(
    'ambiguous startup registration failure keeps legacy cleanup possible',
    () async {
      store.snapshot = FamilyPushRegistrationSnapshot.unknown;
      serverRows[_legacyToken] = const FamilyPushRegistrationRecord(
        familyId: _family,
        registrationId: '66666666-6666-4666-8666-666666666666',
      );
      final tokens = _FakeTokens(token: _legacyToken, cleanupToken: _legacyToken);
      final registrar = FamilyPushRegistrar(
        client: client,
        tokens: tokens,
        store: store,
      );
      failRegister = true;

      await expectLater(
        registrar.ensureRegistered(familyId: _family, idToken: 'owner'),
        throwsA(
          isA<FoundationGateApiException>().having(
            (error) => error.failure,
            'failure',
            FoundationGateApiFailure.networkUnavailable,
          ),
        ),
      );
      expect(store.snapshot.hasUntrackedRegistration, isTrue);
      expect(serverRows, hasLength(1));

      await expectLater(
        registrar.unregister(idToken: () async => 'owner'),
        throwsA(isA<StateError>()),
      );
      expect(serverRows, hasLength(1));
      expect(store.snapshot.hasUntrackedRegistration, isTrue);
      expect(store.snapshot.registrations, isEmpty);
    },
  );

  test(
    'failed cleanup blocks a new push registration until a retry succeeds',
    () async {
      const oldRecord = FamilyPushRegistrationRecord(
        familyId: _family,
        registrationId: _registrationId,
      );
      store.snapshot = const FamilyPushRegistrationSnapshot(
        hasUntrackedRegistration: false,
        registrations: <FamilyPushRegistrationRecord>[oldRecord],
      );
      serverRows[_firstToken] = oldRecord;
      final registrar = FamilyPushRegistrar(
        client: client,
        tokens: _FakeTokens(token: _rotatedToken, cleanupToken: _firstToken),
        store: store,
      );
      failUnregister = true;
      failTokenUnregister = true;

      expect(
        await registrar.ensureRegistered(familyId: _family, idToken: 'owner'),
        isFalse,
      );
      expect(posted, isEmpty);
      expect(serverRows, hasLength(1));
      expect(store.snapshot.registrations, <FamilyPushRegistrationRecord>[oldRecord]);

      failUnregister = false;
      failTokenUnregister = false;
      expect(
        await registrar.ensureRegistered(familyId: _family, idToken: 'owner'),
        isTrue,
      );
      expect(posted, hasLength(1));
      expect(posted.single['token'], _rotatedToken);
      expect(serverRows, hasLength(1));
      expect(serverRows[_rotatedToken]?.familyId, _family);
    },
  );

  test(
    'failed deletion survives app restart and is retried before state is cleared',
    () async {
      const oldRecord = FamilyPushRegistrationRecord(
        familyId: _family,
        registrationId: _registrationId,
      );
      store.snapshot = const FamilyPushRegistrationSnapshot(
        hasUntrackedRegistration: false,
        registrations: <FamilyPushRegistrationRecord>[oldRecord],
      );
      serverRows[_firstToken] = oldRecord;
      final firstProcess = FamilyPushRegistrar(
        client: client,
        tokens: _FakeTokens(cleanupToken: null),
        store: store,
      );
      failUnregister = true;
      failTokenUnregister = true;

      await expectLater(
        firstProcess.unregister(idToken: () async => 'owner'),
        throwsA(isA<StateError>()),
      );
      expect(store.snapshot.registrations, <FamilyPushRegistrationRecord>[oldRecord]);
      expect(serverRows, hasLength(1));

      // The new registrar models a process restart; it can retry using a fresh account token.
      failUnregister = false;
      failTokenUnregister = false;
      final afterRestart = FamilyPushRegistrar(
        client: client,
        tokens: _FakeTokens(cleanupToken: null),
        store: store,
      );
      await afterRestart.unregister(idToken: () async => 'owner');
      expect(serverRows, isEmpty);
      expect(store.snapshot, _knownNone());
    },
  );

  test(
    'deletion failure does not suppress registration for the next account',
    () async {
      const oldRecord = FamilyPushRegistrationRecord(
        familyId: _family,
        registrationId: _registrationId,
      );
      store.snapshot = const FamilyPushRegistrationSnapshot(
        hasUntrackedRegistration: false,
        registrations: <FamilyPushRegistrationRecord>[oldRecord],
      );
      serverRows[_firstToken] = oldRecord;
      final firstProcess = FamilyPushRegistrar(
        client: client,
        tokens: _FakeTokens(cleanupToken: null),
        store: store,
      );
      failUnregister = true;
      failTokenUnregister = true;
      await expectLater(
        firstProcess.unregister(idToken: () async => 'first-owner'),
        throwsA(isA<StateError>()),
      );
      expect(store.snapshot.registrations, hasLength(1));

      failUnregister = false;
      failTokenUnregister = false;
      final nextAccount = FamilyPushRegistrar(
        client: client,
        tokens: _FakeTokens(token: _firstToken, cleanupToken: _firstToken),
        store: store,
      );
      expect(
        await nextAccount.ensureRegistered(
          familyId: _otherFamily,
          idToken: 'next-owner',
        ),
        isTrue,
      );
      expect(serverRows, hasLength(1));
      expect(serverRows[_firstToken]?.familyId, _otherFamily);
      expect(store.snapshot.registrations, hasLength(1));
      expect(
        requests.where((request) => request.method == 'POST').last.headers['authorization'],
        'Bearer next-owner',
      );
    },
  );

  test('known UUID cleanup works even when permission is denied', () async {
    const oldRecord = FamilyPushRegistrationRecord(
      familyId: _family,
      registrationId: _registrationId,
    );
    store.snapshot = const FamilyPushRegistrationSnapshot(
      hasUntrackedRegistration: false,
      registrations: <FamilyPushRegistrationRecord>[oldRecord],
    );
    serverRows[_firstToken] = oldRecord;
    final registrar = FamilyPushRegistrar(
      client: client,
      tokens: _FakeTokens(token: null, cleanupToken: null),
      store: store,
    );

    expect(await registrar.ensureRegistered(familyId: _family, idToken: 'owner'), isFalse);
    expect(serverRows, isEmpty);
    expect(store.snapshot, _knownNone());
    expect(posted, isEmpty);
  });

  test('non-durable fallback never creates an untracked server row', () async {
    final registrar = FamilyPushRegistrar(
      client: client,
      tokens: _FakeTokens(),
      store: _NonDurableStore(),
    );
    expect(await registrar.ensureRegistered(familyId: _family, idToken: 'id'), isFalse);
    expect(requests, isEmpty);
  });

  test('on an unsupported platform nothing is sent', () async {
    final registrar = FamilyPushRegistrar(
      client: client,
      tokens: _FakeTokens(platform: null),
      store: store,
    );
    expect(await registrar.ensureRegistered(familyId: _family, idToken: 'id'), isFalse);
    expect(requests, isEmpty);
  });

  test('a mid-session token rotation re-registers under the watched family', () async {
    store.snapshot = FamilyPushRegistrationSnapshot.knownNone;
    final tokens = _FakeTokens();
    final registrar = FamilyPushRegistrar(
      client: client,
      tokens: tokens,
      store: store,
    );
    addTearDown(registrar.reset);

    expect(await registrar.ensureRegistered(familyId: _family, idToken: 'id'), isTrue);
    await registrar.watchTokenRefresh(
      familyId: _family,
      idToken: () async => 'live-owner',
    );
    expect(posted, hasLength(1));

    // Firebase rotates the token mid-session: getToken() answers fresh from now on
    // and the rotation stream fires. The watch — not another ensureRegistered call —
    // must drive the re-registration.
    tokens.token = _rotatedToken;
    tokens.refreshes.add(_rotatedToken);
    for (var i = 0; i < 100 && posted.length < 2; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(posted, hasLength(2));
    expect(posted.last['token'], _rotatedToken);
    expect(serverRows.containsKey(_rotatedToken), isTrue);
    expect(store.snapshot.registrations, hasLength(1));
  });

  test('a refresh event for the already-registered token sends nothing', () async {
    store.snapshot = FamilyPushRegistrationSnapshot.knownNone;
    final tokens = _FakeTokens();
    final registrar = FamilyPushRegistrar(
      client: client,
      tokens: tokens,
      store: store,
    );
    addTearDown(registrar.reset);

    expect(await registrar.ensureRegistered(familyId: _family, idToken: 'id'), isTrue);
    await registrar.watchTokenRefresh(
      familyId: _family,
      idToken: () async => 'live-owner',
    );
    expect(posted, hasLength(1));

    tokens.refreshes.add(_firstToken);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(posted, hasLength(1));
  });

  test('sign-out stops the refresh watch', () async {
    store.snapshot = FamilyPushRegistrationSnapshot.knownNone;
    final tokens = _FakeTokens();
    final registrar = FamilyPushRegistrar(
      client: client,
      tokens: tokens,
      store: store,
    );

    expect(await registrar.ensureRegistered(familyId: _family, idToken: 'id'), isTrue);
    await registrar.watchTokenRefresh(
      familyId: _family,
      idToken: () async => 'live-owner',
    );
    expect(posted, hasLength(1));

    registrar.reset();
    tokens.token = _rotatedToken;
    tokens.refreshes.add(_rotatedToken);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(posted, hasLength(1));
  });
}
