import 'package:family_os/features/n02_day/child_media_share_models.dart';

abstract class ChildMediaShareRepository {
  Future<ChildMediaShareSnapshot> load();
}

final class InMemoryChildMediaShareRepository
    implements ChildMediaShareRepository {
  InMemoryChildMediaShareRepository({ChildMediaShareSnapshot? seed})
    : _snap = seed ?? childMediaSharePrototypeFixture();

  ChildMediaShareSnapshot _snap;
  Future<void> Function()? loadGate;

  @override
  Future<ChildMediaShareSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    return ChildMediaShareSnapshot(
      recentShares: List<ChildMediaShareItem>.from(_snap.recentShares),
    );
  }

  void seed(ChildMediaShareSnapshot snap) => _snap = snap;
}

final InMemoryChildMediaShareRepository stage1ChildMediaShareRepository =
    InMemoryChildMediaShareRepository();

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
