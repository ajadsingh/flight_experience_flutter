import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/constants/app_config.dart';
import '../../core/models/flight_record.dart';
import '../../core/models/flight_sample.dart';
import '../../core/models/flight_route.dart';
import '../../core/models/flight_state.dart';
import '../../core/models/geo_point.dart';
import '../../core/models/gps_status.dart';
import '../../core/services/demo_flight_service.dart';
import '../../core/services/flight_history_repository.dart';
import '../../core/services/gps_quality_service.dart';
import '../../core/services/gps_service.dart';
import '../../core/services/gps_smoother.dart';
import '../../core/services/nearby_poi_service.dart';
import '../../core/services/poi_repository.dart';
import '../../core/services/route_metrics_service.dart';
import '../../core/services/tile_cache_service.dart';
import 'flight_routes.dart';

final flightControllerProvider =
    NotifierProvider<FlightController, FlightState>(FlightController.new);

class FlightController extends Notifier<FlightState> {
  final _demo = DemoFlightService();
  final _gps = GpsService();
  final _quality = GpsQualityService();
  final _smoother = GpsSmoother();
  final _routeMetrics = RouteMetricsService();
  final _history = const FlightHistoryRepository();

  StreamSubscription<Position>? _gpsSubscription;
  StreamSubscription<MapDownloadStatus>? _cacheSubscription;
  Timer? _elapsedTimer;
  final Stopwatch _stopwatch = Stopwatch();

  late Future<void> _poisLoaded;
  NearbyPoiService _nearbyService = NearbyPoiService(const []);

  final List<GeoPoint> _trackBuffer = [];
  final List<FlightSample> _samples = [];
  static const _maxTrackPoints = 600;

  DateTime? _sessionStartedAt;
  DateTime? _lastAcceptedAt;
  GeoPoint? _lastAcceptedPosition;
  double _maxSpeedKmh = 0;
  double _maxAltitudeFt = 0;
  bool _finalizing = false;

  @override
  FlightState build() {
    final route = demoRoutes.first;
    _poisLoaded = _loadPois();
    ref.onDispose(_stopAll);

    scheduleMicrotask(() => _restoreCacheStatus(route));

    return FlightState.initial(route).copyWith(
      satelliteAvailable: AppConfig.satelliteTileUrl.isNotEmpty,
    );
  }

  Future<void> _loadPois() async {
    try {
      final pois = await const PoiRepository().load();
      _nearbyService = NearbyPoiService(pois);
    } catch (error) {
      debugPrint('FlightController: POI load failed: $error');
    }
  }

  Future<void> _restoreCacheStatus(FlightRoute route) async {
    try {
      final status =
          await TileCacheService.instance.restoreStatus(route.id);
      if (status == null || state.route.id != route.id) return;

      state = state.copyWith(
        mapDownloadProgress: status.progress,
        isMapDownloading: false,
        isMapOfflineReady: status.isDone,
        downloadedTiles: status.downloaded,
        totalTiles: status.total,
        downloadedBytes: status.downloadedBytes,
        failedTiles: status.failedTiles,
        mapDownloadCancelled: status.cancelled,
      );
    } catch (error) {
      debugPrint('FlightController: cached map status unavailable: $error');
    }
  }

