import 'dart:async';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Flight notification service — alerts when tracked flights change status.
/// Uses in-app notifications (snackbar/overlay) on web.
/// On mobile, can be extended with flutter_local_notifications package.
class NotificationService {
  static final _alerts = <FlightAlert>[];
  static final _controller = StreamController<FlightAlert>.broadcast();

  static Stream<FlightAlert> get alertStream => _controller.stream;

  /// Check if a flight meets alert criteria
  static void checkFlight({
    required String callsign,
    required String? status,
    required String? depIata,
    required String? arrIata,
  }) {
    for (final alert in _alerts) {
      if (alert.callsign == callsign) {
        if (alert.onStatusChange && status != alert.lastStatus) {
          _controller.add(FlightAlert(
            callsign: callsign,
            message: '$callsign is now ${status?.toUpperCase() ?? "UNKNOWN"}',
            type: AlertType.statusChange,
          ));
          alert.lastStatus = status;
        }
      }
    }
  }

  /// Subscribe to alerts for a flight
  static void subscribe(String callsign, {bool onStatusChange = true}) {
    _alerts.removeWhere((a) => a.callsign == callsign);
    _alerts.add(FlightAlert(
      callsign: callsign,
      onStatusChange: onStatusChange,
    ));
    debugPrint('[Notifications] Subscribed to $callsign');
  }

  /// Unsubscribe from a flight
  static void unsubscribe(String callsign) {
    _alerts.removeWhere((a) => a.callsign == callsign);
  }

  static bool isSubscribed(String callsign) =>
      _alerts.any((a) => a.callsign == callsign);

  /// Save subscriptions
  static Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'notification_subs', _alerts.map((a) => a.callsign).toList());
  }

  /// Load subscriptions
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final subs = prefs.getStringList('notification_subs') ?? [];
    for (final cs in subs) {
      subscribe(cs);
    }
  }
}

enum AlertType { statusChange, approaching, delay }

class FlightAlert {
  final String callsign;
  String? message;
  AlertType? type;
  bool onStatusChange;
  String? lastStatus;

  FlightAlert({
    required this.callsign,
    this.message,
    this.type,
    this.onStatusChange = true,
    this.lastStatus,
  });
}

final notificationStreamProvider = StreamProvider<FlightAlert>((ref) {
  return NotificationService.alertStream;
});
