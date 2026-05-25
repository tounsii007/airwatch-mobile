import 'package:flutter/material.dart';

import 'package:airwatch_mobile/core/constants/ui_constants.dart';
import 'package:airwatch_mobile/core/theme/app_colors.dart';

/// Theme-aware shortcuts off `BuildContext` so widgets stop hand-rolling
/// the same `Theme.of(context).brightness == Brightness.dark` ternaries
/// for every colour.
///
/// **Why a separate file?**
/// The same five lines —
///
/// ```dart
/// final isDark = Theme.of(context).brightness == Brightness.dark;
/// final primary = isDark ? AppColors.primary : UiConstants.lightPrimary;
/// final surface = isDark ? AppColors.surface : UiConstants.lightSurface;
/// final text    = isDark ? AppColors.textPrimary : UiConstants.lightTextPrimary;
/// final muted   = isDark ? AppColors.textMuted   : UiConstants.lightTextMuted;
/// ```
///
/// — appear in ~80 widgets across `lib/features/`. Each is a small leak
/// of theme knowledge into the widget; together they're the single
/// biggest source of inconsistency in the codebase (mapped from a grep:
/// 4 widgets bind `primary` to `AppColors.primaryDark`, 2 forget the
/// light branch entirely, 3 cache only `isDark` and then re-derive
/// `primary` inline). This extension funnels every callsite through the
/// same lookup so future palette changes (see iter 73 — the navy →
/// charcoal swap) become a single-file diff instead of a 60-file
/// migration.
///
/// **Usage**
/// ```dart
/// @override
/// Widget build(BuildContext context) {
///   final primary = context.themePrimary;       // replaces ternary
///   final isDark  = context.isDarkTheme;        // when only flag is needed
///   final muted   = context.themeMuted;
///   return GlassPanel(
///     borderColor: context.themePrimary.withValues(alpha: 0.4),
///     // …
///   );
/// }
/// ```
///
/// **Naming**
/// All getters are prefixed `theme*` to avoid colliding with the many
/// existing locals (`final primary = …`) — the rename pass that
/// migrates a widget can stay mechanical.
///
/// **Why getters not constants?**
/// Each getter calls `Theme.of(context)` which subscribes the calling
/// widget to theme-rebuild notifications. That's the same subscription
/// the manual ternaries get today — no perf regression, and switching
/// themes at runtime continues to refresh correctly.
///
/// **Performance**
/// `Theme.of(context)` is a cheap InheritedWidget lookup (O(1) after
/// the framework's cache warms). Calling it twice in `build` is the
/// same cost as caching `isDark` in a local — Flutter dedupes the
/// inherited dependency.
extension ThemeContextExt on BuildContext {
  /// True if the active theme is dark mode. Use this when only the
  /// flag is needed (e.g. an icon glow radius gated on dark).
  bool get isDarkTheme => Theme.of(this).brightness == Brightness.dark;

  /// Brand-primary colour — steel blue in dark, deep aviation blue in
  /// light. Wraps the ubiquitous
  /// `isDark ? AppColors.primary : UiConstants.lightPrimary` ternary.
  Color get themePrimary =>
      isDarkTheme ? AppColors.primary : UiConstants.lightPrimary;

  /// Page background — neutral charcoal in dark, off-white in light.
  Color get themeBackground =>
      isDarkTheme ? AppColors.background : UiConstants.lightBackground;

  /// Card / surface — one step lighter than the background.
  Color get themeSurface =>
      isDarkTheme ? AppColors.surface : UiConstants.lightSurface;

  /// Highest-emphasis text colour — silver-white in dark, near-black
  /// in light.
  Color get themeTextPrimary =>
      isDarkTheme ? AppColors.textPrimary : UiConstants.lightTextPrimary;

  /// Secondary text — for body copy in panel chrome.
  Color get themeTextSecondary =>
      isDarkTheme ? AppColors.textSecondary : UiConstants.lightTextSecondary;

  /// Lowest-emphasis text — for captions / hints / metadata. The
  /// dark-theme tone (#6B85A4) was bumped in iter 73 for WCAG AA
  /// contrast on neutral surfaces.
  Color get themeMuted =>
      isDarkTheme ? AppColors.textMuted : UiConstants.lightTextMuted;

  /// Subtle outline for cards / glass panels — primary-tinted in dark,
  /// neutral grey in light.
  Color get themeBorder =>
      isDarkTheme ? AppColors.cardBorder : UiConstants.lightBorder;
}
