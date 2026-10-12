import 'dart:convert';

import 'package:family_os/features/n02_day/family_push_registration.dart';
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

void main() {
  late List<Map<String, Object?>> posted;
  late List<http.Request> requests;
  late bool failUnregister;
  late FamilyPushClient client;

  setUp(() {
    posted = <Map<String, Object?>>[];
    requests = <http.Request>[];
    failUnregister = false;
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

  test('a handset is registered once per token, and again when Firebase rotates the token', () async {
    final tokens = _FakeTokens();
    final registrar = FamilyPushRegistrar(client: client, tokens: tokens);

    expect(await registrar.ensureRegistered(familyId: _family, idToken: 'id'), isTrue);
    expect(await registrar.ensureRegistered(familyId: _family, idToken: 'id'), isTrue);
    expect(posted, hasLength(1));
    expect(posted.single['token'], _firstToken);

    tokens.token = _rotatedToken;
    await registrar.ensureRegistered(familyId: _family, idToken: 'id');
    expect(posted, hasLength(2));
    expect(posted.last['token'], _rotatedToken);
  });

  test('a shared handset registers again after sign-out clears the local owner cache', () async {
    final registrar = FamilyPushRegistrar(client: client, tokens: _FakeTokens());

    await registrar.ensureRegistered(familyId: _family, idToken: 'first-owner');
    registrar.reset();
    await registrar.ensureRegistered(familyId: _family, idToken: 'next-owner');

    expect(posted, hasLength(2));
  });

  test('unregister removes the exact registration using the active account token', () async {
    final registrar = FamilyPushRegistrar(client: client, tokens: _FakeTokens());

    await registrar.ensureRegistered(familyId: _family, idToken: 'first-owner');
    await registrar.unregister(idToken: 'first-owner');

    expect(
      requests.map((request) => request.method).toList(),
      <String>['POST', 'DELETE'],
    );
    expect(requests[1].url.path, endsWith('/$_registrationId'));
    expect(requests[1].headers['authorization'], 'Bearer first-owner');
  });

  test('network failure clears the cache so the next account can register again', () async {
    final registrar = FamilyPushRegistrar(client: client, tokens: _FakeTokens());

    await registrar.ensureRegistered(familyId: _family, idToken: 'first-owner');
    failUnregister = true;
    await expectLater(
      registrar.unregister(idToken: 'first-owner'),
      throwsA(
        isA<FoundationGateApiException>().having(
          (error) => error.failure,
          'failure',
          FoundationGateApiFailure.networkUnavailable,
        ),
      ),
    );

    failUnregister = false;
    expect(
      await registrar.ensureRegistered(familyId: _family, idToken: 'next-owner'),
      isTrue,
    );
    expect(
      requests.map((request) => request.method).toList(),
      <String>['POST', 'DELETE', 'POST'],
    );
    expect(requests.last.headers['authorization'], 'Bearer next-owner');
    expect(posted, hasLength(2));
  });

  test('without a token (no Firebase on this build, or refused) nothing is sent', () async {
    final tokens = _FakeTokens(token: null);
    final registrar = FamilyPushRegistrar(client: client, tokens: tokens);
    expect(await registrar.ensureRegistered(familyId: _family, idToken: 'id'), isFalse);
    expect(posted, isEmpty);
  });

  test('on a platform that cannot receive pushes nothing is sent', () async {
    final registrar = FamilyPushRegistrar(
      client: client,
      tokens: _FakeTokens(platform: null),
    );
    expect(await registrar.ensureRegistered(familyId: _family, idToken: 'id'), isFalse);
    expect(posted, isEmpty);
  });
}
