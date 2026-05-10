import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'package:airwatch_mobile/core/constants/ui_constants.dart';
import 'package:airwatch_mobile/core/l10n/ui_text.dart';
import 'package:airwatch_mobile/core/theme/app_colors.dart';
import 'package:airwatch_mobile/core/widgets/error_boundary.dart';
import 'package:airwatch_mobile/core/widgets/glass_panel.dart';
import 'package:airwatch_mobile/core/widgets/neon_text.dart';
import 'package:airwatch_mobile/features/ar/data/ar_aircraft_detector.dart';
import 'package:airwatch_mobile/features/ar/presentation/widgets/compass_hud.dart';
import 'package:airwatch_mobile/features/ar/presentation/widgets/horizon_line.dart';
import 'package:airwatch_mobile/features/map/data/models/aircraft_state.dart';
import 'package:airwatch_mobile/features/map/presentation/providers/flight_providers.dart';

/// AR Mode — overlays compass + horizon + nearby-aircraft labels on
/// top of the live sky view.
///
/// <p>Camera-feed integration is platform-specific and is wired in
/// separately; this screen uses a dark gradient placeholder behind
/// the HUD so the user still sees heading, tilt and the nearest
/// aircraft list. Detection logic is identical to what the camera
/// path will use — only the background changes.
///
/// <p>Mirrors the web frontend's `/ar` page (CompassHud, HorizonLine,
/// AircraftArLabel composed by ArOverlay).
class ARScreen extends ConsumerStatefulWidget {
  const ARScreen({super.key});

  @override
  ConsumerState<ARScreen> createState() => _ARScreenState();
}

class _ARScreenState extends ConsumerState<ARScreen> {
  StreamSubscription<MagnetometerEvent>? _magSub;
  StreamSubscription<AccelerometerEvent>? _accSub;

  /// Compass heading in degrees [0, 360).
  double _heading = 0;

  /// Pitch above horizon — derived from the accelerometer.
  double _pitch = 0;

  /// Roll — used by the horizon line.
  double _roll = 0;

