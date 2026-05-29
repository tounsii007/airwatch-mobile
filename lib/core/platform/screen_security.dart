import 'package:flutter/services.dart';

/// Toggles platform-level screen-capture protection for sensitive screens.
///
/// On Android, FLAG_SECURE is now **enabled by default app-wide** — set in
/// `MainActivity.configureFlutterEngine()` before the first frame, so the
/// recent-apps thumbnail and any instant screenshot are blocked from t=0
/// without a race window. The `enable()` / `disable()` calls remain for
/// **explicit opt-out** on non-sensitive screens where the operator may
/// legitimately want screenshots.
///
/// On iOS this is a no-op — the equivalent protection is handled at the
/// `AppDelegate` level by overlaying an opaque view in
/// `applicationWillResignActive` / `applicationDidBecomeActive`, which
/// also covers phone-call interrupts and Control-Center pulls (not just
/// full background transitions). The Dart calls are still safe to make
/// (the platform channel simply doesn't exist on iOS and the
/// `MissingPluginException` is swallowed below).
class ScreenSecurity {
  ScreenSecurity._();

  static const _channel = MethodChannel('com.airwatch.mobile/screen_security');

  /// Re-assert FLAG_SECURE on the current activity (Android only). Default
  /// is already ENABLED app-wide; this is mostly useful after a prior
  /// `disable()` call to restore protection.
  static Future<void> enable() async {
    try {
      await _channel.invokeMethod('enable');
    } catch (_) {
      // iOS / unsupported platforms — no-op.
    }
  }

  /// Explicit opt-out: clear FLAG_SECURE on the current activity (Android
  /// only). Default is ENABLED app-wide — call this only on screens where
  /// screenshots are explicitly permitted, and re-`enable()` in dispose.
  static Future<void> disable() async {
    try {
      await _channel.invokeMethod('disable');
    } catch (_) {
      // iOS / unsupported platforms — no-op.
    }
  }
}
