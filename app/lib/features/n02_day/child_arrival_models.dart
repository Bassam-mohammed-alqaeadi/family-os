import 'package:flutter/foundation.dart';

@immutable
final class ChildArrivalZone {
  const ChildArrivalZone({
    required this.id,
    required this.nameKey,
    required this.descKey,
    required this.iconKey,
  });

  final String id;

  /// ARB discriminator — school / home / etc. (Rule 23).
  final String nameKey;
  final String descKey;
  final String iconKey;
}

@immutable
final class ChildArrivalSnapshot {
  const ChildArrivalSnapshot({
    this.zones = const [],
    this.liveLocationSafe = true,
    this.liveLocationLabelKey = 'highAccuracy',
  });

  final List<ChildArrivalZone> zones;
  final bool liveLocationSafe;
  final String liveLocationLabelKey;

  bool get isEmpty => zones.isEmpty;
}
