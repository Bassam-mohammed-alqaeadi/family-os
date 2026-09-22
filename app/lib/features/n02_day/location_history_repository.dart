import 'package:flutter/foundation.dart';

/// One stop on a day thread (prototype `.tstop`).
@immutable
final class LocationHistoryStop {
  const LocationHistoryStop({
    required this.title,
    required this.timeLabel,
    this.isCurrent = false,
  });

  final String title;
  final String timeLabel;
  final bool isCurrent;
}

/// One day card on SCR-FAT-015 (prototype day sections).
@immutable
final class LocationHistoryDay {
  const LocationHistoryDay({
    required this.id,
    required this.heading,
    required this.stops,
  });

  final String id;
  final String heading;
  final List<LocationHistoryStop> stops;
}

/// Frequent-place regularity (S-SEC-023) — Tag.g منتظم / Tag.a جديد.
enum LocationPlaceRegularity { regular, novel }

/// One auto-learned frequent place row (prototype «أماكن … المتكررة»).
@immutable
final class LocationFrequentPlace {
  const LocationFrequentPlace({
    required this.id,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.regularity,
  });

  final String id;
  final String emoji;
  final String title;
  final String subtitle;
  final LocationPlaceRegularity regularity;
}

/// Full location-history snapshot for one child (SCR-FAT-015).
@immutable
final class LocationHistorySnapshot {
  const LocationHistorySnapshot({
    required this.childId,
    required this.displayName,
    required this.days,
    this.frequentPlaces = const [],
  });

  final String childId;
  final String displayName;
  final List<LocationHistoryDay> days;
  final List<LocationFrequentPlace> frequentPlaces;

  bool get isEmpty => days.isEmpty;
}

/// Rule 25 seam — location history for SCR-FAT-015 (no Firebase; Drift later).
abstract class LocationHistoryRepository {
  /// Returns `null` when [childId] is unknown. Empty days when known but no trail.
  Future<LocationHistorySnapshot?> load(String childId);
}

/// In-memory mock — empty until tests/repos seed (Rule 23).
final class InMemoryLocationHistoryRepository
    implements LocationHistoryRepository {
  InMemoryLocationHistoryRepository({
    Map<String, LocationHistorySnapshot> byChildId = const {},
    this.failLoad = false,
  }) : _byChildId = Map.of(byChildId);

  Map<String, LocationHistorySnapshot> _byChildId;

  /// Test seam — next [load] throws.
  bool failLoad;

  void seed(Map<String, LocationHistorySnapshot> byChildId) {
    _byChildId = Map.of(byChildId);
  }

  @override
  Future<LocationHistorySnapshot?> load(String childId) async {
    if (failLoad) {
      throw StateError('mock location history load failure');
    }
    final trimmed = childId.trim();
    if (trimmed.isEmpty) return null;
    final snap = _byChildId[trimmed];
    if (snap == null) return null;
    return LocationHistorySnapshot(
      childId: snap.childId,
      displayName: snap.displayName,
      days: List.unmodifiable(snap.days),
      frequentPlaces: List.unmodifiable(snap.frequentPlaces),
    );
  }
}

/// Stage-1 singleton — empty until tests/repos seed (Rule 23).
final stage1LocationHistoryRepository = InMemoryLocationHistoryRepository();
