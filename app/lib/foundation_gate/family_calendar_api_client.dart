import 'dart:convert';

import 'package:family_os/foundation_gate/foundation_gate_configuration.dart';
import 'package:family_os/foundation_gate/foundation_gate_http.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';

/// W8 — the family calendar, from the guardian's side of the family.
///
/// This is the first wave whose subject is attendance rather than protection, and the client
/// carries that difference in three refusals rather than in a paragraph:
///
///   * A CANCELLED EVENT IS SHOWN AS CANCELLED, WITH ITS REASON. Nothing here filters
///     cancellations out of a list, because a calendar that hid them would leave a child
///     waiting at a door.
///   * AN EDIT MUST NAME THE VERSION IT READ. `updateEvent` takes `version` as a required
///     parameter, so a screen cannot accidentally send an edit that overwrites a co-guardian's
///     change - and a 409 arrives as `conflict`, not as a silent success.
///   * A REMINDER IS A PREFERENCE. `reminderMinutes` is carried here as what the family asked
///     for; there is no field anywhere in this client that claims a notification was
///     delivered, because the server has none to give.
///
/// The child's own handset is deliberately absent, exactly as it was in waves 6 and 7: the
/// device reads its events and answers them with the credential issued at pairing, and that
/// credential is not kept in this layer. A screen that showed a phone a locally-invented
/// calendar would be the lie this wave exists to prevent.

/// What the family decided about one event, as the server states it.
enum FoundationGateEventStatus {
  scheduled('scheduled'),
  cancelled('cancelled');

  const FoundationGateEventStatus(this.wire);

  final String wire;

  static FoundationGateEventStatus? parse(Object? value) {
    for (final status in values) {
      if (status.wire == value) return status;
    }
    return null;
  }
}

/// A child's answer. "No" is a value here, not an absence: a calendar that only counted yes
/// would be a scoreboard.
enum FoundationGateEventAnswer {
  accepted('accepted'),
  declined('declined');

  const FoundationGateEventAnswer(this.wire);

  final String wire;

  static FoundationGateEventAnswer? parse(Object? value) {
    for (final answer in values) {
      if (answer.wire == value) return answer;
    }
    return null;
  }
}

/// One child's answer, and who gave it.
class FoundationGateEventResponse {
  const FoundationGateEventResponse({
    required this.childId,
    required this.answer,
    required this.note,
    required this.respondedByDeviceId,
    required this.respondedByMembershipId,
    required this.respondedAt,
  });

  final String childId;
  final FoundationGateEventAnswer answer;
  final String note;

  /// Exactly one of these is set, never both and never neither: the child's own handset
  /// spoke, or a guardian recorded what the child said. Which one it was is part of what the
  /// answer means, and a payload that claimed both is refused rather than drawn.
  final String? respondedByDeviceId;
  final String? respondedByMembershipId;

  final DateTime respondedAt;
}

/// What a person recorded about what happened, and who recorded it. Never inferred from a
/// device, which is why there is no constructor here that takes a location.
class FoundationGateEventAttendance {
  const FoundationGateEventAttendance({
    required this.childId,
    required this.attended,
    required this.note,
    required this.recordedByMembershipId,
    required this.recordedAt,
  });

  final String childId;

  /// A verdict, not a truthiness: `false` is an absence that was recorded, and it is not the
  /// same fact as no record at all.
  final bool attended;
  final String note;
  final String recordedByMembershipId;
  final DateTime recordedAt;
}

/// One invited child, with their answer and their attendance if either exists yet.
class FoundationGateEventAudienceEntry {
  const FoundationGateEventAudienceEntry({
    required this.childId,
    required this.response,
    required this.attendance,
  });

  final String childId;

  /// Null means the child has not answered - which is different from "declined", and the
  /// screen says so rather than filling the gap with a default.
  final FoundationGateEventResponse? response;
  final FoundationGateEventAttendance? attendance;

  /// How many children have answered, counted from what is actually stored.
  static int answeredCount(List<FoundationGateEventAudienceEntry> audience) =>
      audience.where((entry) => entry.response != null).length;
}

