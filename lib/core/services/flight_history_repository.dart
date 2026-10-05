import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/flight_record.dart';

class FlightHistoryRepository {
  static const _storageKey = 'flight_experience.history.v1';
  static const _maxRecords = 30;

  const FlightHistoryRepository();

  Future<List<FlightRecord>> load() async {
    final preferences = await SharedPreferences.getInstance();
    final values = preferences.getStringList(_storageKey) ?? const [];
    final records = <FlightRecord>[];

    for (final value in values) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map<String, dynamic>) {
          records.add(FlightRecord.fromJson(decoded));
        }
      } catch (_) {
        // Keep one bad record from breaking the rest of the history.
      }
    }

    records.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return records;
  }

  Future<void> save(FlightRecord record) async {
    final existing = await load();
    existing.removeWhere((item) => item.id == record.id);
    existing.insert(0, record);

    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _storageKey,
      existing
          .take(_maxRecords)
          .map((item) => jsonEncode(item.toJson()))
          .toList(),
    );
  }

  Future<void> delete(String id) async {
    final existing = await load();
    existing.removeWhere((item) => item.id == id);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _storageKey,
      existing.map((item) => jsonEncode(item.toJson())).toList(),
    );
  }

  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_storageKey);
  }
}
