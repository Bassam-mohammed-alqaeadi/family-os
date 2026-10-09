// W8 — the calendar client, verified against the contract it speaks.
//
// Waves 5, 6 and 7 each gave their contract a file of its own, and this one follows them
// because the reason is not tidiness: the client is where a wire answer becomes something a
// family reads, and every claim this wave makes is decided here.
//
// What is pinned, in the order the file reads:
//
//   * the URL, the verb, and the window: a read asks for a range, a write carries none, and a
//     path built from a value the server never issued is refused before a socket is opened;
//   * a cancelled event is returned as cancelled, with its author, its reason and its moment -
//     and a cancellation missing any of those is refused rather than drawn;
//   * an answer that cannot be attributed to exactly one author is refused: a payload claiming
//     two authors (or none) is a server whose answers about a child are not evidence;
//   * "declined" parses as an answer, and a recorded absence parses as attendance: neither is
//     an absence of data;
//   * `version` is required on an edit and an empty edit is refused before it is sent;
//   * the failure mapping (400 / 401 / 403 / 404 / 409 / 429 / anything else) for every verb.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/foundation_gate/family_calendar_api_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_configuration.dart';
import 'package:family_os/foundation_gate/foundation_gate_http.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';

const _familyId = '11111111-1111-4111-8111-111111111111';
const _childId = '22222222-2222-4222-8222-222222222222';
const _siblingId = '33333333-3333-4333-8333-333333333333';
const _eventId = '44444444-4444-4444-8444-444444444444';
const _membershipId = '66666666-6666-4666-8666-666666666666';
const _deviceId = '77777777-7777-4777-8777-777777777777';

final class _Transport implements FoundationGateHttpTransport {
  _Transport(this.answer);

  FoundationGateHttpResponse Function(Uri uri, String? body) answer;
  final List<String> calls = <String>[];
  final List<Uri> uris = <Uri>[];
  final List<Map<String, String>> headers = <Map<String, String>>[];
  final List<String> bodies = <String>[];

  FoundationGateHttpResponse _reply(String method, Uri uri, String? body) {
    calls.add('$method ${uri.path}');
    uris.add(uri);
    if (body != null) bodies.add(body);
    return answer(uri, body);
  }

  @override
  Future<FoundationGateHttpResponse> get(
    Uri uri, {
    required Map<String, String> headers,
  }) async {
    this.headers.add(headers);
    return _reply('GET', uri, null);
  }

  @override
  Future<FoundationGateHttpResponse> post(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
  }) async {
    this.headers.add(headers);
    return _reply('POST', uri, body);
  }

  @override
  Future<FoundationGateHttpResponse> patch(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
  }) async {
    this.headers.add(headers);
    return _reply('PATCH', uri, body);
  }

  @override
  Future<FoundationGateHttpResponse> put(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
  }) async {
    this.headers.add(headers);
    return _reply('PUT', uri, body);
  }
}

FamilyCalendarApiClient _client(_Transport transport) =>
    FamilyCalendarApiClient(
      configuration: FoundationGateConfiguration.fromStagingApiOrigin(
        Uri.parse('https://staging.example.test'),
      ),
      transport: transport,
    );

FoundationGateHttpResponse _ok(String body) =>
    FoundationGateHttpResponse(statusCode: 200, body: body);

FoundationGateHttpResponse _created(String body) =>
    FoundationGateHttpResponse(statusCode: 201, body: body);

FoundationGateHttpResponse _status(int status) =>
    FoundationGateHttpResponse(statusCode: status, body: '{}');

Map<String, Object?> _responseJson({
  String childId = _childId,
  String answer = 'accepted',
  String? byDevice,
  String? byMembership = _membershipId,
}) => <String, Object?>{
  'childId': childId,
  'response': answer,
  'note': '',
  'respondedByDeviceId': byDevice,
  'respondedByMembershipId': byMembership,
  'respondedAt': '2026-10-09T06:00:00.000Z',
};

