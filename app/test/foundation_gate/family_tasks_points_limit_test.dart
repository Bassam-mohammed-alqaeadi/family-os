// S3 D4 — the client never sends a task that the server would refuse: points 1..200 (W7).
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/foundation_gate/family_tasks_api_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_configuration.dart';
import 'package:family_os/foundation_gate/foundation_gate_http.dart';

final class _NoWriteTransport implements FoundationGateHttpTransport {
  @override
  Future<FoundationGateHttpResponse> get(Uri uri, {required Map<String, String> headers}) =>
      throw StateError('a task creation is a write, not a read');

  @override
  Future<FoundationGateHttpResponse> post(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
  }) => throw StateError('an out-of-range task must never reach the network');

  @override
  Future<FoundationGateHttpResponse> patch(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
  }) => throw StateError('no patch here');

  @override
  Future<FoundationGateHttpResponse> put(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
  }) => throw StateError('no put here');
}

void main() {
  final api = FamilyTasksApiClient(
    configuration: FoundationGateConfiguration.fromStagingApiOrigin(
      Uri.parse('https://api.example.com'),
    ),
    transport: _NoWriteTransport(),
  );

  Future<void> create(int points) => api.createTask(
    familyId: '11111111-1111-4111-8111-111111111111',
    childId: '22222222-2222-4222-8222-222222222222',
    title: 'tidy',
    points: points,
    idempotencyKey: 'k',
    idToken: 'token',
  );

  test('a task that pays 0 is refused before any request', () async {
    await expectLater(create(0), throwsRangeError);
  });

  test('a task above the server ceiling of 200 is refused before any request', () async {
    await expectLater(create(201), throwsRangeError);
  });
}
