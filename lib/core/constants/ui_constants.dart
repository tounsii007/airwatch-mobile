import 'package:flutter/material.dart';

class UiConstants {
  static const String headingFont = 'Orbitron';
  static const String bodyFont = 'Rajdhani';

  static const Color lightPrimary = Color(0xFF0077B6);
  // Off-white surfaces match airwatch-web iter 73. The previous #F0F4F8 carried
  // a faint blue cast that mismatched the new neutral dark theme; pure-neutral
  // greys ensure both themes share the same "no blue background" rule.
  static const Color lightBackground = Color(0xFFFAFAFA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE5E5E5);
  static const Color lightTextPrimary = Color(0xFF1A1A2E);
  static const Color lightTextSecondary = Color(0xFF6B7280);
  static const Color lightTextMuted = Color(0xFF9CA3AF);
  static const Color lightHintText = Color(0xFFADB5BD);
  static const Color lightDisabled = Color(0xFFD1D5DB);

  static const String unknownValue = 'Unknown';
  static const String missingCode = '???';

  static const Duration retryDelay = Duration(seconds: 5);

  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: 16);
  static const EdgeInsets searchHeaderPadding = EdgeInsets.fromLTRB(
    16,
    8,
    16,
    0,
  );
  static const EdgeInsets searchResultsPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 4,
  );
  static const EdgeInsets panelHeaderPadding = EdgeInsets.fromLTRB(
    14,
    12,
    10,
    10,
  );
  static const EdgeInsets panelSectionPadding = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 12,
  );
  static const EdgeInsets panelCompactSectionPadding = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 8,
  );

  static const double searchHeaderFontSize = 20;
  static const double bodyFontSize = 14;
  static const double captionFontSize = 12;
  static const double microFontSize = 10;
  static const double tinyFontSize = 9;
}
