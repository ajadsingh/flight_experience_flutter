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
    required this.downloadedBytes,
    required this.failedTiles,
    required this.cancelled,
  });

  final String routeId;
  final int downloaded;
  final int total;
  final bool isDownloading;
  final bool isDone;
  final double progress;
  final int downloadedBytes;
  final int failedTiles;
  final bool cancelled;
}

class OfflineMapEstimate {
  const OfflineMapEstimate({
    required this.routeId,
    required this.totalTiles,
    required this.estimatedBytes,
  });

  final String routeId;
  final int totalTiles;
  final int estimatedBytes;
}

class TileCacheService {
  TileCacheService._();

  static final TileCacheService instance = TileCacheService._();
  static const _estimatedBytesPerTile = 30000;

  final Map<String, MapDownloadStatus> _statuses = {};
  final Map<String, StreamController<MapDownloadStatus>> _controllers = {};
  final Map<String, Future<void>> _active = {};
  final Set<String> _cancelled = {};
  Directory? _rootDirectory;

  Future<void> initialize() async {
    if (_rootDirectory != null) return;

    final root = await getApplicationSupportDirectory();
    final directory = Directory(
      '\${root.path}\${Platform.pathSeparator}flight_experience_tiles',
    );

    await directory.create(recursive: true);
    _rootDirectory = directory;
  }

  Stream<MapDownloadStatus> watchProgress(String routeId) {
    return (_controllers[routeId] ??=
          StreamController<MapDownloadStatus>.broadcast())
        .stream;
  }

  MapDownloadStatus? getStatus(String routeId) => _statuses[routeId];

  Future<MapDownloadStatus?> restoreStatus(String routeId) async {
    await initialize();

    final manifest = _manifestFile(routeId);
    if (!await manifest.exists()) return null;

    try {
      final decoded = jsonDecode(await manifest.readAsString());
      if (decoded is! Map<String, dynamic>) return null;

      final status = MapDownloadStatus(
        routeId: routeId,
        downloaded: (decoded['downloaded'] as num?)?.toInt() ?? 0,
        total: (decoded['total'] as num?)?.toInt() ?? 0,
        isDownloading: false,
        isDone: decoded['isDone'] == true,
        progress:
            ((decoded['progress'] as num?)?.toDouble() ?? 0).clamp(0.0, 1.0),
        downloadedBytes: (decoded['downloadedBytes'] as num?)?.toInt() ?? 0,
        failedTiles: (decoded['failedTiles'] as num?)?.toInt() ?? 0,
        cancelled: decoded['cancelled'] == true,
      );

      _statuses[routeId] = status;
      return status;
    } catch (_) {
      return null;
    }
  }

  Future<OfflineMapEstimate> estimateRoute(FlightRoute route) async {
    await initialize();

    final tiles = _buildCorridorTiles(route);
    final sourceCount =
        1 + (AppConfig.satelliteTileUrl.isNotEmpty ? 1 : 0);
    final totalTiles = tiles.length * sourceCount;

    return OfflineMapEstimate(
      routeId: route.id,
      totalTiles: totalTiles,
      estimatedBytes: totalTiles * _estimatedBytesPerTile,
    );
  }

