import 'package:family_os/foundation_gate/family_calendar_api_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_configuration.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';

/// W8 — the family's calendar, or the honest statement that there was no answer.
///
/// The statuses are the five this codebase settled on in waves 4, 5 and 6, and they mean the
/// same thing here as everywhere else: nothing is invented to fill a gap, and there is no
/// `localFallback`. This wave gives the rule a sharper edge than the ones before it, because a
/// calendar is where a family product starts recording people rather than devices: a screen
/// that drew a plan nobody stated, an answer nobody gave or an attendance nobody recorded
/// would be inventing facts about children, and no amount of polish would make that true.
enum CalendarAuthorityStatus {
  /// The answer came from the server and means what it says.
  ready,

  /// This build has no server session. Nothing was asked, because there is nobody to ask.
  notConfigured,

  /// The server refused: this account may not read or change this family's calendar.
  accessDenied,

  /// The server is configured but did not answer. Nothing on the screen may move.
  unreachable,

  /// The server answered with a refusal that has a reason - an event already cancelled, an
  /// evening somebody else edited first, a fact that cannot be recorded yet - which the screen
  /// shows as it is.
  refused,
}

/// One answer from the server, or the honest statement that there was none.
class CalendarAuthorityAnswer<T> {
  const CalendarAuthorityAnswer._({required this.status, required this.value});

  const CalendarAuthorityAnswer.ready(T value)
    : this._(status: CalendarAuthorityStatus.ready, value: value);

  const CalendarAuthorityAnswer.unavailable(CalendarAuthorityStatus status)
    : this._(status: status, value: null);

  final CalendarAuthorityStatus status;
  final T? value;

  bool get isReady => status == CalendarAuthorityStatus.ready && value != null;
}

/// The calendar surface's one connection to the server.
///
/// Six operations, and every one of them is a question a family actually asks: what are we
/// doing, what changed, what was called off and why, who is coming, and what actually
/// happened. Two of them are deliberately narrow. `recordResponse` answers for ONE named
/// child, because a guardian recording what a child said is the author of that record - and
/// `recordAttendance` takes a verdict rather than a location, because presence inferred from
/// a phone is the surveillance this product refuses to be.
final class CalendarServerAuthority {
  CalendarServerAuthority({
    required this.api,
    required this.idToken,
    required this.familyId,
  });

  final FamilyCalendarApiClient api;
  final Future<String> Function() idToken;
  final String? Function() familyId;

  /// Whether this identifier can name a server row at all. A stage-1 key (`k1`) cannot: it is
  /// local identity, not a UUID the server ever minted. Nothing is asked with one, and the
  /// answer says this build has no session for that child rather than pretending the server
  /// refused a request it never heard about.
  static bool _addressable(String id) => isFoundationGateUuid(id.trim());

  CalendarAuthorityAnswer<T> _noSession<T>() =>
      CalendarAuthorityAnswer<T>.unavailable(CalendarAuthorityStatus.notConfigured);

  /// What the family agreed to do, inside the window the caller states. The window is a
  /// parameter and not a default here on purpose: "everything" is not a question this surface
  /// asks, and a caller that wants a month should say a month.
  Future<CalendarAuthorityAnswer<FoundationGateFamilyCalendar>> listEvents({
    required DateTime from,
    required DateTime to,
  }) => _ask(
    (family, token) => api.listEvents(
      familyId: family,
      from: from,
      to: to,
      idToken: token,
    ),
  );

  Future<CalendarAuthorityAnswer<FoundationGateFamilyEvent>> createEvent({
    required String title,
    required DateTime startsAt,
    required DateTime endsAt,
    List<String> childIds = const <String>[],
    String? audienceThreadId,
    String note = '',
    String location = '',
    bool allDay = false,
    int? reminderMinutes,
    required String Function() idempotencyKey,
  }) async {
    if (!childIds.every(_addressable) ||
        (audienceThreadId != null && !_addressable(audienceThreadId))) {
      return _noSession();
    }
    return _ask(
      (family, token) => api.createEvent(
        familyId: family,
        title: title,
        note: note,
        location: location,
        startsAt: startsAt,
        endsAt: endsAt,
        allDay: allDay,
        reminderMinutes: reminderMinutes,
        childIds: childIds,
        audienceThreadId: audienceThreadId,
        idempotencyKey: idempotencyKey(),
        idToken: token,
      ),
    );
  }

  /// A change to a plan. The version is required, so a screen cannot send an edit that does
  /// not say which state of the evening it is editing.
  Future<CalendarAuthorityAnswer<FoundationGateFamilyEvent>> updateEvent({
    required String eventId,
    required int version,
    String? title,
    String? note,
    String? location,
    DateTime? startsAt,
    DateTime? endsAt,
    bool? allDay,
    int? reminderMinutes,
    List<String>? childIds,
    String? audienceThreadId,
    bool clearAudienceThreadId = false,
  }) async {
    if (!_addressable(eventId) ||
        (audienceThreadId != null && !_addressable(audienceThreadId)) ||
        !((childIds ?? const <String>[]).every(_addressable))) {
      return _noSession();
    }
    return _ask(
      (family, token) => api.updateEvent(
        familyId: family,
        eventId: eventId,
        version: version,
        title: title,
        note: note,
        location: location,
        startsAt: startsAt,
        endsAt: endsAt,
        allDay: allDay,
        reminderMinutes: reminderMinutes,
        childIds: childIds,
        audienceThreadId: audienceThreadId,
        clearAudienceThreadId: clearAudienceThreadId,
        idToken: token,
      ),
    );
  }

