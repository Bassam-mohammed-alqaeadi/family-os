import 'package:family_os/foundation_gate/family_discovery_api_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_configuration.dart';
import 'package:family_os/foundation_gate/foundation_gate_http.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'foundation_gate_test_fakes.dart';

const familyId = '11111111-1111-4111-8111-111111111111';

void main() {
  FamilyDiscoveryApiClient clientFor(FakeTransport transport) {
    return FamilyDiscoveryApiClient(
      configuration: FoundationGateConfiguration.fromStagingApiOrigin(
        Uri.parse('https://staging.example.test'),
      ),
      transport: transport,
    );
  }

  test('family discovery uses the fixed server-derived endpoint and minimal projection', () async {
    final transport = FakeTransport(
      const FoundationGateHttpResponse(
        statusCode: 200,
        body: '{"families":[{"id":"$familyId","displayName":"Synthetic family","role":"primary_guardian"}]}',
      ),
    );

    final result = await clientFor(transport).discover(idToken: 'synthetic-token');

    expect(transport.requestedUri.toString(), 'https://staging.example.test/v1/me/families');
    expect(transport.requestedHeaders, {'accept': 'application/json', 'authorization': 'Bearer synthetic-token'});
    expect(result, hasLength(1));
    expect(result.single.id, familyId);
    expect(result.single.role, 'primary_guardian');
  });

  test('family discovery maps server truth without exposing response detail', () async {
    for (final entry in <int, FoundationGateApiFailure>{
      401: FoundationGateApiFailure.unauthenticated,
      403: FoundationGateApiFailure.accessDenied,
      429: FoundationGateApiFailure.serviceUnavailable,
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

  test('family discovery rejects non-minimal or unsafe family payloads', () async {
    for (final body in [
      '{"families":[{"id":"$familyId","displayName":"Synthetic family","role":"primary_guardian","subject":"not-allowed"}]}',
      '{"families":[{"id":"not-a-uuid","displayName":"Synthetic family","role":"primary_guardian"}]}',
    ]) {
      await expectLater(
        clientFor(FakeTransport(FoundationGateHttpResponse(statusCode: 200, body: body))).discover(
          idToken: 'synthetic-token',
        ),
        throwsA(isA<FoundationGateApiException>().having(
          (error) => error.failure,
          'failure',
          FoundationGateApiFailure.invalidResponse,
        )),
      );
    }
  });
}
