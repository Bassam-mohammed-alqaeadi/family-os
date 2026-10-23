import 'dart:convert';

import 'package:flutter/services.dart';

import 'package:family_os/foundation_gate/foundation_gate_http.dart';

/// Where a child's question ended up.
///
/// Six answers because six things can be true, and \"it did not work\" would hide the one
/// that matters to the child: whether a parent will see the question at all.
enum TimeAskOutcome {
  /// The server filed the question. The guardian's next read finds it.
  sent,

  /// The server says a question is already open — which is the same good news, reached by
  /// a different road: a tap that arrived twice must not look like a failure.
  alreadyWaiting,

  /// There is no daily cap to extend, so there is nothing to ask for. The server refuses
  /// this rather than filing a question that could only ever be answered with a number the
  /// system does not enforce.
  noCap,

  /// This build has no native bridge: the device is not the child's paired handset, so it
  /// has no credential to ask with. Nothing was sent and nothing was wrong with the family.
  notPaired,

  /// The handset is paired but the server did not answer. The question is kept locally and
  /// must be offered again.
  offline,

  /// The server answered with a refusal this build cannot name.
  refused,
}

extension TimeAskOutcomeCopy on TimeAskOutcome {
  /// True when a guardian will see the question. This is the only thing a toast may claim.
  bool get reachedGuardian =>
      this == TimeAskOutcome.sent || this == TimeAskOutcome.alreadyWaiting;
}

/// The seam between Dart and the paired handset. The credential never crosses it.
abstract interface class ChildTimeRequestTransport {
  Future<FoundationGateHttpResponse> postAsk({
    required String body,
    required String idempotencyKey,
  });
}

/// Raised when this build has no bridge at all — a plain Dart run, or a device that was
/// never paired. It is a state to explain, not a fault to retry.
final class ChildTimeRequestNotPaired implements Exception {
  const ChildTimeRequestNotPaired();
}

/// The production transport: the same channel the day's measurement uses.
///
/// It reuses `screenTimeReportRequest` on purpose. The server accepts a question inside the
/// report body (`{usage, apps, request}`), and that route authenticates with the device
/// credential, which is exactly the proof of \"which child is asking\". A second channel
/// method would be a second way to spend the same credential.
final class NativeChildTimeRequestTransport implements ChildTimeRequestTransport {
  const NativeChildTimeRequestTransport();

  static const MethodChannel _channel = MethodChannel(
    'com.familyos.family_os/native_child_telemetry',
  );

  @override
  Future<FoundationGateHttpResponse> postAsk({
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
        throw const ChildTimeRequestNotPaired();
      }
      return FoundationGateHttpResponse(
        statusCode: statusCode,
        body: responseBody,
      );
    } on MissingPluginException {
      throw const ChildTimeRequestNotPaired();
    } on PlatformException {
      throw const ChildTimeRequestNotPaired();
    }
  }
}

/// Asks the family's server for extra minutes, once, and says what happened.
///
/// The body is deliberately tiny: `{request: {requestedMinutes, reasonCode}}`. Validation
/// allows `usage` and `apps` to be absent (`deviceScreenTimeReportInput`), so a child can
/// ask for time on a handset whose measurement is not available - the question is not a
/// consequence of the measurement.
final class ChildTimeRequestClient {
  ChildTimeRequestClient({
    required ChildTimeRequestTransport transport,
    DateTime Function()? clock,
  }) : _transport = transport,
       _clock = clock ?? DateTime.now;

  final ChildTimeRequestTransport _transport;
  final DateTime Function() _clock;

  Future<TimeAskOutcome> ask({
    required int requestedMinutes,
    String? reasonCode,
  }) async {
    if (requestedMinutes <= 0) return TimeAskOutcome.refused;
    final body = jsonEncode(<String, Object>{
      'request': <String, Object>{
        'requestedMinutes': requestedMinutes,
        if (reasonCode != null && reasonCode.trim().isNotEmpty)
          'reasonCode': _clip(reasonCode.trim()),
      },
    });

    // One key per tap. A question is not a day and must not replay: asking for 20 minutes
    // and then for 30 are two different questions, even one second apart.
    final key = 'ask-${_clock().microsecondsSinceEpoch}';
    try {
      var response = await _transport.postAsk(body: body, idempotencyKey: key);
      // The same tap retried after a dropped answer is the same question under the same key.
      // A *new* tap is a new key, so the only conflict this can produce is the server's own
      // "a question is already open", which is an answer.
      if (response.statusCode == 409 && _code(response.body) == 'idempotency_key_reused') {
        response = await _transport.postAsk(
          body: body,
          idempotencyKey: '$key-${_clock().microsecondsSinceEpoch}',
        );
      }
      return _outcomeOf(response);
    } on ChildTimeRequestNotPaired {
      return TimeAskOutcome.notPaired;
    } on Object {
      return TimeAskOutcome.offline;
    }
  }

  TimeAskOutcome _outcomeOf(FoundationGateHttpResponse response) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      return TimeAskOutcome.sent;
    }
    if (response.statusCode == 409) {
      return switch (_code(response.body)) {
        'time_request_pending' => TimeAskOutcome.alreadyWaiting,
        'screen_time_no_cap' => TimeAskOutcome.noCap,
        _ => TimeAskOutcome.refused,
      };
    }
    if (response.statusCode == 401 || response.statusCode == 403) {
      // The credential was not accepted: this handset cannot ask as this child. Saying
      // "offline" would send a family to check a router.
      return TimeAskOutcome.notPaired;
    }
    if (response.statusCode >= 500) return TimeAskOutcome.offline;
    return TimeAskOutcome.refused;
  }

  /// The server's error code, from either shape it uses: `{"error": {"code": ...}}` or
  /// `{"code": ...}`.
  static String? _code(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map) return null;
      final error = decoded['error'];
      if (error is Map) return error['code'] as String?;
      return decoded['code'] as String?;
    } on FormatException {
      return null;
    }
  }

  /// `MAX_LOCK_REASON_CODE_LENGTH` is 40; a longer reason is cut here rather than turning
  /// the whole question into a 400.
  static String _clip(String value) =>
      value.length <= 40 ? value : value.substring(0, 40);
}

/// The production asker: the paired handset's own credential, through the native bridge.
ChildTimeRequestClient childTimeRequestClient() =>
    ChildTimeRequestClient(transport: const NativeChildTimeRequestTransport());
