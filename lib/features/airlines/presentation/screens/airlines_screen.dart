import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:airwatch_mobile/core/l10n/app_strings.dart';
import 'package:airwatch_mobile/core/theme/app_colors.dart';
import 'package:airwatch_mobile/core/widgets/aw_page_scaffold.dart';
import 'package:airwatch_mobile/core/widgets/glass_panel.dart';
import 'package:airwatch_mobile/features/map/data/models/aircraft_state.dart';
import 'package:airwatch_mobile/features/map/presentation/providers/flight_providers.dart';

/// Lists the active airlines in the current live flight feed together with
/// their in-the-air flight count. Data is derived from
/// [aircraftStreamProvider] so this screen stays in lock-step with the
/// map — no separate API call.

/// Pure aggregation — given a flight collection, return airline-ICAO →
/// flight count, sorted descending by count. Public so it's directly
/// unit-testable without a Flutter widget tree.
List<MapEntry<String, int>> aggregateByAirlineIcao(
  Iterable<AircraftState> flights,
) {
  final counts = <String, int>{};
  for (final f in flights) {
    final cs = f.callsign?.trim() ?? '';
    if (cs.length < 3) continue;
    final icao = cs.substring(0, 3);
    if (RegExp(r'^[A-Z]{3}$').hasMatch(icao)) {
      counts[icao] = (counts[icao] ?? 0) + 1;
    }
  }
  final entries = counts.entries.toList()
    ..sort((a, b) {
      // Primary sort: descending count. Tie-breaker: ascending ICAO so the
      // result is deterministic across runs (otherwise we'd see flapping in
      // the UI when two airlines have the same count).
      final byCount = b.value.compareTo(a.value);
      if (byCount != 0) return byCount;
      return a.key.compareTo(b.key);
    });
  return entries;
}

class AirlinesScreen extends ConsumerWidget {
  const AirlinesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);
    final s = S.of(language);
    final asyncFlights = ref.watch(aircraftStreamProvider);

    // Compute a live-count subtitle BEFORE the asyncFlights.when chain so
    // the scaffold's badge stays in sync with the body's data — same
    // pattern airwatch-web uses on /airlines (count is part of the page
    // header, not the list itself).
    final liveCount = asyncFlights.maybeWhen(
      data: (flights) => aggregateByAirlineIcao(flights.values).length,
      orElse: () => 0,
    );

    return AwPageScaffold(
      title: s.airlines,
      subtitle: liveCount > 0
          ? AwPageBadge(label: '$liveCount ${s.airlinesCarriers.toUpperCase()}')
          : null,
      child: asyncFlights.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('${s.errorPrefix}: $e')),
        data: (flights) => _buildList(s, flights.values),
      ),
    );
  }

  Widget _buildList(AppStrings s, Iterable<AircraftState> flights) {
    final sorted = aggregateByAirlineIcao(flights);

    if (sorted.isEmpty) {
      return Center(child: Text(s.noAirlinesActive));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: sorted.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final entry = sorted[i];
        return GlassPanel(
          borderRadius: 14,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  entry.key.substring(0, entry.key.length.clamp(0, 3)),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  entry.key,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${entry.value} '
                  '${entry.value == 1 ? s.airlinesFlightOne : s.airlinesFlightMany}',
                  style: const TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
