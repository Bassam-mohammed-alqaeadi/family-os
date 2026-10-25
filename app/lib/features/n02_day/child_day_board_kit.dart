// The child's day board, drawn the way a child reads a screen (SCR-CHD-004 · polish wave).
//
// Everything in this file is presentation: a widget that takes values and labels and paints
// them, plus the small painter behind the time ring. None of it decides a number, reads a
// repository, or asks a server — that stays in `child_day_board_economy.dart` and the screen,
// where a test can pin it. The split is on purpose: a rich surface is only safe to ship when
// the part that can be wrong is small and separate.
//
// Overflow discipline (UI-017 / Rule 16) is a design constraint here, not an afterthought.
// Every label that can be long sits in an `Expanded`/`Flexible` with `maxLines` +
// `ellipsis`, every numeric headline sits in a `FittedBox` so it shrinks instead of breaking
// at 2.0 text scale, and nothing stacks text inside a fixed-height box. These boards are
// pumped at 360 dp in AR and EN at 1.0 and 1.3 in the render suite, and a `RenderFlex`
// overflow there is a failing build, not a visual nit.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/features/n02_day/child_day_board_economy.dart';
import 'package:family_os/features/n02_day/day_board_motion.dart';

/// Keys the polish wave adds, so its own tests can point at parts without reaching into the
/// pre-existing `ChildDayBoardKeys` contract.
abstract final class ChildDayBoardPolishKeys {
  static const heroCard = Key('child_day_board_hero_card');
  static const heroRing = Key('child_day_board_hero_ring');
  static const heroTone = Key('child_day_board_hero_tone');
  static const heroLegend = Key('child_day_board_hero_legend');
  static const routineCard = Key('child_day_board_routine_card');
  static const tasksCard = Key('child_day_board_tasks_card');
  static const tasksList = Key('child_day_board_tasks_list');
  static const tasksState = Key('child_day_board_tasks_state');
  static const tasksOpenAll = Key('child_day_board_tasks_open_all');
  static const safetyCard = Key('child_day_board_safety_card');
  static const safetyHold = Key('child_day_board_safety_hold');
  static const safetyProgress = Key('child_day_board_safety_progress');
  static const touchpointsCard = Key('child_day_board_touchpoints_card');

  /// Prefixes for per-item keys, so a test can name one row without naming the list.
  static const routineBadgePrefix = 'child_day_board_routine_badge_';
  static const taskTilePrefix = 'child_day_board_task_';
  static const touchpointPrefix = 'child_day_board_touchpoint_';
}

/// The palette the ring wears for one tone.
@immutable
final class ChildTimeRingPalette {
  const ChildTimeRingPalette({
    required this.used,
    required this.earned,
    required this.granted,
    required this.track,
    required this.surfaceTop,
    required this.surfaceBottom,
    required this.accent,
  });

  final Color used;
  final Color earned;
  final Color granted;
  final Color track;
  final Color surfaceTop;
  final Color surfaceBottom;
  final Color accent;

  /// The five tones, expressed only in Family OS tokens, so light and dark both hold.
  static ChildTimeRingPalette forTone(
    FamilyColors colors,
    ChildTimeRingTone tone,
  ) {
    return switch (tone) {
      ChildTimeRingTone.plenty => ChildTimeRingPalette(
        used: colors.teal600,
        earned: colors.mint,
        granted: colors.sky,
        track: colors.teal100,
        surfaceTop: colors.teal100,
        surfaceBottom: colors.surface,
        accent: colors.tealDeep,
      ),
      ChildTimeRingTone.nearEnd => ChildTimeRingPalette(
        used: colors.amber,
        earned: colors.mint,
        granted: colors.sky,
        track: colors.amber100,
        surfaceTop: colors.amber100,
        surfaceBottom: colors.surface,
        accent: colors.amberDeep,
      ),
      ChildTimeRingTone.depleted => ChildTimeRingPalette(
        used: colors.coral,
        earned: colors.mint,
        granted: colors.sky,
        track: colors.coral100,
        surfaceTop: colors.coral100,
        surfaceBottom: colors.surface,
        accent: colors.coral,
      ),
      ChildTimeRingTone.bedtime => ChildTimeRingPalette(
        used: colors.p500,
        earned: colors.mint,
        granted: colors.sky,
        track: colors.p100,
        surfaceTop: colors.p100,
        surfaceBottom: colors.surface,
        accent: colors.p700,
      ),
      ChildTimeRingTone.unknown => ChildTimeRingPalette(
        used: colors.p400,
        earned: colors.mint,
        granted: colors.sky,
        track: colors.border,
        surfaceTop: colors.p50,
        surfaceBottom: colors.surface,
        accent: colors.ink2,
      ),
    };
  }
}

