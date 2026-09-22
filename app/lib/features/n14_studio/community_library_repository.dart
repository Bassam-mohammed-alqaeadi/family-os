import 'package:family_os/features/n14_studio/community_library_models.dart';

/// Rule 25 seam — Stage-1 mock community library (no backend).
abstract class CommunityLibraryRepository {
  Future<CommunityLibrarySnapshot> load();
}

/// In-memory mock — prototype FAT-046 shape by default.
final class InMemoryCommunityLibraryRepository
    implements CommunityLibraryRepository {
  InMemoryCommunityLibraryRepository({CommunityLibrarySnapshot? seed})
    : _snap = seed ?? communityLibraryEmptyFixture();

  CommunityLibrarySnapshot _snap;

  /// Optional gate for loading-state widget tests.
  Future<void> Function()? loadGate;

  @override
  Future<CommunityLibrarySnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    return CommunityLibrarySnapshot(
      packages: List<CommunityPackage>.from(_snap.packages),
      publishOffer: _snap.publishOffer,
    );
  }

  void seed(CommunityLibrarySnapshot snap) {
    _snap = snap;
  }
}

/// Shared Stage-1 singleton (empty until a screen/test seeds — Rule 23).
final InMemoryCommunityLibraryRepository stage1CommunityLibraryRepository =
    InMemoryCommunityLibraryRepository();

/// Empty — Rule 23 empty-state coverage.
CommunityLibrarySnapshot communityLibraryEmptyFixture() {
  return const CommunityLibrarySnapshot();
}

/// One package — Rule 23 one-item coverage.
CommunityLibrarySnapshot communityLibraryOneFixture() {
  return const CommunityLibrarySnapshot(
    packages: [
      CommunityPackage(
        id: 'pkg-fractions',
        kind: CommunityPackageKind.fractions,
        titleKey: 'fractions',
        authorKey: CommunityAuthorKey.fatherRiyadh,
        rating: 4.9,
        ratingCount: 320,
        lessons: 5,
        quizzes: 3,
      ),
    ],
    publishOffer: CommunityPublishOffer(
      id: 'pub-fractions-quiz',
      titleKey: 'fractionsQuiz',
    ),
  );
}

/// Prototype FAT-046 — three top-rated packs + publish offer.
CommunityLibrarySnapshot communityLibraryManyFixture() {
  return const CommunityLibrarySnapshot(
    packages: [
      CommunityPackage(
        id: 'pkg-fractions',
        kind: CommunityPackageKind.fractions,
        titleKey: 'fractions',
        authorKey: CommunityAuthorKey.fatherRiyadh,
        rating: 4.9,
        ratingCount: 320,
        lessons: 5,
        quizzes: 3,
      ),
      CommunityPackage(
        id: 'pkg-juz',
        kind: CommunityPackageKind.quran,
        titleKey: 'juzAmma',
        authorKey: CommunityAuthorKey.motherJeddah,
        rating: 4.8,
        ratingCount: 210,
        lessons: 4,
        quizzes: 0,
      ),
      CommunityPackage(
        id: 'pkg-english',
        kind: CommunityPackageKind.english,
        titleKey: 'englishCards',
        authorKey: CommunityAuthorKey.fatherDammam,
        rating: 4.7,
        ratingCount: 180,
        lessons: 0,
        quizzes: 0,
      ),
    ],
    publishOffer: CommunityPublishOffer(
      id: 'pub-fractions-quiz',
      titleKey: 'fractionsQuiz',
    ),
  );
}
