// SCR-CHD-004 · the polish wave's own acceptance test.
//
// The other files in this folder pin what the board already promised (the remaining-minutes
// line, the honest stale state, the a11y budget). This one pins the parts the polish added,
// because each of them is a claim that can rot:
//
//   * the ring's arithmetic — earned minutes count toward the day **only when a guardian said
//     so**, and the fraction is null rather than zero when there is no budget to be a share of;
//   * the routine badge — resolved from a mode, a server reason or the family's own schedule,
//     never from the hour of the day the widget happens to be drawn in;
//   * the task cards — the status a claim has, not the status the screen hoped for;
//   * the safety button — a three-second hold, and *nothing* when the finger leaves early;
//   * the touchpoints — one tap, one callback, and no invented phone number behind it.
//
// Labels here are short literals on purpose: these widgets take their copy from ARB through
// their callers, so a test that typed Arabic prose here would be testing its own strings.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/policy/schedule_window.dart';
import 'package:family_os/core/policy/smart_modes.dart';
import 'package:family_os/features/n02_day/child_day_board_economy.dart';
import 'package:family_os/features/n02_day/child_day_board_kit.dart';
import 'package:family_os/features/n16_tasks/tasks_server_authority.dart';
import 'package:family_os/foundation_gate/family_tasks_api_client.dart';

