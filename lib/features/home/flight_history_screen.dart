import 'package:flutter/material.dart';

import '../../core/models/flight_history_item.dart';
import '../../core/services/flight_history_service.dart';
import '../flight/flight_replay_screen.dart';

class FlightHistoryScreen extends StatefulWidget {
  const FlightHistoryScreen({super.key});

  @override
  State<FlightHistoryScreen> createState() => _FlightHistoryScreenState();
}

class _FlightHistoryScreenState extends State<FlightHistoryScreen> {
  late Future<List<FlightHistoryItem>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    _historyFuture = FlightHistoryService.instance.load();
  }

  Future<void> _delete(FlightHistoryItem item) async {
    await FlightHistoryService.instance.delete(item.id);
    if (!mounted) return;
    setState(_refresh);
  }

  Future<void> _clearAll() async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear flight history?'),
        content: const Text(
          'This removes all saved flights from this device. Your offline map packs are not affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
    if (shouldClear != true) return;
    await FlightHistoryService.instance.clear();
    if (!mounted) return;
    setState(_refresh);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flight History'),
        actions: [
          FutureBuilder<List<FlightHistoryItem>>(
            future: _historyFuture,
            builder: (context, snapshot) => snapshot.data?.isNotEmpty == true
                ? IconButton(
                    tooltip: 'Clear history',
                    onPressed: _clearAll,
                    icon: const Icon(Icons.delete_sweep_outlined),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      body: FutureBuilder<List<FlightHistoryItem>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? const <FlightHistoryItem>[];
          if (items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.history, size: 56),
                    SizedBox(height: 12),
                    Text(
                      'No flights saved yet',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Complete a Demo Flight or GPS flight and it will appear here.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(14),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              final date = MaterialLocalizations.of(context)
                  .formatMediumDate(item.startedAt.toLocal());
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            child: Icon(
                              item.mode == 'demo' ? Icons.slideshow : Icons.gps_fixed,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${item.route.originCode} → ${item.route.destinationCode}',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  '${item.route.flightNumber} · $date',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Delete flight',
                            onPressed: () => _delete(item),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _HistoryStat(icon: Icons.schedule, text: item.durationLabel),
                          _HistoryStat(icon: Icons.route, text: '${item.distanceKm.toStringAsFixed(0)} km'),
                          _HistoryStat(icon: Icons.terrain, text: '${item.maxAltitudeFt.round()} ft'),
                          _HistoryStat(icon: Icons.speed, text: '${item.maxSpeedKmh.round()} km/h'),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.tonalIcon(
                          onPressed: item.track.length < 2
                              ? null
                              : () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => FlightReplayScreen(item: item),
                                    ),
                                  ),
                          icon: const Icon(Icons.play_circle_outline),
                          label: const Text('Replay'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _HistoryStat extends StatelessWidget {
  const _HistoryStat({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(text),
      visualDensity: VisualDensity.compact,
    );
  }
}
