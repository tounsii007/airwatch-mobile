import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'package:airwatch_mobile/core/constants/api_constants.dart';
import 'package:airwatch_mobile/core/l10n/app_strings.dart';
import 'package:airwatch_mobile/core/theme/app_colors.dart';
import 'package:airwatch_mobile/core/widgets/glass_panel.dart';
import 'package:airwatch_mobile/features/map/data/models/aircraft_state.dart';
import 'package:airwatch_mobile/features/map/presentation/providers/flight_providers.dart';

/// Planespotting helper — figures out the user's current position, then
/// shows every flight within a 60 km radius. Two tabs are offered:
/// <ol>
///   <li><b>List</b> — simple textual list, sorted by distance.</li>
///   <li><b>Map</b> — clustered radar view with a 60 km radius ring around
///       the user, mirroring the web app's `/spotting` page.</li>
/// </ol>
///
/// <p>The map uses `flutter_map_marker_cluster` so even dense areas
/// like the London approach (often >100 nearby aircraft on a busy day)
/// stay readable — clusters expand as the user zooms in. Tile rendering
/// honours the active `MapTheme` via the configured tile URLs in
/// [ApiConstants].
class SpottingScreen extends ConsumerStatefulWidget {
  const SpottingScreen({super.key});

  @override
  ConsumerState<SpottingScreen> createState() => _SpottingScreenState();
}

class _SpottingScreenState extends ConsumerState<SpottingScreen> {
  static const double _radiusKm = 60.0;

  Position? _me;
  String?   _error;

  @override
  void initState() {
    super.initState();
    _resolveLocation();
  }

