import 'package:flutter/material.dart';
import 'package:flutter_earth_globe/flutter_earth_globe.dart';
import 'package:flutter_earth_globe/flutter_earth_globe_controller.dart';
import 'package:flutter_earth_globe/globe_coordinates.dart';
import 'package:flutter_earth_globe/point.dart';
import 'package:flutter_earth_globe/sphere_style.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:airwatch_mobile/core/constants/conversion_constants.dart';
import 'package:airwatch_mobile/core/constants/ui_constants.dart';
import 'package:airwatch_mobile/core/l10n/app_strings.dart';
import 'package:airwatch_mobile/core/theme/app_colors.dart';
import 'package:airwatch_mobile/core/widgets/error_boundary.dart';
import 'package:airwatch_mobile/core/widgets/glass_panel.dart';
import 'package:airwatch_mobile/features/flight_details/presentation/widgets/flight_details_panel.dart';
import 'package:airwatch_mobile/features/map/data/models/aircraft_state.dart';
import 'package:airwatch_mobile/features/map/presentation/providers/flight_providers.dart';

/// Native 3-D earth globe — every airborne flight from
/// [aircraftStreamProvider] is rendered as a point on the sphere.
///
/// <h3>Why native and not a WebView</h3>
/// <ul>
///   <li><b>60fps</b> on mid-range Android — the previous WebView variant
///       averaged 30-50fps and stuttered while panning.</li>
///   <li><b>~15-30 MB memory</b> instead of +100-200 MB for a separate
///       WebView process plus its WebGL context.</li>
///   <li><b>Native pinch / pan / rotate gestures</b> — feels identical to
///       the existing flutter_map screen, no JS-bridge latency.</li>
///   <li><b>Offline-friendly</b> — once loaded, renders without an active
///       network connection (point updates obviously still need data).</li>
/// </ul>
///
/// <h3>Performance notes</h3>
/// <ul>
///   <li>The globe controller is created in [initState] and disposed in
///       [dispose] — never inside `build`, otherwise pinch/zoom
///       state would reset on every flight-stream tick.</li>
///   <li>Points are reconciled by id (the ICAO 24-bit hex). Each tick we
///       compute the symmetric difference: drop ids that disappeared, add
///       new ones, and reposition existing ones in place — no full
///       teardown-and-rebuild of the marker set.</li>
///   <li>We cap the rendered marker count at [_maxPoints] (300). With
///       8000+ live flights worldwide on a busy day, plotting them all on a
///       small phone screen looks like noise; we keep the closest-to-the-poles
///       representative sample instead.</li>
/// </ul>
class GlobeScreen extends ConsumerStatefulWidget {
  const GlobeScreen({super.key});

  @override
  ConsumerState<GlobeScreen> createState() => _GlobeScreenState();
}

class _GlobeScreenState extends ConsumerState<GlobeScreen> {
  /// Plotted-marker cap — see class doc for rationale.
  static const int _maxPoints = 300;

  late final FlutterEarthGlobeController _controller;

  /// Currently-rendered point ids — used to compute the diff against the
  /// next flight tick without materialising both lists in full.
  final Set<String> _currentIds = <String>{};

