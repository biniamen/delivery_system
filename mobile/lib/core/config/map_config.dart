abstract final class MapConfig {
  static const googleMapsEnabled = bool.fromEnvironment(
    'GOOGLE_MAPS_ENABLED',
    defaultValue: false,
  );

  static const googleMapId = String.fromEnvironment(
    'GOOGLE_MAPS_MAP_ID',
    defaultValue: 'DEMO_MAP_ID',
  );

  static const tileUrl = String.fromEnvironment(
    'MAP_TILE_URL',
    defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  );
}