  Future<void> cacheRoute(FlightRoute route) async {
    await initialize();

    final active = _active[route.id];
    if (active != null) {
      await active;
      return;
    }

    _cancelled.remove(route.id);
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

  Future<void> cancelRoute(String routeId) async {
    _cancelled.add(routeId);

    final status = _statuses[routeId];
    if (status == null || !status.isDownloading) return;

    final cancelled = MapDownloadStatus(
      routeId: routeId,
      downloaded: status.downloaded,
      total: status.total,
      isDownloading: false,
      isDone: false,
      progress: status.progress,
      downloadedBytes: status.downloadedBytes,
      failedTiles: status.failedTiles,
      cancelled: true,
    );

    _publish(cancelled);
    await _persistStatus(cancelled);
  }

  Future<void> deleteRoute(String routeId) async {
    await initialize();
    await cancelRoute(routeId);

    final directory = Directory(
      '\${_rootDirectory!.path}\${Platform.pathSeparator}$routeId',
    );

    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }

    _statuses.remove(routeId);
    _controllers[routeId]?.add(
      MapDownloadStatus(
        routeId: routeId,
        downloaded: 0,
        total: 0,
        isDownloading: false,
        isDone: false,
        progress: 0,
        downloadedBytes: 0,
        failedTiles: 0,
        cancelled: false,
      ),
    );
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

    if (total == 0) {
      final status = MapDownloadStatus(
        routeId: route.id,
        downloaded: 0,
        total: 0,
        isDownloading: false,
        isDone: true,
        progress: 1,
        downloadedBytes: 0,
        failedTiles: 0,
        cancelled: false,
      );

      _publish(status);
      await _persistStatus(status);
      return;
    }

    final client = http.Client();

    try {
      var downloaded = 0;
      var downloadedBytes = 0;
      var failed = 0;
      final pending = <_TileRequest>[];

      for (final source in sources) {
        for (final tile in tiles) {
          final target = _tileFile(
            route.id,
            source.layerName,
            tile.z,
            tile.x,
            tile.y,
          );

          if (await target.exists()) {
            final bytes = await target.length();
            if (bytes > 0) {
              downloaded++;
              downloadedBytes += bytes;
              continue;
            }
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

      var status = MapDownloadStatus(
        routeId: route.id,
        downloaded: downloaded,
        total: total,
        isDownloading: pending.isNotEmpty,
        isDone: pending.isEmpty,
        progress: downloaded / total,
        downloadedBytes: downloadedBytes,
        failedTiles: 0,
        cancelled: false,
      );

      _publish(status);
      await _persistStatus(status);

      const concurrency = 6;

      for (
        var offset = 0;
        offset < pending.length;
        offset += concurrency
      ) {
        if (_cancelled.contains(route.id)) break;

        final batch = pending.skip(offset).take(concurrency).toList();
        final results = await Future.wait(
          batch.map((request) => _downloadTile(client, request)),
        );

        for (final result in results) {
          if (result.success) {
            downloaded++;
            downloadedBytes += result.bytes;
          } else {
            failed++;
          }
        }

        status = MapDownloadStatus(
          routeId: route.id,
          downloaded: downloaded,
          total: total,
          isDownloading: true,
          isDone: false,
          progress: (downloaded / total).clamp(0.0, 1.0),
          downloadedBytes: downloadedBytes,
          failedTiles: failed,
          cancelled: false,
        );

        _publish(status);
        await _persistStatus(status);
      }

      final cancelled = _cancelled.contains(route.id);
      final complete =
          !cancelled && downloaded >= total && failed == 0;

      status = MapDownloadStatus(
        routeId: route.id,
        downloaded: downloaded,
        total: total,
        isDownloading: false,
        isDone: complete,
        progress: (downloaded / total).clamp(0.0, 1.0),
        downloadedBytes: downloadedBytes,
        failedTiles: failed,
        cancelled: cancelled,
      );

      _publish(status);
      await _persistStatus(status);
    } finally {
      client.close();
      _cancelled.remove(route.id);
    }
  }

  Future<_DownloadResult> _downloadTile(
    http.Client client,
    _TileRequest request,
  ) async {
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
        return const _DownloadResult.failure();
      }

      final bytes = response.bodyBytes;
      if (bytes.isEmpty) return const _DownloadResult.failure();

      await request.target.parent.create(recursive: true);
      final temp = File('\${request.target.path}.part');

      await temp.writeAsBytes(bytes, flush: true);

      if (await request.target.exists()) {
        await request.target.delete();
      }

      await temp.rename(request.target.path);
      return _DownloadResult.success(bytes.length);
    } catch (_) {
      return const _DownloadResult.failure();
    }
  }

  Future<void> _persistStatus(MapDownloadStatus status) async {
    try {
      final manifest = _manifestFile(status.routeId);
      await manifest.parent.create(recursive: true);

      await manifest.writeAsString(
        jsonEncode({
          'downloaded': status.downloaded,
          'total': status.total,
          'isDone': status.isDone,
          'progress': status.progress,
          'downloadedBytes': status.downloadedBytes,
          'failedTiles': status.failedTiles,
          'cancelled': status.cancelled,
        }),
        flush: true,
      );
    } catch (_) {
      // Cached tiles remain usable even if the small manifest cannot persist.
    }
  }

  List<_TileCoordinate> _buildCorridorTiles(FlightRoute route) {
    final coordinates = <_TileCoordinate>{};
    final waypoints = route.waypoints;
    if (waypoints.isEmpty) return const [];

    for (var i = 0; i < waypoints.length - 1; i++) {
      final start = waypoints[i];
      final end = waypoints[i + 1];
      final distance = GeoPoint.distanceKm(start, end);
      final steps = math.max(1, (distance / 80).ceil());

      for (var step = 0; step <= steps; step++) {
        final t = step / steps;
        final lat = start.latitude +
            (end.latitude - start.latitude) * t;
        final lon = start.longitude +
            (end.longitude - start.longitude) * t;

        for (
          var zoom = AppConfig.offlineMinZoom;
          zoom <= AppConfig.offlineMaxZoom;
          zoom++
        ) {
          final tile = _latLonToTile(lat, lon, zoom);
          final max = 1 << zoom;

          for (var dx = -1; dx <= 1; dx++) {
            for (var dy = -1; dy <= 1; dy++) {
              final wrappedX = (tile.x + dx) % max;
              final normalizedX =
                  wrappedX < 0 ? wrappedX + max : wrappedX;
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

    return coordinates.toList()
      ..sort((a, b) {
        final z = a.z.compareTo(b.z);
        if (z != 0) return z;

        final x = a.x.compareTo(b.x);
        return x != 0 ? x : a.y.compareTo(b.y);
      });
  }

  _TileCoordinate _latLonToTile(
    double lat,
    double lon,
    int zoom,
  ) {
    final safeLat = lat.clamp(-85.05112878, 85.05112878);
    final n = 1 << zoom;
    final x = ((lon + 180) / 360 * n)
        .floor()
        .clamp(0, n - 1);
    final latRad = safeLat * math.pi / 180;
    final mercator =
        math.log(math.tan(latRad) + (1 / math.cos(latRad))) /
            math.pi;
    final y = ((1 - mercator) / 2 * n)
        .floor()
        .clamp(0, n - 1);

    return _TileCoordinate(zoom, x, y);
  }

  File _tileFile(
    String routeId,
    String layer,
    int z,
    int x,
    int y,
  ) {
    final root = _rootDirectory;
    if (root == null) {
      throw StateError(
        'TileCacheService.initialize() must be called first.',
      );
    }

    return File(
      '\${root.path}\${Platform.pathSeparator}$routeId'
      '\${Platform.pathSeparator}$layer'
      '\${Platform.pathSeparator}$z'
      '\${Platform.pathSeparator}$x'
      '\${Platform.pathSeparator}$y.png',
    );
  }

  File _manifestFile(String routeId) {
    final root = _rootDirectory;
    if (root == null) {
      throw StateError(
        'TileCacheService.initialize() must be called first.',
      );
    }

    return File(
      '\${root.path}\${Platform.pathSeparator}$routeId'
      '\${Platform.pathSeparator}manifest.json',
    );
  }

  String tilePath(
    String routeId,
    String layer,
    int z,
    int x,
    int y,
  ) =>
      _tileFile(routeId, layer, z, x, y).path;

  String tileUrl(String template, int z, int x, int y) =>
      _tileUrl(template, z, x, y);

  String _tileUrl(String template, int z, int x, int y) =>
      template
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

class _DownloadResult {
  const _DownloadResult.success(this.bytes) : success = true;

  const _DownloadResult.failure()
      : success = false,
        bytes = 0;

  final bool success;
  final int bytes;
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
