import '../models/geo_point.dart';

class GpsSmoother {
  GeoPoint? _smoothed;

  GeoPoint? get current => _smoothed;

  GeoPoint update(GeoPoint raw, {required double accuracyM}) {
    final previous = _smoothed;
    if (previous == null) {
      _smoothed = raw;
      return raw;
    }

    final alpha = accuracyM <= 20
        ? 0.68
        : accuracyM <= 50
            ? 0.48
            : accuracyM <= 150
                ? 0.28
                : 0.18;

    final next = GeoPoint(
      previous.latitude + (raw.latitude - previous.latitude) * alpha,
      previous.longitude + (raw.longitude - previous.longitude) * alpha,
    );
    _smoothed = next;
    return next;
  }

  void reset() {
    _smoothed = null;
  }
}
