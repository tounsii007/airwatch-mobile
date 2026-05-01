import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_earth_globe/flutter_earth_globe.dart';
import 'package:flutter_earth_globe/flutter_earth_globe_controller.dart';
import 'package:flutter_earth_globe/globe_coordinates.dart';
import 'package:flutter_earth_globe/point.dart';
import 'package:flutter_earth_globe/point_connection.dart';
import 'package:flutter_earth_globe/point_connection_style.dart';
import 'package:flutter_earth_globe/sphere_style.dart';

import 'package:airwatch_mobile/core/constants/api_constants.dart';
import 'package:airwatch_mobile/core/constants/ui_constants.dart';
import 'package:airwatch_mobile/core/network/app_http_client.dart';
import 'package:airwatch_mobile/core/theme/app_colors.dart';
import 'package:airwatch_mobile/core/widgets/glass_panel.dart';

/// 3-D globe replay of a past flight track.
///
/// <p>The web frontend's `/replay/3d` route is built on deck.gl's
/// TripsLayer + GPU-animated path, which has no Flutter equivalent.
/// Mobile uses [FlutterEarthGlobe] (the same package powering the
/// `Globe` screen) and renders the trail as a sequence of point
/// connections — visually similar to the web version (animated arc
/// across a 3-D sphere) without needing a WebGL context.
///
/// <p>The animation runs at the controller's natural ~30 fps via the
/// package's built-in arc-draw animation. We don't try to fake a
/// "scrubber" — opening / closing the screen is the play/reset gesture.
class FlightReplay3DScreen extends StatefulWidget {
  final String icao24;
  final String? callsign;

  const FlightReplay3DScreen({
    super.key,
    required this.icao24,
    this.callsign,
  });

  @override
  State<FlightReplay3DScreen> createState() => _FlightReplay3DScreenState();
}

class _FlightReplay3DScreenState extends State<FlightReplay3DScreen> {
  late final FlutterEarthGlobeController _controller;
  bool _loading = true;
  String? _error;
  int _waypointCount = 0;

  @override
  void initState() {
    super.initState();
    _controller = FlutterEarthGlobeController(
      rotationSpeed: 0.02,
      isRotating: false,
      isBackgroundFollowingSphereRotation: true,
      sphereStyle: SphereStyle(
        shadowColor: AppColors.primary,
        shadowBlurSigma: 18,
      ),
    );
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final cs = widget.callsign?.trim() ?? '';
    if (cs.isEmpty) {
      setState(() {
        _error = 'No callsign — replay needs a flight code.';
        _loading = false;
      });
      return;
    }

    try {
      final dio = AppHttpClient.create();
      final r = await dio.get<dynamic>(
        ApiConstants.flightHistoryByCallsign(cs, hours: 24),
      );
      if (r.statusCode != 200 || r.data is! Map) {
        setState(() {
          _error = 'No track data available.';
          _loading = false;
        });
        return;
      }
      final data = Map<String, dynamic>.from(r.data as Map);
      final positions = (data['positions'] as List?) ?? const [];
      if (positions.length < 2) {
        setState(() {
          _error = 'Track too short to render.';
          _loading = false;
        });
        return;
      }

      // Convert raw API points into globe coordinates and chain them
      // into a sequence of arc connections so the package draws an
      // animated path along the route.
      final coords = <GlobeCoordinates>[
        for (final p in positions)
          GlobeCoordinates(
            (p['latitude'] as num? ?? 0).toDouble(),
            (p['longitude'] as num? ?? 0).toDouble(),
          ),
      ];

      // Departure + arrival markers — call out the endpoints so the
      // user can see the arc terminate visually.
      _controller.addPoint(Point(
        id: 'dep',
        coordinates: coords.first,
        label: 'DEP',
        isLabelVisible: true,
        style: const PointStyle(color: Colors.greenAccent, size: 7),
      ));
      _controller.addPoint(Point(
        id: 'arr',
        coordinates: coords.last,
        label: 'ARR',
        isLabelVisible: true,
        style: const PointStyle(color: Colors.amberAccent, size: 7),
      ));

      // Connect consecutive samples so the resulting polyline traces
      // the actual flown path. Sub-sample to keep the connection
      // count reasonable on long flights — every Nth point is enough
      // for a smooth visual.
      final step = (coords.length / 80).ceil().clamp(1, 200);
      var connId = 0;
      for (var i = step; i < coords.length; i += step) {
        _controller.addPointConnection(
          PointConnection(
            id: 'leg-${connId++}',
            start: coords[i - step],
            end: coords[i],
            style: PointConnectionStyle(
              color: AppColors.primary,
              lineWidth: 2,
              type: PointConnectionType.solid,
            ),
          ),
        );
      }

      setState(() {
        _waypointCount = coords.length;
        _loading = false;
      });
    } on DioException catch (e) {
      setState(() {
        _error = 'Network error: ${e.message ?? "unknown"}';
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load track: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.callsign ?? widget.icao24.toUpperCase()),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Auto-rotate',
            icon: const Icon(Icons.threed_rotation_rounded),
            onPressed: () {
              _controller.isRotating = !_controller.isRotating;
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Globe fills the body.
          Center(
            child: FlutterEarthGlobe(
              controller: _controller,
              radius: 140,
            ),
          ),
          // Status / loading overlay.
          if (_loading)
            const Positioned(
              top: 16,
              right: 16,
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 1.5),
              ),
            ),
          if (_error != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: GlassPanel(
                padding: const EdgeInsets.all(12),
                borderRadius: 12,
                borderColor: AppColors.error.withValues(alpha: 0.45),
                child: Text(
                  _error!,
                  style: TextStyle(
                    fontFamily: UiConstants.bodyFont,
                    color: AppColors.error,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          if (!_loading && _error == null)
            Positioned(
              left: 12,
              bottom: 12,
              child: GlassPanel(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                borderRadius: 10,
                child: Text(
                  '$_waypointCount waypoints',
                  style: TextStyle(
                    fontFamily: UiConstants.headingFont,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
