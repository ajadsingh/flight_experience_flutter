import 'dart:math' as math;

import '../models/flight_route.dart';
import '../models/geo_point.dart';

class RouteMetrics {
  const RouteMetrics({
    required this.progress,
    required this.deviationKm,
  });

  final double progress;
  final double deviationKm;
}

class FlightRouteMetrics {
  const FlightRouteMetrics._();

  static RouteMetrics calculate(FlightRoute route, GeoPoint position) {
    final waypoints = route.waypoints;
    if (waypoints.length < 2) {
      return const RouteMetrics(progress: 0, deviationKm: 0);
    }

    double totalDistance = 0;
    double coveredBefore = 0;
    double bestDeviation = double.infinity;
    double bestCovered = 0;

    for (int i = 0; i < waypoints.length - 1; i++) {
      final start = waypoints[i];
      final end = waypoints[i + 1];
      final segmentLength = GeoPoint.distanceKm(start, end);
      totalDistance += segmentLength;

      final projection = _projectOnSegment(start, end, position);
      if (projection.distanceKm < bestDeviation) {
        bestDeviation = projection.distanceKm;
        bestCovered = coveredBefore + segmentLength * projection.t;
      }
      coveredBefore += segmentLength;
    }

    if (totalDistance <= 0) {
      return const RouteMetrics(progress: 0, deviationKm: 0);
    }

    return RouteMetrics(
      progress: (bestCovered / totalDistance).clamp(0.0, 1.0),
      deviationKm: bestDeviation.isFinite ? bestDeviation : 0,
    );
  }

  static _Projection _projectOnSegment(
    GeoPoint start,
    GeoPoint end,
    GeoPoint point,
  ) {
    const earthRadiusKm = 6371.0088;
    final lat0 = _rad((start.latitude + end.latitude + point.latitude) / 3);

    final x1 = _rad(start.longitude) * math.cos(lat0) * earthRadiusKm;
    final y1 = _rad(start.latitude) * earthRadiusKm;
    final x2 = _rad(end.longitude) * math.cos(lat0) * earthRadiusKm;
    final y2 = _rad(end.latitude) * earthRadiusKm;
    final xp = _rad(point.longitude) * math.cos(lat0) * earthRadiusKm;
    final yp = _rad(point.latitude) * earthRadiusKm;

    final dx = x2 - x1;
    final dy = y2 - y1;
    final lenSq = dx * dx + dy * dy;

    final t = lenSq == 0
        ? 0.0
        : ((xp - x1) * dx + (yp - y1) * dy) / lenSq;
    final clampedT = t.clamp(0.0, 1.0);

    final nearestX = x1 + dx * clampedT;
    final nearestY = y1 + dy * clampedT;
    final deviation = math.hypot(xp - nearestX, yp - nearestY);

    return _Projection(
      t: clampedT,
      distanceKm: deviation,
    );
  }

  static double _rad(double degrees) =>
      degrees * math.pi / 180.0;
}

class _Projection {
  const _Projection({
    required this.t,
    required this.distanceKm,
  });

  final double t;
  final double distanceKm;
}
