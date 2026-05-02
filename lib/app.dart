import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/ui_constants.dart';
import 'core/l10n/app_strings.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/theme_provider.dart';
import 'features/airport/presentation/screens/airport_screen.dart';
import 'features/favorites/data/favorites_repository.dart';
import 'features/favorites/presentation/screens/favorites_screen.dart';
import 'features/map/data/models/aircraft_state.dart';
import 'features/map/presentation/providers/flight_providers.dart';
import 'features/map/presentation/screens/map_screen.dart';
import 'features/map/presentation/screens/splash_screen.dart';
import 'features/notifications/presentation/providers/alert_push_listener.dart';
import 'features/search/presentation/screens/search_screen.dart';
import 'features/settings/presentation/screens/settings_screen.dart';

class AirwatchMobileApp extends ConsumerWidget {
  const AirwatchMobileApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final themeData = ref.watch(themeDataProvider);
    final appLanguage = ref.watch(languageProvider);
    final strings = S.of(appLanguage);

    // Set system UI overlay style based on theme
    SystemChrome.setSystemUIOverlayStyle(
      themeMode == AppThemeMode.light
          ? SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: Colors.white,
            )
          : SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: AppColors.surface,
            ),
    );

    return MaterialApp(
      title: strings.appName,
      debugShowCheckedModeBanner: false,
      theme: themeData,
      darkTheme: themeData,
      locale: localeFromLanguage(appLanguage),
      supportedLocales: const [
        Locale('en'),
        Locale('de'),
        Locale('fr'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      themeMode: themeMode == AppThemeMode.system
          ? ThemeMode.system
          : (themeMode == AppThemeMode.dark
              ? ThemeMode.dark
              : ThemeMode.light),
      // Wrap the entry in the alert push listener — it watches
      // alertsProvider and surfaces deltas as system tray notifications
      // when the user has them enabled. Lives at the top of the
      // widget tree so a backgrounded screen still reaches it.
      home: installAlertPushListener(child: const AppEntry()),
    );
  }
}

class AppEntry extends StatefulWidget {
  const AppEntry({super.key});

  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> {
  bool _showSplash = true;

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return SplashScreen(
        onComplete: () => setState(() => _showSplash = false),
      );
    }
    return const AppShell();
  }
}

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _currentIndex = 0;

  void _onFlightSelected(AircraftState aircraft) {
    ref.read(selectedAircraftProvider.notifier).set(aircraft);
    if (aircraft.position != null) {
      ref.read(mapFocusProvider.notifier).focusOn(aircraft.position!, zoom: 10.0);
    }
    setState(() => _currentIndex = 0);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.primary : UiConstants.lightPrimary;
    final strings = S.of(ref.watch(languageProvider));

    final screens = [
      const MapScreen(),
      SearchScreen(onFlightSelected: _onFlightSelected),
      const AirportScreen(),
      FavoritesScreen(onFlightTap: (cs) {
        // Search for this callsign and switch to map
        setState(() => _currentIndex = 0);
      }),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surface : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.glassBorder : UiConstants.lightBorder,
              width: 1,
            ),
          ),
          boxShadow: isDark
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.map_rounded,
                  label: strings.map,
                  isActive: _currentIndex == 0,
                  color: primaryColor,
                  isDark: isDark,
                  onTap: () => setState(() => _currentIndex = 0),
                ),
                _NavItem(
                  icon: Icons.search_rounded,
                  label: strings.search,
                  isActive: _currentIndex == 1,
                  color: primaryColor,
                  isDark: isDark,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                _NavItem(
                  icon: Icons.radar_rounded,
                  label: strings.airport,
                  isActive: _currentIndex == 2,
                  color: primaryColor,
                  isDark: isDark,
                  onTap: () => setState(() => _currentIndex = 2),
                ),
                _NavItem(
                  icon: Icons.star_rounded,
                  label: strings.favs,
                  isActive: _currentIndex == 3,
                  color: primaryColor,
                  isDark: isDark,
                  badge: ref.watch(favoritesProvider).length,
                  onTap: () => setState(() => _currentIndex = 3),
                ),
                _NavItem(
                  icon: Icons.settings_rounded,
                  label: strings.settings,
                  isActive: _currentIndex == 4,
                  color: primaryColor,
                  isDark: isDark,
                  onTap: () => setState(() => _currentIndex = 4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color color;
  final bool isDark;
  final int badge;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.color,
    required this.isDark,
    this.badge = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? color.withValues(alpha: isDark ? 0.12 : 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon with glow effect + optional badge
            Stack(
              clipBehavior: Clip.none,
              children: [
            Container(
              decoration: isActive && isDark
                  ? BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.5),
                          blurRadius: 14,
                          spreadRadius: -2,
                        ),
                        BoxShadow(
                          color: color.withValues(alpha: 0.25),
                          blurRadius: 24,
                          spreadRadius: -4,
                        ),
                      ],
                    )
                  : null,
              child: Icon(
                icon,
                size: isActive ? 26 : 22,
                color: isActive
                    ? color
                    : (isDark ? AppColors.textMuted : UiConstants.lightHintText),
                shadows: isActive && isDark
                    ? [Shadow(color: color.withValues(alpha: 0.6), blurRadius: 10)]
                    : null,
              ),
            ),
            // Badge
            if (badge > 0)
              Positioned(
                top: -4, right: -8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: AppColors.error.withValues(alpha: 0.4), blurRadius: 4)],
                  ),
                  child: Text('$badge', style: const TextStyle(
                    fontFamily: UiConstants.headingFont, fontSize: 8, fontWeight: FontWeight.w700,
                    color: Colors.white,
                  )),
                ),
              ),
            ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: UiConstants.headingFont,
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: isActive
                    ? color
                    : (isDark ? AppColors.textMuted : UiConstants.lightHintText),
                letterSpacing: 1,
                shadows: isActive && isDark
                    ? [Shadow(color: color.withValues(alpha: 0.4), blurRadius: 6)]
                    : null,
              ),
            ),
            // Glowing bottom indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(top: 4),
              width: isActive ? 20 : 0,
              height: 2.5,
              decoration: BoxDecoration(
                color: isActive ? color : Colors.transparent,
                borderRadius: BorderRadius.circular(1.5),
                boxShadow: isActive && isDark
                    ? [
                        BoxShadow(color: color.withValues(alpha: 0.7), blurRadius: 6),
                        BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 12),
                      ]
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
