import 'package:family_os/features/n07_advisor/knowledge_maps_models.dart';

/// Rule 25 seam — Stage-1 mock knowledge maps (no backend).
abstract class KnowledgeMapsRepository {
  Future<KnowledgeMapsSnapshot> load();

  /// Cycle dinner prompt index (Stage-1 local only).
  Future<KnowledgeMapsSnapshot> nextDinnerQuestion();
}

/// In-memory mock — prototype FAT-064 shape by default.
final class InMemoryKnowledgeMapsRepository implements KnowledgeMapsRepository {
  InMemoryKnowledgeMapsRepository({KnowledgeMapsSnapshot? seed})
    : _snap = seed ?? knowledgeMapsPrototypeFixture();

  KnowledgeMapsSnapshot _snap;

  /// Optional gate for loading-state widget tests.
  Future<void> Function()? loadGate;

  @override
  Future<KnowledgeMapsSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    return _copy(_snap);
  }

  @override
  Future<KnowledgeMapsSnapshot> nextDinnerQuestion() async {
    if (_snap.dinnerQuestionKeys.isEmpty) return _copy(_snap);
    final next =
        (_snap.dinnerQuestionIndex + 1) % _snap.dinnerQuestionKeys.length;
    _snap = KnowledgeMapsSnapshot(
      childNameKey: _snap.childNameKey,
      masteryPercent: _snap.masteryPercent,
      learningPaths: List<KnowledgeMapLearningPath>.from(_snap.learningPaths),
      socialShares: List<KnowledgeMapSocialShare>.from(_snap.socialShares),
      dinnerQuestionKeys: List<String>.from(_snap.dinnerQuestionKeys),
      dinnerQuestionIndex: next,
    );
    return _copy(_snap);
  }

  void seed(KnowledgeMapsSnapshot snap) {
    _snap = snap;
  }

  KnowledgeMapsSnapshot _copy(KnowledgeMapsSnapshot s) {
    return KnowledgeMapsSnapshot(
      childNameKey: s.childNameKey,
      masteryPercent: s.masteryPercent,
      learningPaths: List<KnowledgeMapLearningPath>.from(s.learningPaths),
      socialShares: List<KnowledgeMapSocialShare>.from(s.socialShares),
      dinnerQuestionKeys: List<String>.from(s.dinnerQuestionKeys),
      dinnerQuestionIndex: s.dinnerQuestionIndex,
    );
  }
}

/// Shared Stage-1 singleton (prototype fixture until a screen/test seeds).
final InMemoryKnowledgeMapsRepository stage1KnowledgeMapsRepository =
    InMemoryKnowledgeMapsRepository();

/// Empty — Rule 23 empty-state coverage.
KnowledgeMapsSnapshot knowledgeMapsEmptyFixture() {
  return const KnowledgeMapsSnapshot();
}

/// One learning path — minimal non-empty.
KnowledgeMapsSnapshot knowledgeMapsOneFixture() {
  return const KnowledgeMapsSnapshot(
    childNameKey: 'childOne',
    masteryPercent: 50,
    learningPaths: [
      KnowledgeMapLearningPath(
        id: 'path-math',
        kind: KnowledgeMapPathKind.math,
        titleKey: 'mathFractions',
        subtitleKey: 'mathFractionsHint',
        progressPercent: 45,
        ctaScreenId: 'SCR-FAT-049',
      ),
    ],
    socialShares: [
      KnowledgeMapSocialShare(
        segment: KnowledgeMapSocialSegment.family,
        percent: 100,
        titleKey: 'familyDirect',
        subtitleKey: 'familyWarmDaily',
      ),
    ],
    dinnerQuestionKeys: ['dinnerQ1'],
    dinnerQuestionIndex: 0,
  );
}

/// Prototype FAT-064 — learning paths + social bar + dinner prompt.
///
/// Rule 23: nameKey only (no planted person names).
KnowledgeMapsSnapshot knowledgeMapsPrototypeFixture() {
  return const KnowledgeMapsSnapshot(
    childNameKey: 'childOne',
    masteryPercent: 68,
    learningPaths: [
      KnowledgeMapLearningPath(
        id: 'path-quran',
        kind: KnowledgeMapPathKind.quran,
        titleKey: 'quranSurah',
        subtitleKey: 'quranProgressStreak',
        progressPercent: 50,
        ctaScreenId: 'SCR-FAT-072',
      ),
      KnowledgeMapLearningPath(
        id: 'path-math',
        kind: KnowledgeMapPathKind.math,
        titleKey: 'mathFractions',
        subtitleKey: 'mathFractionsHint',
        progressPercent: 45,
        ctaScreenId: 'SCR-FAT-049',
      ),
    ],
    socialShares: [
      KnowledgeMapSocialShare(
        segment: KnowledgeMapSocialSegment.family,
        percent: 80,
        titleKey: 'familyDirect',
        subtitleKey: 'familyWarmDaily',
      ),
      KnowledgeMapSocialShare(
        segment: KnowledgeMapSocialSegment.approvedFriends,
        percent: 15,
        titleKey: 'approvedFriends',
        subtitleKey: null,
      ),
      KnowledgeMapSocialShare(
        segment: KnowledgeMapSocialSegment.newInteraction,
        percent: 5,
        titleKey: 'newInteraction',
        subtitleKey: null,
      ),
    ],
    dinnerQuestionKeys: ['dinnerQ1', 'dinnerQ2', 'dinnerQ3'],
    dinnerQuestionIndex: 0,
  );
}
