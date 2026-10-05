import 'package:flutter/material.dart';

import '../../core/models/flight_record.dart';
import '../../core/services/flight_history_repository.dart';
import 'flight_replay_screen.dart';
import '../../shared/utils/formatters.dart';

class FlightHistoryScreen extends StatefulWidget {
  const FlightHistoryScreen({super.key});

  @override
  State<FlightHistoryScreen> createState() => _FlightHistoryScreenState();
}

class _FlightHistoryScreenState extends State<FlightHistoryScreen> {
  static const _repository = FlightHistoryRepository();
  late Future<List<FlightRecord>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repository.load();
  }

  void _reload() {
    setState(() => _future = _repository.load());
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete flight history?'),
        content: const Text(
          'All locally stored flight history and replay tracks will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await _repository.clear();
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Flights'),
        actions: [
          IconButton(
            tooltip: 'Delete all history',
            onPressed: _clearAll,
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
        ],
      ),
      body: FutureBuilder<List<FlightRecord>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final records = snapshot.data ?? const <FlightRecord>[];
          if (records.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.flight_takeoff_outlined, size: 56),
                    SizedBox(height: 12),
                    Text(
                      'No flights recorded yet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Start a GPS or demo flight and finish it to create a local replay.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: records.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final record = records[index];
                return Card(
                  child: ListTile(
                    isThreeLine: true,
                    leading: CircleAvatar(
                      child: const Icon(Icons.flight),
                    ),
                    title: Text(
                      record.originCode +
                          ' → ' +
                          record.destinationCode,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      dateLabel(record.startedAt) +
                          '  •  ' +
                          durationLabel(record.duration) +
                          '\n' +
                          record.distanceKm.toStringAsFixed(0) +
                          ' km tracked  •  Max ' +
                          record.maxSpeedKmh.toStringAsFixed(0) +
                          ' km/h',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => FlightReplayScreen(record: record),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

