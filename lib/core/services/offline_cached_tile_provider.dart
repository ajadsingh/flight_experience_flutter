import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../constants/app_config.dart';
import 'tile_cache_service.dart';

class OfflineCachedTileProvider extends TileProvider {
  OfflineCachedTileProvider({
    required this.routeId,
    required this.layerName,
    required Map<String, String> headers,
  }) : super(headers: headers);

  final String routeId;
  final String layerName;

  @override
  ImageProvider getImage(
    TileCoordinates coordinates,
    TileLayer options,
  ) {
    final cacheFile = File(
      TileCacheService.instance.tilePath(
        routeId,
        layerName,
        coordinates.z,
        coordinates.x,
        coordinates.y,
      ),
    );

    if (!kIsWeb && cacheFile.existsSync()) {
      return FileImage(cacheFile);
    }

    final template = options.urlTemplate ?? AppConfig.defaultTileUrl;

    return NetworkImage(
      TileCacheService.instance.tileUrl(
        template,
        coordinates.z,
        coordinates.x,
        coordinates.y,
      ),
      headers: {
        ...headers,
        ...AppConfig.tileRequestHeaders,
      },
    );
  }
}
