import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import 'package:airwatch_mobile/core/constants/config.dart';
import 'package:airwatch_mobile/core/constants/ui_constants.dart';
import 'package:airwatch_mobile/core/l10n/ui_text.dart';
import 'package:airwatch_mobile/core/theme/app_colors.dart';
import 'package:airwatch_mobile/core/utils/geo_utils.dart';
import 'package:airwatch_mobile/core/widgets/glass_panel.dart';
import 'package:airwatch_mobile/features/geofences/data/geofences_repository.dart';
import 'package:airwatch_mobile/features/geofences/domain/geofence.dart';
import 'package:airwatch_mobile/features/map/presentation/providers/flight_providers.dart';
import 'package:airwatch_mobile/features/map/presentation/widgets/map_styles.dart';

/// Tap-to-draw geofence editor on a flutter_map basemap.
///
/// <p>Mirrors the web frontend's `GeoFenceDrawMap.tsx`. The user picks
/// a shape (circle / rectangle), then taps:
/// <ul>
///   <li><b>Circle</b> — first tap sets the center, second tap sets
///       the radius (great-circle distance from the center).</li>
///   <li><b>Rectangle</b> — first tap sets one corner, second tap
///       sets the opposite corner.</li>
/// </ul>
///
/// <p>A "Save" button asks for a name + the same optional filters as
/// the form-based screen (altitude band, airline ICAO) and writes the
/// fence through [geofencesProvider]. Cancel discards the draft.
class GeoFenceDrawScreen extends ConsumerStatefulWidget {
  const GeoFenceDrawScreen({super.key});

  @override
  ConsumerState<GeoFenceDrawScreen> createState() => _GeoFenceDrawScreenState();
}

class _GeoFenceDrawScreenState extends ConsumerState<GeoFenceDrawScreen> {
  GeoFenceType _shape = GeoFenceType.circle;

  /// Working draft — the two taps end up here. The fence is materialised
  /// at save-time from these vertices.
  LatLng? _firstTap;
  LatLng? _secondTap;

  void _handleTap(TapPosition _, LatLng latlng) {
    setState(() {
      if (_firstTap == null) {
        _firstTap = latlng;
        _secondTap = null;
      } else {
        _secondTap = latlng;
      }
    });
  }

  void _reset() {
    setState(() {
      _firstTap = null;
      _secondTap = null;
    });
  }

  bool get _ready => _firstTap != null && _secondTap != null;

  Future<void> _save() async {
    if (!_ready) return;
    final name = await _askName();
    if (name == null || name.trim().isEmpty || !mounted) return;

    final GeoFence fence;
    if (_shape == GeoFenceType.circle) {
      final radiusKm = GeoUtils.distanceKm(_firstTap!, _secondTap!);
      fence = GeoFence(
        id: 'fence-${DateTime.now().millisecondsSinceEpoch}',
        name: name.trim(),
        type: GeoFenceType.circle,
        centerLat: _firstTap!.latitude,
        centerLon: _firstTap!.longitude,
        radiusKm: radiusKm.clamp(1, 5000),
      );
    } else {
      // Order corners — tap order doesn't matter; we resolve to
      // north/south + east/west.
      final n = _firstTap!.latitude > _secondTap!.latitude
          ? _firstTap!.latitude
          : _secondTap!.latitude;
      final s = _firstTap!.latitude > _secondTap!.latitude
          ? _secondTap!.latitude
          : _firstTap!.latitude;
      final e = _firstTap!.longitude > _secondTap!.longitude
          ? _firstTap!.longitude
          : _secondTap!.longitude;
      final w = _firstTap!.longitude > _secondTap!.longitude
          ? _secondTap!.longitude
          : _firstTap!.longitude;
      fence = GeoFence(
        id: 'fence-${DateTime.now().millisecondsSinceEpoch}',
        name: name.trim(),
        type: GeoFenceType.rectangle,
        northLat: n,
        southLat: s,
        eastLon: e,
        westLon: w,
      );
    }
    ref.read(geofencesProvider.notifier).add(fence);
    if (mounted) Navigator.of(context).pop();
  }

  Future<String?> _askName() {
    final ctl = TextEditingController();
    final s = context.s;
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.fenceDrawNameTitle),
        content: TextField(
          controller: ctl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: s.fenceNamePlaceholder,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.fenceCancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctl.text),
            child: Text(s.fenceSaveButton),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final styleId = ref.watch(mapStyleProvider);
    final tileUrl = styleDef(styleId).url;
    final s = context.s;

