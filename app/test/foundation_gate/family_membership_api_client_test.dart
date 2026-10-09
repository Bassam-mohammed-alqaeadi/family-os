import 'package:family_os/foundation_gate/family_membership_api_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_configuration.dart';
import 'package:family_os/foundation_gate/foundation_gate_http.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'foundation_gate_test_fakes.dart';

const familyId = '11111111-1111-4111-8111-111111111111';
const membershipId = '55555555-5555-4555-8555-555555555555';
const idempotencyKey = '66666666-6666-4666-8666-666666666666';

/// One membership exactly as `backend/src/membership-roster.js` publishes it: no subject,
/// and `isSelf` decided on the server.
const membershipBody =
    '{"id":"$membershipId","role":"co_guardian","status":"invited",'
    '"statusReasonCode":null,"version":1,"joinedAt":null,'
    '"statusChangedAt":"2026-10-07T09:00:00.000Z",'
    '"createdAt":"2026-10-07T09:00:00.000Z","isSelf":false}';

void main() {
  FamilyMembershipApiClient clientFor(FakeTransport transport) =>
      FamilyMembershipApiClient(
        configuration: FoundationGateConfiguration.fromStagingApiOrigin(
          Uri.parse('https://staging.example.test'),
        ),
        transport: transport,
      );

  test('the roster is read from the family membership endpoint', () async {
    final transport = FakeTransport(
      const FoundationGateHttpResponse(
        statusCode: 200,
        body: '{"memberships":[$membershipBody]}',
      ),
    );
    final memberships = await clientFor(
      transport,
    ).list(familyId: familyId, idToken: 'synthetic-token');

    expect(
      transport.requestedUri.toString(),
      'https://staging.example.test/v1/families/$familyId/memberships',
    );
    expect(transport.requestedHeaders?['authorization'], 'Bearer synthetic-token');
    expect(memberships, hasLength(1));
    expect(memberships.single.role, 'co_guardian');
    expect(memberships.single.status, 'invited');
    expect(memberships.single.isPending, isTrue);
    expect(memberships.single.isSelf, isFalse);
  });

  test('an invitation is posted with the role the server accepts', () async {
    final transport = FakeTransport(
      const FoundationGateHttpResponse(statusCode: 200, body: '{}'),
      postResponse: const FoundationGateHttpResponse(
        statusCode: 201,
        body: '{"membership":$membershipBody}',
      ),
    );
    final membership = await clientFor(transport).invite(
      familyId: familyId,
      role: 'co_guardian',
      targetSubject: 'invitee-subject',
      idempotencyKey: idempotencyKey,
      idToken: 'synthetic-token',
    );

    expect(
      transport.postedUri.toString(),
      'https://staging.example.test/v1/families/$familyId/memberships',
    );
    expect(transport.postedHeaders?['idempotency-key'], idempotencyKey);
    expect(transport.postedBody, contains('"role":"co_guardian"'));
    expect(membership.id, membershipId);
  });

  test('a role the contract does not allow never leaves the device', () async {
    final transport = FakeTransport(
      const FoundationGateHttpResponse(statusCode: 200, body: '{}'),
    );

    // primary_guardian is not invitable: the server refuses it, and sending it would be a
    // request that could only fail. The client refuses first, with the same failure the
    // server would name.
    await expectLater(
      () => clientFor(transport).invite(
        familyId: familyId,
        role: 'primary_guardian',
        targetSubject: 'invitee-subject',
        idempotencyKey: idempotencyKey,
        idToken: 'synthetic-token',
      ),
      throwsA(
        isA<FoundationGateApiException>().having(
          (error) => error.failure,
          'failure',
          FoundationGateApiFailure.invalidInput,
        ),
      ),
    );
    expect(transport.postedUri, isNull, reason: 'nothing may be sent for a refused role');
  });

  test('accept and revoke address one membership by id', () async {
    const acceptedBody =
        '{"membership":{"id":"$membershipId","role":"co_guardian","status":"active",'
        '"statusReasonCode":null,"version":2,"joinedAt":"2026-10-07T10:00:00.000Z",'
        '"statusChangedAt":"2026-10-07T10:00:00.000Z",'
        '"createdAt":"2026-10-07T09:00:00.000Z","isSelf":true}}';
    final acceptTransport = FakeTransport(
      const FoundationGateHttpResponse(statusCode: 200, body: '{}'),
      postResponse: const FoundationGateHttpResponse(statusCode: 200, body: acceptedBody),
    );
    final accepted = await clientFor(acceptTransport).accept(
      familyId: familyId,
      membershipId: membershipId,
      idempotencyKey: idempotencyKey,
      idToken: 'synthetic-token',
    );
    expect(
      acceptTransport.postedUri.toString(),
      'https://staging.example.test/v1/families/$familyId/memberships/$membershipId/accept',
    );
    expect(accepted.status, 'active');
    expect(accepted.isSelf, isTrue);
    expect(accepted.joinedAt, isNotNull);

    const removedBody =
        '{"membership":{"id":"$membershipId","role":"co_guardian","status":"removed",'
        '"statusReasonCode":"member_left","version":3,'
        '"joinedAt":"2026-10-07T10:00:00.000Z",'
        '"statusChangedAt":"2026-10-07T11:00:00.000Z",'
        '"createdAt":"2026-10-07T09:00:00.000Z","isSelf":false}}';
    final revokeTransport = FakeTransport(
      const FoundationGateHttpResponse(statusCode: 200, body: '{}'),
      postResponse: const FoundationGateHttpResponse(statusCode: 200, body: removedBody),
    );
    final removed = await clientFor(revokeTransport).revoke(
      familyId: familyId,
      membershipId: membershipId,
      reasonCode: 'member_left',
      idempotencyKey: idempotencyKey,
      idToken: 'synthetic-token',
    );
    expect(
      revokeTransport.postedUri.toString(),
      'https://staging.example.test/v1/families/$familyId/memberships/$membershipId/revoke',
    );
    expect(revokeTransport.postedBody, contains('member_left'));
    expect(removed.status, 'removed');
    expect(removed.statusReasonCode, 'member_left');
  });

  test('a status this client does not know drops the row instead of guessing', () async {
    final transport = FakeTransport(
      const FoundationGateHttpResponse(
        statusCode: 200,
        body: '{"memberships":[{"id":"$membershipId","role":"co_guardian",'
            '"status":"suspended","statusReasonCode":null,"version":1,'
            '"joinedAt":null,"statusChangedAt":null,'
            '"createdAt":"2026-10-07T09:00:00.000Z","isSelf":false}]}',
      ),
    );

    await expectLater(
      () => clientFor(transport).list(familyId: familyId, idToken: 'synthetic-token'),
      throwsA(
        isA<FoundationGateApiException>().having(
          (error) => error.failure,
          'failure',
          FoundationGateApiFailure.invalidResponse,
        ),
      ),
    );
  });

  test('every server refusal maps to a named failure, including 404', () async {
    Future<FoundationGateApiFailure> failureOf(
      Future<void> Function(FamilyMembershipApiClient client) call,
      int statusCode,
    ) async {
      final transport = FakeTransport(
        FoundationGateHttpResponse(statusCode: statusCode, body: '{}'),
        postResponse: FoundationGateHttpResponse(statusCode: statusCode, body: '{}'),
      );
      final client = clientFor(transport);
      try {
        await call(client);
        fail('the call was expected to fail');
      } on FoundationGateApiException catch (error) {
        return error.failure;
      }
    }

    // A denied read, a membership that no longer exists, and a retry that cannot succeed.
    // Three different failures, three different things a screen can say, none of them a
    // raw exception.
    expect(
      await failureOf(
        (client) => client.list(familyId: familyId, idToken: 'synthetic-token'),
        403,
      ),
      FoundationGateApiFailure.accessDenied,
    );
    expect(
      await failureOf(
        (client) => client.accept(
          familyId: familyId,
          membershipId: membershipId,
          idempotencyKey: idempotencyKey,
          idToken: 'synthetic-token',
        ),
        404,
      ),
      FoundationGateApiFailure.notFound,
    );
    expect(
      await failureOf(
        (client) => client.revoke(
          familyId: familyId,
          membershipId: membershipId,
          reasonCode: 'member_left',
          idempotencyKey: idempotencyKey,
          idToken: 'synthetic-token',
        ),
        409,
      ),
      FoundationGateApiFailure.conflict,
    );
  });
}
