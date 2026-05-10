import 'package:flutter/widgets.dart';

/// Whether the OS-level "reduce motion" / "remove animations" toggle
/// is enabled — Android Settings → Accessibility → Remove animations,
/// iOS Settings → Accessibility → Motion → Reduce Motion.
///
/// <p>Mirrors airwatch-web's commit b379fce (`prefers-reduced-motion`
/// for SVG SMIL animations). The mobile equivalent is exposed by
/// Flutter as [MediaQueryData.disableAnimations]; calling
/// [MediaQuery.disableAnimationsOf] in a build method registers a
/// dependency so the widget rebuilds if the user toggles the OS
/// setting while the app is running.
///
/// <p>Use this helper to short-circuit looping animations
/// (radar sweep, pulsing rings, marker pulse) — leave them static
/// instead of "instant + frozen", which can look broken to operators
/// who tend to think a non-animating dot means the feed is dead.
bool prefersReducedMotion(BuildContext context) {
  return MediaQuery.disableAnimationsOf(context);
}
