import 'package:family_os/features/n02_day/children_list_repository.dart';
import 'package:family_os/features/n07_advisor/family_moments_models.dart';
import 'package:family_os/features/n16_tasks/family_tasks_models.dart';
import 'package:family_os/features/n16_tasks/family_tasks_repository.dart';

abstract class FamilyMomentsRepository {
  Future<FamilyMomentsSnapshot> load();
  Future<FamilyMomentsSnapshot> sharePrideCard();
  Future<FamilyMomentsSnapshot> remindTouch();
  Future<FamilyMomentsSnapshot> addMoment();
}

/// Projects Local family tasks (+ roster) into moments aggregates (CE-B2 / CE-G010).
///
/// No prototype learnHours/verses — those stay 0 until owned Local sources exist.
final class LocalFactsFamilyMomentsRepository
    implements FamilyMomentsRepository {
  LocalFactsFamilyMomentsRepository({
    FamilyTasksRepository? familyTasks,
    ChildrenListRepository? children,
  }) : _familyTasksOverride = familyTasks,
       _childrenOverride = children;

  final FamilyTasksRepository? _familyTasksOverride;
  final ChildrenListRepository? _childrenOverride;

  FamilyTasksRepository get _familyTasks =>
      _familyTasksOverride ?? stage1FamilyTasksRepository;

  ChildrenListRepository get _children =>
      _childrenOverride ?? stage1ChildrenListRepository;

  var _prideShared = false;
  var _touchReminded = false;
  final List<FamilyMomentAlbumItem> _album = [];

  Future<void> Function()? loadGate;

  @override
  Future<FamilyMomentsSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    return _project();
  }

  @override
  Future<FamilyMomentsSnapshot> sharePrideCard() async {
    _prideShared = true;
    return _project();
  }

  @override
  Future<FamilyMomentsSnapshot> remindTouch() async {
    _touchReminded = true;
    return _project();
  }

  @override
  Future<FamilyMomentsSnapshot> addMoment() async {
    _album.insert(
      0,
      const FamilyMomentAlbumItem(
        id: 'new',
        captionKey: 'capNew',
        byKey: 'byFather',
        whenKey: 'whenNow',
        emoji: '✨',
      ),
    );
    return _project();
  }

  Future<FamilyMomentsSnapshot> _project() async {
    final roster = await _children.listChildren();
    if (roster.isEmpty) return familyMomentsEmptyFixture();

    final tasks = await _familyTasks.load();
    final done = tasks.childTasks
        .where((t) => t.status == FamilyTaskStatus.completed)
        .length;

    return FamilyMomentsSnapshot(
      hasFamily: true,
      learnHours: 0,
      versesMemorized: 0,
      tasksDone: done,
      worryAlerts: 0,
      stars: const [],
      album: List<FamilyMomentAlbumItem>.from(_album),
      prideShared: _prideShared,
      touchReminded: _touchReminded,
    );
  }
}

final class InMemoryFamilyMomentsRepository implements FamilyMomentsRepository {
  InMemoryFamilyMomentsRepository({FamilyMomentsSnapshot? seed})
    : _snap = seed ?? familyMomentsEmptyFixture();

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

/// Shared Stage-1 — Local-facts projector (empty when roster empty) (CE-B2).
FamilyMomentsRepository stage1FamilyMomentsRepository =
    LocalFactsFamilyMomentsRepository();

void rebindStage1FamilyMomentsRepository(FamilyMomentsRepository repository) {
  stage1FamilyMomentsRepository = repository;
}

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

/// LOCAL_DEMO / tests only — not production stage1 default.
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
