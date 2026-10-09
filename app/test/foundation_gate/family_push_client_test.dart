import 'dart:convert';

import 'package:family_os/foundation_gate/family_push_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_configuration.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _family = '11111111-1111-4111-8111-111111111111';
const _registration = '44444444-4444-4444-8444-444444444444';
const _token = 'fcm-token-aaaaaaaaaaaaaaaaaaaaaaaaaaaa';

FoundationGateConfiguration _config() =>
    FoundationGateConfiguration.fromStagingApiOrigin(Uri.parse('https://api.example.test'));

Map<String, Object?> _registrationJson({String locale = 'ar'}) => <String, Object?>{
  'registration': <String, Object?>{'id': _registration, 'platform': 'android', 'locale': locale},
};

FamilyPushClient _client(Future<http.Response> Function(http.Request) handler) =>
    FamilyPushClient(configuration: _config(), client: MockClient(handler));

void main() {
  test('registration posts the token to the family route with the bearer credential', () async {
    late http.Request seen;
    final client = _client((request) async {
      seen = request;
      return http.Response(jsonEncode(_registrationJson()), 201,
          headers: {'content-type': 'application/json'});
    });

    final registration = await client.register(
      familyId: _family,
      token: _token,
      platform: 'android',
      locale: 'ar',
      idToken: 'id-token-value',
    );

    expect(seen.method, 'POST');
    expect(seen.url.path, '/v1/families/$_family/push/registrations');
    expect(seen.headers['authorization'], 'Bearer id-token-value');
    expect(jsonDecode(seen.body), <String, Object?>{
      'token': _token,
      'platform': 'android',
      'locale': 'ar',
    });
    expect(registration.id, _registration);
    expect(registration.locale, 'ar');
  });

  test('a repeat registration answers 200 and is the same record', () async {
    final client = _client((_) async => http.Response(jsonEncode(_registrationJson()), 200,
        headers: {'content-type': 'application/json'}));
    final registration = await client.register(
      familyId: _family,
      token: _token,
      platform: 'android',
      locale: 'ar',
      idToken: 'id-token-value',
    );
    expect(registration.id, _registration);
  });

  test('input the server would refuse is refused before any request leaves the app', () async {
    var calls = 0;
    final client = _client((_) async {
      calls += 1;
      return http.Response('{}', 500);
    });

    Future<void> attempt({String? family, String? token, String? platform, String? locale, String? idToken}) =>
        client.register(
          familyId: family ?? _family,
          token: token ?? _token,
          platform: platform ?? 'android',
          locale: locale ?? 'ar',
          idToken: idToken ?? 'id-token-value',
        );

    await expectLater(attempt(family: 'not-a-family'),
        throwsA(_failure(FoundationGateApiFailure.invalidInput)));
    await expectLater(attempt(token: 'short'), throwsA(_failure(FoundationGateApiFailure.invalidInput)));
    await expectLater(attempt(platform: 'web'), throwsA(_failure(FoundationGateApiFailure.invalidInput)));
    await expectLater(attempt(locale: 'fr'), throwsA(_failure(FoundationGateApiFailure.invalidInput)));
    await expectLater(attempt(idToken: '  '), throwsA(_failure(FoundationGateApiFailure.unauthenticated)));
    expect(calls, 0);
  });

  test('each server refusal maps to its own failure', () async {
    final cases = <int, FoundationGateApiFailure>{
      401: FoundationGateApiFailure.unauthenticated,
      403: FoundationGateApiFailure.accessDenied,
      404: FoundationGateApiFailure.notFound,
      503: FoundationGateApiFailure.serviceUnavailable,
    };
    for (final entry in cases.entries) {
      final client = _client((_) async => http.Response(
            jsonEncode({'error': {'code': 'x', 'message': 'x'}}),
            entry.key,
            headers: {'content-type': 'application/json'},
          ));
      await expectLater(
        client.register(
          familyId: _family,
          token: _token,
          platform: 'android',
          locale: 'ar',
          idToken: 'id-token-value',
        ),
        throwsA(_failure(entry.value)),
      );
    }
  });

  test('a malformed registration in a success answer is refused, not stored', () async {
    final client = _client((_) async => http.Response(
          jsonEncode({'registration': {'id': 'not-a-uuid', 'platform': 'android', 'locale': 'ar'}}),
          201,
          headers: {'content-type': 'application/json'},
        ));
    await expectLater(
      client.register(
        familyId: _family,
        token: _token,
        platform: 'android',
        locale: 'ar',
        idToken: 'id-token-value',
      ),
      throwsA(_failure(FoundationGateApiFailure.invalidResponse)),
    );
  });

  test('a dropped connection is reported as unavailable, not as a bad answer', () async {
    final client = _client((_) async => throw http.ClientException('offline'));
    await expectLater(
      client.register(
        familyId: _family,
        token: _token,
        platform: 'android',
        locale: 'ar',
        idToken: 'id-token-value',
      ),
      throwsA(_failure(FoundationGateApiFailure.networkUnavailable)),
    );
  });

  test('removing one of the caller registrations uses the owner route and accepts 204', () async {
    late http.Request seen;
    final client = _client((request) async {
      seen = request;
      return http.Response('', 204);
    });
    await client.unregister(familyId: _family, registrationId: _registration, idToken: 'id-token-value');
    expect(seen.method, 'DELETE');
    expect(seen.url.path, '/v1/families/$_family/push/registrations/$_registration');
  });

  test('a refused removal surfaces the server failure', () async {
    final client = _client((_) async => http.Response('', 404));
    await expectLater(
      client.unregister(familyId: _family, registrationId: _registration, idToken: 'id-token-value'),
      throwsA(_failure(FoundationGateApiFailure.notFound)),
    );
  });
}

Matcher _failure(FoundationGateApiFailure failure) => isA<FoundationGateApiException>()
    .having((error) => error.failure, 'failure', failure);
