import 'package:family_os/features/n07_advisor/peer_compare_models.dart';

abstract class PeerCompareRepository {
  Future<PeerCompareSnapshot> load();
}

final class InMemoryPeerCompareRepository implements PeerCompareRepository {
  InMemoryPeerCompareRepository({PeerCompareSnapshot? seed})
    : _snap = seed ?? peerCompareEmptyFixture();

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

/// Shared Stage-1 — empty until explicit seed (CE-B2 / CE-G009).
/// Cohort averages stay MOCK — never present sample age/metrics as live.
PeerCompareRepository stage1PeerCompareRepository =
    InMemoryPeerCompareRepository(seed: peerCompareEmptyFixture());

void rebindStage1PeerCompareRepository(PeerCompareRepository repository) {
  stage1PeerCompareRepository = repository;
}

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

/// LOCAL_DEMO / tests only — not production stage1 default.
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