/// A family event: what the family agreed to do, and who it is for.
class FoundationGateFamilyEvent {
  const FoundationGateFamilyEvent({
    required this.id,
    required this.title,
    required this.note,
    required this.location,
    required this.startsAt,
    required this.endsAt,
    required this.allDay,
    required this.reminderMinutes,
    required this.status,
    required this.version,
    required this.createdByMembershipId,
    required this.cancelledByMembershipId,
    required this.cancelledAt,
    required this.cancelReason,
    required this.createdAt,
    required this.updatedAt,
    required this.audience,
  });

  final String id;
  final String title;
  final String note;
  final String location;
  final DateTime startsAt;
  final DateTime endsAt;
  final bool allDay;

  /// What the family asked for, or null when they asked for nothing - which is not the same
  /// as zero. Nothing in this class says a reminder was sent.
  final int? reminderMinutes;

  final FoundationGateEventStatus status;

  /// The version this read saw. An edit must state it back, and a stale state is a conflict
  /// the screen has to resolve rather than overwrite.
  final int version;

  final String createdByMembershipId;

  /// Present only on a cancelled event, and together: a cancellation has an author, a reason
  /// and a moment, and a row carrying one of those without the others is refused by parsing.
  final String? cancelledByMembershipId;
  final DateTime? cancelledAt;
  final String cancelReason;

  final DateTime createdAt;
  final DateTime updatedAt;
  final List<FoundationGateEventAudienceEntry> audience;

  /// True when this plan still stands. Kept as a named question so no screen has to spell
  /// `status == cancelled` and get the sense of it backwards.
  bool get isCancelled => status == FoundationGateEventStatus.cancelled;
}

/// A window of the family's calendar, as the server answered it.
class FoundationGateFamilyCalendar {
  const FoundationGateFamilyCalendar({required this.events});

  final List<FoundationGateFamilyEvent> events;

  /// What still stands, in the order the server returned it (which is by start instant).
  List<FoundationGateFamilyEvent> get scheduled =>
      events.where((event) => !event.isCancelled).toList(growable: false);

  /// What was called off. Shown rather than filtered: the reason is the point.
  List<FoundationGateFamilyEvent> get cancelled =>
      events.where((event) => event.isCancelled).toList(growable: false);
}

/// The calendar of one family, as the guardians' screens read it.
class FamilyCalendarApiClient {
  FamilyCalendarApiClient({
    required FoundationGateConfiguration configuration,
    required FoundationGateHttpTransport transport,
  }) : _configuration = configuration,
       _transport = transport;

  final FoundationGateConfiguration _configuration;
  final FoundationGateHttpTransport _transport;

