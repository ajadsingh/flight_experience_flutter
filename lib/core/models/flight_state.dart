import 'flight_route.dart';
import 'geo_point.dart';
import 'poi.dart';

enum FlightMode { demo, gps }

enum MapLayer { street, satellite }

enum GpsQuality { unknown, good, fair, poor, rejected }

class FlightState {
  const FlightState({
    required this.mode,
    required this.route,
    required this.started,
    required this.currentPosition,
    required this.track,
    required this.progress,
    required this.speedKmh,
    required this.altitudeFt,
    required this.heading,
    required this.nearby,
    required this.elapsed,
    required this.mapLayer,
    required this.message,
    required this.gpsAvailable,
    required this.satelliteAvailable,
    this.gpsQuality,
    this.gpsAccuracyMeters,
    this.routeDeviationKm,
    this.routeConfidence,
    this.lastGpsTimestamp,
    this.mockLocationRejected,
    this.cacheFailedTiles,
    this.cacheError,
    this.mapDownloadProgress = 0.0,
    this.isMapDownloading = false,
    this.isMapOfflineReady = false,
    this.downloadedTiles = 0,
    this.totalTiles = 0,
  });

  factory FlightState.initial(FlightRoute route) => FlightState(
        mode: FlightMode.demo,
        route: route,
        started: false,
        currentPosition: null,
        track: const [],
        progress: 0,
        speedKmh: 0,
        altitudeFt: 0,
        heading: 0,
        nearby: const [],
        elapsed: Duration.zero,
        mapLayer: MapLayer.street,
        message: 'Ready to start',
        gpsAvailable: false,
        satelliteAvailable: false,
        gpsQuality: GpsQuality.unknown,
        gpsAccuracyMeters: 0,
        routeDeviationKm: 0,
        routeConfidence: 0,
        lastGpsTimestamp: null,
        mockLocationRejected: false,
        cacheFailedTiles: 0,
        cacheError: null,
        mapDownloadProgress: 0.0,
        isMapDownloading: false,
        isMapOfflineReady: false,
        downloadedTiles: 0,
        totalTiles: 0,
      );

  final FlightMode mode;
  final FlightRoute route;
  final bool started;
  final GeoPoint? currentPosition;
  final List<GeoPoint> track;
  final double progress;
  final double speedKmh;
  final double altitudeFt;
  final double heading;
  final List<NearbyPoi> nearby;
  final Duration elapsed;
  final MapLayer mapLayer;
  final String message;
  final bool gpsAvailable;
  final bool satelliteAvailable;

  final GpsQuality gpsQuality;
  final double gpsAccuracyMeters;
  final double routeDeviationKm;
  final double routeConfidence;
  final DateTime? lastGpsTimestamp;
  final bool mockLocationRejected;
  final int cacheFailedTiles;
  final String? cacheError;

  // Offline map download state
  final double mapDownloadProgress;
  final bool isMapDownloading;
  final bool isMapOfflineReady;
  final int downloadedTiles;
  final int totalTiles;

  FlightState copyWith({
    FlightMode? mode,
    FlightRoute? route,
    bool? started,
    GeoPoint? currentPosition,
    List<GeoPoint>? track,
    double? progress,
    double? speedKmh,
    double? altitudeFt,
    double? heading,
    List<NearbyPoi>? nearby,
    Duration? elapsed,
    MapLayer? mapLayer,
    String? message,
    bool? gpsAvailable,
    bool? satelliteAvailable,
    GpsQuality? gpsQuality,
    double? gpsAccuracyMeters,
    double? routeDeviationKm,
    double? routeConfidence,
    DateTime? lastGpsTimestamp,
    bool? mockLocationRejected,
    int? cacheFailedTiles,
    String? cacheError,
    double? mapDownloadProgress,
    bool? isMapDownloading,
    bool? isMapOfflineReady,
    int? downloadedTiles,
    int? totalTiles,
  }) {
    return FlightState(
      mode: mode ?? this.mode,
      route: route ?? this.route,
      started: started ?? this.started,
      currentPosition: currentPosition ?? this.currentPosition,
      track: track ?? this.track,
      progress: progress ?? this.progress,
      speedKmh: speedKmh ?? this.speedKmh,
      altitudeFt: altitudeFt ?? this.altitudeFt,
      heading: heading ?? this.heading,
      nearby: nearby ?? this.nearby,
      elapsed: elapsed ?? this.elapsed,
      mapLayer: mapLayer ?? this.mapLayer,
      message: message ?? this.message,
      gpsAvailable: gpsAvailable ?? this.gpsAvailable,
      satelliteAvailable: satelliteAvailable ?? this.satelliteAvailable,
      gpsQuality: gpsQuality ?? this.gpsQuality,
      gpsAccuracyMeters: gpsAccuracyMeters ?? this.gpsAccuracyMeters,
      routeDeviationKm: routeDeviationKm ?? this.routeDeviationKm,
      routeConfidence: routeConfidence ?? this.routeConfidence,
      lastGpsTimestamp: lastGpsTimestamp ?? this.lastGpsTimestamp,
      mockLocationRejected: mockLocationRejected ?? this.mockLocationRejected,
      cacheFailedTiles: cacheFailedTiles ?? this.cacheFailedTiles,
      cacheError: cacheError ?? this.cacheError,
      mapDownloadProgress: mapDownloadProgress ?? this.mapDownloadProgress,
      isMapDownloading: isMapDownloading ?? this.isMapDownloading,
      isMapOfflineReady: isMapOfflineReady ?? this.isMapOfflineReady,
      downloadedTiles: downloadedTiles ?? this.downloadedTiles,
      totalTiles: totalTiles ?? this.totalTiles,
    );
  }
}
