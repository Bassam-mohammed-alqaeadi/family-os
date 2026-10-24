// The child's own view of today's minutes economy (SCR-CHD-004 · polish wave).
//
// Two things live in this file and nothing else does: the **shape** of what the day board
// draws (a ring, a routine phase, a task card), and the **one** place those shapes are
// assembled out of sources that already exist — the handset's own screen-time reading, the
// applied policy mirror, and the family tasks server.
//
// It is free of `BuildContext` on purpose, so every rule below is arithmetic a test can pin.
// Where a number is not known the field is `null` and the board says "no limit" or "still
// reading" instead of drawing a clock the child's family never set.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show TimeOfDay;

import 'package:family_os/core/policy/schedule_window.dart';
import 'package:family_os/core/policy/smart_modes.dart';
import 'package:family_os/features/n03_screen_time/screen_time_server_authority.dart';
import 'package:family_os/features/n16_tasks/tasks_server_authority.dart';
import 'package:family_os/foundation_gate/family_tasks_api_client.dart';

/// How the hero ring should feel, in the palette's own words.
///
/// The tone is a *conclusion from minutes*, never a mood the widget chose: the same numbers
/// always produce the same tone, so a child sees the same thing twice in a row.
enum ChildTimeRingTone {
  /// Nothing to report yet — the board stays neutral and says so.
  unknown,

  /// Comfortably inside the day: cool, low-stimulation.
  plenty,

  /// A small slice of the day remains: warmer, still calm, never alarming.
  nearEnd,

  /// The day's minutes are spent: warm and terminal, not red.
  depleted,

  /// The bedtime window owns the moment, whatever the minutes say.
  bedtime,
}

int _nonNegative(int value) => value < 0 ? 0 : value;

/// Today's minutes for one child, as the hero ring should draw them.
@immutable
final class ChildTimeRingModel {
  const ChildTimeRingModel({
    required this.capMinutes,
    required this.usedMinutes,
    required this.earnedMinutes,
    required this.grantedMinutes,
    required this.remainingMinutes,
    required this.noLimit,
    required this.earnedExtendsLimit,
    required this.bedtimeNow,
    required this.fromServer,
  });

  /// The model that says nothing beyond "we have no answer".
  static const ChildTimeRingModel unknown = ChildTimeRingModel(
    capMinutes: null,
    usedMinutes: 0,
    earnedMinutes: 0,
    grantedMinutes: 0,
    remainingMinutes: null,
    noLimit: false,
    earnedExtendsLimit: false,
    bedtimeNow: false,
    fromServer: false,
  );

  /// The guardian's daily cap, or null when none is configured.
  final int? capMinutes;

  /// Countable minutes already spent today.
  final int usedMinutes;

  /// Minutes the child earned through tasks and activities (a wallet, not a gift).
  final int earnedMinutes;

  /// Minutes a guardian added on top of today.
  final int grantedMinutes;

  /// The remaining minutes as the answer states them, or null when there is no limit to be
  /// under. Never coerced to zero: "no limit" and "nothing left" are different sentences.
  final int? remainingMinutes;

  /// True when the answer said plainly that today carries no daily limit.
  final bool noLimit;

  /// Whether earned minutes extend the cap. This decides how the earned arc is *labelled*;
  /// the arc is drawn either way, because the child really did earn it.
  final bool earnedExtendsLimit;

  /// True while the bedtime window is the reason the screen is quiet.
  final bool bedtimeNow;

  /// True when these numbers are the handset's server reading, not the applied mirror.
  final bool fromServer;

  /// The whole budget the ring is drawn against: the cap plus whatever was added on top.
  int get totalAllowedMinutes =>
      _nonNegative((capMinutes ?? 0) + grantedMinutes + todayEarnedMinutes);

  /// The minutes actually added by earning, given the guardian's toggle.
  int get todayEarnedMinutes => earnedExtendsLimit ? earnedMinutes : 0;

  /// What share of today is spent, 0…1, or null when there is no budget to be a share of.
  double? get usedFraction {
    if (noLimit) return null;
    final total = totalAllowedMinutes;
    if (total <= 0) return usedMinutes > 0 ? 1.0 : null;
    return (usedMinutes / total).clamp(0.0, 1.0);
  }

  /// The earned arc's share of the ring.
  double? get earnedFraction {
    if (noLimit || earnedMinutes <= 0) return null;
    final total = totalAllowedMinutes;
    if (total <= 0) return null;
    return (earnedMinutes / total).clamp(0.0, 1.0);
  }

  /// The granted arc's share of the ring.
  double? get grantedFraction {
    if (noLimit || grantedMinutes <= 0) return null;
    final total = totalAllowedMinutes;
    if (total <= 0) return null;
    return (grantedMinutes / total).clamp(0.0, 1.0);
  }

