import 'package:flutter/material.dart';

import '../../core/models/flight_route.dart';
import '../../core/services/tile_cache_service.dart';
import '../flight/flight_routes.dart';

class OfflineMapManagerScreen extends StatelessWidget {
  const OfflineMapManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Offline Maps')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: demoRoutes.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, index) => _OfflineRouteCard(route: demoRoutes[index]),
      ),
    );
  }
}

class _OfflineRouteCard extends StatelessWidget {
  const _OfflineRouteCard({required this.route});

  final FlightRoute route;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MapDownloadStatus>(
      stream: TileCacheService.instance.watchProgress(route.id),
      initialData: TileCacheService.instance.getStatus(route.id),
      builder: (context, snapshot) {
        final status = snapshot.data;
        final downloading = status?.isDownloading ?? false;
        final ready = status?.isDone ?? false;
        final progress = status?.progress ?? 0;
        final failed = status?.failedTiles ?? 0;
        final bytes = status?.downloadedBytes ?? 0;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      child: Icon(
                        ready
                            ? Icons.offline_pin
                            : Icons.flight_takeoff,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            route.originCode +
                                ' → ' +
                                route.destinationCode,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            route.origin +
                                ' to ' +
                                route.destination,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    if (ready)
                      const Chip(
                        avatar: Icon(Icons.check, size: 16),
                        label: Text('Ready'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (downloading) ...[
                  LinearProgressIndicator(value: progress),
                  const SizedBox(height: 6),
                  Text(
                    ((progress * 100).round()).toString() +
                        '%  •  ' +
                        bytesLabel(bytes) +
                        (failed > 0
                            ? '  •  ' + failed.toString() + ' failed'
                            : ''),
                  ),
                  const SizedBox(height: 8),
                ] else if (status != null) ...[
                  Text(
                    status.downloaded.toString() +
                        ' / ' +
                        status.total.toString() +
                        ' tiles  •  ' +
                        bytesLabel(bytes),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                ],
                FutureBuilder<OfflineMapEstimate>(
                  future: TileCacheService.instance.estimateRoute(route),
                  builder: (context, estimateSnapshot) {
                    final estimate = estimateSnapshot.data;
                    if (estimate == null) {
                      return const SizedBox.shrink();
                    }
                    return Text(
                      '~' +
                          estimate.totalTiles.toString() +
                          ' tiles  •  ~' +
                          bytesLabel(estimate.estimatedBytes) +
                          ' download estimate',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (downloading)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              TileCacheService.instance.cancelRoute(route.id),
                          icon: const Icon(Icons.pause),
                          label: const Text('Pause'),
                        ),
                      )
                    else
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () =>
                              TileCacheService.instance.cacheRoute(route),
                          icon: Icon(
                            ready ? Icons.refresh : Icons.download,
                          ),
                          label: Text(ready ? 'Rebuild' : 'Download'),
                        ),
                      ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: status == null && !ready
                          ? null
                          : () => TileCacheService.instance.deleteRoute(
                                route.id,
                              ),
                      child: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

String bytesLabel(int bytes) {
  if (bytes < 1024) return bytes.toString() + ' B';
  if (bytes < 1024 * 1024) {
    return (bytes / 1024).toStringAsFixed(0) + ' KB';
  }
  return (bytes / (1024 * 1024)).toStringAsFixed(1) + ' MB';
}
