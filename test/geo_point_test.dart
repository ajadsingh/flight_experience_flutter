import 'package:flutter_test/flutter_test.dart';
import 'package:flight_experience/core/models/geo_point.dart';

void main() {
  group('GeoPoint.distanceKm', () {
    test('nearby points give roughly correct distance', () {
      const a = GeoPoint(23.0225, 72.5714);
      const b = GeoPoint(23.0325, 72.5814);
      final distance = GeoPoint.distanceKm(a, b);
      expect(distance, greaterThan(1.0));
      expect(distance, lessThan(2.0));
    });

    test('same point returns zero', () {
      const a = GeoPoint(28.6139, 77.2090);
      expect(GeoPoint.distanceKm(a, a), closeTo(0.0, 0.001));
    });

    test('AMD to DEL is approximately 750-850 km (straight line)', () {
      const amd = GeoPoint(23.0720, 72.6260);
      const del = GeoPoint(28.6139, 77.2090);
      final d = GeoPoint.distanceKm(amd, del);
      expect(d, greaterThan(700));
      expect(d, lessThan(900));
    });
  });

  group('GeoPoint.bearingDegrees', () {
    test('returns normalized 0–360 degrees', () {
      const a = GeoPoint(23.0, 72.0);
      const b = GeoPoint(24.0, 72.0);
      final bearing = GeoPoint.bearingDegrees(a, b);
      expect(bearing, closeTo(0, 0.5)); // due North
      expect(bearing, greaterThanOrEqualTo(0));
      expect(bearing, lessThan(360));
    });

    test('East gives ~90 degrees', () {
      const a = GeoPoint(23.0, 72.0);
      const b = GeoPoint(23.0, 73.0);
      final bearing = GeoPoint.bearingDegrees(a, b);
      expect(bearing, closeTo(90, 2));
    });

    test('South gives ~180 degrees', () {
      const a = GeoPoint(24.0, 72.0);
      const b = GeoPoint(23.0, 72.0);
      final bearing = GeoPoint.bearingDegrees(a, b);
      expect(bearing, closeTo(180, 1));
    });

    test('West gives ~270 degrees', () {
      const a = GeoPoint(23.0, 73.0);
      const b = GeoPoint(23.0, 72.0);
      final bearing = GeoPoint.bearingDegrees(a, b);
      expect(bearing, closeTo(270, 2));
    });
  });

  group('GeoPoint.toLatLng', () {
    test('converts coordinates correctly', () {
      const point = GeoPoint(28.6139, 77.2090);
      final latLng = point.toLatLng();
      expect(latLng.latitude, closeTo(28.6139, 0.0001));
      expect(latLng.longitude, closeTo(77.2090, 0.0001));
    });
  });
}
