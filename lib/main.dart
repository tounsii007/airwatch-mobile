import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'features/notifications/data/notification_service.dart';

void main() {
  // Global error handler — prevents crashes from unhandled exceptions
  runZonedGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();

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

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    // Local-notifications init — registers Android channels (squawk +
    // geofence) up-front so the channel UI exists in the system
    // settings before the first alert ever fires. Permission prompt
    // is deferred until the user actually enables alerts.
    unawaited(NotificationService.instance.initialize());

    runApp(
      const ProviderScope(
        child: AirwatchMobileApp(),
      ),
    );
  }, (error, stack) {
    // Catch any unhandled async errors in the zone
    debugPrint('[UnhandledError] $error');
    debugPrint(stack.toString().split('\n').take(5).join('\n'));
  });
}
