import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:airwatch_mobile/features/notifications/data/notification_service.dart';
import 'package:airwatch_mobile/features/notifications/domain/alert.dart';
import 'package:airwatch_mobile/features/notifications/presentation/providers/alerts_provider.dart';

/// User preference: should we surface alerts as system notifications?
/// Default true — better to over-alert than miss a 7700 squawk while
/// the screen is off.
class AlertNotificationsEnabledNotifier extends Notifier<bool> {
  static const _key = 'alert_notifications_enabled_v1';

  @override
  bool build() {
    _load();
    return true;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? true;
  }

  Future<void> set(bool v) async {
    state = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, v);
    if (v) {
      // Re-prompt on every flip-on so a user who said "no" once still
      // sees the prompt next time they turn alerts back on.
      await NotificationService.instance.requestPermissions();
    }
  }

  void toggle() => set(!state);
}

final alertNotificationsEnabledProvider =
    NotifierProvider<AlertNotificationsEnabledNotifier, bool>(
      AlertNotificationsEnabledNotifier.new,
    );

/// Side-effect bridge — watches [alertsProvider] and pushes any
/// newly-arriving alert to the OS tray. Already-tray'd alerts (by id)
/// are ignored, so the same squawk doesn't ping the user twice when
/// the live feed re-emits unchanged.
///
/// <p>Mounted at app top-level via [installAlertPushListener] in app.dart.
class AlertPushListener extends StatefulWidget {
  const AlertPushListener({super.key, required this.child});
  final Widget child;

  @override
  State<AlertPushListener> createState() => _AlertPushListenerState();
}

class _AlertPushListenerState extends State<AlertPushListener> {
  /// Set of alert ids we've already pushed during this app session.
  /// Cleared on cold start — that's fine because the in-memory hub
  /// also resets, so the user gets a fresh "you missed these alerts"
  /// dose at startup.
  final Set<String> _pushed = <String>{};

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final enabled = ref.watch(alertNotificationsEnabledProvider);
        // Listen to alert changes and push deltas.
        ref.listen<List<AppAlert>>(alertsProvider, (prev, next) {
          if (!enabled) return;
          for (final a in next) {
            if (_pushed.contains(a.id)) continue;
            _pushed.add(a.id);
            unawaited(NotificationService.instance.showAlert(a));
          }
          // Trim ids that disappeared from the active set so they can
          // re-fire if the same condition recurs (e.g. the same
          // aircraft re-enters a geofence after leaving it).
          final active = next.map((a) => a.id).toSet();
          _pushed.removeWhere((id) => !active.contains(id));
        });
        return widget.child;
      },
    );
  }
}

/// Convenience helper used in `app.dart` so the wiring stays terse.
Widget installAlertPushListener({required Widget child}) =>
    AlertPushListener(child: child);
