import 'dart:convert';
import 'dart:io';

import '../models/flight_route.dart';
import '../models/poi.dart';
import 'flight_route_metrics.dart';
import 'tile_cache_service.dart';
import 'poi_repository.dart';
import '../models/geo_point.dart';

class PoiPackService {
  PoiPackService._();

  static final instance = PoiPackService._();

  Future<List<Poi>> prepareForRoute(FlightRoute route) async {
    await TileCacheService.instance.initialize();
    final all = await const PoiRepository().load();
    final selected = all.where((poi) {
      final metrics = FlightRouteMetrics.calculate(route, poi.position);
      return metrics.deviationKm <= 160;
    }).toList(growable: false);

    final dir = Directory(
      TileCacheService.instance.routeDirectoryPath(route.id),
    );
    await dir.create(recursive: true);
    final file = File('${dir.path}${Platform.pathSeparator}poi_pack.json');
    final payload = selected.map((poi) => <String, Object>{
      'name': poi.name,
      'type': poi.type,
      'lat': poi.position.latitude,
      'lon': poi.position.longitude,
      'description': poi.description,
    }).toList();
    await file.writeAsString(jsonEncode(payload));
    return selected;
  }

  Future<List<Poi>> loadForRoute(FlightRoute route) async {
    try {
      await TileCacheService.instance.initialize();
      final file = File(
        '${TileCacheService.instance.routeDirectoryPath(route.id)}${Platform.pathSeparator}poi_pack.json',
      );
      if (await file.exists()) {
        final decoded = jsonDecode(await file.readAsString());
        if (decoded is List) {
          return _decode(decoded);
        }
      }
    } catch (_) {}

    // Fall back to the bundled POI dataset when a route pack is not prepared.
    return const PoiRepository().load();
  }

  Future<int> countForRoute(FlightRoute route) async {
    final pois = await loadForRoute(route);
    return pois.length;
  }

  List<Poi> _decode(List<dynamic> rows) {
    final result = <Poi>[];
    for (final row in rows) {
      if (row is! Map) continue;
      try {
        result.add(
          Poi(
            name: row['name'] as String,
            type: row['type'] as String,
            position: GeoPoint(
              (row['lat'] as num).toDouble(),
              (row['lon'] as num).toDouble(),
            ),
            description: row['description'] as String,
          ),
        );
      } catch (_) {}
    }
    return result;
  }
}
