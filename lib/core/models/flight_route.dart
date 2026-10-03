import 'geo_point.dart';

class FlightRoute {
  const FlightRoute({
    required this.id,
    required this.flightNumber,
    required this.origin,
    required this.originCode,
    required this.destination,
    required this.destinationCode,
    required this.waypoints,
  });

  final String id;
  final String flightNumber;
  final String origin;
  final String originCode;
  final String destination;
  final String destinationCode;
  final List<GeoPoint> waypoints;

  GeoPoint get start => waypoints.first;
  GeoPoint get end => waypoints.last;
}