    final hint = _firstTap == null
        ? (_shape == GeoFenceType.circle
              ? s.fenceDrawHintCircleFirst
              : s.fenceDrawHintRectFirst)
        : (_secondTap == null
              ? (_shape == GeoFenceType.circle
                    ? s.fenceDrawHintCircleSecond
                    : s.fenceDrawHintRectSecond)
              : s.fenceDrawHintReady);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.fenceDrawTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_ready)
            TextButton(
              onPressed: _save,
              child: Text(
                s.fenceSaveButton,
                style: const TextStyle(
                  fontFamily: UiConstants.headingFont,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.6,
                  color: AppColors.success,
                ),
              ),
            ),
          if (_firstTap != null)
            TextButton(
              onPressed: _reset,
              child: Text(
                s.fenceDrawResetButton,
                style: const TextStyle(
                  fontFamily: UiConstants.headingFont,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.6,
                  color: AppColors.error,
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: const LatLng(
                AppConfig.defaultLat,
                AppConfig.defaultLon,
              ),
              initialZoom: AppConfig.defaultZoom,
              minZoom: AppConfig.minZoom,
              maxZoom: AppConfig.maxZoom,
              backgroundColor: isDark
                  ? AppColors.background
                  : UiConstants.lightBackground,
              onTap: _handleTap,
            ),
            children: [
              TileLayer(
                urlTemplate: tileUrl,
                userAgentPackageName: 'com.airwatch.mobile',
                tileProvider: NetworkTileProvider(),
              ),
              // Live preview of the in-progress draft. We paint it
              // straight onto the map so the user sees the shape grow
              // as they tap.
              if (_ready) _buildPreviewLayer(),
              // Vertex markers — small dots on the user's tap points.
              if (_firstTap != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _firstTap!,
                      width: 14,
                      height: 14,
                      child: const _Dot(color: AppColors.primary),
                    ),
                    if (_secondTap != null)
                      Marker(
                        point: _secondTap!,
                        width: 14,
                        height: 14,
                        child: const _Dot(color: AppColors.accent),
                      ),
                  ],
                ),
            ],
          ),

          // Shape chooser + hint banner
          Positioned(
            left: 12,
            right: 12,
            bottom: 16,
            child: Column(
              children: [
                GlassPanel(
                  padding: const EdgeInsets.all(8),
                  borderRadius: 10,
                  child: Row(
                    children: [
                      Expanded(
                        child: _ShapeButton(
                          label: s.fenceTypeCircle,
                          icon: Icons.circle_outlined,
                          active: _shape == GeoFenceType.circle,
                          onTap: () {
                            setState(() {
                              _shape = GeoFenceType.circle;
                              _reset();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _ShapeButton(
                          label: s.fenceTypeRectangle,
                          icon: Icons.crop_square_rounded,
                          active: _shape == GeoFenceType.rectangle,
                          onTap: () {
                            setState(() {
                              _shape = GeoFenceType.rectangle;
                              _reset();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                GlassPanel(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  borderRadius: 10,
                  child: Text(
                    hint,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: UiConstants.bodyFont,
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textPrimary
                          : UiConstants.lightTextPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewLayer() {
    if (_shape == GeoFenceType.circle) {
      final radiusMeters = GeoUtils.distanceKm(_firstTap!, _secondTap!) * 1000;
      return CircleLayer(
        circles: [
          CircleMarker(
            point: _firstTap!,
            radius: radiusMeters,
            useRadiusInMeter: true,
            color: AppColors.primary.withValues(alpha: 0.15),
            borderColor: AppColors.primary.withValues(alpha: 0.85),
            borderStrokeWidth: 1.6,
          ),
        ],
      );
    }
    // Rectangle preview as a polygon.
    final n = _firstTap!.latitude > _secondTap!.latitude
        ? _firstTap!.latitude
        : _secondTap!.latitude;
    final s = _firstTap!.latitude > _secondTap!.latitude
        ? _secondTap!.latitude
        : _firstTap!.latitude;
    final e = _firstTap!.longitude > _secondTap!.longitude
        ? _firstTap!.longitude
        : _secondTap!.longitude;
    final w = _firstTap!.longitude > _secondTap!.longitude
        ? _secondTap!.longitude
        : _firstTap!.longitude;
    return PolygonLayer(
      polygons: [
        Polygon(
          points: [LatLng(n, w), LatLng(n, e), LatLng(s, e), LatLng(s, w)],
          color: AppColors.primary.withValues(alpha: 0.15),
          borderColor: AppColors.primary.withValues(alpha: 0.85),
          borderStrokeWidth: 1.6,
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8),
        ],
      ),
    );
  }
}

class _ShapeButton extends StatelessWidget {
  const _ShapeButton({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primary.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: active
                ? AppColors.primary.withValues(alpha: 0.55)
                : AppColors.glassBorder,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: active ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: UiConstants.headingFont,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
                color: active ? AppColors.primary : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
