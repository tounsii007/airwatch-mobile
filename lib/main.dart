import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

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
