import 'package:flutter_test/flutter_test.dart';

import 'package:flight_experience/core/models/flight_history_item.dart';
import 'package:flight_experience/core/models/flight_route.dart';
import 'package:flight_experience/core/models/geo_point.dart';

void main() {
  const route = FlightRoute(
    id: 'amd-del-demo',
    flightNumber: 'FX 482',
    origin: 'Ahmedabad',
    originCode: 'AMD',
    destination: 'Delhi',
    destinationCode: 'DEL',
    waypoints: [
      GeoPoint(23.0720, 72.6260),
      GeoPoint(28.6139, 77.2090),
    ],
  );

  test('flight history serializes and restores a replayable track', () {
    final item = FlightHistoryItem(
      id: '1',
      startedAt: DateTime.utc(2026, 10, 5, 12, 30),
      route: route,
      duration: const Duration(minutes: 42, seconds: 8),
      distanceKm: 520.5,
      maxSpeedKmh: 810,
      maxAltitudeFt: 36000,
      track: const [
        GeoPoint(23.0720, 72.6260),
        GeoPoint(25.3176, 75.7873),
        GeoPoint(28.6139, 77.2090),
      ],
      mode: 'gps',
    );

    final restored = FlightHistoryItem.fromJson(item.toJson());
    expect(restored.id, item.id);
    expect(restored.route.originCode, 'AMD');
    expect(restored.route.destinationCode, 'DEL');
    expect(restored.track.length, 3);
    expect(restored.duration.inSeconds, 2528);
    expect(restored.mode, 'gps');
  });

  test('flight history duration label is human readable', () {
    const item = FlightHistoryItem(
      id: '1',
      startedAt: DateTime.utc(2026, 10, 5),
      route: route,
      duration: Duration(hours: 2, minutes: 15),
      distanceKm: 1,
      maxSpeedKmh: 1,
      maxAltitudeFt: 1,
      track: [],
      mode: 'demo',
    );
    expect(item.durationLabel, '2h 15m');
  });

  test('track distance is zero for a single point', () {
    expect(
      FlightHistoryItem.calculateDistanceKm(const [GeoPoint(20, 70)]),
      0,
    );
  });
}
