import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:airwatch_mobile/core/constants/ui_constants.dart';
import 'package:airwatch_mobile/core/l10n/ui_text.dart';
import 'package:airwatch_mobile/core/theme/app_colors.dart';
import 'package:airwatch_mobile/features/flight_details/data/services/route_stats_service.dart';

/// Thin popularity badge under the dep→arr arrow on the flight detail
/// panel. Mirrors airwatch-web's commit 22e4cc0 ("X today · Y this
/// week · Z in 30 d").
///
/// <h3>Render contract</h3>
/// The badge hides itself entirely when:
///   * dep / arr are missing or fail the IATA pattern (3-4 letters)
///   * the api fetch errors / returns non-2xx
///   * `observed: false` (we've never seen the route)
///   * every bucket is 0 (avoids a "0 flights/week" eyesore)
///
/// Each bucket renders independently — when only the weekly count
/// has data, today and 30-day are dropped; no comma-soup placeholders.
class RouteStatsBadge extends StatefulWidget {
  /// Departure IATA code. Null/empty/malformed → no fetch, no render.
  final String? dep;

  /// Arrival IATA code. Same rules as [dep].
  final String? arr;

  /// Surface colour — usually the panel's primary accent so the badge
  /// blends with the route arrow above.
  final Color primary;

  /// Dark / light mode — controls muted-text contrast.
  final bool isDark;

  const RouteStatsBadge({
    super.key,
    required this.dep,
    required this.arr,
    required this.primary,
    required this.isDark,
  });

  @override
  State<RouteStatsBadge> createState() => _RouteStatsBadgeState();
}

class _RouteStatsBadgeState extends State<RouteStatsBadge> {
  final RouteStatsService _service = RouteStatsService();

  RouteStats? _stats;
  bool _loaded = false;
  String? _lastKey;

  @override
  void initState() {
    super.initState();
    _maybeLoad();
  }

  @override
  void didUpdateWidget(covariant RouteStatsBadge old) {
    super.didUpdateWidget(old);
    if (old.dep != widget.dep || old.arr != widget.arr) {
      setState(() {
        _loaded = false;
        _stats = null;
      });
      _maybeLoad();
    }
  }

  Future<void> _maybeLoad() async {
    final key = '${widget.dep}/${widget.arr}';
    if (_lastKey == key) return;
    _lastKey = key;
    final result = await _service.load(widget.dep, widget.arr);
    if (!mounted) return;
    setState(() {
      _loaded = true;
      _stats = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const SizedBox.shrink();
    final stats = _stats;
    if (stats == null || !stats.hasData) return const SizedBox.shrink();

    final s = context.s;
    final fmt = NumberFormat.decimalPattern();
    final muted = widget.isDark
        ? AppColors.textMuted
        : UiConstants.lightTextMuted;

    final segments = <String>[];
    if (stats.todayCount > 0) {
      segments.add(s.routeTodayFlights
          .replaceFirst('{0}', fmt.format(stats.todayCount)));
    }
    if (stats.weekCount > 0) {
      segments.add(s.routeWeekFlights
          .replaceFirst('{0}', fmt.format(stats.weekCount)));
    }
    if (stats.monthCount > 0) {
      segments.add(s.routeMonthFlights
          .replaceFirst('{0}', fmt.format(stats.monthCount)));
    }
    if (segments.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.show_chart_rounded,
            size: 11,
            color: widget.primary.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              segments.join(' · '),
              style: TextStyle(
                fontFamily: UiConstants.bodyFont,
                fontSize: 9,
                color: muted,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
