import 'package:flutter_test/flutter_test.dart';

import 'package:flight_experience/core/models/flight_record.dart';
import 'package:flight_experience/core/models/flight_route.dart';
import 'package:flight_experience/core/models/geo_point.dart';

void main() {
  const route = FlightRoute(
    id: 'history-route',
    flightNumber: 'HX 010',
    origin: 'A',
    originCode: 'AAA',
    destination: 'B',
    destinationCode: 'BBB',
    waypoints: [
      GeoPoint(23.0, 72.0),
      GeoPoint(24.0, 73.0),
    ],
  );

  test('session record calculates tracked distance', () {
    final record = FlightRecord.fromSession(
      route: route,
      startedAt: DateTime.utc(2026, 1, 1),
      duration: const Duration(minutes: 42),
      track: const [
        GeoPoint(23.0, 72.0),
        GeoPoint(23.5, 72.5),
        GeoPoint(24.0, 73.0),
      ],
      maxSpeedKmh: 840,
      maxAltitudeFt: 36000,
    );

    expect(record.distanceKm, greaterThan(100));
    expect(record.maxSpeedKmh, equals(840));
    expect(record.maxAltitudeFt, equals(36000));
  });

  test('record survives JSON round trip', () {
    final original = FlightRecord.fromSession(
      route: route,
      startedAt: DateTime.utc(2026, 1, 1, 8, 30),
      duration: const Duration(minutes: 12),
      track: const [
        GeoPoint(23.0, 72.0),
        GeoPoint(23.2, 72.2),
      ],
      maxSpeedKmh: 500,
      maxAltitudeFt: 12000,
    );

    final restored = FlightRecord.fromJson(original.toJson());

    expect(restored.id, equals(original.id));
    expect(restored.routeId, equals(original.routeId));
    expect(restored.track.length, equals(original.track.length));
    expect(restored.startedAt, equals(original.startedAt));
    expect(restored.duration, equals(original.duration));
    expect(restored.toRoute().originCode, equals('AAA'));
  });
}
