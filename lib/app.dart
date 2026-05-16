import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/ui_constants.dart';
import 'core/l10n/app_strings.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/theme_provider.dart';
import 'core/utils/rtl.dart';
import 'features/airport/presentation/screens/airport_screen.dart';
import 'features/favorites/data/favorites_repository.dart';
import 'features/favorites/presentation/screens/favorites_screen.dart';
import 'features/home_widget/presentation/widget_publisher.dart';
import 'features/map/data/models/aircraft_state.dart';
import 'features/map/presentation/providers/flight_providers.dart';
import 'features/map/presentation/screens/map_screen.dart';
import 'features/map/presentation/screens/splash_screen.dart';
import 'features/navigation/presentation/more_menu_sheet.dart';
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
        Locale('es'),
        Locale('it'),
        Locale('ar'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      themeMode: themeMode == AppThemeMode.system
          ? ThemeMode.system
          : (themeMode == AppThemeMode.dark ? ThemeMode.dark : ThemeMode.light),
      // RTL flip — Arabic (and any future RTL locale via the
      // `rtlLanguages` set in core/utils/rtl.dart) wraps the entire
      // widget tree in a `Directionality(rtl)` so Flutter's layout
      // system mirrors automatically. Components using start/end
      // EdgeInsets + alignment work without further changes; the few
      // that still hardcode left/right will visually drift (tracked
      // as a follow-up like the web frontend's logical-property
      // migration). Top-level wrappers still apply:
      //  - `installHomeWidgetPublisher` ticks every 30 s + pushes a
      //    compact summary of the live feed to the OS widget host.
      //  - `installAlertPushListener` watches alertsProvider and
      //    surfaces deltas as system tray notifications.
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        return Directionality(
          textDirection: textDirectionFor(appLanguage),
          child: child,
        );
      },
      home: installHomeWidgetPublisher(
        child: installAlertPushListener(child: const AppEntry()),
      ),
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
      ref.read(mapFocusProvider.notifier).focusOn(aircraft.position!);
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
      FavoritesScreen(
        onFlightTap: (cs) {
          // Search for this callsign and switch to map
          setState(() => _currentIndex = 0);
        },
      ),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surface : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.glassBorder : UiConstants.lightBorder,
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
            padding: const EdgeInsets.symmetric(vertical: 6),
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
                // ── "More" overflow slot ───────────────────────────────
                // Doesn't own an IndexedStack index — opens the
                // secondary-routes sheet and pushes the chosen screen
                // on top of the current primary tab. Never "active"
                // (we never know in this widget whether the user is
                // currently on a pushed secondary route).
                _NavItem(
                  icon: Icons.more_horiz_rounded,
                  label: strings.more,
                  isActive: false,
                  color: primaryColor,
                  isDark: isDark,
                  onTap: () => MoreMenuSheet.show(context),
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
    // Active-state palette — kept centralised so changes ripple through
    // every visual element (icon, label, bottom-bar) in one place.
    final activeColor = color;
    final restColor =
        isDark ? AppColors.textMuted : UiConstants.lightHintText;
    final foreground = isActive ? activeColor : restColor;

    // Semantics wrapper so TalkBack / VoiceOver announce the role +
    // selected state correctly. Previously the GestureDetector was
    // unlabeled and the label text was a separate node — screen-reader
    // users heard "MAP" without context.
    return Semantics(
      button: true,
      selected: isActive,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: ExcludeSemantics(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isActive
                  ? activeColor.withValues(alpha: isDark ? 0.12 : 0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon — size is constant (was 22→26 on active, made the
                // active item visually "jump" and stole hierarchy from
                // page content). Glow is a single soft layer in dark
                // mode; was two stacked shadows that read as noise.
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      decoration: isActive && isDark
                          ? BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: activeColor.withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  spreadRadius: -2,
                                ),
                              ],
                            )
                          : null,
                      child: Icon(icon, size: 22, color: foreground),
                    ),
                    // Badge — same as before; one shadow for parity
                    // with the rest of the design tokens.
                    if (badge > 0)
                      Positioned(
                        top: -4,
                        right: -8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.error.withValues(alpha: 0.4),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Text(
                            '$badge',
                            style: const TextStyle(
                              fontFamily: UiConstants.headingFont,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                // Label — 11 px (was 8 px, below Material's 10 sp guideline
                // and consistently flagged as a readability issue in the
                // UX review). No text-shadow — the icon + bottom-bar
                // already carry the active emphasis.
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: UiConstants.headingFont,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: foreground,
                    letterSpacing: 0.6,
                  ),
                ),
                // Bottom indicator — the only "loud" cue we keep. Single
                // glow layer instead of the previous two stacked blurs.
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.only(top: 3),
                  width: isActive ? 20 : 0,
                  height: 2,
                  decoration: BoxDecoration(
                    color: isActive ? activeColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(1),
                    boxShadow: isActive && isDark
                        ? [
                            BoxShadow(
                              color: activeColor.withValues(alpha: 0.55),
                              blurRadius: 6,
                            ),
                          ]
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
