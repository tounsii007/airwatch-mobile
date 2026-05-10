import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:airwatch_mobile/core/constants/config.dart';
import 'package:airwatch_mobile/core/constants/country_database.dart';
import 'package:airwatch_mobile/core/constants/ui_constants.dart';
import 'package:airwatch_mobile/core/l10n/country_translations.dart';
import 'package:airwatch_mobile/core/l10n/ui_text.dart';
import 'package:airwatch_mobile/core/theme/app_colors.dart';
import 'package:airwatch_mobile/core/utils/flight_status_utils.dart';
import 'package:airwatch_mobile/core/widgets/glass_panel.dart';
import 'package:airwatch_mobile/core/widgets/neon_text.dart';
import 'package:airwatch_mobile/features/airline/data/models/airline_flight_info.dart';
import 'package:airwatch_mobile/features/airline/data/services/airline_details_service.dart';
import 'package:airwatch_mobile/features/map/data/datasources/flight_info_datasource.dart';

class AirlineDetailScreen extends StatefulWidget {
  final String icao;
  final String? iata;
  final String? name;
  final String? country;

  const AirlineDetailScreen({
    super.key,
    required this.icao,
    this.iata,
    this.name,
    this.country,
  });

  @override
  State<AirlineDetailScreen> createState() => _AirlineDetailScreenState();
}

