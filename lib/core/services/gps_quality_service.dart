import 'package:geolocator/geolocator.dart';

enum GpsQuality { noFix, poor, fair, good }

class GpsAssessment {
  const GpsAssessment({
    required this.quality,
    required this.accuracyM,
    required this.age,
    required this.isMocked,
  });

  final GpsQuality quality;
  final double accuracyM;
  final Duration age;
  final bool isMocked;

  bool get usable =>
      quality != GpsQuality.noFix && age <= const Duration(seconds: 45);

  String get label {
    switch (quality) {
      case GpsQuality.good:
        return 'Good';
      case GpsQuality.fair:
        return 'Fair';
      case GpsQuality.poor:
        return 'Weak';
      case GpsQuality.noFix:
        return 'No Fix';
    }
  }
}

class GpsQualityService {
  const GpsQualityService();

  GpsAssessment assess(Position position, {DateTime? now}) {
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

    return GpsAssessment(
      quality: quality,
      accuracyM: accuracy,
      age: age,
      isMocked: position.isMocked,
    );
  }
}
