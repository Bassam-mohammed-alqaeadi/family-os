import 'package:family_os/features/n07_advisor/peer_compare_models.dart';

abstract class PeerCompareRepository {
  Future<PeerCompareSnapshot> load();
}

final class InMemoryPeerCompareRepository implements PeerCompareRepository {
  InMemoryPeerCompareRepository({PeerCompareSnapshot? seed})
    : _snap = seed ?? peerComparePrototypeFixture();

  PeerCompareSnapshot _snap;
  Future<void> Function()? loadGate;

  @override
  Future<PeerCompareSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    return PeerCompareSnapshot(
      hasFamily: _snap.hasFamily,
      childLabelKey: _snap.childLabelKey,
      ageYears: _snap.ageYears,
      metrics: List<PeerMetric>.from(_snap.metrics),
    );
  }

  void seed(PeerCompareSnapshot snap) => _snap = snap;
}

final InMemoryPeerCompareRepository stage1PeerCompareRepository =
    InMemoryPeerCompareRepository();

PeerCompareSnapshot peerCompareEmptyFixture() => const PeerCompareSnapshot();

PeerCompareSnapshot peerCompareOneFixture() {
  return const PeerCompareSnapshot(
    hasFamily: true,
    metrics: [
      PeerMetric(
        id: 'screen',
        titleKey: 'screenTime',
        detailKey: 'screenDetail',
      ),
    ],
  );
}

PeerCompareSnapshot peerComparePrototypeFixture() {
  return const PeerCompareSnapshot(
    hasFamily: true,
    ageYears: 11,
    metrics: [
      PeerMetric(
        id: 'screen',
        titleKey: 'screenTime',
        detailKey: 'screenDetail',
      ),
      PeerMetric(id: 'learn', titleKey: 'learnTime', detailKey: 'learnDetail'),
      PeerMetric(
        id: 'sleep',
        titleKey: 'sleep',
        detailKey: 'sleepDetail',
        positive: false,
      ),
    ],
  );
}
