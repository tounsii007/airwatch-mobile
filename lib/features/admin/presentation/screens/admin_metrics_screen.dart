import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:airwatch_mobile/core/l10n/app_strings.dart';
import 'package:airwatch_mobile/core/theme/app_colors.dart';
import 'package:airwatch_mobile/core/widgets/glass_panel.dart';
import 'package:airwatch_mobile/features/admin/presentation/providers/admin_providers.dart';

/// Read-only admin live-metrics screen.
///
/// <p>Polls `/admin/api/overview` every 3 s via
/// [adminOverviewStreamProvider] and surfaces the same KPIs the web
/// dashboard's overview page shows: requests/sec, error rate, active HTTP /
/// WebSocket sessions, heap usage, total tracked flights, total backend
/// requests counter.
///
/// <p>No mutation buttons — the mobile dashboard is intentionally
/// observe-only. Anything that changes server state lives on the web app.
class AdminMetricsScreen extends ConsumerWidget {
  const AdminMetricsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref.watch(languageProvider));
    final async = ref.watch(adminOverviewStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.adminDashboard),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: s.adminSignOut,
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await ref.read(adminSignedInProvider.notifier).logout();
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text('${s.errorPrefix}: $e')),
        data:    (m) => m == null
            ? _OfflineState(title: s.adminOffline, hint: s.adminOfflineHint)
            : _buildBody(context, m, s),
      ),
    );
  }

  Widget _buildBody(BuildContext ctx, Map<String, dynamic> m, AppStrings s) {
    final rps     = (m['rps'] as num?)?.toDouble() ?? 0;
    final errPct  = (m['errorRate'] as num?)?.toDouble() ?? 0;
    final httpS   = (m['httpSessions'] as num?)?.toInt() ?? 0;
    final wsS     = (m['wsSessions'] as num?)?.toInt() ?? 0;
    final heap    = (m['heapUsagePercent'] as num?)?.toDouble() ?? 0;
    final flights = (m['flights'] as num?)?.toInt() ?? 0;
    final reqs    = (m['totalRequests'] as num?)?.toInt() ?? 0;

    return RefreshIndicator(
      onRefresh: () async => Future<void>.value(),
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Row(
            children: [
              Expanded(child: _Kpi(label: s.adminRpsLabel,
                                   value: rps.toStringAsFixed(1),
                                   color: AppColors.primary)),
              const SizedBox(width: 8),
              Expanded(child: _Kpi(label: s.adminErrorRate,
                                   value: errPct.toStringAsFixed(2),
                                   color: errPct > 5 ? AppColors.error : AppColors.success)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _Kpi(label: '${s.adminActive} (HTTP)',
                                   value: httpS.toString(),
                                   color: AppColors.info)),
              const SizedBox(width: 8),
              Expanded(child: _Kpi(label: '${s.adminActive} (WS)',
                                   value: wsS.toString(),
                                   color: AppColors.success)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _Kpi(label: s.adminHeap,
                                   value: '${heap.toStringAsFixed(1)} %',
                                   color: heap > 90 ? AppColors.error :
                                          heap > 75 ? AppColors.warning : AppColors.success)),
              const SizedBox(width: 8),
              Expanded(child: _Kpi(label: s.adminFlightsKpi,
                                   value: flights.toString(),
                                   color: AppColors.accent)),
            ],
          ),
          const SizedBox(height: 16),
          GlassPanel(
            borderRadius: 14,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
            child: Row(
              children: [
                Expanded(child: Text(s.adminTotalReqs,
                    style: const TextStyle(color: AppColors.textMuted, letterSpacing: 0.5))),
                Text(reqs.toString(), style: const TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color  color;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      borderRadius: 14,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11, letterSpacing: 0.8,
                  color: AppColors.textMuted, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}

class _OfflineState extends StatelessWidget {
  const _OfflineState({required this.title, required this.hint});
  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(hint,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted, height: 1.4)),
          ],
        ),
      ),
    );
  }
}
