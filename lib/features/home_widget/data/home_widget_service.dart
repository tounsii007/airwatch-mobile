import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

/// Typed payload pushed to the home-screen widget.
///
/// <p>Kept tiny on purpose — the home_widget channel passes data via
/// SharedPreferences-style keys, and big payloads make the widget
/// update glitchy. We surface the live flight count, the top airline
/// (ICAO + active flight count), and a timestamp the widget shows as
/// "updated …" so the user can tell whether the readout is stale.
@immutable
class HomeWidgetPayload {
  final int liveFlights;
  final String? topAirlineIcao;
  final int topAirlineCount;
  final DateTime updatedAt;

  const HomeWidgetPayload({
    required this.liveFlights,
    required this.topAirlineIcao,
    required this.topAirlineCount,
    required this.updatedAt,
  });
}

/// Thin façade over the home_widget plugin.
///
/// <p>Mirrors the web frontend's lack-of-equivalent — web has no home
/// widget; this is mobile-only. Platforms ship two distinct widget
/// stacks:
/// <ul>
///   <li>Android: AppWidgetProvider XML + Kotlin receiver living
///       under `android/app/src/main`. The receiver reads its data
///       from SharedPreferences (which is where the home_widget plugin
///       stores `saveWidgetData` calls).</li>
///   <li>iOS: WidgetKit extension (separate Xcode target). Stub kept
///       for parity; iOS-side wiring lives in a follow-up.</li>
/// </ul>
class HomeWidgetService {
  HomeWidgetService._();
  static final HomeWidgetService instance = HomeWidgetService._();

  /// Android widget provider class — must match the
  /// `<receiver android:name>` in AndroidManifest.xml.
  static const _androidProvider = 'com.airwatch.mobile.FlightWidgetProvider';

  /// iOS widget kind — match the `kind:` parameter of the
  /// SwiftUI `Widget` declaration in the iOS extension.
  static const _iosWidgetName = 'AirwatchHomeWidget';

  /// Push a payload to the widget host. Idempotent — calling with
  /// the same data twice is cheap and visually-stable; the widget
  /// re-renders only when at least one key actually changed.
  Future<void> publish(HomeWidgetPayload payload) async {
    try {
      await Future.wait([
        HomeWidget.saveWidgetData<int>('live_flights', payload.liveFlights),
        HomeWidget.saveWidgetData<String?>(
          'top_airline_icao',
          payload.topAirlineIcao,
        ),
        HomeWidget.saveWidgetData<int>(
          'top_airline_count',
          payload.topAirlineCount,
        ),
        HomeWidget.saveWidgetData<String>(
          'updated_at',
          payload.updatedAt.toIso8601String(),
        ),
      ]);
      await HomeWidget.updateWidget(
        name: _androidProvider,
        androidName: _androidProvider,
        iOSName: _iosWidgetName,
      );
    } catch (e) {
      // The plugin throws on platforms without a widget host (web,
      // desktop, tests). Swallow — the rest of the app shouldn't
      // care about the widget surface.
      assert(() {
        debugPrint('[HomeWidget] publish failed: $e');
        return true;
      }());
    }
  }
}
