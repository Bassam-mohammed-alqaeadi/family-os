// W8 — the calendar test server: one family, two children, plans that change.
//
// A write mutates this object before answering, so a surface that re-reads after a write sees
// the change it just made. That matters here more than in W7: the panel's whole claim is that
// a cancellation keeps its reason, that a child's answer survives an edit, and that a refused
// write leaves the last true reading alone - and a transport with canned answers would let a
// screen that showed a stale calendar pass every one of those checks.
//
// It is shared by the panel tests and the wiring test on purpose: two fakes would drift, and
// the one that drifted would be the one that stopped catching the bug.
import 'dart:convert';

import 'package:family_os/features/n15_calendar/calendar_server_authority.dart';
import 'package:family_os/foundation_gate/family_calendar_api_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_configuration.dart';
import 'package:family_os/foundation_gate/foundation_gate_http.dart';

const familyId = '11111111-1111-4111-8111-111111111111';
const childId = '22222222-2222-4222-8222-222222222222';
const siblingId = '33333333-3333-4333-8333-333333333333';
const eventId = '44444444-4444-4444-8444-444444444444';
const beganEventId = '55555555-5555-4555-8555-555555555555';
const swimEventId = '66666666-6666-4666-8666-666666666666';
const membershipId = '77777777-7777-4777-8777-777777777777';

/// An authority bound to [server], the way the app binds one at boot.
CalendarServerAuthority calendarAuthorityFor(CalendarFakeServer server) =>
    CalendarServerAuthority(
      api: FamilyCalendarApiClient(
        configuration: FoundationGateConfiguration.fromStagingApiOrigin(
          Uri.parse('https://staging.example.test'),
        ),
        transport: server,
      ),
      idToken: () async => 'test-token',
      familyId: () => familyId,
    );

/// One child's place on one event: what they answered, and what actually happened.
final class FakeAudience {
  FakeAudience({required this.childId});

  final String childId;
  String? answer;
  String answerNote = '';
  String? respondedByMembershipId;
  bool? attended;
  String attendanceNote = '';

  Map<String, Object?> toJson() => <String, Object?>{
    'childId': childId,
    'response': answer == null
        ? null
        : <String, Object?>{
            'childId': childId,
            'response': answer,
            'note': answerNote,
            'respondedByDeviceId': null,
            'respondedByMembershipId': respondedByMembershipId,
            'respondedAt': '2026-10-08T07:30:00.000Z',
          },
    'attendance': attended == null
        ? null
        : <String, Object?>{
            'childId': childId,
            'attended': attended,
            'note': attendanceNote,
            'recordedByMembershipId': membershipId,
            'recordedAt': '2026-10-08T09:30:00.000Z',
          },
  };
}

/// One event, with everything the database would hold about it.
final class FakeCalendarEvent {
  FakeCalendarEvent({
    required this.id,
    required this.title,
    required this.startsAt,
    required this.endsAt,
    required this.audience,
    this.note = '',
    this.location = '',
    this.reminderMinutes,
    this.status = 'scheduled',
    this.version = 1,
    this.cancelReason = '',
  });

  final String id;
  String title;
  String note;
  String location;
  DateTime startsAt;
  DateTime endsAt;
  int? reminderMinutes;
  String status;
  int version;
  String cancelReason;
  String? cancelledByMembershipId;
  String? cancelledAt;
  final List<FakeAudience> audience;

  bool get isCancelled => status == 'cancelled';

  FakeAudience? audienceFor(String child) {
    for (final entry in audience) {
      if (entry.childId == child) return entry;
    }
    return null;
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'title': title,
    'note': note,
    'location': location,
    'startsAt': startsAt.toUtc().toIso8601String(),
    'endsAt': endsAt.toUtc().toIso8601String(),
    'allDay': false,
    'reminderMinutes': reminderMinutes,
    'status': status,
    'version': version,
    'createdByMembershipId': membershipId,
    'cancelledByMembershipId': cancelledByMembershipId,
    'cancelledAt': cancelledAt,
    'cancelReason': cancelReason,
    'createdAt': '2026-10-07T18:00:00.000Z',
    'updatedAt': '2026-10-08T06:00:00.000Z',
    'audience': audience.map((entry) => entry.toJson()).toList(),
  };
}

/// The server, small enough to read and honest enough to catch a stale screen.
final class CalendarFakeServer implements FoundationGateHttpTransport {
  CalendarFakeServer({DateTime? now, List<FakeCalendarEvent>? events})
    : now = now ?? DateTime.now().toUtc(),
      events = events ?? <FakeCalendarEvent>[];

  /// The instant this server believes it is. Attendance and answering are both time rules,
  /// and a test that waited for a real evening would be a test nobody runs.
  final DateTime now;
  final List<FakeCalendarEvent> events;

  /// When set, every write is refused with this status instead of applied: a refused write
  /// must leave the state alone.
  int? refuseWriteWith;
  Object? networkFailure;

  final List<String> calls = <String>[];
  final List<String> bodies = <String>[];
  final List<String?> keys = <String?>[];

  FoundationGateHttpResponse _ok(Map<String, Object?> body, [int status = 200]) =>
      FoundationGateHttpResponse(statusCode: status, body: jsonEncode(body));

  FoundationGateHttpResponse _refused() =>
      FoundationGateHttpResponse(
        statusCode: refuseWriteWith!,
        body: jsonEncode(<String, Object?>{'error': 'refused'}),
      );

