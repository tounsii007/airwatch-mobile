import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:airwatch_mobile/core/constants/airline_database.dart';
import 'package:airwatch_mobile/core/constants/conversion_constants.dart';
import 'package:airwatch_mobile/core/constants/ui_constants.dart';
import 'package:airwatch_mobile/core/l10n/app_strings.dart';
import 'package:airwatch_mobile/core/l10n/country_translations.dart';
import 'package:airwatch_mobile/core/theme/app_colors.dart';
import 'package:airwatch_mobile/core/widgets/glass_panel.dart';
import 'package:airwatch_mobile/core/widgets/stat_card.dart';
import 'package:airwatch_mobile/features/cargo/domain/cargo_filter.dart';
import 'package:airwatch_mobile/features/cargo/domain/cargo_stats.dart';
import 'package:airwatch_mobile/features/map/data/models/aircraft_state.dart';
import 'package:airwatch_mobile/features/map/presentation/providers/flight_providers.dart';

/// Cargo-flight listing — mirrors the web app's `/cargo` page.
///
/// <p>Four-tile stats row + status-filter pills + search bar + rich list
/// of cargo cards. The four stat tiles double as filters: tapping
/// AIRBORNE narrows the list to airborne flights, tapping again returns
/// to ALL. Operators count is informational only.
///
/// <p>Cargo identification: callsign-prefix match against the curated
/// list of cargo carriers (FedEx, UPS, DHL, Atlas, Cargolux, …). Same
/// rules the web uses, kept in lock-step via [cargoAirlineIcaos].
class CargoScreen extends ConsumerStatefulWidget {
  const CargoScreen({super.key});

  @override
  ConsumerState<CargoScreen> createState() => _CargoScreenState();
}

class _CargoScreenState extends ConsumerState<CargoScreen> {
  final _searchController = TextEditingController();
  String _search = '';
  CargoStatusFilter _status = CargoStatusFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    setState(() => _search = value);
  }

  void _toggleStatus(CargoStatusFilter target) {
    setState(() {
      // "Toggle-or-all" behaviour matches the web frontend: tapping the
      // already-active tile returns to ALL, tapping a different tile
      // narrows to that subset.
      _status = _status == target ? CargoStatusFilter.all : target;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(ref.watch(languageProvider));
    final asyncFlights = ref.watch(aircraftStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.cargo),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: asyncFlights.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('${s.errorPrefix}: $e')),
        data: (m) {
          final cargo = m.values.where(isCargoFlight).toList(growable: false);
          // Sort by altitude descending — same default order as the
          // web's `byAltitudeDesc` so a quick scan shows the highest /
          // most-active cargo flights first.
          cargo.sort((a, b) =>
              (b.baroAltitude ?? 0).compareTo(a.baroAltitude ?? 0));
          final stats = computeCargoStats(cargo);
          final filtered = filterCargo(cargo, _search, _status);
          return _buildBody(s, stats, filtered, cargo.isNotEmpty);
        },
      ),
    );
  }

  Widget _buildBody(
    AppStrings s,
    CargoStats stats,
    List<AircraftState> filtered,
    bool hasAnyCargo,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      children: [
        // ── 4-tile stats row (airborne / ground / total / operators).
        //    Three of them are clickable filter chips.
        _StatsRow(stats: stats, status: _status, onToggle: _toggleStatus),
        const SizedBox(height: 12),

        // ── Search input.
        _CargoSearchField(
          controller: _searchController,
          onChanged: _onSearch,
          hint: s.searchCargoHint,
        ),
        const SizedBox(height: 12),

        // ── List heading + count badge.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Text(
                s.cargoFlightsHeader.toUpperCase(),
                style: const TextStyle(
                  fontFamily: UiConstants.headingFont,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.3,
                  color: AppColors.textMuted,
                ),
              ),
              if (filtered.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  filtered.length.toString(),
                  style: const TextStyle(
                    fontFamily: UiConstants.headingFont,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 6),

        // ── List body — empty / loading / data.
        if (!hasAnyCargo)
          _EmptyBox(
            icon: Icons.local_shipping_outlined,
            text: s.noCargoActive,
            hint: s.cargoHint,
          )
        else if (filtered.isEmpty)
          _EmptyBox(
            icon: Icons.search_off_rounded,
            text: s.searchNoResults,
          )
        else
          ...filtered.map((ac) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _CargoCard(
                  aircraft: ac,
                  language: ref.watch(languageProvider),
                ),
              )),
      ],
    );
  }
}

class _StatsRow extends ConsumerWidget {
  const _StatsRow({
    required this.stats,
    required this.status,
    required this.onToggle,
  });

