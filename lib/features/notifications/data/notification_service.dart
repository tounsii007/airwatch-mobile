import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:airwatch_mobile/features/notifications/domain/alert.dart';

/// Thin wrapper around `flutter_local_notifications` that knows about
/// the two channels AirWatch uses (squawk + geofence) and the request-
/// permissions flow on Android 13+ / iOS.
///
/// <p>Singleton-ish — built once at app start, then any feature can
/// fire a notification by calling [showAlert]. The bell-icon hub
/// stays the source of truth for in-app history; this service
/// surfaces alerts to the OS notification tray when the app is
/// backgrounded so the user doesn't miss a 7700 squawk while the
/// screen is off.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Per-kind channel keys. The values match the Android channel IDs
  /// the user sees under Settings → App → Notifications, so renaming
  /// them is a breaking change for users who customised the channel.
  static const _channelSquawk = 'squawk_alerts';
  static const _channelGeofence = 'geofence_alerts';

  bool _initialized = false;

  /// Hooks the plugin into the platform. Idempotent — safe to call
  /// from `main()` and from individual screens that want to surface
  /// notifications without depending on app-bootstrap order.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      // Permission request is deferred to [requestPermissions] so the
      // first prompt fires on a real user action (toggling on alerts
      // from settings), not on cold start.
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
    );

    // Android 8+ requires explicit channel registration. We declare
    // both up-front so the channel UI in system settings shows up
    // even before we've fired the first notification.
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidImpl != null) {
      await androidImpl.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelSquawk,
          'Emergency squawks',
          description:
              'Critical aviation alerts: 7500 hijack, 7600 radio failure, '
              '7700 general emergency.',
          importance: Importance.max,
        ),
      );
      await androidImpl.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelGeofence,
          'Geofence alerts',
          description: 'Fires when an aircraft enters one of your saved zones.',
          importance: Importance.high,
        ),
      );
    }
  }

  /// Ask the OS for permission to post notifications. Required on
  /// Android 13+ (POST_NOTIFICATIONS runtime permission) and iOS.
  Future<bool> requestPermissions() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();

    bool granted = true;
    if (android != null) {
      final r = await android.requestNotificationsPermission();
      // `null` means the platform didn't answer (e.g. < Android 13 —
      // notifications are granted by default).
      granted = granted && (r ?? true);
    }
    if (ios != null) {
      final r = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      granted = granted && (r ?? true);
    }
    return granted;
  }

  /// Surface an alert to the OS tray.
  ///
  /// <p>Matches each [AppAlert.kind] to the right channel + importance
  /// so the user can selectively mute geofence noise without losing
  /// the safety-critical squawk pings.
  Future<void> showAlert(AppAlert alert) async {
    if (!_initialized) {
      // Guard rail — calling showAlert before initialize would silently
      // no-op in release. Fail loud in debug.
      assert(() {
        debugPrint('NotificationService.showAlert called before initialize');
        return true;
      }());
      return;
    }

    final channel = switch (alert.kind) {
      AlertKind.squawk => _channelSquawk,
      _ => _channelGeofence,
    };
    final importance = switch (alert.kind) {
      AlertKind.squawk => Importance.max,
      AlertKind.geofence => Importance.high,
      _ => Importance.defaultImportance,
    };

    await _plugin.show(
      // Hash the id to a stable 31-bit int so the same alert never
      // duplicates in the tray. Negative-bit clears with `& 0x7FFFFFFF`.
      id: alert.id.hashCode & 0x7FFFFFFF,
      title: alert.title,
      body: alert.subtitle,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channel,
          channel == _channelSquawk ? 'Emergency squawks' : 'Geofence alerts',
          importance: importance,
          priority: Priority.high,
          // `category` lets the system bypass DND for safety-critical
          // squawks if the user has set the channel to "Allow override".
          category: alert.kind == AlertKind.squawk
              ? AndroidNotificationCategory.alarm
              : AndroidNotificationCategory.event,
          color: alert.accent,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: alert.targetId,
    );
  }

  /// Cancel a single tray entry by its [AppAlert.id]. Used when the
  /// user dismisses the alert in-app — keeps the tray in sync.
  Future<void> cancel(String alertId) async {
    if (!_initialized) return;
    await _plugin.cancel(id: alertId.hashCode & 0x7FFFFFFF);
  }
}
