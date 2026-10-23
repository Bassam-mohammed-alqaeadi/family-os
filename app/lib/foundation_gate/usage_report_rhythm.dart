/// How often a handset tells the server what today has cost so far.
///
/// The report is **cumulative**: it carries the day's total per app, and the server keeps
/// the larger of the two (`GREATEST`). That single fact decides the whole design here -
/// missing a report costs nothing, because the next one says everything; sending too many
/// costs battery, radio wake-ups and a parent's trust in a phone that keeps talking.
///
/// So the rhythm is biased one way only:
///
///   * the first look of a session always reports, because a screen that opens after six
///     hours asleep has the most to say;
///   * afterwards, at most once per [interval] while the app is in use;
///   * on coming back to the foreground, a shorter [resumeGap] - a child picking the phone
///     up is exactly when today's number changed;
///   * and never more than [maxPerHour] attempts in any rolling hour, so a child flicking
///     between apps cannot turn one handset into a poller.
///
/// A failed attempt still counts. Retrying a dead network every few seconds is how a
/// background job becomes a battery complaint, and the next scheduled attempt is minutes
/// away by design.
final class UsageReportRhythm {
  UsageReportRhythm({
    this.interval = const Duration(minutes: 10),
    this.resumeGap = const Duration(seconds: 45),
    this.maxPerHour = 12,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  /// The gap between two reports while the app stays open.
  final Duration interval;

  /// The gap that must pass before a return to the foreground counts as a new look.
  final Duration resumeGap;

  /// The rolling-hour ceiling on attempts, successful or not.
  final int maxPerHour;

  final DateTime Function() _clock;
  final List<DateTime> _attempts = <DateTime>[];

  /// The number of attempts still inside the current rolling hour. Exposed for tests and
  /// for a caller that wants to show \"last sent\" without keeping its own clock.
  int get attemptsThisHour {
    _prune(_clock());
    return _attempts.length;
  }

  /// Whether this moment is worth a report.
  ///
  /// [resumed] is true when the app has just come back to the foreground, which relaxes the
  /// gap and nothing else: the hour ceiling still applies, because a lock screen unlocked
  /// thirty times in a minute is one child, not thirty measurements.
  bool shouldReport({bool resumed = false}) {
    final now = _clock();
    _prune(now);
    if (_attempts.isEmpty) return true;
    if (_attempts.length >= maxPerHour) return false;
    final gap = now.difference(_attempts.last);
    return gap >= (resumed ? resumeGap : interval);
  }

  /// Records an attempt, whether it succeeded or not.
  void recordAttempt() {
    final now = _clock();
    _prune(now);
    _attempts.add(now);
  }

  void _prune(DateTime now) {
    _attempts.removeWhere((at) => now.difference(at) >= const Duration(hours: 1));
  }
}
