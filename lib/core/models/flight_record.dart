import 'flight_route.dart';
import 'geo_point.dart';

class FlightRecord {
  const FlightRecord({
    required this.id,
    required this.routeId,
    required this.flightNumber,
    required this.origin,
    required this.originCode,
    required this.destination,
    required this.destinationCode,
    required this.startedAt,
    required this.duration,
    required this.distanceKm,
    required this.maxSpeedKmh,
    required this.maxAltitudeFt,
    required this.waypoints,
    required this.track,
  });

  final String id;
  final String routeId;
  final String flightNumber;
  final String origin;
  final String originCode;
  final String destination;
  final String destinationCode;
  final DateTime startedAt;
  final Duration duration;
  final double distanceKm;
  final double maxSpeedKmh;
  final double maxAltitudeFt;
  final List<GeoPoint> waypoints;
  final List<GeoPoint> track;

  FlightRoute toRoute() => FlightRoute(
        id: routeId,
        flightNumber: flightNumber,
        origin: origin,
        originCode: originCode,
        destination: destination,
        destinationCode: destinationCode,
        waypoints: waypoints,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'routeId': routeId,
        'flightNumber': flightNumber,
        'origin': origin,
        'originCode': originCode,
        'destination': destination,
        'destinationCode': destinationCode,
        'startedAt': startedAt.toIso8601String(),
        'durationSeconds': duration.inSeconds,
        'distanceKm': distanceKm,
        'maxSpeedKmh': maxSpeedKmh,
        'maxAltitudeFt': maxAltitudeFt,
        'waypoints': waypoints
            .map((point) => {'lat': point.latitude, 'lon': point.longitude})
            .toList(),
        'track': track
            .map((point) => {'lat': point.latitude, 'lon': point.longitude})
            .toList(),
      };

  factory FlightRecord.fromJson(Map<String, dynamic> json) {
    GeoPoint parsePoint(dynamic value) {
      final map = Map<String, dynamic>.from(value as Map);
      return GeoPoint(
        (map['lat'] as num).toDouble(),
        (map['lon'] as num).toDouble(),
      );
    }

    final waypointValues = (json['waypoints'] as List? ?? const []);
    final trackValues = (json['track'] as List? ?? const []);

    return FlightRecord(
      id: json['id'] as String,
      routeId: json['routeId'] as String,
      flightNumber: json['flightNumber'] as String,
      origin: json['origin'] as String,
      originCode: json['originCode'] as String,
      destination: json['destination'] as String,
      destinationCode: json['destinationCode'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      duration: Duration(seconds: (json['durationSeconds'] as num).round()),
      distanceKm: (json['distanceKm'] as num).toDouble(),
      maxSpeedKmh: (json['maxSpeedKmh'] as num).toDouble(),
      maxAltitudeFt: (json['maxAltitudeFt'] as num).toDouble(),
      waypoints: waypointValues.map(parsePoint).toList(growable: false),
      track: trackValues.map(parsePoint).toList(growable: false),
    );
  }

  factory FlightRecord.fromSession({
    required FlightRoute route,
    required DateTime startedAt,
    required Duration duration,
    required List<GeoPoint> track,
    required double maxSpeedKmh,
    required double maxAltitudeFt,
  }) {
    var distance = 0.0;
    for (var i = 1; i < track.length; i++) {
      distance += GeoPoint.distanceKm(track[i - 1], track[i]);
    }

    return FlightRecord(
      id: '\${route.id}-\${startedAt.microsecondsSinceEpoch}',
      routeId: route.id,
      flightNumber: route.flightNumber,
      origin: route.origin,
      originCode: route.originCode,
      destination: route.destination,
      destinationCode: route.destinationCode,
      startedAt: startedAt,
      duration: duration,
      distanceKm: distance,
      maxSpeedKmh: maxSpeedKmh,
      maxAltitudeFt: maxAltitudeFt,
      waypoints: route.waypoints,
      track: List.unmodifiable(track),
    );
  }
}
