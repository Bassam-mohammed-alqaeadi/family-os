import 'dart:convert';

import 'package:family_os/features/n02_day/family_push_registration.dart';
import 'package:family_os/foundation_gate/family_push_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_configuration.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _family = '11111111-1111-4111-8111-111111111111';
const _firstToken = 'fcm-token-aaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _rotatedToken = 'fcm-token-bbbbbbbbbbbbbbbbbbbbbbbbbbbb';

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
  late FamilyPushClient client;

  setUp(() {
    posted = <Map<String, Object?>>[];
    client = FamilyPushClient(
      configuration: FoundationGateConfiguration.fromStagingApiOrigin(
        Uri.parse('https://api.example.test'),
      ),
      client: MockClient((request) async {
        posted.add(jsonDecode(request.body) as Map<String, Object?>);
        return http.Response(
          jsonEncode({
            'registration': {
              'id': '44444444-4444-4444-8444-444444444444',
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

  test('without a token (no Firebase on this build, or refused) nothing is sent', () async {
    final tokens = _FakeTokens()..token = null;
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
