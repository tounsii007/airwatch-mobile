import 'dart:async';

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
import 'package:airwatch_mobile/core/widgets/error_boundary.dart';
import 'package:airwatch_mobile/core/widgets/glass_panel.dart';

/// Camera follow modes the 3-D replay supports.
///
/// <p>Mirrors the web frontend's `cameraModes.ts`:
/// <ul>
///   <li><b>Chase</b> — sphere rotates so the current playback point
///       sits at the center.</li>
///   <li><b>Top</b> — same as chase, plus the rotation is paused so
///       the camera is "looking down" at the current point.</li>
///   <li><b>Free</b> — the user controls panning + rotation manually
///       (the original behaviour).</li>
/// </ul>
enum _CameraMode { chase, top, free }

/// 3-D globe replay of a past flight track with scrubber + camera modes.
///
/// <p>The web frontend's `/replay/3d` route is built on deck.gl; that
/// has no Flutter equivalent. We use [FlutterEarthGlobe]'s point +
/// connection primitives and drive a "current index" timeline ourselves:
/// a [Slider] scrubs through the track, play/pause advances it, and
/// the active leg (segments up to the current index) is repainted as
/// the user moves through. Camera mode determines whether the globe
/// follows the playback head.
class FlightReplay3DScreen extends StatefulWidget {
  final String icao24;
  final String? callsign;

  const FlightReplay3DScreen({super.key, required this.icao24, this.callsign});

  @override
  State<FlightReplay3DScreen> createState() => _FlightReplay3DScreenState();
}

class _FlightReplay3DScreenState extends State<FlightReplay3DScreen> {
  late final FlutterEarthGlobeController _controller;
  bool _loading = true;
  String? _error;
  List<GlobeCoordinates> _coords = const [];

  /// Index of the most-recent waypoint shown. The slider drives this;
  /// the play loop advances it once per tick.
  int _idx = 0;

  /// Highest leg-index that has a corresponding `leg-N` connection on
  /// the globe. The diff path uses this to add only the new segments
  /// when [_idx] grows, instead of dropping + re-adding every leg
  /// (which had been allocating ~60 connection objects per tick — at
  /// 8x speed that's ~500 GC allocations/second on a phone screen).
  int _renderedLegEnd = -1;