  Future<void> _watchAndCacheRoute(FlightRoute route) async {
    _cacheSubscription?.cancel();
    _cacheSubscription =
        TileCacheService.instance.watchProgress(route.id).listen((status) {
      if (state.route.id != route.id) return;
      state = state.copyWith(
        mapDownloadProgress: status.progress,
        isMapDownloading: status.isDownloading,
        isMapOfflineReady: status.isDone,
        downloadedTiles: status.downloaded,
        totalTiles: status.total,
        downloadedBytes: status.downloadedBytes,
        failedTiles: status.failedTiles,
        mapDownloadCancelled: status.cancelled,
        message: status.cancelled
            ? 'Offline map download cancelled'
            : status.failedTiles > 0
                ? 'Some map tiles failed — tap retry'
                : status.isDone
                    ? 'Offline map ready'
                    : state.message,
      );
    });

    final current =
        await TileCacheService.instance.restoreStatus(route.id);
    if (current != null && state.route.id == route.id) {
      state = state.copyWith(
        mapDownloadProgress: current.progress,
        isMapDownloading: current.isDownloading,
        isMapOfflineReady: current.isDone,
        downloadedTiles: current.downloaded,
        totalTiles: current.total,
        downloadedBytes: current.downloadedBytes,
        failedTiles: current.failedTiles,
        mapDownloadCancelled: current.cancelled,
      );
      if (current.isDone) return;
    }

    state = state.copyWith(
      isMapDownloading: true,
      isMapOfflineReady: false,
      mapDownloadCancelled: false,
      message: 'Preparing offline map...',
    );

    try {
      await TileCacheService.instance.cacheRoute(route);
    } catch (error) {
      debugPrint('FlightController: map caching failed: $error');
      if (state.route.id == route.id) {
        state = state.copyWith(
          isMapDownloading: false,
          isMapOfflineReady: false,
          message: 'Offline map download failed — tap retry',
        );
      }
    }
  }

  void cacheCurrentRoute() {
    final route = state.route;
    unawaited(_watchAndCacheRoute(route));
  }

  Future<void> cancelMapDownload() async {
    await TileCacheService.instance.cancelRoute(state.route.id);
  }

