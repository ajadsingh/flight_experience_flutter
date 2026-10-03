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
  const NearbyPoi({required this.poi, required this.distanceKm});

  final Poi poi;
  final double distanceKm;
}
