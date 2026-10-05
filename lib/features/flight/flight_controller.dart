import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/constants/app_config.dart';
import '../../core/models/flight_route.dart';
import '../../core/models/flight_state.dart';
import '../../core/models/geo_point.dart';
import '../../core/services/demo_flight_service.dart';
import '../../core/services/gps_service.dart';
import '../../core/services/gps_position_filter.dart';
import '../../core/services/flight_route_metrics.dart';
import '../../core/services/nearby_poi_service.dart';
import '../../core/services/poi_repository.dart';
import '../../core/services/tile_cache_service.dart';
import 'flight_routes.dart';

final flightControllerProvider =
    NotifierProvider<FlightController, FlightState>(FlightController.new);

class FlightController extends Notifier<FlightState> {
  final _demo = DemoFlightService();
  final _gps = GpsService();
  final _gpsFilter = GpsPositionFilter();
  DateTime? _lastAcceptedGpsTimestamp;
  StreamSubscription<Position>? _gpsSubscription;
  StreamSubscription<MapDownloadStatus>? _cacheSubscription;

  // GPS elapsed timer — use Stopwatch + periodic timer
  Timer? _elapsedTimer;
  final Stopwatch _stopwatch = Stopwatch();

  // POI load future
  late Future<void> _poisLoaded;
  NearbyPoiService _nearbyService = NearbyPoiService(const []);

  // Reuse mutable buffer to avoid O(n) full list copy every tick
  final List<GeoPoint> _trackBuffer = [];
  static const _maxTrackPoints = 400;

  @override
  FlightState build() {
    final route = demoRoutes.first;
    _poisLoaded = _loadPois();
    ref.onDispose(_stopAll);

    // Auto-start caching map tiles for default route after initial build
    scheduleMicrotask(() => _autoCacheRoute(route));

    return FlightState.initial(route).copyWith(
      satelliteAvailable: AppConfig.satelliteTileUrl.isNotEmpty,
    );
  }

  Future<void> _loadPois() async {
    try {
      final pois = await const PoiRepository().load();
      _nearbyService = NearbyPoiService(pois);
    } catch (e) {
      debugPrint('FlightController: POI load failed — $e');
    }
  }

  Future<void> _autoCacheRoute(FlightRoute route) async {
    _cacheSubscription?.cancel();
    _cacheSubscription =
        TileCacheService.instance.watchProgress(route.id).listen((status) {
      state = state.copyWith(
        mapDownloadProgress: status.progress,
        isMapDownloading: status.isDownloading,
        isMapOfflineReady: status.isDone,
        downloadedTiles: status.downloaded,
        totalTiles: status.total,
        cacheFailedTiles: status.failed,
        cacheError: status.error,
        clearCacheError: status.error == null,
      );
    });

    final currentStatus = TileCacheService.instance.getStatus(route.id);
    if (currentStatus != null) {
      state = state.copyWith(
        mapDownloadProgress: currentStatus.progress,
        isMapDownloading: currentStatus.isDownloading,
        isMapOfflineReady: currentStatus.isDone,
        downloadedTiles: currentStatus.downloaded,
        totalTiles: currentStatus.total,
        cacheFailedTiles: currentStatus.failed,
        cacheError: currentStatus.error,
        clearCacheError: currentStatus.error == null,
      );
      if (currentStatus.isDone) return;
    } else {
      state = state.copyWith(
        isMapDownloading: true,
        isMapOfflineReady: false,
        mapDownloadProgress: 0.0,
      );
    }

    try {
      await TileCacheService.instance.cacheRoute(route);
    } catch (e) {
      debugPrint('FlightController: Map caching failed — $e');
    }
  }

  void selectMode(FlightMode mode) {
    _stopTracking();
    _trackBuffer.clear();
    _gpsFilter.reset();
    _lastAcceptedGpsTimestamp = null;
    state = FlightState.initial(state.route).copyWith(
      mode: mode,
      satelliteAvailable: AppConfig.satelliteTileUrl.isNotEmpty,
      isMapOfflineReady: state.isMapOfflineReady,
      isMapDownloading: state.isMapDownloading,
      mapDownloadProgress: state.mapDownloadProgress,
      downloadedTiles: state.downloadedTiles,
      totalTiles: state.totalTiles,
      message: mode == FlightMode.demo
          ? 'Demo flight ready'
          : 'GPS mode ready — tap Start',
    );
  }

