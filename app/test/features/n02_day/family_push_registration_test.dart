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
const _firstToken = 'fcm-token-aaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _rotatedToken = 'fcm-token-bbbbbbbbbbbbbbbbbbbbbbbbbbbb';
const _registrationId = '44444444-4444-4444-8444-444444444444';

final class _FakeTokens implements PushTokenSource {
  _FakeTokens({this.platform = 'android', this.token = _firstToken});

  @override
  final String? platform;
  String? token;

  @override
  Future<String?> currentToken() async => token;
}

final class _PersistentStore implements FamilyPushRegistrationStore {
  FamilyPushRegistrationRecord? record;

  @override
  bool get isRestartSafe => true;

  @override
  Future<FamilyPushRegistrationRecord?> read() async => record;

  @override
  Future<void> save(FamilyPushRegistrationRecord value) async {
    record = value;
  }

  @override
  Future<void> clear() async {
    record = null;
  }
}

final class _NonDurableStore extends _PersistentStore {
  @override
  bool get isRestartSafe => false;
}

void main() {
  late List<Map<String, Object?>> posted;
  late List<http.Request> requests;
  late bool failRegister;
  late bool failUnregister;
  late _PersistentStore store;
  late FamilyPushClient client;

  setUp(() {
    posted = <Map<String, Object?>>[];
    requests = <http.Request>[];
    failRegister = false;
    failUnregister = false;
    store = _PersistentStore();
    client = FamilyPushClient(
      configuration: FoundationGateConfiguration.fromStagingApiOrigin(
        Uri.parse('https://api.example.test'),
      ),
      client: MockClient((request) async {
        requests.add(request);
        if (request.method == 'DELETE') {
          if (failUnregister) throw StateError('offline');
          return http.Response('', 204);
        }
        if (failRegister) throw StateError('registration offline');
        posted.add(jsonDecode(request.body) as Map<String, Object?>);
        return http.Response(
          jsonEncode({
            'registration': {
              'id': _registrationId,
              'platform': 'android',
              'locale': 'en',
            },
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
  });

  test(
    'a handset is registered once per token in a process, and again when Firebase rotates it',
    () async {
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
      expect(store.record?.familyId, _family);
      expect(store.record?.registrationId, _registrationId);

      tokens.token = _rotatedToken;
      await registrar.ensureRegistered(familyId: _family, idToken: 'id');
      expect(posted, hasLength(2));
      expect(posted.last['token'], _rotatedToken);
    },
  );

  test(
    'a persisted old registration survives registrar recreation and denied permission',
    () async {
      final beforeRestart = FamilyPushRegistrar(
        client: client,
        tokens: _FakeTokens(),
        store: store,
      );
      await beforeRestart.ensureRegistered(
        familyId: _family,
        idToken: 'first-owner',
      );
      expect(store.record, isNotNull);

      // A new registrar represents a new app process. Permission refusal prevents re-registering,
      // but must not erase the old server row's local address.
      final afterRestart = FamilyPushRegistrar(
        client: client,
        tokens: _FakeTokens(token: null),
        store: store,
      );
      expect(
        await afterRestart.ensureRegistered(
          familyId: _family,
          idToken: 'first-owner',
        ),
        isFalse,
      );
      expect(store.record?.registrationId, _registrationId);
      await afterRestart.unregister(idToken: () async => 'first-owner');

      expect(
        requests.map((request) => request.method).toList(),
        <String>['POST', 'DELETE'],
      );
      expect(requests.last.url.path, endsWith('/$_registrationId'));
      expect(requests.last.headers['authorization'], 'Bearer first-owner');
      expect(store.record, isNull);
    },
  );

  test('unregister deletes the exact persisted row using a fresh account token', () async {
    final registrar = FamilyPushRegistrar(
      client: client,
      tokens: _FakeTokens(),
      store: store,
    );

    await registrar.ensureRegistered(familyId: _family, idToken: 'first-owner');
    await registrar.unregister(idToken: () async => 'first-owner');

    expect(
      requests.map((request) => request.method).toList(),
      <String>['POST', 'DELETE'],
    );
    expect(requests[1].url.path, endsWith('/$_registrationId'));
    expect(requests[1].headers['authorization'], 'Bearer first-owner');
    expect(store.record, isNull);
  });

  test(
    'deletion failure clears durable local state so the next account can register',
    () async {
      final registrar = FamilyPushRegistrar(
        client: client,
        tokens: _FakeTokens(),
        store: store,
      );

      await registrar.ensureRegistered(familyId: _family, idToken: 'first-owner');
      failUnregister = true;
      await expectLater(
        registrar.unregister(idToken: () async => 'first-owner'),
        throwsA(
          isA<FoundationGateApiException>().having(
            (error) => error.failure,
            'failure',
            FoundationGateApiFailure.networkUnavailable,
          ),
        ),
      );
      expect(store.record, isNull);

      failUnregister = false;
      expect(
        await registrar.ensureRegistered(
          familyId: _family,
          idToken: 'next-owner',
        ),
        isTrue,
      );
      expect(
        requests.map((request) => request.method).toList(),
        <String>['POST', 'DELETE', 'POST'],
      );
      expect(requests[1].headers['authorization'], 'Bearer first-owner');
      expect(requests.last.headers['authorization'], 'Bearer next-owner');
      expect(posted, hasLength(2));
    },
  );

  test(
    'a failed startup registration leaves the previous server id available for sign-out',
    () async {
      store.record = const FamilyPushRegistrationRecord(
        familyId: _family,
        registrationId: _registrationId,
      );
      final registrar = FamilyPushRegistrar(
        client: client,
        tokens: _FakeTokens(token: _rotatedToken),
        store: store,
      );
      failRegister = true;

      await expectLater(
        registrar.ensureRegistered(
          familyId: _family,
          idToken: 'first-owner',
        ),
        throwsA(
          isA<FoundationGateApiException>().having(
            (error) => error.failure,
            'failure',
            FoundationGateApiFailure.networkUnavailable,
          ),
        ),
      );
      expect(store.record?.registrationId, _registrationId);

      failRegister = false;
      await registrar.unregister(idToken: () async => 'first-owner');
      expect(requests.last.method, 'DELETE');
      expect(requests.last.url.path, endsWith('/$_registrationId'));
      expect(requests.last.headers['authorization'], 'Bearer first-owner');
      expect(store.record, isNull);
    },
  );

  test('without a token, registration is skipped and an existing row is retained', () async {
    store.record = const FamilyPushRegistrationRecord(
      familyId: _family,
      registrationId: _registrationId,
    );
    final registrar = FamilyPushRegistrar(
      client: client,
      tokens: _FakeTokens(token: null),
      store: store,
    );
    expect(await registrar.ensureRegistered(familyId: _family, idToken: 'id'), isFalse);
    expect(requests, isEmpty);
    expect(store.record?.registrationId, _registrationId);
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
    expect(posted, isEmpty);
  });
}
