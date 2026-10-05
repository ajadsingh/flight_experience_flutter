import 'package:flutter_test/flutter_test.dart';

import 'package:flight_experience/core/models/flight_route.dart';
import 'package:flight_experience/core/models/geo_point.dart';
import 'package:flight_experience/core/services/route_metrics_service.dart';

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
      GeoPoint(24.0, 73.0),
      GeoPoint(25.0, 74.0),
    ],
  );

  const service = RouteMetricsService();

  test('on-route point has low deviation and strong confidence', () {
    final metrics = service.calculate(route, const GeoPoint(24.0, 73.0));

    expect(metrics.deviationKm, lessThan(1));
    expect(metrics.confidence, greaterThan(0.98));
    expect(metrics.progress, greaterThan(0.45));
    expect(metrics.progress, lessThan(0.55));
  });

  test('off-route point reports useful deviation', () {
    final metrics = service.calculate(route, const GeoPoint(24.0, 75.0));

    expect(metrics.deviationKm, greaterThan(100));
    expect(metrics.confidence, lessThan(0.2));
  });

  test('progress remains normalized', () {
    final start = service.calculate(route, route.start);
    final end = service.calculate(route, route.end);

    expect(start.progress, closeTo(0, 0.01));
    expect(end.progress, closeTo(1, 0.01));
  });
}
