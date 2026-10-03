import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/flight_route.dart';
import '../../core/models/flight_state.dart';
import '../flight/flight_controller.dart';
import '../flight/flight_routes.dart';
import '../flight/flight_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(flightControllerProvider.notifier);
    final state = ref.watch(flightControllerProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Flight Experience')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Text(
                'Turn your flight into an interactive journey.',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'High-resolution satellite view, GPS tracking, and offline landmarks — even in Airplane Mode.',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),

              // Mode selector
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose experience',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<FlightMode>(
                        segments: const [
                          ButtonSegment(
                            value: FlightMode.demo,
                            label: Text('Demo Flight'),
                            icon: Icon(Icons.flight_takeoff),
                          ),
                          ButtonSegment(
                            value: FlightMode.gps,
                            label: Text('Use GPS'),
                            icon: Icon(Icons.gps_fixed),
                          ),
                        ],
                        selected: {state.mode},
                        onSelectionChanged: (selection) =>
                            controller.selectMode(selection.first),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Route selector card with auto-download indicator
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Select route',
                            style: theme.textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Auto-Cache Map',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...demoRoutes.map(
                        (route) => _RouteOption(
                          route: route,
                          isSelected: state.route.id == route.id,
                          isOfflineReady: state.route.id == route.id &&
                              state.isMapOfflineReady,
                          isDownloading: state.route.id == route.id &&
                              state.isMapDownloading,
                          downloadProgress: state.route.id == route.id
                              ? state.mapDownloadProgress
                              : 0.0,
                          onTap: () => controller.selectRoute(route),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Offline Map Status Card
              _OfflineMapStatusCard(
                state: state,
                onRetry: controller.cacheCurrentRoute,
              ),
              const SizedBox(height: 16),

              // Features card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Included in this MVP',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      const _Feature(
                        icon: Icons.satellite_alt,
                        text: 'High-res satellite & terrain view with auto-caching',
                      ),
                      const _Feature(
                        icon: Icons.flight,
                        text: 'Moving aircraft with live GPS trail or demo simulation',
                      ),
                      const _Feature(
                        icon: Icons.explore_outlined,
                        text: 'Nearby cities, forts, monuments & mountains',
                      ),
                      const _Feature(
                        icon: Icons.wifi_off_rounded,
                        text: '100% offline capability in Airplane Mode inside the cabin',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              FilledButton.icon(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const FlightScreen()),
                  );
                  controller.stop();
                },
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text('Start Flight Experience'),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                state.isMapOfflineReady
                    ? '🟢 Offline Map Ready — All satellite & street tiles cached for this route.'
                    : '📥 Downloading map tiles in background for offline in-flight use...',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: state.isMapOfflineReady
                      ? Colors.green.shade700
                      : colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OfflineMapStatusCard extends StatelessWidget {
  const _OfflineMapStatusCard({
    required this.state,
    required this.onRetry,
  });

  final FlightState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDone = state.isMapOfflineReady;
    final isDownloading = state.isMapDownloading;

    return Card(
      color: isDone
          ? Colors.green.shade50
          : (isDownloading ? Colors.blue.shade50 : null),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isDone
                      ? Icons.check_circle_rounded
                      : (isDownloading
                          ? Icons.cloud_download_rounded
                          : Icons.offline_bolt_rounded),
                  color: isDone
                      ? Colors.green.shade700
                      : (isDownloading ? Colors.blue.shade700 : Colors.grey),
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isDone
                        ? 'Offline Map Ready (Satellite & Street)'
                        : (isDownloading
                            ? 'Downloading Offline Corridor Map...'
                            : 'Offline Map Cache'),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDone
                          ? Colors.green.shade900
                          : (isDownloading ? Colors.blue.shade900 : null),
                    ),
                  ),
                ),
                if (!isDownloading && !isDone)
                  TextButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Download'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (isDownloading) ...[
              LinearProgressIndicator(
                value: state.mapDownloadProgress > 0
                    ? state.mapDownloadProgress
                    : null,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${state.route.originCode} → ${state.route.destinationCode} Corridor',
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(
                    '${(state.mapDownloadProgress * 100).round()}%',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ] else if (isDone) ...[
              Text(
                'High-resolution satellite view is cached on this device. You can safely switch to Airplane Mode on your flight.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.green.shade800,
                ),
              ),
            ] else ...[
              Text(
                'Tap route to auto-cache tiles for offline flight use.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RouteOption extends StatelessWidget {
  const _RouteOption({
    required this.route,
    required this.isSelected,
    required this.isOfflineReady,
    required this.isDownloading,
    required this.downloadProgress,
    required this.onTap,
  });

  final FlightRoute route;
  final bool isSelected;
  final bool isOfflineReady;
  final bool isDownloading;
  final double downloadProgress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: isSelected
                      ? colorScheme.primary
                      : colorScheme.outline.withValues(alpha: 0.2),
                  child: Icon(
                    Icons.flight_takeoff,
                    size: 18,
                    color: isSelected
                        ? colorScheme.onPrimary
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${route.originCode} → ${route.destinationCode}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: isSelected
                                      ? colorScheme.onPrimaryContainer
                                      : null,
                                ),
                          ),
                          const SizedBox(width: 8),
                          if (isSelected && isOfflineReady)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.offline_pin,
                                    size: 12,
                                    color: Colors.green.shade800,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Offline Ready',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      Text(
                        '${route.origin} to ${route.destination} · ${route.flightNumber}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isSelected
                                  ? colorScheme.onPrimaryContainer
                                  : colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, color: colorScheme.primary, size: 20),
              ],
            ),
            if (isSelected && isDownloading) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: downloadProgress > 0 ? downloadProgress : null,
                  minHeight: 3,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 21),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
