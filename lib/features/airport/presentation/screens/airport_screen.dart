import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:airwatch_mobile/core/constants/airport_full_database.dart';
import 'package:airwatch_mobile/core/constants/config.dart';
import 'package:airwatch_mobile/core/constants/conversion_constants.dart';
import 'package:airwatch_mobile/core/constants/country_database.dart';
import 'package:airwatch_mobile/core/constants/settings_provider.dart';
import 'package:airwatch_mobile/core/constants/ui_constants.dart';
import 'package:airwatch_mobile/core/l10n/city_translations.dart';
import 'package:airwatch_mobile/core/l10n/country_translations.dart';
import 'package:airwatch_mobile/core/l10n/ui_text.dart';
import 'package:airwatch_mobile/core/l10n/app_strings.dart';
import 'package:airwatch_mobile/core/theme/app_colors.dart';
import 'package:airwatch_mobile/core/utils/flight_code_formatter.dart';
import 'package:airwatch_mobile/core/widgets/glass_panel.dart';
import 'package:airwatch_mobile/core/widgets/neon_text.dart';
import 'package:airwatch_mobile/features/airport/data/popular_airports_provider.dart';
import 'package:airwatch_mobile/features/map/data/models/aircraft_state.dart';
import 'package:airwatch_mobile/features/map/presentation/providers/flight_providers.dart';
import 'airport_detail_screen.dart';

class AirportScreen extends ConsumerStatefulWidget {
  const AirportScreen({super.key});

  @override
  ConsumerState<AirportScreen> createState() => _AirportScreenState();
}

enum _FlightFilter { all, airborne, ground }

class _AirportScreenState extends ConsumerState<AirportScreen> {
  final _controller = TextEditingController();
  String _query = '';
  List<AirportEntry> _suggestions = [];
  _FlightFilter _activeFilter = _FlightFilter.all;

  void _onSearch(String query) {
    _query = query;
    final raw = query.trim();
    final q = raw.toUpperCase();
    if (q.length < 2) {
      setState(() => _suggestions = []);
      return;
    }
    // Resolve a locale-typed country query ("Tunesien" / "Tunisie") to its
    // canonical ISO code so we can also surface every airport in that
    // country, mirroring the web frontend's airport search behaviour.
    // `find` already handles the "USA"/"UK" English aliases and falls
    // through to the de/fr `country_translations.dart` reverse-lookup.
    final countryHit = CountryDatabase.find(raw);
    final countryCode = countryHit?.code.toUpperCase();

    final results = airportFullDatabase.values.where((a) {
      // Exact ICAO match: show even without IATA
      if (a.icao.toUpperCase() == q) return true;
      // For general search: only show airports with IATA codes (commercial airports)
      if (a.iata.isEmpty) return false;
      // Country-code match — covers a typed country name in any locale.
      if (countryCode != null && a.country.toUpperCase() == countryCode) {
        return true;
      }
      // Substring matches across IATA / ICAO / name / city in English.
      if (a.iata.toUpperCase().contains(q) ||
          a.icao.toUpperCase().contains(q) ||
          a.name.toUpperCase().contains(q) ||
          a.city.toUpperCase().contains(q)) {
        return true;
      }
      // Locale-aware city match — typing "Köln" finds CGN, "Nizza" finds
      // NCE, "Mailand" finds MXP. Same helper the web's `filterAirports`
      // uses, lazily seeded on first call.
      return cityNameMatches(a.city, raw) || cityNameMatches(a.name, raw);
    }).take(15).toList();
    setState(() => _suggestions = results);
  }

  String _localizeAirportName(BuildContext context, String name) {
    final airport = context.tr('airport_word');
    final intl = context.tr('international_word');
    return name
        .replaceAll('Airport', airport)
        .replaceAll('International', intl);
  }

