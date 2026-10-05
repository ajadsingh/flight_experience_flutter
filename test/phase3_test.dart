import 'package:flutter_test/flutter_test.dart';
import 'package:flight_experience/core/models/flight_route.dart';
import 'package:flight_experience/core/models/flight_state.dart';
import 'package:flight_experience/core/services/offline_pack_service.dart';
import 'package:flight_experience/core/services/tile_cache_service.dart';

void main() {
  const route = FlightRoute(
    id: 'amd-del-demo',
    flightNumber: 'FX 482',
    origin: 'Ahmedabad',
    originCode: 'AMD',
    destination: 'Delhi',
    destinationCode: 'DEL',
    waypoints: [],
  );

  test('offline pack formatBytes uses readable units', () {
    expect(OfflinePackService.formatBytes(0), '0 B');
    expect(OfflinePackService.formatBytes(1024), '1 KB');
    expect(OfflinePackService.formatBytes(1024 * 1024), '1.0 MB');
    expect(OfflinePackService.formatBytes(1024 * 1024 * 1024), '1.00 GB');
  });

  test('offline pack info exposes progress safely', () {
    const info = OfflinePackInfo(
      routeId: 'route',
      totalTiles: 200,
      downloadedTiles: 150,
      failedTiles: 0,
      storageBytes: 1000,
      poiCount: 20,
      isReady: false,
    );
    expect(info.progress, closeTo(0.75, 0.001));
  });

  test('zero tile pack has zero progress', () {
    const info = OfflinePackInfo(
      routeId: 'route',
      totalTiles: 0,
      downloadedTiles: 0,
      failedTiles: 0,
      storageBytes: 0,
      poiCount: 0,
      isReady: false,
    );
    expect(info.progress, 0);
  });

  test('tile cache estimate stores tile count', () {
    const estimate = TileCacheEstimate(totalTiles: 321);
    expect(estimate.totalTiles, 321);
  });

  test('offline-only state defaults to false', () {
    final state = FlightState.initial(route);
    expect(state.offlineOnly, isFalse);
  });
}
