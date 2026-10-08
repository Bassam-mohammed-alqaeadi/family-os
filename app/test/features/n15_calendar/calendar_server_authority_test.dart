// W8 — the calendar authority, and the facts it refuses to invent.
//
// The statuses are the same five waves 4, 5 and 6 settled on, and this wave is where they
// matter most, because a calendar records people rather than devices:
//
//   * no session        -> nothing is asked, because there is nobody to ask;
//   * access denied     -> refused, and not retried: this account may not see this calendar;
//   * unreachable       -> nothing on the screen may move, and no plan may be drawn;
//   * a refusal with a  reason (already cancelled, edited by somebody else, a fact that
//     cannot be recorded yet) arrives as a refusal the screen shows as it is;
//   * and a status, an answer or an authorship this build cannot name is refused rather than
//     dropped, because a silently dropped invitation is a child who was not told.
//
// Two laws are asserted here rather than assumed: an answer is recorded for ONE named child
// (there is no method that answers for a group), and an attendance record is a verdict with a
// key - never a location, and never a second moment for a retried tap.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/features/n15_calendar/calendar_server_authority.dart';
import 'package:family_os/foundation_gate/family_calendar_api_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_configuration.dart';
import 'package:family_os/foundation_gate/foundation_gate_http.dart';

const _familyId = '11111111-1111-4111-8111-111111111111';
const _childId = '22222222-2222-4222-8222-222222222222';
const _siblingId = '33333333-3333-4333-8333-333333333333';
const _eventId = '44444444-4444-4444-8444-444444444444';
const _membershipId = '66666666-6666-4666-8666-666666666666';
const _deviceId = '77777777-7777-4777-8777-777777777777';

/// A transport that answers per path and verb, and records what it was asked.
final class _Transport implements FoundationGateHttpTransport {
  _Transport(
    this.responses, {
    this.postResponses = const <String, FoundationGateHttpResponse>{},
  });

  final Map<String, FoundationGateHttpResponse> responses;

  /// Answers for POST only: a real server says different things about the same URL depending
  /// on the verb, and a test that could not express that could not test a refusal.
  final Map<String, FoundationGateHttpResponse> postResponses;
  final List<String> calls = <String>[];
  final List<String> bodies = <String>[];
  final List<Uri> uris = <Uri>[];
  Object? failure;

  @override
  Future<FoundationGateHttpResponse> get(
    Uri uri, {
    required Map<String, String> headers,
  }) async {
    calls.add('GET ${uri.path}');
    uris.add(uri);
    if (failure != null) throw failure!;
    return _match(uri);
  }

  @override
  Future<FoundationGateHttpResponse> post(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
  }) async {
    calls.add('POST ${uri.path}');
    bodies.add(body);
    uris.add(uri);
    if (failure != null) throw failure!;
    return _match(uri, extra: postResponses);
  }

  @override
  Future<FoundationGateHttpResponse> patch(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
  }) async {
    calls.add('PATCH ${uri.path}');
    bodies.add(body);
    uris.add(uri);
    if (failure != null) throw failure!;
    return _match(uri);
  }

  @override
  Future<FoundationGateHttpResponse> put(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
  }) async {
    calls.add('PUT ${uri.path}');
    bodies.add(body);
    uris.add(uri);
    if (failure != null) throw failure!;
    return _match(uri);
  }

  /// The most specific registered path wins, so `/cancel` is never answered by the
  /// `/events` entry beside it.
  FoundationGateHttpResponse _match(
    Uri uri, {
    Map<String, FoundationGateHttpResponse> extra =
        const <String, FoundationGateHttpResponse>{},
  }) {
    final keys = <String>[...extra.keys, ...responses.keys].toList()
      ..sort((left, right) => right.length.compareTo(left.length));
    for (final key in keys) {
      if (uri.path.endsWith(key)) return (extra[key] ?? responses[key])!;
    }
    throw StateError('no response registered for ${uri.path}');
  }
}

FoundationGateHttpResponse _ok(String body) =>
    FoundationGateHttpResponse(statusCode: 200, body: body);

FoundationGateHttpResponse _created(String body) =>
    FoundationGateHttpResponse(statusCode: 201, body: body);

FoundationGateHttpResponse _status(int code) =>
    FoundationGateHttpResponse(statusCode: code, body: '{}');

CalendarServerAuthority _authorityFor(
  _Transport transport, {
  String? familyId = _familyId,
  String token = 'test-token',
}) => CalendarServerAuthority(
  api: FamilyCalendarApiClient(
    configuration: FoundationGateConfiguration.fromStagingApiOrigin(
      Uri.parse('https://staging.example.test'),
    ),
    transport: transport,
  ),
  idToken: () async => token,
  familyId: () => familyId,
);

