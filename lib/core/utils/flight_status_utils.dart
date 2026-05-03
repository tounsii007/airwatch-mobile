import 'package:flutter/material.dart';
import 'package:airwatch_mobile/core/constants/config.dart';
import 'package:airwatch_mobile/core/constants/conversion_constants.dart';
import 'package:airwatch_mobile/core/l10n/ui_text.dart';
import 'package:airwatch_mobile/core/theme/app_colors.dart';

/// Centralized flight status utilities.
/// Eliminates duplication of status color/label logic across UI files.
class FlightStatusUtils {
  /// Returns the color for a given flight status string.
  static Color statusColor(String? status, {required Color primary}) {
    return switch (status?.toLowerCase()) {
      'en-route' || 'active' => AppColors.success,
      'landed' => primary,
      'scheduled' => AppColors.warning,
      'cancelled' => AppColors.error,
      _ => AppColors.textMuted,
    };
  }

  /// Returns a short localized label for a given flight status.
  static String statusLabel(BuildContext context, String? status) {
    return switch (status?.toLowerCase()) {
      'en-route' || 'active' => context.tr('live_badge'),
      'landed' => context.tr('landed_badge'),
      'scheduled' => context.tr('scheduled_badge'),
      'cancelled' => context.tr('cancelled_short'),
      _ => status?.toUpperCase() ?? '',
    };
  }

  /// Simplified altitude color for data displays (not map markers).
  static Color altitudeColor(double? altitudeMeters) {
    if (altitudeMeters == null) return AppColors.textMuted;
    final feet = altitudeMeters * ConversionConstants.metersToFeet;
    if (feet < AppConfig.altitudeGroundMax)
      return const Color(AppConfig.groundColor);
    if (feet < AppConfig.altitudeLowMax) return AppColors.altitudeLow;
    if (feet < AppConfig.altitudeMedMax) return AppColors.altitudeMedium;
    return AppColors.altitudeHigh;
  }
}
