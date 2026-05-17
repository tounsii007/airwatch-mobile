import 'package:flutter/material.dart';

import 'package:airwatch_mobile/core/constants/ui_constants.dart';
import 'package:airwatch_mobile/core/theme/app_colors.dart';

/// Standard mobile page scaffold — the Flutter equivalent of airwatch-
/// web's `PageContainer.tsx`. Centralises:
///
/// <ul>
///   <li>AppBar with transparent background + zero elevation (matches
///       the glass-panel aesthetic used everywhere else).</li>
///   <li>Optional [subtitle] rendered as a small chip / badge under the
///       title — same slot the web uses for "3 active" / "0 flights"
///       counts.</li>
///   <li>Optional [actions] slot for icon-buttons on the right of the
///       app bar — web's `PageContainer actions={...}` equivalent.</li>
///   <li>Safe-area-aware body padding so screens don't have to repeat
///       the `SafeArea(...)` boilerplate.</li>
/// </ul>
///
/// <p>Why a wrapper instead of stateless boilerplate per screen: the
/// title font, padding and badge layout are part of the design system.
/// Letting each screen build its own Scaffold guarantees drift; the
/// wrapper lets layout polish (like the recent honest-empty-state pass)
/// land in one place and ripple through every consumer.
class AwPageScaffold extends StatelessWidget {
  /// Page title — rendered as the AppBar's title widget.
  final String title;

  /// Optional small badge / chip line under the title. Pass any widget,
  /// typically a `_Badge` from page-local code or a plain `Text`.
  final Widget? subtitle;

  /// Optional list of icon buttons (or any widgets) rendered on the
  /// right of the app bar. Same semantics as `AppBar.actions`.
  final List<Widget>? actions;

  /// The screen content. Wrapped in [SafeArea] automatically — the
  /// caller does NOT need to add its own.
  final Widget child;

  /// When true, no SafeArea is applied. Used by screens that themselves
  /// manage status-bar / nav-bar inset (e.g. the map screen).
  final bool extendBody;

  /// Optional FloatingActionButton — passed straight through to the
  /// inner Scaffold so screens with primary actions (geofences DRAW,
  /// favorites add) don't need to roll their own scaffold to keep one.
  final Widget? floatingActionButton;

  /// Optional bottom widget (matches `AppBar.bottom`). Used for tab
  /// bars and the like. Keep light — anything heavier belongs in the
  /// body.
  final PreferredSizeWidget? bottom;

  /// Optional leading widget on the AppBar (e.g. a custom back button).
  /// When null, Flutter's default behaviour applies.
  final Widget? leading;

  const AwPageScaffold({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.actions,
    this.extendBody = false,
    this.floatingActionButton,
    this.bottom,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final titleWidget = subtitle == null
        ? Text(title)
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: UiConstants.headingFont,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              DefaultTextStyle.merge(
                style: const TextStyle(
                  fontFamily: UiConstants.bodyFont,
                  fontSize: 10,
                  color: AppColors.textMuted,
                ),
                child: subtitle!,
              ),
            ],
          );

    final body = extendBody ? child : SafeArea(child: child);

    return Scaffold(
      appBar: AppBar(
        title: titleWidget,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: leading,
        actions: actions,
        bottom: bottom,
      ),
      floatingActionButton: floatingActionButton,
      body: body,
    );
  }
}

/// Convenience subtitle helper — renders a small badge-style label
/// (count + word) to use as the [AwPageScaffold.subtitle] argument.
class AwPageBadge extends StatelessWidget {
  final String label;
  final Color color;
  const AwPageBadge({
    super.key,
    required this.label,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: UiConstants.headingFont,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          color: color,
        ),
      ),
    );
  }
}
