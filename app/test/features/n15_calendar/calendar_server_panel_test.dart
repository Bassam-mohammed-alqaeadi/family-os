// W8 — the calendar panel, rendered and wired.
//
// This is the surface a guardian actually keeps the family's week on, so it is rendered for
// real over a real `CalendarServerAuthority` talking to a transport that behaves like the
// database: a write changes what the next read returns, a cancellation keeps its reason, and a
// refused write changes nothing at all. That last one is why the fake mutates rather than
// answers from a script - the panel re-reads after every accepted write, and a canned transport
// would let a screen that showed a stale calendar pass.
//
// Every test is a way this screen could lie:
//
//   * with no session bound it shows the sentence saying so, and no calendar at all - no form
//     that collects a plan it cannot record;
//   * an evening is drawn with who was invited and where each of them stands, waiting included:
//     a blank is a person who has not answered, not a person who is not coming;
//   * an evening that was called off STAYS on screen with its reason - a calendar that hid a
//     cancellation would leave a child waiting at a door;
//   * the reminder line says a reminder is a recorded preference, because nothing here knows
//     whether a phone ever buzzed;
//   * answering is offered only for evenings that have not started, and recording what happened
//     only for evenings that have - and neither is sent until a guardian has named the evening
//     and the child;
//   * a refused write keeps the last true reading on screen and says that it is the last one;
//   * a reader without edit rights is offered nothing that writes, and still sees the week;
//   * calling an evening off needs a reason, and that reason is what the screen then shows;
//   * and the longest Arabic sentences on this surface fit the phone a father holds.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n15_calendar/calendar_server_authority.dart';
import 'package:family_os/features/n15_calendar/calendar_server_panel.dart';

import 'support/calendar_fake_server.dart';