  void selectRoute(FlightRoute route) {
    _stopTracking();
    _trackBuffer.clear();
    state = FlightState.initial(route).copyWith(
      mode: state.mode,
      satelliteAvailable: AppConfig.satelliteTileUrl.isNotEmpty,
      isMapOfflineReady: false,
      isMapDownloading: false,
      mapDownloadProgress: 0,
      downloadedTiles: 0,
      totalTiles: 0,
      message: state.mode == FlightMode.demo
          ? 'Demo flight ready'
          : 'GPS mode ready — tap Start',
    );
    // Auto-download route map when user selects route
    unawaited(_autoCacheRoute(route));
  }

  Future<void> cacheCurrentRoute() async {
    await _autoCacheRoute(state.route);
  }

  Future<bool> start() async {
    await _poisLoaded;

    if (state.mode == FlightMode.demo) {
      _startDemo();
      return true;
    }

    final ready = await _gps.ensureReady();
    if (!ready) {
      state = state.copyWith(
        message: 'Location service or permission is unavailable.',
        gpsAvailable: false,
      );
      return false;
    }

    _gpsSubscription?.cancel();
    _gpsFilter.reset();
    _lastAcceptedGpsTimestamp = null;

    _stopwatch
      ..reset()
      ..start();
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.started) {
        state = state.copyWith(elapsed: _stopwatch.elapsed);
      }
    });

    _gpsSubscription = _gps.watch().listen(_handleGpsPosition);
    state = state.copyWith(started: true, gpsAvailable: true, message: 'GPS tracking live');
    return true;
  }

  void _startDemo() {
    _demo.stop();
    _trackBuffer.clear();
    state = state.copyWith(
      started: true,
      track: const [],
      progress: 0,
      elapsed: Duration.zero,
      message: 'Demo flight running',
    );
    _demo.start(state.route, (tick) {
      _update(
        position: tick.position,
        progress: tick.progress,
        speedKmh: tick.speedKmh,
        altitudeFt: tick.altitudeFt,
        heading: tick.heading,
        elapsed: tick.elapsed,
      );
      if (tick.progress >= 1) {
        state = state.copyWith(started: false, message: 'Demo flight completed');
      }
    });
  }

  void _handleGpsPosition(Position position) {
    final now = DateTime.now();
    final timestamp = position.timestamp;
    final age = now.difference(timestamp);

    if (age > const Duration(minutes: 2) || age < const Duration(minutes: -2)) {
      state = state.copyWith(
        gpsQuality: GpsQuality.rejected,
        gpsAccuracyMeters: position.accuracy,
        message: 'Waiting for a fresh GPS fix.',
      );
      return;
    }

    if (position.isMocked && !AppConfig.allowMockGps) {
      state = state.copyWith(
        gpsQuality: GpsQuality.rejected,
        gpsAccuracyMeters: position.accuracy,
        mockLocationRejected: true,
        message: 'Mock GPS location rejected.',
      );
      return;
    }

    final accuracy = position.accuracy;
    final quality = _gpsQuality(accuracy);
    if (quality == GpsQuality.rejected) {
      state = state.copyWith(
        gpsQuality: quality,
        gpsAccuracyMeters: accuracy,
        message: 'GPS accuracy is too low — waiting for a better fix.',
      );
      return;
    }

    final rawPoint = _gps.toGeoPoint(position);
    final point = _gpsFilter.update(raw: rawPoint, accuracyMeters: accuracy);
    if (point == null) {
      state = state.copyWith(
        gpsQuality: GpsQuality.rejected,
        gpsAccuracyMeters: accuracy,
        message: 'GPS fix rejected as an outlier.',
      );
      return;
    }

    _lastAcceptedGpsTimestamp = timestamp;
    final metrics = FlightRouteMetrics.calculate(state.route, point);
    final confidence = _routeConfidence(
      deviationKm: metrics.deviationKm,
      accuracyMeters: accuracy,
    );

    final speedKmh = position.speed.isFinite && position.speed >= 0
        ? position.speed * 3.6
        : 0.0;
    final altitudeFt = position.altitude.isFinite
        ? position.altitude * 3.28084
        : state.altitudeFt;
    final heading = position.heading.isFinite && position.heading >= 0
        ? position.heading
        : state.heading;

    _update(
      position: point,
      progress: metrics.progress,
      speedKmh: speedKmh,
      altitudeFt: altitudeFt,
      heading: heading,
      elapsed: _stopwatch.elapsed,
      message: _gpsMessage(quality, metrics.deviationKm),
      gpsQuality: quality,
      gpsAccuracyMeters: accuracy,
      routeDeviationKm: metrics.deviationKm,
      routeConfidence: confidence,
      lastGpsTimestamp: _lastAcceptedGpsTimestamp,
      mockLocationRejected: false,
    );
  }

  GpsQuality _gpsQuality(double accuracyMeters) {
    if (!accuracyMeters.isFinite || accuracyMeters < 0) return GpsQuality.rejected;
    if (accuracyMeters <= 30) return GpsQuality.good;
    if (accuracyMeters <= 100) return GpsQuality.fair;
    if (accuracyMeters <= 250) return GpsQuality.poor;
    return GpsQuality.rejected;
  }

  double _routeConfidence({
    required double deviationKm,
    required double accuracyMeters,
  }) {
    final deviationScore = deviationKm <= 5
        ? 1.0
        : deviationKm >= 40
            ? 0.0
            : 1.0 - ((deviationKm - 5) / 35);
    final accuracyScore = (1.0 - (accuracyMeters / 250)).clamp(0.0, 1.0);
    return (deviationScore * 0.7 + accuracyScore * 0.3).clamp(0.0, 1.0);
  }

  String _gpsMessage(GpsQuality quality, double deviationKm) {
    if (deviationKm >= 40) {
      return 'GPS live — ' + deviationKm.toStringAsFixed(0) + ' km from planned corridor.';
    }
    switch (quality) {
      case GpsQuality.good:
        return 'GPS live — good accuracy.';
      case GpsQuality.fair:
        return 'GPS live — fair accuracy.';
      case GpsQuality.poor:
        return 'GPS live — weak accuracy.';
      case GpsQuality.rejected:
        return 'GPS fix rejected.';
      case GpsQuality.unknown:
        return 'GPS tracking live';
    }
  }

  void _update({
    required GeoPoint position,
    required double progress,
    required double speedKmh,
    required double altitudeFt,
    required double heading,
    required Duration elapsed,
    String? message,
    GpsQuality? gpsQuality,
    double? gpsAccuracyMeters,
    double? routeDeviationKm,
    double? routeConfidence,
    DateTime? lastGpsTimestamp,
    bool? mockLocationRejected,
  }) {
    _trackBuffer.add(position);
    if (_trackBuffer.length > _maxTrackPoints) {
      _trackBuffer.removeAt(0);
    }

    final nearby = _nearbyService.find(position);
    state = state.copyWith(
      currentPosition: position,
      track: List.unmodifiable(_trackBuffer),
      progress: progress,
      speedKmh: speedKmh,
      altitudeFt: altitudeFt,
      heading: heading,
      nearby: nearby,
      elapsed: elapsed,
      message: message,
      gpsQuality: gpsQuality,
      gpsAccuracyMeters: gpsAccuracyMeters,
      routeDeviationKm: routeDeviationKm,
      routeConfidence: routeConfidence,
      lastGpsTimestamp: lastGpsTimestamp,
      mockLocationRejected: mockLocationRejected,
    );
  }

  void toggleMapLayer() {
    if (state.mapLayer == MapLayer.street && !state.satelliteAvailable) return;
    state = state.copyWith(
      mapLayer: state.mapLayer == MapLayer.street ? MapLayer.satellite : MapLayer.street,
    );
  }

  void stop() {
    _stopTracking();
    state = state.copyWith(started: false, message: 'Tracking paused');
  }

  void _stopTracking() {
    _demo.stop();
    _gpsSubscription?.cancel();
    _gpsSubscription = null;
    _elapsedTimer?.cancel();
    _elapsedTimer = null;
    _stopwatch.stop();
  }

  void _stopAll() {
    _stopTracking();
    _cacheSubscription?.cancel();
    _cacheSubscription = null;
  }
}