  void _selectAirport(String iata, [String? name]) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => AirportDetailScreen(iataCode: iata, name: name),
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primary : UiConstants.lightPrimary;
    final aircraftAsync = ref.watch(aircraftStreamProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.background : UiConstants.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: NeonText(text: context.tr('airports'), fontSize: 20, color: primary,
                  glowRadius: isDark ? 10 : 0),
            ),
            const SizedBox(height: 12),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surface : UiConstants.lightSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? AppColors.glassBorder : UiConstants.lightBorder,
                  ),
                ),
                child: TextField(
                  controller: _controller,
                  onChanged: _onSearch,
                  textCapitalization: TextCapitalization.characters,
                  style: TextStyle(
                    fontFamily: UiConstants.headingFont,
                    fontSize: 14,
                    color: isDark ? AppColors.textPrimary : UiConstants.lightTextPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: context.tr('search_airport_hint'),
                    hintStyle: TextStyle(
                      fontFamily: UiConstants.bodyFont,
                      fontSize: 14,
                      color: isDark ? AppColors.textMuted : UiConstants.lightHintText,
                    ),
                    prefixIcon: Icon(Icons.search_rounded, color: primary),
                    suffixIcon: _query.isNotEmpty
                        ? GestureDetector(
                            onTap: () { _controller.clear(); _onSearch(''); },
                            child: Icon(Icons.close_rounded, size: 20,
                                color: isDark ? AppColors.textMuted : UiConstants.lightTextMuted))
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Content: search results OR default view
            Expanded(
              child: _suggestions.isNotEmpty
                  ? _buildSearchResults(isDark, primary)
                  : _buildDefaultView(isDark, primary, aircraftAsync, settings),
            ),
          ],
        ),
      ),
    );
  }

  // ═══ Search results ═══
  Widget _buildSearchResults(bool isDark, Color primary) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _suggestions.length,
      itemBuilder: (ctx, i) {
        final apt = _suggestions[i];
        return GestureDetector(
          onTap: () => _selectAirport(
            apt.iata.isNotEmpty ? apt.iata : apt.icao,
            apt.name,
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 6),
            child: GlassPanel(
              padding: const EdgeInsets.all(12), borderRadius: 12,
              child: Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: isDark ? 0.15 : 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      apt.iata.isNotEmpty ? apt.iata : apt.icao,
                      style: TextStyle(
                        fontFamily: UiConstants.headingFont,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_localizeAirportName(context, apt.name), style: TextStyle(fontFamily: UiConstants.bodyFont,
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textPrimary : UiConstants.lightTextPrimary),
                      overflow: TextOverflow.ellipsis),
                    Text('${localizeCity(apt.city, ref.watch(languageProvider).name)} • ${localizeCountry(CountryDatabase.displayName(apt.country), ref.watch(languageProvider).name)}', style: TextStyle(
                        fontFamily: UiConstants.bodyFont, fontSize: 12,
                        color: isDark ? AppColors.textSecondary : UiConstants.lightTextSecondary)),
                  ],
                )),
                Icon(Icons.chevron_right_rounded, size: 18,
                    color: isDark ? AppColors.textMuted : UiConstants.lightDisabled),
              ]),
            ),
          ),
        );
      },
    );
  }

  // ═══ Default view: stats + live flights by departure/arrival ═══
  Widget _buildDefaultView(bool isDark, Color primary,
      AsyncValue<Map<String, AircraftState>> aircraftAsync, SettingsState settings) {
    return aircraftAsync.when(
      data: (aircraft) {
        final allFlights = aircraft.values.toList();
        // Sort departures by altitude ascending (just took off = low altitude)
        final departures = allFlights
            .where((a) => !a.onGround && (a.altitude ?? 0) < 5000)
            .toList()
          ..sort((a, b) => (a.altitude ?? 0).compareTo(b.altitude ?? 0));
        // Sort arrivals by altitude ascending (about to land = low altitude)
        final arrivals = allFlights
            .where((a) => !a.onGround && (a.altitude ?? 0) >= 5000)
            .toList()
          ..sort((a, b) => (b.altitude ?? 0).compareTo(a.altitude ?? 0));
        final onGround = allFlights.where((a) => a.onGround).length;

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            // Stats
            Row(children: [
              _Stat(icon: Icons.flight_takeoff_rounded,
                  value: '${allFlights.length - onGround}',
                  label: context.tr('airborne'),
                  color: AppColors.success, isDark: isDark,
                  isActive: _activeFilter == _FlightFilter.airborne,
                  onTap: () => setState(() => _activeFilter =
                      _activeFilter == _FlightFilter.airborne ? _FlightFilter.all : _FlightFilter.airborne)),
              const SizedBox(width: 8),
              _Stat(icon: Icons.flight_land_rounded, value: '$onGround',
                  label: context.tr('on_ground'),
                  color: AppColors.warning, isDark: isDark,
                  isActive: _activeFilter == _FlightFilter.ground,
                  onTap: () => setState(() => _activeFilter =
                      _activeFilter == _FlightFilter.ground ? _FlightFilter.all : _FlightFilter.ground)),
              const SizedBox(width: 8),
              _Stat(icon: Icons.flight_rounded, value: '${allFlights.length}',
                  label: context.tr('total'), color: primary, isDark: isDark,
                  isActive: _activeFilter == _FlightFilter.all,
                  onTap: () => setState(() => _activeFilter = _FlightFilter.all)),
            ]),
            const SizedBox(height: 16),

            // Popular airports quick links
            Text(context.tr('popular_airports'), style: TextStyle(fontFamily: UiConstants.headingFont,
                fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2,
                        color: isDark ? AppColors.textSecondary : UiConstants.lightTextSecondary)),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ref.watch(popularAirportsProvider).when(
                data: (airports) => ListView(
                  scrollDirection: Axis.horizontal,
                  children: airports.map((apt) => GestureDetector(
                    onTap: () => _selectAirport(apt.iata, apt.city),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: isDark ? 0.1 : 0.06),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: primary.withValues(alpha: 0.2)),
                      ),
                      child: Text(apt.iata, style: TextStyle(fontFamily: UiConstants.headingFont,
                          fontSize: 11, fontWeight: FontWeight.w700, color: primary)),
                    ),
                  )).toList(),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 16),

            // Filtered flight list
            if (_activeFilter == _FlightFilter.all || _activeFilter == _FlightFilter.airborne) ...[
              Text(context.tr('recent_departures'), style: TextStyle(fontFamily: UiConstants.headingFont,
                  fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2,
                  color: AppColors.success)),
              const SizedBox(height: 6),
              ...departures.take(10).map((ac) => _FlightTile(
                  aircraft: ac, isDark: isDark, primary: primary, isArrival: false, settings: settings)),
              const SizedBox(height: 16),
              Text(context.tr('cruising_flights'), style: TextStyle(fontFamily: UiConstants.headingFont,
                  fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2,
                  color: AppColors.altitudeHigh)),
              const SizedBox(height: 6),
              ...arrivals.take(10).map((ac) => _FlightTile(
                  aircraft: ac, isDark: isDark, primary: primary, isArrival: true, settings: settings)),
            ],
            if (_activeFilter == _FlightFilter.ground) ...[
              Text(context.tr('on_ground').toUpperCase(), style: TextStyle(fontFamily: UiConstants.headingFont,
                  fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2,
                  color: AppColors.warning)),
              const SizedBox(height: 6),
              ...allFlights.where((a) => a.onGround).take(20).map((ac) => _FlightTile(
                  aircraft: ac, isDark: isDark, primary: primary, isArrival: false, settings: settings)),
            ],
          ],
        );
      },
      loading: () => Center(child: CircularProgressIndicator(color: primary)),
      error: (_, _) => Center(child: Text(context.tr('unable_to_load_data'),
          style: TextStyle(color: isDark ? AppColors.textSecondary : const Color(0xFF6B7280)))),
    );
  }

}

