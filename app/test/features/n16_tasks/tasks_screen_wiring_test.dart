// W7 — the wiring itself, asserted where it can be seen: inside the tasks screen.
//
// The panel has a file of its own for what it says; this one proves the other half of the
// wave's standard, which is that the screen a guardian actually opens renders the server's
// tasks and points when a session is bound - and does not quietly show a balance when none is.
//
// It is deliberately small. A wiring test that re-tested the panel would be a second copy of
// the panel's own tests, and the copy is the one that goes stale.
//
// The third case is the one that earned its place: a child identifier this build cannot put in
// a URL must read as "there is nobody to ask", not as "the server did not answer". CI found
// that one - the panel was reporting a local identity gap as an unreachable server.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n16_tasks/family_tasks_repository.dart';
import 'package:family_os/features/n16_tasks/family_tasks_screen.dart';
import 'package:family_os/features/n16_tasks/tasks_server_authority.dart';

import 'support/tasks_fake_server.dart';

Future<void> _pump(
  WidgetTester tester, {
  required ChildId child,
  FamilyTasksRepository? repository,
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
      home: FamilyTasksScreen(
        childId: child,
        repository: repository,
        roleOverride: AppRole.father,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

FamilyTasksRepository get _board =>
    InMemoryFamilyTasksRepository(seed: familyTasksOneFixture());

void main() {
  tearDown(() => bindTasksServerAuthority(null));

  testWidgets('a bound session puts the server panel on the screen the guardian opens', (tester) async {
    final server = TasksFakeServer(points: 15)..pointsAwarded = 15;
    bindTasksServerAuthority(tasksAuthorityFor(server));
    await _pump(tester, child: ChildId(childId), repository: _board);

    expect(
      find.byKey(const Key('tasks_server_panel')),
      findsOneWidget,
      reason: 'the wave is only delivered when the surface a family opens carries it',
    );
    expect(
      tester
          .widget<Text>(find.byKey(const Key('tasks_server_points_total')))
          .data,
      '15',
      reason: 'and the number on it is the server number, not a local one',
    );
    expect(
      find.byKey(const Key('tasks_server_task_$taskId')),
      findsOneWidget,
      reason: 'the task the server holds is on the screen beside the balance',
    );
  });

  testWidgets('a build with no session shows no panel and no balance at all', (tester) async {
    await _pump(tester, child: ChildId(childId), repository: _board);

    expect(find.byKey(const Key('tasks_server_panel')), findsNothing);
    expect(find.byKey(const Key('tasks_server_points_total')), findsNothing);
    expect(
      find.byKey(FamilyTasksKeys.body),
      findsOneWidget,
      reason: 'the local board is still there - it is just not presented as the server',
    );
  });

  testWidgets('a child this build cannot address says so, instead of blaming the server', (tester) async {
    // The stage-1 identity hands out keys like `k1`, which are not server identifiers. Nothing
    // can be asked about such a child, and the honest answer is the one a family can act on:
    // this build has no session for them - not "your connection is broken".
    final server = TasksFakeServer(points: 15)..pointsAwarded = 15;
    bindTasksServerAuthority(tasksAuthorityFor(server));
    await _pump(tester, child: ChildId('k1'), repository: _board);

    expect(find.byKey(const Key('tasks_server_panel')), findsOneWidget);
    expect(find.byKey(const Key('tasks_server_notConfigured')), findsOneWidget);
    expect(find.byKey(const Key('tasks_server_unreachable')), findsNothing);
    expect(find.byKey(const Key('tasks_server_points_total')), findsNothing);
    expect(
      server.calls,
      isEmpty,
      reason: 'and nothing was sent anywhere: a path built from that key would be a guess',
    );
  });
}