Future<void> _tapKey(WidgetTester tester, Key key) async {
  final finder = find.byKey(key);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _choose(WidgetTester tester, Key key, String label) async {
  await _tapKey(tester, key);
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

Future<void> _pump(
  WidgetTester tester, {
  CalendarServerAuthority? authority,
  CalendarFakeServer? server,
  bool canEdit = true,
}) async {
  // Either an authority is handed in, or a fake server is turned into one, or neither - and
  // "neither" is a build with no session, which is a state this panel has to survive.
  final bound = authority ?? (server == null ? null : calendarAuthorityFor(server));
  await tester.pumpWidget(
    MaterialApp(
      theme: buildFamilyTheme(),
      locale: const Locale('ar'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: SingleChildScrollView(
          child: CalendarServerPanel(
            children: [
              CalendarChild(id: ChildId(childId), label: 'سارة'),
              CalendarChild(id: ChildId(siblingId), label: 'نورة'),
            ],
            authority: bound,
            canEdit: canEdit,
            idempotencyKey: () => 'w8-widget-key',
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// One evening, relative to now, so the time rules the panel applies are the real ones.
FakeCalendarEvent _event({
  String id = eventId,
  String title = 'عشاء عند الجدّ',
  Duration startsIn = const Duration(hours: 26),
  Duration lasts = const Duration(hours: 2),
  String location = 'بيت الجدّ',
  int? reminder = 60,
  List<String> children = const [childId, siblingId],
  String status = 'scheduled',
  String cancelReason = '',
  String? answeredBy,
  String answer = 'accepted',
  String answerNote = '',
}) {
  final start = DateTime.now().toUtc().add(startsIn);
  return FakeCalendarEvent(
    id: id,
    title: title,
    startsAt: start,
    endsAt: start.add(lasts),
    location: location,
    reminderMinutes: reminder,
    status: status,
    cancelReason: cancelReason,
    audience: [
      for (final child in children)
        FakeAudience(childId: child)
          ..answer = child == answeredBy ? answer : null
          ..answerNote = child == answeredBy ? answerNote : ''
          ..respondedByMembershipId = child == answeredBy ? membershipId : null,
    ],
  );
}

void main() {
  tearDown(() => bindCalendarServerAuthority(null));

  testWidgets('without a session the panel says so, and offers nothing that writes', (tester) async {
    await _pump(tester);

    expect(find.byKey(const Key('calendar_server_notConfigured')), findsOneWidget);
    expect(find.byKey(const Key('calendar_server_events_card')), findsNothing);
    expect(
      find.byKey(const Key('calendar_server_create_card')),
      findsNothing,
      reason: 'a form that writes is not offered when there is nowhere to write',
    );
  });

  testWidgets('an evening is drawn with who was invited and where each of them stands', (tester) async {
    final server = CalendarFakeServer(
      events: [
        _event(answeredBy: childId),
        _event(
          id: swimEventId,
          title: 'تدريب السباحة',
          startsIn: const Duration(hours: 50),
          children: const [siblingId],
        ),
      ],
    );
    await _pump(tester, server: server);

    expect(find.byKey(const Key('calendar_server_events_card')), findsOneWidget);
    expect(find.byKey(const Key('calendar_server_event_$eventId')), findsOneWidget);
    expect(find.text('عشاء عند الجدّ'), findsOneWidget);
    expect(find.text('بيت الجدّ'), findsOneWidget);
    expect(find.text('سارة: سيأتي'), findsOneWidget);
    expect(
      find.text('نورة: لم يجب بعد'),
      findsWidgets,
      reason: 'a blank is a person who has not answered - not a person who is not coming',
    );
    expect(
      find.byKey(const Key('calendar_server_events_empty')),
      findsNothing,
      reason: 'an empty sentence beside two evenings would be the screen contradicting itself',
    );
    expect(
      find.byKey(const Key('calendar_server_reminder_note')),
      findsOneWidget,
      reason: 'a reminder is a preference this screen recorded, not a delivery it can claim',
    );
  });

  testWidgets('an evening that was called off stays on screen with its reason', (tester) async {
    final server = CalendarFakeServer(
      events: [
        _event(
          status: 'cancelled',
          cancelReason: 'الجدّ تعب',
          id: eventId,
        ),
      ],
    );
    await _pump(tester, server: server);

    expect(
      find.byKey(const Key('calendar_server_event_$eventId')),
      findsOneWidget,
      reason: 'a cancellation is news a child needs, not a row to remove',
    );
    expect(find.byKey(const Key('calendar_server_event_cancelled_$eventId')), findsOneWidget);
    expect(find.text('سبب الإلغاء: الجدّ تعب'), findsOneWidget);
    expect(
      find.byKey(const Key('calendar_server_cancel_$eventId')),
      findsNothing,
      reason: 'an evening that was already called off cannot be called off again',
    );
  });

  testWidgets('an answer is recorded for one named child, and a tap before naming sends nothing', (tester) async {
    final server = CalendarFakeServer(events: [_event()]);
    await _pump(tester, server: server);

    // Nothing is selected: the guardian has not said whose answer this is, so no request is
    // built. A screen that guessed the child would be putting words in their mouth.
    await _tapKey(tester, const Key('calendar_server_answer_yes'));
    expect(server.calls.where((call) => call.startsWith('POST')), isEmpty);

    await _choose(tester, const Key('calendar_server_answer_event'), 'عشاء عند الجدّ');
    await _choose(tester, const Key('calendar_server_answer_child'), 'سارة');
    await tester.enterText(
      find.byKey(const Key('calendar_server_answer_note')),
      'قال إنه يريد أن يذهب',
    );
    await _tapKey(tester, const Key('calendar_server_answer_yes'));

    final sent = jsonDecode(server.bodies.last) as Map<String, Object?>;
    expect(sent['response'], 'accepted');
    expect(sent['note'], 'قال إنه يريد أن يذهب');
    expect(
      server.calls,
      contains('POST /v1/families/$familyId/children/$childId/events/$eventId/response'),
      reason: 'the answer belongs to one child, named in the path as well as the body',
    );
    expect(server.keys.last, 'w8-widget-key');
    expect(server.events.single.audienceFor(childId)!.answer, 'accepted');
    expect(
      server.events.single.audienceFor(siblingId)!.answer,
      isNull,
      reason: 'recording one child\'s answer never answers for a sibling',
    );
    expect(
      server.calls.where((call) => call == 'GET /v1/families/$familyId/events').length,
      2,
      reason: 'the panel asked the server again instead of trusting its own write',
    );
    expect(find.text('سارة: سيأتي'), findsOneWidget);
  });

  testWidgets('what happened is recorded by a person, after the evening began', (tester) async {
    final server = CalendarFakeServer(
      events: [
        _event(
          startsIn: const Duration(hours: -2),
          lasts: const Duration(hours: 4),
        ),
      ],
    );
    await _pump(tester, server: server);

    await _choose(tester, const Key('calendar_server_attendance_event'), 'عشاء عند الجدّ');
    await _choose(tester, const Key('calendar_server_attendance_child'), 'سارة');
    await tester.enterText(
      find.byKey(const Key('calendar_server_attendance_note')),
      'وصل متأخراً',
    );
    await _tapKey(tester, const Key('calendar_server_attendance_present'));

    final sent = jsonDecode(server.bodies.last) as Map<String, Object?>;
    expect(sent['attended'], isTrue);
    expect(sent['note'], 'وصل متأخراً');
    expect(
      sent.containsKey('location'),
      isFalse,
      reason: 'presence is a person\'s word, never a location read off a phone',
    );
    expect(server.calls.last, 'GET /v1/families/$familyId/events');
    expect(find.text('سارة: حضر'), findsOneWidget);
  });

  testWidgets('a refused write keeps the last true reading, and says that it is the last one', (tester) async {
    final server = CalendarFakeServer(events: [_event()])..refuseWriteWith = 409;
    await _pump(tester, server: server);

    await _choose(tester, const Key('calendar_server_answer_event'), 'عشاء عند الجدّ');
    await _choose(tester, const Key('calendar_server_answer_child'), 'سارة');
    await _tapKey(tester, const Key('calendar_server_answer_yes'));

    expect(find.byKey(const Key('calendar_server_refused')), findsOneWidget);
    expect(
      find.byKey(const Key('calendar_server_events_card')),
      findsOneWidget,
      reason: 'a refused write must not empty the week a family is looking at',
    );
    expect(find.text('سارة: لم يجب بعد'), findsOneWidget);
    expect(server.events.single.audienceFor(childId)!.answer, isNull);
  });

  testWidgets('an unreachable server moves nothing at all', (tester) async {
    final server = CalendarFakeServer(events: [_event()]);
    await _pump(tester, server: server);
    expect(find.text('سارة: لم يجب بعد'), findsOneWidget);

    server.networkFailure = StateError('socket closed');
    await _choose(tester, const Key('calendar_server_answer_event'), 'عشاء عند الجدّ');
    await _choose(tester, const Key('calendar_server_answer_child'), 'سارة');
    await _tapKey(tester, const Key('calendar_server_answer_yes'));

    expect(find.byKey(const Key('calendar_server_unreachable')), findsOneWidget);
    expect(find.byKey(const Key('calendar_server_events_card')), findsOneWidget);
    expect(find.text('سارة: لم يجب بعد'), findsOneWidget);
  });

  testWidgets('a reader without edit rights reads the week and is offered nothing that writes', (tester) async {
    final server = CalendarFakeServer(events: [_event(answeredBy: childId)]);
    await _pump(tester, server: server, canEdit: false);

    expect(find.byKey(const Key('calendar_server_create_card')), findsNothing);
    expect(find.byKey(const Key('calendar_server_answer_card')), findsNothing);
    expect(find.byKey(const Key('calendar_server_attendance_card')), findsNothing);
    expect(find.byKey(const Key('calendar_server_cancel_$eventId')), findsNothing);
    expect(find.byKey(const Key('calendar_server_read_only_note')), findsOneWidget);
    expect(
      find.text('سارة: سيأتي'),
      findsOneWidget,
      reason: 'a reader still reads: hiding the week would hide the family from them',
    );
    expect(server.calls.where((call) => call.startsWith('POST')), isEmpty);
  });

  testWidgets('calling an evening off needs a reason, and the reason is what remains on screen', (tester) async {
    final server = CalendarFakeServer(events: [_event()]);
    await _pump(tester, server: server);

    // A confirmation with no reason states nothing: the cancellation would be a fact a child
    // cannot understand, which is worse than the cancellation itself.
    await _tapKey(tester, const Key('calendar_server_cancel_$eventId'));
    await _tapKey(tester, const Key('calendar_server_cancel_confirm'));
    expect(server.calls.where((call) => call.startsWith('POST')), isEmpty);
    expect(server.events.single.isCancelled, isFalse);

    await _tapKey(tester, const Key('calendar_server_cancel_$eventId'));
    await tester.enterText(
      find.byKey(const Key('calendar_server_cancel_reason')),
      'الجدّ تعب',
    );
    await _tapKey(tester, const Key('calendar_server_cancel_confirm'));

    final sent = jsonDecode(server.bodies.last) as Map<String, Object?>;
    expect(sent['reason'], 'الجدّ تعب');
    expect(
      server.calls,
      contains('POST /v1/families/$familyId/events/$eventId/cancel'),
    );
    expect(server.events.single.cancelReason, 'الجدّ تعب');
    expect(find.byKey(const Key('calendar_server_event_cancelled_$eventId')), findsOneWidget);
    expect(find.text('سبب الإلغاء: الجدّ تعب'), findsOneWidget);
  });

  testWidgets('an evening that is not finished is not sent anywhere', (tester) async {
    final server = CalendarFakeServer(events: [_event()]);
    await _pump(tester, server: server);

    await tester.enterText(
      find.byKey(const Key('calendar_server_create_title')),
      'رحلة إلى الشاطئ',
    );
    final submit = tester.widget<FilledButton>(
      find.byKey(const Key('calendar_server_create_submit')),
    );

    expect(
      submit.onPressed,
      isNull,
      reason: 'a title without times or a named child is not a plan, and a form that would '
          'send one would be asking the server to refuse it',
    );
    expect(server.calls.where((call) => call.startsWith('POST')), isEmpty);
  });

  testWidgets('the panel fits a phone in Arabic - nothing runs off the edge', (tester) async {
    // The width that matters is the one a father holds: 360 logical pixels, right to left,
    // carrying the longest sentences on this surface - a cancelled evening with its reason, a
    // waiting invitation, and the three forms. An overflow throws during layout, so this test
    // IS the edge rather than a comment about it.
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final server = CalendarFakeServer(
      events: [
        _event(status: 'cancelled', cancelReason: 'الجدّ تعب فانتقل العشاء إلى الجمعة القادمة'),
        _event(
          id: beganEventId,
          title: 'زيارة المعرض مع المدرسة',
          startsIn: const Duration(hours: -3),
        ),
      ],
    );
    await _pump(tester, server: server);

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('calendar_server_events_card')), findsOneWidget);
    expect(find.byKey(const Key('calendar_server_answer_card')), findsOneWidget);
    expect(find.byKey(const Key('calendar_server_attendance_card')), findsOneWidget);
    expect(find.byKey(const Key('calendar_server_create_card')), findsOneWidget);
  });
}