  ChildTimeRingTone get tone {
    if (bedtimeNow) return ChildTimeRingTone.bedtime;
    if (noLimit) return ChildTimeRingTone.plenty;
    final remaining = remainingMinutes;
    if (capMinutes == null && remaining == null) return ChildTimeRingTone.unknown;
    if (remaining != null && remaining <= 0) return ChildTimeRingTone.depleted;
    if (remaining != null && remaining <= 15) return ChildTimeRingTone.nearEnd;
    if (remaining == null && totalAllowedMinutes <= 0) {
      return ChildTimeRingTone.unknown;
    }
    return ChildTimeRingTone.plenty;
  }

  /// The minutes left before the day closes, when the ring knows them.
  int? get minutesLeft => noLimit ? null : remainingMinutes;

  /// Builds the model from the handset's server reading when there is one, and from the
  /// applied policy mirror otherwise.
  ///
  /// The order is the whole honesty of the card: the device's answer wins because it is what
  /// the phone is obeying; the mirror is what this child was last told.
  factory ChildTimeRingModel.resolve({
    required bool serverAnswered,
    required int? serverRemainingMinutes,
    required int? serverCapMinutes,
    required int serverUsedMinutes,
    required int serverGrantedMinutes,
    required bool serverEarnedExtend,
    required int mirrorCapMinutes,
    required int mirrorUsedMinutes,
    required int mirrorGrantRemaining,
    required int mirrorEarnedMinutes,
    required bool mirrorEarnedExtend,
    required bool hasExplicitPolicy,
    required bool bedtimeNow,
  }) {
    if (serverAnswered) {
      return ChildTimeRingModel(
        capMinutes: serverCapMinutes,
        usedMinutes: _nonNegative(serverUsedMinutes),
        earnedMinutes: _nonNegative(mirrorEarnedMinutes),
        grantedMinutes: _nonNegative(serverGrantedMinutes),
        remainingMinutes: serverRemainingMinutes,
        noLimit: serverRemainingMinutes == null,
        earnedExtendsLimit: serverEarnedExtend,
        bedtimeNow: bedtimeNow,
        fromServer: true,
      );
    }
    if (!hasExplicitPolicy) return ChildTimeRingModel.unknown;
    final earned = mirrorEarnedExtend ? mirrorEarnedMinutes : 0;
    return ChildTimeRingModel(
      capMinutes: mirrorCapMinutes,
      usedMinutes: _nonNegative(mirrorUsedMinutes),
      earnedMinutes: _nonNegative(mirrorEarnedMinutes),
      grantedMinutes: _nonNegative(mirrorGrantRemaining),
      remainingMinutes: _nonNegative(
        mirrorCapMinutes - mirrorUsedMinutes + earned,
      ),
      noLimit: false,
      earnedExtendsLimit: mirrorEarnedExtend,
      bedtimeNow: bedtimeNow,
      fromServer: false,
    );
  }
}

/// What part of the day the child is standing in, according to the family's own schedule.
enum ChildRoutinePhase { sleep, windDown, school, free }

/// Resolves the routine phase from real inputs only.
///
/// Priority is stated rather than discovered at runtime: a mode a guardian just switched on
/// beats a standing schedule, because it is the newer human decision; the live sleep window
/// beats the school window; wind-down is a *forecast* of the sleep window and only speaks
/// when the sleep window is not yet on. Free time is the honest remainder — the board never
/// invents a reason to celebrate.
abstract final class ChildRoutinePhaseResolver {
  const ChildRoutinePhaseResolver._();

  /// How many minutes before a sleep window the wind-down badge starts speaking.
  static const int windDownLeadMinutes = 30;

  static ChildRoutinePhase resolve({
    required bool modeActive,
    required BuiltInModeId? modeId,
    String? serverReasonCode,
    List<ScheduleWindow> schedules = const [],
  }) {
    if (modeActive) {
      if (modeId == BuiltInModeId.sleep) return ChildRoutinePhase.sleep;
      if (modeId == BuiltInModeId.school) return ChildRoutinePhase.school;
    }
    if (serverReasonCode == 'bedtime') return ChildRoutinePhase.sleep;
    if (serverReasonCode == 'school_mode') return ChildRoutinePhase.school;
    final sleep = _enabledWindow(schedules, ScheduleKind.sleep);
    final now = TimeOfDay.now();
    if (sleep != null && sleep.contains(now)) return ChildRoutinePhase.sleep;
    if (sleep != null && _withinLeadMinutes(sleep, now)) {
      return ChildRoutinePhase.windDown;
    }
    return ChildRoutinePhase.free;
  }

  static ScheduleWindow? _enabledWindow(
    List<ScheduleWindow> schedules,
    ScheduleKind kind,
  ) {
    for (final window in schedules) {
      if (window.kind == kind && window.enabled) return window;
    }
    return null;
  }

  static bool _withinLeadMinutes(ScheduleWindow window, TimeOfDay now) {
    final start = ScheduleWindow.toMinutes(window.start);
    if (start == null) return false;
    final minutes = now.hour * 60 + now.minute;
    final delta = start - minutes;
    return delta > 0 && delta <= windDownLeadMinutes;
  }
}