/// The pulsing hero ring: what is spent, what was earned, what was gifted.
///
/// Three arcs on one track, drawn in the order the child's day actually happened — spent
/// first, then the minutes the child earned, then anything a guardian added. The legend says
/// which is which, because a green arc with no name is decoration.
class ChildTimeHeroRing extends StatelessWidget {
  const ChildTimeHeroRing({
    super.key,
    required this.model,
    required this.title,
    required this.remainingValue,
    required this.remainingKey,
    required this.remainingLabel,
    required this.baseLabel,
    required this.earnedLabel,
    required this.grantLabel,
    required this.toneLine,
    this.extendNote,
    this.footer,
    this.semanticsLabel,
    this.pulse = false,
  });

  final ChildTimeRingModel model;
  final Key remainingKey;

  /// The headline number, already worded by the caller — the screen owns which source it
  /// came from, so the ring never gets to decide what "remaining" means.
  final String remainingValue;
  final String remainingLabel;
  final String title;
  final String baseLabel;
  final String earnedLabel;
  final String grantLabel;
  final String toneLine;
  final Widget? extendNote;
  final Widget? footer;

  /// What a screen reader hears for the whole ring. Defaults to the headline number, because
  /// a ring with nothing said about it is a ring that says nothing at all.
  final String? semanticsLabel;

  /// A breathing scale is reserved for the one moment it helps: time is nearly out.
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final palette = ChildTimeRingPalette.forTone(colors, model.tone);

    return DecoratedBox(
      key: ChildDayBoardPolishKeys.heroCard,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.surfaceTop, palette.surfaceBottom],
        ),
        borderRadius: BorderRadius.circular(radii.cardChild),
        border: Border.all(color: colors.border.withValues(alpha: 0.9)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: colors.ink,
                      height: 1.25,
                    ),
                  ),
                ),
                _RingChip(label: remainingLabel, color: palette.accent),
              ],
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final available = constraints.maxWidth.isFinite
                    ? constraints.maxWidth
                    : 320.0;
                final size = math.min(math.max(available * 0.72, 168.0), 216.0)
                    .toDouble();
                return Center(
                  // The breathing is reserved for the one moment it helps: when the day is
                  // nearly out the ring softens its own edges instead of the app shouting.
                  child: DayBoardMotionPulse(
                    enabled: pulse,
                    mode: DayBoardMotionPulseMode.scale,
                    preferredDuration: const Duration(milliseconds: 1600),
                    child: _RingBody(
                      size: size,
                      palette: palette,
                      model: model,
                      remainingKey: remainingKey,
                      remainingValue: remainingValue,
                      semanticsLabel: semanticsLabel,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            Wrap(
              key: ChildDayBoardPolishKeys.heroLegend,
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.start,
              children: [
                _LegendChip(
                  color: palette.used,
                  label: baseLabel,
                  minutes: model.capMinutes,
                ),
                _LegendChip(
                  color: palette.earned,
                  label: earnedLabel,
                  minutes: model.earnedMinutes,
                ),
                _LegendChip(
                  color: palette.granted,
                  label: grantLabel,
                  minutes: model.grantedMinutes,
                ),
              ],
            ),
            if (extendNote != null) ...[
              const SizedBox(height: 12),
              extendNote!,
            ],
            const SizedBox(height: 10),
            Text(
              key: ChildDayBoardPolishKeys.heroTone,
              toneLine,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: palette.accent,
                height: 1.45,
              ),
            ),
            if (footer != null) ...[const SizedBox(height: 12), footer!],
          ],
        ),
      ),
    );
  }
}

class _RingBody extends StatelessWidget {
  const _RingBody({
    required this.size,
    required this.palette,
    required this.model,
    required this.remainingKey,
    required this.remainingValue,
    required this.semanticsLabel,
  });

