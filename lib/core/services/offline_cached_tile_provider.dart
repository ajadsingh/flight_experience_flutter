import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../constants/app_config.dart';
import 'tile_cache_service.dart';

class OfflineCachedTileProvider extends TileProvider {
  OfflineCachedTileProvider({
    required this.layerName,
    required Map<String, String> headers,
  }) : super(headers: headers);

  final String layerName;

  @override
  ImageProvider getImage(
    TileCoordinates coordinates,
    TileLayer options,
  ) {
    final cacheFile = File(
      TileCacheService.instance.tilePath(
        layerName,
        coordinates.z,
        coordinates.x,
        coordinates.y,
      ),
    );

    if (!kIsWeb && cacheFile.existsSync()) {
      return FileImage(cacheFile);
    }

    return NetworkImage(
      TileCacheService.instance.tileUrl(
        options.urlTemplate,
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
