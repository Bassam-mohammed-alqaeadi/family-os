import 'dart:convert';

import 'package:family_os/core/runtime/family_child_context_source.dart';
import 'package:family_os/foundation_gate/child_context_api_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_configuration.dart';
import 'package:family_os/foundation_gate/foundation_gate_http.dart';
import 'package:flutter_test/flutter_test.dart';

const familyId = '6dbb6760-f609-4f3e-a29f-4c209dc1d53b';
const childId = '4a3846da-8f5f-4f2b-b7ea-8a0afcd989fb';

void main() {
  test('parses exact context and sends bearer only to the validated URI', () async {
    final transport = _Transport(
      response: FoundationGateHttpResponse(
        statusCode: 200,
        body: jsonEncode(_validBody()),
      ),
    );
    final client = _client(transport);

    final context = await client.get(
      familyId: familyId,
      childId: childId,
      idToken: 'secret-token',
    );

    expect(
      transport.uri,
      Uri.parse(
        'https://api.example.test/v1/families/$familyId/children/$childId/context',
      ),
    );
    expect(transport.headers?['authorization'], 'Bearer secret-token');
    expect(context.childId.value, childId);
    expect(context.displayName, 'Amani');
    expect(context.deviceState, FamilyChildDeviceSetupState.notLinked);
    expect(context.deviceCount, 0);
    expect(
      context.permissionSnapshot.allows(
        FamilyChildPermissionScope.createDevicePairing,
        at: DateTime.parse('2026-10-07T09:01:00Z'),
      ),
      isTrue,
    );
  });

  test(
    'tolerates a bounded server clock lead without extending local authority',
    () async {
      final client = _client(
        _Transport(
          response: FoundationGateHttpResponse(
            statusCode: 200,
            body: jsonEncode(
              _validBody(
                observedAt: '2026-10-07T09:03:00Z',
                expiresAt: '2026-10-07T09:08:00Z',
              ),
            ),
          ),
        ),
      );

      final context = await client.get(
        familyId: familyId,
        childId: childId,
        idToken: 'token',
      );

      expect(
        context.permissionSnapshot.expiresAt,
        DateTime.parse('2026-10-07T09:08:00Z'),
      );
      expect(
        context.permissionSnapshot.presentationExpiresAt,
        DateTime.parse('2026-10-07T09:06:00Z'),
      );
      expect(
        context.permissionSnapshot.allows(
          FamilyChildPermissionScope.read,
          at: DateTime.parse('2026-10-07T09:05:59Z'),
        ),
        isTrue,
      );
      expect(
        context.permissionSnapshot.allows(
          FamilyChildPermissionScope.read,
          at: DateTime.parse('2026-10-07T09:06:00Z'),
        ),
        isFalse,
      );
    },
  );

  test('rejects a server clock lead beyond the bounded tolerance', () async {
    final client = _client(
      _Transport(
        response: FoundationGateHttpResponse(
          statusCode: 200,
          body: jsonEncode(
            _validBody(
              observedAt: '2026-10-07T09:31:01Z',
              expiresAt: '2026-10-07T09:36:01Z',
            ),
          ),
        ),
      ),
    );

    await expectLater(
      client.get(familyId: familyId, childId: childId, idToken: 'token'),
      throwsA(
        isA<FamilyChildContextApiException>().having(
          (error) => error.failure,
          'failure',
          FamilyChildContextFailure.invalidResponse,
        ),
      ),
    );
  });

  test('maps authorization, lifecycle and availability statuses exactly', () async {
    for (final entry in <int, FamilyChildContextFailure>{
      401: FamilyChildContextFailure.sessionInvalid,
      403: FamilyChildContextFailure.accessDenied,
      404: FamilyChildContextFailure.notFound,
      429: FamilyChildContextFailure.serviceUnavailable,
      503: FamilyChildContextFailure.serviceUnavailable,
      500: FamilyChildContextFailure.invalidResponse,
    }.entries) {
      final client = _client(
        _Transport(
          response: FoundationGateHttpResponse(
            statusCode: entry.key,
            body: entry.key == 404
                ? '{"error":{"code":"family_child_not_found","message":"Not found"}}'
                : '{}',
          ),
        ),
      );
      await expectLater(
        client.get(
          familyId: familyId,
          childId: childId,
          idToken: 'token',
        ),
        throwsA(
          isA<FamilyChildContextApiException>().having(
            (error) => error.failure,
            'failure',
            entry.value,
          ),
        ),
      );
    }
  });

  test('does not misreport an API route miss as a missing child', () async {
    final client = _client(
      _Transport(
        response: const FoundationGateHttpResponse(
          statusCode: 404,
          body:
              '{"error":{"code":"route_not_found","message":"Route was not found."}}',
        ),
      ),
    );

    await expectLater(
      client.get(familyId: familyId, childId: childId, idToken: 'token'),
      throwsA(
        isA<FamilyChildContextApiException>().having(
          (error) => error.failure,
          'failure',
          FamilyChildContextFailure.invalidResponse,
        ),
      ),
    );
  });

  test('fails closed on unknown fields, mismatched ids and stale snapshots', () async {
    final invalidBodies = <Map<String, Object?>>[
      {..._validBody(), 'batteryLevel': 92},
      _validBody(childIdValue: '11111111-1111-4111-8111-111111111111'),
      _validBody(expiresAt: '2026-10-07T09:04:59Z'),
      _validBody(observedAt: '2026-10-07T08:50:00Z', expiresAt: '2026-10-07T08:55:00Z'),
      _validBody(deviceState: 'linked', deviceCount: 0),
    ];

    for (final body in invalidBodies) {
      final client = _client(
        _Transport(
          response: FoundationGateHttpResponse(
            statusCode: 200,
            body: jsonEncode(body),
          ),
        ),
      );
      await expectLater(
        client.get(
          familyId: familyId,
          childId: childId,
          idToken: 'token',
        ),
        throwsA(
          isA<FamilyChildContextApiException>().having(
            (error) => error.failure,
            'failure',
            FamilyChildContextFailure.invalidResponse,
          ),
        ),
      );
    }
  });

  test('rejects co-guardian pairing scope and malformed local identifiers before I/O', () async {
    final body = _validBody();
    final permission = Map<String, Object?>.from(
      body['permissionSnapshot']! as Map,
    );
    permission['role'] = 'co_guardian';
    body['permissionSnapshot'] = permission;
    final transport = _Transport(
      response: FoundationGateHttpResponse(
        statusCode: 200,
        body: jsonEncode(body),
      ),
    );
    final client = _client(transport);

    await expectLater(
      client.get(familyId: familyId, childId: childId, idToken: 'token'),
      throwsA(isA<FamilyChildContextApiException>()),
    );
    await expectLater(
      client.get(familyId: familyId, childId: 'not-a-uuid', idToken: 'token'),
      throwsA(isA<FamilyChildContextApiException>()),
    );
  });
}

