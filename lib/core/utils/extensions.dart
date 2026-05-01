import 'dart:math' as math;
import '../constants/conversion_constants.dart';

extension DoubleExtensions on double {
  /// Convert meters to feet
  double get metersToFeet => this * ConversionConstants.metersToFeet;

  /// Convert meters/second to knots
  double get msToKnots => this * ConversionConstants.msToKnots;

  /// Convert meters/second to km/h
  double get msToKmh => this * ConversionConstants.msToKmh;

  /// Convert degrees to radians
  double get toRadians => this * (math.pi / 180.0);

  /// Convert radians to degrees
  double get toDegrees => this * (180.0 / math.pi);

  /// Format altitude in feet with commas
  String formatAltitude() {
    final feet = metersToFeet;
    if (feet < 1000) return '${feet.round()} ft';
    return '${(feet / 1000).toStringAsFixed(1)}k ft';
  }

  /// Format speed in knots
  String formatSpeed() {
    final knots = msToKnots;
    return '${knots.round()} kts';
  }

  /// Format heading as compass direction
  String formatHeading() {
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final index = ((this + 22.5) % 360 / 45).floor();
    return '${round()}° ${directions[index]}';
  }
}

extension IntExtensions on int {
  /// Format with leading zeros
  String padLeft2() => toString().padLeft(2, '0');
}

extension DateTimeExtensions on DateTime {
  String formatTime() => '${hour.padLeft2()}:${minute.padLeft2()}';

  String formatDateTime() =>
      '${day.padLeft2()}/${month.padLeft2()} ${formatTime()}';

  String formatRelative() {
    final now = DateTime.now();
    final diff = now.difference(this);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

extension StringExtensions on String {
  /// Capitalize first letter
  String get capitalize =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  /// Get airline name from ICAO callsign (first 3 letters)
  String get airlineIcao =>
      length >= 3 ? substring(0, 3).toUpperCase() : toUpperCase();
}
