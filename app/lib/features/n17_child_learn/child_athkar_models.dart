import 'package:flutter/foundation.dart';

@immutable
final class ChildAthkarSnapshot {
  const ChildAthkarSnapshot({
    this.hasSession = false,
    this.sessionKey = 'evening',
    this.done = 0,
    this.total = 10,
    this.morningDone = 10,
    this.morningTotal = 10,
    this.thikrKey = 'amsayna',
  });

  final bool hasSession;
  final String sessionKey;
  final int done;
  final int total;
  final int morningDone;
  final int morningTotal;
  final String thikrKey;

  bool get isEmpty => !hasSession;
  bool get complete => done >= total;

  ChildAthkarSnapshot copyWith({int? done}) {
    return ChildAthkarSnapshot(
      hasSession: hasSession,
      sessionKey: sessionKey,
      done: done ?? this.done,
      total: total,
      morningDone: morningDone,
      morningTotal: morningTotal,
      thikrKey: thikrKey,
    );
  }
}