  /// Calling an event off. The answer is the cancelled event with its reason and its answers
  /// still attached - which is what the screen draws, instead of removing the row.
  Future<CalendarAuthorityAnswer<FoundationGateFamilyEvent>> cancelEvent({
    required String eventId,
    required String reason,
    required String Function() idempotencyKey,
  }) async {
    if (!_addressable(eventId)) return _noSession();
    return _ask(
      (family, token) => api.cancelEvent(
        familyId: family,
        eventId: eventId,
        reason: reason,
        idempotencyKey: idempotencyKey(),
        idToken: token,
      ),
    );
  }

  /// What happened, stated by a guardian after the event started. The key is required because
  /// `recordedAt` is part of the fact: a retried tap is the same record, not a new moment.
  Future<CalendarAuthorityAnswer<FoundationGateEventAttendance>> recordAttendance({
    required String eventId,
    required String childId,
    required bool attended,
    String note = '',
    required String Function() idempotencyKey,
  }) async {
    if (!_addressable(childId)) return _noSession();
    return _ask(
      (family, token) => api.recordAttendance(
        familyId: family,
        eventId: eventId,
        childId: childId,
        attended: attended,
        note: note,
        idempotencyKey: idempotencyKey(),
        idToken: token,
      ),
    );
  }

  /// The answer a child gave in words. One child per call: there is no method here that
  /// answers for "the children" as a group, because an answer belongs to a person.
  Future<CalendarAuthorityAnswer<FoundationGateEventResponse>> recordResponse({
    required String childId,
    required String eventId,
    required FoundationGateEventAnswer answer,
    String note = '',
    required String Function() idempotencyKey,
  }) async {
    if (!_addressable(childId)) return _noSession();
    return _ask(
      (family, token) => api.recordResponse(
        familyId: family,
        childId: childId,
        eventId: eventId,
        answer: answer,
        note: note,
        idempotencyKey: idempotencyKey(),
        idToken: token,
      ),
    );
  }

  Future<CalendarAuthorityAnswer<T>> _ask<T>(
    Future<T> Function(String family, String token) run,
  ) async {
    final family = familyId();
    if (family == null || !_addressable(family)) {
      // Nothing is asked, because there is nobody to ask: a screen bound without a session
      // is a screen that says so.
      return const CalendarAuthorityAnswer.unavailable(
        CalendarAuthorityStatus.notConfigured,
      );
    }
    String token;
    try {
      token = await idToken();
    } on Object {
      return const CalendarAuthorityAnswer.unavailable(
        CalendarAuthorityStatus.notConfigured,
      );
    }
    if (token.trim().isEmpty) {
      return const CalendarAuthorityAnswer.unavailable(
        CalendarAuthorityStatus.notConfigured,
      );
    }
    try {
      return CalendarAuthorityAnswer.ready(await run(family, token));
    } on ArgumentError {
      // The route refused to be built - a window that runs backwards, an event identifier
      // this build does not have, an event with nobody invited. Nothing was asked, and
      // reporting `unreachable` would blame the network for this build's own gap.
      return const CalendarAuthorityAnswer.unavailable(
        CalendarAuthorityStatus.refused,
      );
    } on FoundationGateApiException catch (exception) {
      return CalendarAuthorityAnswer.unavailable(
        switch (exception.failure) {
          FoundationGateApiFailure.unauthenticated ||
          FoundationGateApiFailure.accessDenied =>
            CalendarAuthorityStatus.accessDenied,
          FoundationGateApiFailure.networkUnavailable =>
            CalendarAuthorityStatus.unreachable,
          _ => CalendarAuthorityStatus.refused,
        },
      );
    } on Object {
      return const CalendarAuthorityAnswer.unavailable(
        CalendarAuthorityStatus.unreachable,
      );
    }
  }
}

CalendarServerAuthority? _activeCalendarAuthority;

/// The authority the calendar screens read, or null when no server session is bound.
CalendarServerAuthority? get activeCalendarServerAuthority =>
    _activeCalendarAuthority;

/// Binds every calendar surface to one server session, or clears them all.
///
/// One call site, at boot: the plans a family reads, the changes they make, the cancellations
/// they explain and the facts they record all move together - a build that recorded an
/// attendance through one path while reading the evening through another would be two
/// products wearing one screen.
void bindCalendarServerAuthority(CalendarServerAuthority? authority) {
  _activeCalendarAuthority = authority;
}
