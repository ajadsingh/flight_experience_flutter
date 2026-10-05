import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/flight_state.dart';
import '../../shared/widgets/stat_chip.dart';
import 'flight_controller.dart';
import 'widgets/flight_map.dart';
import 'widgets/nearby_panel.dart';

class FlightScreen extends ConsumerStatefulWidget {
  const FlightScreen({super.key});

  @override
  ConsumerState<FlightScreen> createState() => _FlightScreenState();
}

class _FlightScreenState extends ConsumerState<FlightScreen> {
  final MapController _mapController = MapController();
  bool _followAircraft = true;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(flightControllerProvider);
    final controller = ref.read(flightControllerProvider.notifier);
    final isSatellite = state.mapLayer == MapLayer.satellite;

    return Scaffold(
      appBar: AppBar(
        title: Text('${state.route.originCode} → ${state.route.destinationCode}'),
        actions: [
          // Offline indicator badge
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: state.isMapOfflineReady
                  ? Colors.green.shade100
                  : Colors.orange.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  state.isMapOfflineReady
                      ? Icons.offline_pin
                      : Icons.cloud_download,
                  size: 14,
                  color: state.isMapOfflineReady
                      ? Colors.green.shade800
                      : Colors.orange.shade800,
                ),
                const SizedBox(width: 4),
                Text(
                  state.isMapOfflineReady
                      ? 'Offline Ready'
                      : '${(state.mapDownloadProgress * 100).round()}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: state.isMapOfflineReady
                        ? Colors.green.shade900
                        : Colors.orange.shade900,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: state.offlineOnly
                ? 'Offline Only is on'
                : 'Enable Offline Only',
            onPressed: state.isMapOfflineReady
                ? controller.toggleOfflineOnly
                : null,
            icon: Icon(
              state.offlineOnly
                  ? Icons.wifi_off
                  : Icons.wifi,
              color: state.offlineOnly
                  ? Colors.green.shade700
                  : null,
            ),
          ),
          if (state.mode == FlightMode.gps)
            Padding(
              padding: const EdgeInsets.only(right: 12, left: 4),
              child: Icon(
                state.gpsAvailable ? Icons.gps_fixed : Icons.gps_off,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Column(
              children: [
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    StatChip(label: 'Altitude', value: '${state.altitudeFt.round()} ft'),
                    StatChip(label: 'Speed', value: '${state.speedKmh.round()} km/h'),
                    StatChip(label: 'Heading', value: '${state.heading.round()}°'),
                    StatChip(
                      label: 'Elapsed',
                      value: '${state.elapsed.inMinutes}m ${state.elapsed.inSeconds.remainder(60)}s',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _ReliabilityRow(state: state),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: FlightMap(
                    state: state,
                    mapController: _mapController,
                    followAircraft: _followAircraft,
                    onUserGesture: () {
                      if (_followAircraft && mounted) {
                        setState(() => _followAircraft = false);
                      }
                    },
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 11, 14, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.flight_takeoff, size: 20),
                              const SizedBox(width: 7),
                              Text(
                                state.route.flightNumber,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const Spacer(),
                              Text('${(state.progress * 100).round()}%'),
                            ],
                          ),
                          const SizedBox(height: 7),
                          LinearProgressIndicator(value: state.progress),
                          const SizedBox(height: 7),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  state.message,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                              Text(
                                isSatellite ? '🛰️ Satellite' : '🗺️ Map',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 122,
                  right: 12,
                  child: Column(
                    children: [
                      FloatingActionButton.small(
                        heroTag: 'follow',
                        tooltip: _followAircraft
                            ? 'Following aircraft'
                            : 'Follow aircraft',
                        onPressed: state.currentPosition == null
                            ? null
                            : () {
                                setState(() => _followAircraft = true);
                                final point = state.currentPosition!.toLatLng();
                                _mapController.move(point, _zoomForAltitude(state.altitudeFt));
                              },
                        child: Icon(
                          _followAircraft
                              ? Icons.navigation
                              : Icons.my_location,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton.small(
                        heroTag: 'recenter',
                        tooltip: 'Recenter on aircraft',
                        onPressed: () {
                          final point = (state.currentPosition ?? state.route.start).toLatLng();
                          _mapController.move(point, _zoomForAltitude(state.altitudeFt));
                        },
                        child: const Icon(Icons.center_focus_strong),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton.small(
                        heroTag: 'layer',
                        tooltip: isSatellite
                            ? 'Switch to Street Map'
                            : 'Switch to Satellite View',
                        onPressed: state.satelliteAvailable
                            ? controller.toggleMapLayer
                            : null,
                        child: Icon(
                          isSatellite ? Icons.map_outlined : Icons.satellite_alt,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: NearbyPanel(
                    items: state.nearby,
                    below: state.belowPoi,
                    ahead: state.aheadPoi,
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: FilledButton.icon(
                onPressed: state.started
                    ? controller.stop
                    : () async {
                        final ok = await controller.start();
                        if (!ok && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please enable device location permission and service.',
                              ),
                            ),
                          );
                        }
                      },
                icon: Icon(state.started ? Icons.stop : Icons.play_arrow),
                label: Text(state.started ? 'End & Save Flight' : 'Start Flight'),
              ),
            ),
          ),
        ],
      ),
    );

  double _zoomForAltitude(double altitudeFt) {
    const minZoom = 5.5;
    const maxZoom = 10.0;
    final fraction = (altitudeFt / 40000).clamp(0.0, 1.0);
    return maxZoom - fraction * (maxZoom - minZoom);
  }
}

class _ReliabilityRow extends StatelessWidget {
  const _ReliabilityRow({required this.state});

  final FlightState state;

  @override
  Widget build(BuildContext context) {
    final qualityText = switch (state.gpsQuality) {
      GpsQuality.good => 'GPS good',
      GpsQuality.fair => 'GPS fair',
      GpsQuality.poor => 'GPS weak',
      GpsQuality.rejected => 'GPS rejected',
      GpsQuality.unknown => 'GPS waiting',
    };
    final qualityIcon = switch (state.gpsQuality) {
      GpsQuality.good => Icons.gps_fixed,
      GpsQuality.fair => Icons.gps_fixed,
      GpsQuality.poor => Icons.gps_not_fixed,
      GpsQuality.rejected => Icons.gps_off,
      GpsQuality.unknown => Icons.gps_off,
    };
    final qualityColor = switch (state.gpsQuality) {
      GpsQuality.good => Colors.green,
      GpsQuality.fair => Colors.orange,
      GpsQuality.poor => Colors.deepOrange,
      GpsQuality.rejected => Colors.red,
      GpsQuality.unknown => Theme.of(context).colorScheme.outline,
    };

    final routeValue = state.mode == FlightMode.gps
        ? state.routeDeviationKm.toStringAsFixed(0) +
            ' km · ' +
            (state.routeConfidence * 100).round().toString() +
            '%'
        : 'Demo';

    return Row(
      children: [
        Expanded(
          child: _InfoPill(
            icon: qualityIcon,
            label: qualityText,
            value: state.mode == FlightMode.gps && state.gpsAccuracyMeters > 0
                ? '±' + state.gpsAccuracyMeters.round().toString() + ' m'
                : '—',
            color: qualityColor,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _InfoPill(
            icon: state.routeDeviationKm <= 5
                ? Icons.route
                : Icons.warning_amber_rounded,
            label: 'Route',
            value: routeValue,
            color: state.mode == FlightMode.gps && state.routeDeviationKm > 40
                ? Colors.red
                : Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      ),
    );
  }

}