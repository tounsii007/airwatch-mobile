import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/constants/airport_full_database.dart';
import 'features/notifications/data/notification_service.dart';

void main() {
  // Global error handler — prevents crashes from unhandled exceptions
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Prime the 21 k airport cache from `assets/airports.json` BEFORE
      // any UI builds. The lookup helpers (`airportCity`,
      // `airportCountry`, `lookupAirportByIata`) are synchronous and
      // any screen that builds before this completes would see an
      // empty dataset. Load takes ~50–100 ms on a mid-range phone —
      // happens during the splash screen, so the user never notices.
      await loadAirportFullDatabase();

      // Catch Flutter framework errors (rendering, layout, etc.)
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        debugPrint('[FlutterError] ${details.exceptionAsString()}');
      };

      // Catch platform dispatcher errors (platform channel failures)
      PlatformDispatcher.instance.onError = (error, stack) {
        debugPrint('[PlatformError] $error');
        return true; // Prevent crash
      };

      unawaited(
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]),
      );

      unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));

      // Local-notifications init — registers Android channels (squawk +
      // geofence) up-front so the channel UI exists in the system
      // settings before the first alert ever fires. Permission prompt
      // is deferred until the user actually enables alerts.
      unawaited(NotificationService.instance.initialize());

      runApp(const ProviderScope(child: AirwatchMobileApp()));
    },
    (error, stack) {
      // Catch any unhandled async errors in the zone
      debugPrint('[UnhandledError] $error');
      debugPrint(stack.toString().split('\n').take(5).join('\n'));
    },
  );
}
