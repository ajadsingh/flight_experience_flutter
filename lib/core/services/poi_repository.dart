import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/geo_point.dart';
import '../models/poi.dart';

class PoiRepository {
  const PoiRepository();

  Future<List<Poi>> load() async {
    try {
      final raw = await rootBundle.loadString('assets/data/pois.json');
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map((item) {
            try {
              return Poi(
                name: item['name'] as String,
                type: item['type'] as String,
                position: GeoPoint(
                  (item['lat'] as num).toDouble(),
                  (item['lon'] as num).toDouble(),
                ),
                description: item['description'] as String,
                importance: (item['importance'] as num?)?.toInt() ?? 0,
              );
            } catch (e) {
              debugPrint('PoiRepository: skipping malformed entry $item — $e');
              return null;
            }
          })
          .whereType<Poi>()
          .toList(growable: false);
    } catch (e, st) {
      debugPrint('PoiRepository: failed to load pois.json — $e\n$st');
      return const [];
    }
  }
}
