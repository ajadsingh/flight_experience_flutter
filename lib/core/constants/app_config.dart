class AppConfig {
  static const appName = 'Flight Experience';

  static const defaultTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  static const userAgent = 'FlightExperience/0.1';

  // Satellite imagery is opt-in. Provide a licensed provider URL at build time.
  static const satelliteTileUrl = String.fromEnvironment(
    'SATELLITE_TILE_URL',
    defaultValue: '',
  );

  // Required by the selected satellite provider. Keep empty until configured.
  static const satelliteAttribution = String.fromEnvironment(
    'SATELLITE_ATTRIBUTION',
    defaultValue: '',
  );

  static const offlineMinZoom = 6;
  static const offlineMaxZoom = 10;

  static const allowMockGps = String.fromEnvironment(
    'ALLOW_MOCK_GPS',
    defaultValue: 'false',
  ) == 'true';

  static const maxOfflineTiles = 12000;

  static const tileRequestHeaders = <String, String>{
    'User-Agent': userAgent,
    'Accept': 'image/avif,image/webp,image/png,image/*,*/*;q=0.8',
  };
}
