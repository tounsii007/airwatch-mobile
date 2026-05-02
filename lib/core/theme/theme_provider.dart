import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:airwatch_mobile/core/constants/ui_constants.dart';
import 'app_colors.dart';

enum AppThemeMode { dark, light, system }

class ThemeNotifier extends Notifier<AppThemeMode> {
  @override
  AppThemeMode build() {
    _loadTheme();
    return AppThemeMode.dark;
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString('theme_mode') ?? 'dark';
    state = AppThemeMode.values.firstWhere(
      (e) => e.name == mode,
      orElse: () => AppThemeMode.dark,
    );
  }

  Future<void> setTheme(AppThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode.name);
  }

  Future<void> toggle() async {
    final next =
        state == AppThemeMode.dark ? AppThemeMode.light : AppThemeMode.dark;
    await setTheme(next);
  }
}

final themeProvider =
    NotifierProvider<ThemeNotifier, AppThemeMode>(ThemeNotifier.new);

final themeDataProvider = Provider<ThemeData>((ref) {
  final mode = ref.watch(themeProvider);
  switch (mode) {
    case AppThemeMode.dark:
      return _darkTheme;
    case AppThemeMode.light:
      return _lightTheme;
    case AppThemeMode.system:
      return _darkTheme;
  }
});

// --- Dark Theme ---
final ThemeData _darkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: AppColors.background,
  primaryColor: AppColors.primary,
  colorScheme: const ColorScheme.dark(
    primary: AppColors.primary,
    secondary: AppColors.accent,
    surface: AppColors.surface,
    error: AppColors.error,
  ),
  fontFamily: UiConstants.bodyFont,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(
      fontFamily: UiConstants.headingFont,
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: AppColors.primary,
      letterSpacing: 2,
    ),
  ),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
        fontFamily: UiConstants.headingFont, fontSize: 28, fontWeight: FontWeight.w700,
        color: AppColors.textPrimary, letterSpacing: 2),
    headlineMedium: TextStyle(
        fontFamily: UiConstants.headingFont, fontSize: 20, fontWeight: FontWeight.w700,
        color: AppColors.textPrimary, letterSpacing: 1.5),
    headlineSmall: TextStyle(
        fontFamily: UiConstants.headingFont, fontSize: 16, fontWeight: FontWeight.w700,
        color: AppColors.textPrimary, letterSpacing: 1),
    titleLarge: TextStyle(
        fontFamily: UiConstants.bodyFont, fontSize: 22, fontWeight: FontWeight.w700,
        color: AppColors.textPrimary),
    titleMedium: TextStyle(
        fontFamily: UiConstants.bodyFont, fontSize: 18, fontWeight: FontWeight.w500,
        color: AppColors.textPrimary),
    bodyLarge: TextStyle(
        fontFamily: UiConstants.bodyFont, fontSize: 16, fontWeight: FontWeight.w500,
        color: AppColors.textSecondary),
    bodyMedium: TextStyle(
        fontFamily: UiConstants.bodyFont, fontSize: 14, color: AppColors.textSecondary),
    labelLarge: TextStyle(
        fontFamily: UiConstants.bodyFont, fontSize: 14, fontWeight: FontWeight.w700,
        color: AppColors.primary, letterSpacing: 1),
  ),
  iconTheme: const IconThemeData(color: AppColors.primary),
  cardTheme: CardThemeData(
    color: AppColors.cardBackground,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: AppColors.cardBorder),
    ),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: AppColors.surface,
    selectedItemColor: AppColors.primary,
    unselectedItemColor: AppColors.textMuted,
    type: BottomNavigationBarType.fixed,
    elevation: 0,
  ),
);

// --- Light Theme ---
final ThemeData _lightTheme = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: UiConstants.lightBackground,
  primaryColor: UiConstants.lightPrimary,
  colorScheme: const ColorScheme.light(
    primary: UiConstants.lightPrimary,
    secondary: Color(0xFFE0256C),
    error: Color(0xFFD32F2F),
  ),
  fontFamily: UiConstants.bodyFont,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(
        fontFamily: UiConstants.headingFont, fontSize: 18, fontWeight: FontWeight.w700,
        color: UiConstants.lightPrimary, letterSpacing: 2),
    iconTheme: IconThemeData(color: UiConstants.lightPrimary),
  ),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
        fontFamily: UiConstants.headingFont, fontSize: 28, fontWeight: FontWeight.w700,
        color: UiConstants.lightTextPrimary, letterSpacing: 2),
    headlineMedium: TextStyle(
        fontFamily: UiConstants.headingFont, fontSize: 20, fontWeight: FontWeight.w700,
        color: UiConstants.lightTextPrimary, letterSpacing: 1.5),
    headlineSmall: TextStyle(
        fontFamily: UiConstants.headingFont, fontSize: 16, fontWeight: FontWeight.w700,
        color: UiConstants.lightTextPrimary, letterSpacing: 1),
    titleLarge: TextStyle(
        fontFamily: UiConstants.bodyFont, fontSize: 22, fontWeight: FontWeight.w700,
        color: UiConstants.lightTextPrimary),
    titleMedium: TextStyle(
        fontFamily: UiConstants.bodyFont, fontSize: 18, fontWeight: FontWeight.w500,
        color: UiConstants.lightTextPrimary),
    bodyLarge: TextStyle(
        fontFamily: UiConstants.bodyFont, fontSize: 16, fontWeight: FontWeight.w500,
        color: Color(0xFF4A5568)),
    bodyMedium: TextStyle(
        fontFamily: UiConstants.bodyFont, fontSize: 14, color: Color(0xFF4A5568)),
    labelLarge: TextStyle(
        fontFamily: UiConstants.bodyFont, fontSize: 14, fontWeight: FontWeight.w700,
        color: UiConstants.lightPrimary, letterSpacing: 1),
  ),
  iconTheme: const IconThemeData(color: UiConstants.lightPrimary),
  cardTheme: CardThemeData(
    color: Colors.white,
    elevation: 2,
    shadowColor: Colors.black12,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: UiConstants.lightBorder),
    ),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Colors.white,
    selectedItemColor: UiConstants.lightPrimary,
    unselectedItemColor: UiConstants.lightHintText,
    type: BottomNavigationBarType.fixed,
    elevation: 8,
  ),
);
