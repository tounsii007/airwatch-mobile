import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:airwatch_mobile/core/constants/config.dart';
import 'package:airwatch_mobile/core/constants/ui_constants.dart';
import 'package:airwatch_mobile/core/l10n/ui_text.dart';
import 'package:airwatch_mobile/core/network/app_http_client.dart';
import 'package:airwatch_mobile/core/theme/app_colors.dart';
import 'package:airwatch_mobile/core/utils/flight_code_formatter.dart';
import 'package:airwatch_mobile/core/widgets/glass_panel.dart';
import 'package:airwatch_mobile/core/widgets/neon_text.dart';

/// Replays a past flight track on the map with animated aircraft movement.
class FlightReplayScreen extends StatefulWidget {
  final String icao24;
  final String? callsign;

  const FlightReplayScreen({super.key, required this.icao24, this.callsign});

  @override
  State<FlightReplayScreen> createState() => _FlightReplayScreenState();
}

class _FlightReplayScreenState extends State<FlightReplayScreen>
    with SingleTickerProviderStateMixin {
  final Dio _dio = AppHttpClient.create();

  List<_Waypoint> _waypoints = [];
  bool _isLoading = true;
  String? _error;
  late AnimationController _playController;
  double _playbackSpeed = 1.0;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _playController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..addListener(() => setState(() {}));
    _fetchTrack();
  }

  @override
  void dispose() {
    _playController.dispose();
    super.dispose();
  }

  Future<void> _fetchTrack() async {
    try {
      // Use Airlabs /flight to get current position data
      final url = AppConfig.flightUrl(
        flightIcao: widget.callsign ?? widget.icao24,
      );
      final response = await _dio.get(url);

      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map;
        final path = data['path'] as List?;

        if (path != null && path.length >= 2) {
          _waypoints = path.map((wp) {
            final w = wp as List;
            return _Waypoint(
              time: w[0] as int,
              lat: (w[1] as num?)?.toDouble() ?? 0,
              lng: (w[2] as num?)?.toDouble() ?? 0,
              altitude: (w[3] as num?)?.toDouble(),
              heading: (w[4] as num?)?.toDouble(),
              onGround: w[5] as bool? ?? false,
            );
          }).toList();
        }
      }

      setState(() {
        _isLoading = false;
        if (_waypoints.length < 2) {
          _error = context.tr('no_track_data');
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = '${context.tr('failed_to_load_track')}: $e';
      });
    }
  }

  void _togglePlay() {
    setState(() {
      if (_isPlaying) {
        _playController.stop();
      } else {
        if (_playController.isCompleted) _playController.reset();
        _playController.forward();
      }
      _isPlaying = !_isPlaying;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primary : UiConstants.lightPrimary;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.background
          : UiConstants.lightBackground,
      body: Stack(
        children: [
          // Map with track
          if (_waypoints.length >= 2)
            FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(
                  _waypoints.first.lat,
                  _waypoints.first.lng,
                ),
                initialZoom: 6,
                backgroundColor: isDark
                    ? AppColors.background
                    : UiConstants.lightBackground,
              ),
              children: [
                TileLayer(
                  urlTemplate: isDark
                      ? 'https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png'
                      : 'https://basemaps.cartocdn.com/light_all/{z}/{x}/{y}@2x.png',
                ),
                // Full track line
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _waypoints
                          .map((w) => LatLng(w.lat, w.lng))
                          .toList(),
                      strokeWidth: 3,
                      color: primary.withValues(alpha: 0.4),
                      gradientColors: [primary.withValues(alpha: 0.1), primary],
                    ),
                  ],
                ),
                // Traveled portion (up to current playback)
                if (_playController.value > 0)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _traveledPoints(),
                        strokeWidth: 4,
                        color: AppColors.altitudeHigh,
                      ),
                    ],
                  ),
                // Aircraft marker at current position
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentPosition(),
                      width: 40,
                      height: 40,
                      child: Transform.rotate(
                        angle: (_currentHeading() ?? 0) * 3.14159 / 180,
                        child: Icon(
                          Icons.flight_rounded,
                          size: 28,
                          color: primary,
                          shadows: [
                            Shadow(
                              color: primary.withValues(alpha: 0.6),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Start marker
                    Marker(
                      point: LatLng(_waypoints.first.lat, _waypoints.first.lng),
                      width: 14,
                      height: 14,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.success,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.success.withValues(alpha: 0.5),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // End marker
                    Marker(
                      point: LatLng(_waypoints.last.lat, _waypoints.last.lng),
                      width: 14,
                      height: 14,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accent,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.5),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: GlassPanel(
                      padding: const EdgeInsets.all(10),
                      borderRadius: 12,
                      child: Icon(
                        Icons.arrow_back_rounded,
                        size: 20,
                        color: primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  NeonText(
                    text: context.tr('flight_replay'),
                    fontSize: 14,
                    color: primary,
                    glowRadius: isDark ? 8 : 0,
                  ),
                  const Spacer(),
                  GlassPanel(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    borderRadius: 10,
                    child: Text(
                      FlightCodeFormatter.displayFlightCode(
                        callsign: widget.callsign,
                        fallback: widget.icao24,
                      ),
                      style: TextStyle(
                        fontFamily: UiConstants.headingFont,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom playback controls
          if (_waypoints.length >= 2)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: GlassPanel(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Progress slider
                        SliderTheme(
                          data: SliderThemeData(
                            activeTrackColor: primary,
                            inactiveTrackColor: primary.withValues(alpha: 0.15),
                            thumbColor: primary,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6,
                            ),
                            trackHeight: 3,
                          ),
                          child: Slider(
                            value: _playController.value,
                            onChanged: (v) {
                              _playController.value = v;
                              setState(() {});
                            },
                          ),
                        ),
                        // Controls row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Altitude
                            Text(
                              '${context.s.altitude}: ${_currentAltitude()?.toStringAsFixed(0) ?? "--"}m',
                              style: const TextStyle(
                                fontFamily: UiConstants.headingFont,
                                fontSize: 9,
                                color: AppColors.altitudeHigh,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Play/Pause
                            GestureDetector(
                              onTap: _togglePlay,
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: primary,
                                  boxShadow: [
                                    BoxShadow(
                                      color: primary.withValues(alpha: 0.4),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  _isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Speed
                            GestureDetector(
                              onTap: () => setState(() {
                                _playbackSpeed = _playbackSpeed >= 4
                                    ? 1
                                    : _playbackSpeed * 2;
                                _playController.duration = Duration(
                                  seconds: (30 / _playbackSpeed).round(),
                                );
                              }),
                              child: Text(
                                '${_playbackSpeed.toStringAsFixed(0)}x',
                                style: TextStyle(
                                  fontFamily: UiConstants.headingFont,
                                  fontSize: 11,
                                  color: primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Loading/Error
          if (_isLoading)
            Center(child: CircularProgressIndicator(color: primary)),
          if (_error != null)
            Center(
              child: GlassPanel(
                padding: const EdgeInsets.all(20),
                child: Text(
                  _error!,
                  style: TextStyle(
                    fontFamily: UiConstants.bodyFont,
                    color: isDark
                        ? AppColors.textSecondary
                        : UiConstants.lightTextSecondary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  LatLng _currentPosition() {
    if (_waypoints.isEmpty) return const LatLng(0, 0);
    final idx = (_playController.value * (_waypoints.length - 1)).floor();
    final frac = (_playController.value * (_waypoints.length - 1)) - idx;
    if (idx >= _waypoints.length - 1) {
      return LatLng(_waypoints.last.lat, _waypoints.last.lng);
    }
    final a = _waypoints[idx];
    final b = _waypoints[idx + 1];
    return LatLng(
      a.lat + (b.lat - a.lat) * frac,
      a.lng + (b.lng - a.lng) * frac,
    );
  }

  double? _currentHeading() {
    final idx = (_playController.value * (_waypoints.length - 1)).floor().clamp(
      0,
      _waypoints.length - 1,
    );
    return _waypoints[idx].heading;
  }

  double? _currentAltitude() {
    final idx = (_playController.value * (_waypoints.length - 1)).floor().clamp(
      0,
      _waypoints.length - 1,
    );
    return _waypoints[idx].altitude;
  }

  List<LatLng> _traveledPoints() {
    final endIdx = (_playController.value * (_waypoints.length - 1))
        .ceil()
        .clamp(0, _waypoints.length);
    return _waypoints.take(endIdx).map((w) => LatLng(w.lat, w.lng)).toList()
      ..add(_currentPosition());
  }
}

class _Waypoint {
  final int time;
  final double lat, lng;
  final double? altitude, heading;
  final bool onGround;

  _Waypoint({
    required this.time,
    required this.lat,
    required this.lng,
    this.altitude,
    this.heading,
    this.onGround = false,
  });
}
