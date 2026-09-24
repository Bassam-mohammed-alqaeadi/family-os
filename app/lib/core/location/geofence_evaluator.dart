import 'geo_point.dart';
import 'geofence_event.dart';
import 'zone_geometry.dart';

/// Offline geofence evaluation — ENTER/EXIT only from inside/outside flips.
///
/// NO_SHOW is not inferred from a single fix (needs schedule context —
/// numeric grace remains Technical Q-LOC-06). Callers emit NO_SHOW explicitly
/// via the repository when product context is ready.
abstract final class GeofenceEvaluator {
  /// Whether [point] is inside [geometry].
  static bool contains(ZoneGeometry geometry, GeoPoint point) =>
      geometry.contains(point);

  /// Returns ENTER / EXIT when presence flips; null when unchanged.
  static GeofenceEventKind? transition({
    required bool wasInside,
    required bool isInside,
  }) {
    if (!wasInside && isInside) return GeofenceEventKind.enter;
    if (wasInside && !isInside) return GeofenceEventKind.exit;
    return null;
  }

  /// Evaluates a fix against a zone. Returns null when no transition.
  static GeofenceEventKind? evaluateFix({
    required ZoneGeometry geometry,
    required GeoPoint point,
    required bool wasInside,
  }) {
    final isInside = contains(geometry, point);
    return transition(wasInside: wasInside, isInside: isInside);
  }
}
