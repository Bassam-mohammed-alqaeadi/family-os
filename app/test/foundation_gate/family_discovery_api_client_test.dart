import 'package:family_os/foundation_gate/family_discovery_api_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_configuration.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'foundation_gate_test_fakes.dart';

void main() {
  FamilyDiscoveryApiClient clientFor(FakeTransport transport) {
    return FamilyDiscoveryApiClient(
      configuration: FoundationGateConfiguration.fromStagingApiOrigin(
        Uri.parse('https://staging.example.test'),
      ),
      transport: transport,
    );
  }

  test('family discovery requests only the approved endpoint and parses minimal families', () async {
    final transport = FakeTransport(
      const FoundationGateHttpResponse(
        statusCode: 200,
        body: '{"families":[{"id":"family-a","displayName":"Synthetic family","role":"primary_guardian"}]}',
      ),
    );

    final result = await clientFor(transport).discover(idToken: 'synthetic-token');

    expect(transport.requestedUri.toString(), 'https://staging.example.test/v1/me/families');
    expect(transport.requestedHeaders!.keys, containsAll(['accept', 'authorization']));
    expect(result, hasLength(1));
    expect(result.single.displayName, 'Synthetic family');
    expect(result.single.role, 'primary_guardian');
  });

  test('family discovery maps server truth without exposing response detail', () async {
    for (final entry in <int, FoundationGateApiFailure>{
      401: FoundationGateApiFailure.unauthenticated,
      403: FoundationGateApiFailure.accessDenied,
      503: FoundationGateApiFailure.serviceUnavailable,
      500: FoundationGateApiFailure.invalidResponse,
    }.entries) {
      final transport = FakeTransport(FoundationGateHttpResponse(statusCode: entry.key, body: 'raw-body'));
      await expectLater(
        clientFor(transport).discover(idToken: 'synthetic-token'),
        throwsA(isA<FoundationGateApiException>().having((error) => error.failure, 'failure', entry.value)),
      );
    }
  });

  test('family discovery rejects oversized or non-minimal payloads', () async {
    final extraField = FakeTransport(
      const FoundationGateHttpResponse(
        statusCode: 200,
        body: '{"families":[{"id":"family-a","displayName":"Synthetic family","role":"primary_guardian","subject":"not-allowed"}]}',
      ),
    );

    await expectLater(
      clientFor(extraField).discover(idToken: 'synthetic-token'),
      throwsA(isA<FoundationGateApiException>().having(
        (error) => error.failure,
        'failure',
        FoundationGateApiFailure.invalidResponse,
      )),
    );
  });
}
