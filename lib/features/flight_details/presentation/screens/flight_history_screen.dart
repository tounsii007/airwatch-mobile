import 'package:flutter/material.dart';
import 'package:airwatch_mobile/core/constants/airport_database.dart';
import 'package:airwatch_mobile/core/constants/ui_constants.dart';
import 'package:airwatch_mobile/core/l10n/ui_text.dart';
import 'package:airwatch_mobile/core/theme/app_colors.dart';
import 'package:airwatch_mobile/core/widgets/glass_panel.dart';
import 'package:airwatch_mobile/core/widgets/neon_text.dart';
import 'package:airwatch_mobile/features/flight_details/data/models/flight_history_models.dart';
import 'package:airwatch_mobile/features/flight_details/data/services/flight_history_service.dart';
import 'package:airwatch_mobile/features/flight_details/presentation/widgets/flight_history_tile.dart';
import 'package:airwatch_mobile/features/map/data/datasources/flight_info_datasource.dart';

/// Shows the last 7 days of flights for a specific callsign,
/// including delays, scheduled vs actual times, aircraft info, and full airport names.
class FlightHistoryScreen extends StatefulWidget {
  final String? initialCallsign;

  const FlightHistoryScreen({super.key, this.initialCallsign});

  @override
  State<FlightHistoryScreen> createState() => _FlightHistoryScreenState();
}

class _FlightHistoryScreenState extends State<FlightHistoryScreen> {
  final _controller = TextEditingController();
  final _service = FlightHistoryService();

