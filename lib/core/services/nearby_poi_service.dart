import '../models/geo_point.dart';
import '../models/poi.dart';

class NearbyPoiService {
  NearbyPoiService(this._pois);

  final List<Poi> _pois;

  List<NearbyPoi> find(GeoPoint center, {double radiusKm = 180}) {
    final result = _pois
        .map((poi) => NearbyPoi(
              poi: poi,
              distanceKm: GeoPoint.distanceKm(center, poi.position),
            ))
        .where((item) => item.distanceKm <= radiusKm)
        .toList();
    result.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return result.take(5).toList(growable: false);
  }
}
