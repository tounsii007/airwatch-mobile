import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:airwatch_mobile/core/constants/ui_constants.dart';
import 'package:airwatch_mobile/core/l10n/app_strings.dart';
import 'package:airwatch_mobile/core/theme/app_colors.dart';
import 'package:airwatch_mobile/core/widgets/glass_panel.dart';
import 'package:airwatch_mobile/core/widgets/stat_card.dart';
import 'package:airwatch_mobile/features/flight_details/presentation/screens/flight_history_screen.dart';
import 'package:airwatch_mobile/features/stats/data/personal_stats_provider.dart';
import 'package:airwatch_mobile/features/stats/domain/stats_metrics.dart';

/// Personal tracking history — mirrors airwatch-web's `/stats` page
/// (commit 1e24147).
///
/// <p>Sections (top → bottom):
/// <ol>
///   <li>Summary KPI tiles — total / unique-airlines / unique-airports /
///       avg-views (the last only when there's any data, mirroring the
///       web's "no fake 0" empty-state).</li>
///   <li>Activity meta strip — tracking-since, days-active, peak hour.</li>
///   <li>24-hour activity histogram — pure-CSS bars, locale-stamped
///       axis ticks at 00 / 06 / 12 / 18.</li>
///   <li>Top airlines / top routes / top airports / recent flights —
///       four list cards, with the recent-list rendering a clear CTA on
///       each row to jump back to the live map.</li>
///   <li>Export + clear-history footer.</li>
/// </ol>
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref.watch(languageProvider));
    final stats = ref.watch(personalStatsProvider);
    final flights = stats.viewedFlights;
    final isEmpty = flights.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.stats),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (!isEmpty)
            IconButton(
              tooltip: s.statsExport,
              icon: const Icon(Icons.download_rounded, size: 20),
              onPressed: () => _showExportSheet(context, ref, s),
            ),
        ],
      ),
      body: isEmpty
          ? _EmptyState(s: s)
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
              child: _buildBody(context, ref, s, stats),
            ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    AppStrings s,
    PersonalStatsState stats,
  ) {
    final flights = stats.viewedFlights;
    final uniqueAirlines = countUniqueAirlines(flights);
    final uniqueAirports = countUniqueAirports(flights);
    final airlines = topAirlines(flights);
    final routes = topRoutes(flights);
    final airports = topAirports(flights);
    final hourBuckets = viewsByHour(flights);
    final summary = activitySummary(flights);

    // Avg views per flight — strip the trailing zero so "9" not "9.0",
    // matching web's render. NaN-safe via the empty-check above.
    final avgViews = flights.isEmpty
        ? 0.0
        : (stats.totalViews / flights.length * 10).round() / 10;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // KPI tiles
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: s.statsFlightsTracked,
                value: flights.length,
                icon: Icons.flight_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: StatCard(
                label: s.statsUniqueAirlines,
                value: uniqueAirlines,
                status: StatCardStatus.info,
                icon: Icons.business_center_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: s.statsUniqueAirports,
                value: uniqueAirports,
                status: StatCardStatus.success,
                icon: Icons.location_city_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: StatCard(
                label: s.statsAvgViewsPerFlight,
                value: avgViews,
                decimals: avgViews % 1 == 0 ? 0 : 1,
                status: StatCardStatus.warning,
                icon: Icons.visibility_outlined,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),
        _ActivityMetaStrip(summary: summary, s: s),

        const SizedBox(height: 12),
        _ActivityChart(buckets: hourBuckets, s: s),

        const SizedBox(height: 16),
        _TopList(
          title: s.statsTopAirlines,
          entries: airlines,
          tone: AppColors.primary,
          iconBuilder: (_) => const Icon(
            Icons.flight_rounded,
            size: 14,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        _TopList(
          title: s.statsTopRoutes,
          entries: routes,
          tone: AppColors.accent,
          iconBuilder: (_) => const Icon(
            Icons.alt_route_rounded,
            size: 14,
            color: AppColors.accent,
          ),
        ),
        const SizedBox(height: 12),
        _TopList(
          title: s.statsTopAirports,
          entries: airports,
          tone: AppColors.success,
          iconBuilder: (_) => const Icon(
            Icons.location_city_rounded,
            size: 14,
            color: AppColors.success,
          ),
        ),
        const SizedBox(height: 12),
        _RecentFlightsList(flights: flights, s: s),

        const SizedBox(height: 20),
        Center(
          child: TextButton.icon(
            onPressed: () => _confirmClear(context, ref, s),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error.withValues(alpha: 0.85),
            ),
            icon: const Icon(Icons.delete_outline_rounded, size: 16),
            label: Text(s.statsClear),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmClear(
    BuildContext context,
    WidgetRef ref,
    AppStrings s,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.statsClear),
        content: Text(s.statsClearConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(s.statsClear),
          ),
        ],
      ),
    );
    if (ok == true) {
      ref.read(personalStatsProvider.notifier).clear();
    }
  }

  Future<void> _showExportSheet(
    BuildContext context,
    WidgetRef ref,
    AppStrings s,
  ) async {
    final stats = ref.read(personalStatsProvider);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.code_rounded),
              title: Text(s.statsExportJson),
              onTap: () {
                Navigator.of(ctx).pop();
                _copyToClipboard(
                  ctx,
                  s,
                  _buildJson(stats),
                  s.statsExportJsonCopied,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.grid_on_rounded),
              title: Text(s.statsExportCsv),
              onTap: () {
                Navigator.of(ctx).pop();
                _copyToClipboard(
                  ctx,
                  s,
                  _buildCsv(stats.viewedFlights),
                  s.statsExportCsvCopied,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _buildJson(PersonalStatsState stats) {
    final payload = {
      'version': 1,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'totalViews': stats.totalViews,
      'flights': stats.viewedFlights.map((vf) => vf.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  String _buildCsv(List<ViewedFlight> flights) {
    final buf = StringBuffer();
    buf.writeln(
      'icao24,callsign,origin,destination,airline,views,firstSeenAt,lastSeenAt',
    );
    for (final f in flights) {
      buf.writeln(
        [
          f.icao24,
          f.callsign ?? '',
          f.originIata ?? '',
          f.destIata ?? '',
          f.airlineIcao ?? '',
          f.views,
          f.firstSeenAt.toUtc().toIso8601String(),
          f.lastSeenAt.toUtc().toIso8601String(),
        ].join(','),
      );
    }
    return buf.toString();
  }

  void _copyToClipboard(
    BuildContext context,
    AppStrings s,
    String payload,
    String message,
  ) {
    Clipboard.setData(ClipboardData(text: payload));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

// ─── Activity meta strip ────────────────────────────────────────────────
class _ActivityMetaStrip extends StatelessWidget {
  const _ActivityMetaStrip({required this.summary, required this.s});
  final ActivitySummary summary;
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    final since = summary.trackingSince;
    final sinceLabel = since == null ? '—' : _formatDate(since.toLocal());
    final daysLabel = summary.daysActive.toString();
    final peak = summary.peakHour;
    final peakLabel = peak == null
        ? '—'
        : '${peak.toString().padLeft(2, '0')}:00';

    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      borderRadius: 12,
      child: Row(
        children: [
          Expanded(
            child: _MetaCell(label: s.statsTrackingSince, value: sinceLabel),
          ),
          _MetaDivider(),
          Expanded(
            child: _MetaCell(label: s.statsDaysActive, value: daysLabel),
          ),
          _MetaDivider(),
          Expanded(
            child: _MetaCell(label: s.statsPeakHour, value: peakLabel),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime d) {
    final y = d.year.toString();
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}

class _MetaCell extends StatelessWidget {
  const _MetaCell({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: UiConstants.headingFont,
            fontSize: 8,
            letterSpacing: 1.0,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontFamily: UiConstants.headingFont,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

class _MetaDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 24,
    margin: const EdgeInsets.symmetric(horizontal: 8),
    color: AppColors.glassBorder.withValues(alpha: 0.4),
  );
}

// ─── 24-hour activity histogram ─────────────────────────────────────────
class _ActivityChart extends StatelessWidget {
  const _ActivityChart({required this.buckets, required this.s});
  final List<int> buckets;
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    final maxBucket = buckets.reduce((a, b) => a > b ? a : b);
    return GlassPanel(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      borderRadius: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.statsActivityChart,
            style: const TextStyle(
              fontFamily: UiConstants.headingFont,
              fontSize: 10,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 60,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List<Widget>.generate(24, (i) {
                final v = buckets[i];
                final ratio = maxBucket == 0 ? 0.0 : v / maxBucket;
                final height = (ratio * 56).clamp(2.0, 56.0);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0.5),
                    child: Tooltip(
                      message: '${i.toString().padLeft(2, '0')}:00 · $v',
                      child: Container(
                        height: height,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(
                            alpha: v == 0 ? 0.12 : 0.55,
                          ),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 4),
          // 00 / 06 / 12 / 18 ticks below the bars — tells the user that
          // peak hour is time-of-day, not "third bar from the right".
          Row(
            children: [
              for (final tick in const [0, 6, 12, 18])
                Expanded(
                  flex: 6,
                  child: Text(
                    tick.toString().padLeft(2, '0'),
                    style: const TextStyle(
                      fontFamily: UiConstants.bodyFont,
                      fontSize: 8,
                      color: AppColors.textMuted,
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

// ─── Top entries list (airlines / routes / airports) ────────────────────
class _TopList extends StatelessWidget {
  const _TopList({
    required this.title,
    required this.entries,
    required this.tone,
    required this.iconBuilder,
  });
  final String title;
  final List<CountEntry> entries;
  final Color tone;
  final Widget Function(int index) iconBuilder;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    final maxCount = entries.first.count;
    return GlassPanel(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      borderRadius: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: UiConstants.headingFont,
              fontSize: 10,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(entries.length, (i) {
            final e = entries[i];
            final ratio = maxCount == 0 ? 0.0 : e.count / maxCount;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  iconBuilder(i),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 80,
                    child: Text(
                      e.key,
                      style: const TextStyle(
                        fontFamily: UiConstants.headingFont,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Share bar — width is scaled against the topmost entry
                  // so the visual ratio between rows is comparable.
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 6,
                        backgroundColor: tone.withValues(alpha: 0.08),
                        valueColor: AlwaysStoppedAnimation(
                          tone.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 34,
                    child: Text(
                      e.count.toString(),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: UiConstants.headingFont,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: tone,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Recent flights list (search + sort + last N) ───────────────────────
//
// Mirrors airwatch-web's `RecentFlightsList.tsx` from commit 1e24147 —
// live filter input + recency-vs-views sort toggle. Tap on a row pushes
// the FlightHistoryScreen for that callsign (the closest mobile
// equivalent of web's /flight/[icao24] route).
enum _RecentSort { recency, views }

class _RecentFlightsList extends StatefulWidget {
  const _RecentFlightsList({required this.flights, required this.s});
  final List<ViewedFlight> flights;
  final AppStrings s;

  @override
  State<_RecentFlightsList> createState() => _RecentFlightsListState();
}

class _RecentFlightsListState extends State<_RecentFlightsList> {
  final _searchController = TextEditingController();
  String _q = '';
  _RecentSort _sort = _RecentSort.recency;
  static const _displayCap = 25;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.flights.isEmpty) return const SizedBox.shrink();
    final filtered = _filterAndSort(widget.flights);
    final rows = filtered.take(_displayCap).toList(growable: false);

    return GlassPanel(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      borderRadius: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.s.statsRecentFlights,
                  style: const TextStyle(
                    fontFamily: UiConstants.headingFont,
                    fontSize: 10,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              // Sort toggle — recency by default; tap to flip to view-
              // count rank. Tooltip explains the inverse of the current
              // selection so the user knows what the tap will do.
              IconButton(
                tooltip: _sort == _RecentSort.recency
                    ? widget.s.statsSortByViews
                    : widget.s.statsSortByRecency,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  _sort == _RecentSort.recency
                      ? Icons.access_time_rounded
                      : Icons.bar_chart_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
                onPressed: () => setState(() {
                  _sort = _sort == _RecentSort.recency
                      ? _RecentSort.views
                      : _RecentSort.recency;
                }),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Search input — live filter (no submit needed). Hidden when
          // the dataset is small enough that scanning is faster than
          // typing.
          if (widget.flights.length >= 5)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: SizedBox(
                height: 32,
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
                  style: const TextStyle(
                    fontFamily: UiConstants.headingFont,
                    fontSize: 12,
                    color: AppColors.primary,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                    hintText: widget.s.statsSearchHint,
                    hintStyle: const TextStyle(
                      fontFamily: UiConstants.bodyFont,
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(
                        color: AppColors.glassBorder.withValues(alpha: 0.5),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(
                        color: AppColors.glassBorder.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                widget.s.statsSearchNoMatch,
                style: TextStyle(
                  fontFamily: UiConstants.bodyFont,
                  fontSize: 11,
                  color: AppColors.textMuted.withValues(alpha: 0.8),
                ),
              ),
            )
          else
            for (final f in rows) _Row(flight: f, s: widget.s),
        ],
      ),
    );
  }

  List<ViewedFlight> _filterAndSort(List<ViewedFlight> flights) {
    Iterable<ViewedFlight> out = flights;
    if (_q.isNotEmpty) {
      out = out.where((f) {
        final cs = (f.callsign ?? '').toLowerCase();
        final icao = f.icao24.toLowerCase();
        final airline = (f.airlineIcao ?? '').toLowerCase();
        final orig = (f.originIata ?? '').toLowerCase();
        final dest = (f.destIata ?? '').toLowerCase();
        return cs.contains(_q) ||
            icao.contains(_q) ||
            airline.contains(_q) ||
            orig.contains(_q) ||
            dest.contains(_q);
      });
    }
    final list = out.toList();
    switch (_sort) {
      case _RecentSort.recency:
        list.sort((a, b) => b.lastSeenAt.compareTo(a.lastSeenAt));
        break;
      case _RecentSort.views:
        list.sort((a, b) => b.views.compareTo(a.views));
        break;
    }
    return list;
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.flight, required this.s});
  final ViewedFlight flight;
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    final cs = flight.callsign?.isNotEmpty == true
        ? flight.callsign!
        : flight.icao24.toUpperCase();
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => FlightHistoryScreen(initialCallsign: cs),
        ),
      ),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 2),
        child: Row(
          children: [
            SizedBox(
              width: 60,
              child: Text(
                cs,
                style: const TextStyle(
                  fontFamily: UiConstants.headingFont,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                flight.originIata != null && flight.destIata != null
                    ? '${flight.originIata} → ${flight.destIata}'
                    : '—',
                style: const TextStyle(
                  fontFamily: UiConstants.bodyFont,
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (flight.views > 1) ...[
              Icon(
                Icons.visibility_outlined,
                size: 10,
                color: AppColors.textMuted.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 2),
              Text(
                '${flight.views}',
                style: const TextStyle(
                  fontFamily: UiConstants.headingFont,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              _formatRelative(flight.lastSeenAt),
              style: const TextStyle(
                fontFamily: UiConstants.bodyFont,
                fontSize: 10,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatRelative(DateTime when) {
    final diff = DateTime.now().difference(when);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}

// ─── Empty state ────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.s});
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.timeline_rounded,
              size: 56,
              color: AppColors.textMuted.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              s.statsEmptyTitle,
              style: const TextStyle(
                fontFamily: UiConstants.headingFont,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              s.statsEmptyHint,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: UiConstants.bodyFont,
                fontSize: 12,
                color: AppColors.textMuted.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
