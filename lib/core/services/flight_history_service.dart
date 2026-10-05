import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/flight_history_item.dart';

class FlightHistoryService {
  FlightHistoryService._();

  static final instance = FlightHistoryService._();
  static const _fileName = 'flight_history.json';

  List<FlightHistoryItem>? _memory;
  Future<void>? _writeFuture;

  Future<File> _file() async {
    final root = await getApplicationSupportDirectory();
    final directory = Directory('${root.path}${Platform.pathSeparator}flight_experience_history');
    await directory.create(recursive: true);
    return File('${directory.path}${Platform.pathSeparator}$_fileName');
  }

  Future<List<FlightHistoryItem>> load() async {
    final cached = _memory;
    if (cached != null) return List.unmodifiable(cached);
    try {
      final file = await _file();
      if (!await file.exists()) {
        _memory = [];
        return const [];
      }
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! List) {
        _memory = [];
        return const [];
      }
      final result = <FlightHistoryItem>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        try {
          result.add(FlightHistoryItem.fromJson(Map<String, dynamic>.from(item)));
        } catch (_) {}
      }
      result.sort((a, b) => b.startedAt.compareTo(a.startedAt));
      _memory = result;
      return List.unmodifiable(result);
    } catch (_) {
      _memory = [];
      return const [];
    }
  }

  Future<void> save(FlightHistoryItem item) async {
    final existing = List<FlightHistoryItem>.from(await load());
    existing.removeWhere((old) => old.id == item.id);
    existing.insert(0, item);
    while (existing.length > 30) existing.removeLast();
    _memory = existing;
    _writeFuture = _persist(existing);
    await _writeFuture;
  }

  Future<void> delete(String id) async {
    final existing = List<FlightHistoryItem>.from(await load())
      ..removeWhere((item) => item.id == id);
    _memory = existing;
    _writeFuture = _persist(existing);
    await _writeFuture;
  }

  Future<void> clear() async {
    _memory = [];
    _writeFuture = _persist(const []);
    await _writeFuture;
  }

  Future<void> _persist(List<FlightHistoryItem> items) async {
    final file = await _file();
    final temp = File('${file.path}.part');
    await temp.writeAsString(
      jsonEncode(items.map((item) => item.toJson()).toList(growable: false)),
      flush: true,
    );
    if (await file.exists()) await file.delete();
    await temp.rename(file.path);
  }
}
