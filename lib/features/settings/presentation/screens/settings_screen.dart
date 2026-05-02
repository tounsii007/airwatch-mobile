import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:airwatch_mobile/core/constants/settings_provider.dart';
import 'package:airwatch_mobile/core/constants/ui_constants.dart';
import 'package:airwatch_mobile/core/l10n/app_strings.dart';
import 'package:airwatch_mobile/core/l10n/ui_text.dart';
import 'package:airwatch_mobile/core/theme/app_colors.dart';
import 'package:airwatch_mobile/core/theme/theme_provider.dart';
import 'package:airwatch_mobile/core/widgets/glass_panel.dart';
import 'package:airwatch_mobile/core/widgets/neon_text.dart';
import 'package:airwatch_mobile/features/admin/presentation/providers/admin_providers.dart';
import 'package:airwatch_mobile/features/admin/presentation/screens/admin_login_screen.dart';
import 'package:airwatch_mobile/features/admin/presentation/screens/admin_metrics_screen.dart';
import 'package:airwatch_mobile/features/airlines/presentation/screens/airlines_screen.dart';
import 'package:airwatch_mobile/features/cargo/presentation/screens/cargo_screen.dart';
import 'package:airwatch_mobile/features/compare/presentation/screens/compare_screen.dart';
import 'package:airwatch_mobile/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:airwatch_mobile/features/geofences/presentation/screens/geofences_screen.dart';
import 'package:airwatch_mobile/features/globe/presentation/screens/globe_screen.dart';
import 'package:airwatch_mobile/features/spotting/presentation/screens/spotting_screen.dart';
import 'package:airwatch_mobile/features/stats/presentation/screens/stats_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primary : UiConstants.lightPrimary;
    final themeMode = ref.watch(themeProvider);
    final settings = ref.watch(settingsProvider);
    final currentLang = ref.watch(languageProvider);
    final s = S.of(currentLang);

    return Scaffold(
      backgroundColor: isDark ? AppColors.background : UiConstants.lightBackground,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            NeonText(text: s.settings, fontSize: UiConstants.searchHeaderFontSize, color: primary,
                glowRadius: isDark ? 10 : 0),
            const SizedBox(height: 20),

            // ═══ MORE FEATURES ═══════════════════════════════════════════
            // Mirrors the airwatch-web side-nav: every feature surface the
            // web app exposes has an entry point here, so the mobile user
            // can reach the same set of screens. Replay is reachable via
            // any flight detail, so it isn't repeated in this list.
            _Sec(s.featuresHeader, isDark),
            const SizedBox(height: 8),
            GlassPanel(borderRadius: 14, padding: const EdgeInsets.all(4), child: Column(children: [
              _NavTile(Icons.flight_takeoff, s.airlines, s.airlinesCarriers,
                  primary, isDark,
                  () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const AirlinesScreen()))),
              _Div(isDark),
              _NavTile(Icons.local_shipping_outlined, s.cargo, s.cargoSubtitle,
                  primary, isDark,
                  () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const CargoScreen()))),
              _Div(isDark),
              // `Icons.binoculars_outlined` does not exist in Material Icons —
              // `visibility_outlined` is the closest stand-in for the spotting
              // metaphor (eyes / observing aircraft from the ground).
              _NavTile(Icons.visibility_outlined, s.spotting, s.spottingSubtitle,
                  primary, isDark,
                  () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const SpottingScreen()))),
              _Div(isDark),
              _NavTile(Icons.dashboard_outlined, s.dashboard, s.dashSubtitle,
                  primary, isDark,
                  () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const DashboardScreen()))),
              _Div(isDark),
              _NavTile(Icons.bar_chart_rounded, s.stats, s.statsTopAirlines,
                  primary, isDark,
                  () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const StatsScreen()))),
              _Div(isDark),
              _NavTile(Icons.public_rounded, s.globe, s.globeSubtitle,
                  primary, isDark,
                  () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const GlobeScreen()))),
              _Div(isDark),
              _NavTile(Icons.compare_arrows_rounded, s.compareFlights, s.compareSubtitle,
                  primary, isDark,
                  () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const CompareScreen()))),
              _Div(isDark),
              _NavTile(Icons.fence_rounded, s.geofences, s.geofencesSubtitle,
                  primary, isDark,
                  () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const GeofencesScreen()))),
              _Div(isDark),
              _NavTile(Icons.shield_moon_outlined, s.adminDashboard, s.adminMetrics,
                  primary, isDark,
                  () {
                    final isIn = ref.read(adminSignedInProvider);
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                          builder: (_) => isIn
                              ? const AdminMetricsScreen()
                              : const AdminLoginScreen()),
                    );
                  }),
            ])),

            const SizedBox(height: 20),

            // ═══ APPEARANCE ═══
            _Sec(s.appearance, isDark),
            const SizedBox(height: 8),
            GlassPanel(borderRadius: 14, padding: const EdgeInsets.all(4), child: Column(children: [
              _Radio(context.tr('dark_radar'), context.tr('neon_theme'), Icons.dark_mode_rounded,
                  themeMode == AppThemeMode.dark, AppColors.primary, isDark,
                  () => ref.read(themeProvider.notifier).setTheme(AppThemeMode.dark)),
              _Div(isDark),
              _Radio(context.tr('light_aviation'), context.tr('clean_theme'), Icons.light_mode_rounded,
                  themeMode == AppThemeMode.light, UiConstants.lightPrimary, isDark,
                  () => ref.read(themeProvider.notifier).setTheme(AppThemeMode.light)),
              _Div(isDark),
              _Radio(context.tr('system'), context.tr('follow_os'), Icons.settings_brightness_rounded,
                  themeMode == AppThemeMode.system, AppColors.accent, isDark,
                  () => ref.read(themeProvider.notifier).setTheme(AppThemeMode.system)),
            ])),

            const SizedBox(height: 20),

            // ═══ MAP THEME ═══
            _Sec(s.mapStyle, isDark),
            const SizedBox(height: 8),
            GlassPanel(borderRadius: 14, padding: const EdgeInsets.all(4), child: Column(children: [
              _Radio(context.tr('dark_radar'), context.tr('cartodb_dark'), Icons.map_rounded,
                  settings.mapTheme == MapTheme.darkRadar, primary, isDark,
                  () => ref.read(settingsProvider.notifier).update((s) => s.copyWith(mapTheme: MapTheme.darkRadar))),
              _Div(isDark),
              _Radio(context.tr('light_aviation'), context.tr('cartodb_light'), Icons.map_outlined,
                  settings.mapTheme == MapTheme.lightAviation, primary, isDark,
                  () => ref.read(settingsProvider.notifier).update((s) => s.copyWith(mapTheme: MapTheme.lightAviation))),
              _Div(isDark),
              _Radio(context.tr('satellite'), context.tr('arcgis_imagery'), Icons.satellite_alt_rounded,
                  settings.mapTheme == MapTheme.satellite, primary, isDark,
                  () => ref.read(settingsProvider.notifier).update((s) => s.copyWith(mapTheme: MapTheme.satellite))),
              _Div(isDark),
              // New — matches the web app's mapStyle options 1:1.
              _Radio('Streets', 'OpenStreetMap', Icons.map_outlined,
                  settings.mapTheme == MapTheme.streets, primary, isDark,
                  () => ref.read(settingsProvider.notifier).update((s) => s.copyWith(mapTheme: MapTheme.streets))),
              _Div(isDark),
              _Radio('Terrain', 'Stadia Stamen', Icons.terrain_rounded,
                  settings.mapTheme == MapTheme.terrain, primary, isDark,
                  () => ref.read(settingsProvider.notifier).update((s) => s.copyWith(mapTheme: MapTheme.terrain))),
            ])),

            const SizedBox(height: 20),

            // ═══ UNITS ═══
            _Sec(s.units, isDark),
            const SizedBox(height: 8),
            GlassPanel(borderRadius: 14, padding: const EdgeInsets.all(4), child: Column(children: [
              _Seg(context.tr('altitude_short'), Icons.height_rounded, [context.tr('feet'), context.tr('meters')],
                  settings.altitudeUnit.index, primary, isDark,
                  (i) => ref.read(settingsProvider.notifier).update((s) => s.copyWith(altitudeUnit: AltitudeUnit.values[i]))),
              _Div(isDark),
              _Seg(context.tr('speed_short'), Icons.speed_rounded, [context.tr('knots'), 'km/h', 'mph'],
                  settings.speedUnit.index, primary, isDark,
                  (i) => ref.read(settingsProvider.notifier).update((s) => s.copyWith(speedUnit: SpeedUnit.values[i]))),
            ])),

            const SizedBox(height: 20),

            // ═══ MAP OPTIONS ═══
            _Sec(s.mapOptions, isDark),
            const SizedBox(height: 8),
            GlassPanel(borderRadius: 14, padding: const EdgeInsets.all(4), child: Column(children: [
              _Tog(context.tr('aircraft_trails'), context.tr('flight_path'), Icons.timeline_rounded,
                  settings.showAircraftTrails, primary, isDark,
                  (v) => ref.read(settingsProvider.notifier).update((s) => s.copyWith(showAircraftTrails: v))),
              _Div(isDark),
              _Tog(context.tr('aircraft_labels'), context.tr('callsign_label'), Icons.label_rounded,
                  settings.showAircraftLabels, primary, isDark,
                  (v) => ref.read(settingsProvider.notifier).update((s) => s.copyWith(showAircraftLabels: v))),
              _Div(isDark),
              _Tog(context.tr('airport_labels'), context.tr('iata_codes'), Icons.location_city_rounded,
                  settings.showAirportLabels, primary, isDark,
                  (v) => ref.read(settingsProvider.notifier).update((s) => s.copyWith(showAirportLabels: v))),
              _Div(isDark),
              _Tog(context.tr('density_heatmap'), context.tr('overlay'), Icons.blur_on_rounded,
                  settings.showHeatmap, primary, isDark,
                  (v) => ref.read(settingsProvider.notifier).update((s) => s.copyWith(showHeatmap: v))),
            ])),

            const SizedBox(height: 20),

            // ═══ LANGUAGE ═══
            _Sec(s.language, isDark),
            const SizedBox(height: 8),
            GlassPanel(borderRadius: 14, padding: const EdgeInsets.all(4), child: Column(children: [
              _LangTile(
                flagCode: 'gb', flagFallbackEmoji: '🇬🇧',
                label: 'English', subtitle: 'Englisch',
                isSelected: currentLang == AppLanguage.en,
                color: primary, isDark: isDark,
                onTap: () => ref.read(languageProvider.notifier).set(AppLanguage.en),
              ),
              _Div(isDark),
              _LangTile(
                flagCode: 'de', flagFallbackEmoji: '🇩🇪',
                label: 'Deutsch', subtitle: 'German',
                isSelected: currentLang == AppLanguage.de,
                color: primary, isDark: isDark,
                onTap: () => ref.read(languageProvider.notifier).set(AppLanguage.de),
              ),
              _Div(isDark),
              _LangTile(
                flagCode: 'fr', flagFallbackEmoji: '🇫🇷',
                label: 'Français', subtitle: 'French',
                isSelected: currentLang == AppLanguage.fr,
                color: primary, isDark: isDark,
                onTap: () => ref.read(languageProvider.notifier).set(AppLanguage.fr),
              ),
            ])),

            const SizedBox(height: 20),

            // ═══ DATA SOURCE + REFRESH INTERVAL ═══
            _Sec(s.dataSource, isDark),
            const SizedBox(height: 8),
            GlassPanel(borderRadius: 14, padding: const EdgeInsets.all(4), child: Column(children: [
              _Info(context.tr('provider'), 'Airlabs.co', Icons.cloud_rounded, AppColors.success, isDark),
              _Div(isDark),
              // Refresh interval selector
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.timer_rounded, size: 16, color: primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.tr('refresh'),
                        style: TextStyle(
                          fontFamily: UiConstants.bodyFont,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.textPrimary : UiConstants.lightTextPrimary,
                        ),
                      ),
                    ),
                    ...[5, 10, 30, 60, 300].map((sec) {
                      final isActive = settings.updateIntervalSec == sec;
                      final label = sec < 60 ? '${sec}s' : '${sec ~/ 60}m';
                      return Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: GestureDetector(
                          onTap: () => ref
                              .read(settingsProvider.notifier)
                              .update((s) => s.copyWith(updateIntervalSec: sec)),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? primary.withValues(alpha: isDark ? 0.2 : 0.1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isActive
                                    ? primary.withValues(alpha: 0.4)
                                    : (isDark
                                        ? AppColors.glassBorder
                                        : UiConstants.lightBorder),
                              ),
                            ),
                            child: Text(
                              label,
                              style: TextStyle(
                                fontFamily: UiConstants.headingFont,
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                color: isActive
                                    ? primary
                                    : (isDark
                                        ? AppColors.textMuted
                                        : UiConstants.lightTextMuted),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ])),

            const SizedBox(height: 20),

            // ═══ ABOUT ═══
            // ═══ ABOUT ═══
            GlassPanel(
              borderRadius: 14,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  NeonText(text: 'AIRWATCH', fontSize: 16, color: primary, glowRadius: isDark ? 6 : 0),
                  const SizedBox(height: 4),
                  Text(
                    'v2.0.0 — ${s.tagline}',
                    style: TextStyle(
                      fontFamily: UiConstants.bodyFont,
                      fontSize: 13,
                      color: isDark ? AppColors.textMuted : UiConstants.lightTextMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// Compact helper widgets
class _Sec extends StatelessWidget {
  final String t; final bool d;
  const _Sec(this.t, this.d);
  @override
  Widget build(BuildContext context) => Text(t, style: TextStyle(fontFamily: UiConstants.headingFont,
      fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2,
      color: d ? AppColors.textSecondary : UiConstants.lightTextSecondary));
}

class _Div extends StatelessWidget {
  final bool d;
  const _Div(this.d);
  @override
  Widget build(BuildContext context) => Divider(height: 1,
      color: d ? AppColors.glassBorder : UiConstants.lightBorder);
}

/// Reusable "navigate to feature screen" tile. Used by the FEATURES section
/// at the top of [SettingsScreen] to link every web-app feature into
/// the mobile UI without growing the bottom navigation past 5 items.
class _NavTile extends StatelessWidget {
  final IconData    icon;
  final String      title;
  final String      subtitle;
  final Color       color;
  final bool        isDark;
  final VoidCallback onTap;
  const _NavTile(this.icon, this.title, this.subtitle, this.color, this.isDark, this.onTap);

  @override
  Widget build(BuildContext context) => ListTile(
        dense: false,
        onTap: onTap,
        leading: Icon(icon, color: color),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5)),
        subtitle: Text(subtitle,
            style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.textMuted : UiConstants.lightTextSecondary)),
        trailing: const Icon(Icons.chevron_right_rounded),
      );
}

class _Radio extends StatelessWidget {
  final String t, s; final IconData i; final bool sel;
  final Color c; final bool d; final VoidCallback onTap;
  const _Radio(this.t, this.s, this.i, this.sel, this.c, this.d, this.onTap);
  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    onTap: onTap,
    leading: Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: sel ? c.withValues(alpha: d ? 0.2 : 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        i,
        size: 16,
        color: sel ? c : (d ? AppColors.textMuted : UiConstants.lightHintText),
      ),
    ),
    title: Text(
      t,
      style: TextStyle(
        fontFamily: UiConstants.bodyFont,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: d ? AppColors.textPrimary : UiConstants.lightTextPrimary,
      ),
    ),
    subtitle: Text(
      s,
      style: TextStyle(
        fontFamily: UiConstants.bodyFont,
        fontSize: 11,
        color: d ? AppColors.textSecondary : UiConstants.lightTextSecondary,
      ),
    ),
    trailing: sel ? Icon(Icons.check_circle_rounded, size: 18, color: c) : null,
  );
}