class _AirlineDetailScreenState extends State<AirlineDetailScreen> {
  final _service = AirlineDetailsService();
  List<AirlineFlightInfo> _flights = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadFlights();
  }

  Future<void> _loadFlights() async {
    final flights = await _service.fetchActiveFlights(
      widget.icao,
      airlineIata: widget.iata,
    );
    if (mounted) {
      setState(() {
        _flights = flights;
        _isLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    await _loadFlights();
    if (mounted) setState(() => _isRefreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primary : UiConstants.lightPrimary;
    final logoUrl = FlightInfoDatasource.getAirlineLogoUrl(widget.iata);

    final airborne = _flights.where((f) => f.isAirborne).length;
    final grounded = _flights.length - airborne;
    final routes = _flights.map((f) => f.route).toSet().length;

    final filtered = _searchQuery.isEmpty
        ? _flights
        : _flights.where((f) {
            final q = _searchQuery.toUpperCase();
            return f.displayCode.toUpperCase().contains(q) ||
                f.depIata.toUpperCase().contains(q) ||
                f.arrIata.toUpperCase().contains(q);
          }).toList();

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.background
          : UiConstants.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark, primary, logoUrl),
            _buildInfoRow(isDark, primary),
            _buildStats(isDark, primary, airborne, grounded, routes),
            const SizedBox(height: 8),
            // Search
            Padding(
              padding: UiConstants.screenPadding,
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surface : UiConstants.lightSurface,
                  borderRadius: BorderRadius.circular(
                    AppConfig.inputBorderRadius,
                  ),
                  border: Border.all(
                    color: isDark
                        ? AppColors.glassBorder
                        : UiConstants.lightBorder,
                  ),
                ),
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: TextStyle(
                    fontFamily: UiConstants.bodyFont,
                    fontSize: UiConstants.bodyFontSize,
                    color: isDark
                        ? AppColors.textPrimary
                        : UiConstants.lightTextPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: context.tr('search_flights_hint'),
                    hintStyle: TextStyle(
                      fontFamily: UiConstants.bodyFont,
                      color: isDark
                          ? AppColors.textMuted
                          : UiConstants.lightHintText,
                    ),
                    prefixIcon: Icon(Icons.search_rounded, color: primary),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Section header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    '${context.tr('active_flights')} (${filtered.length})',
                    style: const TextStyle(
                      fontFamily: UiConstants.headingFont,
                      fontSize: UiConstants.microFontSize,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            // Flights list
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: primary))
                  : filtered.isEmpty
                  ? Center(
                      child: Text(
                        context.tr('no_flights'),
                        style: TextStyle(
                          fontFamily: UiConstants.bodyFont,
                          color: isDark
                              ? AppColors.textMuted
                              : UiConstants.lightTextMuted,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) => _FlightTile(
                        flight: filtered[i],
                        isDark: isDark,
                        primary: primary,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, Color primary, String? logoUrl) {
    final countryCode = CountryDatabase.codeOf(widget.country);
    final flagPath = CountryDatabase.flagAssetPathOf(
      countryCode ?? widget.country,
    );

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
          // Logo
          if (logoUrl != null)
            Container(
              width: 60,
              height: 36,
              margin: const EdgeInsetsDirectional.only(end: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(4),
              child: CachedNetworkImage(
                imageUrl: logoUrl,
                fit: BoxFit.contain,
                errorWidget: (_, _, _) =>
                    Icon(Icons.airlines_rounded, color: primary, size: 24),
                placeholder: (_, _) => const SizedBox.shrink(),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: NeonText(
                        text: widget.name ?? widget.icao,
                        fontSize: 18,
                        color: primary,
                        glowRadius: isDark ? 8 : 0,
                      ),
                    ),
                    if (flagPath != null) ...[
                      const SizedBox(width: 8),
                      SvgPicture.asset(
                        flagPath,
                        width: 22,
                        height: 16,
                        fit: BoxFit.cover,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _refresh,
            child: _isRefreshing
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: primary,
                    ),
                  )
                : Icon(Icons.refresh_rounded, color: primary, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(bool isDark, Color primary) {
    final locale = Localizations.localeOf(context).languageCode;
    final countryDisplay = widget.country != null
        ? localizeCountry(CountryDatabase.displayName(widget.country), locale)
        : '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        children: [
          const SizedBox(width: 80), // align with logo
          if (widget.iata != null && widget.iata!.isNotEmpty)
            _CodeChip(label: widget.iata!, color: primary, isDark: isDark),
          const SizedBox(width: 6),
          _CodeChip(label: widget.icao, color: primary, isDark: isDark),
          if (countryDisplay.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(
              '· $countryDisplay',
              style: TextStyle(
                fontFamily: UiConstants.bodyFont,
                fontSize: UiConstants.captionFontSize,
                color: isDark
                    ? AppColors.textSecondary
                    : UiConstants.lightTextSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStats(
    bool isDark,
    Color primary,
    int airborne,
    int grounded,
    int routes,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _StatCard(
            icon: Icons.flight_takeoff_rounded,
            value: '$airborne',
            label: context.tr('airborne'),
            color: AppColors.success,
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _StatCard(
            icon: Icons.route_rounded,
            value: '$routes',
            label: context.tr('routes'),
            color: primary,
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _StatCard(
            icon: Icons.flight_land_rounded,
            value: '$grounded',
            label: context.tr('on_ground'),
            color: AppColors.warning,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _CodeChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isDark;

  const _CodeChip({
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(AppConfig.tagBorderRadius),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: UiConstants.headingFont,
          fontSize: UiConstants.microFontSize,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value, label;
  final Color color;
  final bool isDark;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassPanel(
        padding: const EdgeInsets.all(10),
        borderRadius: 12,
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontFamily: UiConstants.headingFont,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontFamily: UiConstants.bodyFont,
                fontSize: 9,
                color: isDark
                    ? AppColors.textMuted
                    : UiConstants.lightTextMuted,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlightTile extends StatelessWidget {
  final AirlineFlightInfo flight;
  final bool isDark;
  final Color primary;

  const _FlightTile({
    required this.flight,
    required this.isDark,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = FlightStatusUtils.statusColor(
      flight.status,
      primary: primary,
    );
    final statusLabel = FlightStatusUtils.statusLabel(context, flight.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: GlassPanel(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        borderRadius: AppConfig.tileBorderRadius,
        child: Row(
          children: [
            SizedBox(
              width: 65,
              child: Text(
                flight.displayCode,
                style: TextStyle(
                  fontFamily: UiConstants.headingFont,
                  fontSize: UiConstants.captionFontSize,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.textPrimary
                      : UiConstants.lightTextPrimary,
                ),
              ),
            ),
            Expanded(
              child: Text(
                flight.route,
                style: TextStyle(
                  fontFamily: UiConstants.bodyFont,
                  fontSize: UiConstants.captionFontSize,
                  fontWeight: FontWeight.w600,
                  color: flight.isAirborne
                      ? AppColors.success
                      : AppColors.accent,
                ),
              ),
            ),
            if (flight.aircraftIcao != null && flight.aircraftIcao!.isNotEmpty)
              Container(
                margin: const EdgeInsetsDirectional.only(end: 8),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(
                    AppConfig.tagBorderRadius,
                  ),
                ),
                child: Text(
                  flight.aircraftIcao!,
                  style: TextStyle(
                    fontFamily: UiConstants.headingFont,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: primary,
                  ),
                ),
              ),
            if (statusLabel.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontFamily: UiConstants.headingFont,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