  Position? _userPos;
  String? _sensorError;
  DateTime _lastSetState = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _initLocation();
    _initSensors();
  }

  @override
  void dispose() {
    _magSub?.cancel();
    _accSub?.cancel();
    super.dispose();
  }

  Future<void> _initLocation() async {
    try {
      final perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      if (mounted) setState(() => _userPos = pos);
    } catch (e) {
      if (mounted) setState(() => _sensorError = 'Location: $e');
    }
  }

  void _initSensors() {
    try {
      _magSub = magnetometerEventStream().listen(
        (e) {
          // Heading from magnetic field components — atan2(y, x) gives
          // the bearing in radians, +90° offset because the device's
          // y axis points "up" in portrait. Throttled to 10 Hz to keep
          // setState cost reasonable.
          final raw = math.atan2(e.y, e.x) * 180 / math.pi + 90;
          final h = (raw + 360) % 360;
          _maybeUpdate(() => _heading = h);
        },
        onError: (e) {
          if (mounted) setState(() => _sensorError = 'Compass: $e');
        },
      );

      _accSub = accelerometerEventStream().listen(
        (e) {
          // Approximate pitch + roll from gravity components. Best when
          // the user holds the phone roughly vertical (the AR use case).
          final pitch =
              math.atan2(-e.z, math.sqrt(e.x * e.x + e.y * e.y)) *
              180 /
              math.pi;
          final roll = math.atan2(e.x, e.y) * 180 / math.pi;
          _maybeUpdate(() {
            _pitch = pitch;
            _roll = roll;
          });
        },
        onError: (e) {
          if (mounted) setState(() => _sensorError = 'Tilt: $e');
        },
      );
    } catch (e) {
      if (mounted) setState(() => _sensorError = '$e');
    }
  }

  /// Throttle setState to ~10 Hz — sensors stream at ~50 Hz but UI
  /// updates that fast burn battery without user-visible benefit.
  void _maybeUpdate(VoidCallback apply) {
    final now = DateTime.now();
    if (now.difference(_lastSetState).inMilliseconds < 100) return;
    _lastSetState = now;
    if (mounted) setState(apply);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primary : UiConstants.lightPrimary;

    final asyncFlights = ref.watch(aircraftStreamProvider);
    final flights = asyncFlights.value ?? const <String, AircraftState>{};

    final detected = (_userPos == null || flights.isEmpty)
        ? const <DetectedAircraft>[]
        : ARAircraftDetector.detect(
            userPos: LatLng(_userPos!.latitude, _userPos!.longitude),
            compassHeading: _heading,
            tiltAngle: _pitch.clamp(-90, 90),
            aircraft: flights.values.toList(growable: false),
          );

    return Scaffold(
      backgroundColor: Colors.black,
      // AR mixes camera + sensor + math in real time; the closest thing
      // in this app to "many ways to crash on bad data". Wrap in an
      // ErrorBoundary so a sensor / camera / detector blowup surfaces
      // as a recoverable section instead of taking the whole screen.
      body: ErrorBoundary(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Camera placeholder — gradient sky. Replaced by the live
            // CameraPreview when the platform-specific feed is wired in.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF1a2a3a), Color(0xFF0a1520)],
                ),
              ),
            ),

          // Horizon line — translates with pitch + roll.
          HorizonLine(pitchDeg: _pitch, rollDeg: _roll),

          // Aircraft labels — one per detected flight.
          ..._buildAircraftLabels(detected, primary),

          // Crosshair — aiming reticle at screen center.
          IgnorePointer(
            child: Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: primary.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primary,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Top bar + compass hud.
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: GlassPanel(
                          padding: const EdgeInsets.all(8),
                          borderRadius: 10,
                          child: Icon(
                            Icons.arrow_back_rounded,
                            size: 18,
                            color: primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      NeonText(
                        text: context.s.arMode,
                        fontSize: 14,
                        color: primary,
                        glowRadius: isDark ? 8 : 0,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                CompassHud(headingDeg: _heading),
              ],
            ),
          ),

          // Bottom telemetry footer — heading / pitch / detected count.
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: GlassPanel(
                  borderRadius: 12,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      _Stat(label: 'HDG', value: '${_heading.round()}°'),
                      const SizedBox(width: 18),
                      _Stat(label: 'PITCH', value: '${_pitch.round()}°'),
                      const SizedBox(width: 18),
                      _Stat(
                        label: 'IN VIEW',
                        value: detected.length.toString(),
                      ),
                      const Spacer(),
                      if (_sensorError != null)
                        Tooltip(
                          message: _sensorError!,
                          child: const Icon(
                            Icons.warning_amber_rounded,
                            size: 16,
                            color: AppColors.warning,
                          ),
                        )
                      else
                        Icon(
                          _userPos == null
                              ? Icons.gps_off_rounded
                              : Icons.gps_fixed_rounded,
                          size: 16,
                          color: _userPos == null
                              ? AppColors.textMuted
                              : AppColors.success,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAircraftLabels(
    List<DetectedAircraft> detected,
    Color primary,
  ) {
    return [
      for (final d in detected)
        LayoutBuilder(
          builder: (ctx, constraints) {
            final x = (d.screenXFraction * constraints.maxWidth).clamp(
              20.0,
              constraints.maxWidth - 100,
            );
            final y = (d.screenYFraction * constraints.maxHeight).clamp(
              60.0,
              constraints.maxHeight - 80,
            );
            return Positioned(
              left: x,
              top: y,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: primary.withValues(alpha: 0.45),
                    width: 0.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.aircraft.callsign?.trim() ?? d.aircraft.icao24,
                      style: TextStyle(
                        fontFamily: UiConstants.headingFont,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: primary,
                      ),
                    ),
                    Text(
                      '${d.distanceKm.toStringAsFixed(0)} km · '
                      '${d.elevationDeg.toStringAsFixed(0)}°',
                      style: TextStyle(
                        fontFamily: UiConstants.bodyFont,
                        fontSize: 8,
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
    ];
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: UiConstants.headingFont,
            fontSize: 8,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontFamily: UiConstants.headingFont,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}
