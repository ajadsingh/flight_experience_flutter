import 'package:flutter_test/flutter_test.dart';
import 'package:flight_experience/core/models/flight_route.dart';
import 'package:flight_experience/core/models/geo_point.dart';
import 'package:flight_experience/core/models/poi.dart';
import 'package:flight_experience/core/services/demo_flight_service.dart';
import 'package:flight_experience/core/services/nearby_poi_service.dart';

void main() {
  // ── DemoFlightService ───────────────────────────────────────────────────────
  group('DemoFlightService', () {
    late DemoFlightService service;
    const route = FlightRoute(
      id: 'test',
      flightNumber: 'TX 001',
      origin: 'A',
      originCode: 'AAA',
      destination: 'B',
      destinationCode: 'BBB',
      waypoints: [
        GeoPoint(23.0, 72.0),
        GeoPoint(25.0, 74.0),
        GeoPoint(27.0, 76.0),
      ],
    );

    setUp(() => service = DemoFlightService());
    tearDown(() => service.stop());

    test('first tick has progress > 0', () async {
      DemoFlightTick? first;
      service.start(route, (tick) => first ??= tick);
      await Future<void>.delayed(const Duration(milliseconds: 600));
      expect(first, isNotNull);
      expect(first!.progress, greaterThan(0));
      expect(first!.progress, lessThanOrEqualTo(1));
    });

    test('progress increases over time', () async {
      final ticks = <DemoFlightTick>[];
      service.start(route, ticks.add);
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      expect(ticks.length, greaterThanOrEqualTo(2));
      expect(ticks.last.progress, greaterThan(ticks.first.progress));
    });

    test('heading is 0–360 degrees', () async {
      DemoFlightTick? first;
      service.start(route, (tick) => first ??= tick);
      await Future<void>.delayed(const Duration(milliseconds: 600));
      expect(first!.heading, greaterThanOrEqualTo(0));
      expect(first!.heading, lessThan(360));
    });

    test('stop cancels further ticks', () async {
      int count = 0;
      service.start(route, (_) => count++);
      await Future<void>.delayed(const Duration(milliseconds: 600));
      service.stop();
      final before = count;
      await Future<void>.delayed(const Duration(milliseconds: 600));
      expect(count, equals(before)); // no new ticks after stop
    });

    test('altitude follows bell curve (max near progress=0.5)', () async {
      final altitudes = <double>[];
      service.start(route, (tick) => altitudes.add(tick.altitudeFt));
      // Let ~8 ticks accumulate (4 seconds)
      await Future<void>.delayed(const Duration(milliseconds: 4100));
      service.stop();
      if (altitudes.length >= 3) {
        // Middle alt should be higher than very first
        final mid = altitudes[altitudes.length ~/ 2];
        expect(mid, greaterThan(altitudes.first));
      }
    });
  });

  // ── NearbyPoiService ────────────────────────────────────────────────────────
  group('NearbyPoiService', () {
    final pois = [
      const Poi(
        name: 'Jaipur',
        type: 'City',
        position: GeoPoint(26.9124, 75.7873),
        description: 'Capital of Rajasthan.',
      ),
      const Poi(
        name: 'Delhi',
        type: 'City',
        position: GeoPoint(28.6139, 77.2090),
        description: 'National capital.',
      ),
      const Poi(
        name: 'Udaipur',
        type: 'City',
        position: GeoPoint(24.5854, 73.7125),
        description: 'City of lakes.',
      ),
    ];

    test('returns POIs within radius, sorted by distance', () {
      final service = NearbyPoiService(pois);
      const center = GeoPoint(26.9124, 75.7873); // at Jaipur
      final result = service.find(center, radiusKm: 500);
      expect(result, isNotEmpty);
      expect(result.first.poi.name, equals('Jaipur')); // closest
      for (int i = 1; i < result.length; i++) {
        expect(result[i].distanceKm, greaterThanOrEqualTo(result[i - 1].distanceKm));
      }
    });

    test('excludes POIs outside radius', () {
      final service = NearbyPoiService(pois);
      const center = GeoPoint(26.9124, 75.7873); // Jaipur
      final result = service.find(center, radiusKm: 10); // very small
      // Only Jaipur itself (distance ~0) should be in range
      expect(result.length, equals(1));
      expect(result.first.poi.name, equals('Jaipur'));
    });

    test('returns at most 5 results', () {
      // Build 10 identical POIs right at center
      final many = List.generate(
        10,
        (i) => Poi(
          name: 'Place $i',
          type: 'City',
          position: const GeoPoint(26.9, 75.7),
          description: '',
        ),
      );
      final service = NearbyPoiService(many);
      final result = service.find(const GeoPoint(26.9, 75.7));
      expect(result.length, lessThanOrEqualTo(8));
    });

    test('returns empty list when no POIs in range', () {
      final service = NearbyPoiService(pois);
      const farAway = GeoPoint(0.0, 0.0); // middle of ocean
      final result = service.find(farAway, radiusKm: 1);
      expect(result, isEmpty);
    });

    test('handles empty POI list gracefully', () {
      final service = NearbyPoiService(const []);
      final result = service.find(const GeoPoint(26.9, 75.7));
      expect(result, isEmpty);
    });
    test('findAhead prefers places in the flight direction', () {
      final service = NearbyPoiService([
        const Poi(
          name: 'Ahead',
          type: 'City',
          position: GeoPoint(24.0, 72.0),
          description: 'North of aircraft.',
          importance: 4,
        ),
        const Poi(
          name: 'Behind',
          type: 'City',
          position: GeoPoint(22.0, 72.0),
          description: 'South of aircraft.',
          importance: 5,
        ),
      ]);

      const center = GeoPoint(23.0, 72.0);
      final result = service.findAhead(center, 0);

      expect(result, isNotNull);
      expect(result!.poi.name, equals('Ahead'));
    });
  });
}
