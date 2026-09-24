import 'package:flutter/foundation.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';

import 'zone_geometry.dart';

/// Zone definition + geometry + explicit child assignment (Q-LOC-12=B).
@immutable
final class SafeZoneDefinition {
  const SafeZoneDefinition({
    required this.id,
    required this.familyId,
    required this.name,
    required this.geometry,
    required this.assignedChildIds,
    this.emoji = '📍',
    this.active = true,
    this.archived = false,
    this.alertEnter = true,
    this.alertExit = true,
    this.alertNoShow = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final FamilyId familyId;
  final String name;
  final String emoji;
  final ZoneGeometry geometry;

  /// Explicit multi-select — must be non-empty on save (Q-LOC-12=B).
  final List<ChildId> assignedChildIds;

  final bool active;
  final bool archived;
  final bool alertEnter;
  final bool alertExit;
  final bool alertNoShow;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get hasAssignment => assignedChildIds.isNotEmpty;

  SafeZoneDefinition copyWith({
    String? name,
    String? emoji,
    ZoneGeometry? geometry,
    List<ChildId>? assignedChildIds,
    bool? active,
    bool? archived,
    bool? alertEnter,
    bool? alertExit,
    bool? alertNoShow,
    DateTime? updatedAt,
  }) {
    return SafeZoneDefinition(
      id: id,
      familyId: familyId,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      geometry: geometry ?? this.geometry,
      assignedChildIds: assignedChildIds ?? this.assignedChildIds,
      active: active ?? this.active,
      archived: archived ?? this.archived,
      alertEnter: alertEnter ?? this.alertEnter,
      alertExit: alertExit ?? this.alertExit,
      alertNoShow: alertNoShow ?? this.alertNoShow,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Thrown when save violates frozen assignment law.
final class ZoneAssignmentRequiredException implements Exception {
  const ZoneAssignmentRequiredException();

  @override
  String toString() =>
      'Safe zone save requires explicit child multi-select (Q-LOC-12=B)';
}

/// Thrown when geometry fails validation.
final class InvalidZoneGeometryException implements Exception {
  const InvalidZoneGeometryException(this.reason);
  final String reason;

  @override
  String toString() => 'InvalidZoneGeometryException: $reason';
}