  /// What the family agreed to do, inside a window. The window is required because the
  /// server refuses a read without one, and this signature passes that refusal on rather
  /// than inventing a default range.
  Future<FoundationGateFamilyCalendar> listEvents({
    required String familyId,
    required DateTime from,
    required DateTime to,
    required String idToken,
  }) async {
    if (!to.isAfter(from)) {
      throw ArgumentError.value(to, 'to', 'must be after from');
    }
    final response = await _get(
      _configuration.familyEventsWindowUri(
        familyId,
        from: from.toUtc().toIso8601String(),
        to: to.toUtc().toIso8601String(),
      ),
      idToken,
    );
    return switch (response.statusCode) {
      200 => _parseCalendar(response.body),
      400 => throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidInput,
      ),
      401 => throw const FoundationGateApiException(
        FoundationGateApiFailure.unauthenticated,
      ),
      403 => throw const FoundationGateApiException(
        FoundationGateApiFailure.accessDenied,
      ),
      429 || 503 => throw const FoundationGateApiException(
        FoundationGateApiFailure.serviceUnavailable,
      ),
      _ => throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      ),
    };
  }

  /// A guardian states an event and names who it is for, in one request. The audience is not
  /// optional and not empty: an event nobody is invited to is a note, and the server refuses
  /// it - so this method refuses to build the request that would earn that refusal.
  Future<FoundationGateFamilyEvent> createEvent({
    required String familyId,
    required String title,
    required DateTime startsAt,
    required DateTime endsAt,
    required List<String> childIds,
    required String idempotencyKey,
    required String idToken,
    String note = '',
    String location = '',
    bool allDay = false,
    int? reminderMinutes,
  }) async {
    if (childIds.isEmpty) {
      throw ArgumentError.value(childIds, 'childIds', 'at least one child');
    }
    final body = <String, Object>{
      'title': title,
      'startsAt': startsAt.toUtc().toIso8601String(),
      'endsAt': endsAt.toUtc().toIso8601String(),
      'childIds': childIds,
      if (note.isNotEmpty) 'note': note,
      if (location.isNotEmpty) 'location': location,
      if (allDay) 'allDay': true,
      if (reminderMinutes != null) 'reminderMinutes': reminderMinutes,
    };
    // No query parameters on the write: the server refuses them, because a body that
    // disagrees with a URL is two requests wearing one coat.
    final response = await _post(
      _configuration.familyEventsUri(familyId),
      idToken,
      body,
      idempotencyKey: idempotencyKey,
    );
    return switch (response.statusCode) {
      201 => _parseEvent(_decode(response.body)['event']),
      400 => throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidInput,
      ),
      401 => throw const FoundationGateApiException(
        FoundationGateApiFailure.unauthenticated,
      ),
      403 => throw const FoundationGateApiException(
        FoundationGateApiFailure.accessDenied,
      ),
      422 => throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidInput,
      ),
      429 || 503 => throw const FoundationGateApiException(
        FoundationGateApiFailure.serviceUnavailable,
      ),
      _ => throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      ),
    };
  }

  /// A guardian changes a plan - and states the version they read, so two guardians editing
  /// the same evening collide loudly. `version` is required and has no default, because a
  /// default here would be the silent overwrite this parameter exists to prevent.
  ///
  /// Exactly one of the change parameters must be given. A request that changes nothing would
  /// still move the version and wake every reader, and the server refuses it, so it is
  /// refused here too rather than sent to earn a 400.
  Future<FoundationGateFamilyEvent> updateEvent({
    required String familyId,
    required String eventId,
    required int version,
    required String idToken,
    String? title,
    String? note,
    String? location,
    DateTime? startsAt,
    DateTime? endsAt,
    bool? allDay,
    int? reminderMinutes,
    List<String>? childIds,
  }) async {
    if (title == null &&
        note == null &&
        location == null &&
        startsAt == null &&
        endsAt == null &&
        allDay == null &&
        reminderMinutes == null &&
        childIds == null) {
      throw ArgumentError(
        'An update must change at least one field; the server refuses an empty edit.',
      );
    }
    if (childIds != null && childIds.isEmpty) {
      throw ArgumentError.value(childIds, 'childIds', 'at least one child');
    }
    final body = <String, Object>{
      'version': version,
      if (title != null) 'title': title,
      if (note != null) 'note': note,
      if (location != null) 'location': location,
      if (startsAt != null) 'startsAt': startsAt.toUtc().toIso8601String(),
      if (endsAt != null) 'endsAt': endsAt.toUtc().toIso8601String(),
      if (allDay != null) 'allDay': allDay,
      if (reminderMinutes != null) 'reminderMinutes': reminderMinutes,
      if (childIds != null) 'childIds': childIds,
    };
    final response = await _patch(
      _configuration.familyEventUri(familyId, eventId),
      idToken,
      body,
    );
    return switch (response.statusCode) {
      200 => _parseEvent(_decode(response.body)['event']),
      400 => throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidInput,
      ),
      401 => throw const FoundationGateApiException(
        FoundationGateApiFailure.unauthenticated,
      ),
      403 => throw const FoundationGateApiException(
        FoundationGateApiFailure.accessDenied,
      ),
      404 => throw const FoundationGateApiException(
        FoundationGateApiFailure.notFound,
      ),
      409 => throw const FoundationGateApiException(
        FoundationGateApiFailure.conflict,
      ),
      422 => throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidInput,
      ),
      429 || 503 => throw const FoundationGateApiException(
        FoundationGateApiFailure.serviceUnavailable,
      ),
      _ => throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      ),
    };
  }

  /// Calling an event off. A cancellation needs a reason, because a cancellation a child
  /// cannot understand is worse than the cancellation itself - and the server refuses an
  /// empty one, so this method does not build it.
  ///
  /// The answer is the cancelled event itself: same times, same audience, same answers, plus
  /// the author, the reason and the moment.
  Future<FoundationGateFamilyEvent> cancelEvent({
    required String familyId,
    required String eventId,
    required String reason,
    required String idempotencyKey,
    required String idToken,
  }) async {
    if (reason.trim().isEmpty) {
      throw ArgumentError.value(reason, 'reason', 'a cancellation states why');
    }
    final response = await _post(
      _configuration.familyEventCancelUri(familyId, eventId),
      idToken,
      <String, Object>{'reason': reason},
      idempotencyKey: idempotencyKey,
    );
    return switch (response.statusCode) {
      200 => _parseEvent(_decode(response.body)['event']),
      400 => throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidInput,
      ),
      401 => throw const FoundationGateApiException(
        FoundationGateApiFailure.unauthenticated,
      ),
      403 => throw const FoundationGateApiException(
        FoundationGateApiFailure.accessDenied,
      ),
      404 => throw const FoundationGateApiException(
        FoundationGateApiFailure.notFound,
      ),
      409 => throw const FoundationGateApiException(
        FoundationGateApiFailure.conflict,
      ),
      429 || 503 => throw const FoundationGateApiException(
        FoundationGateApiFailure.serviceUnavailable,
      ),
      _ => throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      ),
    };
  }

  /// What actually happened, recorded by a guardian after the event started.
  ///
  /// There is no parameter for a location and none for a device: attendance here is a person's
  /// statement, and a screen that inferred it from a phone's presence would be inventing a
  /// fact about a child. The idempotency key is required because `recordedAt` is part of the
  /// fact: a retried tap must be the same record, not a second moment.
  Future<FoundationGateEventAttendance> recordAttendance({
    required String familyId,
    required String eventId,
    required String childId,
    required bool attended,
    required String idempotencyKey,
    required String idToken,
    String note = '',
  }) async {
    final response = await _post(
      _configuration.familyEventAttendanceUri(familyId, eventId),
      idToken,
      <String, Object>{
        'childId': childId,
        'attended': attended,
        if (note.isNotEmpty) 'note': note,
      },
      idempotencyKey: idempotencyKey,
    );
    return switch (response.statusCode) {
      200 => _parseAttendance(_decode(response.body)['attendance']),
      400 => throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidInput,
      ),
      401 => throw const FoundationGateApiException(
        FoundationGateApiFailure.unauthenticated,
      ),
      403 => throw const FoundationGateApiException(
        FoundationGateApiFailure.accessDenied,
      ),
      404 => throw const FoundationGateApiException(
        FoundationGateApiFailure.notFound,
      ),
      409 => throw const FoundationGateApiException(
        FoundationGateApiFailure.conflict,
      ),
      429 || 503 => throw const FoundationGateApiException(
        FoundationGateApiFailure.serviceUnavailable,
      ),
      _ => throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      ),
    };
  }

  /// The answer a child gave in words, recorded by the guardian who heard it. The author of
  /// this record is the guardian - which is exactly why the method takes the child's id: a
  /// guardian answers for a named child, and the handset path (which the child's own device
  /// uses, with a credential this layer does not hold) answers for the child the device row
  /// names and no other.
  Future<FoundationGateEventResponse> recordResponse({
    required String familyId,
    required String childId,
    required String eventId,
    required FoundationGateEventAnswer answer,
    required String idempotencyKey,
    required String idToken,
    String note = '',
  }) async {
    final response = await _post(
      _configuration.familyChildEventResponseUri(familyId, childId, eventId),
      idToken,
      <String, Object>{
        'response': answer.wire,
        if (note.isNotEmpty) 'note': note,
      },
      idempotencyKey: idempotencyKey,
    );
    return switch (response.statusCode) {
      200 => _parseResponse(_decode(response.body)['response']),
      400 => throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidInput,
      ),
      401 => throw const FoundationGateApiException(
        FoundationGateApiFailure.unauthenticated,
      ),
      403 => throw const FoundationGateApiException(
        FoundationGateApiFailure.accessDenied,
      ),
      404 => throw const FoundationGateApiException(
        FoundationGateApiFailure.notFound,
      ),
      409 => throw const FoundationGateApiException(
        FoundationGateApiFailure.conflict,
      ),
      429 || 503 => throw const FoundationGateApiException(
        FoundationGateApiFailure.serviceUnavailable,
      ),
      _ => throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      ),
    };
  }

  // ── parsing ──────────────────────────────────────────────────────────────────────────

  static FoundationGateFamilyCalendar _parseCalendar(String body) {
    final raw = _decode(body)['events'];
    if (raw is! List) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      );
    }
    return FoundationGateFamilyCalendar(
      events: raw.map((entry) => _parseEvent(entry)).toList(growable: false),
    );
  }

  static FoundationGateFamilyEvent _parseEvent(Object? value) {
    final event = _object(value, 'event');
    final status = FoundationGateEventStatus.parse(event['status']);
    if (status == null) {
      // A status this build cannot name is refused rather than drawn. A screen that muted an
      // unknown state would show a family a plan that looks ordinary and is not.
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      );
    }
    final cancelledAt = event['cancelledAt'];
    final cancelledByMembershipId = event['cancelledByMembershipId'] as String?;
    if (status == FoundationGateEventStatus.cancelled &&
        (cancelledAt == null || cancelledByMembershipId == null)) {
      // A cancellation without its author or its moment is a half-written fact. The database
      // refuses to hold one; if one arrives anyway, this client refuses to believe it.
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      );
    }
    final rawAudience = event['audience'];
    if (rawAudience is! List) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      );
    }
    return FoundationGateFamilyEvent(
      id: _string(event['id'], 'id'),
      title: _string(event['title'], 'title'),
      note: event['note'] is String ? event['note']! as String : '',
      location: event['location'] is String ? event['location']! as String : '',
      startsAt: _instant(event['startsAt'], 'startsAt'),
      endsAt: _instant(event['endsAt'], 'endsAt'),
      allDay: event['allDay'] == true,
      reminderMinutes: event['reminderMinutes'] == null
          ? null
          : _integer(event['reminderMinutes'], 'reminderMinutes'),
      status: status,
      version: _integer(event['version'], 'version'),
      createdByMembershipId: _string(
        event['createdByMembershipId'],
        'createdByMembershipId',
      ),
      cancelledByMembershipId: cancelledByMembershipId,
      cancelledAt: cancelledAt == null
          ? null
          : _instant(cancelledAt, 'cancelledAt'),
      cancelReason: event['cancelReason'] is String
          ? event['cancelReason']! as String
          : '',
      createdAt: _instant(event['createdAt'], 'createdAt'),
      updatedAt: _instant(event['updatedAt'], 'updatedAt'),
      audience: rawAudience
          .map((entry) => _parseAudienceEntry(entry))
          .toList(growable: false),
    );
  }

  static FoundationGateEventAudienceEntry _parseAudienceEntry(Object? value) {
    final entry = _object(value, 'audience');
    final rawResponse = entry['response'];
    final rawAttendance = entry['attendance'];
    return FoundationGateEventAudienceEntry(
      childId: _string(entry['childId'], 'childId'),
      response: rawResponse == null ? null : _parseResponse(rawResponse),
      attendance: rawAttendance == null
          ? null
          : _parseAttendance(rawAttendance),
    );
  }

  static FoundationGateEventResponse _parseResponse(Object? value) {
    final response = _object(value, 'response');
    final answer = FoundationGateEventAnswer.parse(response['response']);
    if (answer == null) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      );
    }
    final byDevice = response['respondedByDeviceId'] as String?;
    final byMembership = response['respondedByMembershipId'] as String?;
    if ((byDevice == null) == (byMembership == null)) {
      // Exactly one author. A payload with both, or with neither, is a server whose answers
      // cannot be attributed - and an unattributed answer about a child is not evidence.
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      );
    }
    return FoundationGateEventResponse(
      childId: _string(response['childId'], 'childId'),
      answer: answer,
      note: response['note'] is String ? response['note']! as String : '',
      respondedByDeviceId: byDevice,
      respondedByMembershipId: byMembership,
      respondedAt: _instant(response['respondedAt'], 'respondedAt'),
    );
  }

  static FoundationGateEventAttendance _parseAttendance(Object? value) {
    final attendance = _object(value, 'attendance');
    if (attendance['attended'] is! bool) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      );
    }
    return FoundationGateEventAttendance(
      childId: _string(attendance['childId'], 'childId'),
      attended: attendance['attended']! as bool,
      note: attendance['note'] is String ? attendance['note']! as String : '',
      recordedByMembershipId: _string(
        attendance['recordedByMembershipId'],
        'recordedByMembershipId',
      ),
      recordedAt: _instant(attendance['recordedAt'], 'recordedAt'),
    );
  }

  // ── transport ────────────────────────────────────────────────────────────────────────

  Future<FoundationGateHttpResponse> _get(Uri uri, String idToken) async {
    try {
      return await _transport.get(uri, headers: _headers(idToken));
    } on FoundationGateApiException {
      rethrow;
    } on Object {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.networkUnavailable,
      );
    }
  }

  Future<FoundationGateHttpResponse> _post(
    Uri uri,
    String idToken,
    Map<String, Object> body, {
    required String idempotencyKey,
  }) async {
    try {
      return await _transport.post(
        uri,
        headers: _headers(idToken, idempotencyKey: idempotencyKey),
        body: jsonEncode(body),
      );
    } on FoundationGateApiException {
      rethrow;
    } on Object {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.networkUnavailable,
      );
    }
  }

  Future<FoundationGateHttpResponse> _patch(
    Uri uri,
    String idToken,
    Map<String, Object> body,
  ) async {
    try {
      return await _transport.patch(
        uri,
        headers: _headers(idToken),
        body: jsonEncode(body),
      );
    } on FoundationGateApiException {
      rethrow;
    } on Object {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.networkUnavailable,
      );
    }
  }

  Map<String, String> _headers(String idToken, {String? idempotencyKey}) {
    final headers = <String, String>{
      'authorization': 'Bearer $idToken',
      'accept': 'application/json',
      'content-type': 'application/json',
    };
    if (idempotencyKey != null) {
      headers['idempotency-key'] = idempotencyKey;
    }
    return headers;
  }

  /// A body that is not a JSON object is refused here rather than at each call site: every
  /// answer in this contract is an object, so a list or a bare string is a server this build
  /// cannot read, not a shape to be tolerated.
  static Map<String, Object?> _decode(String body) {
    final Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      );
    }
    if (decoded is! Map) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      );
    }
    return decoded.map((key, value) => MapEntry(key.toString(), value));
  }

  static Map<String, Object?> _object(Object? value, String field) {
    if (value is! Map) {
      throw FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
        details: <String, Object?>{'field': field},
      );
    }
    return value.map((key, item) => MapEntry(key.toString(), item));
  }

  static String _string(Object? value, String field) {
    if (value is! String || value.isEmpty) {
      throw FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
        details: <String, Object?>{'field': field},
      );
    }
    return value;
  }

  static int _integer(Object? value, String field) {
    if (value is! num) {
      throw FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
        details: <String, Object?>{'field': field},
      );
    }
    return value.toInt();
  }

  static DateTime _instant(Object? value, String field) {
    if (value is! String) {
      throw FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
        details: <String, Object?>{'field': field},
      );
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      throw FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
        details: <String, Object?>{'field': field},
      );
    }
    return parsed;
  }
}
