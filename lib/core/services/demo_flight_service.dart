import 'dart:async';
import 'dart:math' as math;
import '../models/flight_route.dart';
import '../models/geo_point.dart';

class DemoFlightTick {
  const DemoFlightTick({
    required this.position,
    required this.progress,
    required this.speedKmh,
    required this.altitudeFt,
    required this.heading,
    required this.elapsed,
  });

  final GeoPoint position;
  final double progress;
  final double speedKmh;
  final double altitudeFt;
  final double heading;
  final Duration elapsed;
}

class DemoFlightService {
  Timer? _timer;
  final List<_Segment> _segments = [];
  double _totalDistance = 0;
  Duration _elapsed = Duration.zero;

  void start(FlightRoute route, void Function(DemoFlightTick tick) onTick) {
    stop();
    _buildSegments(route);
    _elapsed = Duration.zero;

    const interval = Duration(milliseconds: 500);
    _timer = Timer.periodic(interval, (_) {
      _elapsed += interval;
      final totalDurationSeconds = 90.0;
      final progress = (_elapsed.inMilliseconds / 1000 / totalDurationSeconds)
          .clamp(0.0, 1.0);
      final position = _positionAt(progress);
      final heading = _headingAt(progress);
      final altitude = _altitudeAt(progress);
      final speed = _speedAt(progress);
      onTick(
        DemoFlightTick(
          position: position,
          progress: progress,
          speedKmh: speed,
          altitudeFt: altitude,
          heading: heading,
          elapsed: _elapsed,
        ),
      );
      if (progress >= 1) {
        stop();
      }
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void _buildSegments(FlightRoute route) {
    _segments
      ..clear()
      ..addAll(
        List.generate(route.waypoints.length - 1, (index) {
          final start = route.waypoints[index];
          final end = route.waypoints[index + 1];
          return _Segment(
            start: start,
            end: end,
            distanceKm: GeoPoint.distanceKm(start, end),
          );
        }),
      );
    _totalDistance = _segments.fold(0, (sum, segment) => sum + segment.distanceKm);
  }

  GeoPoint _positionAt(double progress) {
    if (_segments.isEmpty) {
      throw StateError('Demo flight route has no segments.');
    }
    final target = _totalDistance * progress;
    var consumed = 0.0;
    for (final segment in _segments) {
      if (target <= consumed + segment.distanceKm) {
        final local = segment.distanceKm == 0
            ? 0
            : ((target - consumed) / segment.distanceKm).clamp(0.0, 1.0);
        return GeoPoint(
          segment.start.latitude +
              (segment.end.latitude - segment.start.latitude) * local,
          segment.start.longitude +
              (segment.end.longitude - segment.start.longitude) * local,
        );
      }
      consumed += segment.distanceKm;
    }
    return _segments.last.end;
  }

  double _headingAt(double progress) {
    if (_segments.isEmpty) return 0;
    final position = _positionAt(progress);
    final lookAhead = _positionAt((progress + 0.003).clamp(0.0, 1.0));
    return GeoPoint.bearingDegrees(position, lookAhead);
  }

  double _altitudeAt(double progress) {
    final climb = math.sin(math.min(progress * math.pi, math.pi));
    return 34000 * climb;
  }

  double _speedAt(double progress) {
    if (progress < 0.12) return 260 + progress * 1000;
    if (progress > 0.88) return 280 + (1 - progress) * 800;
    return 820;
  }
}

class _Segment {
  const _Segment({required this.start, required this.end, required this.distanceKm});

  final GeoPoint start;
  final GeoPoint end;
  final double distanceKm;
}