  Future<void> deleteCurrentOfflineMap() async {
    await TileCacheService.instance.deleteRoute(state.route.id);
    state = state.copyWith(
        mapDownloadProgress: 0,
        isMapDownloading: false,
        isMapOfflineReady: false,
        downloadedTiles: 0,
        totalTiles: 0,
        downloadedBytes: 0,
        failedTiles: 0,
        mapDownloadCancelled: false,
      );
    }
  }

  void selectMode(FlightMode mode) {
    _stopTracking();
    _trackBuffer.clear();
    _resetSessionData();

    state = FlightState.initial(state.route).copyWith(
      mode: mode,
      satelliteAvailable: AppConfig.satelliteTileUrl.isNotEmpty,
      isMapOfflineReady: state.isMapOfflineReady,
      isMapDownloading: state.isMapDownloading,
      mapDownloadProgress: state.mapDownloadProgress,
      downloadedTiles: state.downloadedTiles,
      totalTiles: state.totalTiles,
      downloadedBytes: state.downloadedBytes,
      failedTiles: state.failedTiles,
      message: mode == FlightMode.demo
          ? 'Demo flight ready'
          : 'GPS mode ready — tap Start',
    );
  }

  void selectRoute(FlightRoute route) {
    _stopTracking();
    _trackBuffer.clear();
    _resetSessionData();
    _cacheSubscription?.cancel();
    _cacheSubscription = null;

    state = FlightState.initial(route).copyWith(
      mode: state.mode,
      satelliteAvailable: AppConfig.satelliteTileUrl.isNotEmpty,
      message: state.mode == FlightMode.demo
          ? 'Demo flight ready'
          : 'GPS mode ready — tap Start',
    );

    unawaited(_restoreCacheStatus(route));
  }

  Future<bool> start() async {
    await _poisLoaded;
    if (state.started) return true;

    if (state.mode == FlightMode.demo) {
      _startDemo();
      return true;
    }

    final ready = await _gps.ensureReady();
    if (!ready) {
      state = state.copyWith(
        gpsAvailable: false,
        gpsQuality: GpsQuality.noFix,
        message: 'Enable device location permission and service',
      );
      return false;
    }

    _beginSession();
    _gpsSubscription?.cancel();

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
    state = state.copyWith(
      started: true,
      gpsAvailable: true,
      message: 'GPS tracking live',
    );
    return true;
  }

  void _startDemo() {
    _beginSession();
    _demo.stop();

    state = state.copyWith(
      started: true,
      track: const [],
      progress: 0,
      elapsed: Duration.zero,
      gpsAvailable: false,
      gpsQuality: GpsQuality.noFix,
      gpsAccuracyM: 0,
      isMockLocation: false,
      routeDeviationKm: 0,
      routeConfidence: 1,
      message: 'Demo flight running',
      clearBelow: true,
      clearAhead: true,
    );

    _demo.start(state.route, (tick) {
      final below = _nearbyService.findBelow(tick.position);
      final ahead = _nearbyService.findAhead(
        tick.position,
        tick.heading,
      );

      _update(
        position: tick.position,
        progress: tick.progress,
        speedKmh: tick.speedKmh,
        altitudeFt: tick.altitudeFt,
        heading: tick.heading,
        elapsed: tick.elapsed,
        routeDeviationKm: 0,
        routeConfidence: 1,
        below: below,
        ahead: ahead,
        clearBelow: below == null,
        clearAhead: ahead == null,
        sampleAt: _sessionStartedAt?.add(tick.elapsed),
        accuracyM: 0,
      );

      if (tick.progress >= 1) {
        unawaited(finish(message: 'Demo flight completed'));
      }
    });
  }

  void _handleGpsPosition(Position position) {
    final status = _quality.assess(position);
    state = state.copyWith(
      gpsAvailable: status.usable,
      gpsQuality: status.quality,
      gpsAccuracyM: status.accuracyM.isFinite ? status.accuracyM : 0,
      lastFixAt: position.timestamp,
      isMockLocation: status.isMocked,
    );

    if (!status.usable) {
      state = state.copyWith(message: 'Waiting for a usable GPS fix');
      return;
    }

    final timestamp = position.timestamp;
    final previousTime = _lastAcceptedAt;
    final rawPoint = _gps.toGeoPoint(position);

    if (previousTime != null) {
      final seconds = timestamp.difference(previousTime).inMilliseconds / 1000;
      if (seconds < 3) return;

      final previousPoint = _lastAcceptedPosition;
      if (previousPoint != null && seconds > 0) {
        final jumpKm = GeoPoint.distanceKm(previousPoint, rawPoint);
        final impliedSpeed = jumpKm / (seconds / 3600);
        final reportedSpeedKmh = position.speed.isFinite && position.speed >= 0
            ? position.speed * 3.6
            : 0.0;
        if (impliedSpeed > 1500 && reportedSpeedKmh < 1300) {
          state = state.copyWith(
            message: 'Ignoring an implausible GPS jump',
          );
          return;
        }
      }
    }

    final filteredPoint = _smoother.update(
      rawPoint,
      accuracyM: status.accuracyM,
    );

    var speedKmh = position.speed.isFinite && position.speed >= 0
        ? position.speed * 3.6
        : 0.0;

    if (speedKmh <= 1 && previousTime != null) {
      final previousPoint = _lastAcceptedPosition;
      if (previousPoint != null) {
        final seconds =
            timestamp.difference(previousTime).inMilliseconds / 1000;
        if (seconds > 0) {
          speedKmh = GeoPoint.distanceKm(previousPoint, filteredPoint) /
              (seconds / 3600);
        }
      }
    }

    final altitudeFt = position.altitude.isFinite
        ? position.altitude * 3.28084
        : state.altitudeFt;

    var heading = position.heading.isFinite && position.heading >= 0
        ? position.heading
        : state.heading;

    final previousPoint = _lastAcceptedPosition;
    if (position.heading < 0 &&
        previousPoint != null &&
        GeoPoint.distanceKm(previousPoint, filteredPoint) > 0.5) {
      heading = GeoPoint.bearingDegrees(previousPoint, filteredPoint);
    }

    final metrics = _routeMetrics.calculate(state.route, filteredPoint);
    final below = _nearbyService.findBelow(filteredPoint);
    final ahead = _nearbyService.findAhead(
      filteredPoint,
      heading,
    );

    _lastAcceptedAt = timestamp;
    _lastAcceptedPosition = filteredPoint;

    _update(
      position: filteredPoint,
      progress: metrics.progress,
      speedKmh: speedKmh,
      altitudeFt: altitudeFt,
      heading: heading,
      elapsed: _stopwatch.elapsed,
      routeDeviationKm: metrics.deviationKm,
      routeConfidence: metrics.confidence,
      below: below,
      ahead: ahead,
      clearBelow: below == null,
      clearAhead: ahead == null,
      sampleAt: timestamp,
      accuracyM: status.accuracyM,
      message: status.isMocked
          ? 'GPS tracking live — mock location detected'
          : 'GPS tracking live',
    );
  }

  void _update({
    required GeoPoint position,
    required double progress,
    required double speedKmh,
    required double altitudeFt,
    required double heading,
    required Duration elapsed,
    required double routeDeviationKm,
    required double routeConfidence,
    NearbyPoi? below,
    NearbyPoi? ahead,
    bool clearBelow = false,
    bool clearAhead = false,
    DateTime? sampleAt,
    double accuracyM = 0,
    String? message,
  }) {
    _trackBuffer.add(position);
    if (_trackBuffer.length > _maxTrackPoints) {
      _trackBuffer.removeAt(0);
    }

    if (sampleAt != null) {
      _samples.add(
        FlightSample(
          position: position,
          timestamp: sampleAt,
          speedKmh: speedKmh,
          altitudeFt: altitudeFt,
          heading: heading,
          accuracyM: accuracyM,
        ),
      );
      if (_samples.length > _maxTrackPoints) {
        _samples.removeAt(0);
      }
    }

    _maxSpeedKmh = speedKmh > _maxSpeedKmh ? speedKmh : _maxSpeedKmh;
    _maxAltitudeFt =
        altitudeFt > _maxAltitudeFt ? altitudeFt : _maxAltitudeFt;

    final nearby = _nearbyService.find(position);

    state = state.copyWith(
      currentPosition: position,
      track: List.unmodifiable(_trackBuffer),
      progress: progress,
      speedKmh: speedKmh,
      altitudeFt: altitudeFt,
      heading: heading,
      nearby: nearby,
      below: below,
      ahead: ahead,
      clearBelow: clearBelow,
      clearAhead: clearAhead,
      elapsed: elapsed,
      routeDeviationKm: routeDeviationKm,
      routeConfidence: routeConfidence,
      message: message,
    );
  }

  void _beginSession() {
    if (_sessionStartedAt != null) return;

    _sessionStartedAt = DateTime.now();
    _lastAcceptedAt = null;
    _lastAcceptedPosition = null;
    _maxSpeedKmh = 0;
    _maxAltitudeFt = 0;
    _trackBuffer.clear();
    _samples.clear();
    _smoother.reset();
    _finalizing = false;
  }

  void _resetSessionData() {
    _sessionStartedAt = null;
    _lastAcceptedAt = null;
    _lastAcceptedPosition = null;
    _maxSpeedKmh = 0;
    _maxAltitudeFt = 0;
    _samples.clear();
    _finalizing = false;
    _smoother.reset();
  }

  Future<void> finish({String message = 'Flight finished'}) async {
    if (_finalizing) return;

    final startedAt = _sessionStartedAt;
    _finalizing = true;
    _stopTracking();

    try {
      if (startedAt != null && _trackBuffer.length >= 2) {
        final record = FlightRecord.fromSession(
          route: state.route,
          startedAt: startedAt,
          duration: state.elapsed,
          track: _trackBuffer,
          maxSpeedKmh: _maxSpeedKmh,
          maxAltitudeFt: _maxAltitudeFt,
          samples: _samples,
        );
        await _history.save(record);
      }
    } catch (error) {
      debugPrint('FlightController: history save failed: $error');
    } finally {
      _resetSessionData();
      state = state.copyWith(
        started: false,
        message: message,
      );
      _finalizing = false;
    }
  }

  void toggleMapLayer() {
    if (!state.satelliteAvailable &&
        state.mapLayer == MapLayer.street) {
      return;
    }

    state = state.copyWith(
      mapLayer: state.mapLayer == MapLayer.street
          ? MapLayer.satellite
          : MapLayer.street,
    );
  }

  void stop() {
    unawaited(finish());
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