final _from = DateTime.utc(2026, 10, 5);
final _to = DateTime.utc(2026, 10, 12);

Map<String, Object?> eventJson({
  String status = 'scheduled',
  int version = 1,
  List<Object?>? audience,
}) => <String, Object?>{
  'id': _eventId,
  'title': 'زيارة الجدّ',
  'note': 'نأخذ الكيك',
  'location': 'بيت الجدّ',
  'startsAt': '2026-10-09T15:00:00.000Z',
  'endsAt': '2026-10-09T17:00:00.000Z',
  'allDay': false,
  'reminderMinutes': 60,
  'status': status,
  'version': version,
  'createdByMembershipId': _membershipId,
  'cancelledByMembershipId': status == 'cancelled' ? _membershipId : null,
  'cancelledAt': status == 'cancelled' ? '2026-10-08T11:00:00.000Z' : null,
  'cancelReason': status == 'cancelled' ? 'الجدّ مريض' : '',
  'createdAt': '2026-10-08T08:00:00.000Z',
  'updatedAt': '2026-10-08T08:00:00.000Z',
  'audience':
      audience ??
      <Object?>[
        <String, Object?>{'childId': _childId, 'response': null, 'attendance': null},
        <String, Object?>{'childId': _siblingId, 'response': null, 'attendance': null},
      ],
};

String calendarBody({List<Object?>? events}) => jsonEncode(<String, Object?>{
  'events': events ?? <Object?>[eventJson()],
});

Map<String, Object?> attendanceJson({bool attended = true}) =>
    <String, Object?>{
      'childId': _childId,
      'attended': attended,
      'note': '',
      'recordedByMembershipId': _membershipId,
      'recordedAt': '2026-10-09T18:00:00.000Z',
    };

Map<String, Object?> responseJson({String answer = 'declined'}) =>
    <String, Object?>{
      'childId': _childId,
      'response': answer,
      'note': 'عندي تدريب',
      'respondedByDeviceId': _deviceId,
      'respondedByMembershipId': null,
      'respondedAt': '2026-10-09T06:00:00.000Z',
    };

