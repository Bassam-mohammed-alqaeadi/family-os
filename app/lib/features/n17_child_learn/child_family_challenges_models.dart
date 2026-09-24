import 'package:flutter/foundation.dart';

@immutable
final class FamilyChallengeDay {
  const FamilyChallengeDay({required this.done});
  final bool done;
}

@immutable
final class FamilyChallengePeer {
  const FamilyChallengePeer({
    required this.id,
    required this.labelKey,
    required this.days,
  });

  final String id;
  final String labelKey;
  final List<FamilyChallengeDay> days;
}

@immutable
final class FamilyChallengeDone {
  const FamilyChallengeDone({
    required this.id,
    required this.titleKey,
    required this.subKey,
    required this.emoji,
  });

  final String id;
  final String titleKey;
  final String subKey;
  final String emoji;
}

@immutable
final class ChildFamilyChallengesSnapshot {
  const ChildFamilyChallengesSnapshot({
    this.hasChallenges = false,
    this.activeTitleKey = 'reviewMarathon',
    this.activeSubKey = 'reviewMarathonSub',
    this.peers = const [],
    this.done = const [],
  });

  final bool hasChallenges;
  final String activeTitleKey;
  final String activeSubKey;
  final List<FamilyChallengePeer> peers;
  final List<FamilyChallengeDone> done;

  bool get isEmpty => !hasChallenges;
}