Map<String, Object?> _attendanceJson({
  String childId = _childId,
  bool attended = true,
}) => <String, Object?>{
  'childId': childId,
  'attended': attended,
  'note': attended ? '' : 'كان مريضاً',
  'recordedByMembershipId': _membershipId,
  'recordedAt': '2026-10-09T18:00:00.000Z',
};

Map<String, Object?> _audienceJson({
  String childId = _childId,
  Object? response,
  Object? attendance,
}) => <String, Object?>{
  'childId': childId,
  'response': response,
  'attendance': attendance,
};

Map<String, Object?> _eventJson({
  String status = 'scheduled',
  int version = 1,
  int? reminderMinutes = 60,
  List<Object?>? audience,
  Object? cancelledBy = _membershipId,
  Object? cancelledAt = '2026-10-08T11:00:00.000Z',
  String cancelReason = 'الجدّ مريض',
}) => <String, Object?>{
  'id': _eventId,
  'title': 'زيارة الجدّ',
  'note': 'نأخذ الكيك',
  'location': 'بيت الجدّ',
  'startsAt': '2026-10-09T15:00:00.000Z',
  'endsAt': '2026-10-09T17:00:00.000Z',
  'allDay': false,
  'reminderMinutes': reminderMinutes,
  'status': status,
  'version': version,
  'createdByMembershipId': _membershipId,
  'cancelledByMembershipId': status == 'cancelled' ? cancelledBy : null,
  'cancelledAt': status == 'cancelled' ? cancelledAt : null,
  'cancelReason': status == 'cancelled' ? cancelReason : '',
  'createdAt': '2026-10-08T08:00:00.000Z',
  'updatedAt': '2026-10-08T08:00:00.000Z',
  'audience':
      audience ??
      <Object?>[_audienceJson(), _audienceJson(childId: _siblingId)],
};

/// Runs [call] and returns the refusal it must produce. A call that succeeds is a failure
/// here: every one of these cases is a server answer this client exists to reject.
Future<FoundationGateApiException> _refusal(
  Future<Object?> Function() call,
) async {
  try {
    await call();
  } on FoundationGateApiException catch (exception) {
    return exception;
  }
  fail('the client accepted an answer it should have refused');
}

