import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:airwatch_mobile/features/geofences/presentation/providers/geofence_alerts_provider.dart';
import 'package:airwatch_mobile/features/map/data/models/aircraft_state.dart';
import 'package:airwatch_mobile/features/map/presentation/providers/squawk_alerts_provider.dart';
import 'package:airwatch_mobile/features/notifications/domain/alert.dart';

/// Live aggregated alert list — combines squawk + geofence sources into
/// a single feed for the bell badge / alerts panel.
///
/// <p>Mirrors the web frontend's `alertStore`. Each tick re-derives
/// from the upstream providers; deduplication by `id` means the same
/// alert never appears twice in a single render pass.
final alertsProvider = Provider<List<AppAlert>>((ref) {
  final squawks = ref.watch(squawkAlertsProvider);
  final geoHits = ref.watch(geofenceAlertsProvider);

  final out = <AppAlert>[];

  // Squawks first — they're safety-critical, so they belong at the
  // top of the panel.
  for (final ac in squawks) {
    out.add(
      AppAlert(
        id: 'sq-${ac.icao24}',
        kind: AlertKind.squawk,
        title: _squawkTitle(ac),
        subtitle: 'Emergency squawk · ${ac.callsign?.trim() ?? ac.icao24}',
        firedAt: DateTime.now(),
        targetId: ac.icao24,
      ),
    );
  }

  // Geofence intrusions — one per (fence, aircraft) pair.
  for (final hit in geoHits) {
    final cs = hit.aircraft.callsign?.trim();
    out.add(
      AppAlert(
        id: 'gf-${hit.fence.id}-${hit.aircraft.icao24}',
        kind: AlertKind.geofence,
        title: '${cs ?? hit.aircraft.icao24} entered ${hit.fence.name}',
        subtitle: hit.aircraft.originCountry,
        firedAt: DateTime.now(),
        targetId: hit.aircraft.icao24,
      ),
    );
  }

  return out;
});

/// Headline string for a squawk — different label per emergency code
/// so the user can tell hijack (7500) from radio fail (7600) at a
/// glance. Same wording the web's banner uses.
String _squawkTitle(AircraftState ac) {
  final code = ac.squawk;
  return switch (code) {
    '7500' => 'Unlawful interference (7500)',
    '7600' => 'Radio communication failure (7600)',
    '7700' => 'General emergency (7700)',
    _ => 'Emergency squawk',
  };
}

/// Total alerts — drives the bell-icon badge.
final alertCountProvider = Provider<int>((ref) {
  return ref.watch(alertsProvider).length;
});