void main() {
  test('a build with no session asks nothing and says why', () async {
    final transport = _Transport(<String, FoundationGateHttpResponse>{
      '/events': _ok(calendarBody()),
    });
    final answer = await _authorityFor(
      transport,
      familyId: null,
    ).listEvents(from: _from, to: _to);
    expect(answer.status, CalendarAuthorityStatus.notConfigured);
    expect(answer.value, isNull);
    expect(transport.calls, isEmpty, reason: 'there was nobody to ask');
  });

  test('the plans the server states are the plans the screen gets', () async {
    final transport = _Transport(<String, FoundationGateHttpResponse>{
      '/events': _ok(calendarBody()),
    });
    final answer = await _authorityFor(
      transport,
    ).listEvents(from: _from, to: _to);
    expect(answer.status, CalendarAuthorityStatus.ready);
    final event = answer.value!.events.single;
    expect(event.title, 'زيارة الجدّ');
    expect(event.audience.length, 2, reason: 'both children were invited');
    expect(
      event.audience.first.response,
      isNull,
      reason: 'nobody has answered yet - which is not the same as "declined"',
    );
    expect(transport.calls.single, 'GET /v1/families/$_familyId/events');
    expect(transport.uris.single.queryParameters['from'], '2026-10-05T00:00:00.000Z');
  });

  test('a status this build cannot name is refused rather than drawn', () async {
    final transport = _Transport(<String, FoundationGateHttpResponse>{
      '/events': _ok(
        calendarBody(events: <Object?>[eventJson(status: 'postponed')]),
      ),
    });
    final answer = await _authorityFor(
      transport,
    ).listEvents(from: _from, to: _to);
    expect(answer.status, CalendarAuthorityStatus.refused);
    expect(answer.value, isNull);
  });

  test('an answer nobody can be attributed to is refused, because an unattributed answer is not evidence', () async {
    final transport = _Transport(<String, FoundationGateHttpResponse>{
      '/events': _ok(
        calendarBody(
          events: <Object?>[
            eventJson(
              audience: <Object?>[
                <String, Object?>{
                  'childId': _childId,
                  'response': <String, Object?>{
                    ...responseJson(),
                    'respondedByMembershipId': _membershipId,
                    'respondedByDeviceId': _deviceId,
                  },
                  'attendance': null,
                },
              ],
            ),
          ],
        ),
      ),
    });
    final answer = await _authorityFor(
      transport,
    ).listEvents(from: _from, to: _to);
    expect(answer.status, CalendarAuthorityStatus.refused);
  });

  test('a window that runs backwards is refused without asking anybody', () async {
    final transport = _Transport(<String, FoundationGateHttpResponse>{
      '/events': _ok(calendarBody()),
    });
    final answer = await _authorityFor(
      transport,
    ).listEvents(from: _to, to: _from);
    expect(answer.status, CalendarAuthorityStatus.refused);
    expect(
      transport.calls,
      isEmpty,
      reason: 'a window this build cannot build is not a network problem',
    );
  });

  test('a stated event carries its audience, and its key is the caller\'s', () async {
    final transport = _Transport(
      <String, FoundationGateHttpResponse>{'/events': _ok(calendarBody())},
      postResponses: <String, FoundationGateHttpResponse>{
        '/events': _created(jsonEncode(<String, Object?>{'event': eventJson()})),
      },
    );
    final answer = await _authorityFor(transport).createEvent(
      title: 'زيارة الجدّ',
      startsAt: DateTime.utc(2026, 10, 9, 15),
      endsAt: DateTime.utc(2026, 10, 9, 17),
      childIds: <String>[_childId, _siblingId],
      reminderMinutes: 60,
      idempotencyKey: () => 'key-create',
    );
    expect(answer.status, CalendarAuthorityStatus.ready);
    final sent = jsonDecode(transport.bodies.single) as Map<String, Object?>;
    expect(sent['childIds'], <String>[_childId, _siblingId]);
    expect(
      sent.containsKey('createdByMembershipId'),
      isFalse,
      reason: 'the author is decided by the session, not by the request',
    );
  });

  test('an evening with nobody invited is refused without asking anybody', () async {
    final transport = _Transport(<String, FoundationGateHttpResponse>{
      '/events': _ok(calendarBody()),
    });
    final answer = await _authorityFor(transport).createEvent(
      title: 'ملاحظة لنفسي',
      startsAt: DateTime.utc(2026, 10, 9, 15),
      endsAt: DateTime.utc(2026, 10, 9, 17),
      childIds: const <String>[],
      idempotencyKey: () => 'key-create',
    );
    expect(answer.status, CalendarAuthorityStatus.refused);
    expect(transport.calls, isEmpty);
  });

  test('an edit sends only what changed, and states the version it read', () async {
    final transport = _Transport(<String, FoundationGateHttpResponse>{
      '/events': _ok(calendarBody()),
      // The event's own path is more specific than the collection beside it, so the edit
      // lands on its own answer: the server's, not the read's.
      '/$_eventId': _ok(
        jsonEncode(<String, Object?>{'event': eventJson(version: 4)}),
      ),
    });
    final answer = await _authorityFor(transport).updateEvent(
      eventId: _eventId,
      version: 3,
      location: 'بيت العمّ',
    );
    expect(answer.status, CalendarAuthorityStatus.ready);
    expect(answer.value!.version, 4, reason: 'an edit that landed moves the version');
    expect(
      transport.calls.single,
      'PATCH /v1/families/$_familyId/events/$_eventId',
    );
    final sent = jsonDecode(transport.bodies.single) as Map<String, Object?>;
    expect(sent['version'], 3, reason: 'the version that was read, not the one hoped for');
    expect(
      sent.keys.toSet(),
      <String>{'version', 'location'},
      reason: 'an edit sends only what it changes; a full body would overwrite a co-guardian',
    );
  });

  test('an edit by a guardian who read an older version arrives as a refusal, not a success', () async {
    final transport = _Transport(<String, FoundationGateHttpResponse>{
      '/events': _ok(calendarBody()),
      '/$_eventId': _status(409),
    });
    final answer = await _authorityFor(transport).updateEvent(
      eventId: _eventId,
      version: 3,
      title: 'شيء آخر',
    );
    expect(
      answer.status,
      CalendarAuthorityStatus.refused,
      reason: 'a conflict is an answer, not a crash and not a silent success',
    );
    expect(answer.value, isNull);
  });

  test('an edit that changes nothing is refused without asking anybody', () async {
    final transport = _Transport(<String, FoundationGateHttpResponse>{
      '/events': _ok(calendarBody()),
    });
    final answer = await _authorityFor(
      transport,
    ).updateEvent(eventId: _eventId, version: 1);
    expect(answer.status, CalendarAuthorityStatus.refused);
    expect(transport.calls, isEmpty);
  });

  test('cancelling keeps the plan, its reason and the answers it already had', () async {
    final transport = _Transport(
      <String, FoundationGateHttpResponse>{'/events': _ok(calendarBody())},
      postResponses: <String, FoundationGateHttpResponse>{
        '/cancel': _ok(
          jsonEncode(<String, Object?>{
            'event': eventJson(
              status: 'cancelled',
              version: 2,
              audience: <Object?>[
                <String, Object?>{
                  'childId': _childId,
                  'response': responseJson(answer: 'accepted'),
                  'attendance': null,
                },
              ],
            ),
          }),
        ),
      },
    );
    final answer = await _authorityFor(transport).cancelEvent(
      eventId: _eventId,
      reason: 'الجدّ مريض',
      idempotencyKey: () => 'key-cancel',
    );
    expect(answer.status, CalendarAuthorityStatus.ready);
    expect(answer.value!.isCancelled, isTrue);
    expect(answer.value!.cancelReason, 'الجدّ مريض');
    expect(
      answer.value!.audience.single.response!.answer,
      FoundationGateEventAnswer.accepted,
      reason: 'the answer that was given before the cancellation is not erased by it',
    );
  });

  test('an answer is recorded for one named child, never for the children as a group', () async {
    final transport = _Transport(
      <String, FoundationGateHttpResponse>{'/events': _ok(calendarBody())},
      postResponses: <String, FoundationGateHttpResponse>{
        '/response': _ok(
          jsonEncode(<String, Object?>{'response': responseJson()}),
        ),
      },
    );
    final answer = await _authorityFor(transport).recordResponse(
      childId: _childId,
      eventId: _eventId,
      answer: FoundationGateEventAnswer.declined,
      note: 'عندي تدريب',
      idempotencyKey: () => 'key-response',
    );
    expect(answer.status, CalendarAuthorityStatus.ready);
    expect(answer.value!.answer, FoundationGateEventAnswer.declined);
    expect(
      transport.calls.single,
      'POST /v1/families/$_familyId/children/$_childId/events/$_eventId/response',
      reason: 'the child answered is the child named, and there is no group route',
    );
    final sent = jsonDecode(transport.bodies.single) as Map<String, Object?>;
    expect(sent['response'], 'declined');
  });

  test('an attendance record is a verdict with a key, never a location and never a second moment', () async {
    final transport = _Transport(
      <String, FoundationGateHttpResponse>{'/events': _ok(calendarBody())},
      postResponses: <String, FoundationGateHttpResponse>{
        '/attendance': _ok(
          jsonEncode(<String, Object?>{
            'attendance': attendanceJson(attended: false),
          }),
        ),
      },
    );
    final answer = await _authorityFor(transport).recordAttendance(
      eventId: _eventId,
      childId: _childId,
      attended: false,
      idempotencyKey: () => 'key-attendance',
    );
    expect(answer.status, CalendarAuthorityStatus.ready);
    expect(
      answer.value!.attended,
      isFalse,
      reason: 'an absence that was recorded is a fact, not a missing value',
    );
    final sent = jsonDecode(transport.bodies.single) as Map<String, Object?>;
    expect(
      sent.keys.where((key) => key.toLowerCase().contains('location')),
      isEmpty,
      reason: 'presence is stated by a person, never read from a phone',
    );
    expect(sent.keys.toSet(), <String>{'childId', 'attended'});
  });

  test('a refusal with a reason arrives as a refusal, and nothing is invented', () async {
    final transport = _Transport(
      <String, FoundationGateHttpResponse>{'/events': _ok(calendarBody())},
      postResponses: <String, FoundationGateHttpResponse>{
        '/attendance': _status(409),
      },
    );
    final answer = await _authorityFor(transport).recordAttendance(
      eventId: _eventId,
      childId: _childId,
      attended: true,
      idempotencyKey: () => 'key-attendance-2',
    );
    expect(answer.status, CalendarAuthorityStatus.refused);
    expect(answer.value, isNull);
  });

  test('an unreachable server moves nothing at all', () async {
    final transport = _Transport(<String, FoundationGateHttpResponse>{
      '/events': _ok(calendarBody()),
    })..failure = StateError('socket closed');
    final answer = await _authorityFor(
      transport,
    ).listEvents(from: _from, to: _to);
    expect(answer.status, CalendarAuthorityStatus.unreachable);
    expect(answer.value, isNull);
  });

  test('an access refusal is not retried and not softened', () async {
    final transport = _Transport(<String, FoundationGateHttpResponse>{
      '/events': _status(403),
    });
    final answer = await _authorityFor(
      transport,
    ).listEvents(from: _from, to: _to);
    expect(answer.status, CalendarAuthorityStatus.accessDenied);
    expect(
      transport.calls.length,
      1,
      reason: 'a refusal is an answer, not a retry hint',
    );
  });

  test('a server that answers with a shape this build cannot read is refused', () async {
    final transport = _Transport(<String, FoundationGateHttpResponse>{
      '/events': _ok(jsonEncode(<String, Object?>{'items': <Object?>[]})),
    });
    final answer = await _authorityFor(
      transport,
    ).listEvents(from: _from, to: _to);
    expect(answer.status, CalendarAuthorityStatus.refused);
  });
}