ChildTimeRingModel _model({
  int? capMinutes = 120,
  int usedMinutes = 30,
  int earnedMinutes = 0,
  int grantedMinutes = 0,
  int? remainingMinutes = 90,
  bool noLimit = false,
  bool earnedExtendsLimit = false,
  bool bedtimeNow = false,
}) => ChildTimeRingModel(
  capMinutes: capMinutes,
  usedMinutes: usedMinutes,
  earnedMinutes: earnedMinutes,
  grantedMinutes: grantedMinutes,
  remainingMinutes: remainingMinutes,
  noLimit: noLimit,
  earnedExtendsLimit: earnedExtendsLimit,
  bedtimeNow: bedtimeNow,
  fromServer: true,
);

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildFamilyTheme(),
      home: Scaffold(
        // RTL + a narrow phone on purpose: every label in this board is Arabic-first, and a
        // ring that only fits an LTR tablet is a ring that will overflow on a child's phone.
        body: SingleChildScrollView(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: SizedBox(width: 390, child: child),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

FoundationGateTask _task({
  required String id,
  String title = 'Read ten pages',
  String note = '',
  int points = 20,
  FoundationGateTaskStatus status = FoundationGateTaskStatus.open,
  FoundationGateTaskClaimStatus? claimStatus,
}) => FoundationGateTask(
  id: id,
  childId: 'child-1',
  audienceThreadId: null,
  title: title,
  note: note,
  points: points,
  status: status,
  createdAt: DateTime.utc(2026, 10, 7),
  claim: claimStatus == null
      ? null
      : FoundationGateTaskClaim(
          id: 'claim-$id',
          taskId: id,
          status: claimStatus,
          note: '',
          claimedByDeviceId: 'device-1',
          claimedByMembershipId: null,
          decidedByMembershipId: null,
          decidedAt: null,
          decisionNote: '',
          pointsAwarded: 0,
          createdAt: DateTime.utc(2026, 10, 7),
        ),
);

void main() {
  setUp(() => bindTasksServerAuthority(null));
  tearDown(() => bindTasksServerAuthority(null));

  group('time ring model', () {
    test('earned minutes join the day only when the guardian allowed it', () {
      final off = _model(earnedMinutes: 30, grantedMinutes: 15);
      expect(off.totalAllowedMinutes, 135);
      expect(off.todayEarnedMinutes, 0);
      // 120 + 15 granted, because the earned 30 are kept, not added.
      expect(_model(earnedMinutes: 30, grantedMinutes: 15).totalAllowedMinutes, 135);
      final on = _model(
        earnedMinutes: 30,
        grantedMinutes: 15,
        earnedExtendsLimit: true,
      );
      expect(on.totalAllowedMinutes, 165);
      expect(on.usedMinutes / on.totalAllowedMinutes, closeTo(30 / 165, 0.0001));
    });

    test('the fraction is null when there is no budget to be a share of', () {
      expect(_model(noLimit: true, remainingMinutes: null).usedFraction, isNull);
      expect(
        _model(capMinutes: 0, usedMinutes: 0, remainingMinutes: 0).usedFraction,
        isNull,
      );
      expect(
        _model(capMinutes: 0, usedMinutes: 40, remainingMinutes: 0).usedFraction,
        1.0,
        reason: 'spent with nothing to spend against is drawn as full, not as zero',
      );
    });

    test('the arcs that do not exist are not drawn as zero', () {
      final model = _model(earnedMinutes: 0, grantedMinutes: 0);
      expect(model.earnedFraction, isNull);
      expect(model.grantedFraction, isNull);
      final both = _model(
        earnedMinutes: 30,
        grantedMinutes: 30,
        earnedExtendsLimit: true,
      );
      expect(both.earnedFraction, closeTo(30 / 180, 0.0001));
      expect(both.grantedFraction, closeTo(30 / 180, 0.0001));
    });

    test('the tone is bedtime first, and unknown only when nothing answered', () {
      expect(
        _model(bedtimeNow: true, remainingMinutes: 500).tone,
        ChildTimeRingTone.bedtime,
      );
      expect(_model(noLimit: true, remainingMinutes: null).tone, ChildTimeRingTone.plenty);
      expect(_model(remainingMinutes: 0).tone, ChildTimeRingTone.depleted);
      expect(_model(remainingMinutes: 12).tone, ChildTimeRingTone.nearEnd);
      expect(_model(remainingMinutes: 90).tone, ChildTimeRingTone.plenty);
      expect(ChildTimeRingModel.unknown.tone, ChildTimeRingTone.unknown);
      expect(_model(remainingMinutes: 90).minutesLeft, 90);
      expect(_model(noLimit: true, remainingMinutes: null).minutesLeft, isNull);
    });

    test('the handset answer wins, and no answer is drawn as no answer', () {
      final fromServer = ChildTimeRingModel.resolve(
        serverAnswered: true,
        serverRemainingMinutes: 45,
        serverCapMinutes: 60,
        serverUsedMinutes: 15,
        serverGrantedMinutes: 0,
        serverEarnedExtend: true,
        mirrorCapMinutes: 999,
        mirrorUsedMinutes: 999,
        mirrorGrantRemaining: 999,
        mirrorEarnedMinutes: 0,
        mirrorEarnedExtend: false,
        hasExplicitPolicy: false,
        bedtimeNow: false,
      );
      expect(fromServer.fromServer, isTrue);
      expect(fromServer.remainingMinutes, 45);
      expect(fromServer.capMinutes, 60, reason: 'the mirror never overwrites the phone');

      final mirrored = ChildTimeRingModel.resolve(
        serverAnswered: false,
        serverRemainingMinutes: null,
        serverCapMinutes: null,
        serverUsedMinutes: 0,
        serverGrantedMinutes: 0,
        serverEarnedExtend: false,
        mirrorCapMinutes: 60,
        mirrorUsedMinutes: 20,
        mirrorGrantRemaining: 5,
        mirrorEarnedMinutes: 10,
        mirrorEarnedExtend: true,
        hasExplicitPolicy: true,
        bedtimeNow: false,
      );
      expect(mirrored.fromServer, isFalse);
      expect(mirrored.remainingMinutes, 50, reason: '60 − 20 + 10 earned');
      expect(mirrored.grantedMinutes, 5);

      expect(
        ChildTimeRingModel.resolve(
          serverAnswered: false,
          serverRemainingMinutes: null,
          serverCapMinutes: null,
          serverUsedMinutes: 0,
          serverGrantedMinutes: 0,
          serverEarnedExtend: false,
          mirrorCapMinutes: 60,
          mirrorUsedMinutes: 20,
          mirrorGrantRemaining: 5,
          mirrorEarnedMinutes: 10,
          mirrorEarnedExtend: true,
          hasExplicitPolicy: false,
          bedtimeNow: false,
        ),
        same(ChildTimeRingModel.unknown),
        reason: 'an empty day is empty, not a policy this build assembled',
      );
    });
  });

  group('routine phase resolver', () {
    test('a mode a guardian switched on outranks a standing schedule', () {
      expect(
        ChildRoutinePhaseResolver.resolve(
          modeActive: true,
          modeId: BuiltInModeId.sleep,
          serverReasonCode: 'bedtime',
        ),
        ChildRoutinePhase.sleep,
      );
      expect(
        ChildRoutinePhaseResolver.resolve(
          modeActive: true,
          modeId: BuiltInModeId.school,
          serverReasonCode: 'bedtime',
        ),
        ChildRoutinePhase.school,
        reason: 'the newer human decision is what the child is living in',
      );
    });

    test('the server reason is read as the server wrote it', () {
      expect(
        ChildRoutinePhaseResolver.resolve(
          modeActive: false,
          modeId: null,
          serverReasonCode: 'bedtime',
        ),
        ChildRoutinePhase.sleep,
      );
      expect(
        ChildRoutinePhaseResolver.resolve(
          modeActive: false,
          modeId: null,
          serverReasonCode: 'school_mode',
        ),
        ChildRoutinePhase.school,
      );
      expect(
        ChildRoutinePhaseResolver.resolve(
          modeActive: false,
          modeId: null,
          serverReasonCode: 'daily_limit',
        ),
        ChildRoutinePhase.free,
        reason: 'a spent day is not a bedtime, and the badge must not say otherwise',
      );
    });

    test('a schedule that cannot be trusted does not claim a phase', () {
      final disabled = ScheduleWindow(
        kind: ScheduleKind.sleep,
        enabled: false,
        start: const TimeOfDay(hour: 0, minute: 0),
        end: const TimeOfDay(hour: 23, minute: 59),
      );
      expect(
        ChildRoutinePhaseResolver.resolve(
          modeActive: false,
          modeId: null,
          schedules: [disabled],
        ),
        ChildRoutinePhase.free,
      );
      final malformed = const ScheduleWindow(
        kind: ScheduleKind.sleep,
        enabled: true,
        start: TimeOfDay(hour: 0, minute: 0),
        end: TimeOfDay(hour: 0, minute: 0),
      );
      expect(
        ChildRoutinePhaseResolver.resolve(
          modeActive: false,
          modeId: null,
          schedules: [malformed],
        ),
        ChildRoutinePhase.free,
        reason: 'a window whose end is not after its start is not a sleep window',
      );
      expect(ChildRoutinePhaseResolver.windDownLeadMinutes, 30);
    });
  });

  group('task cards', () {
    test('a task keeps the words the guardian wrote and the status the claim has', () {
      final open = ChildEarnTaskCard.fromServer(_task(id: 't1', points: 15));
      expect(open.title, 'Read ten pages');
      expect(open.points, 15);
      expect(open.status, ChildEarnTaskStatus.notSent);

      expect(
        ChildEarnTaskStatus.fromClaim(
          _task(id: 't2', claimStatus: FoundationGateTaskClaimStatus.pending),
        ),
        ChildEarnTaskStatus.awaitingGuardian,
      );
      expect(
        ChildEarnTaskStatus.fromClaim(
          _task(id: 't3', claimStatus: FoundationGateTaskClaimStatus.confirmed),
        ),
        ChildEarnTaskStatus.rewarded,
      );
      expect(
        ChildEarnTaskStatus.fromClaim(
          _task(id: 't4', claimStatus: FoundationGateTaskClaimStatus.declined),
        ),
        ChildEarnTaskStatus.declined,
      );
      expect(
        ChildEarnTaskStatus.fromClaim(
          _task(id: 't5', status: FoundationGateTaskStatus.archived),
        ),
        ChildEarnTaskStatus.closed,
      );
      expect(
        ChildEarnTaskCard.fromServer(
          _task(id: 't6', title: '   ', note: 'Water the plants'),
        ).title,
        'Water the plants',
        reason: 'a blank title falls back to the note, never to the id',
      );
    });

    test('the board shows three cards, waiting ones first', () {
      final economy = ChildDayBoardEconomy.ready([
        ChildEarnTaskCard.fromServer(_task(id: 'a')),
        ChildEarnTaskCard.fromServer(
          _task(id: 'b', claimStatus: FoundationGateTaskClaimStatus.pending),
        ),
        ChildEarnTaskCard.fromServer(
          _task(id: 'c', claimStatus: FoundationGateTaskClaimStatus.confirmed),
        ),
        ChildEarnTaskCard.fromServer(_task(id: 'd')),
      ]);
      final headline = economy.headlineTasks;
      expect(headline.length, 3);
      expect(headline.first.id, 'b', reason: 'a question the child asked is worth seeing');
      expect(headline.map((task) => task.id).toSet(), containsAll(<String>['a', 'd']));
    });

    test('an empty read is empty, and no server is not an error', () {
      expect(
        ChildDayBoardEconomy.ready(const []).phase,
        ChildDayBoardEconomyPhase.empty,
      );
      expect(
        const ChildDayBoardEconomy.noServer().phase,
        ChildDayBoardEconomyPhase.noServer,
      );
      expect(const ChildDayBoardEconomy.loading().tasks, isEmpty);
      expect(const ChildDayBoardEconomy.error().phase, ChildDayBoardEconomyPhase.error);
    });

    test('with nothing bound the bridge reports no server instead of an empty day', () async {
      final economy = await ChildDayBoardTasksBridge().load('child-1');
      expect(economy.phase, ChildDayBoardEconomyPhase.noServer);
    });
  });

  group('hero ring widget', () {
    testWidgets('it names the day, the number, and the three sources of minutes', (tester) async {
      await _pump(
        tester,
        ChildTimeHeroRing(
          model: _model(earnedMinutes: 20, grantedMinutes: 10),
          title: 'TITLE',
          remainingLabel: 'REMAINING',
          remainingKey: const Key('remaining'),
          remainingValue: '90',
          baseLabel: 'BASE',
          earnedLabel: 'EARNED',
          grantLabel: 'GRANT',
          toneLine: 'TONE',
          semanticsLabel: 'RING 20% used',
        ),
      );

      expect(find.text('TITLE'), findsOneWidget);
      expect(find.text('90'), findsOneWidget);
      expect(find.byKey(const Key('remaining')), findsOneWidget);
      expect(find.text('BASE'), findsOneWidget);
      expect(find.text('EARNED'), findsOneWidget);
      expect(find.text('GRANT'), findsOneWidget);
      expect(find.text('TONE'), findsOneWidget);
      expect(
        find.textContaining('%'),
        findsOneWidget,
        reason: 'a day with a budget has a share of it spent',
      );
      expect(
        tester
            .widget<Semantics>(find.byKey(ChildDayBoardPolishKeys.heroRing))
            .properties
            .label,
        'RING 20% used',
      );
    });

    testWidgets('an open day says so and hides the arcs it has no number for', (tester) async {
      await _pump(
        tester,
        ChildTimeHeroRing(
          model: _model(noLimit: true, remainingMinutes: null),
          title: 'TITLE',
          remainingLabel: 'REMAINING',
          remainingKey: const Key('remaining'),
          remainingValue: 'OPEN',
          baseLabel: 'BASE',
          earnedLabel: 'EARNED',
          grantLabel: 'GRANT',
          toneLine: 'TONE',
        ),
      );

      expect(find.text('OPEN'), findsOneWidget);
      expect(find.text('0'), findsNothing, reason: 'a zero arc is drawn as no arc at all');
      expect(
        find.textContaining('%'),
        findsNothing,
        reason: 'no budget means no share of it, not a zero percent',
      );
    });

    testWidgets('the breathing ring is only for the moment it helps', (tester) async {
      await _pump(
        tester,
        ChildTimeHeroRing(
          model: _model(remainingMinutes: 3, usedMinutes: 117),
          title: 'TITLE',
          remainingLabel: 'REMAINING',
          remainingKey: const Key('remaining'),
          remainingValue: '3',
          baseLabel: 'BASE',
          earnedLabel: 'EARNED',
          grantLabel: 'GRANT',
          toneLine: 'TONE',
          pulse: true,
        ),
      );

      expect(
        find.byKey(ChildDayBoardPolishKeys.heroRing),
        findsOneWidget,
        reason: 'a scale pulse must not change the ring\'s identity in the tree',
      );
      expect(find.text('TONE'), findsOneWidget);
    });
  });

  group('safety hold', () {
    testWidgets('three seconds of holding is what sends it', (tester) async {
      var sent = 0;
      await _pump(
        tester,
        ChildSafetyHoldButton(
          holdDuration: const Duration(seconds: 3),
          onHoldCompleted: () => sent++,
          title: 'SAFE',
          instruction: 'HOLD',
          releasedMessage: 'SENT',
          progressLabel: (seconds) => 'KEEP $seconds',
          semanticsLabel: 'HELP',
        ),
      );

      expect(find.text('SAFE'), findsOneWidget);
      expect(find.text('HOLD'), findsOneWidget);
      expect(find.text('SENT'), findsNothing);

      final hold = find.byKey(ChildDayBoardPolishKeys.safetyHold);
      await tester.ensureVisible(hold);
      final gesture = await tester.startGesture(tester.getCenter(hold));
      await tester.pump(const Duration(milliseconds: 1200));
      expect(find.textContaining('KEEP'), findsOneWidget, reason: 'the countdown is visible');
      expect(sent, 0, reason: 'one second is not three');

      await tester.pump(const Duration(milliseconds: 1200));
      expect(sent, 0, reason: 'two seconds is not three either');

      await tester.pump(const Duration(milliseconds: 1000));
      expect(sent, 1);
      expect(find.text('SENT'), findsOneWidget);

      await gesture.up();
      await tester.pumpAndSettle();
      expect(sent, 1, reason: 'releasing after it fired does not fire it twice');

      await tester.pump(const Duration(milliseconds: 2700));
      expect(
        find.text('SENT'),
        findsNothing,
        reason: 'the confirmation expires on its own — the board does not sit on a stale claim',
      );
    });

    testWidgets('a finger that leaves early sends nothing', (tester) async {
      var sent = 0;
      await _pump(
        tester,
        ChildSafetyHoldButton(
          holdDuration: const Duration(seconds: 3),
          onHoldCompleted: () => sent++,
          title: 'SAFE',
          instruction: 'HOLD',
          releasedMessage: 'SENT',
          progressLabel: (seconds) => 'KEEP $seconds',
          semanticsLabel: 'HELP',
        ),
      );

      final hold = find.byKey(ChildDayBoardPolishKeys.safetyHold);
      await tester.ensureVisible(hold);
      final gesture = await tester.startGesture(tester.getCenter(hold));
      await tester.pump(const Duration(milliseconds: 900));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(sent, 0);
      expect(find.text('HOLD'), findsOneWidget);
      expect(find.textContaining('KEEP'), findsNothing);
    });

    testWidgets('a disabled button holds forever and sends nothing', (tester) async {
      var sent = 0;
      await _pump(
        tester,
        ChildSafetyHoldButton(
          holdDuration: const Duration(seconds: 3),
          onHoldCompleted: () => sent++,
          title: 'SAFE',
          instruction: 'HOLD',
          releasedMessage: 'SENT',
          progressLabel: (seconds) => 'KEEP $seconds',
          semanticsLabel: 'HELP',
          enabled: false,
        ),
      );

      final hold = find.byKey(ChildDayBoardPolishKeys.safetyHold);
      await tester.ensureVisible(hold);
      final gesture = await tester.startGesture(tester.getCenter(hold));
      await tester.pump(const Duration(seconds: 5));
      await gesture.up();
      expect(sent, 0);
    });
  });

  group('routine badges and touchpoints', () {
    testWidgets('every phase of the day is visible, the live one named first', (tester) async {
      await _pump(
        tester,
        ChildRoutineBadgeCard(
          phase: ChildRoutinePhase.school,
          title: 'ROUTINE',
          hint: 'HINT',
          sleepLabel: 'SLEEP',
          schoolLabel: 'SCHOOL',
          freeLabel: 'FREE',
          windDownLabel: 'WIND',
        ),
      );

      expect(find.text('ROUTINE'), findsOneWidget);
      expect(find.text('HINT'), findsOneWidget);
      for (final label in ['SLEEP', 'SCHOOL', 'FREE', 'WIND']) {
        expect(find.text(label), findsOneWidget);
      }
      expect(
        find.byKey(const Key('child_day_board_routine_badge_school')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('child_day_board_routine_badge_sleep')),
        findsOneWidget,
        reason: 'the rest of the day stays readable, not hidden by the live phase',
      );
    });

    testWidgets('one tap on a touchpoint is one call', (tester) async {
      var calls = 0;
      await _pump(
        tester,
        FamilyTouchpointStrip(
          title: 'FAMILY',
          subtitle: 'ONE TAP',
          points: [
            FamilyTouchpoint(
              id: 'thread',
              label: 'THREAD',
              glyph: Icons.chat_bubble_outline,
              onTap: () => calls++,
            ),
            const FamilyTouchpoint(
              id: 'ask',
              label: 'ASK',
              glyph: Icons.more_time,
              onTap: null,
            ),
          ],
        ),
      );

      expect(find.text('FAMILY'), findsOneWidget);
      expect(find.text('ONE TAP'), findsOneWidget);
      expect(find.text('THREAD'), findsOneWidget);

      final thread = find.byKey(const Key('child_day_board_touchpoint_thread'));
      await tester.ensureVisible(thread);
      await tester.tap(thread);
      await tester.pumpAndSettle();
      expect(calls, 1);

      // The one with nobody to call has no callback, and says so by not looking live.
      expect(find.text('ASK'), findsOneWidget);
      expect(
        tester
            .widget<Semantics>(
              find
                  .descendant(
                    of: find.byKey(
                      const Key('child_day_board_touchpoint_ask'),
                    ),
                    matching: find.byType(Semantics),
                  )
                  .first,
            )
            .properties
            .enabled,
        isNot(true),
        reason: 'a touchpoint with nobody to call is not announced as a live button',
      );
    });
  });

  group('tasks card states', () {
    Future<void> pumpCard(
      WidgetTester tester,
      ChildDayBoardEconomy economy,
    ) => _pump(
      tester,
      ChildEarnTasksCard(
        economy: economy,
        title: 'TASKS',
        subtitle: 'SUB',
        stateMessage: (phase) => 'STATE ${phase.name}',
        pointsLabel: (points) => '+$points',
        statusLabel: (status) => 'ST ${status.name}',
        openAllLabel: 'ALL',
        onOpenAll: () {},
      ),
    );

    testWidgets('a ready day draws the task, its number and its status', (tester) async {
      await pumpCard(
        tester,
        ChildDayBoardEconomy.ready([
          ChildEarnTaskCard.fromServer(_task(id: 't1', points: 15)),
        ]),
      );
      expect(find.text('Read ten pages'), findsOneWidget);
      expect(find.text('+15'), findsOneWidget);
      expect(find.text('ST notSent'), findsOneWidget);
      expect(find.text('STATE ready'), findsNothing);
    });

    for (final phase in [
      ChildDayBoardEconomyPhase.empty,
      ChildDayBoardEconomyPhase.loading,
      ChildDayBoardEconomyPhase.noServer,
      ChildDayBoardEconomyPhase.error,
    ]) {
      testWidgets('${phase.name} is drawn as itself, not as an empty list', (tester) async {
        final economy = switch (phase) {
          ChildDayBoardEconomyPhase.empty => ChildDayBoardEconomy.ready(const []),
          ChildDayBoardEconomyPhase.loading => const ChildDayBoardEconomy.loading(),
          ChildDayBoardEconomyPhase.noServer => const ChildDayBoardEconomy.noServer(),
          _ => const ChildDayBoardEconomy.error(),
        };
        await pumpCard(tester, economy);
        expect(find.text('STATE ${phase.name}'), findsOneWidget);
        expect(find.text('Read ten pages'), findsNothing);
      });
    }
  });
}
