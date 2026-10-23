// S3 measurement — when a handset may speak.
//
// The report is cumulative and the server keeps the larger total, so a missed report costs
// nothing and a repeated one costs battery. Every rule below is one half of that trade.
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/foundation_gate/usage_report_rhythm.dart';

void main() {
  late DateTime now;
  UsageReportRhythm rhythm({int maxPerHour = 12}) => UsageReportRhythm(
    clock: () => now,
    maxPerHour: maxPerHour,
  );

  setUp(() => now = DateTime(2026, 10, 23, 9));

  test('the first look of a session always reports', () {
    expect(rhythm().shouldReport(), isTrue);
  });

  test('a second look straight away does not', () {
    final r = rhythm()..recordAttempt();
    now = now.add(const Duration(seconds: 5));

    expect(
      r.shouldReport(),
      isFalse,
      reason: 'two reports five seconds apart say the same thing',
    );
  });

  test('ten minutes of use is worth one report', () {
    final r = rhythm()..recordAttempt();
    now = now.add(const Duration(minutes: 9));
    expect(r.shouldReport(), isFalse);

    now = now.add(const Duration(minutes: 1));
    expect(r.shouldReport(), isTrue);
  });

  test('picking the phone up reports sooner, but not instantly', () {
    final r = rhythm()..recordAttempt();

    now = now.add(const Duration(seconds: 10));
    expect(r.shouldReport(resumed: true), isFalse);

    now = now.add(const Duration(seconds: 40));
    expect(
      r.shouldReport(resumed: true),
      isTrue,
      reason: 'a child returning to the phone is exactly when the day changed',
    );
  });

  test('a failed attempt still spends the slot', () {
    // There is no failure flag on purpose: the attempt is recorded before the network is
    // asked, so a dead connection waits for the next window instead of retrying in a loop.
    final r = rhythm()..recordAttempt();
    now = now.add(const Duration(seconds: 2));

    expect(r.shouldReport(), isFalse);
    expect(r.shouldReport(resumed: true), isFalse);
  });

  test('no more than twelve attempts in a rolling hour', () {
    final r = rhythm(maxPerHour: 12);
    for (var i = 0; i < 12; i++) {
      r.recordAttempt();
      now = now.add(const Duration(minutes: 1));
    }

    expect(r.shouldReport(resumed: true), isFalse);
    expect(r.attemptsThisHour, 12);

    // An hour after the first attempt, the window has room again.
    now = DateTime(2026, 10, 23, 10, 1);
    expect(r.shouldReport(), isTrue);
  });
}
