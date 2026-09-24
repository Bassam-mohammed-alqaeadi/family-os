import 'package:family_os/features/n17_child_learn/child_family_challenges_models.dart';

abstract class ChildFamilyChallengesRepository {
  Future<ChildFamilyChallengesSnapshot> load();
}

final class InMemoryChildFamilyChallengesRepository
    implements ChildFamilyChallengesRepository {
  InMemoryChildFamilyChallengesRepository({ChildFamilyChallengesSnapshot? seed})
    : _snap = seed ?? childFamilyChallengesPrototypeFixture();

  ChildFamilyChallengesSnapshot _snap;
  Future<void> Function()? loadGate;

  @override
  Future<ChildFamilyChallengesSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    return ChildFamilyChallengesSnapshot(
      hasChallenges: _snap.hasChallenges,
      activeTitleKey: _snap.activeTitleKey,
      activeSubKey: _snap.activeSubKey,
      peers: List<FamilyChallengePeer>.from(_snap.peers),
      done: List<FamilyChallengeDone>.from(_snap.done),
    );
  }

  void seed(ChildFamilyChallengesSnapshot snap) => _snap = snap;
}

final InMemoryChildFamilyChallengesRepository
stage1ChildFamilyChallengesRepository =
    InMemoryChildFamilyChallengesRepository();

ChildFamilyChallengesSnapshot childFamilyChallengesEmptyFixture() =>
    const ChildFamilyChallengesSnapshot();

ChildFamilyChallengesSnapshot childFamilyChallengesOneFixture() {
  return const ChildFamilyChallengesSnapshot(
    hasChallenges: true,
    peers: [
      FamilyChallengePeer(
        id: 'you',
        labelKey: 'you',
        days: [
          FamilyChallengeDay(done: true),
          FamilyChallengeDay(done: true),
          FamilyChallengeDay(done: false),
        ],
      ),
    ],
  );
}

ChildFamilyChallengesSnapshot childFamilyChallengesPrototypeFixture() {
  const week = [
    FamilyChallengeDay(done: true),
    FamilyChallengeDay(done: true),
    FamilyChallengeDay(done: true),
    FamilyChallengeDay(done: true),
    FamilyChallengeDay(done: false),
    FamilyChallengeDay(done: false),
    FamilyChallengeDay(done: false),
  ];
  return const ChildFamilyChallengesSnapshot(
    hasChallenges: true,
    peers: [
      FamilyChallengePeer(id: 'you', labelKey: 'you', days: week),
      FamilyChallengePeer(id: 'sib', labelKey: 'sibling', days: week),
    ],
    done: [
      FamilyChallengeDone(
        id: 'fajr',
        titleKey: 'fajrWeek',
        subKey: 'fajrWeekSub',
        emoji: '🕌',
      ),
      FamilyChallengeDone(
        id: 'amma',
        titleKey: 'ammaKhatma',
        subKey: 'ammaKhatmaSub',
        emoji: '📖',
      ),
    ],
  );
}