/// One task the child can do, in the words the child's board needs.
@immutable
final class ChildEarnTaskCard {
  const ChildEarnTaskCard({
    required this.id,
    required this.title,
    required this.points,
    required this.status,
  });

  final String id;

  /// The title as the guardian wrote it on the server — never a local guess at it, and never
  /// an identifier shown in its place.
  final String title;

  /// The number the guardian put on the task once. The board shows it and explains that a
  /// person, not the app, turns points into minutes.
  final int points;
  final ChildEarnTaskStatus status;

  factory ChildEarnTaskCard.fromServer(FoundationGateTask task) {
    final title = task.title.trim();
    return ChildEarnTaskCard(
      id: task.id,
      title: title.isEmpty ? task.note.trim() : title,
      points: task.points,
      status: ChildEarnTaskStatus.fromClaim(task),
    );
  }
}

/// Where a task stands between "nobody spoke" and "a guardian answered".
enum ChildEarnTaskStatus {
  notSent,
  awaitingGuardian,
  rewarded,
  declined,
  closed;

  static ChildEarnTaskStatus fromClaim(FoundationGateTask task) {
    if (task.status == FoundationGateTaskStatus.archived) {
      return ChildEarnTaskStatus.closed;
    }
    final claim = task.claim;
    if (claim == null) return ChildEarnTaskStatus.notSent;
    return switch (claim.status) {
      FoundationGateTaskClaimStatus.pending =>
        ChildEarnTaskStatus.awaitingGuardian,
      FoundationGateTaskClaimStatus.confirmed => ChildEarnTaskStatus.rewarded,
      FoundationGateTaskClaimStatus.declined => ChildEarnTaskStatus.declined,
    };
  }
}

/// What the tasks read produced — the five honest states in one value.
enum ChildDayBoardEconomyPhase { loading, ready, empty, noServer, error }

/// A read of the child's tasks, or the honest statement that there was none.
@immutable
final class ChildDayBoardEconomy {
  const ChildDayBoardEconomy({required this.phase, this.tasks = const []});

  const ChildDayBoardEconomy.loading()
    : phase = ChildDayBoardEconomyPhase.loading,
      tasks = const [];

  const ChildDayBoardEconomy.noServer()
    : phase = ChildDayBoardEconomyPhase.noServer,
      tasks = const [];

  const ChildDayBoardEconomy.error()
    : phase = ChildDayBoardEconomyPhase.error,
      tasks = const [];

  ChildDayBoardEconomy.ready(List<ChildEarnTaskCard> tasks)
    : phase = tasks.isEmpty
          ? ChildDayBoardEconomyPhase.empty
          : ChildDayBoardEconomyPhase.ready,
      tasks = List<ChildEarnTaskCard>.unmodifiable(tasks);

  final ChildDayBoardEconomyPhase phase;
  final List<ChildEarnTaskCard> tasks;

  /// The cards the board has room for.
  ///
  /// The order is the child's, not the server's: something still waiting on an answer is
  /// worth looking at, an unstarted task is worth doing, a finished one is worth leaving at
  /// the end where it can be admired without competing.
  List<ChildEarnTaskCard> get headlineTasks {
    final ordered = <ChildEarnTaskCard>[
      ...tasks.where(
        (task) => task.status == ChildEarnTaskStatus.awaitingGuardian,
      ),
      ...tasks.where((task) => task.status == ChildEarnTaskStatus.notSent),
      ...tasks.where((task) => task.status == ChildEarnTaskStatus.declined),
      ...tasks.where((task) => task.status == ChildEarnTaskStatus.rewarded),
      ...tasks.where((task) => task.status == ChildEarnTaskStatus.closed),
    ];
    return ordered.length <= 3 ? ordered : ordered.sublist(0, 3);
  }
}

/// The child board's one read of the family tasks server.
///
/// It reads through the authority the app bound at boot — the same one the guardian's tasks
/// panel uses — so a child and a guardian are never looking at two different boards. When
/// nothing is bound there is nothing to ask, and the card says so quietly: this section is a
/// window onto the economy, not the screen's promise about minutes.
final class ChildDayBoardTasksBridge {
  ChildDayBoardTasksBridge({TasksServerAuthority? authority})
    : _authorityOverride = authority;

  final TasksServerAuthority? _authorityOverride;

  TasksServerAuthority? get _authority =>
      _authorityOverride ?? activeTasksServerAuthority;

  Future<ChildDayBoardEconomy> load(String childId) async {
    final authority = _authority;
    if (authority == null) return const ChildDayBoardEconomy.noServer();
    final answer = await authority.listTasks(
      ScreenTimeServerAuthority.unscopeChildId(childId),
    );
    if (!answer.isReady) return const ChildDayBoardEconomy.error();
    return ChildDayBoardEconomy.ready(<ChildEarnTaskCard>[
      for (final task in answer.value ?? const <FoundationGateTask>[])
        ChildEarnTaskCard.fromServer(task),
    ]);
  }
}
