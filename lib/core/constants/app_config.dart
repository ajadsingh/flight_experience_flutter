class AppConfig {
  static const appName = 'Flight Experience';
  static const defaultTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const userAgent = 'FlightExperience/0.1';

  // Default to free high-res Esri World Imagery for realistic satellite simulation
  static const defaultSatelliteTileUrl =
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';

  static const satelliteTileUrl = String.fromEnvironment(
    'SATELLITE_TILE_URL',
    defaultValue: defaultSatelliteTileUrl,
  );
}