void main() {
  test('a calendar read asks for a window, and the window is in the URL', () async {
    final transport = _Transport(
      (uri, body) => _ok(
        jsonEncode(<String, Object?>{
          'events': <Object?>[_eventJson()],
        }),
      ),
    );

    final calendar = await _client(transport).listEvents(
      familyId: _familyId,
      from: DateTime.utc(2026, 10, 5),
      to: DateTime.utc(2026, 10, 12),
      idToken: 'token',
    );

    expect(transport.calls.single, 'GET /v1/families/$_familyId/events');
    expect(
      transport.uris.single.queryParameters['from'],
      '2026-10-05T00:00:00.000Z',
      reason: 'an instant, not a day: the server refuses a read without a window',
    );
    expect(transport.uris.single.queryParameters['to'], '2026-10-12T00:00:00.000Z');
    expect(transport.headers.single['authorization'], 'Bearer token');
    expect(calendar.events.single.audience.length, 2);
    expect(
      calendar.events.single.audience.first.response,
      isNull,
      reason: 'a child who has not answered is not a child who declined',
    );
  });

  test('a window that runs backwards is refused here, before a request exists', () async {
    final transport = _Transport((uri, body) => _ok('{}'));
    await expectLater(
      () => _client(transport).listEvents(
        familyId: _familyId,
        from: DateTime.utc(2026, 10, 12),
        to: DateTime.utc(2026, 10, 5),
        idToken: 'token',
      ),
      throwsArgumentError,
    );
    expect(transport.calls, isEmpty);
  });

  test('what was called off comes back as called off, with its reason', () async {
    final transport = _Transport(
      (uri, body) => _ok(
        jsonEncode(<String, Object?>{
          'events': <Object?>[
            _eventJson(),
            _eventJson(status: 'cancelled', version: 2),
          ],
        }),
      ),
    );

    final calendar = await _client(transport).listEvents(
      familyId: _familyId,
      from: DateTime.utc(2026, 10, 5),
      to: DateTime.utc(2026, 10, 12),
      idToken: 'token',
    );

    expect(calendar.scheduled.length, 1);
    expect(calendar.cancelled.length, 1, reason: 'a cancellation is not a disappearance');
    final cancelled = calendar.cancelled.single;
    expect(cancelled.isCancelled, isTrue);
    expect(cancelled.cancelReason, 'الجدّ مريض');
    expect(cancelled.cancelledByMembershipId, _membershipId);
    expect(cancelled.cancelledAt, DateTime.utc(2026, 10, 8, 11));
  });

  test('a cancellation missing its author or its moment is refused, not drawn', () async {
    for (final incomplete in <Map<String, Object?>>[
      _eventJson(status: 'cancelled', cancelledBy: null),
      _eventJson(status: 'cancelled', cancelledAt: null),
    ]) {
      final transport = _Transport(
        (uri, body) => _ok(
          jsonEncode(<String, Object?>{
            'events': <Object?>[incomplete],
          }),
        ),
      );
      final failure = await _refusal(
        () => _client(transport).listEvents(
          familyId: _familyId,
          from: DateTime.utc(2026, 10, 5),
          to: DateTime.utc(2026, 10, 12),
          idToken: 'token',
        ),
      );
      expect(failure.failure, FoundationGateApiFailure.invalidResponse);
    }
  });

  test('an event status this build cannot name is refused', () async {
    final transport = _Transport(
      (uri, body) => _ok(
        jsonEncode(<String, Object?>{
          'events': <Object?>[_eventJson(status: 'postponed')],
        }),
      ),
    );
    final failure = await _refusal(
      () => _client(transport).listEvents(
        familyId: _familyId,
        from: DateTime.utc(2026, 10, 5),
        to: DateTime.utc(2026, 10, 12),
        idToken: 'token',
      ),
    );
    expect(failure.failure, FoundationGateApiFailure.invalidResponse);
  });

  test('a reminder is what the family asked for, and zero is not the same as nothing', () async {
    final transport = _Transport(
      (uri, body) => _ok(
        jsonEncode(<String, Object?>{
          'events': <Object?>[
            _eventJson(reminderMinutes: 0),
            _eventJson(reminderMinutes: null),
          ],
        }),
      ),
    );

    final calendar = await _client(transport).listEvents(
      familyId: _familyId,
      from: DateTime.utc(2026, 10, 5),
      to: DateTime.utc(2026, 10, 12),
      idToken: 'token',
    );

    expect(calendar.events.first.reminderMinutes, 0);
    expect(
      calendar.events.last.reminderMinutes,
      isNull,
      reason: 'asking for nothing is not asking for "at the moment it starts"',
    );
  });

  test('an answer with two authors, or with none, is refused', () async {
    for (final authorship in <Map<String, Object?>>[
      _responseJson(byDevice: _deviceId, byMembership: _membershipId),
      _responseJson(byMembership: null),
    ]) {
      final transport = _Transport(
        (uri, body) => _ok(
          jsonEncode(<String, Object?>{
            'events': <Object?>[
              _eventJson(
                audience: <Object?>[_audienceJson(response: authorship)],
              ),
            ],
          }),
        ),
      );
      final failure = await _refusal(
        () => _client(transport).listEvents(
          familyId: _familyId,
          from: DateTime.utc(2026, 10, 5),
          to: DateTime.utc(2026, 10, 12),
          idToken: 'token',
        ),
      );
      expect(
        failure.failure,
        FoundationGateApiFailure.invalidResponse,
        reason: 'an answer about a child that cannot be attributed is not evidence',
      );
    }
  });

  test('a "no" is an answer and a recorded absence is attendance', () async {
    final transport = _Transport(
      (uri, body) => _ok(
        jsonEncode(<String, Object?>{
          'events': <Object?>[
            _eventJson(
              audience: <Object?>[
                _audienceJson(
                  response: _responseJson(
                    answer: 'declined',
                    byMembership: null,
                    byDevice: _deviceId,
                  ),
                  attendance: _attendanceJson(attended: false),
                ),
              ],
            ),
          ],
        }),
      ),
    );

    final calendar = await _client(transport).listEvents(
      familyId: _familyId,
      from: DateTime.utc(2026, 10, 5),
      to: DateTime.utc(2026, 10, 12),
      idToken: 'token',
    );

    final entry = calendar.events.single.audience.single;
    expect(entry.response!.answer, FoundationGateEventAnswer.declined);
    expect(
      entry.response!.respondedByDeviceId,
      _deviceId,
      reason: 'the child answered from their own handset, and that is who answered',
    );
    expect(entry.response!.respondedByMembershipId, isNull);
    expect(
      entry.attendance!.attended,
      isFalse,
      reason: 'an absence that was recorded is a fact, not a missing value',
    );
    expect(FoundationGateEventAudienceEntry.answeredCount(calendar.events.single.audience), 1);
  });

  test('a guardian states an event: POST on the collection, audience and key included', () async {
    final transport = _Transport(
      (uri, body) => _created(jsonEncode(<String, Object?>{'event': _eventJson()})),
    );

    await _client(transport).createEvent(
      familyId: _familyId,
      title: 'زيارة الجدّ',
      note: 'نأخذ الكيك',
      location: 'بيت الجدّ',
      startsAt: DateTime.utc(2026, 10, 9, 15),
      endsAt: DateTime.utc(2026, 10, 9, 17),
      reminderMinutes: 60,
      childIds: <String>[_childId, _siblingId],
      idempotencyKey: 'key-create',
      idToken: 'token',
    );

    expect(transport.calls.single, 'POST /v1/families/$_familyId/events');
    expect(
      transport.uris.single.hasQuery,
      isFalse,
      reason: 'the write refuses query parameters: the body is the whole request',
    );
    expect(transport.headers.single['idempotency-key'], 'key-create');
    final sent = jsonDecode(transport.bodies.single) as Map<String, Object?>;
    expect(sent['startsAt'], '2026-10-09T15:00:00.000Z');
    expect(sent['childIds'], <String>[_childId, _siblingId]);
    expect(sent['reminderMinutes'], 60);
    expect(
      sent.keys.where((key) => key.toLowerCase().contains('notif')),
      isEmpty,
      reason: 'nothing here may claim a notification was delivered',
    );
    expect(
      sent.containsKey('status'),
      isFalse,
      reason: 'an event is born scheduled; the client does not state its own lifecycle',
    );
  });

  test('an event with nobody invited is refused before it is sent', () async {
    final transport = _Transport((uri, body) => _created('{}'));
    await expectLater(
      () => _client(transport).createEvent(
        familyId: _familyId,
        title: 'ملاحظة لنفسي',
        startsAt: DateTime.utc(2026, 10, 9, 15),
        endsAt: DateTime.utc(2026, 10, 9, 17),
        childIds: const <String>[],
        idempotencyKey: 'key',
        idToken: 'token',
      ),
      throwsArgumentError,
    );
    expect(transport.calls, isEmpty);
  });

  test('an edit states the version it read, and sends only what changed', () async {
    final transport = _Transport(
      (uri, body) => _ok(jsonEncode(<String, Object?>{'event': _eventJson(version: 2)})),
    );

    final updated = await _client(transport).updateEvent(
      familyId: _familyId,
      eventId: _eventId,
      version: 1,
      location: 'بيت العمّ',
      idToken: 'token',
    );

    expect(transport.calls.single, 'PATCH /v1/families/$_familyId/events/$_eventId');
    final sent = jsonDecode(transport.bodies.single) as Map<String, Object?>;
    expect(sent['version'], 1, reason: 'the version that was read, not the one hoped for');
    expect(sent['location'], 'بيت العمّ');
    expect(
      sent.keys.toSet(),
      <String>{'version', 'location'},
      reason: 'an edit sends only what it changes; a full body would overwrite a co-guardian',
    );
    expect(updated.version, 2);
  });

  test('an edit that changes nothing is refused here, not sent to earn a 400', () async {
    final transport = _Transport((uri, body) => _ok('{}'));
    await expectLater(
      () => _client(transport).updateEvent(
        familyId: _familyId,
        eventId: _eventId,
        version: 1,
        idToken: 'token',
      ),
      throwsArgumentError,
    );
    expect(transport.calls, isEmpty);
  });

  test('a stale edit arrives as a conflict, not as a silent success', () async {
    final transport = _Transport((uri, body) => _status(409));
    final failure = await _refusal(
      () => _client(transport).updateEvent(
        familyId: _familyId,
        eventId: _eventId,
        version: 1,
        title: 'شيء آخر',
        idToken: 'token',
      ),
    );
    expect(failure.failure, FoundationGateApiFailure.conflict);
  });

  test('cancelling needs a reason and a key, and keeps the audience and the answers', () async {
    final transport = _Transport(
      (uri, body) => _ok(
        jsonEncode(<String, Object?>{
          'event': _eventJson(
            status: 'cancelled',
            version: 2,
            audience: <Object?>[
              _audienceJson(response: _responseJson()),
              _audienceJson(childId: _siblingId),
            ],
          ),
        }),
      ),
    );

    final cancelled = await _client(transport).cancelEvent(
      familyId: _familyId,
      eventId: _eventId,
      reason: 'الجدّ مريض',
      idempotencyKey: 'key-cancel',
      idToken: 'token',
    );

    expect(transport.calls.single, 'POST /v1/families/$_familyId/events/$_eventId/cancel');
    expect(transport.headers.single['idempotency-key'], 'key-cancel');
    expect(cancelled.isCancelled, isTrue);
    expect(cancelled.cancelReason, 'الجدّ مريض');
    expect(cancelled.audience.length, 2, reason: 'the invitation survives the cancellation');
    expect(
      cancelled.audience.first.response!.answer,
      FoundationGateEventAnswer.accepted,
      reason: 'and so does the answer that was given before it was called off',
    );

    final empty = _Transport((uri, body) => _ok('{}'));
    await expectLater(
      () => _client(empty).cancelEvent(
        familyId: _familyId,
        eventId: _eventId,
        reason: '   ',
        idempotencyKey: 'key',
        idToken: 'token',
      ),
      throwsArgumentError,
    );
    expect(empty.calls, isEmpty);
  });

  test('cancelling twice arrives as a conflict', () async {
    final transport = _Transport((uri, body) => _status(409));
    final failure = await _refusal(
      () => _client(transport).cancelEvent(
        familyId: _familyId,
        eventId: _eventId,
        reason: 'مرة ثانية',
        idempotencyKey: 'key',
        idToken: 'token',
      ),
    );
    expect(failure.failure, FoundationGateApiFailure.conflict);
  });

  test('attendance carries the child, the verdict and the key that makes a retry the same fact', () async {
    final transport = _Transport(
      (uri, body) => _ok(
        jsonEncode(<String, Object?>{'attendance': _attendanceJson(attended: false)}),
      ),
    );

    final attendance = await _client(transport).recordAttendance(
      familyId: _familyId,
      eventId: _eventId,
      childId: _childId,
      attended: false,
      note: 'كان مريضاً',
      idempotencyKey: 'key-attendance',
      idToken: 'token',
    );

    expect(
      transport.calls.single,
      'POST /v1/families/$_familyId/events/$_eventId/attendance',
    );
    expect(transport.headers.single['idempotency-key'], 'key-attendance');
    final sent = jsonDecode(transport.bodies.single) as Map<String, Object?>;
    expect(sent['attended'], isFalse);
    expect(
      sent.keys.where((key) => key.toLowerCase().contains('location')),
      isEmpty,
      reason: 'attendance is what a person said, never where a phone was',
    );
    expect(attendance.attended, isFalse);
    expect(attendance.recordedByMembershipId, _membershipId);
  });

  test('recording a fact too early arrives as a conflict', () async {
    final transport = _Transport((uri, body) => _status(409));
    final failure = await _refusal(
      () => _client(transport).recordAttendance(
        familyId: _familyId,
        eventId: _eventId,
        childId: _childId,
        attended: true,
        idempotencyKey: 'key',
        idToken: 'token',
      ),
    );
    expect(failure.failure, FoundationGateApiFailure.conflict);
  });

  test('a guardian records the answer a child gave, naming that child', () async {
    final transport = _Transport(
      (uri, body) => _ok(
        jsonEncode(<String, Object?>{'response': _responseJson(answer: 'declined')}),
      ),
    );

    final response = await _client(transport).recordResponse(
      familyId: _familyId,
      childId: _childId,
      eventId: _eventId,
      answer: FoundationGateEventAnswer.declined,
      note: 'قال إنه مشغول',
      idempotencyKey: 'key-response',
      idToken: 'token',
    );

    expect(
      transport.calls.single,
      'POST /v1/families/$_familyId/children/$_childId/events/$_eventId/response',
    );
    expect(transport.headers.single['idempotency-key'], 'key-response');
    final sent = jsonDecode(transport.bodies.single) as Map<String, Object?>;
    expect(sent['response'], 'declined');
    expect(
      sent.containsKey('respondedByMembershipId'),
      isFalse,
      reason: 'the author is decided by how the request arrived, not by the body',
    );
    expect(response.answer, FoundationGateEventAnswer.declined);
    expect(
      response.respondedByMembershipId,
      _membershipId,
      reason: 'the guardian is the author of the answer they recorded',
    );
  });

  test('a path built from a value the server never issued is refused before a request', () async {
    final transport = _Transport((uri, body) => _ok('{}'));
    await expectLater(
      () => _client(transport).recordAttendance(
        familyId: _familyId,
        eventId: 'not-an-event-id',
        childId: _childId,
        attended: true,
        idempotencyKey: 'key',
        idToken: 'token',
      ),
      throwsArgumentError,
    );
    expect(transport.calls, isEmpty);
  });

  test('every refusal the contract can send is mapped, per verb', () async {
    final cases = <int, FoundationGateApiFailure>{
      400: FoundationGateApiFailure.invalidInput,
      401: FoundationGateApiFailure.unauthenticated,
      403: FoundationGateApiFailure.accessDenied,
      429: FoundationGateApiFailure.serviceUnavailable,
      503: FoundationGateApiFailure.serviceUnavailable,
      500: FoundationGateApiFailure.invalidResponse,
    };
    for (final entry in cases.entries) {
      final transport = _Transport((uri, body) => _status(entry.key));
      final failure = await _refusal(
        () => _client(transport).listEvents(
          familyId: _familyId,
          from: DateTime.utc(2026, 10, 5),
          to: DateTime.utc(2026, 10, 12),
          idToken: 'token',
        ),
      );
      expect(failure.failure, entry.value, reason: 'status ${entry.key}');
    }
  });

  test('a socket that fails is a network answer, never an invented empty calendar', () async {
    final transport = _Transport((uri, body) => throw Exception('offline'));
    final failure = await _refusal(
      () => _client(transport).listEvents(
        familyId: _familyId,
        from: DateTime.utc(2026, 10, 5),
        to: DateTime.utc(2026, 10, 12),
        idToken: 'token',
      ),
    );
    expect(failure.failure, FoundationGateApiFailure.networkUnavailable);
  });
}
