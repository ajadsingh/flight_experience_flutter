import 'package:geolocator/geolocator.dart';

import '../models/gps_status.dart';

class GpsQualityService {
  const GpsQualityService();

  GpsStatus assess(Position position, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final age = current.difference(position.timestamp).abs();
    final accuracy =
        position.accuracy.isFinite ? position.accuracy : double.infinity;

    final quality = age > const Duration(seconds: 45)
        ? GpsQuality.noFix
        : accuracy <= 20
            ? GpsQuality.good
            : accuracy <= 50
                ? GpsQuality.fair
                : accuracy <= 150
                    ? GpsQuality.poor
                    : GpsQuality.noFix;

    return GpsStatus(
      quality: quality,
      accuracyM: accuracy,
      age: age,
      isMocked: position.isMocked,
    );
  }
}