  final double size;
  final ChildTimeRingPalette palette;
  final ChildTimeRingModel model;
  final Key remainingKey;
  final String remainingValue;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    return Semantics(
      key: ChildDayBoardPolishKeys.heroRing,
      excludeSemantics: true,
      label: semanticsLabel ?? remainingValue,
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size.square(size),
              painter: _ChildTimeRingPainter(
                segments: <_RingArc>[
                  if ((model.usedFraction ?? 0) > 0)
                    _RingArc(
                      fraction: model.usedFraction ?? 0,
                      color: palette.used,
                    ),
                  if ((model.earnedFraction ?? 0) > 0)
                    _RingArc(
                      fraction: model.earnedFraction ?? 0,
                      color: palette.earned,
                    ),
                  if ((model.grantedFraction ?? 0) > 0)
                    _RingArc(
                      fraction: model.grantedFraction ?? 0,
                      color: palette.granted,
                    ),
                ],
                trackColor: palette.track,
                strokeWidth: math.max(10.0, size * 0.075),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(size * 0.19),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: size * 0.30,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: Text(
                        key: remainingKey,
                        remainingValue,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: colors.ink,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
                  if (model.usedFraction != null) ...[
                    SizedBox(height: size * 0.03),
                    Text(
                      '${(model.usedFraction! * 100).round()}%',
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: palette.accent,
                        height: 1.2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One coloured slice of the hero ring.
@immutable
final class _RingArc {
  const _RingArc({required this.fraction, required this.color});

  final double fraction;
  final Color color;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _RingArc && other.fraction == fraction && other.color == color;

  @override
  int get hashCode => Object.hash(fraction, color);
}

class _ChildTimeRingPainter extends CustomPainter {
  _ChildTimeRingPainter({
    required this.segments,
    required this.trackColor,
    required this.strokeWidth,
  });

  final List<_RingArc> segments;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final side = math.min(size.width, size.height);
    final radius = (side - strokeWidth) / 2;
    if (radius <= 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = trackColor;
    canvas.drawCircle(center, radius, track);

    var cursor = -math.pi / 2;
    for (final segment in segments) {
      final sweep = 2 * math.pi * segment.fraction;
      if (sweep <= 0) continue;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = segment.color;
      canvas.drawArc(rect, cursor, sweep, false, paint);
      cursor += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _ChildTimeRingPainter oldDelegate) {
    return oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.segments.length != segments.length ||
        !listEquals(oldDelegate.segments, segments);
  }
}

/// A soft pill used inside the ring card header.
class _RingChip extends StatelessWidget {
  const _RingChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    return Container(
      constraints: const BoxConstraints(maxWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(radii.pill),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
          height: 1.3,
        ),
      ),
    );
  }
}

/// Legend pill: a colour, a word, and the minutes behind the word — only when there are any.
///
/// A zero is never printed here. "0 minutes earned" and "you have not earned any yet" are the
/// same fact, and the second one is the one a child reads without thinking the app is broken.
class _LegendChip extends StatelessWidget {
  const _LegendChip({
    required this.color,
    required this.label,
    required this.minutes,
  });

  final Color color;
  final String label;
  final int? minutes;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final shown = minutes ?? 0;
    return Container(
      constraints: const BoxConstraints(maxWidth: 168),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radii.pill),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: colors.ink2,
                height: 1.3,
              ),
            ),
          ),
          if (shown > 0) ...[
            const SizedBox(width: 6),
            Text(
              '$shown',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: color,
                height: 1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The expressive "where am I in my day" card (🌙 · 🎒 · 🎮).
///
/// The active phase is drawn large and lit; the others stay visible but quiet, so a child can
/// see what comes next instead of being told only that something is forbidden now.
class ChildRoutineBadgeCard extends StatelessWidget {
  const ChildRoutineBadgeCard({
    super.key,
    required this.phase,
    required this.title,
    required this.hint,
    required this.sleepLabel,
    required this.schoolLabel,
    required this.freeLabel,
    required this.windDownLabel,
  });

  final ChildRoutinePhase phase;
  final String title;
  final String hint;
  final String sleepLabel;
  final String schoolLabel;
  final String freeLabel;
  final String windDownLabel;

  static const List<ChildRoutinePhase> _order = [
    ChildRoutinePhase.free,
    ChildRoutinePhase.school,
    ChildRoutinePhase.windDown,
    ChildRoutinePhase.sleep,
  ];

  String _label(ChildRoutinePhase value) => switch (value) {
    ChildRoutinePhase.free => freeLabel,
    ChildRoutinePhase.school => schoolLabel,
    ChildRoutinePhase.windDown => windDownLabel,
    ChildRoutinePhase.sleep => sleepLabel,
  };

  String _glyph(ChildRoutinePhase value) => switch (value) {
    ChildRoutinePhase.free => '🎮',
    ChildRoutinePhase.school => '🎒',
    ChildRoutinePhase.windDown => '✨',
    ChildRoutinePhase.sleep => '🌙',
  };

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    return DecoratedBox(
      key: ChildDayBoardPolishKeys.routineCard,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radii.cardChild),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: colors.ink,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final value in _order)
                  _RoutineBadge(
                    key: Key(
                      '${ChildDayBoardPolishKeys.routineBadgePrefix}${value.name}',
                    ),
                    glyph: _glyph(value),
                    label: _label(value),
                    active: value == phase,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              hint,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: colors.ink2,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoutineBadge extends StatelessWidget {
  const _RoutineBadge({
    super.key,
    required this.glyph,
    required this.label,
    required this.active,
  });

  final String glyph;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      constraints: const BoxConstraints(maxWidth: 170),
      padding: EdgeInsets.symmetric(
        horizontal: active ? 12 : 10,
        vertical: active ? 10 : 8,
      ),
      decoration: BoxDecoration(
        color: active ? colors.p100 : colors.bg,
        borderRadius: BorderRadius.circular(radii.pill),
        border: Border.all(color: active ? colors.p400 : colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            glyph,
            style: const TextStyle(fontSize: 16, height: 1.2),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: active ? 12.5 : 11.5,
                fontWeight: active ? FontWeight.w900 : FontWeight.w700,
                color: active ? colors.p700 : colors.ink2,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One task, as a card the child can read in a second.
class ChildEarnTaskTile extends StatelessWidget {
  const ChildEarnTaskTile({
    super.key,
    required this.task,
    required this.pointsLabel,
    required this.statusLabel,
  });

  final ChildEarnTaskCard task;
  final String pointsLabel;
  final String statusLabel;

  IconData get _icon => switch (task.status) {
    ChildEarnTaskStatus.notSent => Icons.assignment,
    ChildEarnTaskStatus.awaitingGuardian => Icons.hourglass_bottom,
    ChildEarnTaskStatus.rewarded => Icons.emoji_events,
    ChildEarnTaskStatus.declined => Icons.chat_bubble,
    ChildEarnTaskStatus.closed => Icons.task_alt,
  };

  Color _tint(FamilyColors colors) => switch (task.status) {
    ChildEarnTaskStatus.notSent => colors.sky.withValues(alpha: 0.18),
    ChildEarnTaskStatus.awaitingGuardian => colors.amber100,
    ChildEarnTaskStatus.rewarded => colors.mint100,
    ChildEarnTaskStatus.declined => colors.p50,
    ChildEarnTaskStatus.closed => colors.bg,
  };

  Color _ink(FamilyColors colors) => switch (task.status) {
    ChildEarnTaskStatus.notSent => colors.tealDeep,
    ChildEarnTaskStatus.awaitingGuardian => colors.amberDeep,
    ChildEarnTaskStatus.rewarded => colors.mintInk,
    ChildEarnTaskStatus.declined => colors.p700,
    ChildEarnTaskStatus.closed => colors.ink2,
  };

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final title = task.title.trim().isEmpty ? '·' : task.title.trim();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radii.tcard),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _tint(colors),
                borderRadius: BorderRadius.circular(radii.tcardIcon),
              ),
              child: Icon(_icon, size: 20, color: _ink(colors)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: colors.ink,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    statusLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: _ink(colors),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              constraints: const BoxConstraints(maxWidth: 96),
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: colors.amber100,
                borderRadius: BorderRadius.circular(radii.pill),
              ),
              child: Text(
                pointsLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: colors.amberDeep,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The safety button: honest affordance, deliberate press, no accidental calls.
///
/// A hold is the only gesture that arms it, the ring says how far the hold has gone, letting
/// go early says "nothing opened" instead of staying silent, and completing it hands off to
/// the real emergency screen — which is where the actual send happens and where the real
/// state is stated. This card claims nothing beyond opening that door.
class ChildSafetyHoldButton extends StatefulWidget {
  const ChildSafetyHoldButton({
    super.key,
    required this.holdDuration,
    required this.onHoldCompleted,
    required this.title,
    required this.instruction,
    required this.releasedMessage,
    required this.progressLabel,
    required this.semanticsLabel,
    this.enabled = true,
  });

  final Duration holdDuration;
  final VoidCallback onHoldCompleted;
  final String title;
  final String instruction;
  final String releasedMessage;
  final String Function(int secondsRemaining) progressLabel;
  final String semanticsLabel;
  final bool enabled;

  @override
  State<ChildSafetyHoldButton> createState() => ChildSafetyHoldButtonState();
}

@visibleForTesting
class ChildSafetyHoldButtonState extends State<ChildSafetyHoldButton> {
  static const Duration _tick = Duration(milliseconds: 50);
  static const Duration _notice = Duration(milliseconds: 2600);

  Timer? _ticker;
  Timer? _noticeTimer;
  Duration _elapsed = Duration.zero;
  bool _holding = false;
  bool _showReleased = false;

  double get _progress {
    final total = widget.holdDuration.inMilliseconds;
    if (total <= 0) return 1;
    return (_elapsed.inMilliseconds / total).clamp(0.0, 1.0);
  }

  int get _secondsLeft {
    final leftMs = widget.holdDuration.inMilliseconds - _elapsed.inMilliseconds;
    if (leftMs <= 0) return 0;
    return ((leftMs + 999) ~/ 1000);
  }

  void _start() {
    if (!widget.enabled || _holding) return;
    _noticeTimer?.cancel();
    setState(() {
      _holding = true;
      _showReleased = false;
      _elapsed = Duration.zero;
    });
    _ticker = Timer.periodic(_tick, (_) {
      if (!mounted) return;
      final next = _elapsed + _tick;
      if (next >= widget.holdDuration) {
        _finish();
        return;
      }
      setState(() => _elapsed = next);
    });
  }

  /// The hold completed: this is the only path that says anything was sent.
  ///
  /// The line a child reads after it is the app's own answer, so it is shown here and nowhere
  /// else — a button that reports success when a finger merely left early would teach a child
  /// that help was on the way when nothing was.
  void _finish() {
    _ticker?.cancel();
    _ticker = null;
    setState(() {
      _holding = false;
      _elapsed = widget.holdDuration;
      _showReleased = true;
    });
    _noticeTimer = Timer(_notice, () {
      if (!mounted) return;
      setState(() => _showReleased = false);
    });
    widget.onHoldCompleted();
  }

  /// Letting go before the hold finished. It cancels; it reports nothing.
  void _release() {
    if (!_holding) return;
    _ticker?.cancel();
    _ticker = null;
    setState(() {
      _holding = false;
      _elapsed = Duration.zero;
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _noticeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final label = _showReleased
        ? widget.releasedMessage
        : (_holding
              ? widget.progressLabel(_secondsLeft)
              : widget.instruction);
    return Semantics(
      key: ChildDayBoardPolishKeys.safetyHold,
      button: true,
      enabled: widget.enabled,
      label: widget.semanticsLabel,
      excludeSemantics: true,
      child: GestureDetector(
        onTapDown: widget.enabled ? (_) => _start() : null,
        onTapUp: widget.enabled ? (_) => _release() : null,
        onTapCancel: widget.enabled ? _release : null,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            gradient: _holding
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [colors.coral, colors.coral.withValues(alpha: 0.82)],
                  )
                : null,
            color: _holding ? null : colors.surface,
            borderRadius: BorderRadius.circular(radii.cardChild),
            border: Border.all(
              color: _holding ? colors.coral : colors.coral100,
              width: _holding ? 2 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  key: ChildDayBoardPolishKeys.safetyProgress,
                  width: 44,
                  height: 44,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: _progress,
                        strokeWidth: 4,
                        backgroundColor: colors.coral100,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _holding ? colors.surface : colors.coral,
                        ),
                      ),
                      Icon(
                        Icons.sos,
                        size: 18,
                        color: _holding ? colors.surface : colors.coral,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                          color: _holding ? colors.surface : colors.ink,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: _holding
                              ? colors.surface.withValues(alpha: 0.95)
                              : colors.ink2,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "My tasks and rewards" — the minutes economy, in the child's own words.
///
/// The card carries all five states because the section reads a server: still loading, real
/// tasks, nothing to do, no server session, and a refusal that says "the server did not
/// answer" instead of showing yesterday's tasks as today's. The list itself is capped by the
/// model, not here, so what a child sees is what the economy chose to put first.
class ChildEarnTasksCard extends StatelessWidget {
  const ChildEarnTasksCard({
    super.key,
    required this.economy,
    required this.title,
    required this.subtitle,
    required this.stateMessage,
    required this.pointsLabel,
    required this.statusLabel,
    this.openAllLabel,
    this.onOpenAll,
  });

  final ChildDayBoardEconomy economy;
  final String title;
  final String subtitle;

  /// The sentence for the non-`ready` phases — loading, empty, no server, error.
  final String Function(ChildDayBoardEconomyPhase phase) stateMessage;

  /// Words the caller owns, so this file never builds a sentence out of a numeral.
  final String Function(int points) pointsLabel;
  final String Function(ChildEarnTaskStatus status) statusLabel;
  final String? openAllLabel;
  final VoidCallback? onOpenAll;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final tasks = economy.headlineTasks;
    final showList =
        economy.phase == ChildDayBoardEconomyPhase.ready && tasks.isNotEmpty;
    return DecoratedBox(
      key: ChildDayBoardPolishKeys.tasksCard,
      decoration: BoxDecoration(
        color: colors.p50,
        borderRadius: BorderRadius.circular(radii.cardChild),
        border: Border.all(color: colors.p100),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: colors.ink,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: colors.ink2,
                height: 1.45,
              ),
            ),
            if (showList) ...[
              const SizedBox(height: 12),
              Column(
                key: ChildDayBoardPolishKeys.tasksList,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final task in tasks)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ChildEarnTaskTile(
                        key: Key(
                          '${ChildDayBoardPolishKeys.taskTilePrefix}${task.id}',
                        ),
                        task: task,
                        pointsLabel: pointsLabel(task.points),
                        statusLabel: statusLabel(task.status),
                      ),
                    ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 10),
              Text(
                key: ChildDayBoardPolishKeys.tasksState,
                stateMessage(economy.phase),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: colors.ink2,
                  height: 1.5,
                ),
              ),
            ],
            if (openAllLabel != null && onOpenAll != null) ...[
              const SizedBox(height: 4),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  key: ChildDayBoardPolishKeys.tasksOpenAll,
                  onPressed: onOpenAll,
                  icon: const Icon(Icons.menu_book, size: 18),
                  label: Text(openAllLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// One one-tap route to a person or a place that always answers.
@immutable
final class FamilyTouchpoint {
  const FamilyTouchpoint({
    required this.id,
    required this.label,
    required this.glyph,
    required this.onTap,
    this.badge,
  });

  final String id;
  final String label;
  final IconData glyph;
  final VoidCallback? onTap;

  /// An optional count a parent's message left behind; null means nothing to announce, and
  /// the chip is simply not drawn.
  final String? badge;
}

/// The family touchpoints rail.
///
/// Deliberately a `Wrap`, not a row: four one-tap chips at 2.0 text scale on a 360 dp phone
/// is exactly the layout that breaks in a `Row`, and a parent's face is not a layout bug.
class FamilyTouchpointStrip extends StatelessWidget {
  const FamilyTouchpointStrip({
    super.key,
    required this.title,
    required this.subtitle,
    required this.points,
  });

  final String title;
  final String subtitle;
  final List<FamilyTouchpoint> points;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    return DecoratedBox(
      key: ChildDayBoardPolishKeys.touchpointsCard,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radii.cardChild),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: colors.ink,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: colors.ink2,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final point in points)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 128),
                    child: _TouchpointChip(
                      key: Key(
                        '${ChildDayBoardPolishKeys.touchpointPrefix}${point.id}',
                      ),
                      point: point,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TouchpointChip extends StatelessWidget {
  const _TouchpointChip({super.key, required this.point});

  final FamilyTouchpoint point;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final enabled = point.onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: point.label,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: point.onTap,
          borderRadius: BorderRadius.circular(radii.tcard),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: enabled ? colors.p50 : colors.bg,
              borderRadius: BorderRadius.circular(radii.tcard),
              border: Border.all(color: colors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        point.glyph,
                        size: 22,
                        color: enabled ? colors.p600 : colors.ink2,
                      ),
                      if (point.badge != null)
                        PositionedDirectional(
                          top: -4,
                          end: -6,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: colors.coral,
                              borderRadius: BorderRadius.circular(radii.pill),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              child: Text(
                                point.badge!,
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    point.label,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: enabled ? colors.ink : colors.ink2,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
