import 'package:flutter/material.dart';
import 'package:airwatch_mobile/core/constants/ui_constants.dart';
import 'package:airwatch_mobile/core/theme/app_colors.dart';

class SearchSectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final bool isDark;

  const SearchSectionHeader({
    super.key,
    required this.title,
    required this.count,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontFamily: UiConstants.headingFont,
              fontSize: UiConstants.microFontSize,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textSecondary : UiConstants.lightTextSecondary,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '($count)',
            style: TextStyle(
              fontFamily: UiConstants.bodyFont,
              fontSize: UiConstants.microFontSize,
              color: isDark ? AppColors.textMuted : UiConstants.lightTextMuted,
            ),
          ),
        ],
      ),
    );
  }
}
