import 'geo_point.dart';

class FlightSample {
  const FlightSample({
    required this.position,
    required this.timestamp,
    required this.speedKmh,
    required this.altitudeFt,
    required this.heading,
    required this.accuracyM,
  });

  final GeoPoint position;
  final DateTime timestamp;
  final double speedKmh;
  final double altitudeFt;
  final double heading;
  final double accuracyM;

  Map<String, dynamic> toJson() => {
        'lat': position.latitude,
        'lon': position.longitude,
        'timestamp': timestamp.toIso8601String(),
        'speedKmh': speedKmh,
        'altitudeFt': altitudeFt,
        'heading': heading,
        'accuracyM': accuracyM,
      };

  factory FlightSample.fromJson(Map<String, dynamic> json) {
    return FlightSample(
      position: GeoPoint(
        (json['lat'] as num).toDouble(),
        (json['lon'] as num).toDouble(),
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      speedKmh: (json['speedKmh'] as num?)?.toDouble() ?? 0,
      altitudeFt: (json['altitudeFt'] as num?)?.toDouble() ?? 0,
      heading: (json['heading'] as num?)?.toDouble() ?? 0,
      accuracyM: (json['accuracyM'] as num?)?.toDouble() ?? 0,
    );
  }
}
