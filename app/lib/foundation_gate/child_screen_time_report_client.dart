import 'dart:convert';

import 'package:flutter/services.dart';

import 'package:family_os/foundation_gate/foundation_gate_http.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';

/// The categories the server accepts, and the only four words this client will send.
///
/// `validation.js` → `APP_CATEGORY_VALUES` refuses any other string with a 400 **for the
/// whole report**, so an unknown category is dropped here: one unrecognised app must never
/// cost the family the other nineteen.
const Set<String> kServerAppCategories = <String>{'games', 'social', 'edu', 'tools'};

/// The server's own per-app ceiling (`MAX_USAGE_MINUTES_PER_APP`).
const int kMaxUsageMinutesPerApp = 1440;

/// The server's cap on rows per report (`MAX_APP_REPORTS`).
const int kMaxAppReports = 200;

/// One app as the handset measured it today.
final class AppUsageSample {
  const AppUsageSample({
    required this.packageName,
    required this.displayName,
    required this.categoryName,
    required this.minutes,
  });

  final String packageName;
  final String displayName;

  /// The server's word, decided on the device. Not Android's category name.
  final String categoryName;
  final int minutes;
}

/// What one look at the phone's own measurement returned.
final class UsageSnapshot {
  const UsageSnapshot({
    required this.permissionGranted,
    required this.apps,
    this.available = true,
  });

  /// False when the family has not granted "Usage access". It is reported rather than
  /// thrown: a missing setting is a thing to explain, not a fault to retry.
  final bool permissionGranted;

  /// False when the phone could not be asked at all — no native bridge in this build, or
  /// the bridge answered with a failure. It is a third answer on purpose: "we cannot see"
  /// is not "you did not allow us", and a screen must not tell a family to change a
  /// setting that was never the problem.
  final bool available;

  final List<AppUsageSample> apps;

  bool get isEmpty => apps.isEmpty;
}

/// The seam between Dart and the phone. No credential and no device id cross it.
abstract interface class ChildScreenTimeReportTransport {
  Future<UsageSnapshot> snapshot();

  /// Opens the system's own "Usage access" screen. Returns false when it could not.
  Future<bool> openUsageAccessSettings();

  Future<FoundationGateHttpResponse> postUsage({
    required String body,
    required String idempotencyKey,
  });
}

