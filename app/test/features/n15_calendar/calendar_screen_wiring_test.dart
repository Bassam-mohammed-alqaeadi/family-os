// W8 — the wiring itself, asserted where it can be seen: inside the calendar screen.
//
// The panel has a file of its own for what it says; this one proves the other half of the
// wave's standard - that the screen a guardian actually opens renders the week the SERVER
// holds, and renders it even when this build's own board is empty, because a family whose
// local board was cleared still has a Friday.
//
// It is deliberately small, and the third case is the one that earns its place here: the
// stage-1 identity hands out keys like `child_a`, which are not server identifiers. The panel
// still reads the family's week - the window asks about the family, not about a child - and it
// offers no form that would collect a plan it cannot record. Nothing is sent with a key the
// server never minted.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n15_calendar/calendar_server_authority.dart';
import 'package:family_os/features/n15_calendar/family_calendar_repository.dart';
import 'package:family_os/features/n15_calendar/family_calendar_screen.dart';

import 'support/calendar_fake_server.dart';

Future<void> _pump(
  WidgetTester tester, {
  required FamilyCalendarRepository repository,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildFamilyTheme(),
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: FamilyCalendarScreen(
        repository: repository,
        roleOverride: AppRole.father,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

FakeCalendarEvent _dinner() {
  final start = DateTime.now().toUtc().add(const Duration(hours: 30));
  return FakeCalendarEvent(
    id: eventId,
    title: 'عشاء عند الجدّ',
    startsAt: start,
    endsAt: start.add(const Duration(hours: 2)),
    location: 'بيت الجدّ',
    reminderMinutes: 60,
    audience: [FakeAudience(childId: childId)],
  );
}

void main() {
  tearDown(() => bindCalendarServerAuthority(null));

  testWidgets('a bound session puts the server week on the screen, even with an empty local board', (tester) async {
    final server = CalendarFakeServer(events: [_dinner()]);
    bindCalendarServerAuthority(calendarAuthorityFor(server));
    await _pump(
      tester,
      repository: InMemoryFamilyCalendarRepository(
        seed: familyCalendarEmptyFixture(),
      ),
    );

    expect(
      find.byKey(const Key('calendar_server_panel')),
      findsOneWidget,
      reason: 'the wave is only delivered when the surface a family opens carries it',
    );
    expect(
      find.byKey(const Key('calendar_server_events_card')),
      findsOneWidget,
      reason: 'and it is the server\'s week, drawn although this build\'s own board is empty',
    );
    expect(find.text('عشاء عند الجدّ'), findsOneWidget);
    expect(
      server.calls,
      contains('GET /v1/families/$familyId/events'),
      reason: 'the week on screen came from the server, not from the local fixture',
    );
  });

  testWidgets('a build with no session shows no panel and no server week at all', (tester) async {
    await _pump(
      tester,
      repository: InMemoryFamilyCalendarRepository(
        seed: familyCalendarOneFixture(),
      ),
    );

    expect(find.byKey(const Key('calendar_server_panel')), findsNothing);
    expect(find.byKey(const Key('calendar_server_events_card')), findsNothing);
    expect(
      find.byKey(FamilyCalendarKeys.body),
      findsOneWidget,
      reason: 'the local calendar is still there - it is just not presented as the server\'s',
    );
  });

  testWidgets('children this build cannot address: the week reads, and nothing is written', (tester) async {
    // The stage-1 roster keys are `child_a` / `child_b`: local identity, not server rows.
    final server = CalendarFakeServer(events: [_dinner()]);
    bindCalendarServerAuthority(calendarAuthorityFor(server));
    await _pump(
      tester,
      repository: InMemoryFamilyCalendarRepository(
        seed: familyCalendarOneFixture(),
      ),
    );

    expect(
      find.byKey(const Key('calendar_server_events_card')),
      findsOneWidget,
      reason: 'the window asks about the family: a family with a Friday still reads it',
    );
    expect(find.byKey(const Key('calendar_server_read_only_note')), findsOneWidget);
    expect(find.byKey(const Key('calendar_server_create_card')), findsNothing);
    expect(find.byKey(const Key('calendar_server_cancel_$eventId')), findsNothing);
    expect(
      find.byKey(const Key('calendar_server_unreachable')),
      findsNothing,
      reason: 'a gap in this build\'s identity is not a broken connection',
    );
    expect(
      server.calls.where((call) => call.startsWith('POST')),
      isEmpty,
      reason: 'a path built from a local key would be a guess sent to a real server',
    );
  });
}