ChildContextApiClient _client(_Transport transport) => ChildContextApiClient(
  configuration: FoundationGateConfiguration.fromStagingApiOrigin(
    Uri.parse('https://api.example.test'),
  ),
  transport: transport,
  clock: () => DateTime.parse('2026-10-07T09:01:00Z'),
);

Map<String, Object?> _validBody({
  String childIdValue = childId,
  String observedAt = '2026-10-07T09:00:00Z',
  String expiresAt = '2026-10-07T09:05:00Z',
  String deviceState = 'not_linked',
  int deviceCount = 0,
}) => {
  'child': {
    'id': childIdValue,
    'displayName': 'Amani',
    'ageYears': 8,
    'avatarEmoji': '🦁',
    'themeColor': 'purple',
    'version': 2,
    'createdAt': '2026-10-01T09:00:00Z',
    'updatedAt': '2026-10-06T09:00:00Z',
  },
  'setup': {
    'deviceState': deviceState,
    'deviceCount': deviceCount,
    'observedAt': observedAt,
  },
  'permissionSnapshot': {
    'policyVersion': 4,
    'role': 'primary_guardian',
    'scopes': [
      FamilyChildPermissionScope.read,
      FamilyChildPermissionScope.createDevicePairing,
    ],
    'observedAt': observedAt,
    'expiresAt': expiresAt,
  },
};

final class _Transport implements FoundationGateHttpTransport {
  _Transport({required this.response});

  final FoundationGateHttpResponse response;
  Uri? uri;
  Map<String, String>? headers;

  @override
  Future<FoundationGateHttpResponse> get(
    Uri uri, {
    required Map<String, String> headers,
  }) async {
    this.uri = uri;
    this.headers = headers;
    return response;
  }

  @override
  Future<FoundationGateHttpResponse> post(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
  }) => throw UnimplementedError();
}
