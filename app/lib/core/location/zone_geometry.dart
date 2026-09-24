import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'geo_point.dart';

/// Circle or polygon geometry (LOC-OD-11 — both first-class).
sealed class ZoneGeometry {
  const ZoneGeometry();

  String get kindWire;
  int get version;

  bool get isValid;
  bool contains(GeoPoint point);

  Map<String, Object?> toJson();

  static ZoneGeometry fromJson(Map<String, Object?> json) {
    final kind = (json['kind'] as String?)?.toUpperCase();
    return switch (kind) {
      'CIRCLE' => CircleGeometry.fromJson(json),
      'POLYGON' => PolygonGeometry.fromJson(json),
      _ => throw FormatException('Unknown ZoneGeometry kind: $kind'),
    };
  }
}

@immutable
final class CircleGeometry extends ZoneGeometry {
  const CircleGeometry({
    required this.center,
    required this.radiusMeters,
    this.version = 1,
  });

  final GeoPoint center;
  final double radiusMeters;
  @override
  final int version;

  @override
  String get kindWire => 'CIRCLE';

  @override
  bool get isValid =>
      center.isValid && radiusMeters.isFinite && radiusMeters > 0;

  @override
  bool contains(GeoPoint point) {
    if (!isValid || !point.isValid) return false;
    return center.distanceMetersTo(point) <= radiusMeters;
  }

  @override
  Map<String, Object?> toJson() => {
    'kind': kindWire,
    'version': version,
    'center': center.toJson(),
    'radiusMeters': radiusMeters,
  };

  factory CircleGeometry.fromJson(Map<String, Object?> json) {
    final centerRaw = json['center'];
    if (centerRaw is! Map) {
      throw const FormatException('CircleGeometry.center required');
    }
    return CircleGeometry(
      center: GeoPoint.fromJson(
        centerRaw.map((k, v) => MapEntry(k.toString(), v)),
      ),
      radiusMeters: (json['radiusMeters']! as num).toDouble(),
      version: (json['version'] as num?)?.toInt() ?? 1,
    );
  }
}

@immutable
final class PolygonGeometry extends ZoneGeometry {
  const PolygonGeometry({required this.vertices, this.version = 1});

  /// Ordered ring; first≠last (auto-closed for containment).
  final List<GeoPoint> vertices;
  @override
  final int version;

  @override
  String get kindWire => 'POLYGON';

  @override
  bool get isValid {
    if (vertices.length < 3) return false;
    return vertices.every((v) => v.isValid);
  }

  /// Ray-casting point-in-polygon (finite vertices; not a survey claim).
  @override
  bool contains(GeoPoint point) {
    if (!isValid || !point.isValid) return false;
    var inside = false;
    for (var i = 0, j = vertices.length - 1; i < vertices.length; j = i++) {
      final xi = vertices[i].longitude;
      final yi = vertices[i].latitude;
      final xj = vertices[j].longitude;
      final yj = vertices[j].latitude;
      final intersect =
          ((yi > point.latitude) != (yj > point.latitude)) &&
          (point.longitude <
              (xj - xi) *
                      (point.latitude - yi) /
                      ((yj - yi) == 0 ? 1e-12 : (yj - yi)) +
                  xi);
      if (intersect) inside = !inside;
    }
    return inside;
  }

  @override
  Map<String, Object?> toJson() => {
    'kind': kindWire,
    'version': version,
    'vertices': vertices.map((v) => v.toJson()).toList(growable: false),
  };

  factory PolygonGeometry.fromJson(Map<String, Object?> json) {
    final raw = json['vertices'];
    if (raw is! List || raw.isEmpty) {
      throw const FormatException('PolygonGeometry.vertices required');
    }
    final verts = <GeoPoint>[];
    for (final item in raw) {
      if (item is! Map) continue;
      verts.add(
        GeoPoint.fromJson(item.map((k, v) => MapEntry(k.toString(), v))),
      );
    }
    return PolygonGeometry(
      vertices: List.unmodifiable(verts),
      version: (json['version'] as num?)?.toInt() ?? 1,
    );
  }

  static String encodeVertices(List<GeoPoint> vertices) =>
      jsonEncode(vertices.map((v) => v.toJson()).toList());

  static List<GeoPoint> decodeVertices(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return [
      for (final item in decoded)
        if (item is Map)
          GeoPoint.fromJson(item.map((k, v) => MapEntry(k.toString(), v))),
    ];
  }
}
