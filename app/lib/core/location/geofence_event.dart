import 'package:flutter/foundation.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';

/// Canonical geofence event kinds (Q-LOC-18=A · Q-LOC-06=A).
enum GeofenceEventKind { enter, exit, noShow }

extension GeofenceEventKindWire on GeofenceEventKind {
  String get wireName => switch (this) {
    GeofenceEventKind.enter => 'ENTER',
    GeofenceEventKind.exit => 'EXIT',
    GeofenceEventKind.noShow => 'NO_SHOW',
  };

  static GeofenceEventKind parse(String raw) {
    switch (raw.trim().toUpperCase()) {
      case 'ENTER':
        return GeofenceEventKind.enter;
      case 'EXIT':
        return GeofenceEventKind.exit;
      case 'NO_SHOW':
      case 'NOSHOW':
        return GeofenceEventKind.noShow;
      default:
        throw FormatException('Unknown GeofenceEventKind: $raw');
    }
  }
}

/// Immutable canonical geofence event (append-only once emitted).
@immutable
final class GeofenceEvent {
  const GeofenceEvent({
    required this.eventId,
    required this.familyId,
    required this.childId,
    required this.deviceId,
    required this.zoneId,
    required this.kind,
    required this.occurredAt,
    this.geometryVersion,
  });

  final String eventId;
  final FamilyId familyId;
  final ChildId childId;
  final DeviceId deviceId;
  final String zoneId;
  final GeofenceEventKind kind;
  final DateTime occurredAt;
  final int? geometryVersion;
}
