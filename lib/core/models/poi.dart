import 'geo_point.dart';

class Poi {
  const Poi({
    required this.name,
    required this.type,
    required this.position,
    required this.description,
    this.importance = 0,
  });

  final String name;
  final String type;
  final GeoPoint position;
  final String description;
  final int importance;
}

class NearbyPoi {
  const NearbyPoi({
    required this.poi,
    required this.distanceKm,
    this.bearingDegrees,
  });

  final Poi poi;
  final double distanceKm;
  final double? bearingDegrees;
}
