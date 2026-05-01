import 'package:flutter/material.dart';

class AppColors {
  // ═══ Primary palette — Steel Blue / Silver (matching AIRWATCH branding) ═══
  static const Color primary = Color(0xFF7A9ABF);       // Steel blue
  static const Color primaryDark = Color(0xFF4A6B8A);    // Dark steel
  static const Color primaryLight = Color(0xFFB0C4D8);   // Light steel

  // Accent — Warm silver/gold highlight
  static const Color accent = Color(0xFFD4A574);         // Warm bronze
  static const Color accentLight = Color(0xFFE8C49A);    // Light bronze

  // ═══ Background layers — Deep navy ═══
  static const Color background = Color(0xFF0A1628);     // Dark navy
  static const Color surface = Color(0xFF0F1D32);        // Surface navy
  static const Color surfaceLight = Color(0xFF1A2E48);   // Lighter navy

  // Card
  static const Color cardBackground = Color(0x330F1D32);
  static const Color cardBorder = Color(0x447A9ABF);

  // Glass morphism
  static const Color glassBackground = Color(0x1A4A6B8A);
  static const Color glassBorder = Color(0x337A9ABF);

  // ═══ Text ═══
  static const Color textPrimary = Color(0xFFD0D8E4);    // Silver white
  static const Color textSecondary = Color(0xFF8A9BB0);  // Steel grey
  static const Color textMuted = Color(0xFF4A5F78);      // Muted steel

  // ═══ Status — kept distinct for readability ═══
  static const Color success = Color(0xFF4ADE80);        // Soft green
  static const Color warning = Color(0xFFFBBF24);        // Amber
  static const Color error = Color(0xFFF87171);          // Soft red
  static const Color info = Color(0xFF60A5FA);           // Blue

  // ═══ Altitude colors — adjusted to match steel palette ═══
  static const Color altitudeLow = Color(0xFF4ADE80);    // < 10,000 ft — green
  static const Color altitudeMedium = Color(0xFFFBBF24); // 10k-30k ft — amber
  static const Color altitudeHigh = Color(0xFFE879A8);   // > 30k ft — rose

  // ═══ Map ═══
  static const Color mapGrid = Color(0x1A4A6B8A);
  static const Color mapAirportGlow = Color(0xFF7A9ABF);
  static const Color flightTrail = Color(0x887A9ABF);
  static const Color radarSweep = Color(0x334A6B8A);

  // ═══ Gradients ═══
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryDark, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [surface, Color(0xFF0B1420)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, accentLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const RadialGradient radarGradient = RadialGradient(
    colors: [
      Color(0x334A6B8A),
      Color(0x114A6B8A),
      Color(0x004A6B8A),
    ],
  );
}
