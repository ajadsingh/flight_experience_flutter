import 'dart:math' as math;

import '../models/geo_point.dart';
import '../models/poi.dart';

class NearbyPoiService {
  NearbyPoiService(this._pois);

  final List<Poi> _pois;

  List<NearbyPoi> find(GeoPoint center, {double radiusKm = 180}) {
    return discover(center, headingDegrees: 0, radiusKm: radiusKm).nearby;
  }

  FlightPoiSnapshot discover(
    GeoPoint center, {
    required double headingDegrees,
    double radiusKm = 180,
    double aheadConeDegrees = 60,
  }) {
    final candidates = _pois
        .map(
          (poi) => NearbyPoi(
            poi: poi,
            distanceKm: GeoPoint.distanceKm(center, poi.position),
            bearingDegrees:
                GeoPoint.bearingDegrees(center, poi.position),
          ),
        )
        .where((item) => item.distanceKm <= radiusKm)
        .toList()
      ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

    final below = candidates.isEmpty ? null : candidates.first;

    NearbyPoi? ahead;
    double bestAheadScore = double.infinity;
    for (final item in candidates) {
      if (below != null && item.poi.name == below.poi.name) continue;
      final delta = _bearingDelta(headingDegrees, item.bearingDegrees);
      if (delta > aheadConeDegrees) continue;

      // Favor places that are both close and strongly ahead.
      final score = item.distanceKm + delta * 2.0;
      if (score < bestAheadScore) {
        bestAheadScore = score;
        ahead = item;
      }
    }

    return FlightPoiSnapshot(
      nearby: candidates.take(5).toList(growable: false),
      below: below,
      ahead: ahead,
    );
  }

  double _bearingDelta(double a, double b) {
    final difference = (a - b).abs() % 360;
    return math.min(difference, 360 - difference);
  }
}
