import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/location/geo_point.dart';
import 'package:family_os/core/location/geofence_evaluator.dart';
import 'package:family_os/core/location/geofence_event.dart';
import 'package:family_os/core/location/zone_geometry.dart';

void main() {
  const center = GeoPoint(latitude: 24.7136, longitude: 46.6753);

  group('CircleGeometry', () {
    test('contains points within radius', () {
      const circle = CircleGeometry(center: center, radiusMeters: 200);
      expect(circle.isValid, isTrue);
      expect(circle.contains(center), isTrue);
      // ~111m north ≈ still inside 200m
      const near = GeoPoint(latitude: 24.7146, longitude: 46.6753);
      expect(circle.contains(near), isTrue);
    });

    test('rejects far points', () {
      const circle = CircleGeometry(center: center, radiusMeters: 50);
      const far = GeoPoint(latitude: 24.7200, longitude: 46.6753);
      expect(circle.contains(far), isFalse);
    });
  });

  group('PolygonGeometry', () {
    test('contains interior point', () {
      const poly = PolygonGeometry(
        vertices: [
          GeoPoint(latitude: 24.71, longitude: 46.67),
          GeoPoint(latitude: 24.71, longitude: 46.68),
          GeoPoint(latitude: 24.72, longitude: 46.68),
          GeoPoint(latitude: 24.72, longitude: 46.67),
        ],
      );
      expect(poly.isValid, isTrue);
      expect(
        poly.contains(const GeoPoint(latitude: 24.715, longitude: 46.675)),
        isTrue,
      );
      expect(
        poly.contains(const GeoPoint(latitude: 24.70, longitude: 46.66)),
        isFalse,
      );
    });

    test('rejects fewer than 3 vertices', () {
      const poly = PolygonGeometry(
        vertices: [
          GeoPoint(latitude: 1, longitude: 1),
          GeoPoint(latitude: 2, longitude: 2),
        ],
      );
      expect(poly.isValid, isFalse);
    });
  });

  group('GeofenceEvaluator', () {
    test('ENTER / EXIT transitions only', () {
      expect(
        GeofenceEvaluator.transition(wasInside: false, isInside: true),
        GeofenceEventKind.enter,
      );
      expect(
        GeofenceEvaluator.transition(wasInside: true, isInside: false),
        GeofenceEventKind.exit,
      );
      expect(
        GeofenceEvaluator.transition(wasInside: true, isInside: true),
        isNull,
      );
    });
  });
}
