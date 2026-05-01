/// Offline map tile caching strategy.
///
/// Flutter Map supports tile caching via flutter_map_tile_caching package.
///
/// Implementation:
/// 1. Add dependency: flutter_map_tile_caching: ^9.0.0
/// 2. Initialize store on app start
/// 3. Use CachedTileProvider instead of NetworkTileProvider
///
/// Example:
/// ```dart
/// import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
///
/// // In main():
/// await FMTCObjectBoxBackend().initialise();
/// final store = FMTCStore('airwatch_tiles');
/// await store.manage.create();
///
/// // In map:
/// TileLayer(
///   urlTemplate: '...',
///   tileProvider: store.getTileProvider(),
/// )
/// ```
///
/// Cache management:
/// - Auto-cache viewed tiles
/// - Pre-download regions (e.g., user's area)
/// - Set max cache size (e.g., 500MB)
/// - Clear old tiles after 30 days
class OfflineTileConfig {
  static const String storeName = 'airwatch_tiles';
  static const int maxCacheSizeMB = 500;
  static const Duration maxTileAge = Duration(days: 30);

  /// Pre-download tiles for a specific region
  /// This would be called when user taps "Download for offline"
  static Future<void> downloadRegion({
    required double south,
    required double north,
    required double west,
    required double east,
    required int minZoom,
    required int maxZoom,
  }) async {
    // Implementation with flutter_map_tile_caching:
    // final region = RectangleRegion(
    //   LatLngBounds(LatLng(south, west), LatLng(north, east)),
    // );
    // final store = FMTCStore(storeName);
    // await store.download.startForeground(
    //   region: region.toDownloadable(
    //     minZoom: minZoom,
    //     maxZoom: maxZoom,
    //     options: TileLayer(urlTemplate: AppConfig.darkTileUrl),
    //   ),
    // );
  }
}
