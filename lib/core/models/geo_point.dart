import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

class GeoPoint {
  const GeoPoint(this.latitude, this.longitude);

  final double latitude;
  final double longitude;

  LatLng toLatLng() => LatLng(latitude, longitude);

  static double distanceKm(GeoPoint a, GeoPoint b) {
    const earthRadiusKm = 6371.0088;
    final dLat = _degToRad(b.latitude - a.latitude);
    final dLon = _degToRad(b.longitude - a.longitude);
    final lat1 = _degToRad(a.latitude);
    final lat2 = _degToRad(b.latitude);
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) * math.cos(lat2) * math.sin(dLon / 2) * math.sin(dLon / 2);
    return earthRadiusKm * 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
  }

  static double bearingDegrees(GeoPoint a, GeoPoint b) {
    final lat1 = _degToRad(a.latitude);
    final lat2 = _degToRad(b.latitude);
    final dLon = _degToRad(b.longitude - a.longitude);
    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    final bearing = _radToDeg(math.atan2(y, x));
    return (bearing + 360) % 360;
  }

  static double _degToRad(double degrees) => degrees * math.pi / 180;
  static double _radToDeg(double radians) => radians * 180 / math.pi;
}
