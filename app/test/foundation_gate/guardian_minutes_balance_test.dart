// S3 — the guardian's read of a child's minutes balance.
//
// Pinned here: the URL and verb (GET only: nothing on this path writes minutes), the wire
// answer becoming per-app minutes, the refusals mapping to a failure the screen can name, and
// the authority returning null on every non-answer so no screen shows a number this device made up.
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/features/n03_screen_time/guardian_minutes_balance_authority.dart';
import 'package:family_os/foundation_gate/child_minutes_balance_client.dart';
import 'package:family_os/foundation_gate/family_tasks_api_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_configuration.dart';
import 'package:family_os/foundation_gate/foundation_gate_http.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';

const _familyId = '11111111-1111-4111-8111-111111111111';
const _childId = '22222222-2222-4222-8222-222222222222';
const _balanceBody =
    '{"daily":0,"temporary":0,"free":0,"apps":[{"appId":"youtube","minutes":25}],"total":25,"asOf":"2026-10-15T10:00:00.000Z"}';

final class _Transport implements FoundationGateHttpTransport {
  _Transport(this.status, [this.body = _balanceBody]);

  final int status;
  final String body;
  final List<String> calls = <String>[];

  @override
  Future<FoundationGateHttpResponse> get(
    Uri uri, {
    required Map<String, String> headers,
  }) async {
    calls.add('GET ${uri.path}');
    return FoundationGateHttpResponse(statusCode: status, body: body);
  }

  @override
  Future<FoundationGateHttpResponse> post(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
  }) => throw StateError('the balance read must not write');

  @override
  Future<FoundationGateHttpResponse> patch(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
  }) => throw StateError('the balance read must not write');

  @override
  Future<FoundationGateHttpResponse> put(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
  }) => throw StateError('the balance read must not write');
}

FamilyTasksApiClient _api(_Transport transport) => FamilyTasksApiClient(
  configuration: FoundationGateConfiguration.fromStagingApiOrigin(
    Uri.parse('https://api.example.com'),
  ),
  transport: transport,
);

void main() {
  test('reads the guardian balance with GET on the family child path', () async {
    final transport = _Transport(200);
    final balance = await _api(transport).readMinutesBalance(
      familyId: _familyId,
      childId: _childId,
      idToken: 'token',
    );

    expect(transport.calls, ['GET /v1/families/$_familyId/children/$_childId/minutes/balance']);
    expect(balance.apps.single.appId, 'youtube');
    expect(balance.apps.single.minutes, 25);
  });

  test('refusals map to named failures, never to a number', () async {
    for (final entry in {
      401: FoundationGateApiFailure.unauthenticated,
      403: FoundationGateApiFailure.accessDenied,
      404: FoundationGateApiFailure.notFound,
      503: FoundationGateApiFailure.serviceUnavailable,
      418: FoundationGateApiFailure.invalidResponse,
    }.entries) {
      await expectLater(
        _api(_Transport(entry.key)).readMinutesBalance(
          familyId: _familyId,
          childId: _childId,
          idToken: 'token',
        ),
        throwsA(
          isA<FoundationGateApiException>().having((e) => e.failure, 'failure', entry.value),
        ),
        reason: 'status ${entry.key}',
      );
    }
  });

  test('the authority answers per app, and null on every non-answer', () async {
    GuardianMinutesBalanceAuthority authority(_Transport transport) =>
        GuardianMinutesBalanceAuthority(
          api: _api(transport),
          idToken: () async => 'token',
          familyId: () => _familyId,
        );

    expect(await authority(_Transport(200)).balanceByApp(_childId), {'youtube': 25});
    expect(await authority(_Transport(403)).balanceByApp(_childId), isNull);
    expect(await authority(_Transport(200)).balanceByApp('not-a-uuid'), isNull);

    final noFamily = GuardianMinutesBalanceAuthority(
      api: _api(_Transport(200)),
      idToken: () async => 'token',
      familyId: () => null,
    );
    expect(await noFamily.balanceByApp(_childId), isNull);
  });
}
