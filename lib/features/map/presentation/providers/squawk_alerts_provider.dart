import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:airwatch_mobile/core/theme/app_colors.dart';
import 'package:airwatch_mobile/features/map/data/models/aircraft_state.dart';
import 'package:airwatch_mobile/features/map/presentation/providers/flight_providers.dart';

/// Three ICAO emergency squawk codes that ATC trains pilots on:
///
/// <ul>
///   <li><b>7500</b> — Hijack / unlawful interference.</li>
///   <li><b>7600</b> — Radio (com) failure.</li>
///   <li><b>7700</b> — General emergency (mayday).</li>
/// </ul>
///
/// <p>Mirrors `EMERGENCY_SQUAWKS` in `useSquawkAlerts.ts` on the web.
const Set<String> emergencySquawks = {'7500', '7600', '7700'};

/// Short-uppercase label for the banner pill.
String squawkLabel(String squawk) {
  return switch (squawk) {
    '7700' => 'EMERGENCY',
    '7600' => 'RADIO FAIL',
    '7500' => 'HIJACK',
    _ => squawk,
  };
}

/// Banner pill background colour. Uses the app's existing semantic
/// palette so dark/light themes stay consistent.
Color squawkColor(String squawk) {
  return switch (squawk) {
    '7700' => AppColors.error,
    '7500' => AppColors.warning, // hijack — slightly cooler than 7700
    '7600' => AppColors.altitudeMedium, // radio fail — amber
    _ => AppColors.primary,
  };
}

/// Reactive provider that emits every currently-airborne aircraft on an
/// emergency squawk.
///
/// <p>Mirrors the spirit of the web's `useSquawkAlerts` hook — derived
/// state on top of the live flight feed, no separate API call. The
/// banner widget consumes this to render a top-of-screen pulsing strip.
///
/// <p>Note: this provider is INTENTIONALLY pure-derived (no side
/// effects). The web version had an in-hook `addAlert` write into a
/// global alert store on first sighting; on mobile we plug that into a
/// dedicated history provider in a follow-up commit. Keeping the hot
/// path side-effect-free here makes the banner cheaper to render on
/// every flight tick.
final squawkAlertsProvider = Provider<List<AircraftState>>((ref) {
  final asyncAircraft = ref.watch(aircraftStreamProvider);
  final m = asyncAircraft.value;
  if (m == null) return const [];

  final out = <AircraftState>[];
  for (final ac in m.values) {
    final sq = ac.squawk;
    if (sq != null && emergencySquawks.contains(sq)) {
      out.add(ac);
    }
  }
  return out;
});
