import 'package:family_os/features/n17_child_learn/child_memorization_models.dart';
import 'package:family_os/features/quran/quran_local_bridge.dart';

abstract class ChildMemorizationRepository {
  Future<ChildMemorizationSnapshot> load();
  Future<void> startReview(String id);
}

final class InMemoryChildMemorizationRepository
    implements ChildMemorizationRepository {
  InMemoryChildMemorizationRepository({
    ChildMemorizationSnapshot? seed,
    QuranLocalBridge? bridge,
  }) : _snap = seed ?? childMemorizationEmptyFixture(),
       _bridgeOverride = bridge;

  ChildMemorizationSnapshot _snap;
  final QuranLocalBridge? _bridgeOverride;
  Future<void> Function()? loadGate;
  final List<String> startedReviews = [];

  QuranLocalBridge get _bridge => _bridgeOverride ?? stage1QuranLocalBridge;

  @override
  Future<ChildMemorizationSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    return ChildMemorizationSnapshot(
      hasProgress: _snap.hasProgress,
      surahCount: _snap.surahCount,
      extraAyahs: _snap.extraAyahs,
      surahs: List<ChildMemSurah>.from(_snap.surahs),
      badges: List<ChildMemBadge>.from(_snap.badges),
      reviews: List<ChildMemReview>.from(_snap.reviews),
    );
  }

  @override
  Future<void> startReview(String id) async {
    startedReviews.add(id);
    // P15-QUR-006 — Local review event for father FAT-072 / board.
    _bridge.recordMemorizationReview(id);
  }

  void seed(ChildMemorizationSnapshot snap) => _snap = snap;
}

final InMemoryChildMemorizationRepository stage1ChildMemorizationRepository =
    InMemoryChildMemorizationRepository();

ChildMemorizationSnapshot childMemorizationEmptyFixture() =>
    const ChildMemorizationSnapshot();

ChildMemorizationSnapshot childMemorizationOneFixture() {
  return const ChildMemorizationSnapshot(
    hasProgress: true,
    surahCount: 1,
    surahs: [ChildMemSurah(id: 'fatiha', nameKey: 'fatiha', progress: 1)],
  );
}

ChildMemorizationSnapshot childMemorizationPrototypeFixture() {
  return const ChildMemorizationSnapshot(
    hasProgress: true,
    surahCount: 3,
    extraAyahs: 15,
    surahs: [
      ChildMemSurah(id: 'fatiha', nameKey: 'fatiha'),
      ChildMemSurah(id: 'ikhlas', nameKey: 'ikhlas'),
      ChildMemSurah(id: 'naba', nameKey: 'naba'),
      ChildMemSurah(id: 'mulk', nameKey: 'mulk', progress: 0.5),
    ],
    badges: [
      ChildMemBadge(id: 'b1', labelKey: 'firstSurah', earned: true),
      ChildMemBadge(id: 'b2', labelKey: 'threeSurahs', earned: true),
      ChildMemBadge(id: 'b3', labelKey: 'halfAmma'),
      ChildMemBadge(id: 'b4', labelKey: 'littleHafiz'),
    ],
    reviews: [
      ChildMemReview(id: 'r1', titleKey: 'tabarak', metaKey: 'fourDaysAgo'),
      ChildMemReview(
        id: 'r2',
        titleKey: 'nabaFull',
        metaKey: 'tomorrow',
        dueToday: false,
      ),
    ],
  );
}
