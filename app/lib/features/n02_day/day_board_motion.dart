import 'package:flutter/material.dart';

/// UI-017 — day-board motion helper (a11y / Rule 16 spirit).
///
/// When [MediaQuery.disableAnimations] is set (OS reduce-motion), nonessential
/// motion must collapse to zero duration so controllers skip / finish instantly.
Duration dayBoardMotionDuration(BuildContext context, Duration preferred) {
  if (MediaQuery.disableAnimationsOf(context)) {
    return Duration.zero;
  }
  return preferred;
}

/// Whether day-board decorative motion may run.
bool dayBoardMotionEnabled(BuildContext context) =>
    !MediaQuery.disableAnimationsOf(context);

/// Soft opacity/scale pulse for day-board chrome — gated by reduce-motion.
///
/// Controllers use [dayBoardMotionDuration]; when animations are disabled the
/// controller duration is [Duration.zero] and the ticker stays stopped.
class DayBoardMotionPulse extends StatefulWidget {
  const DayBoardMotionPulse({
    super.key,
    required this.child,
    this.preferredDuration = const Duration(milliseconds: 1100),
    this.enabled = true,
    this.mode = DayBoardMotionPulseMode.scale,
  });

  final Widget child;
  final Duration preferredDuration;

  /// When false (e.g. idle child status), motion stays off even if animations
  /// are allowed.
  final bool enabled;

  final DayBoardMotionPulseMode mode;

  @override
  State<DayBoardMotionPulse> createState() => DayBoardMotionPulseState();
}

enum DayBoardMotionPulseMode { scale, opacity }

class DayBoardMotionPulseState extends State<DayBoardMotionPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: widget.preferredDuration,
    );
  }

  @override
  void didUpdateWidget(covariant DayBoardMotionPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  void _sync() {
    final duration = dayBoardMotionDuration(context, widget.preferredDuration);
    controller.duration = duration;
    if (duration == Duration.zero || !widget.enabled) {
      controller.stop();
      controller.value = 1;
      return;
    }
    // One-shot soft pulse (not infinite) so widget tests can pumpAndSettle.
    if (!controller.isAnimating && controller.status != AnimationStatus.completed) {
      controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final motionOn = dayBoardMotionEnabled(context) && widget.enabled;
        final t = motionOn ? controller.value : 1.0;
        return switch (widget.mode) {
          DayBoardMotionPulseMode.scale => Transform.scale(
              scale: 0.92 + (0.08 * t),
              child: child,
            ),
          DayBoardMotionPulseMode.opacity => Opacity(
              opacity: 0.88 + (0.12 * t),
              child: child,
            ),
        };
      },
      child: widget.child,
    );
  }
}