  List<HistoryFlight> _flights = [];
  AircraftMetadata? _aircraftMeta;
  AirlineInfo? _airline;
  bool _isLoading = false;
  String? _error;
  String _searchedCallsign = '';
  int _loadProgress = 0;
  int _loadTotal = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialCallsign != null) {
      _controller.text = widget.initialCallsign!;
      _search(widget.initialCallsign!);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search(String callsign) async {
    final cs = callsign.trim().toUpperCase();
    if (cs.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _flights = [];
      _aircraftMeta = null;
      _searchedCallsign = cs;
      _loadProgress = 0;
      _loadTotal = 0;
    });

    try {
      final result = await _service.search(
        cs,
        onProgress: (progress) {
          if (!mounted) return;
          setState(() {
            _loadTotal = progress.total;
            _loadProgress = progress.step;
            _flights = progress.flights;
          });
        },
      );

      setState(() {
        _flights = result.flights;
        _aircraftMeta = result.aircraftMeta;
        _airline = result.airline;
        _isLoading = false;
        if (result.flights.isEmpty) {
          _error =
              '${context.tr('no_flights_found')} "$cs".\n'
              '${context.tr('search_callsign_hint')}';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error: $e';
      });
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: NeonText(
          text: context.s.flightHistory,
          color: primary,
          glowRadius: isDark ? 8 : 0,
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.surface
                            : UiConstants.lightSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? AppColors.glassBorder
                              : UiConstants.lightBorder,
                        ),
                      ),
                      child: TextField(
                        controller: _controller,
                        textCapitalization: TextCapitalization.characters,
                        style: TextStyle(
                          fontFamily: UiConstants.headingFont,
                          fontSize: 14,
                          color: isDark
                              ? AppColors.textPrimary
                              : UiConstants.lightTextPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: context.tr('search_callsign_hint'),
                          hintStyle: TextStyle(
                            fontFamily: UiConstants.bodyFont,
                            fontSize: 14,
                            color: isDark
                                ? AppColors.textMuted
                                : UiConstants.lightHintText,
                          ),
                          prefixIcon: Icon(
                            Icons.history_rounded,
                            color: primary,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(12),
                        ),
                        onSubmitted: _search,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _search(_controller.text),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Icon(
                        Icons.search_rounded,
                        color: primary,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_airline != null || _aircraftMeta != null)
              _buildInfoHeader(isDark, primary),
            if (_searchedCallsign.isNotEmpty &&
                !_isLoading &&
                _flights.isNotEmpty)
              _buildSummary(isDark, primary),
            const SizedBox(height: 4),
            Expanded(child: _buildContent(isDark, primary)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoHeader(bool isDark, Color primary) {
    final logoUrl = _airline != null
        ? FlightInfoDatasource.getAirlineLogoUrl(_airline?.iata ?? '')
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: GlassPanel(
        padding: const EdgeInsets.all(10),
        borderRadius: 12,
        child: Row(
          children: [
            // Airline logo
            if (logoUrl != null)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 10),
                child: Image.network(
                  logoUrl,
                  width: 50,
                  height: 24,
                  // Decode at ~2x logical size so 3x-DPR screens stay
                  // sharp without the engine keeping the full upstream
                  // bitmap in memory. Airline logos can be 512x512+ from
                  // the upstream; without cacheWidth/cacheHeight the
                  // decoded RGBA buffer is ~1 MB per logo per history
                  // row.
                  cacheWidth: 100,
                  cacheHeight: 48,
                  fit: BoxFit.contain,
                  errorBuilder: (_, error, stackTrace) =>
                      Icon(Icons.airlines_rounded, color: primary, size: 22),
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_airline != null)
                    Text(
                      _airline?.name ?? '',
                      style: TextStyle(
                        fontFamily: UiConstants.bodyFont,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textPrimary
                            : UiConstants.lightTextPrimary,
                      ),
                    ),
                  if (_aircraftMeta != null)
                    Text(
                      '${_aircraftMeta?.displayType ?? ''} • ${_aircraftMeta?.registration ?? ''}',
                      style: TextStyle(
                        fontFamily: UiConstants.bodyFont,
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textSecondary
                            : UiConstants.lightTextSecondary,
                      ),
                    ),
                ],
              ),
            ),
            if (_aircraftMeta?.typecode != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: primary.withValues(alpha: 0.2)),
                ),
                child: Text(
                  _aircraftMeta?.typecode ?? '',
                  style: TextStyle(
                    fontFamily: UiConstants.headingFont,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(bool isDark, Color primary) {
    // Calculate delay statistics
    int onTimeCount = 0;
    int delayedCount = 0;
    int totalDelayMinutes = 0;

    for (final f in _flights) {
      final delay = f.departureDelayMinutes;
      if (delay != null) {
        if (delay.abs() <= 15) {
          onTimeCount++;
        } else {
          delayedCount++;
          totalDelayMinutes += delay;
        }
      }
    }

    final dep = _flights.isNotEmpty ? _flights.first.effectiveDep : null;
    final arr = _flights.isNotEmpty ? _flights.first.effectiveArr : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Route header
          if (dep != null || arr != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AirportDatabase.fullDisplay(dep),
                    style: const TextStyle(
                      fontFamily: UiConstants.bodyFont,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: primary,
                    ),
                  ),
                  Text(
                    AirportDatabase.fullDisplay(arr),
                    style: const TextStyle(
                      fontFamily: UiConstants.bodyFont,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
            ),
          // Stats row
          Row(
            children: [
              _StatChip(
                label: '${_flights.length}',
                subtitle: context.tr('flights_count'),
                color: primary,
                isDark: isDark,
              ),
              const SizedBox(width: 6),
              _StatChip(
                label: '$onTimeCount',
                subtitle: context.tr('on_time'),
                color: AppColors.success,
                isDark: isDark,
              ),
              const SizedBox(width: 6),
              _StatChip(
                label: '$delayedCount',
                subtitle: context.tr('delayed'),
                color: delayedCount > 0 ? AppColors.error : AppColors.success,
                isDark: isDark,
              ),
              if (delayedCount > 0) ...[
                const SizedBox(width: 6),
                _StatChip(
                  label:
                      '~${(totalDelayMinutes / delayedCount.clamp(1, 999)).round()}m',
                  subtitle: context.tr('avg_delay'),
                  color: AppColors.warning,
                  isDark: isDark,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark, Color primary) {
    // Show results live while still loading
    if (_isLoading && _flights.isNotEmpty) {
      return Column(
        children: [
          // Loading progress bar at top
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${context.tr('searching')} ${_flights.length} ${context.tr('found')}',
                  style: TextStyle(
                    fontFamily: UiConstants.bodyFont,
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textSecondary
                        : UiConstants.lightTextSecondary,
                  ),
                ),
                const Spacer(),
                if (_loadTotal > 0)
                  Text(
                    '$_loadProgress/$_loadTotal',
                    style: TextStyle(
                      fontFamily: UiConstants.headingFont,
                      fontSize: 9,
                      color: isDark
                          ? AppColors.textMuted
                          : UiConstants.lightTextMuted,
                    ),
                  ),
              ],
            ),
          ),
          if (_loadTotal > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: LinearProgressIndicator(
                value: _loadProgress / _loadTotal.clamp(1, 999),
                color: primary,
                backgroundColor: primary.withValues(alpha: 0.1),
                minHeight: 2,
              ),
            ),
          const SizedBox(height: 4),
          // Live results list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _flights.length,
              itemBuilder: (ctx, i) => FlightHistoryTile(
                flight: _flights[i],
                isDark: isDark,
                primary: primary,
                airline: _airline,
                aircraftMeta: _aircraftMeta,
              ),
            ),
          ),
        ],
      );
    }

    // Pure loading state (no results yet)
    if (_isLoading && _flights.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: primary),
            const SizedBox(height: 16),
            Text(
              context.s.searchingDays,
              style: TextStyle(
                fontFamily: UiConstants.bodyFont,
                fontSize: 14,
                color: isDark
                    ? AppColors.textSecondary
                    : UiConstants.lightTextSecondary,
              ),
            ),
            if (_loadTotal > 0) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: 200,
                child: LinearProgressIndicator(
                  value: _loadProgress / _loadTotal.clamp(1, 999),
                  color: primary,
                  backgroundColor: primary.withValues(alpha: 0.15),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$_loadProgress / $_loadTotal ${context.tr('time_windows')}',
                style: TextStyle(
                  fontFamily: UiConstants.bodyFont,
                  fontSize: 11,
                  color: isDark
                      ? AppColors.textMuted
                      : UiConstants.lightTextMuted,
                ),
              ),
            ],
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: UiConstants.bodyFont,
              fontSize: 14,
              color: isDark
                  ? AppColors.textSecondary
                  : UiConstants.lightTextSecondary,
            ),
          ),
        ),
      );
    }

    if (_flights.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_rounded,
              size: 48,
              color: isDark ? AppColors.textMuted : UiConstants.lightDisabled,
            ),
            const SizedBox(height: 12),
            Text(
              context.tr('search_callsign_prompt'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: UiConstants.bodyFont,
                fontSize: 14,
                color: isDark
                    ? AppColors.textSecondary
                    : UiConstants.lightTextSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _flights.length,
      itemBuilder: (ctx, i) => FlightHistoryTile(
        flight: _flights[i],
        isDark: isDark,
        primary: primary,
        airline: _airline,
        aircraftMeta: _aircraftMeta,
      ),
    );
  }
}

// ═══════════════════ SMALL WIDGETS ═══════════════════

class _StatChip extends StatelessWidget {
  final String label, subtitle;
  final Color color;
  final bool isDark;
  const _StatChip({
    required this.label,
    required this.subtitle,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.1 : 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: UiConstants.headingFont,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontFamily: UiConstants.bodyFont,
                fontSize: 9,
                color: isDark
                    ? AppColors.textMuted
                    : UiConstants.lightTextMuted,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