  final CargoStats stats;
  final CargoStatusFilter status;
  final void Function(CargoStatusFilter) onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref.watch(languageProvider));
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => onToggle(CargoStatusFilter.airborne),
            child: Opacity(
              opacity: status == CargoStatusFilter.airborne ||
                      status == CargoStatusFilter.all
                  ? 1.0
                  : 0.5,
              child: StatCard(
                label: s.cargoAirborne,
                value: stats.airborne,
                status: StatCardStatus.success,
                icon: Icons.flight_takeoff_rounded,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: () => onToggle(CargoStatusFilter.ground),
            child: Opacity(
              opacity: status == CargoStatusFilter.ground ||
                      status == CargoStatusFilter.all
                  ? 1.0
                  : 0.5,
              child: StatCard(
                label: s.cargoOnGround,
                value: stats.ground,
                status: StatCardStatus.warning,
                icon: Icons.flight_land_rounded,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: StatCard(
            label: s.cargoOperators,
            value: stats.operators,
            status: StatCardStatus.info,
            icon: Icons.business_rounded,
          ),
        ),
      ],
    );
  }
}

class _CargoSearchField extends StatelessWidget {
  const _CargoSearchField({
    required this.controller,
    required this.onChanged,
    required this.hint,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      borderRadius: 12,
      child: Row(
        children: [
          const Icon(Icons.search_rounded,
              size: 18, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: TextStyle(
                fontFamily: UiConstants.bodyFont,
                fontSize: 14,
                color: isDark ? AppColors.textPrimary : Colors.black87,
              ),
              decoration: InputDecoration(
                isDense: true,
                hintText: hint,
                hintStyle: const TextStyle(
                  fontFamily: UiConstants.bodyFont,
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                controller.clear();
                onChanged('');
              },
              child: const Icon(Icons.close_rounded,
                  size: 16, color: AppColors.textMuted),
            ),
        ],
      ),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  const _EmptyBox({required this.icon, required this.text, this.hint});
  final IconData icon;
  final String text;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(20),
      borderRadius: 14,
      child: Column(
        children: [
          Icon(icon, size: 32, color: AppColors.textMuted),
          const SizedBox(height: 10),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: UiConstants.bodyFont,
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: 6),
            Text(
              hint!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: UiConstants.bodyFont,
                fontSize: 11,
                color: AppColors.textMuted.withValues(alpha: 0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CargoCard extends ConsumerWidget {
  const _CargoCard({required this.aircraft, required this.language});
  final AircraftState aircraft;
  final AppLanguage language;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = aircraft.callsign?.trim().toUpperCase() ?? '—';
    // Look up the operator from the airline database keyed off the
    // first three callsign chars. `resolveAirline` already does that
    // lookup + merges curated overrides, so we get the canonical name
    // (e.g. "Lufthansa Cargo" instead of just "GEC").
    final airlineInfo = resolveAirline(aircraft.callsign);
    final operatorName = airlineInfo?.name ?? '';

    final altMeters = aircraft.baroAltitude;
    final altText = altMeters == null
        ? '—'
        : '${(altMeters * ConversionConstants.metersToFeet / 1000).toStringAsFixed(1)}k ft';
    final spdMs = aircraft.velocity;
    final spdText = spdMs == null
        ? '—'
        : '${(spdMs * ConversionConstants.msToKnots).round()} kts';

    final originCountry = aircraft.originCountry;
    final localizedCountry = (originCountry == null || originCountry.isEmpty)
        ? null
        : localizeCountry(
            originCountry,
            switch (language) {
              AppLanguage.de => 'de',
              AppLanguage.fr => 'fr',
              AppLanguage.en => 'en',
            },
          );
    final cityFromAirport = _maybeCityFromCallsign(cs, language);

    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      borderRadius: 14,
      child: Row(
        children: [
          // Cargo icon — neutral colour because the airline logo isn't
          // reliably available on mobile (no airlineIcao field).
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.30),
              ),
            ),
            child: const Icon(Icons.local_shipping_outlined,
                size: 20, color: AppColors.accent),
          ),
          const SizedBox(width: 12),
          // Title block + status pill.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        cs,
                        style: const TextStyle(
                          fontFamily: UiConstants.headingFont,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: AppColors.primary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _StatusPill(onGround: aircraft.onGround),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  <String>[
                    if (operatorName.isNotEmpty) operatorName,
                    ?cityFromAirport,
                    if (localizedCountry != null && localizedCountry.isNotEmpty)
                      localizedCountry,
                  ].where((e) => e.isNotEmpty).join(' • '),
                  style: const TextStyle(
                    fontFamily: UiConstants.bodyFont,
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Right column: altitude (accent) + speed (muted).
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                altText,
                style: const TextStyle(
                  fontFamily: UiConstants.headingFont,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                spdText,
                style: const TextStyle(
                  fontFamily: UiConstants.bodyFont,
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Best-effort: pull the city from the airport database keyed by the
  /// callsign's airline prefix when the route is known, then localize it.
  /// We don't have dep/arr IATAs on mobile's [AircraftState] yet, so this
  /// remains a no-op for now — kept as a hook for the day the model
  /// gains those fields (mirrors the web's `airportCity(iata)` call).
  String? _maybeCityFromCallsign(String _, AppLanguage _) {
    return null;
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.onGround});
  final bool onGround;

  @override
  Widget build(BuildContext context) {
    final color = onGround ? AppColors.warning : AppColors.success;
    final label = onGround ? 'GND' : 'AIR';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: UiConstants.headingFont,
          fontSize: 8,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: color,
        ),
      ),
    );
  }
}
