import 'package:flutter/foundation.dart';

import 'package:family_os/features/n02_day/day_child_mock.dart';

/// One child pin on SCR-FAT-014 — values from repos, never planted in widgets.
@immutable
final class LocationMapPin {
  const LocationMapPin({
    required this.id,
    required this.displayName,
    required this.emoji,
    required this.swatch,
    required this.locationLabel,
    required this.lastSeenLabel,
    required this.batteryLabel,
    required this.xFraction,
    required this.yFraction,
    this.safeZoneLabel = '',
    this.batteryWarn = false,
  });

  final String id;
  final String displayName;
  final String emoji;
  final DayChildSwatch swatch;
  final String locationLabel;
  final String lastSeenLabel;
  final String batteryLabel;

  /// 0–1 position on the decorative map canvas (LTR coordinates).
  final double xFraction;
  final double yFraction;

  /// Optional «داخل منطقة …» label when inside a safe zone.
  final String safeZoneLabel;

  /// Low-battery caution (prototype ⚠️).
  final bool batteryWarn;
}

/// Decorative safe-zone circle on the map (prototype `.zone`).
@immutable
final class LocationMapZone {
  const LocationMapZone({
    required this.id,
    required this.xFraction,
    required this.yFraction,
    required this.diameterFraction,
    this.purpleTint = false,
  });

  final String id;
  final double xFraction;
  final double yFraction;
  final double diameterFraction;
  final bool purpleTint;
}

/// One stop on the embedded day-thread (prototype `.tstop`).
@immutable
final class LocationThreadStop {
  const LocationThreadStop({
    required this.title,
    required this.timeLabel,
    this.isCurrent = false,
  });

  final String title;
  final String timeLabel;
  final bool isCurrent;
}

/// Family live-map snapshot for SCR-FAT-014.
@immutable
final class LocationMapSnapshot {
  const LocationMapSnapshot({
    required this.pins,
    required this.zones,
    this.focusChildId,
    this.focusDisplayName = '',
    this.threadStops = const [],
  });

  final List<LocationMapPin> pins;
  final List<LocationMapZone> zones;

  /// When set, day-thread section focuses this child.
  final String? focusChildId;
  final String focusDisplayName;
  final List<LocationThreadStop> threadStops;

  bool get isEmpty => pins.isEmpty;
}

/// Rule 25 seam — live map for SCR-FAT-014 (no Firebase; Drift later).
abstract class LocationMapRepository {
  /// Family map. When [focusChildId] is set and unknown → returns `null`.
  /// Empty pins when no children linked (Rule 23).
  Future<LocationMapSnapshot?> load({String? focusChildId});
}

/// In-memory mock — empty until tests/repos seed (Rule 23).
final class InMemoryLocationMapRepository implements LocationMapRepository {
  InMemoryLocationMapRepository({
    List<LocationMapPin> pins = const [],
    List<LocationMapZone> zones = const [],
    Map<String, List<LocationThreadStop>> threadsByChildId = const {},
    this.failLoad = false,
  })  : _pins = List.of(pins),
        _zones = List.of(zones),
        _threads = Map.of(threadsByChildId);

  List<LocationMapPin> _pins;
  List<LocationMapZone> _zones;
  Map<String, List<LocationThreadStop>> _threads;

  /// Test seam — next [load] throws.
  bool failLoad;

  void seed({
    List<LocationMapPin>? pins,
    List<LocationMapZone>? zones,
    Map<String, List<LocationThreadStop>>? threadsByChildId,
  }) {
    if (pins != null) _pins = List.of(pins);
    if (zones != null) _zones = List.of(zones);
    if (threadsByChildId != null) _threads = Map.of(threadsByChildId);
  }

  @override
  Future<LocationMapSnapshot?> load({String? focusChildId}) async {
    if (failLoad) {
      throw StateError('mock location map load failure');
    }

    final trimmed = focusChildId?.trim();
    final hasFocus = trimmed != null && trimmed.isNotEmpty;

    if (_pins.isEmpty) {
      if (hasFocus) return null;
      return const LocationMapSnapshot(pins: [], zones: []);
    }

    if (hasFocus) {
      final match = _pins.where((p) => p.id == trimmed).toList();
      if (match.isEmpty) return null;
      final focus = match.first;
      return LocationMapSnapshot(
        pins: List.unmodifiable(_pins),
        zones: List.unmodifiable(_zones),
        focusChildId: focus.id,
        focusDisplayName: focus.displayName,
        threadStops: List.unmodifiable(_threads[focus.id] ?? const []),
      );
    }

    final first = _pins.first;
    return LocationMapSnapshot(
      pins: List.unmodifiable(_pins),
      zones: List.unmodifiable(_zones),
      focusChildId: first.id,
      focusDisplayName: first.displayName,
      threadStops: List.unmodifiable(_threads[first.id] ?? const []),
    );
  }
}

/// Stage-1 singleton — empty until tests/repos seed (Rule 23).
final stage1LocationMapRepository = InMemoryLocationMapRepository();
