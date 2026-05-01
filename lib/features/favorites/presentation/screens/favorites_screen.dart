import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:airwatch_mobile/core/constants/ui_constants.dart';
import 'package:airwatch_mobile/core/l10n/ui_text.dart';
import 'package:airwatch_mobile/core/theme/app_colors.dart';
import 'package:airwatch_mobile/core/widgets/glass_panel.dart';
import 'package:airwatch_mobile/core/widgets/neon_text.dart';
import 'package:airwatch_mobile/features/favorites/data/favorites_repository.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  final Function(String callsign)? onFlightTap;
  const FavoritesScreen({super.key, this.onFlightTap});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  // Snapshot of favorites when screen was entered — items stay visible
  // until user leaves the screen, even if unfavorited
  List<FavoriteItem> _snapshot = [];
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primary : UiConstants.lightPrimary;
    final liveFavorites = ref.watch(favoritesProvider);

    // Take snapshot on first build or when new items are added
    if (!_initialized || liveFavorites.length > _snapshot.length) {
      _snapshot = List.from(liveFavorites);
      _initialized = true;
    }

    // Show snapshot items (keeps removed ones visible). Within each
    // type, pinned-first then most-recent — so the user sees their
    // pinned entries float to the top regardless of how long ago they
    // saved them. Mirrors the web's `useSavedGroups` ordering.
    int pinSort(FavoriteItem a, FavoriteItem b) {
      // Resolve the LIVE pinned state — when the user toggles a pin
      // mid-session, the snapshot still reflects the original boolean,
      // but the list should re-order immediately.
      final aPin = liveFavorites.any((f) => f.id == a.id && f.pinned);
      final bPin = liveFavorites.any((f) => f.id == b.id && f.pinned);
      if (aPin != bPin) return aPin ? -1 : 1;
      return b.addedAt.compareTo(a.addedAt);
    }
    final flights  = _snapshot.where((f) => f.type == FavoriteType.flight).toList()..sort(pinSort);
    final airlines = _snapshot.where((f) => f.type == FavoriteType.airline).toList()..sort(pinSort);
    final airports = _snapshot.where((f) => f.type == FavoriteType.airport).toList()..sort(pinSort);

    return Scaffold(
      backgroundColor: isDark ? AppColors.background : UiConstants.lightBackground,
      body: SafeArea(
        child: _snapshot.isEmpty
            ? _emptyState(isDark, primary)
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  NeonText(text: context.tr('favorites'), fontSize: UiConstants.searchHeaderFontSize, color: primary,
                      glowRadius: isDark ? 10 : 0),
                  const SizedBox(height: 16),

                  // Stats (show LIVE count, not snapshot)
                  Row(children: [
                    _CountChip(count: liveFavorites.where((f) => f.type == FavoriteType.flight).length,
                        label: context.tr('flights_count'), icon: Icons.flight_rounded, color: primary, isDark: isDark),
                    const SizedBox(width: 8),
                    _CountChip(count: liveFavorites.where((f) => f.type == FavoriteType.airline).length,
                        label: context.tr('airlines_count'), icon: Icons.airlines_rounded, color: AppColors.accent, isDark: isDark),
                    const SizedBox(width: 8),
                    _CountChip(count: liveFavorites.where((f) => f.type == FavoriteType.airport).length,
                        label: context.tr('airports_count'), icon: Icons.location_city_rounded, color: AppColors.success, isDark: isDark),
                  ]),
                  const SizedBox(height: 20),

                  if (flights.isNotEmpty) ...[
                    _SectionTitle(title: context.tr('flights_upper'), isDark: isDark),
                    const SizedBox(height: 8),
                    ...flights.map((f) {
                      final isFav = ref.watch(favoritesProvider).any((fav) => fav.id == f.id);
                      return _FavoriteTile(
                        item: f, isDark: isDark, primary: primary,
                        icon: Icons.flight_rounded, color: primary,
                        isFavorite: isFav,
                        onTap: () => widget.onFlightTap?.call(f.id),
                        onToggle: () {
                          ref.read(favoritesProvider.notifier).toggle(f);
                          // Don't remove from snapshot — stays visible
                        },
                      );
                    }),
                    const SizedBox(height: 16),
                  ],

                  if (airlines.isNotEmpty) ...[
                    _SectionTitle(title: context.tr('airlines'), isDark: isDark),
                    const SizedBox(height: 8),
                    ...airlines.map((f) {
                      final isFav = ref.watch(favoritesProvider).any((fav) => fav.id == f.id);
                      return _FavoriteTile(
                        item: f, isDark: isDark, primary: primary,
                        icon: Icons.airlines_rounded, color: AppColors.accent,
                        isFavorite: isFav,
                        onToggle: () => ref.read(favoritesProvider.notifier).toggle(f),
                      );
                    }),
                    const SizedBox(height: 16),
                  ],

                  if (airports.isNotEmpty) ...[
                    _SectionTitle(title: context.tr('airports_upper'), isDark: isDark),
                    const SizedBox(height: 8),
                    ...airports.map((f) {
                      final isFav = ref.watch(favoritesProvider).any((fav) => fav.id == f.id);
                      return _FavoriteTile(
                        item: f, isDark: isDark, primary: primary,
                        icon: Icons.location_city_rounded, color: AppColors.success,
                        isFavorite: isFav,
                        onToggle: () => ref.read(favoritesProvider.notifier).toggle(f),
                      );
                    }),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _emptyState(bool isDark, Color primary) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star_border_rounded, size: 64,
              color: isDark ? AppColors.textMuted : UiConstants.lightDisabled),
          const SizedBox(height: 16),
          NeonText(text: context.s.noFavorites, fontSize: 16, color: primary,
              glowRadius: isDark ? 6 : 0),
          const SizedBox(height: 8),
          Text(context.tr('no_favorites_help'),
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: UiConstants.bodyFont, fontSize: 14,
                color: isDark ? AppColors.textSecondary : UiConstants.lightTextSecondary),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════ WIDGETS ═══════════════════

class _CountChip extends StatelessWidget {
  final int count; final String label; final IconData icon;
  final Color color; final bool isDark;
  const _CountChip({required this.count, required this.label,
      required this.icon, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassPanel(
        padding: const EdgeInsets.symmetric(vertical: 10), borderRadius: 10,
        child: Column(children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text('$count', style: TextStyle(fontFamily: UiConstants.headingFont, fontSize: 16,
              fontWeight: FontWeight.w700, color: color)),
          Text(label, style: TextStyle(fontFamily: UiConstants.bodyFont, fontSize: 10,
              color: isDark ? AppColors.textMuted : UiConstants.lightTextMuted)),
        ]),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title; final bool isDark;
  const _SectionTitle({required this.title, required this.isDark});
  @override
  Widget build(BuildContext context) => Text(title, style: TextStyle(
      fontFamily: UiConstants.headingFont, fontSize: 11, fontWeight: FontWeight.w700,
      letterSpacing: 2,
      color: isDark ? AppColors.textSecondary : UiConstants.lightTextSecondary));
}

class _FavoriteTile extends ConsumerWidget {
  final FavoriteItem item;
  final bool isDark;
  final Color primary;
  final IconData icon;
  final Color color;
  final bool isFavorite;
  final VoidCallback? onTap;
  final VoidCallback onToggle;

  const _FavoriteTile({required this.item, required this.isDark,
      required this.primary, required this.icon, required this.color,
      required this.isFavorite, this.onTap, required this.onToggle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Live pin state — re-read from the provider so flipping the pin on
    // one tile re-orders the list immediately. The parent passes the
    // sorted snapshot, so we pull `pinned` straight from the provider
    // for the icon state.
    final livePinned = ref.watch(favoritesProvider).any(
          (f) => f.id == item.id && f.pinned,
        );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Opacity(
          opacity: isFavorite ? 1.0 : 0.5,
          child: GlassPanel(
            padding: const EdgeInsets.all(12), borderRadius: 12,
            // Pinned tiles get a subtle accent border so the user can
            // see at a glance which entries float to the top.
            borderColor: livePinned ? primary.withValues(alpha: 0.45) : null,
            child: Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.15 : 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.label, style: TextStyle(
                      fontFamily: UiConstants.headingFont,
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textPrimary : UiConstants.lightTextPrimary)),
                  if (item.subtitle != null)
                    Text(item.subtitle!, style: TextStyle(fontFamily: UiConstants.bodyFont,
                        fontSize: 12, color: isDark ? AppColors.textSecondary : UiConstants.lightTextSecondary)),
                ],
              )),
              // Pin toggle — primary-coloured filled-pin when pinned,
              // muted outline when unpinned. Only shown for currently-
              // favourited tiles so the action makes sense (you can't
              // pin something you've removed).
              if (isFavorite) ...[
                GestureDetector(
                  onTap: () => ref
                      .read(favoritesProvider.notifier)
                      .togglePin(item.id),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      livePinned
                          ? Icons.push_pin_rounded
                          : Icons.push_pin_outlined,
                      size: 20,
                      color: livePinned ? primary : AppColors.textMuted,
                    ),
                  ),
                ),
              ],
              // Star toggle — yellow if favorite, grey if removed
              GestureDetector(
                onTap: onToggle,
                child: Icon(
                  isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                  size: 24,
                  color: isFavorite ? AppColors.warning : AppColors.textMuted,
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
