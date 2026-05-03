import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class NeonText extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color color;
  final FontWeight fontWeight;
  final String fontFamily;
  final double glowRadius;
  final TextAlign? textAlign;

  const NeonText({
    super.key,
    required this.text,
    this.fontSize = 16,
    this.color = AppColors.primary,
    this.fontWeight = FontWeight.w700,
    this.fontFamily = 'Orbitron',
    this.glowRadius = 12,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!isDark) {
      return Text(
        text,
        textAlign: textAlign,
        style: TextStyle(
          fontFamily: fontFamily,
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          letterSpacing: 1.5,
        ),
      );
    }

    return Stack(
      children: [
        // Outer glow layer
        Text(
          text,
          textAlign: textAlign,
          style: TextStyle(
            fontFamily: fontFamily,
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: Colors.transparent,
            letterSpacing: 1.5,
            shadows: [
              Shadow(
                color: color.withValues(alpha: 0.6),
                blurRadius: glowRadius * 2.5,
              ),
              Shadow(
                color: color.withValues(alpha: 0.8),
                blurRadius: glowRadius,
              ),
              Shadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: glowRadius * 1.5,
              ),
            ],
          ),
        ),
        // Sharp text on top
        Text(
          text,
          textAlign: textAlign,
          style: TextStyle(
            fontFamily: fontFamily,
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}
