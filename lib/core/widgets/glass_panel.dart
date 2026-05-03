import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blur;
  final Color? borderColor;
  final Color? backgroundColor;
  final double opacity;
  final bool glowBorder;

  const GlassPanel({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 16,
    this.blur = 14,
    this.borderColor,
    this.backgroundColor,
    this.opacity = 0.22,
    this.glowBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: margin,
      decoration: glowBorder && isDark
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  blurRadius: 16,
                  spreadRadius: -4,
                ),
              ],
            )
          : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? (backgroundColor ??
                        AppColors.surface.withValues(alpha: opacity))
                  : (backgroundColor ?? Colors.white.withValues(alpha: 0.88)),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: isDark
                    ? (borderColor ?? AppColors.primary.withValues(alpha: 0.18))
                    : (borderColor ?? const Color(0xFFE2E8F0)),
                width: isDark ? 1.0 : 0.5,
              ),
              boxShadow: isDark
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.06),
                        blurRadius: 24,
                        spreadRadius: -6,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 20,
                        spreadRadius: -5,
                      ),
                    ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class GlowingBorder extends StatelessWidget {
  final Widget child;
  final Color glowColor;
  final double borderRadius;
  final double glowIntensity;

  const GlowingBorder({
    super.key,
    required this.child,
    this.glowColor = AppColors.primary,
    this.borderRadius = 16,
    this.glowIntensity = 0.3,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: glowIntensity),
            blurRadius: 16,
            spreadRadius: -2,
          ),
          BoxShadow(
            color: glowColor.withValues(alpha: glowIntensity * 0.4),
            blurRadius: 30,
            spreadRadius: -6,
          ),
        ],
      ),
      child: child,
    );
  }
}
