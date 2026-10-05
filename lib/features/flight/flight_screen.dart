import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/flight_state.dart';
import '../../core/models/poi.dart';
import '../../core/models/gps_status.dart';
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
  final _mapKey = GlobalKey<FlightMapState>();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(flightControllerProvider);
    final controller = ref.read(flightControllerProvider.notifier);
    final isSatellite = state.mapLayer == MapLayer.satellite;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          state.route.originCode + ' → ' + state.route.destinationCode,
        ),
        actions: [
          _StatusBadge(
            icon: state.isMapOfflineReady
                ? Icons.offline_pin
                : Icons.download_outlined,
            label: state.isMapOfflineReady
                ? 'Offline'
                : ((state.mapDownloadProgress * 100).round()).toString() + '%',
            positive: state.isMapOfflineReady,
          ),
          if (state.mode == FlightMode.gps)
            Padding(
              padding: const EdgeInsets.only(right: 12, left: 6),
              child: Icon(
                state.gpsAvailable
                    ? Icons.gps_fixed
                    : Icons.gps_not_fixed,
                color: state.gpsAvailable
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.error,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StatChip(
                  label: 'Altitude',
                  value: state.altitudeFt.round().toString() + ' ft',
                ),
                StatChip(
                  label: 'Speed',
                  value: state.speedKmh.round().toString() + ' km/h',
                ),
                StatChip(
                  label: 'Heading',
                  value: state.heading.round().toString() + '°',
                ),
                if (state.mode == FlightMode.gps)
                  StatChip(
                    label: 'GPS',
                    value: state.gpsAccuracyM > 0
                        ? '±' + state.gpsAccuracyM.round().toString() + ' m'
                        : state.gpsQuality.label,
                  ),
                if (state.mode == FlightMode.gps)
                  StatChip(
                    label: 'Route',
                    value: state.routeDeviationKm.isFinite
                        ? state.routeDeviationKm.toStringAsFixed(1) + ' km off'
                        : 'No route',
                  ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: FlightMap(
                    key: _mapKey,
                    state: state,
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
                              Text(
                                ((state.progress * 100).round()).toString() +
                                    '%',
                              ),
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
                                isSatellite ? 'Satellite' : 'Offline map',
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
                  top: 132,
                  right: 12,
                  child: Column(
                    children: [
                      FloatingActionButton.small(
                        heroTag: 'recenter',
                        tooltip: 'Recenter on aircraft',
                        onPressed: _mapKey.currentState?.recenter,
                        child: const Icon(Icons.my_location),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton.small(
                        heroTag: 'follow',
                        tooltip: 'Toggle follow aircraft',
                        onPressed: _mapKey.currentState?.toggleFollowAircraft,
                        child: Icon(
                          _mapKey.currentState?.isFollowingAircraft == true
                              ? Icons.gps_fixed
                              : Icons.gps_off,
                        ),
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
                          isSatellite
                              ? Icons.map_outlined
                              : Icons.satellite_alt,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (state.below != null || state.ahead != null)
                        _FlightInsights(
                          below: state.below,
                          ahead: state.ahead,
                        ),
                      if (state.below != null || state.ahead != null)
                        const SizedBox(height: 8),
                      NearbyPanel(items: state.nearby),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Column(
                children: [
                  if (state.mode == FlightMode.gps &&
                      state.isMockLocation)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        'Mock location detected — useful for testing only.',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.error,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  FilledButton.icon(
                    onPressed: state.started
                        ? () => controller.finish()
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
                    icon: Icon(
                      state.started
                          ? Icons.flag_circle_outlined
                          : Icons.play_arrow_rounded,
                    ),
                    label: Text(
                      state.started ? 'Finish Flight' : 'Start Tracking',
                    ),
                  ),
                  if (!state.started && state.message == 'Flight finished')
                    const SizedBox(height: 4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.icon,
    required this.label,
    required this.positive,
  });

  final IconData icon;
  final String label;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: positive
            ? Colors.green.withValues(alpha: 0.12)
            : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: positive ? Colors.green.shade700 : null,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: positive ? Colors.green.shade800 : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _FlightInsights extends StatelessWidget {
  const _FlightInsights({
    required this.below,
    required this.ahead,
  });

  final NearbyPoi? below;
  final NearbyPoi? ahead;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (below != null)
          Expanded(
            child: _InsightCard(
              icon: Icons.vertical_align_bottom,
              title: 'Below',
              name: below.poi.name,
              detail: below.distanceKm.toStringAsFixed(0) + ' km',
            ),
          ),
        if (below != null && ahead != null) const SizedBox(width: 8),
        if (ahead != null)
          Expanded(
            child: _InsightCard(
              icon: Icons.trending_flat,
              title: 'Ahead',
              name: ahead.poi.name,
              detail: ahead.distanceKm.toStringAsFixed(0) + ' km',
            ),
          ),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.icon,
    required this.title,
    required this.name,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String name;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            Text(
              detail,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}
