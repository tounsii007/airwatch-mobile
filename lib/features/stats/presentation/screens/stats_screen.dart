import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:airwatch_mobile/core/constants/api_constants.dart';
import 'package:airwatch_mobile/core/l10n/app_strings.dart';
import 'package:airwatch_mobile/core/network/app_http_client.dart';
import 'package:airwatch_mobile/core/theme/app_colors.dart';
import 'package:airwatch_mobile/core/widgets/stat_card.dart';

/// Global flight statistics sourced from `GET /api/stats` on the
/// airwatch-api backend — same shape the web app consumes.
///
/// <p>Response contract (from `FlightController#stats`):
/// ```json
/// {
///   "total":           1245,
///   "airborne":         980,
///   "onGround":         265,
///   "requestCount":   15000,
///   "lastPollTime":   1710000000000,
///   "topAirlines": [ { "icao": "DLH", "count": 42 } ]
/// }
/// ```
///
/// <p>Refreshes every 30 seconds while visible (the backend already caches
/// the aggregation server-side, so polling is cheap).
final _statsStreamProvider = StreamProvider.autoDispose<Map<String, dynamic>>((
  ref,
) async* {
  final dio = AppHttpClient.create();
  while (true) {
    try {
      final r = await dio.get<dynamic>(ApiConstants.flightStats);
      if (r.statusCode == 200 && r.data is Map) {
        yield Map<String, dynamic>.from(r.data as Map);
      }
    } on DioException {
      // Swallow — next tick retries. Don't tear the stream down.
    }
    await Future<void>.delayed(const Duration(seconds: 30));
  }
});

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref.watch(languageProvider));
    final async = ref.watch(_statsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.stats),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('${s.errorPrefix}: $e')),
        data: (data) => _buildBody(s, data),
      ),
    );
  }

  Widget _buildBody(AppStrings s, Map<String, dynamic> data) {
    final total = (data['total'] as num?)?.toInt() ?? 0;
    final airborne = (data['airborne'] as num?)?.toInt() ?? 0;
    final onGround = (data['onGround'] as num?)?.toInt() ?? 0;
    final reqCount = (data['requestCount'] as num?)?.toInt() ?? 0;
    final topList = (data['topAirlines'] as List?) ?? const [];

    // Per the airwatch-web stats overhaul: only show the "AVG VIEWS /
    // FLIGHT" tile when there's actually data. With zero flights every
    // ratio is `0 / 0 = NaN`, and a fourth screaming-zero tile would just
    // make the empty state noisier.
    final hasAnyData = total > 0;
    final avgPerFlight = total == 0 ? 0.0 : reqCount / total;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // ── Top KPI row — uses the rich StatCard with halo + accent bar.
          //    Mirrors the web's SummaryRow + StatCard combo so a stat-conscious
          //    user sees the same visual language across both clients.
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: s.statsFlightsTracked,
                  value: total,
                  icon: Icons.flight_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StatCard(
                  label: s.statsAirborne,
                  value: airborne,
                  status: StatCardStatus.success,
                  icon: Icons.flight_takeoff_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: s.statsOnGround,
                  value: onGround,
                  status: StatCardStatus.warning,
                  icon: Icons.flight_land_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StatCard(
                  label: s.statsAirlabsCalls,
                  value: reqCount,
                  status: StatCardStatus.info,
                  icon: Icons.cloud_sync_rounded,
                ),
              ),
            ],
          ),
          // Fourth tile — only shown when there's data, matching the
          // web's hide-zero-state behaviour.
          if (hasAnyData) ...[
            const SizedBox(height: 8),
            StatCard(
              label: s.statsAvgViewsPerFlight,
              value: avgPerFlight,
              decimals: 1,
              icon: Icons.bar_chart_rounded,
            ),
          ],

          const SizedBox(height: 16),
          _SectionTitle(s.statsTopAirlines),
          const SizedBox(height: 8),
          if (topList.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(s.statsNoData),
              ),
            )
          else
            ...topList.take(20).map((row) {
              final m = row as Map;
              return _AirlineRow(
                icao: (m['icao'] as String?) ?? '—',
                count: (m['count'] as num?)?.toInt() ?? 0,
                flightsLabel: s.statsFlightsLabel,
              );
            }),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  // ignore: unused_element_parameter
  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          letterSpacing: 1.2,
          color: AppColors.textMuted,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AirlineRow extends StatelessWidget {
  const _AirlineRow({
    required this.icao,
    required this.count,
    required this.flightsLabel,
  });
  final String icao;
  final int count;
  final String flightsLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              icao,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              icao,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            '$count $flightsLabel',
            style: const TextStyle(
              color: AppColors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
