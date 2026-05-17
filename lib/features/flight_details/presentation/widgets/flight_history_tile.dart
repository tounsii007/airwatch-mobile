import 'package:flutter/material.dart';
import 'package:airwatch_mobile/core/constants/airport_database.dart';
import 'package:airwatch_mobile/core/constants/ui_constants.dart';
import 'package:airwatch_mobile/core/l10n/ui_text.dart';
import 'package:airwatch_mobile/core/theme/app_colors.dart';
import 'package:airwatch_mobile/core/utils/flight_code_formatter.dart';
import 'package:airwatch_mobile/core/widgets/glass_panel.dart';
import 'package:airwatch_mobile/features/flight_details/data/models/flight_history_models.dart';
import 'package:airwatch_mobile/features/flight_details/presentation/screens/flight_replay_screen.dart';
import 'package:airwatch_mobile/features/map/data/datasources/flight_info_datasource.dart';

class FlightHistoryTile extends StatelessWidget {
  final HistoryFlight flight;
  final bool isDark;
  final Color primary;
  final AirlineInfo? airline;
  final AircraftMetadata? aircraftMeta;

  const FlightHistoryTile({
    super.key,
    required this.flight,
    required this.isDark,
    required this.primary,
    this.airline,
    this.aircraftMeta,
  });

