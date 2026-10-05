import '../models/geo_point.dart';
import '../models/poi.dart';

class NearbyPoiService {
  NearbyPoiService(this._pois) {
    for (final poi in _pois) {
      final key = _keyFor(poi.position);
      (_grid[key] ??= <Poi>[]).add(poi);
    }
  }

  static const _cellSizeDegrees = 1.0;

  final List<Poi> _pois;
  final Map<String, List<Poi>> _grid = {};

  List<NearbyPoi> find(GeoPoint center, {double radiusKm = 180}) {
    final result = _candidates(center, radiusKm)
        .map(
          (poi) => NearbyPoi(
            poi: poi,
            distanceKm: GeoPoint.distanceKm(center, poi.position),
            bearingDegrees: GeoPoint.bearingDegrees(center, poi.position),
          ),
        )
        .where((item) => item.distanceKm <= radiusKm)
        .toList();

    result.sort((a, b) {
      if (a.distanceKm <= 25 && b.distanceKm <= 25) {
        return a.distanceKm.compareTo(b.distanceKm);
      }

      final importance = b.poi.importance.compareTo(a.poi.importance);
      if (importance != 0) return importance;
      return a.distanceKm.compareTo(b.distanceKm);
    });

    return result.take(8).toList(growable: false);
  }

  NearbyPoi? findBelow(GeoPoint center, {double radiusKm = 100}) {
    final candidates = _candidates(center, radiusKm)
        .map(
          (poi) => NearbyPoi(
            poi: poi,
            distanceKm: GeoPoint.distanceKm(center, poi.position),
            bearingDegrees: GeoPoint.bearingDegrees(center, poi.position),
          ),
        )
        .where((item) => item.distanceKm <= radiusKm)
        .toList()
      ..sort((a, b) {
        final importance = b.poi.importance.compareTo(a.poi.importance);
        if (importance != 0 && a.distanceKm > 10 && b.distanceKm > 10) {
          return importance;
        }
        return a.distanceKm.compareTo(b.distanceKm);
      });

    return candidates.isEmpty ? null : candidates.first;
  }

  NearbyPoi? findAhead(
    GeoPoint center,
    double headingDegrees, {
    double radiusKm = 220,
    double coneDegrees = 65,
  }) {
    final candidates = _candidates(center, radiusKm)
        .map(
          (poi) => NearbyPoi(
            poi: poi,
            distanceKm: GeoPoint.distanceKm(center, poi.position),
            bearingDegrees: GeoPoint.bearingDegrees(center, poi.position),
          ),
        )
        .where((item) => item.distanceKm <= radiusKm)
        .where(
          (item) =>
              _angleDifference(
                headingDegrees,
                item.bearingDegrees ?? headingDegrees,
              ) <=
              coneDegrees,
        )
        .toList();

    candidates.sort((a, b) {
      double score(NearbyPoi item) {
        final angle = _angleDifference(
          headingDegrees,
          item.bearingDegrees ?? headingDegrees,
        );
        final importanceBonus = item.poi.importance * 0.08;
        return (item.distanceKm / radiusKm) +
            (angle / coneDegrees) -
            importanceBonus;
      }

      return score(a).compareTo(score(b));
    });

    return candidates.isEmpty ? null : candidates.first;
  }

  List<Poi> _candidates(GeoPoint center, double radiusKm) {
    final degreeRadius = radiusKm / 110.574 + 1;
    final latCell = (center.latitude / _cellSizeDegrees).floor();
    final lonCell = (center.longitude / _cellSizeDegrees).floor();
    final cellRadius = degreeRadius.ceil();
    final values = <Poi>[];

    for (var dLat = -cellRadius; dLat <= cellRadius; dLat++) {
      for (var dLon = -cellRadius; dLon <= cellRadius; dLon++) {
        values.addAll(
          _grid['${latCell + dLat}:${lonCell + dLon}'] ?? const [],
        );
      }
    }

    return values;
  }

  String _keyFor(GeoPoint point) =>
      '${(point.latitude / _cellSizeDegrees).floor()}:${(point.longitude / _cellSizeDegrees).floor()}';

  double _angleDifference(double a, double b) {
    var diff = (a - b).abs() % 360;
    if (diff > 180) diff = 360 - diff;
    return diff;
  }
}
