import 'package:family_os/features/n02_day/child_media_share_models.dart';

abstract class ChildMediaShareRepository {
  Future<ChildMediaShareSnapshot> load();

  /// Local intent only — camera/mic/file Native CLOSED.
  Future<void> queueShareIntent(ChildMediaShareType type);
}

final class InMemoryChildMediaShareRepository
    implements ChildMediaShareRepository {
  InMemoryChildMediaShareRepository({ChildMediaShareSnapshot? seed})
      : _snap = seed ?? childMediaShareEmptyFixture();

  ChildMediaShareSnapshot _snap;
  Future<void> Function()? loadGate;
  Object? loadError;
  final List<ChildMediaShareType> queuedIntents = [];

  @override
  Future<ChildMediaShareSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    final err = loadError;
    if (err != null) {
      loadError = null;
      throw err;
    }
    return ChildMediaShareSnapshot(
      recentShares: List<ChildMediaShareItem>.from(_snap.recentShares),
      intentJournal: List<String>.from(_snap.intentJournal),
    );
  }

  @override
  Future<void> queueShareIntent(ChildMediaShareType type) async {
    queuedIntents.add(type);
    _snap = ChildMediaShareSnapshot(
      recentShares: _snap.recentShares,
      intentJournal: [..._snap.intentJournal, type.name],
    );
  }

  void seed(ChildMediaShareSnapshot snap) => _snap = snap;
}

/// Shared Stage-1 — empty until Local bind / test seed (CE-B1 / CE-G021).
ChildMediaShareRepository stage1ChildMediaShareRepository =
    InMemoryChildMediaShareRepository(seed: childMediaShareEmptyFixture());

void rebindStage1ChildMediaShareRepository(
  ChildMediaShareRepository repository,
) {
  stage1ChildMediaShareRepository = repository;
}

ChildMediaShareSnapshot childMediaShareEmptyFixture() =>
    const ChildMediaShareSnapshot();

ChildMediaShareSnapshot childMediaShareOneFixture() {
  return const ChildMediaShareSnapshot(
    recentShares: [
      ChildMediaShareItem(
        id: 'm1',
        type: ChildMediaShareType.photo,
        titleKey: 'photoGoal',
        subtitleKey: 'photoGoalSub',
      ),
    ],
  );
}

/// LOCAL_DEMO / tests only — not production stage1 default.
ChildMediaShareSnapshot childMediaSharePrototypeFixture() {
  return const ChildMediaShareSnapshot(
    recentShares: [
      ChildMediaShareItem(
        id: 'm1',
        type: ChildMediaShareType.photo,
        titleKey: 'photoGoal',
        subtitleKey: 'photoGoalSub',
      ),
      ChildMediaShareItem(
        id: 'm2',
        type: ChildMediaShareType.voice,
        titleKey: 'voiceShoes',
        subtitleKey: 'voiceShoesSub',
        hasTranscript: true,
      ),
    ],
  );
}
