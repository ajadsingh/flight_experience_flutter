import 'package:flutter_test/flutter_test.dart';
import 'package:flight_experience/core/models/geo_point.dart';
import 'package:flight_experience/core/models/poi.dart';
import 'package:flight_experience/core/services/nearby_poi_service.dart';

void main() {
  group('NearbyPoiService directional discovery', () {
    final service = NearbyPoiService([
      const Poi(
        name: 'Ahead City',
        type: 'City',
        position: GeoPoint(23.0, 73.0),
        description: 'East of the aircraft.',
      ),
      const Poi(
        name: 'Nearby City',
        type: 'City',
        position: GeoPoint(23.4, 72.6),
        description: 'Nearby and slightly behind.',
      ),
      const Poi(
        name: 'Far Place',
        type: 'Landmark',
        position: GeoPoint(25.0, 80.0),
        description: 'Far away.',
      ),
    ]);

    test('identifies the nearest POI as below/closest', () {
      final snapshot = service.discover(
        const GeoPoint(23.0, 72.0),
        headingDegrees: 90,
        radiusKm: 200,
      );
      expect(snapshot.below, isNotNull);
      expect(snapshot.below!.poi.name, 'Nearby City');
    });

    test('identifies an eastbound POI as ahead', () {
      final snapshot = service.discover(
        const GeoPoint(23.0, 72.0),
        headingDegrees: 90,
        radiusKm: 200,
      );
      expect(snapshot.ahead, isNotNull);
      expect(snapshot.ahead!.poi.name, 'Ahead City');
      expect(snapshot.ahead!.bearingDegrees, closeTo(90, 2));
    });

    test('does not return a POI outside the radius', () {
      final snapshot = service.discover(
        const GeoPoint(23.0, 72.0),
        headingDegrees: 90,
        radiusKm: 20,
      );
      expect(snapshot.nearby, isEmpty);
      expect(snapshot.below, isNull);
      expect(snapshot.ahead, isNull);
    });
  });

  test('NearbyPoi supports bearing metadata', () {
    const poi = Poi(
      name: 'Test',
      type: 'City',
      position: GeoPoint(23.0, 73.0),
      description: '',
    );
    const item = NearbyPoi(
      poi: poi,
      distanceKm: 50,
      bearingDegrees: 90,
    );
    expect(item.bearingDegrees, 90);
  });
}