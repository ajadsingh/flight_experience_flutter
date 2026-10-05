import 'package:flutter_test/flutter_test.dart';
import 'package:flight_experience/core/models/flight_route.dart';
import 'package:flight_experience/core/models/geo_point.dart';
import 'package:flight_experience/core/models/flight_state.dart';
import 'package:flight_experience/core/services/flight_route_metrics.dart';
import 'package:flight_experience/core/services/gps_position_filter.dart';
import 'package:flight_experience/core/services/tile_cache_service.dart';

void main() {
  const route = FlightRoute(
    id: 'test-route',
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

  group('GpsPositionFilter', () {
    test('accepts a good first fix', () {
      final filter = GpsPositionFilter();
      const point = GeoPoint(23.5, 72.5);
      expect(
        filter.update(raw: point, accuracyMeters: 15),
        equals(point),
      );
    });

    test('rejects a fix with excessive accuracy radius', () {
      final filter = GpsPositionFilter();
      expect(
        filter.update(
          raw: const GeoPoint(23.5, 72.5),
          accuracyMeters: 400,
        ),
        isNull,
      );
    });

    test('smooths a reasonable movement instead of jumping directly', () {
      final filter = GpsPositionFilter(alpha: 0.35);
      filter.update(
        raw: const GeoPoint(23.0, 72.0),
        accuracyMeters: 10,
      );
      final result = filter.update(
        raw: const GeoPoint(23.1, 72.1),
        accuracyMeters: 50,
      );
      expect(result, isNotNull);
      expect(result!.latitude, greaterThan(23.0));
      expect(result.latitude, lessThan(23.1));
    });

    test('rejects a huge location jump', () {
      final filter = GpsPositionFilter(maxJumpKm: 100);
      filter.update(
        raw: const GeoPoint(23.0, 72.0),
        accuracyMeters: 10,
      );
      final result = filter.update(
        raw: const GeoPoint(28.0, 77.0),
        accuracyMeters: 10,
      );
      expect(result, isNotNull);
      expect(result!.latitude, closeTo(23.0, 0.0001));
      expect(result.longitude, closeTo(72.0, 0.0001));
    });
  });

  group('FlightRouteMetrics', () {
    test('returns near-zero deviation for an on-route point', () {
      const point = GeoPoint(24.0, 73.0);
      final metrics = FlightRouteMetrics.calculate(route, point);
      expect(metrics.deviationKm, lessThan(1.0));
      expect(metrics.progress, greaterThan(0.0));
      expect(metrics.progress, lessThan(0.6));
    });

    test('reports meaningful deviation for an off-route point', () {
      const point = GeoPoint(24.0, 78.0);
      final metrics = FlightRouteMetrics.calculate(route, point);
      expect(metrics.deviationKm, greaterThan(300));
      expect(metrics.progress, inInclusiveRange(0.0, 1.0));
    });
  });

  test('MapDownloadStatus exposes failed tile count', () {
    const status = MapDownloadStatus(
      routeId: 'route',
      downloaded: 90,
      total: 100,
      isDownloading: false,
      isDone: false,
      progress: 0.9,
      failed: 10,
      error: 'retry',
    );
    expect(status.failed, 10);
    expect(status.error, 'retry');
  });

  test('GpsQuality starts unknown in a fresh state', () {
    final state = FlightState.initial(route);
    expect(state.gpsQuality, GpsQuality.unknown);
    expect(state.routeConfidence, 0);
  });
}