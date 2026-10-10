import 'dart:convert';

import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/runtime/family_invite_code_source.dart';
import 'package:family_os/foundation_gate/children_roster_api_client.dart';
import 'package:family_os/foundation_gate/family_device_api_client.dart';
import 'package:family_os/foundation_gate/family_discovery_api_client.dart';
import 'package:family_os/foundation_gate/family_invite_code_api_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_configuration.dart';
import 'package:family_os/foundation_gate/foundation_gate_http.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';
import 'package:family_os/foundation_gate/foundation_gate_session_controller.dart';
import 'package:family_os/foundation_gate/main_app_foundation_runtime.dart';
import 'package:flutter_test/flutter_test.dart';

import 'foundation_gate_test_fakes.dart';

const familyId = '11111111-1111-4111-8111-111111111111';
const inviteId = '77777777-7777-4777-8777-777777777777';
const membershipId = '88888888-8888-4888-8888-888888888888';
const idempotencyKey = '66666666-6666-4666-8666-666666666666';

/// Exactly what `backend/src/family-invite-codes.js` returns from an issue.
const issuedBody =
    '{"invite":{"id":"$inviteId","role":"co_guardian","status":"open",'
    '"expiresAt":"2026-10-11T09:00:00.000Z","createdAt":"2026-10-10T09:00:00.000Z",'
    '"code":"ABCDE-FGHJK"}}';
const redeemedBody =
    '{"family":{"id":"$familyId","displayName":"عائلة الدعوة"},'
    '"membership":{"id":"$membershipId","role":"co_guardian","status":"active",'
    '"statusReasonCode":null,"version":1,"joinedAt":"2026-10-10T09:05:00.000Z",'
    '"statusChangedAt":null,"createdAt":"2026-10-10T09:05:00.000Z"}}';

FoundationGateConfiguration _configuration() =>
    FoundationGateConfiguration.fromStagingApiOrigin(
      Uri.parse('https://staging.example.test'),
    );