class _Stat extends StatelessWidget {
  final IconData icon; final String value, label;
  final Color color; final bool isDark;
  final bool isActive;
  final VoidCallback? onTap;
  const _Stat({required this.icon, required this.value, required this.label,
      required this.color, required this.isDark, this.isActive = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: isActive ? BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
        ) : null,
        child: GlassPanel(
          padding: const EdgeInsets.all(10), borderRadius: 12,
          child: Column(children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontFamily: UiConstants.headingFont, fontSize: 14,
                fontWeight: FontWeight.w700, color: color)),
            Text(label, style: TextStyle(fontFamily: UiConstants.bodyFont, fontSize: 9,
                color: isDark ? AppColors.textMuted : UiConstants.lightTextMuted, letterSpacing: 1)),
          ]),
        ),
      ),
    ));
  }
}

class _FlightTile extends StatelessWidget {
  final AircraftState aircraft;
  final bool isDark;
  final Color primary;
  final bool isArrival;
  final SettingsState settings;
  const _FlightTile({required this.aircraft, required this.isDark,
      required this.primary, required this.isArrival, required this.settings});

  @override
  Widget build(BuildContext context) {
    final cs = FlightCodeFormatter.displayFlightCode(
      callsign: aircraft.callsign,
      fallback: aircraft.icao24,
    );
    final airline = FlightCodeFormatter.resolveAirline(aircraft.callsign);
    final locale = Localizations.localeOf(context).languageCode;
    final countryFull = localizeCountry(
      CountryDatabase.displayName(aircraft.originCountry),
      locale,
    );
    final alt = aircraft.altitude;
    final altFt = alt != null ? (alt * ConversionConstants.metersToFeet) : 0.0;
    final altColor = altFt < AppConfig.altitudeLowMax ? AppColors.altitudeLow
        : altFt < AppConfig.altitudeMedMax ? AppColors.altitudeMedium : AppColors.altitudeHigh;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: GlassPanel(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        borderRadius: AppConfig.tileBorderRadius,
        child: Row(children: [
          Container(
            width: 4, height: 42,
            decoration: BoxDecoration(
              color: aircraft.onGround ? AppColors.warning : altColor,
              borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(cs, style: TextStyle(fontFamily: UiConstants.headingFont, fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textPrimary : UiConstants.lightTextPrimary)),
                  if (airline != null) ...[
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(airline.name, style: TextStyle(
                          fontFamily: UiConstants.bodyFont, fontSize: 11,
                          color: primary),
                        overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ],
              ),
              Text(countryFull, style: TextStyle(
                  fontFamily: UiConstants.bodyFont, fontSize: 11,
                  color: isDark ? AppColors.textSecondary : UiConstants.lightTextSecondary)),
            ],
          )),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            if (alt != null)
              Text(UiText.formatAltitude(context, settings, alt), style: TextStyle(
                  fontFamily: UiConstants.headingFont, fontSize: 10, fontWeight: FontWeight.w700,
                  color: altColor)),
            if (aircraft.velocity != null)
              Text(UiText.formatSpeed(context, settings, aircraft.velocity), style: TextStyle(
                  fontFamily: UiConstants.bodyFont, fontSize: 11, color: primary)),
          ]),
        ]),
      ),
    );
  }
}
