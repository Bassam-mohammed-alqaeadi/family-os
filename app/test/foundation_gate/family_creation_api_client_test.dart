import 'package:family_os/foundation_gate/family_creation_api_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_configuration.dart';
import 'package:family_os/foundation_gate/foundation_gate_http.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'foundation_gate_test_fakes.dart';

const _familyId = '11111111-1111-4111-8111-111111111111';
const _idempotencyKey = '33333333-3333-4333-8333-333333333333';
const _createdBody =
    '{"family":{"id":"$_familyId","displayName":"Synthetic family"}}';

void main() {
  FamilyCreationApiClient clientFor(FakeTransport transport) {
    return FamilyCreationApiClient(
      configuration: FoundationGateConfiguration.fromStagingApiOrigin(
        Uri.parse('https://staging.example.test'),
      ),
      transport: transport,
    );
  }

  test(
    'family creation sends the narrow displayName body with bearer and idempotency key',
    () async {
      final transport = FakeTransport(
        const FoundationGateHttpResponse(statusCode: 201, body: _createdBody),
      );

      final created = await clientFor(transport).create(
        idToken: 'synthetic-token',
        idempotencyKey: _idempotencyKey,
        displayName: '  Synthetic family  ',
      );

      expect(
        transport.postedUri.toString(),
        'https://staging.example.test/v1/families',
      );
      expect(transport.postedHeaders, {
        'accept': 'application/json',
        'content-type': 'application/json',
        'authorization': 'Bearer synthetic-token',
        'idempotency-key': _idempotencyKey,
      });
      expect(transport.postedBody, '{"displayName":"Synthetic family"}');
      expect(created.id, _familyId);
      expect(created.displayName, 'Synthetic family');
    },
  );

  test(
    'family creation rejects invalid local input before a request is sent',
    () async {
      final transport = FakeTransport(
        const FoundationGateHttpResponse(statusCode: 201, body: _createdBody),
      );

      await expectLater(
        clientFor(transport).create(
          idToken: 'synthetic-token',
          idempotencyKey: _idempotencyKey,
          displayName: '   ',
        ),
        throwsA(
          isA<FoundationGateApiException>().having(
            (error) => error.failure,
            'failure',
            FoundationGateApiFailure.invalidInput,
          ),
        ),
      );
      expect(transport.postedUri, isNull);
    },
  );

  test(
    'family creation maps authorization, conflict, unavailable and malformed states',
    () async {
      final cases = {
        400: FoundationGateApiFailure.invalidInput,
        401: FoundationGateApiFailure.unauthenticated,
        403: FoundationGateApiFailure.accessDenied,
        409: FoundationGateApiFailure.conflict,
        429: FoundationGateApiFailure.serviceUnavailable,
        503: FoundationGateApiFailure.serviceUnavailable,
        500: FoundationGateApiFailure.invalidResponse,
      };
      for (final entry in cases.entries) {
        final transport = FakeTransport(
          FoundationGateHttpResponse(statusCode: entry.key, body: '{}'),
        );
        await expectLater(
          clientFor(transport).create(
            idToken: 'synthetic-token',
            idempotencyKey: _idempotencyKey,
            displayName: 'Synthetic family',
          ),
          throwsA(
            isA<FoundationGateApiException>().having(
              (error) => error.failure,
              'failure',
              entry.value,
            ),
          ),
        );
      }

      await expectLater(
        clientFor(
          FakeTransport(
            const FoundationGateHttpResponse(
              statusCode: 201,
              body: '{"family":{"id":"not-a-uuid","displayName":"x"}}',
            ),
          ),
        ).create(
          idToken: 'synthetic-token',
          idempotencyKey: _idempotencyKey,
          displayName: 'Synthetic family',
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
}
