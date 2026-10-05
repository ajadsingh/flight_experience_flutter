import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../constants/app_config.dart';
import '../models/flight_route.dart';
import '../models/geo_point.dart';

class MapDownloadStatus {
  const MapDownloadStatus({
    required this.routeId,
    required this.downloaded,
    required this.total,
    required this.isDownloading,
    required this.isDone,
    required this.progress,
    this.failed = 0,
    this.error,
  });

  final String routeId;
  final int downloaded;
  final int total;
  final bool isDownloading;
  final bool isDone;
  final double progress;
  final int failed;
  final String? error;
}

class TileCacheEstimate {
  const TileCacheEstimate({required this.totalTiles});

  final int totalTiles;
}

class TileCacheService {
  TileCacheService._();

  static final TileCacheService instance = TileCacheService._();

  final Map<String, MapDownloadStatus> _statuses = {};
  final Map<String, StreamController<MapDownloadStatus>> _controllers = {};
  final Map<String, Future<void>> _active = {};
  Directory? _rootDirectory;

  bool get isInitialized => _rootDirectory != null;
  String get rootPath => _rootDirectory?.path ?? '';

  Future<void> initialize() async {
    if (_rootDirectory != null) return;
    final root = await getApplicationSupportDirectory();
    final directory = Directory(
      '${root.path}${Platform.pathSeparator}flight_experience_tiles',
    );
    await directory.create(recursive: true);
    _rootDirectory = directory;
  }

  Stream<MapDownloadStatus> watchProgress(String routeId) {
    final controller = _controllers.putIfAbsent(
      routeId,
      () => StreamController<MapDownloadStatus>.broadcast(),
    );
    return controller.stream;
  }

  MapDownloadStatus? getStatus(String routeId) => _statuses[routeId];

  Future<TileCacheEstimate> estimateRoute(FlightRoute route) async {
    await initialize();
    final tileCount = _buildCorridorTiles(route).length;
    final sourceCount = AppConfig.satelliteTileUrl.isEmpty ? 1 : 2;
    return TileCacheEstimate(totalTiles: tileCount * sourceCount);
  }

  Future<int> storageBytesForRoute(String routeId) async {
    await initialize();
    final dir = _routeDirectory(routeId);
    if (!await dir.exists()) return 0;
    return _directorySize(dir);
  }

  Future<Map<String, int>> storageByRoute() async {
    await initialize();
    final result = <String, int>{};
    final root = _rootDirectory!;
    if (!await root.exists()) return result;
    await for (final entity in root.list(followLinks: false)) {
      if (entity is Directory) {
        result[entity.path.split(Platform.pathSeparator).last] =
            await _directorySize(entity);
      }
    }
    return result;
  }

  Future<void> deleteRoute(String routeId) async {
    await initialize();
    final active = _active[routeId];
    if (active != null) await active;
    final dir = _routeDirectory(routeId);
    if (await dir.exists()) await dir.delete(recursive: true);
    _statuses.remove(routeId);
  }

  Future<void> cacheRoute(FlightRoute route) async {
    await initialize();
    final active = _active[route.id];
    if (active != null) {
      await active;
      return;
    }
    final future = _cacheRouteInternal(route);
    _active[route.id] = future;
    try {
      await future;
    } finally {
      if (identical(_active[route.id], future)) _active.remove(route.id);
    }
  }

  Future<void> _cacheRouteInternal(FlightRoute route) async {
    final tiles = _buildCorridorTiles(route);
    final sources = <_TileSource>[
      const _TileSource(layerName: 'street', template: AppConfig.defaultTileUrl),
      if (AppConfig.satelliteTileUrl.isNotEmpty)
        const _TileSource(layerName: 'satellite', template: AppConfig.satelliteTileUrl),
    ];
    final total = tiles.length * sources.length;

    if (total > AppConfig.maxOfflineTiles) {
      _publish(MapDownloadStatus(
        routeId: route.id,
        downloaded: 0,
        total: total,
        isDownloading: false,
        isDone: false,
        progress: 0,
        error: 'Offline map is too large for the learning cache limit.',
      ));
      return;
    }

    if (total == 0) {
      _publish(MapDownloadStatus(
        routeId: route.id, downloaded: 0, total: 0,
        isDownloading: false, isDone: true, progress: 1,
      ));
      await _writeManifest(route, 0, 0);
      return;
    }

    final client = http.Client();
    try {
      int downloaded = 0;
      int failed = 0;
      _publish(MapDownloadStatus(
        routeId: route.id, downloaded: 0, total: total,
        isDownloading: true, isDone: false, progress: 0,
      ));

      final pending = <_TileRequest>[];
      for (final source in sources) {
        for (final tile in tiles) {
          final target = _tileFile(route.id, source.layerName, tile.z, tile.x, tile.y);
          if (await target.exists() && await target.length() > 0) {
            downloaded++;
          } else {
            pending.add(_TileRequest(source: source, tile: tile, target: target));
          }
        }
      }

      _publish(MapDownloadStatus(
        routeId: route.id, downloaded: downloaded, total: total,
        isDownloading: pending.isNotEmpty, isDone: pending.isEmpty,
        progress: downloaded / total,
      ));

      const concurrency = 6;
      for (int offset = 0; offset < pending.length; offset += concurrency) {
        final batch = pending.skip(offset).take(concurrency).toList();
        await Future.wait(batch.map((request) async {
          final ok = await _downloadTile(client, request);
          if (ok) downloaded++; else failed++;
          _publish(MapDownloadStatus(
            routeId: route.id, downloaded: downloaded, total: total,
            isDownloading: downloaded < total, isDone: downloaded >= total,
            progress: (downloaded / total).clamp(0.0, 1.0), failed: failed,
          ));
        }));
      }

      final complete = downloaded >= total;
      final error = complete ? null : '$failed tile(s) failed to download; retry while online.';
      final status = MapDownloadStatus(
        routeId: route.id, downloaded: downloaded, total: total,
        isDownloading: false, isDone: complete,
        progress: (downloaded / total).clamp(0.0, 1.0),
        failed: failed, error: error,
      );
      _publish(status);
      await _writeManifest(route, downloaded, failed);
    } finally {
      client.close();
    }
  }

