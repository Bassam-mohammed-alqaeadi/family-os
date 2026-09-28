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

  Map<String, Object?> toJson() => {
        'id': id,
        'nameKey': nameKey,
        'descKey': descKey,
        'iconKey': iconKey,
      };

  static ChildArrivalZone fromJson(Map<String, Object?> json) {
    return ChildArrivalZone(
      id: json['id']?.toString() ?? '',
      nameKey: json['nameKey']?.toString() ?? '',
      descKey: json['descKey']?.toString() ?? '',
      iconKey: json['iconKey']?.toString() ?? '',
    );
  }
}

@immutable
final class ChildArrivalSnapshot {
  const ChildArrivalSnapshot({
    this.zones = const [],
    this.liveLocationSafe = true,
    this.liveLocationLabelKey = 'highAccuracy',
    this.checkInJournal = const [],
  });

  final List<ChildArrivalZone> zones;
  final bool liveLocationSafe;
  final String liveLocationLabelKey;

  /// Local check-in journal — no fake GPS / FCM delivery (CE-G022).
  final List<String> checkInJournal;

  bool get isEmpty => zones.isEmpty;

  Map<String, Object?> toJson() => {
        'zones': zones.map((e) => e.toJson()).toList(),
        'liveLocationSafe': liveLocationSafe,
        'liveLocationLabelKey': liveLocationLabelKey,
        'checkInJournal': checkInJournal,
      };

  static ChildArrivalSnapshot fromJson(Map<String, Object?> json) {
    final zones = <ChildArrivalZone>[];
    final raw = json['zones'];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map) {
          zones.add(
            ChildArrivalZone.fromJson(
              e.map((k, v) => MapEntry(k.toString(), v)),
            ),
          );
        }
      }
    }
    final journal = <String>[];
    final jRaw = json['checkInJournal'];
    if (jRaw is List) {
      for (final e in jRaw) {
        journal.add(e.toString());
      }
    }
    return ChildArrivalSnapshot(
      zones: zones,
      liveLocationSafe: json['liveLocationSafe'] != false,
      liveLocationLabelKey:
          json['liveLocationLabelKey']?.toString() ?? 'highAccuracy',
      checkInJournal: journal,
    );
  }
}
