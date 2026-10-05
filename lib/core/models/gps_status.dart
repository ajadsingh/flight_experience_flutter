enum GpsQuality { noFix, poor, fair, good }

class GpsStatus {
  const GpsStatus({
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
