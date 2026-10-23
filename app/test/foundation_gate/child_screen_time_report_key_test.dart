// S3 measurement — the second report of a day.
//
// The server hashes the body of every idempotent request and refuses to reuse a key with a
// different body (`idempotency_key_reused`, 409). A handset's day grows while it is being
// lived, so the second report of the same day is *not* the first one: it carries more
// minutes. Sending it under the same key would be refused, and the newer measurement - the
// one that says the child has been on the phone since - would be thrown away.
//
// These tests pin both halves of that: a real repeat still replays, and a grown measurement
// still lands.
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/foundation_gate/child_screen_time_report_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_http.dart';

final class _ScriptedTransport implements ChildScreenTimeReportTransport {
  _ScriptedTransport(this.answers);

  final List<FoundationGateHttpResponse> answers;
  final List<String> keys = <String>[];
  final List<String> bodies = <String>[];

  @override
  Future<UsageSnapshot> snapshot() async => UsageSnapshot(
    permissionGranted: true,
    apps: <AppUsageSample>[
      const AppUsageSample(
        packageName: 'com.game.app',
        displayName: 'Game',
        categoryName: 'games',
        minutes: 40,
      ),
    ],
  );

  @override
  Future<bool> openUsageAccessSettings() async => true;

  @override
  Future<FoundationGateHttpResponse> postUsage({
    required String body,
    required String idempotencyKey,
  }) async {
    keys.add(idempotencyKey);
    bodies.add(body);
    final index = keys.length - 1;
    return index < answers.length ? answers[index] : answers.last;
  }
}

void main() {
  test('a grown measurement is not lost to the day key', () async {
    final transport = _ScriptedTransport(<FoundationGateHttpResponse>[
      const FoundationGateHttpResponse(
        statusCode: 409,
        body: '{"error":{"code":"idempotency_key_reused"}}',
      ),
      const FoundationGateHttpResponse(statusCode: 201, body: '{}'),
    ]);
    final client = ChildScreenTimeReportClient(
      transport: transport,
      clock: () => DateTime(2026, 10, 23, 17, 40),
    );

    final outcome = await client.report();

    expect(outcome.kind, ReportOutcomeKind.sent);
    expect(transport.keys.length, 2, reason: 'one refused key, one accepted');
    expect(
      transport.keys.first,
      'usage-2026-10-23',
      reason: 'the day key must stay the day key: a lost answer has to replay',
    );
    expect(
      transport.keys.last,
      isNot(transport.keys.first),
      reason: 'the same key with a different body is what the server refused',
    );
    expect(
      transport.bodies.first,
      transport.bodies.last,
      reason: 'the retry is the same measurement, not a re-measurement',
    );
    expect(transport.keys.last.length, lessThanOrEqualTo(128));
  });

  test('a conflict that is not about the key is reported, not retried', () async {
    final transport = _ScriptedTransport(<FoundationGateHttpResponse>[
      const FoundationGateHttpResponse(
        statusCode: 409,
        body: '{"error":{"code":"screen_time_no_cap"}}',
      ),
    ]);
    final client = ChildScreenTimeReportClient(transport: transport);

    final outcome = await client.report();

    expect(outcome.kind, ReportOutcomeKind.refused);
    expect(outcome.statusCode, 409);
    expect(transport.keys.length, 1, reason: 'asking twice cannot change a missing cap');
  });
}
