import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_config.dart';
import '../../../core/models/flight_state.dart';
import '../../../core/services/offline_cached_tile_provider.dart';

class FlightMap extends StatefulWidget {
  const FlightMap({super.key, required this.state});
  final FlightState state;

  @override
  State<FlightMap> createState() => FlightMapState();
}

class FlightMapState extends State<FlightMap> {
  final MapController _mapController = MapController();
  LatLng? _lastCenter;
  OfflineCachedTileProvider? _streetTileProvider;
  OfflineCachedTileProvider? _satelliteTileProvider;
  bool _followAircraft = true;

  @override
  void initState() {
    super.initState();
    _streetTileProvider = OfflineCachedTileProvider(
      routeId: widget.state.route.id,
      layerName: 'street',
      headers: {'User-Agent': AppConfig.userAgent},
    );
    _satelliteTileProvider = OfflineCachedTileProvider(
      routeId: widget.state.route.id,
      layerName: 'satellite',
      headers: {'User-Agent': AppConfig.userAgent},
    );
  }

  @override
  void dispose() {
    _streetTileProvider?.dispose();
    _satelliteTileProvider?.dispose();
    super.dispose();
  }

  bool get isFollowingAircraft => _followAircraft;

  void toggleFollowAircraft() {
    setState(() => _followAircraft = !_followAircraft);
    if (_followAircraft) recenter();
  }

  void recenter() {
    final current = widget.state.currentPosition?.toLatLng() ??
        widget.state.route.start.toLatLng();
    _lastCenter = current;
    _mapController.move(
      current,
      _zoomForAltitude(widget.state.altitudeFt),
    );
  }

  @override
  void didUpdateWidget(covariant FlightMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.state.route.id != widget.state.route.id) {
      _streetTileProvider?.dispose();
      _satelliteTileProvider?.dispose();
      _streetTileProvider = OfflineCachedTileProvider(
        routeId: widget.state.route.id,
        layerName: 'street',
        headers: {'User-Agent': AppConfig.userAgent},
      );
      _satelliteTileProvider = OfflineCachedTileProvider(
        routeId: widget.state.route.id,
        layerName: 'satellite',
        headers: {'User-Agent': AppConfig.userAgent},
      );
      _lastCenter = null;
    }

    final current = widget.state.currentPosition?.toLatLng();
    if (current == null) return;

    final moved = _lastCenter == null ||
        _haversineKm(_lastCenter!, current) > 2.0; // threshold in km
    if (moved && _followAircraft) {
      _lastCenter = current;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _mapController.move(current, _zoomForAltitude(widget.state.altitudeFt));
        }
      });
    }
  }

  double _haversineKm(LatLng a, LatLng b) {
    const earthR = 6371.0088;
    final dLat = _rad(b.latitude - a.latitude);
    final dLon = _rad(b.longitude - a.longitude);
    final lat1 = _rad(a.latitude);
    final lat2 = _rad(b.latitude);
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) * math.cos(lat2) * math.sin(dLon / 2) * math.sin(dLon / 2);
    return earthR * 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
  }

  double _rad(double deg) => deg * math.pi / 180;

  double _zoomForAltitude(double altitudeFt) {
    const minZoom = 5.5;
    const maxZoom = 10.0;
    const maxAlt = 40000.0;
    final fraction = (altitudeFt / maxAlt).clamp(0.0, 1.0);
    return maxZoom - fraction * (maxZoom - minZoom);
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.state.currentPosition?.toLatLng() ??
        widget.state.route.start.toLatLng();
    final planned = widget.state.route.waypoints
        .map((p) => p.toLatLng())
        .toList(growable: false);
    final actual = widget.state.track
        .map((p) => p.toLatLng())
        .toList(growable: false);

    final isSatellite = widget.state.mapLayer == MapLayer.satellite;
    final tileUrl = isSatellite
        ? AppConfig.satelliteTileUrl
        : AppConfig.defaultTileUrl;
    final tileProvider = isSatellite
        ? _satelliteTileProvider
        : _streetTileProvider;

    final primaryColor = Theme.of(context).colorScheme.primary;

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: current,
            initialZoom: 6.2,
            minZoom: 3,
            maxZoom: 13,
          ),
          children: [
            TileLayer(
              urlTemplate: tileUrl,
              userAgentPackageName: AppConfig.userAgent,
              tileProvider: tileProvider!,
              maxNativeZoom: AppConfig.offlineMaxZoom,
            ),
            PolylineLayer(
              polylines: [
                Polyline(
                  points: planned,
                  strokeWidth: 3.5,
                  color: isSatellite
                      ? Colors.amber.withValues(alpha: 0.8)
                      : primaryColor.withValues(alpha: 0.45),
                  pattern: StrokePattern.dotted(),
                ),
                if (actual.length >= 2)
                  Polyline(
                    points: actual,
                    strokeWidth: 5,
                    color: isSatellite ? Colors.amberAccent : primaryColor,
                  ),
              ],
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: current,
                  width: 56,
                  height: 56,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (isSatellite ? Colors.amber : primaryColor)
                              .withValues(alpha: 0.35),
                          blurRadius: 16,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Transform.rotate(
                      angle: widget.state.heading * math.pi / 180,
                      child: Icon(
                        Icons.flight,
                        size: 40,
                        color: isSatellite ? Colors.amberAccent : primaryColor,
                      ),
                    ),
                  ),
                ),
                ...widget.state.nearby.take(5).map(
                      (item) => Marker(
                        point: item.poi.position.toLatLng(),
                        width: 40,
                        height: 40,
                        child: Tooltip(
                          message: item.poi.name,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isSatellite
                                  ? Colors.black87
                                  : Colors.white.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSatellite
                                    ? Colors.amberAccent
                                    : primaryColor,
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              _iconForType(item.poi.type),
                              size: 20,
                              color: isSatellite
                                  ? Colors.amberAccent
                                  : primaryColor,
                            ),
                          ),
                        ),
                      ),
                    ),
              ],
            ),
          ],
        ),

        // Attribution
        Positioned(
          left: 12,
          bottom: 80,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isSatellite
                  ? Colors.black.withValues(alpha: 0.75)
                  : Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                isSatellite
                    ? (AppConfig.satelliteAttribution.isNotEmpty
                        ? '${AppConfig.satelliteAttribution} (Offline Cached)'
                        : 'Satellite imagery provider (Offline Cached)')
                    : '© OpenStreetMap contributors (Offline Cached)',
                style: TextStyle(
                  fontSize: 10,
                  color: isSatellite ? Colors.white70 : null,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  IconData _iconForType(String type) {
    switch (type.toLowerCase()) {
      case 'airport':
        return Icons.flight_land;
      case 'mountain':
        return Icons.terrain;
      case 'landmark':
        return Icons.place;
      default:
        return Icons.location_city;
    }
  }
}