/// The production transport: the native bridge measures, authenticates and posts.
final class NativeChildScreenTimeReportTransport
    implements ChildScreenTimeReportTransport {
  const NativeChildScreenTimeReportTransport();

  static const MethodChannel _channel = MethodChannel(
    'com.familyos.family_os/native_child_telemetry',
  );

  @override
  Future<UsageSnapshot> snapshot() async {
    try {
      final answer = await _channel.invokeMapMethod<String, dynamic>(
        'usageStatsSnapshot',
      );
      final granted = answer?['permissionGranted'] == true;
      final raw = answer?['apps'];
      final apps = <AppUsageSample>[];
      if (raw is List) {
        for (final row in raw) {
          if (row is! Map) continue;
          final packageName = row['packageName'];
          final minutes = row['minutes'];
          if (packageName is! String || packageName.isEmpty) continue;
          if (minutes is! int || minutes <= 0) continue;
          final displayName = row['displayName'];
          final categoryName = row['categoryName'];
          apps.add(
            AppUsageSample(
              packageName: packageName,
              displayName:
                  displayName is String && displayName.trim().isNotEmpty
                  ? displayName.trim()
                  : packageName,
              categoryName: categoryName is String ? categoryName : '',
              minutes: minutes,
            ),
          );
        }
      }
      return UsageSnapshot(permissionGranted: granted, apps: apps);
    } on MissingPluginException {
      // A build without the native bridge was never asked anything. Saying "no access"
      // here would send a family to a settings screen that cannot help them.
      return const UsageSnapshot(
        permissionGranted: false,
        apps: <AppUsageSample>[],
        available: false,
      );
    } on PlatformException {
      return const UsageSnapshot(
        permissionGranted: false,
        apps: <AppUsageSample>[],
        available: false,
      );
    }
  }

  @override
  Future<bool> openUsageAccessSettings() async {
    try {
      final opened = await _channel.invokeMethod<bool>('openUsageAccessSettings');
      return opened == true;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<FoundationGateHttpResponse> postUsage({
    required String body,
    required String idempotencyKey,
  }) async {
    try {
      final answer = await _channel.invokeMapMethod<String, dynamic>(
        'screenTimeReportRequest',
        <String, Object?>{'body': body, 'idempotencyKey': idempotencyKey},
      );
      final statusCode = answer?['statusCode'];
      final responseBody = answer?['body'];
      if (statusCode is! int || responseBody is! String) {
        throw const FoundationGateApiException(
          FoundationGateApiFailure.invalidResponse,
        );
      }
      return FoundationGateHttpResponse(
        statusCode: statusCode,
        body: responseBody,
      );
    } on FoundationGateApiException {
      rethrow;
    } on MissingPluginException {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.networkUnavailable,
      );
    } on PlatformException catch (e) {
      throw FoundationGateApiException(_failureFor(e.code));
    }
  }

  /// A handset that is not paired must not look merely offline: the difference decides
  /// whether a family is told to check their network or their pairing.
  static FoundationGateApiFailure _failureFor(String code) => switch (code) {
    'device_screen_time_not_configured' ||
    'device_screen_time_invalid_request' =>
      FoundationGateApiFailure.unauthenticated,
    _ => FoundationGateApiFailure.networkUnavailable,
  };
}

/// What one attempt to report produced. Four answers, because there are four things that
/// can be true, and "it did not work" would hide which one.
enum ReportOutcomeKind {
  sent,
  unavailable,
  permissionMissing,
  nothingMeasured,
  refused,
}

final class ReportOutcome {
  const ReportOutcome._(
    this.kind, {
    this.appCount = 0,
    this.totalMinutes = 0,
    this.statusCode,
  });

  const ReportOutcome.sent({
    required int appCount,
    required int totalMinutes,
  }) : this._(ReportOutcomeKind.sent, appCount: appCount, totalMinutes: totalMinutes);

  const ReportOutcome.unavailable() : this._(ReportOutcomeKind.unavailable);

  const ReportOutcome.permissionMissing()
    : this._(ReportOutcomeKind.permissionMissing);

  const ReportOutcome.nothingMeasured()
    : this._(ReportOutcomeKind.nothingMeasured);

  const ReportOutcome.refused(int statusCode)
    : this._(ReportOutcomeKind.refused, statusCode: statusCode);

  final ReportOutcomeKind kind;
  final int appCount;
  final int totalMinutes;
  final int? statusCode;

  bool get isSent => kind == ReportOutcomeKind.sent;
  bool get needsUsageAccess => kind == ReportOutcomeKind.permissionMissing;
  bool get isUnavailable => kind == ReportOutcomeKind.unavailable;
}

/// Reports what the phone measured, once a day, in the server's own words.
///
/// The order of the checks is the design: access first (nothing is measured without it),
/// then the rows (nothing is sent when nothing was measured), then the report. Each step
/// can end the attempt with a reason a screen can act on.
final class ChildScreenTimeReportClient {
  ChildScreenTimeReportClient({
    required ChildScreenTimeReportTransport transport,
    DateTime Function()? clock,
  }) : _transport = transport,
       _clock = clock ?? DateTime.now;

  final ChildScreenTimeReportTransport _transport;
  final DateTime Function() _clock;

  Future<ReportOutcome> report() async {
    final snapshot = await _transport.snapshot();
    if (!snapshot.available) return const ReportOutcome.unavailable();
    if (!snapshot.permissionGranted) {
      return const ReportOutcome.permissionMissing();
    }

    final rows = <(AppUsageSample, String)>[];
    for (final app in snapshot.apps) {
      final category = _serverCategory(app.categoryName);
      if (category == null) continue;
      if (app.minutes <= 0 || app.minutes > kMaxUsageMinutesPerApp) continue;
      rows.add((app, category));
    }
    if (rows.isEmpty) return const ReportOutcome.nothingMeasured();

    // The snapshot arrives sorted by minutes descending, so a handset with more apps than
    // the server accepts reports the ones that cost the most, not the alphabetically first.
    final kept = rows.length > kMaxAppReports ? rows.sublist(0, kMaxAppReports) : rows;
    final usage = <Map<String, Object>>[];
    final apps = <Map<String, Object>>[];
    var total = 0;
    for (final (app, category) in kept) {
      usage.add(<String, Object>{
        'appId': app.packageName,
        'usedMinutes': app.minutes,
      });
      apps.add(<String, Object>{
        'appId': app.packageName,
        'displayName': app.displayName,
        'category': category,
      });
      total += app.minutes;
    }

    final response = await _transport.postUsage(
      body: jsonEncode(<String, Object>{'usage': usage, 'apps': apps}),
      idempotencyKey: keyFor(_clock()),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      return ReportOutcome.sent(appCount: kept.length, totalMinutes: total);
    }
    return ReportOutcome.refused(response.statusCode);
  }

  /// Opens the system settings screen so a guardian can grant usage access.
  Future<bool> openUsageAccessSettings() => _transport.openUsageAccessSettings();

  /// One key per handset per day.
  ///
  /// The same day must be the same request, or a flaky network turns one measurement into
  /// several rows. The date is the device's own, because the key only has to be stable on
  /// this handset; which day the report *belongs to* is the server's decision.
  static String keyFor(DateTime at) {
    final month = at.month.toString().padLeft(2, '0');
    final day = at.day.toString().padLeft(2, '0');
    return 'usage-${at.year}-$month-$day';
  }

  /// The server's word for a category, or null when this build cannot name it.
  static String? _serverCategory(String raw) {
    final value = raw.trim().toLowerCase();
    return kServerAppCategories.contains(value) ? value : null;
  }
}

/// The production reporter: the paired handset's own measurement, through the native bridge.
ChildScreenTimeReportClient childScreenTimeReport() => ChildScreenTimeReportClient(
  transport: const NativeChildScreenTimeReportTransport(),
);
