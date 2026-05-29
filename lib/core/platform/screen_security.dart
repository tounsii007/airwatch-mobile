import 'package:flutter/services.dart';

/// Toggles platform-level screen-capture protection for sensitive screens.
///
/// On Android, this sets `WindowManager.LayoutParams.FLAG_SECURE` on the
/// activity window, which blocks screenshots, screen recordings, and
/// prevents the screen contents from appearing in the OS recent-apps
/// thumbnail.
///
/// On iOS this is a no-op — the equivalent protection is handled at the
/// `AppDelegate` level by overlaying an opaque view in
/// `applicationDidEnterBackground` / `applicationWillEnterForeground`,
/// which covers the entire app rather than per-screen. The Dart calls are
/// still safe to make (the platform channel simply doesn't exist on iOS
/// and the `MissingPluginException` is swallowed below).
class ScreenSecurity {
  ScreenSecurity._();

  static const _channel = MethodChannel('com.airwatch.mobile/screen_security');

  /// Enable FLAG_SECURE on the current activity (Android only). Call from
  /// `initState()` on screens that should not be screenshottable.
  static Future<void> enable() async {
    try {
      await _channel.invokeMethod('enable');
    } catch (_) {
      // iOS / unsupported platforms — no-op.
    }
  }

  /// Disable FLAG_SECURE on the current activity (Android only). Call
  /// from `dispose()` to restore default behaviour for other screens.
  static Future<void> disable() async {
    try {
      await _channel.invokeMethod('disable');
    } catch (_) {
      // iOS / unsupported platforms — no-op.
    }
  }
}
