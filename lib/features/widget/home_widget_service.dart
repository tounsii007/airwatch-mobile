/// Home Screen Widget service for Android/iOS.
///
/// Android: Uses home_widget package to create an AppWidget
/// iOS: Uses WidgetKit via home_widget package
///
/// Widget shows: Favorite flight status, departure/arrival, delay info
///
/// Implementation requires:
/// 1. Add dependency: home_widget: ^0.6.0
/// 2. Android: Create widget layout XML in android/app/src/main/res/layout/
/// 3. iOS: Create Widget Extension in ios/
///
/// Data flow:
/// App saves flight data → SharedPreferences/UserDefaults
/// Widget reads from SharedPreferences/UserDefaults
/// Background fetch updates data every 15 minutes
///
/// Example usage:
/// ```dart
/// await HomeWidget.saveWidgetData('flight_callsign', 'LX39');
/// await HomeWidget.saveWidgetData('flight_dep', 'SFO');
/// await HomeWidget.saveWidgetData('flight_arr', 'ZRH');
/// await HomeWidget.saveWidgetData('flight_status', 'en-route');
/// await HomeWidget.updateWidget(name: 'AirWatchWidget');
/// ```
class HomeWidgetService {
  /// Save favorite flight data for the home widget
  static Future<void> updateWidget({
    required String callsign,
    required String depIata,
    required String arrIata,
    required String status,
    String? airline,
    String? delay,
  }) async {
    // In production, use:
    // await HomeWidget.saveWidgetData('flight_callsign', callsign);
    // await HomeWidget.saveWidgetData('flight_dep', depIata);
    // await HomeWidget.saveWidgetData('flight_arr', arrIata);
    // await HomeWidget.saveWidgetData('flight_status', status);
    // await HomeWidget.saveWidgetData('flight_airline', airline ?? '');
    // await HomeWidget.saveWidgetData('flight_delay', delay ?? '');
    // await HomeWidget.updateWidget(
    //   name: 'AirWatchWidget',
    //   androidName: 'AirWatchWidget',
    //   iOSName: 'AirWatchWidget',
    // );
  }
}

/// Smartwatch (Wear OS / watchOS) architecture.
///
/// Wear OS: Use wear package + WearableListView
/// watchOS: Use WatchConnectivity via Flutter method channels
///
/// Watch app shows:
/// - Favorite flight status (big text)
/// - Departure/Arrival codes
/// - Time remaining
/// - Complication for watch face
///
/// Data sync:
/// Phone app → WearableDataClient/WatchConnectivity → Watch app
/// Background sync every 5 minutes
///
/// Required packages:
/// - wear: ^1.1.0 (for Wear OS)
/// - watch_connectivity: ^0.1.0 (for Apple Watch)
class SmartwatchService {
  static Future<void> syncFlightToWatch({
    required String callsign,
    required String dep,
    required String arr,
    required String status,
  }) async {
    // Implementation requires platform channels
    // See: https://pub.dev/packages/wear
  }
}
