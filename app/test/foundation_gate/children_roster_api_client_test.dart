import 'package:family_os/foundation_gate/children_roster_api_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_configuration.dart';
import 'package:family_os/foundation_gate/foundation_gate_http.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'foundation_gate_test_fakes.dart';

const familyId = '11111111-1111-4111-8111-111111111111';
const childId = '22222222-2222-4222-8222-222222222222';
const rosterBody =
    '{"children":[{"id":"$childId","displayName":"Synthetic child","ageYears":8,"avatarEmoji":"🧒","themeColor":"purple","version":1,"createdAt":"2026-10-03T10:00:00.000Z","updatedAt":"2026-10-03T10:00:00.000Z"}]}';
const createdChildBody =
    '{"child":{"id":"$childId","displayName":"Synthetic child","ageYears":8,"avatarEmoji":"🧒","themeColor":"purple","version":1,"createdAt":"2026-10-03T10:00:00.000Z","updatedAt":"2026-10-03T10:00:00.000Z"}}';
const idempotencyKey = '33333333-3333-4333-8333-333333333333';

void main() {
  ChildrenRosterApiClient clientFor(FakeTransport transport) {
    return ChildrenRosterApiClient(
      configuration: FoundationGateConfiguration.fromStagingApiOrigin(
        Uri.parse('https://staging.example.test'),
      ),
      transport: transport,
    );
  }

  test(
    'roster read uses only the selected server family path and transient authorization header',
    () async {
      final transport = FakeTransport(
        const FoundationGateHttpResponse(statusCode: 200, body: rosterBody),
      );

      final result = await clientFor(
        transport,
      ).list(familyId: familyId, idToken: 'synthetic-token');

      expect(
        transport.requestedUri.toString(),
        'https://staging.example.test/v1/families/$familyId/children',
      );
      expect(transport.requestedHeaders, {
        'accept': 'application/json',
        'authorization': 'Bearer synthetic-token',
      });
      expect(result, hasLength(1));
      expect(result.single.id, childId);
      expect(result.single.displayName, 'Synthetic child');
      expect(result.single.ageYears, 8);
    },
  );

  test(
    'child creation sends the narrow body and an idempotency key without retaining a token',
    () async {
      final transport = FakeTransport(
        const FoundationGateHttpResponse(
          statusCode: 201,
          body: createdChildBody,
        ),
      );

      final child = await clientFor(transport).create(
        familyId: familyId,
        idToken: 'synthetic-token',
        idempotencyKey: idempotencyKey,
        displayName: '  Synthetic child  ',
        ageYears: 8,
        avatarEmoji: '🧒',
        themeColor: 'purple',
      );

      expect(
        transport.postedUri.toString(),
        'https://staging.example.test/v1/families/$familyId/children',
      );
      expect(transport.postedHeaders, {
        'accept': 'application/json',
        'content-type': 'application/json',
        'authorization': 'Bearer synthetic-token',
        'idempotency-key': idempotencyKey,
      });
      expect(
        transport.postedBody,
        '{"displayName":"Synthetic child","ageYears":8,"avatarEmoji":"🧒","themeColor":"purple"}',
      );
      expect(child.id, childId);
      expect(child.displayName, 'Synthetic child');
      expect(child.ageYears, 8);
    },
  );

  test(
    'roster client maps authorization and availability failures without parsing response bodies',
    () async {
      for (final entry in <int, FoundationGateApiFailure>{
        401: FoundationGateApiFailure.unauthenticated,
        403: FoundationGateApiFailure.accessDenied,
        429: FoundationGateApiFailure.serviceUnavailable,
        503: FoundationGateApiFailure.serviceUnavailable,
        500: FoundationGateApiFailure.invalidResponse,
      }.entries) {
        await expectLater(
          clientFor(
            FakeTransport(
              FoundationGateHttpResponse(
                statusCode: entry.key,
                body: 'raw-body',
              ),
            ),
          ).list(familyId: familyId, idToken: 'synthetic-token'),
          throwsA(
            isA<FoundationGateApiException>().having(
              (error) => error.failure,
              'failure',
              entry.value,
            ),
          ),
        );
      }
    },
  );

  test(
    'child creation maps server rejection classes without parsing error bodies',
    () async {
      for (final entry in <int, FoundationGateApiFailure>{
        400: FoundationGateApiFailure.invalidInput,
        401: FoundationGateApiFailure.unauthenticated,
        403: FoundationGateApiFailure.accessDenied,
        409: FoundationGateApiFailure.conflict,
        429: FoundationGateApiFailure.serviceUnavailable,
        503: FoundationGateApiFailure.serviceUnavailable,
        500: FoundationGateApiFailure.invalidResponse,
      }.entries) {
        await expectLater(
          clientFor(
            FakeTransport(
              FoundationGateHttpResponse(
                statusCode: entry.key,
                body: 'raw-body',
              ),
            ),
          ).create(
            familyId: familyId,
            idToken: 'synthetic-token',
            idempotencyKey: idempotencyKey,
            displayName: 'Synthetic child',
            ageYears: 8,
            avatarEmoji: '🧒',
            themeColor: 'purple',
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
    },
  );

  test(
    'child creation rejects invalid local input before a request is sent',
    () async {
      final transport = FakeTransport(
        const FoundationGateHttpResponse(
          statusCode: 201,
          body: createdChildBody,
        ),
      );

      await expectLater(
        clientFor(transport).create(
          familyId: familyId,
          idToken: 'synthetic-token',
          idempotencyKey: idempotencyKey,
          displayName: '   ',
          ageYears: 8,
          avatarEmoji: '🧒',
          themeColor: 'purple',
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
    'roster client rejects an injected family path and malformed server data before roster UI can exist',
    () async {
      final transport = FakeTransport(
        const FoundationGateHttpResponse(statusCode: 200, body: rosterBody),
      );
      await expectLater(
        clientFor(
          transport,
        ).list(familyId: '$familyId?another=value', idToken: 'synthetic-token'),
        throwsA(isA<FoundationGateApiException>()),
      );
      expect(transport.requestedUri, isNull);

      await expectLater(
        clientFor(
          FakeTransport(
            const FoundationGateHttpResponse(
              statusCode: 200,
              body:
                  '{"children":[{"id":"$childId","displayName":"Synthetic child","ageYears":8,"avatarEmoji":"🧒","themeColor":"purple","version":1,"createdAt":"bad","updatedAt":"2026-10-03T10:00:00.000Z","deviceState":"invented"}]}',
            ),
          ),
        ).list(familyId: familyId, idToken: 'synthetic-token'),
        throwsA(
          isA<FoundationGateApiException>().having(
            (error) => error.failure,
            'failure',
            FoundationGateApiFailure.invalidResponse,
          ),
        ),
      );

      await expectLater(
        clientFor(
          FakeTransport(
            const FoundationGateHttpResponse(
              statusCode: 201,
              body:
                  '{"child":{"id":"$childId","displayName":"Synthetic child","ageYears":8,"avatarEmoji":"🧒","themeColor":"purple","version":1,"createdAt":"bad","updatedAt":"2026-10-03T10:00:00.000Z"}}',
            ),
          ),
        ).create(
          familyId: familyId,
          idToken: 'synthetic-token',
          idempotencyKey: idempotencyKey,
          displayName: 'Synthetic child',
          ageYears: 8,
          avatarEmoji: '🧒',
          themeColor: 'purple',
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