void main() {
  FamilyInviteCodeApiClient clientFor(FakeTransport transport) =>
      FamilyInviteCodeApiClient(
        configuration: _configuration(),
        transport: transport,
      );

  FakeTransport answering(int status, String body) => FakeTransport(
    const FoundationGateHttpResponse(statusCode: 200, body: '{}'),
    postResponse: FoundationGateHttpResponse(statusCode: status, body: body),
  );

  test('issue posts only the role to the family invite-code route', () async {
    final transport = answering(201, issuedBody);
    final issued = await clientFor(transport).issue(
      familyId: familyId,
      role: 'co_guardian',
      idempotencyKey: idempotencyKey,
      idToken: 'synthetic-token',
    );
    expect(
      transport.postedUri.toString(),
      'https://staging.example.test/v1/families/$familyId/invite-codes',
    );
    expect(jsonDecode(transport.postedBody!), {'role': 'co_guardian'});
    expect(transport.postedHeaders?['idempotency-key'], idempotencyKey);
    expect(transport.postedHeaders?['authorization'], 'Bearer synthetic-token');
    expect(issued.id, inviteId);
    expect(issued.code, 'ABCDE-FGHJK');
    expect(issued.expiresAt, DateTime.utc(2026, 10, 11, 9));
  });

  test(
    'a code that does not look like a server code is an invalid response',
    () async {
      final transport = answering(
        201,
        issuedBody.replaceFirst('ABCDE-FGHJK', 'abcde-fghjk'),
      );
      await expectLater(
        clientFor(transport).issue(
          familyId: familyId,
          role: 'co_guardian',
          idempotencyKey: idempotencyKey,
          idToken: 'synthetic-token',
        ),
        throwsA(
          isA<FoundationGateApiException>().having(
            (error) => error.failure,
            'failure',
            FoundationGateApiFailure.invalidResponse,
          ),
        ),
      );
    },
  );

  test('primary_guardian is never requested', () async {
    final transport = answering(201, issuedBody);
    await expectLater(
      clientFor(transport).issue(
        familyId: familyId,
        role: 'primary_guardian',
        idempotencyKey: idempotencyKey,
        idToken: 'synthetic-token',
      ),
      throwsA(isA<FoundationGateApiException>()),
    );
    expect(transport.postedUri, isNull);
  });

  test('revoke posts to the invite revoke route', () async {
    final transport = answering(
      200,
      '{"invite":{"id":"$inviteId","role":"co_guardian","status":"revoked",'
      '"expiresAt":"2026-10-11T09:00:00.000Z","createdAt":"2026-10-10T09:00:00.000Z"}}',
    );
    await clientFor(transport).revoke(
      familyId: familyId,
      inviteId: inviteId,
      idempotencyKey: idempotencyKey,
      idToken: 'synthetic-token',
    );
    expect(
      transport.postedUri.toString(),
      'https://staging.example.test/v1/families/$familyId/invite-codes/$inviteId/revoke',
    );
  });

  test(
    'redeem normalises the typed code and reads the joined family',
    () async {
      final transport = answering(200, redeemedBody);
      final joined = await clientFor(transport).redeem(
        code: ' abcde fghjk ',
        idempotencyKey: idempotencyKey,
        idToken: 'synthetic-token',
      );
      expect(
        transport.postedUri.toString(),
        'https://staging.example.test/v1/invite-codes/redeem',
      );
      expect(jsonDecode(transport.postedBody!), {'code': 'ABCDEFGHJK'});
      expect(joined.familyId, familyId);
      expect(joined.familyDisplayName, 'عائلة الدعوة');
      expect(joined.role, 'co_guardian');
    },
  );

  test('a malformed code never leaves the device', () async {
    final transport = answering(200, redeemedBody);
    await expectLater(
      clientFor(transport).redeem(
        code: 'O0O0O-I1I1I',
        idempotencyKey: idempotencyKey,
        idToken: 'synthetic-token',
      ),
      throwsA(isA<FoundationGateApiException>()),
    );
    expect(transport.postedUri, isNull);
  });

  for (final (status, failure) in [
    (404, FoundationGateApiFailure.notFound),
    (409, FoundationGateApiFailure.conflict),
    (401, FoundationGateApiFailure.unauthenticated),
    (503, FoundationGateApiFailure.serviceUnavailable),
  ]) {
    test('redeem maps $status to ${failure.name}', () async {
      final transport = answering(status, '{"error":{"code":"x"}}');
      await expectLater(
        clientFor(transport).redeem(
          code: 'ABCDE-FGHJK',
          idempotencyKey: idempotencyKey,
          idToken: 'synthetic-token',
        ),
        throwsA(
          isA<FoundationGateApiException>().having(
            (error) => error.failure,
            'failure',
            failure,
          ),
        ),
      );
    });
  }

  test('redeem names the rate limit apart from an outage', () async {
    final transport = answering(
      429,
      '{"error":{"code":"rate_limit_exceeded"}}',
    );
    await expectLater(
      clientFor(transport).redeem(
        code: 'ABCDE-FGHJK',
        idempotencyKey: idempotencyKey,
        idToken: 'synthetic-token',
      ),
      throwsA(isA<FamilyInviteCodeRateLimited>()),
    );
  });

  test(
    'runtime: redeeming adopts the joined family from the server list, as co-guardian',
    () async {
      final identity = FakeIdentity(subject: 'firebase-mother');
      final configuration = _configuration();
      final discovery = FakeTransport(
        const FoundationGateHttpResponse(
          statusCode: 200,
          body: '{"families":[]}',
        ),
      );
      final invites = answering(200, redeemedBody);
      final runtime = MainAppFoundationRuntime(
        identity: identity,
        controller: FoundationGateSessionController(
          identity: identity,
          discoveryApi: FamilyDiscoveryApiClient(
            configuration: configuration,
            transport: discovery,
          ),
          rosterApi: ChildrenRosterApiClient(
            configuration: configuration,
            transport: FakeTransport(
              const FoundationGateHttpResponse(
                statusCode: 200,
                body: '{"children":[]}',
              ),
            ),
          ),
        ),
        deviceApi: FamilyDeviceApiClient(
          configuration: configuration,
          transport: FakeTransport(
            const FoundationGateHttpResponse(
              statusCode: 200,
              body: '{"devices":[]}',
            ),
          ),
        ),
        inviteCodeApi: FamilyInviteCodeApiClient(
          configuration: configuration,
          transport: invites,
        ),
      );
      addTearDown(runtime.dispose);
      final identitySource = MainAppFoundationIdentitySource(runtime);
      final source = RemoteFamilyInviteCodeSource(runtime);

      final before = await identitySource.signIn(
        email: 'mother@example.test',
        password: 'synthetic-password',
      );
      expect(
        before.familyId,
        isNull,
        reason: 'no family before the code is redeemed',
      );

      // The server now lists the family this account joined.
      discovery.response = const FoundationGateHttpResponse(
        statusCode: 200,
        body:
            '{"families":[{"id":"$familyId","displayName":"عائلة الدعوة","role":"co_guardian"}]}',
      );
      final result = await source.redeem(
        code: 'ABCDE-FGHJK',
        idempotencyKey: idempotencyKey,
      );
      expect(result.isJoined, isTrue);
      expect(result.familyId, familyId);
      expect(runtime.selectedFamilyId, familyId);
      expect(identitySource.value.familyId, FamilyId(familyId));
      expect(identitySource.value.role, AppRole.mother);
      expect(identitySource.value.isPrimaryOwner, isFalse);

      // A co-guardian cannot issue codes: refused on the phone before any request.
      final postsBefore = invites.postedHeadersHistory.length;
      final issued = await source.issue(
        familyId: FamilyId(familyId),
        role: 'co_guardian',
        idempotencyKey: '99999999-9999-4999-8999-999999999999',
      );
      expect(issued.failure, InviteCodeFailure.accessDenied);
      expect(invites.postedHeadersHistory.length, postsBefore);
    },
  );

  test('runtime: a spent code is a refusal and no family is adopted', () async {
    final identity = FakeIdentity(subject: 'firebase-stranger');
    final configuration = _configuration();
    final runtime = MainAppFoundationRuntime(
      identity: identity,
      controller: FoundationGateSessionController(
        identity: identity,
        discoveryApi: FamilyDiscoveryApiClient(
          configuration: configuration,
          transport: FakeTransport(
            const FoundationGateHttpResponse(
              statusCode: 200,
              body: '{"families":[]}',
            ),
          ),
        ),
        rosterApi: ChildrenRosterApiClient(
          configuration: configuration,
          transport: FakeTransport(
            const FoundationGateHttpResponse(statusCode: 200, body: '{}'),
          ),
        ),
      ),
      deviceApi: FamilyDeviceApiClient(
        configuration: configuration,
        transport: FakeTransport(
          const FoundationGateHttpResponse(statusCode: 200, body: '{}'),
        ),
      ),
      inviteCodeApi: FamilyInviteCodeApiClient(
        configuration: configuration,
        transport: answering(
          404,
          '{"error":{"code":"invite_code_not_redeemable"}}',
        ),
      ),
    );
    addTearDown(runtime.dispose);
    final result = await RemoteFamilyInviteCodeSource(
      runtime,
    ).redeem(code: 'ABCDE-FGHJK', idempotencyKey: idempotencyKey);
    expect(result.failure, InviteCodeFailure.notRedeemable);
    expect(runtime.selectedFamilyId, isNull);
  });
}
