import 'geo_point.dart';

class Poi {
  const Poi({
    required this.name,
    required this.type,
    required this.position,
    required this.description,
  });

  final String name;
  final String type;
  final GeoPoint position;
  final String description;
}

class NearbyPoi {
  const NearbyPoi({
    required this.poi,
    required this.distanceKm,
    this.bearingDegrees = 0,
  });

  final Poi poi;
  final double distanceKm;
  final double bearingDegrees;
}

class FlightPoiSnapshot {
  const FlightPoiSnapshot({
    required this.nearby,
    this.below,
    this.ahead,
  });

  final List<NearbyPoi> nearby;
  final NearbyPoi? below;
  final NearbyPoi? ahead;
}
