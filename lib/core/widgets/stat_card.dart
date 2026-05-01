import 'package:flutter/material.dart';
import 'package:airwatch_mobile/core/constants/ui_constants.dart';
import 'package:airwatch_mobile/core/theme/app_colors.dart';
import 'package:airwatch_mobile/core/widgets/count_up.dart';
import 'package:airwatch_mobile/core/widgets/glass_panel.dart';

/// Pre-styled stat tile used on dashboard, stats, and admin overview.
///
/// <p>Mirrors the web frontend's `StatCard.tsx`. Stays presentation-only —
/// the parent supplies the value (which may itself be derived from a
/// store or API). This widget just animates the count-up + applies the
/// design language.
///
/// <p>Each card has:
/// <ul>
///   <li>a 3-letter / short uppercase label;</li>
///   <li>a large numeric value (animated via [CountUp],
///       gradient-tinted);</li>
///   <li>an optional secondary line (delta, unit, status badge);</li>
///   <li>an optional trend indicator (▲ / ▼ / –);</li>
///   <li>an optional accent icon rendered inside a soft tinted halo.</li>
/// </ul>
///
/// <p>The tile renders a faint decorative ring + corner glow keyed to the
/// status colour so a row of cards feels visually rich even when every
/// value is currently 0 (the "empty stats" state).
enum StatCardStatus { defaultStatus, success, warning, error, info }

enum StatCardTrend { up, down, flat }

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.decimals = 0,
    this.status = StatCardStatus.defaultStatus,
    this.trend,
    this.hint,
    this.icon,
    this.minHeight = 96,
  });

  /// Short uppercase label below the value (e.g. "ACTIVE FLIGHTS").
  final String label;

  /// Numeric value — animated via [CountUp]. Pass `null` while loading;
  /// the card renders a shimmer placeholder in that case.
  final num? value;

  /// Optional inline unit suffix (e.g. "kg", "%", "ms").
  final String? unit;

  /// Number of digits after the decimal point. Defaults to 0.
  final int decimals;

  /// Status colour key — drives the value colour, halo tint, and corner
  /// glow. Defaults to [StatCardStatus.defaultStatus] (primary).
  final StatCardStatus status;

  /// Optional up/down/flat trend indicator.
  final StatCardTrend? trend;

  /// Optional secondary line below the label (e.g. "vs last hour").
  final String? hint;

  /// Optional accent icon rendered inside a tinted halo on the right.
  final IconData? icon;

  /// Minimum tile height — keeps a row of cards visually consistent
  /// even when one of them has no hint / trend / icon.
  final double minHeight;

  Color _statusColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primary : UiConstants.lightPrimary;
    return switch (status) {
      StatCardStatus.defaultStatus => primary,
      StatCardStatus.success => AppColors.success,
      StatCardStatus.warning => AppColors.warning,
      StatCardStatus.error => AppColors.error,
      StatCardStatus.info => AppColors.info,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = _statusColor(context);
    final isLoading = value == null;
    final isZero = !isLoading && (value!.toDouble() == 0);
    final mutedColor = isDark
        ? AppColors.textMuted
        : UiConstants.lightTextMuted;

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: Stack(
        children: [
          // Glass panel — picks up the existing app aesthetic.
          GlassPanel(
            borderRadius: 14,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Value + label + hint stack ──
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DefaultTextStyle.merge(
                        style: TextStyle(
                          fontFamily: UiConstants.headingFont,
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                          // Zero values stay muted so the eye lands on
                          // cards that actually have data. Non-zero
                          // values get the status accent colour.
                          color: isZero ? mutedColor : accent,
                          height: 1.1,
                        ),
                        child: isLoading
                            ? _ShimmerBlock(width: 56, height: 22)
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CountUp(
                                    value: value!,
                                    decimals: decimals,
                                  ),
                                  if (unit != null) ...[
                                    const SizedBox(width: 3),
                                    Text(
                                      unit!,
                                      style: TextStyle(
                                        fontFamily: UiConstants.headingFont,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11,
                                        color: mutedColor,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: TextStyle(
                          fontFamily: UiConstants.headingFont,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                          color: mutedColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (hint != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          hint!,
                          style: TextStyle(
                            fontFamily: UiConstants.bodyFont,
                            fontSize: 10,
                            color: isDark
                                ? AppColors.textSecondary
                                : UiConstants.lightTextSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (trend != null && icon != null) ...[
                        const SizedBox(height: 4),
                        _TrendChip(trend: trend!),
                      ],
                    ],
                  ),
                ),

                // ── Icon halo on the right ──
                if (icon != null)
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.30),
                        width: 1,
                      ),
                    ),
                    child: Icon(icon, size: 18, color: accent),
                  )
                else if (trend != null)
                  _TrendChip(trend: trend!),
              ],
            ),
          ),

          // Top-right corner glow — matches web's
          // `radial-gradient(circle at 100% 0%, ...)` accent.
          Positioned(
            right: 0,
            top: 0,
            child: IgnorePointer(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(1, -1),
                    radius: 1.0,
                    colors: [
                      accent.withValues(alpha: 0.18),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.6],
                  ),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(14),
                  ),
                ),
              ),
            ),
          ),

          // Left accent bar — purely decorative; ties the card visually to
          // its status colour.
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 3,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.55),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendChip extends StatelessWidget {
  const _TrendChip({required this.trend});
  final StatCardTrend trend;

  @override
  Widget build(BuildContext context) {
    final (glyph, color) = switch (trend) {
      StatCardTrend.up => ('▲', AppColors.success),
      StatCardTrend.down => ('▼', AppColors.error),
      StatCardTrend.flat => ('–', AppColors.textMuted),
    };
    return Text(
      glyph,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: color,
      ),
    );
  }
}

class _ShimmerBlock extends StatefulWidget {
  const _ShimmerBlock({required this.width, required this.height});
  final double width;
  final double height;

  @override
  State<_ShimmerBlock> createState() => _ShimmerBlockState();
}

class _ShimmerBlockState extends State<_ShimmerBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    // Defer `.repeat()` to the next frame so the controller doesn't trip
    // `elapsedInSeconds >= 0.0` under flutter_test's FakeAsync clock.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ctl.repeat();
    });
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.06);
    final highlight = isDark
        ? Colors.white.withValues(alpha: 0.16)
        : Colors.black.withValues(alpha: 0.10);

    return AnimatedBuilder(
      animation: _ctl,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: LinearGradient(
              begin: Alignment(-1 + _ctl.value * 2, 0),
              end: Alignment(1 + _ctl.value * 2, 0),
              colors: [base, highlight, base],
            ),
          ),
        );
      },
    );
  }
}
