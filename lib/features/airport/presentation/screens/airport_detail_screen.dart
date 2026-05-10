import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:airwatch_mobile/core/constants/airport_full_database.dart';
import 'package:airwatch_mobile/core/constants/country_database.dart';
import 'package:airwatch_mobile/core/constants/ui_constants.dart';
import 'package:airwatch_mobile/core/l10n/ui_text.dart';
import 'package:airwatch_mobile/core/theme/app_colors.dart';
import 'package:airwatch_mobile/core/widgets/glass_panel.dart';
import 'package:airwatch_mobile/core/widgets/neon_text.dart';
import 'package:airwatch_mobile/features/airport/data/models/airport_detail_models.dart';
import 'package:airwatch_mobile/features/airport/data/recent_airports_repository.dart';
import 'package:airwatch_mobile/features/airport/presentation/widgets/airport_schedule_tile.dart';
import 'package:airwatch_mobile/features/airport/data/services/airport_details_service.dart';
import 'package:airwatch_mobile/features/airport/presentation/widgets/atc_audio_panel.dart';
import 'package:airwatch_mobile/features/airport/presentation/widgets/metar_panel.dart';
import 'package:airwatch_mobile/features/airport/presentation/widgets/notam_panel.dart';

/// Sort modes for the schedule tabs. Mirrors the web's `SortBy` union.
enum _ScheduleSort { time, delay }

/// Full airport detail screen with weather, local time, and live schedules.
class AirportDetailScreen extends ConsumerStatefulWidget {
  final String iataCode;
  final String? name;

  const AirportDetailScreen({super.key, required this.iataCode, this.name});

  @override
  ConsumerState<AirportDetailScreen> createState() =>
      _AirportDetailScreenState();
}

