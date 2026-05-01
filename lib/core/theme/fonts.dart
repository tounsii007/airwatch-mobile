import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppFonts {
  static TextStyle orbitron({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w700,
    Color? color,
    double letterSpacing = 1.5,
    List<Shadow>? shadows,
  }) {
    return GoogleFonts.orbitron(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      shadows: shadows,
    );
  }

  static TextStyle rajdhani({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w500,
    Color? color,
    double letterSpacing = 0,
  }) {
    return GoogleFonts.rajdhani(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  static String get orbitronFamily => GoogleFonts.orbitron().fontFamily!;
  static String get rajdhaniFamily => GoogleFonts.rajdhani().fontFamily!;
}