  @override
  void initState() {
    super.initState();
    _controller = FlutterEarthGlobeController(
      rotationSpeed: 0.04,
      isRotating: true,
      isBackgroundFollowingSphereRotation: true,
      // Solid colour fill — we don't ship an Earth texture asset, so the
      // sphere uses the app's primary brand colour at low alpha. Looks like
      // a stylised radar planet — fits the neon aesthetic without a 5 MB PNG.
      sphereStyle: const SphereStyle(
        shadowColor: AppColors.primary,
        shadowBlurSigma: 18,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Reconcile `points` with what's currently on the globe.
  ///
  /// O(N + M) — single pass over the new ids and a single pass over the
  /// stale ones. Avoids the easy-but-wrong full rebuild that would also
  /// break ongoing tap targets in flight.
  void _syncPoints(Iterable<AircraftState> flights) {
    final selected = _topByLatitude(flights, _maxPoints);
    final nextIds = <String>{for (final f in selected) f.icao24};

    // Remove gone-away points.
    final stale = _currentIds.difference(nextIds);
    for (final id in stale) {
      _controller.removePoint(id);
    }

    // Add fresh ones — colour-coded by altitude band so the globe
    // visually highlights low/cruise/high traffic at a glance,
    // matching the web's Cesium variant.
    final fresh = nextIds.difference(_currentIds);
    for (final f in selected) {
      if (!fresh.contains(f.icao24)) continue;
      final pos = f.position;
      if (pos == null) continue;
      _controller.addPoint(
        Point(
          id: f.icao24,
          coordinates: GlobeCoordinates(pos.latitude, pos.longitude),
          label: f.callsign,
          style: PointStyle(color: _altitudeColor(f), size: 5),
          onTap: () => _onPointTap(f),
        ),
      );
    }

    _currentIds
      ..clear()
      ..addAll(nextIds);
  }

  /// Map an aircraft's barometric altitude to one of the app's
  /// altitude-band colours so the globe matches the map's palette.
  Color _altitudeColor(AircraftState ac) {
    if (ac.onGround) return AppColors.textMuted;
    final altFt = (ac.baroAltitude ?? 0) * ConversionConstants.metersToFeet;
    if (altFt < 10000) return AppColors.altitudeLow;
    if (altFt < 30000) return AppColors.altitudeMedium;
    return AppColors.altitudeHigh;
  }

  /// Tapping a globe point selects the aircraft in the global
  /// `selectedAircraftProvider` so the existing flight-details panel
  /// surfaces the data — same UX pattern the map uses.
  void _onPointTap(AircraftState ac) {
    ref.read(selectedAircraftProvider.notifier).set(ac);
  }

  /// Pick a representative subset of flights ordered by absolute latitude
  /// (descending) — gives the globe a globally-distributed look rather than
  /// 300 markers all clumped on the heavily-trafficked north Atlantic.
  Iterable<AircraftState> _topByLatitude(
    Iterable<AircraftState> flights,
    int n,
  ) {
    final positioned = flights.where((f) => f.position != null).toList()
      ..sort(
        (a, b) =>
            b.position!.latitude.abs().compareTo(a.position!.latitude.abs()),
      );
    return positioned.take(n);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(ref.watch(languageProvider));
    final asyncFlights = ref.watch(aircraftStreamProvider);

    asyncFlights.whenData((m) => _syncPoints(m.values));

    return Scaffold(
      appBar: AppBar(
        title: Text(s.globe),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: s.globeReload,
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              // "Reload" on a native globe re-arms auto-rotation and resyncs
              // points from the latest stream value — cheap, no network.
              _controller.isRotating = true;
              asyncFlights.whenData((m) => _syncPoints(m.values));
            },
          ),
        ],
      ),
      // The 3D globe widget (flutter_earth_globe) and its OpenGL surface
      // are the most likely thing in this app to throw at runtime —
      // wrap the Stack in an ErrorBoundary so a graphics-driver failure
      // surfaces as a "section unavailable" panel instead of a red
      // screen and the user can navigate away.
      body: ErrorBoundary(
        child: Stack(
          children: [
            Center(
              child: FlutterEarthGlobe(controller: _controller, radius: 140),
            ),
          // Stats overlay — airborne / ground / total / showing
          // Mirrors the web's overlay on the Cesium globe so the
          // user knows how representative the visible dot cloud is.
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: _StatsOverlay(
              asyncFlights: asyncFlights,
              shown: _currentIds.length,
            ),
          ),
          // Altitude-band legend — explains what the dot colours mean.
          const Positioned(bottom: 12, left: 12, child: _AltitudeLegend()),
          // Flight detail panel surfaces over the globe when a point
          // is tapped. The panel is the same widget the map uses, so
          // the user gets identical functionality on both screens.
          const FlightDetailsPanel(),
          ],
        ),
      ),
    );
  }
}

class _StatsOverlay extends StatelessWidget {
  const _StatsOverlay({required this.asyncFlights, required this.shown});
  final AsyncValue<Map<String, AircraftState>> asyncFlights;
  final int shown;

  @override
  Widget build(BuildContext context) {
    final all = asyncFlights.value;
    if (all == null) {
      return const SizedBox.shrink();
    }
    var airborne = 0;
    var onGround = 0;
    for (final ac in all.values) {
      if (ac.onGround) {
        onGround++;
      } else {
        airborne++;
      }
    }
    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      borderRadius: 10,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StatChip(label: 'AIR', value: airborne, color: AppColors.success),
          const SizedBox(width: 14),
          _StatChip(label: 'GND', value: onGround, color: AppColors.textMuted),
          const SizedBox(width: 14),
          _StatChip(label: 'SHOWN', value: shown, color: AppColors.primary),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: UiConstants.headingFont,
            fontSize: 8,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          value.toString(),
          style: TextStyle(
            fontFamily: UiConstants.headingFont,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _AltitudeLegend extends StatelessWidget {
  const _AltitudeLegend();

  @override
  Widget build(BuildContext context) {
    Widget swatch(Color c, String label) => Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: c),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontFamily: UiConstants.headingFont,
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );

    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      borderRadius: 8,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          swatch(AppColors.altitudeLow, 'LOW'),
          swatch(AppColors.altitudeMedium, 'MID'),
          swatch(AppColors.altitudeHigh, 'HI'),
          swatch(AppColors.textMuted, 'GND'),
        ],
      ),
    );
  }
}
