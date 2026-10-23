// S3 measurement — what a handset is allowed to say about a child's day.
//
// The transport is faked here on purpose: these tests are about the four decisions between
// a measurement and a report (access, honour, naming, one-key-per-day), and none of them
// needs a phone to be true.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/foundation_gate/child_screen_time_report_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_http.dart';

final class _FakeTransport implements ChildScreenTimeReportTransport {
  _FakeTransport({
    this.permissionGranted = true,
    List<AppUsageSample>? apps,
    this.statusCode = 201,
    this.openedSettings = true,
  }) : apps = apps ?? <AppUsageSample>[];

  final bool permissionGranted;
  final List<AppUsageSample> apps;
  final int statusCode;
  final bool openedSettings;

  String? sentBody;
  String? sentKey;
  int posts = 0;
  int settingsOpened = 0;

  @override
  Future<UsageSnapshot> snapshot() async =>
      UsageSnapshot(permissionGranted: permissionGranted, apps: apps);

  @override
  Future<bool> openUsageAccessSettings() async {
    settingsOpened++;
    return openedSettings;
  }

  @override
  Future<FoundationGateHttpResponse> postUsage({
    required String body,
    required String idempotencyKey,
  }) async {
    posts++;
    sentBody = body;
    sentKey = idempotencyKey;
    return FoundationGateHttpResponse(
      statusCode: statusCode,
      body: statusCode == 201 ? '{"ok":true}' : '{"error":"refused"}',
    );
  }
}

AppUsageSample _app(
  String packageName, {
  String? displayName,
  String categoryName = 'games',
  int minutes = 10,
}) {
  return AppUsageSample(
    packageName: packageName,
    displayName: displayName ?? packageName,
    categoryName: categoryName,
    minutes: minutes,
  );
}

void main() {
  test('without usage access nothing is sent', () async {
    final transport = _FakeTransport(
      permissionGranted: false,
      apps: <AppUsageSample>[_app('com.game.app', minutes: 40)],
    );
    final client = ChildScreenTimeReportClient(transport: transport);

    final outcome = await client.report();

    expect(outcome.kind, ReportOutcomeKind.permissionMissing);
    expect(outcome.needsUsageAccess, isTrue);
    expect(transport.posts, 0, reason: 'a phone that may not look may not report');
  });

  test('unknown categories are never sent as games', () async {
    final transport = _FakeTransport(
      apps: <AppUsageSample>[
        _app('com.quran.reader', categoryName: '', minutes: 30),
        _app('com.mystery.app', categoryName: 'entertainment', minutes: 25),
        _app('com.real.game', categoryName: 'games', minutes: 20),
        _app('com.school.app', categoryName: 'edu', minutes: 15),
      ],
    );
    final client = ChildScreenTimeReportClient(transport: transport);

    final outcome = await client.report();

    expect(outcome.kind, ReportOutcomeKind.sent);
    expect(outcome.appCount, 2);

    final body = jsonDecode(transport.sentBody!) as Map<String, Object?>;
    final apps = (body['apps']! as List).cast<Map<String, Object?>>();
    final sentIds = apps.map((app) => app['appId']).toList();

    expect(sentIds, <String>['com.real.game', 'com.school.app']);
    expect(
      sentIds.contains('com.quran.reader'),
      isFalse,
      reason: 'an app this build cannot name must not be sent at all',
    );
    for (final app in apps) {
      expect(
        kServerAppCategories.contains(app['category']),
        isTrue,
        reason: 'the server refuses the whole report for one unknown word',
      );
    }
  });

  test('a sent report uses one stable key per day', () async {
    final transport = _FakeTransport(
      apps: <AppUsageSample>[_app('com.game.app', minutes: 12)],
    );
    final client = ChildScreenTimeReportClient(
      transport: transport,
      clock: () => DateTime(2026, 10, 23, 8, 30),
    );

    await client.report();
    final firstKey = transport.sentKey;

    // A retry on the same day, at another hour, is the same request.
    final retry = ChildScreenTimeReportClient(
      transport: transport,
      clock: () => DateTime(2026, 10, 23, 21, 5),
    );
    await retry.report();

    expect(firstKey, 'usage-2026-10-23');
    expect(transport.sentKey, firstKey);
    expect(transport.posts, 2);

    // The next day is a different measurement and must be a different request.
    final tomorrow = ChildScreenTimeReportClient(
      transport: transport,
      clock: () => DateTime(2026, 10, 24, 0, 1),
    );
    await tomorrow.report();
    expect(transport.sentKey, 'usage-2026-10-24');
  });

  test('a refused report is reported as refused', () async {
    final transport = _FakeTransport(
      apps: <AppUsageSample>[_app('com.game.app', minutes: 5)],
      statusCode: 403,
    );
    final client = ChildScreenTimeReportClient(transport: transport);

    final outcome = await client.report();

    expect(outcome.kind, ReportOutcomeKind.refused);
    expect(outcome.statusCode, 403);
    expect(outcome.isSent, isFalse);
  });

  test('a day with nothing measured sends nothing', () async {
    final transport = _FakeTransport(apps: <AppUsageSample>[]);
    final client = ChildScreenTimeReportClient(transport: transport);

    final outcome = await client.report();

    expect(outcome.kind, ReportOutcomeKind.nothingMeasured);
    expect(transport.posts, 0);
  });

  test('the settings screen is offered without claiming it opened', () async {
    final refused = _FakeTransport(openedSettings: false);
    expect(
      await ChildScreenTimeReportClient(transport: refused)
          .openUsageAccessSettings(),
      isFalse,
    );

    final opened = _FakeTransport();
    expect(
      await ChildScreenTimeReportClient(transport: opened)
          .openUsageAccessSettings(),
      isTrue,
    );
    expect(opened.settingsOpened, 1);
  });
}