  Future<void> _writeManifest(FlightRoute route, int downloaded, int failed) async {
    final dir = _routeDirectory(route.id);
    await dir.create(recursive: true);
    final manifest = <String, Object>{
      'version': 1,
      'routeId': route.id,
      'originCode': route.originCode,
      'destinationCode': route.destinationCode,
      'downloadedTiles': downloaded,
      'failedTiles': failed,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    };
    await File('${dir.path}${Platform.pathSeparator}manifest.json')
        .writeAsString(jsonEncode(manifest));
  }

  Future<bool> _downloadTile(http.Client client, _TileRequest request) async {
    try {
      final response = await client
          .get(Uri.parse(_tileUrl(request.source.template, request.tile.z, request.tile.x, request.tile.y)),
              headers: AppConfig.tileRequestHeaders)
          .timeout(const Duration(seconds: 12));
      if (response.statusCode < 200 || response.statusCode >= 300 || response.bodyBytes.isEmpty) return false;
      await request.target.parent.create(recursive: true);
      final temp = File('${request.target.path}.part');
      await temp.writeAsBytes(response.bodyBytes, flush: true);
      if (await request.target.exists()) await request.target.delete();
      await temp.rename(request.target.path);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<int> _directorySize(Directory directory) async {
    var total = 0;
    await for (final entity in directory.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        try { total += await entity.length(); } catch (_) {}
      }
    }
    return total;
  }

  List<_TileCoordinate> _buildCorridorTiles(FlightRoute route) {
    final coordinates = <_TileCoordinate>{};
    final waypoints = route.waypoints;
    if (waypoints.isEmpty) return const [];
    for (int i = 0; i < waypoints.length - 1; i++) {
      final start = waypoints[i];
      final end = waypoints[i + 1];
      final distance = GeoPoint.distanceKm(start, end);
      final steps = math.max(1, (distance / 80).ceil());
      for (int step = 0; step <= steps; step++) {
        final t = step / steps;
        final lat = start.latitude + (end.latitude - start.latitude) * t;
        final lon = start.longitude + (end.longitude - start.longitude) * t;
        for (int zoom = AppConfig.offlineMinZoom; zoom <= AppConfig.offlineMaxZoom; zoom++) {
          final tile = _latLonToTile(lat, lon, zoom);
          final max = 1 << zoom;
          for (int dx = -1; dx <= 1; dx++) {
            for (int dy = -1; dy <= 1; dy++) {
              final wrappedX = (tile.x + dx) % max;
              final normalizedX = wrappedX < 0 ? wrappedX + max : wrappedX;
              final y = tile.y + dy;
              if (y >= 0 && y < max) coordinates.add(_TileCoordinate(zoom, normalizedX, y));
            }
          }
        }
      }
    }
    return coordinates.toList()..sort((a, b) {
      final z = a.z.compareTo(b.z);
      if (z != 0) return z;
      final x = a.x.compareTo(b.x);
      return x != 0 ? x : a.y.compareTo(b.y);
    });
  }

  _TileCoordinate _latLonToTile(double lat, double lon, int zoom) {
    final safeLat = lat.clamp(-85.05112878, 85.05112878);
    final n = 1 << zoom;
    final x = ((lon + 180) / 360 * n).floor().clamp(0, n - 1);
    final latRad = safeLat * math.pi / 180;
    final mercator = math.log(math.tan(latRad) + (1 / math.cos(latRad))) / math.pi;
    final y = ((1 - mercator) / 2 * n).floor().clamp(0, n - 1);
    return _TileCoordinate(zoom, x, y);
  }

  Directory _routeDirectory(String routeId) {
    final root = _rootDirectory;
    if (root == null) throw StateError('TileCacheService.initialize() must be called first.');
    return Directory('${root.path}${Platform.pathSeparator}${_safeRouteId(routeId)}');
  }

  File _tileFile(String routeId, String layer, int z, int x, int y) {
    final dir = _routeDirectory(routeId);
    return File('${dir.path}${Platform.pathSeparator}$layer${Platform.pathSeparator}$z${Platform.pathSeparator}$x${Platform.pathSeparator}$y.png');
  }

  String routeDirectoryPath(String routeId) => _routeDirectory(routeId).path;

  String tilePath(String routeId, String layer, int z, int x, int y) =>
      _tileFile(routeId, layer, z, x, y).path;

  String tileUrl(String template, int z, int x, int y) =>
      template.replaceAll('{z}', '$z').replaceAll('{x}', '$x').replaceAll('{y}', '$y');

  String _safeRouteId(String value) => value.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');

  void _publish(MapDownloadStatus status) {
    _statuses[status.routeId] = status;
    _controllers[status.routeId]?.add(status);
  }
}

class _TileSource {
  const _TileSource({required this.layerName, required this.template});
  final String layerName;
  final String template;
}

class _TileRequest {
  const _TileRequest({required this.source, required this.tile, required this.target});
  final _TileSource source;
  final _TileCoordinate tile;
  final File target;
}

class _TileCoordinate {
  const _TileCoordinate(this.z, this.x, this.y);
  final int z;
  final int x;
  final int y;
  @override bool operator ==(Object other) => other is _TileCoordinate && other.z == z && other.x == x && other.y == y;
  @override int get hashCode => Object.hash(z, x, y);
}
