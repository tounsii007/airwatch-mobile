import 'dart:collection';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:airwatch_mobile/core/l10n/app_strings.dart';
import 'package:airwatch_mobile/core/theme/app_colors.dart';
import 'package:airwatch_mobile/core/theme/chart_theme.dart';
import 'package:airwatch_mobile/core/widgets/glass_panel.dart';
import 'package:airwatch_mobile/features/favorites/data/favorites_repository.dart';
import 'package:airwatch_mobile/features/map/data/models/aircraft_state.dart';
import 'package:airwatch_mobile/features/map/presentation/providers/flight_providers.dart';

/// Personal dashboard — widgetised, reorderable, live-charting.
///
/// <p>Mirrors the spirit of the airwatch-web `/dashboard` page: a grid
/// of independently-useful tiles the user can rearrange (long-press → drag)
/// to suit their workflow. Tile order is persisted in
/// [SharedPreferences] so it survives restarts.
///
/// <h3>Tiles included</h3>
/// <ul>
///   <li><b>Live flights</b> — sparkline of the last 60 backend ticks.</li>
///   <li><b>Saved items</b> — the user's favourites count + visual cue.</li>
///   <li><b>Top airlines</b> — bar chart of the top 5 carriers in the live feed.</li>
///   <li><b>Altitude bands</b> — histogram of low / mid / high traffic.</li>
/// </ul>
///
/// <p>Each widget reads from the existing [aircraftStreamProvider], so
/// the dashboard piggybacks on the same poll the map already runs — no
/// duplicate backend calls.
const _orderKey = 'dashboard.tile.order.v1';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  /// Default tile order. Each id is wired to a builder; the list is the
  /// authoritative ordering and gets persisted on every reorder.
  late List<String> _order = const ['live', 'saved', 'top', 'altitude'];

  /// Sliding-window of recent flight counts — feeds the live sparkline.
  /// Capped at 60 samples (~5 min @ 5 s polling) so memory stays flat.
  final Queue<int> _liveSamples = Queue<int>();

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_orderKey);
    // Only honour the persisted list if every known tile is in it; otherwise
    // a future schema change wouldn't accidentally hide a new tile.
    if (stored != null && stored.toSet().containsAll(_order)) {
      setState(() => _order = List.of(stored));
    }
  }

  Future<void> _saveOrder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_orderKey, _order);
  }

  void _pushSample(int n) {
    _liveSamples.addLast(n);
    while (_liveSamples.length > 60) {
      _liveSamples.removeFirst();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(ref.watch(languageProvider));
    final asyncFlights = ref.watch(aircraftStreamProvider);
    final favorites = ref.watch(favoritesProvider);

    asyncFlights.whenData((m) => _pushSample(m.length));

    // Riverpod 3.x: `value` returns ValueT? (was `valueOrNull` in Riverpod 2.x).
    final flights = asyncFlights.value?.values ?? const <AircraftState>[];

    final builders = <String, Widget Function()>{
      'live': () => _LiveSparklineTile(
        label: s.dashLiveFlights,
        samples: List.unmodifiable(_liveSamples),
      ),
      'saved': () =>
          _SavedTile(label: s.dashSavedItems, count: favorites.length),
      'top': () => _TopAirlinesTile(label: s.dashTopAirlines, flights: flights),
      'altitude': () =>
          _AltitudeHistogramTile(label: s.dashAltBands, flights: flights),
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(s.dashboard),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: ReorderableGridView.count(
          padding: const EdgeInsets.all(12),
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          // Long-press on the tile body to start dragging — the floating
          // proxy is a screenshot of the tile, with a slight elevation so
          // the user clearly sees what they're moving.
          dragWidgetBuilderV2: DragWidgetBuilderV2(
            isScreenshotDragWidget: true,
            builder: (_, child, _) =>
                Material(color: Colors.transparent, elevation: 8, child: child),
          ),
          onReorder: (oldIdx, newIdx) {
            setState(() {
              final id = _order.removeAt(oldIdx);
              _order.insert(newIdx, id);
            });
            _saveOrder();
          },
          children: [
            for (final id in _order)
              KeyedSubtree(
                key: ValueKey(id),
                child: builders[id]?.call() ?? const SizedBox.shrink(),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tile widgets — kept in this file so the dashboard's wiring is in one place.
// Each tile is intentionally self-contained: its data comes from a single
// argument, so reordering and scrolling never causes a tile to refetch.
// ─────────────────────────────────────────────────────────────────────────────

class _LiveSparklineTile extends StatelessWidget {
  const _LiveSparklineTile({required this.label, required this.samples});
  final String label;
  final List<int> samples;

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[
      for (var i = 0; i < samples.length; i++)
        FlSpot(i.toDouble(), samples[i].toDouble()),
    ];
    final current = samples.isEmpty ? '—' : samples.last.toString();

    return _Tile(
      label: label,
      value: current,
      color: AppColors.primary,
      child: spots.length < 2
          ? const SizedBox.shrink()
          : LineChart(
              ChartTheme.lineChart(
                spots: spots,
                primary: AppColors.primary,
                minY: 0,
                enableTooltip: true,
              ),
            ),
    );
  }
}

class _SavedTile extends StatelessWidget {
  const _SavedTile({required this.label, required this.count});
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return _Tile(
      label: label,
      value: count.toString(),
      color: AppColors.accent,
      child: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            const Icon(Icons.flight_rounded, color: AppColors.accent, size: 22),
            Icon(
              Icons.local_airport_rounded,
              color: AppColors.accent.withValues(alpha: 0.7),
              size: 22,
            ),
            Icon(
              Icons.business_rounded,
              color: AppColors.accent.withValues(alpha: 0.5),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _TopAirlinesTile extends StatelessWidget {
  const _TopAirlinesTile({required this.label, required this.flights});
  final String label;
  final Iterable<AircraftState> flights;

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (final f in flights) {
      final cs = f.callsign?.trim() ?? '';
      if (cs.length < 3) continue;
      final icao = cs.substring(0, 3);
      if (RegExp(r'^[A-Z]{3}$').hasMatch(icao)) {
        counts[icao] = (counts[icao] ?? 0) + 1;
      }
    }
    final top = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top5 = top.take(5).toList();

    return _Tile(
      label: label,
      value: top5.isEmpty ? '—' : top5.first.key,
      color: AppColors.success,
      child: top5.length < 2
          ? const SizedBox.shrink()
          : BarChart(
              ChartTheme.barChart(
                values: top5.map((e) => e.value.toDouble()).toList(),
                palette: const [AppColors.success],
                rodWidth: 10,
                enableTooltip: true,
              ),
            ),
    );
  }
}

class _AltitudeHistogramTile extends StatelessWidget {
  const _AltitudeHistogramTile({required this.label, required this.flights});
  final String label;
  final Iterable<AircraftState> flights;

  @override
  Widget build(BuildContext context) {
    // Three altitude bands matching the web app's flight-coloring rule:
    // <10k ft (low), 10-30k ft (mid), >30k ft (high).
    int low = 0, mid = 0, high = 0;
    for (final f in flights) {
      final altMeters = f.baroAltitude;
      if (altMeters == null) continue;
      final ft = altMeters * 3.281;
      if (ft < 10000) {
        low++;
      } else if (ft < 30000) {
        mid++;
      } else {
        high++;
      }
    }
    final total = low + mid + high;

    return _Tile(
      label: label,
      value: total.toString(),
      color: AppColors.info,
      child: total == 0
          ? const SizedBox.shrink()
          : BarChart(
              ChartTheme.barChart(
                values: [low.toDouble(), mid.toDouble(), high.toDouble()],
                palette: const [
                  AppColors.warning,
                  AppColors.success,
                  AppColors.info,
                ],
                rodWidth: 18,
                enableTooltip: true,
              ),
            ),
    );
  }
}

/// Common tile chrome — header (label + KPI) and a flexible chart body.
class _Tile extends StatelessWidget {
  const _Tile({
    required this.label,
    required this.value,
    required this.color,
    required this.child,
  });

  final String label;
  final String value;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              letterSpacing: 1.2,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(child: child),
        ],
      ),
    );
  }
}
