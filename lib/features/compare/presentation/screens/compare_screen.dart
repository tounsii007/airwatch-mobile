import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:airwatch_mobile/core/constants/airline_database.dart';
import 'package:airwatch_mobile/core/constants/conversion_constants.dart';
import 'package:airwatch_mobile/core/constants/ui_constants.dart';
import 'package:airwatch_mobile/core/theme/app_colors.dart';
import 'package:airwatch_mobile/core/widgets/glass_panel.dart';
import 'package:airwatch_mobile/features/map/data/models/aircraft_state.dart';
import 'package:airwatch_mobile/features/map/presentation/providers/flight_providers.dart';

/// Side-by-side flight comparison.
///
/// <p>Mirrors the web frontend's `/compare` page — two flight pickers,
/// then a stat grid (altitude, speed, distance, vertical rate) with
/// horizontal bar visuals. Pickers search the live flight feed by
/// callsign/icao24 substring; users can clear and pick again to swap
/// either slot. Empty-state hints at the next action.
class CompareScreen extends ConsumerStatefulWidget {
  const CompareScreen({super.key});

  @override
  ConsumerState<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends ConsumerState<CompareScreen> {
  AircraftState? _flightA;
  AircraftState? _flightB;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primary : UiConstants.lightPrimary;
    final asyncFlights = ref.watch(aircraftStreamProvider);
    final liveAircraft = asyncFlights.value ?? const <String, AircraftState>{};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compare flights'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            // Status badge — "X / 2 selected".
            _StatusBadge(
              count: (_flightA != null ? 1 : 0) + (_flightB != null ? 1 : 0),
              ready: _flightA != null && _flightB != null,
              primary: primary,
            ),
            const SizedBox(height: 12),

            // Two pickers side by side.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _FlightPicker(
                    value: _flightA,
                    onSelect: (ac) => setState(() => _flightA = ac),
                    onClear: () => setState(() => _flightA = null),
                    liveAircraft: liveAircraft,
                    primary: primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _FlightPicker(
                    value: _flightB,
                    onSelect: (ac) => setState(() => _flightB = ac),
                    onClear: () => setState(() => _flightB = null),
                    liveAircraft: liveAircraft,
                    primary: primary,
                  ),
                ),
              ],
            ),

            // Stats grid — only when both slots filled.
            if (_flightA != null && _flightB != null) ...[
              const SizedBox(height: 16),
              _StatsGrid(a: _flightA!, b: _flightB!, primary: primary),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.count,
    required this.ready,
    required this.primary,
  });
  final int count;
  final bool ready;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final color = ready ? AppColors.success : AppColors.textMuted;
    final text = ready ? '2 flights · ready to compare' : '$count / 2 selected';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.45), width: 0.5),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          fontFamily: UiConstants.headingFont,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
          color: color,
        ),
      ),
    );
  }
}

class _FlightPicker extends StatefulWidget {
  const _FlightPicker({
    required this.value,
    required this.onSelect,
    required this.onClear,
    required this.liveAircraft,
    required this.primary,
  });

  final AircraftState? value;
  final ValueChanged<AircraftState> onSelect;
  final VoidCallback onClear;
  final Map<String, AircraftState> liveAircraft;
  final Color primary;

  @override
  State<_FlightPicker> createState() => _FlightPickerState();
}