  FakeCalendarEvent? _byId(String id) {
    for (final event in events) {
      if (event.id == id) return event;
    }
    return null;
  }

  FoundationGateHttpResponse _get(Uri uri) {
    // What the family agreed to do, inside the window the screen asked for. Both ends of the
    // window are honoured, because a screen that widened its own read would be inventing
    // plans the server never returned.
    final from = DateTime.parse(uri.queryParameters['from']!);
    final to = DateTime.parse(uri.queryParameters['to']!);
    final inside = events
        .where(
          (event) =>
              !event.startsAt.isBefore(from) && !event.startsAt.isAfter(to),
        )
        .map((event) => event.toJson())
        .toList();
    return _ok(<String, Object?>{'events': inside});
  }

  FoundationGateHttpResponse _write(Uri uri, Map<String, Object?>? post) {
    if (refuseWriteWith != null) return _refused();
    final path = uri.path;

    if (path.endsWith('/events') && post != null) {
      final childIds = (post['childIds']! as List).cast<String>();
      final created = FakeCalendarEvent(
        id: 'abcdefab-cdef-4abc-8def-abcdefabcdef',
        title: post['title']! as String,
        note: post['note'] as String? ?? '',
        location: post['location'] as String? ?? '',
        startsAt: DateTime.parse(post['startsAt']! as String),
        endsAt: DateTime.parse(post['endsAt']! as String),
        reminderMinutes: post['reminderMinutes'] as int?,
        audience: [
          for (final child in childIds) FakeAudience(childId: child),
        ],
      );
      events.add(created);
      return _ok(<String, Object?>{'event': created.toJson()}, 201);
    }

    if (path.contains('/events/') && path.endsWith('/cancel')) {
      final event = _byId(path.split('/events/')[1].split('/').first)!;
      if (event.isCancelled) {
        return FoundationGateHttpResponse(statusCode: 409, body: '{}');
      }
      event.status = 'cancelled';
      event.cancelReason = post!['reason']! as String;
      event.cancelledByMembershipId = membershipId;
      event.cancelledAt = '2026-10-08T08:00:00.000Z';
      event.version += 1;
      return _ok(<String, Object?>{'event': event.toJson()});
    }

    if (path.contains('/children/') && path.endsWith('/response')) {
      final child = path.split('/children/')[1].split('/').first;
      final id = path.split('/events/')[1].split('/').first;
      final event = _byId(id)!;
      final entry = event.audienceFor(child);
      if (entry == null) {
        return FoundationGateHttpResponse(statusCode: 403, body: '{}');
      }
      if (!event.startsAt.isAfter(now)) {
        // "Will you come" is over once the evening has begun: the server refuses, and it
        // refuses rather than storing an answer nobody could act on.
        return FoundationGateHttpResponse(statusCode: 409, body: '{}');
      }
      entry.answer = post!['response']! as String;
      entry.answerNote = post['note'] as String? ?? '';
      entry.respondedByMembershipId = membershipId;
      return _ok(<String, Object?>{'response': entry.toJson()['response']});
    }

    if (path.contains('/events/') && path.endsWith('/attendance')) {
      // What happened is recorded under the event, with the child stated in the body: the
      // route names one event, and the person recording says who it was about. Reading a child
      // out of this path would have been reading it out of nothing.
      final id = path.split('/events/')[1].split('/').first;
      final child = post!['childId'] as String;
      final event = _byId(id)!;
      final entry = event.audienceFor(child);
      if (entry == null || event.isCancelled) {
        return FoundationGateHttpResponse(statusCode: 403, body: '{}');
      }
      if (event.startsAt.isAfter(now)) {
        return FoundationGateHttpResponse(statusCode: 409, body: '{}');
      }
      entry.attended = post!['attended']! as bool;
      entry.attendanceNote = post['note'] as String? ?? '';
      return _ok(<String, Object?>{'attendance': entry.toJson()['attendance']});
    }

    throw StateError('the fake server was asked to write ${uri.path}');
  }

  @override
  Future<FoundationGateHttpResponse> get(
    Uri uri, {
    required Map<String, String> headers,
  }) async {
    if (networkFailure != null) throw networkFailure!;
    calls.add('GET ${uri.path}');
    return _get(uri);
  }

  @override
  Future<FoundationGateHttpResponse> post(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
  }) async {
    if (networkFailure != null) throw networkFailure!;
    calls.add('POST ${uri.path}');
    bodies.add(body);
    keys.add(headers['idempotency-key'] ?? headers['Idempotency-Key']);
    return _write(uri, jsonDecode(body) as Map<String, Object?>);
  }

  @override
  Future<FoundationGateHttpResponse> patch(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
  }) async {
    if (networkFailure != null) throw networkFailure!;
    calls.add('PATCH ${uri.path}');
    bodies.add(body);
    // The panel has no edit form: a plan is corrected by calling it off and stating a new
    // one, which is the correction a child can follow. An edit arriving here is a screen
    // this fake never learned to answer, and saying so beats answering wrongly.
    return _write(uri, jsonDecode(body) as Map<String, Object?>);
  }

  @override
  Future<FoundationGateHttpResponse> put(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
  }) async {
    calls.add('PUT ${uri.path}');
    bodies.add(body);
    return _write(uri, jsonDecode(body) as Map<String, Object?>);
  }
}