class _AirportDetailScreenState extends ConsumerState<AirportDetailScreen>
    with SingleTickerProviderStateMixin {
  /// Active sort mode for both departures + arrivals.
  _ScheduleSort _sortMode = _ScheduleSort.time;
  final _service = AirportDetailsService();

  late TabController _tabController;
  Timer? _clockTimer;
  AirportInfo? _airportInfo;
  WeatherInfo? _weather;
  List<AirportScheduleFlight> _departures = [];
  List<AirportScheduleFlight> _arrivals = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _refreshError = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Three tabs: DEP / ARR / INFO. The INFO tab carries the MetarPanel
    // + NotamPanel — mirrors the airwatch-web airport detail page where
    // those panels live above the schedule grid. On mobile we pack them
    // into a tab so the schedules don't get pushed off the bottom of
    // the viewport on smaller phones.
    _tabController = TabController(length: 3, vsync: this);
    _loadAll();
    // Update clock every second for real-time display
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    await _loadBundle();
  }

  Future<void> _refresh() async {
    if (_isRefreshing) {
      return;
    }

    setState(() {
      _isRefreshing = true;
      _refreshError = false;
    });

    try {
      await _loadBundle();
    } catch (_) {
      if (mounted) {
        setState(() => _refreshError = true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _loadBundle() async {
    try {
      final bundle = await _service.load(widget.iataCode);
      if (mounted) {
        setState(() {
          _airportInfo = bundle.airport;
          _weather = bundle.weather;
          _departures = bundle.departures;
          _arrivals = bundle.arrivals;
          _isLoading = false;
        });
        // Record the visit for the recent-airports list — only after
        // a successful load so we don't pollute the history with
        // failed lookups. City + country resolve through the
        // bundled `airportFullDatabase` so the recent list survives
        // a backend outage.
        final dbEntry = lookupAirportByIata(widget.iataCode);
        ref
            .read(recentAirportsProvider.notifier)
            .record(
              iata: widget.iataCode,
              city: dbEntry?.city,
              country: dbEntry?.country,
            );
      }
    } on DioException catch (e) {
      debugPrint('[Airport] Load info failed: ${e.message}');
    } catch (e) {
      debugPrint('[Airport] Info error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primary : UiConstants.lightPrimary;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.background
          : UiConstants.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark, primary),
            if (_airportInfo != null || _weather != null)
              _buildInfoRow(isDark, primary),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surface : UiConstants.lightSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark
                        ? AppColors.glassBorder
                        : UiConstants.lightBorder,
                  ),
                ),
                child: TextField(
                  onChanged: (value) =>
                      setState(() => _searchQuery = value.toUpperCase()),
                  style: TextStyle(
                    fontFamily: UiConstants.bodyFont,
                    fontSize: 13,
                    color: isDark
                        ? AppColors.textPrimary
                        : UiConstants.lightTextPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: context.tr('search_flights'),
                    hintStyle: TextStyle(
                      fontFamily: UiConstants.bodyFont,
                      fontSize: 13,
                      color: isDark
                          ? AppColors.textMuted
                          : UiConstants.lightHintText,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: primary,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
            TabBar(
              controller: _tabController,
              labelColor: primary,
              unselectedLabelColor: isDark
                  ? AppColors.textMuted
                  : UiConstants.lightTextMuted,
              indicatorColor: primary,
              labelStyle: const TextStyle(
                fontFamily: UiConstants.headingFont,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
              tabs: [
                Tab(text: '${context.s.departures} (${_departures.length})'),
                Tab(text: '${context.s.arrivals} (${_arrivals.length})'),
                Tab(text: context.s.infoTab),
              ],
            ),
            // Sort toggle — mirrors the web frontend's "By time / By
            // delay" pill on `/airports/[iata]`. Default sort is by
            // time; flipping to delay reorders both tabs.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  Text(
                    context.s.sortLabel,
                    style: const TextStyle(
                      fontFamily: UiConstants.headingFont,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _SortChip(
                    label: context.s.sortByTime,
                    active: _sortMode == _ScheduleSort.time,
                    primary: primary,
                    onTap: () => setState(() => _sortMode = _ScheduleSort.time),
                  ),
                  const SizedBox(width: 6),
                  _SortChip(
                    label: context.s.sortByDelay,
                    active: _sortMode == _ScheduleSort.delay,
                    primary: primary,
                    onTap: () =>
                        setState(() => _sortMode = _ScheduleSort.delay),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildScheduleList(_departures, true, isDark, primary),
                  _buildScheduleList(_arrivals, false, isDark, primary),
                  _buildInfoTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, Color primary) {
    final airportName = _airportInfo?.name.isNotEmpty == true
        ? _airportInfo!.name
        : (widget.name ?? '');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: GlassPanel(
              padding: const EdgeInsets.all(8),
              borderRadius: 10,
              child: Icon(Icons.arrow_back_rounded, size: 18, color: primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    NeonText(
                      text: widget.iataCode,
                      fontSize: 22,
                      color: primary,
                      glowRadius: isDark ? 8 : 0,
                    ),
                    const SizedBox(width: 8),
                    Builder(
                      builder: (_) {
                        final country = airportCountry(widget.iataCode);
                        final flagPath = CountryDatabase.flagAssetPathOf(
                          country,
                        );
                        if (flagPath == null) return const SizedBox.shrink();
                        return SvgPicture.asset(
                          flagPath,
                          width: 22,
                          height: 16,
                          fit: BoxFit.cover,
                        );
                      },
                    ),
                  ],
                ),
                if (airportName.isNotEmpty)
                  Text(
                    airportName,
                    style: TextStyle(
                      fontFamily: UiConstants.bodyFont,
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textSecondary
                          : UiConstants.lightTextSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _isRefreshing ? null : _refresh,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _refreshError
                    ? AppColors.error.withValues(alpha: 0.15)
                    : primary.withValues(alpha: isDark ? 0.1 : 0.06),
                borderRadius: BorderRadius.circular(8),
                border: _refreshError
                    ? Border.all(color: AppColors.error.withValues(alpha: 0.3))
                    : null,
              ),
              child: _isRefreshing
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: primary,
                      ),
                    )
                  : _refreshError
                  ? const Icon(
                      Icons.wifi_off_rounded,
                      size: 18,
                      color: AppColors.error,
                    )
                  : Icon(Icons.refresh_rounded, size: 18, color: primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(bool isDark, Color primary) {
    final temp = _weather?.temperatureC;
    final windSpeed = _weather?.windSpeedKmh;
    final weatherCode = _weather?.weatherCode;
    final isDay = _weather?.isDay ?? true;
    final humidity = _weather?.humidity;
    final tz = _airportInfo?.timezone;

    var localTime = '--:--';
    String? tzLabel;
    try {
      int? offset;
      if (tz != null && tz.isNotEmpty) {
        offset = _estimateUtcOffset(tz);
        tzLabel = tz.split('/').last.replaceAll('_', ' ');
      } else if (_airportInfo?.lng != null) {
        // Estimate timezone from longitude (~15° per hour)
        offset = (_airportInfo!.lng! / 15).round();
      }
      if (offset != null) {
        final now = DateTime.now().toUtc();
        final localNow = now.add(Duration(hours: offset));
        localTime = DateFormat('HH:mm:ss').format(localNow);
      }
    } catch (_) {}

    final weatherIcon = _weatherIcon(weatherCode, isDay);
    final weatherText = UiText.weatherLabel(context, weatherCode);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          if (temp != null)
            Expanded(
              child: GlassPanel(
                padding: const EdgeInsets.all(10),
                borderRadius: 12,
                child: Row(
                  children: [
                    Text(weatherIcon, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                weatherText.toUpperCase(),
                                style: TextStyle(
                                  fontFamily: UiConstants.headingFont,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.textPrimary
                                      : UiConstants.lightTextPrimary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${temp.toStringAsFixed(0)}°C',
                                style: TextStyle(
                                  fontFamily: UiConstants.headingFont,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: primary,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            weatherText,
                            style: TextStyle(
                              fontFamily: UiConstants.bodyFont,
                              fontSize: 10,
                              color: isDark
                                  ? AppColors.textSecondary
                                  : UiConstants.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (temp != null) const SizedBox(width: 8),
          if (windSpeed != null)
            GlassPanel(
              padding: const EdgeInsets.all(10),
              borderRadius: 12,
              child: Column(
                children: [
                  Icon(Icons.air_rounded, size: 16, color: primary),
                  const SizedBox(height: 2),
                  Text(
                    windSpeed.toStringAsFixed(0),
                    style: TextStyle(
                      fontFamily: UiConstants.headingFont,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: primary,
                    ),
                  ),
                  Text(
                    'km/h',
                    style: TextStyle(
                      fontFamily: UiConstants.bodyFont,
                      fontSize: 9,
                      color: isDark
                          ? AppColors.textMuted
                          : UiConstants.lightTextMuted,
                    ),
                  ),
                ],
              ),
            ),
          if (windSpeed != null) const SizedBox(width: 8),
          if (humidity != null)
            GlassPanel(
              padding: const EdgeInsets.all(10),
              borderRadius: 12,
              child: Column(
                children: [
                  const Icon(
                    Icons.water_drop_rounded,
                    size: 16,
                    color: AppColors.info,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$humidity%',
                    style: const TextStyle(
                      fontFamily: UiConstants.headingFont,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.info,
                    ),
                  ),
                ],
              ),
            ),
          if (humidity != null) const SizedBox(width: 8),
          GlassPanel(
            padding: const EdgeInsets.all(10),
            borderRadius: 12,
            child: Column(
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  size: 16,
                  color: AppColors.accent,
                ),
                const SizedBox(height: 2),
                Text(
                  localTime,
                  style: const TextStyle(
                    fontFamily: UiConstants.headingFont,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                  ),
                ),
                if (tzLabel != null)
                  Text(
                    tzLabel,
                    style: TextStyle(
                      fontFamily: UiConstants.bodyFont,
                      fontSize: 8,
                      color: isDark
                          ? AppColors.textMuted
                          : UiConstants.lightTextMuted,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleList(
    List<AirportScheduleFlight> flights,
    bool isDeparture,
    bool isDark,
    Color primary,
  ) {
    if (_isLoading && flights.isEmpty) {
      return Center(child: CircularProgressIndicator(color: primary));
    }

    var filtered = flights;
    if (_searchQuery.isNotEmpty) {
      filtered = flights.where((flight) {
        final code = flight.searchCode;
        final airline = flight.airlineIata.toUpperCase();
        final dep = flight.depIata.toUpperCase();
        final arr = flight.arrIata.toUpperCase();
        return code.contains(_searchQuery) ||
            airline.contains(_searchQuery) ||
            dep.contains(_searchQuery) ||
            arr.contains(_searchQuery);
      }).toList();
    }

    if (_sortMode == _ScheduleSort.delay) {
      // Sort descending by delay magnitude — biggest disruption at
      // the top, undelayed flights at the bottom. Flights without a
      // delay reading sort last.
      filtered.sort((a, b) {
        final delayA = isDeparture ? a.depDelayed ?? -1 : a.arrDelayed ?? -1;
        final delayB = isDeparture ? b.depDelayed ?? -1 : b.arrDelayed ?? -1;
        return delayB.compareTo(delayA);
      });
    } else {
      filtered.sort((a, b) {
        final timeA = isDeparture ? (a.depTime ?? '') : (a.arrTime ?? '');
        final timeB = isDeparture ? (b.depTime ?? '') : (b.arrTime ?? '');
        return timeA.compareTo(timeB);
      });
    }

    if (filtered.isEmpty) {
      return Center(
        child: Text(
          context.tr('no_flights_found'),
          style: TextStyle(
            fontFamily: 'Rajdhani',
            fontSize: 14,
            color: isDark
                ? AppColors.textSecondary
                : UiConstants.lightTextSecondary,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final flight = filtered[index];
        return GestureDetector(
          onTap: () => _onFlightTap(flight),
          child: AirportScheduleTile(
            flight: flight,
            isDep: isDeparture,
            isDark: isDark,
            primary: primary,
          ),
        );
      },
    );
  }

  /// INFO tab: METAR/TAF + NOTAM panels. Resolves ICAO from the upstream
  /// airport payload first; falls back to the bundled `airportFullDatabase`
  /// (IATA → ICAO) so the panels still load when the upstream entry
  /// didn't carry an ICAO field.
  Widget _buildInfoTab() {
    final upstreamIcao = _airportInfo?.icao ?? '';
    final fallbackIcao = lookupAirportByIata(widget.iataCode)?.icao ?? '';
    final icao = upstreamIcao.isNotEmpty ? upstreamIcao : fallbackIcao;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        MetarPanel(icao: icao),
        NotamPanel(icao: icao),
        AtcAudioPanel(icao: icao),
        const SizedBox(height: 24),
      ],
    );
  }

  void _onFlightTap(AirportScheduleFlight flight) {
    final flightCode = flight.flightIcao.isNotEmpty
        ? flight.flightIcao
        : flight.flightIata;
    if (flightCode.isEmpty) {
      return;
    }
    Navigator.of(context).pop(flightCode);
  }

  /// Estimate UTC offset from IANA timezone name.
  /// Not DST-aware but covers common cases.
  static int _estimateUtcOffset(String tz) {
    return switch (tz) {
      // Americas
      'America/New_York' || 'America/Toronto' || 'US/Eastern' => -4,
      'America/Chicago' || 'US/Central' => -5,
      'America/Denver' || 'US/Mountain' => -6,
      'America/Los_Angeles' || 'US/Pacific' => -7,
      'America/Sao_Paulo' || 'America/Buenos_Aires' => -3,
      'America/Bogota' || 'America/Lima' => -5,
      'America/Mexico_City' => -5,
      // Europe
      'Europe/London' || 'Europe/Dublin' || 'Europe/Lisbon' => 1,
      'Europe/Berlin' ||
      'Europe/Paris' ||
      'Europe/Rome' ||
      'Europe/Madrid' ||
      'Europe/Amsterdam' ||
      'Europe/Brussels' ||
      'Europe/Zurich' ||
      'Europe/Vienna' ||
      'Europe/Warsaw' ||
      'Europe/Prague' ||
      'Europe/Copenhagen' ||
      'Europe/Oslo' ||
      'Europe/Stockholm' ||
      'Europe/Belgrade' ||
      'Europe/Budapest' => 2,
      'Europe/Athens' ||
      'Europe/Bucharest' ||
      'Europe/Helsinki' ||
      'Europe/Istanbul' ||
      'Europe/Kiev' ||
      'Europe/Moscow' => 3,
      // Middle East / Africa
      'Asia/Dubai' || 'Asia/Muscat' => 4,
      'Asia/Riyadh' ||
      'Asia/Kuwait' ||
      'Asia/Qatar' ||
      'Africa/Nairobi' ||
      'Africa/Addis_Ababa' => 3,
      'Africa/Cairo' => 2,
      'Africa/Casablanca' || 'Africa/Tunis' || 'Africa/Algiers' => 1,
      'Africa/Johannesburg' => 2,
      // Asia / Pacific
      'Asia/Kolkata' || 'Asia/Calcutta' => 5,
      'Asia/Bangkok' || 'Asia/Jakarta' => 7,
      'Asia/Singapore' ||
      'Asia/Hong_Kong' ||
      'Asia/Shanghai' ||
      'Asia/Taipei' ||
      'Asia/Kuala_Lumpur' => 8,
      'Asia/Tokyo' || 'Asia/Seoul' => 9,
      'Asia/Karachi' => 5,
      'Australia/Sydney' => 10,
      'Pacific/Auckland' => 12,
      _ => 0, // UTC fallback
    };
  }

  String _weatherIcon(int? code, bool isDay) {
    if (code == null) return '🌡️';
    if (code == 0) return isDay ? '☀️' : '🌙';
    if (code <= 3) return isDay ? '⛅' : '☁️';
    if (code <= 49) return '🌫️';
    if (code <= 59) return '🌦️';
    if (code <= 69) return '🌧️';
    if (code <= 79) return '🌨️';
    if (code <= 82) return '🌧️';
    if (code <= 86) return '🌨️';
    if (code >= 95) return '⛈️';
    return '☁️';
  }
}

/// Pill button used by the schedule-sort toggle. Stays small + dense
/// so the row never wraps, even on narrow phone screens.
class _SortChip extends StatelessWidget {
  const _SortChip({
    required this.label,
    required this.active,
    required this.primary,
    required this.onTap,
  });

  final String label;
  final bool active;
  final Color primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: active ? primary.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: active
                ? primary.withValues(alpha: 0.55)
                : AppColors.glassBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: UiConstants.headingFont,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
            color: active ? primary : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
