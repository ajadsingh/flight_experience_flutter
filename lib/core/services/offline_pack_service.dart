import 'dart:io';

import '../models/flight_route.dart';
import '../models/poi.dart';
import 'poi_pack_service.dart';
import 'tile_cache_service.dart';

class OfflinePackInfo {
  const OfflinePackInfo({
    required this.routeId,
    required this.totalTiles,
    required this.downloadedTiles,
    required this.failedTiles,
    required this.storageBytes,
    required this.poiCount,
    required this.isReady,
  });

  final String routeId;
  final int totalTiles;
  final int downloadedTiles;
  final int failedTiles;
  final int storageBytes;
  final int poiCount;
  final bool isReady;

  double get progress =>
      totalTiles == 0 ? 0 : (downloadedTiles / totalTiles).clamp(0.0, 1.0);
}

class OfflinePackService {
  OfflinePackService._();

  static final instance = OfflinePackService._();

  final _tiles = TileCacheService.instance;
  final _pois = PoiPackService.instance;

  Future<void> prepare(FlightRoute route) async {
    await _tiles.initialize();
    await Future.wait([
      _tiles.cacheRoute(route),
      _pois.prepareForRoute(route),
    ]);
  }

  Future<List<Poi>> loadPois(FlightRoute route) => _pois.loadForRoute(route);

  Future<OfflinePackInfo> info(FlightRoute route) async {
    final estimate = await _tiles.estimateRoute(route);
    final status = _tiles.getStatus(route.id);
    final storage = await _tiles.storageBytesForRoute(route.id);
    final poiCount = await _pois.countForRoute(route);
    final hasPoiPack = await this.hasPoiPack(route.id);
    return OfflinePackInfo(
      routeId: route.id,
      totalTiles: status?.total ?? estimate.totalTiles,
      downloadedTiles: status?.downloaded ?? 0,
      failedTiles: status?.failed ?? 0,
      storageBytes: storage,
      poiCount: poiCount,
      isReady: status?.isDone == true && status?.failed == 0 && hasPoiPack && poiCount > 0,
    );
  }

  Future<Map<String, int>> storageByRoute() => _tiles.storageByRoute();

  Future<int> storageBytes() async {
    final values = await storageByRoute();
    return values.values.fold(0, (sum, value) => sum + value);
  }

  Future<void> delete(FlightRoute route) async {
    await _tiles.deleteRoute(route.id);
  }

  Future<bool> hasPoiPack(String routeId) async {
    await _tiles.initialize();
    final file = File(
      '${_tiles.routeDirectoryPath(routeId)}${Platform.pathSeparator}poi_pack.json',
    );
    return file.exists();
  }

  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