class _Tog extends StatelessWidget {
  final String t, s; final IconData i; final bool v;
  final Color c; final bool d; final ValueChanged<bool> on;
  const _Tog(this.t, this.s, this.i, this.v, this.c, this.d, this.on);
  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    leading: Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: v ? c.withValues(alpha: d ? 0.2 : 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        i,
        size: 16,
        color: v ? c : (d ? AppColors.textMuted : UiConstants.lightHintText),
      ),
    ),
    title: Text(
      t,
      style: TextStyle(
        fontFamily: UiConstants.bodyFont,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: d ? AppColors.textPrimary : UiConstants.lightTextPrimary,
      ),
    ),
    subtitle: Text(
      s,
      style: TextStyle(
        fontFamily: UiConstants.bodyFont,
        fontSize: 11,
        color: d ? AppColors.textSecondary : UiConstants.lightTextSecondary,
      ),
    ),
    trailing: Switch(
      value: v,
      onChanged: on,
      activeThumbColor: c,
      activeTrackColor: c.withValues(alpha: 0.3),
    ),
  );
}

class _Seg extends StatelessWidget {
  final String t; final IconData i; final List<String> opts;
  final int sel; final Color c; final bool d; final ValueChanged<int> on;
  const _Seg(this.t, this.i, this.opts, this.sel, this.c, this.d, this.on);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(i, size: 16, color: c),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                t,
                style: TextStyle(
                  fontFamily: UiConstants.bodyFont,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: d ? AppColors.textPrimary : UiConstants.lightTextPrimary,
                ),
              ),
            ),
            ...List.generate(
              opts.length,
              (j) => Padding(
                padding: EdgeInsets.only(left: j > 0 ? 4 : 0),
                child: GestureDetector(
                  onTap: () => on(j),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: sel == j ? c.withValues(alpha: d ? 0.2 : 0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: sel == j
                            ? c.withValues(alpha: 0.4)
                            : (d ? AppColors.glassBorder : const Color(0xFFE2E8F0)),
                      ),
                    ),
                    child: Text(
                      opts[j],
                      style: TextStyle(
                        fontFamily: UiConstants.headingFont,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: sel == j
                            ? c
                            : (d ? AppColors.textMuted : UiConstants.lightTextMuted),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

class _Info extends StatelessWidget {
  final String t, v; final IconData i; final Color c; final bool d;
  const _Info(this.t, this.v, this.i, this.c, this.d);
  @override
  Widget build(BuildContext context) => ListTile(
        dense: true,
        leading: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: c.withValues(alpha: d ? 0.15 : 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(i, size: 16, color: c),
        ),
        title: Text(
          t,
          style: TextStyle(
            fontFamily: UiConstants.bodyFont,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: d ? AppColors.textPrimary : UiConstants.lightTextPrimary,
          ),
        ),
        trailing: Text(
          v,
          style: TextStyle(
            fontFamily: UiConstants.headingFont,
            fontSize: 8,
            fontWeight: FontWeight.w700,
            color: c,
          ),
        ),
      );
}

class _LangTile extends StatelessWidget {
  /// Two-letter ISO code (lowercase) for the SVG asset lookup —
  /// `assets/flags/4x3/{flagCode}.svg`. The class also accepts a
  /// fallback emoji for the rare case the asset is missing (defensive
  /// — every supported language has its asset).
  final String flagCode;
  final String flagFallbackEmoji;
  final String label, subtitle;
  final bool isSelected;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;
  const _LangTile({
    required this.flagCode,
    required this.flagFallbackEmoji,
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true, onTap: onTap,
      leading: Container(
        width: 38, height: 28,
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: isDark ? 0.2 : 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.5)
                : (isDark ? AppColors.glassBorder : UiConstants.lightBorder),
            width: 0.5,
          ),
        ),
        clipBehavior: Clip.hardEdge,
        // SVG flag — same asset path the country / route widgets use.
        // Mirrors the web frontend's `<flag cc="de">` chip on the
        // settings page. Emoji fallback covers any future locale that
        // ships before its SVG does.
        child: SvgPicture.asset(
          'assets/flags/4x3/$flagCode.svg',
          fit: BoxFit.cover,
          placeholderBuilder: (_) => Center(
            child: Text(
              flagFallbackEmoji,
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ),
      ),
      title: Text(label, style: TextStyle(fontFamily: UiConstants.bodyFont, fontSize: 14,
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.textPrimary : UiConstants.lightTextPrimary)),
      subtitle: Text(subtitle, style: TextStyle(fontFamily: UiConstants.bodyFont, fontSize: 11,
          color: isDark ? AppColors.textSecondary : UiConstants.lightTextSecondary)),
      trailing: isSelected
          ? Icon(Icons.check_circle_rounded, size: 18, color: color)
          : null,
    );
  }
}