  Future<void> _resolveLocation() async {
    final s = S.of(ref.read(languageProvider));
    try {
      final perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        setState(() => _error = s.spottingPermDenied);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      setState(() => _me = pos);
    } catch (e) {
      setState(() => _error = '${s.spottingPermErrPrefix}: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(ref.watch(languageProvider));

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(s.spotting), backgroundColor: Colors.transparent),
        body: _ErrorState(
            message: _error!, retryLabel: s.spottingTryAgain, onRetry: _resolveLocation),
      );
    }
    if (_me == null) {
      return Scaffold(
        appBar: AppBar(title: Text(s.spotting), backgroundColor: Colors.transparent),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final asyncFlights = ref.watch(aircraftStreamProvider);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(s.spotting),
          backgroundColor: Colors.transparent,
          elevation: 0,
          bottom: TabBar(
            tabs: [
              Tab(icon: const Icon(Icons.list_rounded),   text: s.spottingTabList),
              Tab(icon: const Icon(Icons.radar_rounded),  text: s.spottingTabMap),
            ],
          ),
        ),
        body: asyncFlights.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error:   (e, _) => Center(child: Text('${s.errorPrefix}: $e')),
          data:    (flights) {
            final nearby = _filterNearby(flights.values, _me!);
            return TabBarView(
              children: [
                _NearbyList(items: nearby, emptyText: s.spottingNoNearby),
                _NearbyMap(items: nearby, me: _me!, radiusKm: _radiusKm),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Shared filter — returns flights inside the spotting radius, sorted by
  /// distance. Keeping this in one place means the list and map tabs always
  /// agree on what "nearby" means.
  List<NearbyFlight> _filterNearby(Iterable<AircraftState> flights, Position me) {
    final out = <NearbyFlight>[];
    for (final f in flights) {
      final pos = f.position;
      if (pos == null) continue;
      final dist = haversineKm(me.latitude, me.longitude, pos.latitude, pos.longitude);
      if (dist > _radiusKm) continue;
      final brng = bearingDeg(me.latitude, me.longitude, pos.latitude, pos.longitude);
      out.add(NearbyFlight(flight: f, distanceKm: dist, bearingDeg: brng));
    }
    out.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return out;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Nearby model + math (exported for tests)
// ─────────────────────────────────────────────────────────────────────────────

class NearbyFlight {
  NearbyFlight({required this.flight, required this.distanceKm, required this.bearingDeg});
  final AircraftState flight;
  final double        distanceKm;
  final double        bearingDeg;
}

/// Great-circle distance in kilometres on a spherical Earth (WGS-84 mean).
/// Errors stay below 0.3 % up to 200 km, which is more than adequate for the
/// spotting screen's 60 km horizon. Exported so unit tests can verify it.
double haversineKm(double lat1, double lon1, double lat2, double lon2) {
  const r = 6371.0;
  final dLat = _deg2rad(lat2 - lat1);
  final dLon = _deg2rad(lon2 - lon1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_deg2rad(lat1)) * math.cos(_deg2rad(lat2)) *
          math.sin(dLon / 2) * math.sin(dLon / 2);
  return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

/// Initial-bearing in degrees from (lat1, lon1) toward (lat2, lon2),
/// clockwise from true north [0, 360). Exported so unit tests can verify it.
double bearingDeg(double lat1, double lon1, double lat2, double lon2) {
  final y = math.sin(_deg2rad(lon2 - lon1)) * math.cos(_deg2rad(lat2));
  final x = math.cos(_deg2rad(lat1)) * math.sin(_deg2rad(lat2)) -
      math.sin(_deg2rad(lat1)) * math.cos(_deg2rad(lat2)) *
          math.cos(_deg2rad(lon2 - lon1));
  final brng = _rad2deg(math.atan2(y, x));
  return (brng + 360) % 360;
}

double _deg2rad(double d) => d * math.pi / 180;
double _rad2deg(double r) => r * 180 / math.pi;

// ─────────────────────────────────────────────────────────────────────────────
// Tab bodies
// ─────────────────────────────────────────────────────────────────────────────

class _NearbyList extends StatelessWidget {
  const _NearbyList({required this.items, required this.emptyText});
  final List<NearbyFlight> items;
  final String             emptyText;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(child: Text(emptyText));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _NearbyTile(item: items[i]),
    );
  }
}

class _NearbyTile extends StatelessWidget {
  const _NearbyTile({required this.item});
  final NearbyFlight item;

  @override
  Widget build(BuildContext context) {
    final f = item.flight;
    final alt = f.baroAltitude == null
        ? '—'
        : '${(f.baroAltitude! * 3.281 / 1000).toStringAsFixed(1)}k ft';
    return GlassPanel(
      borderRadius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Transform.rotate(
            angle: item.bearingDeg * math.pi / 180,
            child: const Icon(Icons.navigation_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(f.callsign ?? '—', style: const TextStyle(fontWeight: FontWeight.w700)),
                Text('${item.distanceKm.toStringAsFixed(1)} km · '
                     '${item.bearingDeg.toStringAsFixed(0)}°',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          Text(alt, style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _NearbyMap extends StatelessWidget {
  const _NearbyMap({required this.items, required this.me, required this.radiusKm});

  final List<NearbyFlight> items;
  final Position           me;
  final double             radiusKm;

  @override
  Widget build(BuildContext context) {
    final center = LatLng(me.latitude, me.longitude);

    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: 9.0,
        minZoom: 6.0,
        maxZoom: 14.0,
      ),
      children: [
        // Dark Carto by default — matches the app's neon aesthetic. The map
        // screen has a more elaborate theme switcher; this tab keeps things
        // simple to stay focused on the spotting use case.
        TileLayer(
          urlTemplate: ApiConstants.darkTileUrl,
          userAgentPackageName: 'com.airwatch.mobile',
        ),
        // Spotting radius — shows the 60 km horizon as a translucent disc
        // so the user can see where their listed flights are spatially.
        CircleLayer(
          circles: [
            CircleMarker(
              point: center,
              radius: radiusKm * 1000,           // metres
              useRadiusInMeter: true,
              color: AppColors.primary.withValues(alpha: 0.10),
              borderColor: AppColors.primary.withValues(alpha: 0.45),
              borderStrokeWidth: 1.5,
            ),
          ],
        ),
        // User-position pin.
        MarkerLayer(
          markers: [
            Marker(
              point: center,
              width: 28, height: 28,
              child: const Icon(Icons.my_location, color: Colors.white, size: 22),
            ),
          ],
        ),
        // Clustered flight markers.
        MarkerClusterLayerWidget(
          options: MarkerClusterLayerOptions(
            maxClusterRadius: 60,
            size: const Size(40, 40),
            padding: const EdgeInsets.all(50),
            markers: [
              for (final n in items)
                if (n.flight.position != null)
                  Marker(
                    point: LatLng(n.flight.position!.latitude, n.flight.position!.longitude),
                    width: 28,
                    height: 28,
                    child: Transform.rotate(
                      angle: ((n.flight.trueTrack ?? 0) - 45) * math.pi / 180,
                      child: const Icon(Icons.flight_rounded,
                          size: 22, color: Colors.amberAccent),
                    ),
                  ),
            ],
            builder: (ctx, markers) => DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(blurRadius: 6, color: Colors.black38)],
              ),
              child: Center(
                child: Text('${markers.length}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.retryLabel, required this.onRetry});
  final String       message;
  final String       retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_off, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(retryLabel),
            ),
          ],
        ),
      ),
    );
  }
}
