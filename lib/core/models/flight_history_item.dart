import 'flight_route.dart';
import 'geo_point.dart';

class FlightHistoryItem {
  const FlightHistoryItem({
    required this.id,
    required this.startedAt,
    required this.route,
    required this.duration,
    required this.distanceKm,
    required this.maxSpeedKmh,
    required this.maxAltitudeFt,
    required this.track,
    required this.mode,
  });

  final String id;
  final DateTime startedAt;
  final FlightRoute route;
  final Duration duration;
  final double distanceKm;
  final double maxSpeedKmh;
  final double maxAltitudeFt;
  final List<GeoPoint> track;
  final String mode;

  factory FlightHistoryItem.fromJson(Map<String, dynamic> json) {
    final routeJson = json['route'] as Map<String, dynamic>;
    final waypoints = (routeJson['waypoints'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map((p) => GeoPoint(
              (p['lat'] as num).toDouble(),
              (p['lon'] as num).toDouble(),
            ))
        .toList(growable: false);
    final track = (json['track'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map((p) => GeoPoint(
              (p['lat'] as num).toDouble(),
              (p['lon'] as num).toDouble(),
            ))
        .toList(growable: false);
    return FlightHistoryItem(
      id: json['id'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      route: FlightRoute(
        id: routeJson['id'] as String,
        flightNumber: routeJson['flightNumber'] as String,
        origin: routeJson['origin'] as String,
        originCode: routeJson['originCode'] as String,
        destination: routeJson['destination'] as String,
        destinationCode: routeJson['destinationCode'] as String,
        waypoints: waypoints,
      ),
      duration: Duration(seconds: (json['durationSeconds'] as num).round()),
      distanceKm: (json['distanceKm'] as num).toDouble(),
      maxSpeedKmh: (json['maxSpeedKmh'] as num).toDouble(),
      maxAltitudeFt: (json['maxAltitudeFt'] as num).toDouble(),
      track: track,
      mode: json['mode'] as String? ?? 'gps',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'startedAt': startedAt.toUtc().toIso8601String(),
        'durationSeconds': duration.inSeconds,
        'distanceKm': distanceKm,
        'maxSpeedKmh': maxSpeedKmh,
        'maxAltitudeFt': maxAltitudeFt,
        'mode': mode,
        'route': {
          'id': route.id,
          'flightNumber': route.flightNumber,
          'origin': route.origin,
          'originCode': route.originCode,
          'destination': route.destination,
          'destinationCode': route.destinationCode,
          'waypoints': route.waypoints
              .map((p) => {'lat': p.latitude, 'lon': p.longitude})
              .toList(growable: false),
        },
        'track': track
            .map((p) => {'lat': p.latitude, 'lon': p.longitude})
            .toList(growable: false),
      };

  String get durationLabel {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  static double calculateDistanceKm(List<GeoPoint> points) {
    if (points.length < 2) return 0;
    var total = 0.0;
    for (var i = 1; i < points.length; i++) {
      total += GeoPoint.distanceKm(points[i - 1], points[i]);
    }
    return total;
  }
}