class _FlightPickerState extends State<_FlightPicker> {
  final _ctl = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  List<AircraftState> _results() {
    if (_q.length < 2) return const [];
    final query = _q.trim().toUpperCase();
    final out = <AircraftState>[];
    for (final ac in widget.liveAircraft.values) {
      if (out.length >= 8) break;
      final cs = (ac.callsign ?? '').toUpperCase();
      final hex = ac.icao24.toUpperCase();
      if (cs.contains(query) || hex.contains(query)) {
        out.add(ac);
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.value;
    if (v != null) {
      final airline = resolveAirline(v.callsign);
      return GlassPanel(
        padding: const EdgeInsets.all(10),
        borderRadius: 10,
        child: Column(
          children: [
            Text(
              v.callsign?.trim().isNotEmpty == true
                  ? v.callsign!
                  : v.icao24.toUpperCase(),
              style: TextStyle(
                fontFamily: UiConstants.headingFont,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: widget.primary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            if (airline != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  airline.name,
                  style: const TextStyle(
                    fontFamily: UiConstants.bodyFont,
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () {
                _ctl.clear();
                _q = '';
                widget.onClear();
              },
              behavior: HitTestBehavior.opaque,
              child: const Text(
                'REMOVE',
                style: TextStyle(
                  fontFamily: UiConstants.headingFont,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                  color: AppColors.error,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final results = _results();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassPanel(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          borderRadius: 10,
          child: Row(
            children: [
              const Icon(
                Icons.search_rounded,
                size: 14,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: TextField(
                  controller: _ctl,
                  onChanged: (v) => setState(() => _q = v),
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(
                    fontFamily: UiConstants.bodyFont,
                    fontSize: 12,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    hintText: 'Callsign / ICAO24',
                    hintStyle: TextStyle(
                      fontFamily: UiConstants.bodyFont,
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        for (final ac in results)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: GestureDetector(
              onTap: () {
                widget.onSelect(ac);
                _ctl.clear();
                _q = '';
                setState(() {});
              },
              behavior: HitTestBehavior.opaque,
              child: GlassPanel(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                borderRadius: 8,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        ac.callsign?.trim().isNotEmpty == true
                            ? ac.callsign!
                            : ac.icao24.toUpperCase(),
                        style: TextStyle(
                          fontFamily: UiConstants.headingFont,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: widget.primary,
                        ),
                      ),
                    ),
                    if (ac.originCountry != null &&
                        ac.originCountry!.isNotEmpty)
                      Text(
                        ac.originCountry!,
                        style: const TextStyle(
                          fontFamily: UiConstants.bodyFont,
                          fontSize: 9,
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.a, required this.b, required this.primary});
  final AircraftState a;
  final AircraftState b;
  final Color primary;

  int? _altFt(AircraftState ac) => ac.baroAltitude == null
      ? null
      : (ac.baroAltitude! * ConversionConstants.metersToFeet).round();

  int? _spdKts(AircraftState ac) => ac.velocity == null
      ? null
      : (ac.velocity! * ConversionConstants.msToKnots).round();

  int? _verticalFpm(AircraftState ac) => ac.verticalRate == null
      ? null
      : (ac.verticalRate! * ConversionConstants.msToFtPerMin).round();

  /// Great-circle distance for the flight's route, if both endpoints
  /// exist in the airport DB. Returns null otherwise — the row falls
  /// back to "—" rendering.
  int? _routeDistKm(AircraftState ac) {
    // mobile AircraftState doesn't carry depIata/arrIata yet — derive
    // from the airport DB via a callsign-based ICAO lookup if possible.
    // For now we just signal "no route data" so the bar row degrades.
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(10),
      borderRadius: 12,
      child: Column(
        children: [
          _Row(
            label: 'ALTITUDE (ft)',
            valueA: _altFt(a),
            valueB: _altFt(b),
            higherIsBetter: true,
          ),
          _Row(
            label: 'SPEED (kts)',
            valueA: _spdKts(a),
            valueB: _spdKts(b),
            higherIsBetter: true,
          ),
          _Row(
            label: 'V/S (ft/min)',
            valueA: _verticalFpm(a),
            valueB: _verticalFpm(b),
            // V/S can be negative on descent; we don't grade higher = better.
            higherIsBetter: false,
          ),
          _Row(
            label: 'ROUTE (km)',
            valueA: _routeDistKm(a),
            valueB: _routeDistKm(b),
            higherIsBetter: true,
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.valueA,
    required this.valueB,
    required this.higherIsBetter,
  });

  final String label;
  final int? valueA;
  final int? valueB;
  final bool higherIsBetter;

  @override
  Widget build(BuildContext context) {
    final a = valueA ?? 0;
    final b = valueB ?? 0;
    final maxVal = [a.abs(), b.abs(), 1].reduce((x, y) => x > y ? x : y);
    final pctA = maxVal == 0 ? 0.0 : a.abs() / maxVal;
    final pctB = maxVal == 0 ? 0.0 : b.abs() / maxVal;

    final winsA = higherIsBetter ? a >= b : a <= b;
    final colorA = winsA ? AppColors.success : AppColors.textMuted;
    final colorB = winsA ? AppColors.textMuted : AppColors.success;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
          const SizedBox(height: 3),
          Row(
            children: [
              SizedBox(
                width: 56,
                child: Text(
                  valueA == null ? '—' : valueA.toString(),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: UiConstants.headingFont,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: colorA,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: FractionallySizedBox(
                          widthFactor: pctA,
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: colorA.withValues(alpha: 0.55),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                bottomLeft: Radius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: pctB,
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: colorB.withValues(alpha: 0.55),
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(4),
                                bottomRight: Radius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 56,
                child: Text(
                  valueB == null ? '—' : valueB.toString(),
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontFamily: UiConstants.headingFont,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: colorB,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
