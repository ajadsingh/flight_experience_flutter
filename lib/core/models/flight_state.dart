import 'flight_route.dart';
import 'geo_point.dart';
import 'poi.dart';
import 'gps_status.dart';

enum FlightMode { demo, gps }

enum MapLayer { street, satellite }

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
    required this.below,
    required this.ahead,
    required this.elapsed,
    required this.mapLayer,
    required this.message,
    required this.gpsAvailable,
    required this.gpsQuality,
    required this.gpsAccuracyM,
    required this.lastFixAt,
    required this.isMockLocation,
    required this.routeDeviationKm,
    required this.routeConfidence,
    required this.satelliteAvailable,
    this.mapDownloadProgress = 0.0,
    this.isMapDownloading = false,
    this.isMapOfflineReady = false,
    this.downloadedTiles = 0,
    this.totalTiles = 0,
    this.downloadedBytes = 0,
    this.failedTiles = 0,
    this.mapDownloadCancelled = false,
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
        below: null,
        ahead: null,
        elapsed: Duration.zero,
        mapLayer: MapLayer.street,
        message: 'Ready to start',
        gpsAvailable: false,
        gpsQuality: GpsQuality.noFix,
        gpsAccuracyM: 0,
        lastFixAt: null,
        isMockLocation: false,
        routeDeviationKm: 0,
        routeConfidence: 0,
        satelliteAvailable: false,
        mapDownloadProgress: 0.0,
        isMapDownloading: false,
        isMapOfflineReady: false,
        downloadedTiles: 0,
        totalTiles: 0,
        downloadedBytes: 0,
        failedTiles: 0,
        mapDownloadCancelled: false,
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
  final NearbyPoi? below;
  final NearbyPoi? ahead;
  final Duration elapsed;
  final MapLayer mapLayer;
  final String message;
  final bool gpsAvailable;
  final GpsQuality gpsQuality;
  final double gpsAccuracyM;
  final DateTime? lastFixAt;
  final bool isMockLocation;
  final double routeDeviationKm;
  final double routeConfidence;
  final bool satelliteAvailable;

  final double mapDownloadProgress;
  final bool isMapDownloading;
  final bool isMapOfflineReady;
  final int downloadedTiles;
  final int totalTiles;
  final int downloadedBytes;
  final int failedTiles;
  final bool mapDownloadCancelled;

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
    NearbyPoi? below,
    NearbyPoi? ahead,
    bool clearBelow = false,
    bool clearAhead = false,
    Duration? elapsed,
    MapLayer? mapLayer,
    String? message,
    bool? gpsAvailable,
    GpsQuality? gpsQuality,
    double? gpsAccuracyM,
    DateTime? lastFixAt,
    bool? isMockLocation,
    double? routeDeviationKm,
    double? routeConfidence,
    bool? satelliteAvailable,
    double? mapDownloadProgress,
    bool? isMapDownloading,
    bool? isMapOfflineReady,
    int? downloadedTiles,
    int? totalTiles,
    int? downloadedBytes,
    int? failedTiles,
    bool? mapDownloadCancelled,
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
      below: clearBelow ? null : (below ?? this.below),
      ahead: clearAhead ? null : (ahead ?? this.ahead),
      elapsed: elapsed ?? this.elapsed,
      mapLayer: mapLayer ?? this.mapLayer,
      message: message ?? this.message,
      gpsAvailable: gpsAvailable ?? this.gpsAvailable,
      gpsQuality: gpsQuality ?? this.gpsQuality,
      gpsAccuracyM: gpsAccuracyM ?? this.gpsAccuracyM,
      lastFixAt: lastFixAt ?? this.lastFixAt,
      isMockLocation: isMockLocation ?? this.isMockLocation,
      routeDeviationKm: routeDeviationKm ?? this.routeDeviationKm,
      routeConfidence: routeConfidence ?? this.routeConfidence,
      satelliteAvailable: satelliteAvailable ?? this.satelliteAvailable,
      mapDownloadProgress:
          mapDownloadProgress ?? this.mapDownloadProgress,
      isMapDownloading: isMapDownloading ?? this.isMapDownloading,
      isMapOfflineReady: isMapOfflineReady ?? this.isMapOfflineReady,
      downloadedTiles: downloadedTiles ?? this.downloadedTiles,
      totalTiles: totalTiles ?? this.totalTiles,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      failedTiles: failedTiles ?? this.failedTiles,
      mapDownloadCancelled:
          mapDownloadCancelled ?? this.mapDownloadCancelled,
    );
  }
}
