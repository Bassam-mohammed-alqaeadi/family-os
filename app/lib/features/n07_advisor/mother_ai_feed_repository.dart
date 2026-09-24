import 'package:family_os/features/n07_advisor/mother_ai_feed_models.dart';

abstract class MotherAiFeedRepository {
  Future<MotherAiFeedSnapshot> load();
  Future<MotherAiFeedSnapshot> sendWhisper();
}

final class InMemoryMotherAiFeedRepository implements MotherAiFeedRepository {
  InMemoryMotherAiFeedRepository({MotherAiFeedSnapshot? seed})
    : _snap = seed ?? motherAiFeedPrototypeFixture();

  MotherAiFeedSnapshot _snap;
  Future<void> Function()? loadGate;

  @override
  Future<MotherAiFeedSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    return _snap.copyWith();
  }

  @override
  Future<MotherAiFeedSnapshot> sendWhisper() async {
    _snap = _snap.copyWith(whisperSent: true);
    return _snap.copyWith();
  }

  void seed(MotherAiFeedSnapshot snap) => _snap = snap;
}

final InMemoryMotherAiFeedRepository stage1MotherAiFeedRepository =
    InMemoryMotherAiFeedRepository();

MotherAiFeedSnapshot motherAiFeedEmptyFixture() => const MotherAiFeedSnapshot();

MotherAiFeedSnapshot motherAiFeedOneFixture() {
  return const MotherAiFeedSnapshot(
    hasFamily: true,
    items: [
      MotherFeedItem(id: 'i1', titleKey: 'weekSummary', bodyKey: 'mathImprove'),
    ],
  );
}

MotherAiFeedSnapshot motherAiFeedPrototypeFixture() {
  return const MotherAiFeedSnapshot(
    hasFamily: true,
    items: [
      MotherFeedItem(
        id: 'i1',
        titleKey: 'weekSummary',
        bodyKey: 'mathImprove',
        tagKey: 'excellent',
      ),
      MotherFeedItem(
        id: 'i2',
        titleKey: 'sleepNote',
        bodyKey: 'weekendLate',
        tagKey: 'watch',
      ),
    ],
  );
}
