import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:airwatch_mobile/core/theme/app_colors.dart';

/// Centralised `fl_chart` styling so every chart in the app — and
/// every future chart — shares the same neon-glass aesthetic without each
/// callsite re-declaring axis colours, grid stroke widths and tooltip
/// padding.
///
/// <h3>How to use</h3>
/// ```dart
///   LineChart(
///     ChartTheme.lineChart(
///       spots: spots,
///       primary: AppColors.primary,
///     ),
///   );
/// ```
///
/// <p>Each helper takes the data + the brand colour and returns a fully
/// themed [LineChartData] / [BarChartData] object — callers
/// can still override individual properties via `.copyWith` on the
/// returned object if a one-off needs more chrome.
class ChartTheme {
  ChartTheme._();

  // ── Palette helpers ──────────────────────────────────────────────────────
  static Color  get gridColor   => AppColors.glassBorder;
  static Color  get axisColor   => AppColors.textMuted;
  static double get gridStroke  => 0.6;

  /// Tooltip box used by every line / bar chart. Glass-panel-ish, with the
  /// app's text-muted colour for labels so it sits naturally inside the
  /// surrounding `GlassPanel`.
  static Color get tooltipBg => AppColors.surface.withValues(alpha: 0.92);

  // ── LineChart ────────────────────────────────────────────────────────────
  /// Build a fully themed [LineChartData].
  ///
  /// Defaults emphasise the brand colour (`primary`) and hide chart
  /// chrome unless explicitly enabled — that way Dashboard sparklines
  /// stay clean while a Stats screen can opt in to axis labels.
  static LineChartData lineChart({
    required List<FlSpot> spots,
    required Color        primary,
    bool                  showAxes      = false,
    bool                  showGrid      = false,
    bool                  fillBelow     = true,
    bool                  enableTooltip = false,
    double?               minY,
    double?               maxY,
  }) {
    return LineChartData(
      titlesData: FlTitlesData(
        show: showAxes,
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: showAxes,
            reservedSize: 32,
            getTitlesWidget: (v, _) => Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(_compact(v),
                  style: TextStyle(fontSize: 9, color: axisColor)),
            ),
          ),
        ),
        rightTitles: const AxisTitles(),
        topTitles:   const AxisTitles(),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: showAxes,
            getTitlesWidget: (v, _) => Text(v.toStringAsFixed(0),
                style: TextStyle(fontSize: 9, color: axisColor)),
          ),
        ),
      ),
      gridData: FlGridData(
        show: showGrid,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (_) =>
            FlLine(color: gridColor, strokeWidth: gridStroke),
      ),
      borderData: FlBorderData(show: false),
      lineTouchData: enableTooltip
          ? LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => tooltipBg,
                tooltipBorder: const BorderSide(color: AppColors.glassBorder),
                tooltipPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                getTooltipItems: (touched) => touched.map((t) {
                  return LineTooltipItem(
                    t.y.toStringAsFixed(0),
                    TextStyle(
                        color: primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 11),
                  );
                }).toList(),
              ),
            )
          : const LineTouchData(enabled: false),
      minY: minY,
      maxY: maxY,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.3,
          color: primary,
          dotData: const FlDotData(show: false),
          belowBarData: fillBelow
              ? BarAreaData(
                  show: true,
                  color: primary.withValues(alpha: 0.18),
                )
              : BarAreaData(),
        ),
      ],
    );
  }

  // ── BarChart ─────────────────────────────────────────────────────────────
  /// Build a fully themed [BarChartData]. Pass one or more rod values
  /// per group via `groups`; colours rotate through the supplied
  /// `palette` so multi-series bars stay visually distinct.
  static BarChartData barChart({
    required List<double> values,
    Color?                primary,
    List<Color>?          palette,
    double                rodWidth = 12,
    bool                  showAxes = false,
    bool                  enableTooltip = false,
  }) {
    final colours = palette ??
        [primary ?? AppColors.primary, AppColors.success, AppColors.accent, AppColors.info];
    return BarChartData(
      titlesData: FlTitlesData(
        show: showAxes,
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: showAxes,
            reservedSize: 26,
            getTitlesWidget: (v, _) => Text(_compact(v),
                style: TextStyle(fontSize: 9, color: axisColor)),
          ),
        ),
        rightTitles: const AxisTitles(),
        topTitles:   const AxisTitles(),
        bottomTitles: const AxisTitles(),
      ),
      gridData: FlGridData(
        show: showAxes,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (_) =>
            FlLine(color: gridColor, strokeWidth: gridStroke),
      ),
      borderData: FlBorderData(show: false),
      barTouchData: enableTooltip
          ? BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => tooltipBg,
                tooltipPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                  rod.toY.toStringAsFixed(0),
                  TextStyle(
                      color: rod.color ?? colours.first,
                      fontWeight: FontWeight.w800,
                      fontSize: 11),
                ),
              ),
            )
          : BarTouchData(enabled: false),
      barGroups: [
        for (var i = 0; i < values.length; i++)
          BarChartGroupData(x: i, barRods: [
            BarChartRodData(
              toY: values[i],
              color: colours[i % colours.length],
              width: rodWidth,
              borderRadius: BorderRadius.circular(2),
            ),
          ]),
      ],
    );
  }

  /// 1.2k / 480 / 35 — the kind of compact label fl_chart axes need so they
  /// don't overlap each other on small dashboard tiles.
  static String _compact(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(v >= 10000 ? 0 : 1)}k';
    return v.toStringAsFixed(0);
  }
}
