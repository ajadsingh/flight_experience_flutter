import 'package:geolocator/geolocator.dart';
import '../models/geo_point.dart';

class GpsService {
  Future<bool> ensureReady() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Stream<Position> watch() {
    const settings = LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 50,
    );
    return Geolocator.getPositionStream(locationSettings: settings);
  }

  GeoPoint toGeoPoint(Position position) =>
      GeoPoint(position.latitude, position.longitude);
}
