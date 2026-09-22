import 'package:flutter/foundation.dart';

/// Package subject kinds on SCR-FAT-046 (prototype FAT-046 rows).
enum CommunityPackageKind { fractions, quran, english }

/// Anonymous author keys — Rule 23 / prototype «بلا هوية» (no real names).
enum CommunityAuthorKey { fatherRiyadh, motherJeddah, fatherDammam }

@immutable
final class CommunityPackage {
  const CommunityPackage({
    required this.id,
    required this.kind,
    required this.titleKey,
    required this.authorKey,
    required this.rating,
    required this.ratingCount,
    this.trusted = true,
    this.lessons = 0,
    this.quizzes = 0,
  });

  final String id;
  final CommunityPackageKind kind;

  /// ARB discriminator for title (Rule 23 — no planted person names).
  final String titleKey;
  final CommunityAuthorKey authorKey;
  final double rating;
  final int ratingCount;
  final bool trusted;
  final int lessons;
  final int quizzes;
}

@immutable
final class CommunityPublishOffer {
  const CommunityPublishOffer({required this.id, required this.titleKey});

  final String id;

  /// ARB discriminator for the local pack suggested for publish.
  final String titleKey;
}

@immutable
final class CommunityLibrarySnapshot {
  const CommunityLibrarySnapshot({this.packages = const [], this.publishOffer});

  final List<CommunityPackage> packages;
  final CommunityPublishOffer? publishOffer;

  bool get isEmpty => packages.isEmpty;

  CommunityLibrarySnapshot filtered(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return this;
    return CommunityLibrarySnapshot(
      packages: [
        for (final p in packages)
          if (p.titleKey.toLowerCase().contains(q) ||
              p.kind.name.toLowerCase().contains(q))
            p,
      ],
      publishOffer: publishOffer,
    );
  }
}
