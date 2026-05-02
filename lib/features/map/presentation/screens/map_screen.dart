import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:airwatch_mobile/core/constants/config.dart';
import 'package:airwatch_mobile/core/constants/ui_constants.dart';
import 'package:airwatch_mobile/core/l10n/ui_text.dart';
import 'package:airwatch_mobile/core/theme/app_colors.dart';
import 'package:airwatch_mobile/features/flight_details/presentation/widgets/flight_details_panel.dart';
import 'package:airwatch_mobile/features/map/data/models/aircraft_state.dart';
import 'package:airwatch_mobile/features/map/presentation/providers/flight_providers.dart';
import 'package:airwatch_mobile/features/map/presentation/providers/interpolation_provider.dart';
import 'package:airwatch_mobile/features/map/presentation/widgets/aircraft_marker.dart';
import 'package:airwatch_mobile/features/map/presentation/widgets/airport_markers.dart';
import 'package:airwatch_mobile/features/map/presentation/widgets/flight_trail.dart';
import 'package:airwatch_mobile/features/map/presentation/widgets/map_controls.dart';
import 'package:airwatch_mobile/features/map/presentation/widgets/map_styles.dart';
import 'package:airwatch_mobile/features/map/presentation/widgets/radar_overlay.dart';
import 'package:airwatch_mobile/features/map/presentation/widgets/squawk_alert_banner.dart';
import 'package:airwatch_mobile/features/map/presentation/widgets/status_overlay.dart';
import 'package:airwatch_mobile/features/map/presentation/widgets/turbulence_overlay.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with TickerProviderStateMixin {
  late MapController _mapController;
  bool _showSearch = false;
  double _currentZoom = AppConfig.defaultZoom;
  final _searchController = TextEditingController();
  Timer? _detectLocationTimer;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _detectLocation();
  }

  /// Detect user location and zoom to nearest major airport.
  /// Fallback: zoom to Europe (centered on Frankfurt area).
  Future<void> _detectLocation() async {
    try {
      _detectLocationTimer = Timer(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        _mapController.move(const LatLng(AppConfig.defaultLat, AppConfig.defaultLon), AppConfig.defaultZoom);
      });
      return;
    } catch (_) {
      if (!mounted) return; // Guard against disposed widget
      _mapController.move(const LatLng(AppConfig.defaultLat, AppConfig.defaultLon), AppConfig.defaultZoom);
    }
  }

  @override
  void dispose() {
    _detectLocationTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aircraft = ref.watch(filteredAircraftProvider);
    final selectedAircraft = ref.watch(selectedAircraftProvider);
    final showTrails = ref.watch(showTrailsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Selected basemap style (persisted in mapStyleProvider). Drives the
    // tile URL + label-color contrast and replaces the older
    // dark/light-theme-based switch. See widgets/map_styles.dart for the
    // catalog.
    final styleId = ref.watch(mapStyleProvider);
    final style = styleDef(styleId);

    // Pan to aircraft when selected from outside the map (search / airport screen)
    ref.listen(mapFocusProvider, (_, trigger) {
      if (trigger != null) {
        _mapController.move(trigger.position, trigger.zoom);
        ref.read(mapFocusProvider.notifier).clear();
      }
    });

    // Voice-driven zoom — the command provider increments / decrements
    // a tick. Each delta moves the camera one zoom step, clamped to
    // the map's allowed range.
    ref.listen<int>(mapZoomCommandProvider, (prev, next) {
      if (prev == null || prev == next) return;
      final delta = next - prev;
      final cur = _mapController.camera.zoom;
      final target = (cur + delta).clamp(AppConfig.minZoom, AppConfig.maxZoom);
      _mapController.move(_mapController.camera.center, target);
    });

    return Scaffold(
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(48.8566, 2.3522),
              initialZoom: AppConfig.defaultZoom,
              minZoom: AppConfig.minZoom,
              maxZoom: AppConfig.maxZoom,
              backgroundColor: isDark
                  ? AppColors.background
                  : UiConstants.lightBackground,
              // Restrict panning to a single world copy with a small
              // dateline buffer. flutter_map has no `worldCopyJump`
              // equivalent (Leaflet teleports the view across the
              // anti-meridian; flutter_map just hits the edge), so the
              // closest match is to constrain the center coordinate.
              // Latitude is clipped at ±85 because Web Mercator can't
              // project the poles cleanly anyway.
              cameraConstraint: CameraConstraint.containCenter(
                bounds: LatLngBounds(
                  const LatLng(-85, -180),
                  const LatLng(85, 180),
                ),
              ),
              // Slower scroll-wheel zoom for desktop / web builds — the
              // default 0.005 is jittery on high-DPI mice. Mirrors the
              // web's `wheelDebounceTime: 100` / `wheelPxPerZoomLevel: 80`
              // tuning, just expressed as flutter_map's velocity number.
              interactionOptions: const InteractionOptions(
                scrollWheelVelocity: 0.003,
              ),
              onTap: (tapPosition, point) {
                ref.read(selectedAircraftProvider.notifier).set(null);
                ref.read(isTrackingFlightProvider.notifier).set(false);
                setState(() => _showSearch = false);
              },
              onPositionChanged: (position, hasGesture) {
                if (hasGesture) {
                  ref.read(isTrackingFlightProvider.notifier).set(false);
                }
                final zoom = position.zoom;
                if (zoom != _currentZoom) {
                  setState(() => _currentZoom = zoom);
                }
              },
            ),
            children: [
              // Tile layer — URL comes from the selected basemap style. The
              // ValueKey ties the layer's lifecycle to the URL so flutter_map
              // disposes the previous tile cache and rebuilds when the user
              // picks a different style (the web frontend keeps a per-URL
              // layer cache; flutter_map's tile manager handles that
              // internally so we don't need an explicit cache here).
              TileLayer(
                key: ValueKey(style.url),
                urlTemplate: style.url,
                userAgentPackageName: 'com.airwatch.mobile',
                tileProvider: NetworkTileProvider(),
                maxNativeZoom: style.maxNativeZoom ?? 19,
              ),

              // Turbulence / SIGMET overlay (translucent polygons,
              // toggled via showTurbulenceProvider).
              const TurbulenceOverlayLayer(),

              // Airport markers (major airports)
              AirportMarkersLayer(zoom: _currentZoom),

              // Flight trail — only for selected aircraft
              if (showTrails && selectedAircraft != null)
                FlightTrailLayer(
                  aircraft: [selectedAircraft],
                  selectedIcao: selectedAircraft.icao24,
                  // destinationPosition could be set from route data
                ),

              // Aircraft markers (with interpolated positions)
              _InterpolatedMarkerLayer(
                aircraft: aircraft,
                selectedAircraft: selectedAircraft,
                currentZoom: _currentZoom,
                onSelect: (ac) => ref.read(selectedAircraftProvider.notifier).set(ac),
              ),
            ],
          ),

          // Radar overlay (concentric circles + sweep)
          const RadarOverlay(),

          // Squawk emergency alert banner — surfaces 7500 / 7600 / 7700
          // squawks at the top of the map. Hidden when there are no
          // active emergencies.
          const SquawkAlertBanner(),

          // Status overlay
          const StatusOverlay(),

          // Map controls (zoom clamped to min/max)
          MapControls(
            onZoomIn: _currentZoom < AppConfig.maxZoom ? () => _mapController.move(
              _mapController.camera.center,
              (_mapController.camera.zoom + 1).clamp(AppConfig.minZoom, AppConfig.maxZoom),
            ) : null,
            onZoomOut: _currentZoom > 3 ? () => _mapController.move(
              _mapController.camera.center,
              (_mapController.camera.zoom - 1).clamp(3.0, AppConfig.maxZoom),
            ) : null,
            onMyLocation: () {
              // Default to center of map
              _mapController.move(const LatLng(AppConfig.defaultLat, AppConfig.defaultLon), 8);
            },
            onToggleSearch: () {
              setState(() => _showSearch = !_showSearch);
            },
          ),

          // Search overlay
          if (_showSearch) _buildSearchOverlay(isDark),

          // Flight details panel
          const FlightDetailsPanel(),
        ],
      ),
    );
  }

  Widget _buildSearchOverlay(bool isDark) {
    final searchResults = ref.watch(searchResultsProvider);
    final primaryColor = isDark ? AppColors.primary : UiConstants.lightPrimary;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 60,
      left: 12,
      right: 60,
      child: Column(
        children: [
          // Search bar
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surface.withValues(alpha: 0.95)
                  : Colors.white.withValues(alpha: 0.98),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? AppColors.glassBorder : UiConstants.lightBorder,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? primaryColor.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (v) =>
                  ref.read(searchQueryProvider.notifier).set(v),
              style: TextStyle(
                fontFamily: UiConstants.bodyFont,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.textPrimary : UiConstants.lightTextPrimary,
              ),
              decoration: InputDecoration(
                hintText: context.tr('search_map_hint'),
                hintStyle: TextStyle(
                  fontFamily: UiConstants.bodyFont,
                  color: isDark ? AppColors.textMuted : UiConstants.lightHintText,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: primaryColor,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          ref.read(searchQueryProvider.notifier).set('');
                        },
                        child: Icon(
                          Icons.close_rounded,
                          color: isDark ? AppColors.textMuted : UiConstants.lightTextMuted,
                        ),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
              ),
            ),
          ),

          // Results
          if (searchResults.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8),
              constraints: const BoxConstraints(maxHeight: 300),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surface.withValues(alpha: 0.95)
                    : Colors.white.withValues(alpha: 0.98),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? AppColors.glassBorder : UiConstants.lightBorder,
                ),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: searchResults.length,
                itemBuilder: (context, index) {
                  final ac = searchResults[index];
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.flight_rounded,
                      color: primaryColor,
                      size: 20,
                    ),
                    title: Text(
                      ac.callsign?.trim() ?? ac.icao24.toUpperCase(),
                      style: TextStyle(
                        fontFamily: UiConstants.headingFont,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textPrimary : UiConstants.lightTextPrimary,
                      ),
                    ),
                    subtitle: Text(
                      '${ac.originCountry ?? UiConstants.unknownValue} • ${ac.altitude?.toStringAsFixed(0) ?? "--"}m',
                      style: TextStyle(
                        fontFamily: UiConstants.bodyFont,
                        fontSize: 12,
                        color: isDark ? AppColors.textSecondary : UiConstants.lightTextSecondary,
                      ),
                    ),
                    onTap: () {
                      ref.read(selectedAircraftProvider.notifier).set(ac);
                      if (ac.position != null) {
                        _mapController.move(ac.position!, 10);
                      }
                      setState(() => _showSearch = false);
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// Optimized marker layer with viewport culling + clustering.
/// Only renders aircraft visible on screen. At low zoom, clusters nearby aircraft.
class _InterpolatedMarkerLayer extends ConsumerWidget {
  final Map<String, AircraftState> aircraft;
  final AircraftState? selectedAircraft;
  final double currentZoom;
  final void Function(AircraftState) onSelect;

  const _InterpolatedMarkerLayer({
    required this.aircraft,
    required this.selectedAircraft,
    required this.currentZoom,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final camera = MapCamera.maybeOf(context);
    if (camera == null) return const SizedBox.shrink();

    // Watch interpolated positions for smooth movement
    final interpState = ref.watch(interpolationProvider);
    final interpPositions = interpState.positions;

    // Get visible bounds with margin
    final bounds = camera.visibleBounds;
    final margin = (AppConfig.viewportMarginBase - currentZoom).clamp(AppConfig.viewportMarginMin, AppConfig.viewportMarginMax);
    final south = bounds.south - margin;
    final north = bounds.north + margin;
    final west = bounds.west - margin;
    final east = bounds.east + margin;

    // Step 1: Viewport culling — only keep aircraft in visible area
    final visible = aircraft.values.where((a) {
      if (!a.hasPosition) return false;
      final lat = a.latitude!;
      final lng = a.longitude!;
      return lat >= south && lat <= north && lng >= west && lng <= east;
    }).toList();

    // Step 2: Clustering at low zoom levels
    List<_MarkerData> markerData;
    if (currentZoom < AppConfig.clusterZoomThreshold && visible.length > AppConfig.clusterMinCount) {
      markerData = _clusterAircraft(visible, currentZoom);
    } else {
      markerData = visible.map((ac) => _MarkerData(aircraft: ac)).toList();
    }

    // Step 3: Build markers (max ~800 for performance)
    if (markerData.length > AppConfig.maxVisibleMarkers && currentZoom < AppConfig.maxMarkersSamplingZoom) {
      // Too many even after culling — sample every Nth
      final step = (markerData.length / AppConfig.maxMarkersSamplingTarget).ceil();
      markerData = [
        for (int i = 0; i < markerData.length; i += step) markerData[i],
      ];
    }

    // Always include selected aircraft
    if (selectedAircraft != null && selectedAircraft!.hasPosition) {
      final hasSelected = markerData.any((m) =>
          m.aircraft?.icao24 == selectedAircraft!.icao24);
      if (!hasSelected) {
        markerData.add(_MarkerData(aircraft: selectedAircraft));
      }
    }

    final markers = markerData.map((md) {
      if (md.isCluster) {
        // Unique key from grid position (lat/lon rounded)
        final ck = 'c_${md.clusterCenter!.latitude.toStringAsFixed(1)}_${md.clusterCenter!.longitude.toStringAsFixed(1)}';
        return Marker(
          key: ValueKey(ck),
          point: md.clusterCenter!,
          width: 36, height: 36,
          child: _ClusterDot(count: md.clusterCount, zoom: currentZoom),
        );
      }

      final ac = md.aircraft!;
      final isSelected = ac.icao24 == selectedAircraft?.icao24;
      final baseSize = _baseSize(ac.category);
      final zoomScale = (currentZoom / AppConfig.markerZoomScaleDivisor).clamp(AppConfig.markerZoomScaleMin, AppConfig.markerZoomScaleMax);
      final markerSize = isSelected ? AppConfig.selectedMarkerSize : (baseSize * zoomScale).clamp(AppConfig.markerSizeMin, AppConfig.markerSizeMax);

      // Use interpolated position if available (smooth movement)
      final point = interpPositions[ac.icao24] ?? ac.position!;

      return Marker(
        key: ValueKey(ac.icao24),
        point: point,
        width: isSelected ? AppConfig.selectedMarkerOverflowWidth : markerSize,
        height: isSelected ? markerSize + AppConfig.selectedMarkerExtraHeight : markerSize,
        child: AnimatedAircraftMarker(
          key: ValueKey('marker_${ac.icao24}'),
          aircraft: ac,
          isSelected: isSelected,
          markerSize: markerSize,
          onTap: () => onSelect(ac),
        ),
      );
    }).toList();

    return MarkerLayer(markers: markers);
  }

  /// Simple grid-based clustering for low zoom levels
  List<_MarkerData> _clusterAircraft(List<AircraftState> aircraft, double zoom) {
    // Grid cell size in degrees — larger cells at lower zoom
    final cellSize = (AppConfig.clusterCellSizeBase - zoom).clamp(AppConfig.clusterCellSizeMin, AppConfig.clusterCellSizeMax);
    final clusters = <String, List<AircraftState>>{};

    for (final ac in aircraft) {
      final gridX = (ac.longitude! / cellSize).floor();
      final gridY = (ac.latitude! / cellSize).floor();
      final key = '$gridX,$gridY';
      (clusters[key] ??= []).add(ac);
    }

    final result = <_MarkerData>[];
    for (final cluster in clusters.values) {
      if (cluster.length == 1) {
        result.add(_MarkerData(aircraft: cluster.first));
      } else if (cluster.length <= AppConfig.clusterSmallThreshold) {
        // Small cluster — show individual markers
        for (final ac in cluster) {
          result.add(_MarkerData(aircraft: ac));
        }
      } else {
        // Cluster — show dot with count
        double sumLat = 0, sumLng = 0;
        for (final ac in cluster) {
          sumLat += ac.latitude!;
          sumLng += ac.longitude!;
        }
        result.add(_MarkerData(
          clusterCenter: LatLng(sumLat / cluster.length, sumLng / cluster.length),
          clusterCount: cluster.length,
        ));
      }
    }
    return result;
  }

  double _baseSize(int category) =>
      AppConfig.categoryMarkerSizes[category] ?? AppConfig.categoryMarkerSizeDefault;
}

class _MarkerData {
  final AircraftState? aircraft;
  final LatLng? clusterCenter;
  final int clusterCount;

  _MarkerData({this.aircraft, this.clusterCenter, this.clusterCount = 0});

  bool get isCluster => clusterCenter != null;
}

/// Cluster dot showing aircraft count
class _ClusterDot extends StatelessWidget {
  final int count;
  final double zoom;
  const _ClusterDot({required this.count, required this.zoom});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? AppColors.primary : UiConstants.lightPrimary;

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.2),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
        boxShadow: isDark ? [
          BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8),
        ] : null,
      ),
      child: Center(
        child: Text(
          '$count',
          style: TextStyle(
            fontFamily: UiConstants.headingFont, fontSize: 9,
            fontWeight: FontWeight.w700, color: color,
          ),
        ),
      ),
    );
  }
}
