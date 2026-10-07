// W7 — the tasks panel, rendered and wired.
//
// This is the surface a guardian actually touches, so it is rendered for real over a real
// `TasksServerAuthority` talking to a transport that behaves like a server: a write changes
// what the next read returns, exactly as the database does. That matters here more than
// anywhere - the panel re-reads after every accepted write, and a fake that answered the same
// thing twice would hide a screen that shows a stale total.
//
// Every test is a way this screen could lie:
//
//   * with no session bound it shows no balance and no task list, only the sentence saying so;
//   * the balance it draws is the server's number with the entries that produced it;
//   * a claim waiting for an answer offers an answer, not points;
//   * confirming shows the number the SERVER returned, and a decline shows a refusal with the
//     balance unmoved - a refusal that quietly subtracted would be a different product;
//   * a refused write keeps the last true reading on screen instead of emptying it;
//   * a reader without edit rights is offered no button that writes;
//   * and the longest Arabic sentences on this surface fit the phone a father holds.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n16_tasks/tasks_server_authority.dart';
import 'package:family_os/features/n16_tasks/tasks_server_panel.dart';
import 'support/tasks_fake_server.dart';

Future<void> _tapKey(WidgetTester tester, Key key) async {
  final finder = find.byKey(key);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _pump(
  WidgetTester tester, {
  TasksServerAuthority? authority,
  bool canEdit = true,
}) async {
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
          child: TasksServerPanel(
            childId: ChildId(childId),
            authority: authority,
            canEdit: canEdit,
            idempotencyKey: () => 'w7-widget-key',
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

String _total(WidgetTester tester) => tester
    .widget<Text>(find.byKey(const Key('tasks_server_points_total')))
    .data!;

void main() {
  tearDown(() => bindTasksServerAuthority(null));

  testWidgets('without a session the panel shows no balance and no task list', (tester) async {
    await _pump(tester, authority: null);

    expect(find.byKey(const Key('tasks_server_notConfigured')), findsOneWidget);
    expect(find.byKey(const Key('tasks_server_points_card')), findsNothing);
    expect(find.byKey(const Key('tasks_server_tasks_card')), findsNothing);
    expect(
      find.byKey(const Key('tasks_server_create_card')),
      findsNothing,
      reason: 'a form that writes is not offered when there is nowhere to write',
    );
  });

  testWidgets('the balance is the server number, with the entry that produced it', (tester) async {
    final server = TasksFakeServer(points: 15, pointsAssigned: 15)..pointsAwarded = 15;
    await _pump(tester, authority: tasksAuthorityFor(server));

    expect(find.byKey(const Key('tasks_server_points_card')), findsOneWidget);
    expect(_total(tester), '15');
    expect(find.byKey(const Key('tasks_server_points_entry_$entryId')), findsOneWidget);
    expect(find.text('‏+15 نقطة — أكّدها أحد الوالدين.'), findsOneWidget);
    expect(find.byKey(const Key('tasks_server_points_empty')), findsNothing);
  });

  testWidgets('a child who has said nothing has said nothing - not "claimed"', (tester) async {
    final server = TasksFakeServer();
    await _pump(tester, authority: tasksAuthorityFor(server));

    expect(find.text('لم يقل الابن شيئًا بعد.'), findsOneWidget);
    expect(find.byKey(const Key('tasks_server_claim_$taskId')), findsOneWidget);
    expect(find.byKey(const Key('tasks_server_confirm_$taskId')), findsNothing);
  });

  testWidgets('the guardian can record the word the child gave them, and it becomes a claim', (tester) async {
    final server = TasksFakeServer();
    await _pump(tester, authority: tasksAuthorityFor(server));

    await _tapKey(tester, const Key('tasks_server_claim_$taskId'));

    expect(server.claimStatus, 'pending', reason: 'the server now holds a claim awaiting an answer');
    expect(find.text('قال الابن إنه أنجزها — بانتظار كلمتك.'), findsOneWidget);
    expect(find.byKey(const Key('tasks_server_confirm_$taskId')), findsOneWidget);
    expect(
      _total(tester),
      '0',
      reason: 'a claim is a claim: recording it awards nothing',
    );
  });

  testWidgets('confirming pays what the task says, and the panel re-reads the truth', (tester) async {
    final server = TasksFakeServer(claimStatus: 'pending');
    await _pump(tester, authority: tasksAuthorityFor(server));

    await tester.enterText(find.byKey(const Key('tasks_server_note_$taskId')), 'أحسنت');
    await _tapKey(tester, const Key('tasks_server_confirm_$taskId'));

    final sent = jsonDecode(server.bodies.last) as Map<String, Object?>;
    expect(sent['decision'], 'confirm');
    expect(sent['note'], 'أحسنت');
    expect(sent.containsKey('points'), isFalse, reason: 'the task says what the work is worth');
    expect(server.claimStatus, 'confirmed');
    expect(server.points, 15);
    expect(find.text('أكّدت الإنجاز — أُضيفت 15 نقطة إلى رصيده.'), findsOneWidget);
    expect(_total(tester), '15', reason: 'the number on screen is the number the server now holds');
    expect(
      server.calls.where((call) => call == 'GET /v1/families/$familyId/children/$childId/points').length,
      2,
      reason: 'the panel asked again after the write instead of trusting its own arithmetic',
    );
  });

  testWidgets('declining awards nothing, moves no balance, and is explained to the child', (tester) async {
    final server = TasksFakeServer(claimStatus: 'pending', points: 15, pointsAssigned: 15)..pointsAwarded = 15;
    await _pump(tester, authority: tasksAuthorityFor(server));

    await tester.enterText(
      find.byKey(const Key('tasks_server_note_$taskId')),
      'الملابس ما زالت على الأرض',
    );
    await _tapKey(tester, const Key('tasks_server_decline_$taskId'));

    final sent = jsonDecode(server.bodies.last) as Map<String, Object?>;
    expect(sent['decision'], 'decline');
    expect(server.claimStatus, 'declined');
    expect(server.points, 15, 'a refusal awards nothing and takes nothing');
    expect(find.text('لم تُؤكَّد بعد — ويمكنه المحاولة مرة أخرى.'), findsOneWidget);
    expect(find.text('الملابس ما زالت على الأرض'), findsOneWidget);
    expect(_total(tester), '15');
  });

  testWidgets('a refused write keeps the last true reading on screen and says so', (tester) async {
    final server = TasksFakeServer(claimStatus: 'pending')..refuseDecisionWith = 409;
    await _pump(tester, authority: tasksAuthorityFor(server));

    await _tapKey(tester, const Key('tasks_server_confirm_$taskId'));

    expect(find.byKey(const Key('tasks_server_refused')), findsOneWidget);
    expect(find.byKey(const Key('tasks_server_tasks_card')), findsOneWidget);
    expect(find.text('قال الابن إنه أنجزها — بانتظار كلمتك.'), findsOneWidget);
    expect(server.points, 0, reason: 'a refused decision awarded nothing on the server either');
  });

  testWidgets('an unreachable server moves nothing at all', (tester) async {
    final server = TasksFakeServer(claimStatus: 'pending');
    await _pump(tester, authority: tasksAuthorityFor(server));
    expect(find.byKey(const Key('tasks_server_tasks_card')), findsOneWidget);

    server.networkFailure = StateError('socket closed');
    await _tapKey(tester, const Key('tasks_server_confirm_$taskId'));

    expect(find.byKey(const Key('tasks_server_unreachable')), findsOneWidget);
    expect(find.text('قال الابن إنه أنجزها — بانتظار كلمتك.'), findsOneWidget);
  });

  testWidgets('the guardian states a task with its number of points, once', (tester) async {
    final server = TasksFakeServer();
    await _pump(tester, authority: tasksAuthorityFor(server));

    await tester.enterText(find.byKey(const Key('tasks_server_create_title')), 'ترتيب الغرفة');
    await tester.enterText(find.byKey(const Key('tasks_server_create_points')), '20');
    await tester.enterText(find.byKey(const Key('tasks_server_create_note')), 'الملابس في الخزانة');
    await _tapKey(tester, const Key('tasks_server_create_button'));

    final sent = jsonDecode(server.bodies.last) as Map<String, Object?>;
    expect(sent['title'], 'ترتيب الغرفة');
    expect(sent['points'], 20);
    expect(sent['note'], 'الملابس في الخزانة');
    expect(
      server.calls.where(
        (call) => call == 'POST /v1/families/$familyId/children/$childId/tasks',
      ),
      hasLength(1),
    );
    expect(
      find.byKey(const Key('tasks_server_task_$newTaskId')),
      findsOneWidget,
      reason: 'the panel re-read the list instead of trusting the write',
    );
    expect(server.stated.single['title'], 'ترتيب الغرفة');
  });

  testWidgets('a reader without edit rights is offered no button that writes', (tester) async {
    final server = TasksFakeServer(claimStatus: 'pending', points: 15)..pointsAwarded = 15;
    await _pump(tester, authority: tasksAuthorityFor(server), canEdit: false);

    expect(find.byKey(const Key('tasks_server_create_card')), findsNothing);
    expect(find.byKey(const Key('tasks_server_confirm_$taskId')), findsNothing);
    expect(find.byKey(const Key('tasks_server_decline_$taskId')), findsNothing);
    expect(
      find.text('قال الابن إنه أنجزها — بانتظار كلمتك.'),
      findsOneWidget,
      reason: 'a reader still reads: hiding the state would hide the child from them',
    );
    expect(find.text('15'), findsOneWidget);
  });

  testWidgets('the panel fits a phone in Arabic - nothing runs off the edge', (tester) async {
    // The width that matters is the one a father holds: 360 logical pixels, right to left,
    // with the longest sentences on this surface - a claim waiting for his word, the note
    // beside it and the two actions. An overflow throws during layout, so this test IS the
    // edge rather than a comment about it.
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final server = TasksFakeServer(claimStatus: 'pending', points: 15)..pointsAwarded = 15;
    await _pump(tester, authority: tasksAuthorityFor(server));

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('tasks_server_confirm_$taskId')), findsOneWidget);
    expect(find.byKey(const Key('tasks_server_decline_$taskId')), findsOneWidget);
    expect(find.byKey(const Key('tasks_server_create_card')), findsOneWidget);
  });
}
