import '../models/geo_point.dart';

class GpsPositionFilter {
  GpsPositionFilter({
    this.minAccuracyMeters = 250,
    this.maxJumpKm = 120,
    this.alpha = 0.35,
  });

  final double minAccuracyMeters;
  final double maxJumpKm;
  final double alpha;

  GeoPoint? _smoothed;

  GeoPoint? get current => _smoothed;

  GeoPoint? update({
    required GeoPoint raw,
    required double accuracyMeters,
  }) {
    if (!accuracyMeters.isFinite || accuracyMeters < 0) return null;
    if (accuracyMeters > minAccuracyMeters) return null;

    final previous = _smoothed;
    if (previous != null &&
        GeoPoint.distanceKm(previous, raw) > maxJumpKm) {
      return previous;
    }

    if (previous == null) {
      _smoothed = raw;
      return raw;
    }

    final safeAccuracy = accuracyMeters.clamp(5.0, minAccuracyMeters);
    final weight = (alpha * (50.0 / safeAccuracy)).clamp(0.15, 0.75);
    _smoothed = GeoPoint(
      previous.latitude + (raw.latitude - previous.latitude) * weight,
      previous.longitude + (raw.longitude - previous.longitude) * weight,
    );
    return _smoothed;
  }

  void reset() {
    _smoothed = null;
  }
}
