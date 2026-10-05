import 'package:flutter_test/flutter_test.dart';

import 'package:flight_experience/core/services/tile_cache_service.dart';

void main() {
  group('MapDownloadStatus', () {
    test('stores progress and byte information', () {
      const status = MapDownloadStatus(
        routeId: 'amd-del-demo',
        downloaded: 90,
        total: 100,
        isDownloading: true,
        isDone: false,
        progress: 0.9,
        downloadedBytes: 2700000,
        failedTiles: 2,
        cancelled: false,
      );

      expect(status.routeId, equals('amd-del-demo'));
      expect(status.downloaded, equals(90));
      expect(status.total, equals(100));
      expect(status.progress, closeTo(0.9, 0.0001));
      expect(status.downloadedBytes, equals(2700000));
      expect(status.failedTiles, equals(2));
      expect(status.cancelled, isFalse);
    });
  });

  group('OfflineMapEstimate', () {
    test('stores tile and size estimate', () {
      const estimate = OfflineMapEstimate(
        routeId: 'bom-blr-demo',
        totalTiles: 1200,
        estimatedBytes: 36000000,
      );

      expect(estimate.routeId, equals('bom-blr-demo'));
      expect(estimate.totalTiles, equals(1200));
      expect(estimate.estimatedBytes, equals(36000000));
    });
  });
}