  bool _playing = false;
  double _speed = 1.0;
  _CameraMode _cameraMode = _CameraMode.free;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _controller = FlutterEarthGlobeController(
      rotationSpeed: 0.02,
      isBackgroundFollowingSphereRotation: true,
      sphereStyle: const SphereStyle(
        shadowColor: AppColors.primary,
        shadowBlurSigma: 18,
      ),
    );
    _load();
  }

  @override
  void dispose() {
    _ticker?.cancel();
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
        ApiConstants.flightHistoryByCallsign(cs),
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

      final coords = <GlobeCoordinates>[
        for (final p in positions)
          GlobeCoordinates(
            (p['latitude'] as num? ?? 0).toDouble(),
            (p['longitude'] as num? ?? 0).toDouble(),
          ),
      ];

      // Departure + arrival markers — fixed for the entire session.
      _controller.addPoint(
        Point(
          id: 'dep',
          coordinates: coords.first,
          label: 'DEP',
          isLabelVisible: true,
          style: const PointStyle(color: Colors.greenAccent, size: 7),
        ),
      );
      _controller.addPoint(
        Point(
          id: 'arr',
          coordinates: coords.last,
          label: 'ARR',
          isLabelVisible: true,
          style: const PointStyle(color: Colors.amberAccent, size: 7),
        ),
      );

      // Current-position marker — moves as the user scrubs / plays.
      _controller.addPoint(
        Point(
          id: 'cur',
          coordinates: coords.first,
          label: cs,
          isLabelVisible: true,
          style: const PointStyle(color: Colors.cyanAccent, size: 9),
        ),
      );

      // Sub-sample to ~60 segments along the route — the user can't
      // tell the difference at globe scale, and the incremental
      // diff path needs a deterministic step to keep connection ids
      // stable across ticks.
      _legStep = (coords.length / 60).ceil().clamp(1, 200);

      setState(() {
        _coords = coords;
        _idx = 0;
        _renderedLegEnd = -1; // force a full rebuild on first paint
        _loading = false;
      });
      _renderUpToCurrent();
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

  /// Step size for the leg sub-sampler. Computed once at load-time so
  /// every play tick uses the same stride — that's what makes the
  /// incremental diff cheap.
  late int _legStep;

  /// Repaint the trail up to [_idx] using an INCREMENTAL diff — only
  /// the segments between the previously-rendered end and the new one
  /// touch the globe controller. A scrub backwards (or a shape
  /// change) tears the chain down once and rebuilds.
  ///
  /// <p>The previous version dropped + re-added every leg on every
  /// tick — that allocated ~60 connection objects per frame at 8x
  /// speed (≈ 500 / sec), which made low-end Androids stutter under
  /// the GC pressure. The diff path keeps allocations to one new
  /// connection per actually-new segment.
  void _renderUpToCurrent() {
    if (_coords.isEmpty) return;
    final upto = _idx.clamp(0, _coords.length - 1);

    // ── Scrub backwards or first paint after load: rebuild from 0. ──
    if (upto < _renderedLegEnd || _renderedLegEnd < 0) {
      _clearLegs();
      _renderedLegEnd = 0;
    }

    if (upto >= 1) {
      // Add only the segments past _renderedLegEnd up to upto. The
      // step is fixed so the connection ids stay deterministic
      // across ticks ("leg-7" always covers the same lat/lon span).
      final start = _renderedLegEnd <= 0
          ? _legStep
          : _renderedLegEnd + _legStep;
      for (var i = start; i <= upto; i += _legStep) {
        final connId = ((i ~/ _legStep) - 1).toString(); // 1-based → 0-based
        _controller.addPointConnection(
          PointConnection(
            id: 'leg-$connId',
            start: _coords[i - _legStep],
            end: _coords[i],
            style: const PointConnectionStyle(
              color: AppColors.primary,
              lineWidth: 2,
            ),
          ),
        );
        _renderedLegEnd = i;
      }
    }

    _moveCurrentTo(_coords[upto]);
    _maybeFollowCamera(_coords[upto]);
  }

  /// Drop every `leg-*` connection. Used by the rebuild path when
  /// the user scrubs backwards — much rarer than the forward path,
  /// so this lookup-then-remove approach is fine.
  void _clearLegs() {
    final ids = _controller.connections.map((c) => c.id).toList();
    for (final id in ids) {
      if (id.startsWith('leg-')) {
        _controller.removePointConnection(id);
      }
    }
  }

  /// Move the `cur` marker to a new coordinate. flutter_earth_globe's
  /// [FlutterEarthGlobeController.updatePoint] only updates label + style,
  /// so re-positioning requires a remove + add.
  void _moveCurrentTo(GlobeCoordinates pos) {
    _controller.removePoint('cur');
    _controller.addPoint(
      Point(
        id: 'cur',
        coordinates: pos,
        label: widget.callsign?.trim() ?? widget.icao24.toUpperCase(),
        isLabelVisible: true,
        style: const PointStyle(color: Colors.cyanAccent, size: 9),
      ),
    );
  }

  void _maybeFollowCamera(GlobeCoordinates pos) {
    if (_cameraMode == _CameraMode.free) return;
    _controller.focusOnCoordinates(pos, animate: true);
  }

  void _setCameraMode(_CameraMode mode) {
    setState(() => _cameraMode = mode);
    switch (mode) {
      case _CameraMode.chase:
        _controller.isRotating = true;
        if (_coords.isNotEmpty) {
          _controller.focusOnCoordinates(_coords[_idx], animate: true);
        }
      case _CameraMode.top:
        _controller.isRotating = false;
        if (_coords.isNotEmpty) {
          _controller.focusOnCoordinates(_coords[_idx], animate: true);
        }
      case _CameraMode.free:
        _controller.isRotating = false;
    }
  }

  void _togglePlay() {
    if (_coords.isEmpty) return;
    if (_playing) {
      _ticker?.cancel();
      setState(() => _playing = false);
      return;
    }
    setState(() => _playing = true);
    _ticker = Timer.periodic(
      Duration(milliseconds: (200 / _speed).round().clamp(33, 1000)),
      (_) {
        if (!mounted) return;
        if (_idx >= _coords.length - 1) {
          // Loop back to start so the user can replay without re-entering.
          setState(() => _idx = 0);
          _renderUpToCurrent();
          return;
        }
        setState(() => _idx = _idx + 1);
        _renderUpToCurrent();
      },
    );
  }

  void _onScrub(double v) {
    setState(() => _idx = v.round().clamp(0, _coords.length - 1));
    _renderUpToCurrent();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.callsign ?? widget.icao24.toUpperCase()),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      // 3D globe + history-replay scrubber — same crash surface as the
      // standalone globe screen plus the timeline math. Boundary scopes
      // any blowup to "section unavailable" so the user can back out
      // and pick a different replay.
      body: ErrorBoundary(
        child: Stack(
          children: [
            Center(
              child: FlutterEarthGlobe(controller: _controller, radius: 140),
            ),
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
                top: 16,
                child: GlassPanel(
                  padding: const EdgeInsets.all(12),
                  borderRadius: 12,
                  borderColor: AppColors.error.withValues(alpha: 0.45),
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      fontFamily: UiConstants.bodyFont,
                      color: AppColors.error,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            if (!_loading && _error == null && _coords.isNotEmpty)
              Positioned(
                left: 12,
                right: 12,
                bottom: 16,
                child: _ControlsPanel(
                  idx: _idx,
                  count: _coords.length,
                  playing: _playing,
                  speed: _speed,
                  cameraMode: _cameraMode,
                  onPlayToggle: _togglePlay,
                  onScrub: _onScrub,
                  onSpeedChange: (v) => setState(() => _speed = v),
                  onCameraMode: _setCameraMode,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Bottom control strip — scrubber + play/pause + speed pills + camera
/// mode selector. Stays compact so it doesn't cover too much globe.
class _ControlsPanel extends StatelessWidget {
  const _ControlsPanel({
    required this.idx,
    required this.count,
    required this.playing,
    required this.speed,
    required this.cameraMode,
    required this.onPlayToggle,
    required this.onScrub,
    required this.onSpeedChange,
    required this.onCameraMode,
  });

  final int idx;
  final int count;
  final bool playing;
  final double speed;
  final _CameraMode cameraMode;
  final VoidCallback onPlayToggle;
  final ValueChanged<double> onScrub;
  final ValueChanged<double> onSpeedChange;
  final ValueChanged<_CameraMode> onCameraMode;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      borderRadius: 12,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Scrubber
          Row(
            children: [
              GestureDetector(
                onTap: onPlayToggle,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
              ),
              Expanded(
                child: Slider(
                  max: (count - 1).toDouble(),
                  value: idx.toDouble().clamp(0, (count - 1).toDouble()),
                  onChanged: onScrub,
                ),
              ),
              SizedBox(
                width: 56,
                child: Text(
                  '$idx / ${count - 1}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontFamily: UiConstants.headingFont,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Speed pills
          Row(
            children: [
              const Text(
                'SPEED',
                style: TextStyle(
                  fontFamily: UiConstants.headingFont,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 6),
              for (final s in const [1.0, 2.0, 4.0, 8.0])
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 4),
                  child: _Chip(
                    label: '${s.toStringAsFixed(0)}x',
                    active: speed == s,
                    onTap: () => onSpeedChange(s),
                  ),
                ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 6),
          // Camera mode
          Row(
            children: [
              const Text(
                'CAMERA',
                style: TextStyle(
                  fontFamily: UiConstants.headingFont,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 6),
              _Chip(
                label: 'CHASE',
                active: cameraMode == _CameraMode.chase,
                onTap: () => onCameraMode(_CameraMode.chase),
              ),
              const SizedBox(width: 4),
              _Chip(
                label: 'TOP',
                active: cameraMode == _CameraMode.top,
                onTap: () => onCameraMode(_CameraMode.top),
              ),
              const SizedBox(width: 4),
              _Chip(
                label: 'FREE',
                active: cameraMode == _CameraMode.free,
                onTap: () => onCameraMode(_CameraMode.free),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primary.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: active
                ? AppColors.primary.withValues(alpha: 0.55)
                : AppColors.glassBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: UiConstants.headingFont,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
            color: active ? AppColors.primary : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
