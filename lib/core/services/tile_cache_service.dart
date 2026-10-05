import 'dart:async';
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
      if (identical(_active[route.id], future)) {
        _active.remove(route.id);
      }
    }
  }

  Future<void> _cacheRouteInternal(FlightRoute route) async {
    final tiles = _buildCorridorTiles(route);
    final sources = <_TileSource>[
      _TileSource(
        layerName: 'street',
        template: AppConfig.defaultTileUrl,
      ),
      if (AppConfig.satelliteTileUrl.isNotEmpty)
        _TileSource(
          layerName: 'satellite',
          template: AppConfig.satelliteTileUrl,
        ),
    ];

    final total = tiles.length * sources.length;
    if (total > AppConfig.maxOfflineTiles) {
      _publish(
        MapDownloadStatus(
          routeId: route.id,
          downloaded: 0,
          total: total,
          isDownloading: false,
          isDone: false,
          progress: 0,
          error: 'Offline map is too large for the learning cache limit.',
        ),
      );
      return;
    }

    if (total == 0) {
      _publish(
        MapDownloadStatus(
          routeId: route.id,
          downloaded: 0,
          total: 0,
          isDownloading: false,
          isDone: true,
          progress: 1,
        ),
      );
      return;
    }

    final client = http.Client();
    try {
      int downloaded = 0;
      int failed = 0;
      _publish(
        MapDownloadStatus(
          routeId: route.id,
          downloaded: 0,
          total: total,
          isDownloading: true,
          isDone: false,
          progress: 0,
          failed: 0,
        ),
      );

      final pending = <_TileRequest>[];
      for (final source in sources) {
        for (final tile in tiles) {
          final target = _tileFile(source.layerName, tile.z, tile.x, tile.y);
          if (await target.exists() && await target.length() > 0) {
            downloaded++;
            continue;
          }
          pending.add(
            _TileRequest(
              source: source,
              tile: tile,
              target: target,
            ),
          );
        }
      }

      _publish(
        MapDownloadStatus(
          routeId: route.id,
          downloaded: downloaded,
          total: total,
          isDownloading: pending.isNotEmpty,
          isDone: pending.isEmpty,
          progress: downloaded / total,
          failed: failed,
        ),
      );

      const concurrency = 6;
      for (int offset = 0; offset < pending.length; offset += concurrency) {
        final batch = pending.skip(offset).take(concurrency).toList();
        await Future.wait(
          batch.map(
            (request) async {
              final ok = await _downloadTile(client, request);
              if (ok) {
                downloaded++;
              } else {
                failed++;
              }
              _publish(
                MapDownloadStatus(
                  routeId: route.id,
                  downloaded: downloaded,
                  total: total,
                  isDownloading: downloaded < total,
                  isDone: downloaded >= total,
                  progress: (downloaded / total).clamp(0.0, 1.0),
                  failed: failed,
                ),
              );
            },
          ),
        );
      }

      final complete = downloaded >= total;
      _publish(
        MapDownloadStatus(
          routeId: route.id,
          downloaded: downloaded,
          total: total,
          isDownloading: false,
          isDone: complete,
          progress: (downloaded / total).clamp(0.0, 1.0),
          failed: failed,
          error: complete ? null : '$failed tile(s) failed to download; retry while online.',
        ),
      );
    } finally {
      client.close();
    }
  }

  Future<bool> _downloadTile(http.Client client, _TileRequest request) async {
    try {
      final response = await client
          .get(
            Uri.parse(
              _tileUrl(
                request.source.template,
                request.tile.z,
                request.tile.x,
                request.tile.y,
              ),
            ),
            headers: AppConfig.tileRequestHeaders,
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return false;
      }

      final bytes = response.bodyBytes;
      if (bytes.isEmpty) return false;

      await request.target.parent.create(recursive: true);
      final temp = File('${request.target.path}.part');
      await temp.writeAsBytes(bytes, flush: true);
      if (await request.target.exists()) {
        await request.target.delete();
      }
      await temp.rename(request.target.path);
      return true;
    } catch (_) {
      return false;
    }
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

        for (
          int zoom = AppConfig.offlineMinZoom;
          zoom <= AppConfig.offlineMaxZoom;
          zoom++
        ) {
          final tile = _latLonToTile(lat, lon, zoom);
          final max = 1 << zoom;
          for (int dx = -1; dx <= 1; dx++) {
            for (int dy = -1; dy <= 1; dy++) {
              final wrappedX = (tile.x + dx) % max;
              final normalizedX = wrappedX < 0 ? wrappedX + max : wrappedX;
              final y = tile.y + dy;
              if (y >= 0 && y < max) {
                coordinates.add(
                  _TileCoordinate(zoom, normalizedX, y),
                );
              }
            }
          }
        }
      }
    }

    if (waypoints.length == 1) {
      final point = waypoints.first;
      for (
        int zoom = AppConfig.offlineMinZoom;
        zoom <= AppConfig.offlineMaxZoom;
        zoom++
      ) {
        final tile = _latLonToTile(point.latitude, point.longitude, zoom);
        final max = 1 << zoom;
        for (int dx = -1; dx <= 1; dx++) {
          for (int dy = -1; dy <= 1; dy++) {
            final wrappedX = (tile.x + dx) % max;
            final normalizedX = wrappedX < 0 ? wrappedX + max : wrappedX;
            final y = tile.y + dy;
            if (y >= 0 && y < max) {
              coordinates.add(_TileCoordinate(zoom, normalizedX, y));
            }
          }
        }
      }
    }

    return coordinates.toList()
      ..sort((a, b) {
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
    final mercator =
        math.log(math.tan(latRad) + (1 / math.cos(latRad))) / math.pi;
    final y = ((1 - mercator) / 2 * n).floor().clamp(0, n - 1);
    return _TileCoordinate(zoom, x, y);
  }

  File _tileFile(String layer, int z, int x, int y) {
    final root = _rootDirectory;
    if (root == null) {
      throw StateError('TileCacheService.initialize() must be called first.');
    }
    return File(
      '${root.path}${Platform.pathSeparator}$layer'
      '${Platform.pathSeparator}$z'
      '${Platform.pathSeparator}$x'
      '${Platform.pathSeparator}$y.png',
    );
  }

  String tilePath(String layer, int z, int x, int y) =>
      _tileFile(layer, z, x, y).path;

  String tileUrl(String template, int z, int x, int y) =>
      _tileUrl(template, z, x, y);

  String _tileUrl(String template, int z, int x, int y) => template
      .replaceAll('{z}', '$z')
      .replaceAll('{x}', '$x')
      .replaceAll('{y}', '$y');

  void _publish(MapDownloadStatus status) {
    _statuses[status.routeId] = status;
    _controllers[status.routeId]?.add(status);
  }
}

class _TileSource {
  const _TileSource({
    required this.layerName,
    required this.template,
  });

  final String layerName;
  final String template;
}

class _TileRequest {
  const _TileRequest({
    required this.source,
    required this.tile,
    required this.target,
  });

  final _TileSource source;
  final _TileCoordinate tile;
  final File target;
}

class _TileCoordinate {
  const _TileCoordinate(this.z, this.x, this.y);

  final int z;
  final int x;
  final int y;

  @override
  bool operator ==(Object other) =>
      other is _TileCoordinate &&
      other.z == z &&
      other.x == x &&
      other.y == y;

  @override
  int get hashCode => Object.hash(z, x, y);
}
