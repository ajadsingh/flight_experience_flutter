import 'dart:math' as math;

import '../models/flight_route.dart';
import '../models/geo_point.dart';

class RouteMetrics {
  const RouteMetrics({
    required this.progress,
    required this.deviationKm,
    required this.confidence,
    required this.nearestSegmentIndex,
    required this.routeBearing,
  });

  final double progress;
  final double deviationKm;
  final double confidence;
  final int nearestSegmentIndex;
  final double routeBearing;
}

class RouteMetricsService {
  const RouteMetricsService();

  RouteMetrics calculate(FlightRoute route, GeoPoint position) {
    if (route.waypoints.length < 2) {
      return const RouteMetrics(
        progress: 0,
        deviationKm: double.infinity,
        confidence: 0,
        nearestSegmentIndex: 0,
        routeBearing: 0,
      );
    }

    double totalDistance = 0;
    final lengths = <double>[];
    for (var i = 0; i < route.waypoints.length - 1; i++) {
      final length = GeoPoint.distanceKm(
        route.waypoints[i],
        route.waypoints[i + 1],
      );
      lengths.add(length);
      totalDistance += length;
    }

    if (totalDistance <= 0) {
      return const RouteMetrics(
        progress: 0,
        deviationKm: double.infinity,
        confidence: 0,
        nearestSegmentIndex: 0,
        routeBearing: 0,
      );
    }

    double distanceBefore = 0;
    double bestDeviation = double.infinity;
    double bestCovered = 0;
    int bestSegment = 0;
    double bestBearing = 0;

    for (var i = 0; i < lengths.length; i++) {
      final start = route.waypoints[i];
      final end = route.waypoints[i + 1];
      final projected = _project(start, end, position);
      final segmentLength = lengths[i];
      final along = projected.t * segmentLength;

      if (projected.deviationKm < bestDeviation) {
        bestDeviation = projected.deviationKm;
        bestCovered = distanceBefore + along;
        bestSegment = i;
        bestBearing = GeoPoint.bearingDegrees(start, end);
      }

      distanceBefore += segmentLength;
    }

    final progress = (bestCovered / totalDistance).clamp(0.0, 1.0).toDouble();
    final confidence = math.exp(-bestDeviation / 60.0).clamp(0.0, 1.0).toDouble();

    return RouteMetrics(
      progress: progress,
      deviationKm: bestDeviation,
      confidence: confidence,
      nearestSegmentIndex: bestSegment,
      routeBearing: bestBearing,
    );
  }

  _Projection _project(
    GeoPoint start,
    GeoPoint end,
    GeoPoint point,
  ) {
    const kmPerLatitude = 110.574;
    final meanLat =
        (start.latitude + end.latitude + point.latitude) / 3.0;
    final kmPerLongitude =
        111.320 * math.cos(meanLat * math.pi / 180.0);

    final dx = (end.longitude - start.longitude) * kmPerLongitude;
    final dy = (end.latitude - start.latitude) * kmPerLatitude;
    final px = (point.longitude - start.longitude) * kmPerLongitude;
    final py = (point.latitude - start.latitude) * kmPerLatitude;

    final lengthSquared = dx * dx + dy * dy;
    final t = lengthSquared <= 0
        ? 0.0
        : ((px * dx + py * dy) / lengthSquared)
            .clamp(0.0, 1.0)
            .toDouble();

    final projected = GeoPoint(
      start.latitude + (end.latitude - start.latitude) * t,
      start.longitude + (end.longitude - start.longitude) * t,
    );

    return _Projection(
      t: t,
      deviationKm: GeoPoint.distanceKm(point, projected),
    );
  }
}

class _Projection {
  const _Projection({
    required this.t,
    required this.deviationKm,
  });

  final double t;
  final double deviationKm;
}
