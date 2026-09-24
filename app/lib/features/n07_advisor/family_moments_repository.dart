import 'package:family_os/features/n07_advisor/family_moments_models.dart';

abstract class FamilyMomentsRepository {
  Future<FamilyMomentsSnapshot> load();
  Future<FamilyMomentsSnapshot> sharePrideCard();
  Future<FamilyMomentsSnapshot> remindTouch();
  Future<FamilyMomentsSnapshot> addMoment();
}

final class InMemoryFamilyMomentsRepository implements FamilyMomentsRepository {
  InMemoryFamilyMomentsRepository({FamilyMomentsSnapshot? seed})
    : _snap = seed ?? familyMomentsPrototypeFixture();

  FamilyMomentsSnapshot _snap;
  Future<void> Function()? loadGate;

  @override
  Future<FamilyMomentsSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    return _copy();
  }

  @override
  Future<FamilyMomentsSnapshot> sharePrideCard() async {
    _snap = FamilyMomentsSnapshot(
      hasFamily: _snap.hasFamily,
      weekLabelKey: _snap.weekLabelKey,
      learnHours: _snap.learnHours,
      versesMemorized: _snap.versesMemorized,
      tasksDone: _snap.tasksDone,
      worryAlerts: _snap.worryAlerts,
      stars: List<FamilyMomentStar>.from(_snap.stars),
      touchHintKey: _snap.touchHintKey,
      album: List<FamilyMomentAlbumItem>.from(_snap.album),
      prideShared: true,
      touchReminded: _snap.touchReminded,
    );
    return _copy();
  }

  @override
  Future<FamilyMomentsSnapshot> remindTouch() async {
    _snap = FamilyMomentsSnapshot(
      hasFamily: _snap.hasFamily,
      weekLabelKey: _snap.weekLabelKey,
      learnHours: _snap.learnHours,
      versesMemorized: _snap.versesMemorized,
      tasksDone: _snap.tasksDone,
      worryAlerts: _snap.worryAlerts,
      stars: List<FamilyMomentStar>.from(_snap.stars),
      touchHintKey: _snap.touchHintKey,
      album: List<FamilyMomentAlbumItem>.from(_snap.album),
      prideShared: _snap.prideShared,
      touchReminded: true,
    );
    return _copy();
  }

  @override
  Future<FamilyMomentsSnapshot> addMoment() async {
    final next = [
      const FamilyMomentAlbumItem(
        id: 'new',
        captionKey: 'capNew',
        byKey: 'byFather',
        whenKey: 'whenNow',
        emoji: '✨',
      ),
      ..._snap.album,
    ];
    _snap = FamilyMomentsSnapshot(
      hasFamily: _snap.hasFamily,
      weekLabelKey: _snap.weekLabelKey,
      learnHours: _snap.learnHours,
      versesMemorized: _snap.versesMemorized,
      tasksDone: _snap.tasksDone,
      worryAlerts: _snap.worryAlerts,
      stars: List<FamilyMomentStar>.from(_snap.stars),
      touchHintKey: _snap.touchHintKey,
      album: next,
      prideShared: _snap.prideShared,
      touchReminded: _snap.touchReminded,
    );
    return _copy();
  }

  void seed(FamilyMomentsSnapshot snap) => _snap = snap;

  bool get prideShared => _snap.prideShared;

  FamilyMomentsSnapshot _copy() => FamilyMomentsSnapshot(
    hasFamily: _snap.hasFamily,
    weekLabelKey: _snap.weekLabelKey,
    learnHours: _snap.learnHours,
    versesMemorized: _snap.versesMemorized,
    tasksDone: _snap.tasksDone,
    worryAlerts: _snap.worryAlerts,
    stars: List<FamilyMomentStar>.from(_snap.stars),
    touchHintKey: _snap.touchHintKey,
    album: List<FamilyMomentAlbumItem>.from(_snap.album),
    prideShared: _snap.prideShared,
    touchReminded: _snap.touchReminded,
  );
}

final InMemoryFamilyMomentsRepository stage1FamilyMomentsRepository =
    InMemoryFamilyMomentsRepository();

FamilyMomentsSnapshot familyMomentsEmptyFixture() =>
    const FamilyMomentsSnapshot();

FamilyMomentsSnapshot familyMomentsOneFixture() {
  return const FamilyMomentsSnapshot(
    hasFamily: true,
    learnHours: 3,
    versesMemorized: 5,
    tasksDone: 2,
    stars: [
      FamilyMomentStar(
        id: 's1',
        childLabelKey: 'childOne',
        titleKey: 'starQuran',
        subKey: 'starQuranSub',
        emoji: '👑',
      ),
    ],
    album: [
      FamilyMomentAlbumItem(
        id: 'a1',
        captionKey: 'capGarden',
        byKey: 'byMother',
        whenKey: 'whenYesterday',
        emoji: '🌱',
      ),
    ],
  );
}

FamilyMomentsSnapshot familyMomentsPrototypeFixture() {
  return const FamilyMomentsSnapshot(
    hasFamily: true,
    learnHours: 12,
    versesMemorized: 47,
    tasksDone: 21,
    worryAlerts: 0,
    stars: [
      FamilyMomentStar(
        id: 's1',
        childLabelKey: 'childOne',
        titleKey: 'starQuran',
        subKey: 'starQuranSub',
        emoji: '👑',
      ),
      FamilyMomentStar(
        id: 's2',
        childLabelKey: 'childTwo',
        titleKey: 'starMath',
        subKey: 'starMathSub',
        emoji: '🚀',
      ),
      FamilyMomentStar(
        id: 's3',
        childLabelKey: 'childOne',
        titleKey: 'starSleep',
        subKey: 'starSleepSub',
        emoji: '🌙',
      ),
    ],
    album: [
      FamilyMomentAlbumItem(
        id: 'a1',
        captionKey: 'capGarden',
        byKey: 'byMother',
        whenKey: 'whenYesterday',
        emoji: '🌱',
      ),
      FamilyMomentAlbumItem(
        id: 'a2',
        captionKey: 'capPrayer',
        byKey: 'byFather',
        whenKey: 'whenTue',
        emoji: '🤲',
      ),
      FamilyMomentAlbumItem(
        id: 'a3',
        captionKey: 'capCook',
        byKey: 'byChildOne',
        whenKey: 'whenMon',
        emoji: '🍳',
      ),
      FamilyMomentAlbumItem(
        id: 'a4',
        captionKey: 'capRead',
        byKey: 'byChildTwo',
        whenKey: 'whenSun',
        emoji: '📖',
      ),
      FamilyMomentAlbumItem(
        id: 'a5',
        captionKey: 'capWalk',
        byKey: 'byMother',
        whenKey: 'whenSat',
        emoji: '🚶',
      ),
      FamilyMomentAlbumItem(
        id: 'a6',
        captionKey: 'capLaugh',
        byKey: 'byFather',
        whenKey: 'whenFri',
        emoji: '😄',
      ),
    ],
  );
}