  /// Open the animated track replay for this past flight. The
  /// [FlightReplayScreen] needs the ICAO24 hex (carried on every
  /// history row) plus the callsign for the title bar.
  void _openReplay(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FlightReplayScreen(
          icao24: flight.icao24,
          callsign: flight.callsign,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = UiText.dateFormat(context, 'EEE, dd MMM yyyy');
    final timeFmt = UiText.dateFormat(context, 'HH:mm');
    final depTime = flight.departureTime;
    final arrTime = flight.arrivalTime;
    final depDelay = flight.departureDelayMinutes;
    final arrDelay = flight.arrivalDelayMinutes;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          // Tap a history row to launch its animated track replay —
          // mirrors airwatch-web's /replay tile click. Without this
          // the row was static; users could SEE that the flight was
          // delayed by 12 min but had no path to actually watch it
          // unfold on the map.
          onTap: () => _openReplay(context),
          borderRadius: BorderRadius.circular(14),
          child: GlassPanel(
            padding: const EdgeInsets.all(12),
            borderRadius: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Row 1: Date + Delay Badge + Duration ──
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 11,
                      color: primary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      dateFmt.format(depTime),
                      style: TextStyle(
                        fontFamily: UiConstants.bodyFont,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textPrimary
                            : UiConstants.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (flight.isDelayed)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          context.tr('delayed').toUpperCase(),
                          style: const TextStyle(
                            fontFamily: UiConstants.headingFont,
                            fontSize: 7,
                            fontWeight: FontWeight.w700,
                            color: AppColors.error,
                            letterSpacing: 0.5,
                          ),
                        ),
                      )
                    else if (depDelay != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          context.tr('on_time').toUpperCase(),
                          style: const TextStyle(
                            fontFamily: UiConstants.headingFont,
                            fontSize: 7,
                            fontWeight: FontWeight.w700,
                            color: AppColors.success,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    const Spacer(),
                    Icon(
                      Icons.timer_rounded,
                      size: 11,
                      color: isDark
                          ? AppColors.textSecondary
                          : UiConstants.lightTextSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      flight.durationText,
                      style: TextStyle(
                        fontFamily: UiConstants.headingFont,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // ── Row 2: Route DEP → ARR with airport names ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Departure airport
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                flight.hasDeparture
                                    ? AirportDatabase.displayCode(
                                        flight.effectiveDep,
                                      )
                                    : UiConstants.missingCode,
                                style: TextStyle(
                                  fontFamily: UiConstants.headingFont,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: flight.hasDeparture
                                      ? AppColors.success
                                      : AppColors.textMuted,
                                ),
                              ),
                              if (flight.depIsInferred)
                                const Text(
                                  ' ~',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.warning,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                            ],
                          ),
                          if (flight.hasDeparture)
                            Text(
                              AirportDatabase.getCity(flight.effectiveDep),
                              style: TextStyle(
                                fontFamily: UiConstants.bodyFont,
                                fontSize: 11,
                                fontStyle: flight.depIsInferred
                                    ? FontStyle.italic
                                    : FontStyle.normal,
                                color: isDark
                                    ? AppColors.textSecondary
                                    : UiConstants.lightTextSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Center: flight icon
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        children: [
                          Icon(Icons.flight_rounded, size: 16, color: primary),
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            width: 30,
                            height: 1,
                            color: primary.withValues(alpha: 0.3),
                          ),
                        ],
                      ),
                    ),
                    // Arrival airport
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (flight.arrIsInferred)
                                const Text(
                                  '~ ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.warning,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              Text(
                                flight.hasArrival
                                    ? AirportDatabase.displayCode(
                                        flight.effectiveArr,
                                      )
                                    : UiConstants.missingCode,
                                style: TextStyle(
                                  fontFamily: UiConstants.headingFont,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: flight.hasArrival
                                      ? AppColors.accent
                                      : AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                          if (flight.hasArrival)
                            Text(
                              AirportDatabase.getCity(flight.effectiveArr),
                              style: TextStyle(
                                fontFamily: UiConstants.bodyFont,
                                fontSize: 11,
                                fontStyle: flight.arrIsInferred
                                    ? FontStyle.italic
                                    : FontStyle.normal,
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
                const SizedBox(height: 10),

                // ── Row 3: Scheduled vs Actual Times ──
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black).withValues(
                      alpha: 0.04,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      // Departure times
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              context.tr('departure'),
                              style: TextStyle(
                                fontFamily: UiConstants.bodyFont,
                                fontSize: 9,
                                letterSpacing: 1,
                                color: isDark
                                    ? AppColors.textMuted
                                    : UiConstants.lightTextMuted,
                              ),
                            ),
                            const SizedBox(height: 3),
                            if (flight.scheduledDeparture != null)
                              Text(
                                '${context.tr('scheduled_short')}: ${timeFmt.format(flight.scheduledDeparture!)}',
                                style: TextStyle(
                                  fontFamily: UiConstants.bodyFont,
                                  fontSize: 11,
                                  color: isDark
                                      ? AppColors.textSecondary
                                      : UiConstants.lightTextSecondary,
                                ),
                              ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${context.tr('actual')}: ',
                                  style: TextStyle(
                                    fontFamily: UiConstants.bodyFont,
                                    fontSize: 11,
                                    color: isDark
                                        ? AppColors.textSecondary
                                        : UiConstants.lightTextSecondary,
                                  ),
                                ),
                                Text(
                                  timeFmt.format(depTime),
                                  style: TextStyle(
                                    fontFamily: UiConstants.headingFont,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: flight.isDelayed
                                        ? AppColors.error
                                        : AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                            if (depDelay != null && depDelay != 0)
                              Text(
                                depDelay > 0
                                    ? '+${depDelay}min ${context.tr('late')}'
                                    : '${depDelay.abs()}min ${context.tr('early')}',
                                style: TextStyle(
                                  fontFamily: UiConstants.bodyFont,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: depDelay > 15
                                      ? AppColors.error
                                      : AppColors.success,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: (isDark ? Colors.white : Colors.black)
                            .withValues(alpha: 0.08),
                      ),
                      // Arrival times
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              context.tr('arrival'),
                              style: TextStyle(
                                fontFamily: UiConstants.bodyFont,
                                fontSize: 9,
                                letterSpacing: 1,
                                color: isDark
                                    ? AppColors.textMuted
                                    : UiConstants.lightTextMuted,
                              ),
                            ),
                            const SizedBox(height: 3),
                            if (flight.scheduledArrival != null)
                              Text(
                                '${context.tr('scheduled_short')}: ${timeFmt.format(flight.scheduledArrival!)}',
                                style: TextStyle(
                                  fontFamily: UiConstants.bodyFont,
                                  fontSize: 11,
                                  color: isDark
                                      ? AppColors.textSecondary
                                      : UiConstants.lightTextSecondary,
                                ),
                              ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${context.tr('actual')}: ',
                                  style: TextStyle(
                                    fontFamily: UiConstants.bodyFont,
                                    fontSize: 11,
                                    color: isDark
                                        ? AppColors.textSecondary
                                        : UiConstants.lightTextSecondary,
                                  ),
                                ),
                                Text(
                                  timeFmt.format(arrTime),
                                  style: TextStyle(
                                    fontFamily: UiConstants.headingFont,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: (arrDelay ?? 0) > 15
                                        ? AppColors.error
                                        : AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                            if (arrDelay != null && arrDelay != 0)
                              Text(
                                arrDelay > 0
                                    ? '+${arrDelay}min ${context.tr('late')}'
                                    : '${arrDelay.abs()}min ${context.tr('early')}',
                                style: TextStyle(
                                  fontFamily: 'Rajdhani',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: arrDelay > 15
                                      ? AppColors.error
                                      : AppColors.success,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // ── Row 4: Extra info line ──
                if (flight.depDistanceText.isNotEmpty ||
                    flight.arrDistanceText.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        if (flight.depDistanceText.isNotEmpty)
                          Expanded(
                            child: Text(
                              '${context.tr('dep')}: ${flight.depDistanceText}',
                              style: TextStyle(
                                fontFamily: UiConstants.bodyFont,
                                fontSize: 10,
                                color: isDark
                                    ? AppColors.textMuted
                                    : UiConstants.lightTextMuted,
                              ),
                            ),
                          ),
                        if (flight.arrDistanceText.isNotEmpty)
                          Expanded(
                            child: Text(
                              '${context.tr('arr')}: ${flight.arrDistanceText}',
                              textAlign: TextAlign.end,
                              style: TextStyle(
                                fontFamily: UiConstants.bodyFont,
                                fontSize: 10,
                                color: isDark
                                    ? AppColors.textMuted
                                    : UiConstants.lightTextMuted,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                // ── Row 5: Tags ──
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _SmallTag(
                      label: 'ICAO',
                      value: flight.icao24.toUpperCase(),
                      color: primary,
                      isDark: isDark,
                    ),
                    if (aircraftMeta?.registration != null)
                      _SmallTag(
                        label: 'REG',
                        value: aircraftMeta?.registration ?? '',
                        color: primary,
                        isDark: isDark,
                      ),
                    if (aircraftMeta?.typecode != null)
                      _SmallTag(
                        label: 'TYPE',
                        value: aircraftMeta?.typecode ?? '',
                        color: AppColors.accent,
                        isDark: isDark,
                      ),
                    if (flight.callsign != null && flight.callsign!.isNotEmpty)
                      _SmallTag(
                        label: 'FLT',
                        value: FlightCodeFormatter.displayFlightCode(
                          flightIata: flight.flightIata,
                          flightIcao: flight.flightIcao,
                          callsign: flight.callsign,
                          fallback: flight.callsign,
                        ),
                        color: primary,
                        isDark: isDark,
                      ),
                    if (flight.depCandidatesCount > 0)
                      _SmallTag(
                        label: 'DEP?',
                        value: '${flight.depCandidatesCount}',
                        color: AppColors.textMuted,
                        isDark: isDark,
                      ),
                    if (flight.arrCandidatesCount > 0)
                      _SmallTag(
                        label: 'ARR?',
                        value: '${flight.arrCandidatesCount}',
                        color: AppColors.textMuted,
                        isDark: isDark,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════ SMALL WIDGETS ═══════════════════

class _SmallTag extends StatelessWidget {
  final String label, value;
  final Color color;
  final bool isDark;
  const _SmallTag({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.08 : 0.05),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label ',
            style: TextStyle(
              fontFamily: UiConstants.bodyFont,
              fontSize: 9,
              color: isDark ? AppColors.textMuted : UiConstants.lightTextMuted,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: UiConstants.headingFont,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
