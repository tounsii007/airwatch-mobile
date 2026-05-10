import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint, kReleaseMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:airwatch_mobile/core/constants/config.dart';
import 'package:airwatch_mobile/core/network/app_http_client.dart';

/// Mobile-side counterpart to airwatch-web's Web Push pipeline (api
/// commits 21578b9 + f67dd6c).
///
/// <h3>Why mobile parity matters</h3>
/// Local notifications only fire while the app is running or briefly
/// after suspend. For "your tracked flight has landed" / "geofence
/// triggered while you were asleep" the device needs an OS-level
/// push channel — Firebase Cloud Messaging on Android and APNs on
/// iOS (both flow through `firebase_messaging` on Flutter).
///
/// <h3>Status</h3>
/// This file ships the [RemotePushClient] interface + a [NoOpPush]
/// implementation. Wiring up the actual FCM/APNs side requires:
///   1. A Firebase project with iOS + Android apps configured
///   2. `flutterfire configure` to drop the platform config files
///      (`google-services.json` for Android, `GoogleService-Info.plist`
///      for iOS, `firebase_options.dart` for Dart)
///   3. Adding `firebase_core` + `firebase_messaging` to pubspec.yaml
///   4. A new [FcmPush] implementation in this file that wraps
///      `FirebaseMessaging.instance.getToken()` + `onTokenRefresh`
///      and forwards to [registerToken] / [unregisterToken]
///
/// Until step 4 ships, [pushClientProvider] returns [NoOpPush] and
/// the rest of the app behaves identically to before — local
/// notifications still work, no remote push, no compile-time
/// dependency on Firebase.
abstract interface class RemotePushClient {
  /// Initialise the underlying push channel + ask the user for OS
  /// permission. Idempotent — safe to call from `main()`.
  Future<void> initialize();

  /// Are we able to receive remote push? false on the no-op + on
  /// devices where the user denied permission.
  Future<bool> isAvailable();

  /// Register the current device token with the airwatch-api so the
  /// backend can route alerts to it. Caller passes a stable
  /// [clientId] (we generate + persist one in SharedPreferences) so
  /// the api can dedupe duplicate registrations.
  Future<bool> registerToken(String clientId);

  /// Tell the api to drop our subscription — typically on logout.
  Future<bool> unregisterToken(String clientId);

  /// Local cache of the current device token. Empty when not
  /// registered.
  String? get currentToken;
}

/// Production stub — every method is a no-op. Used until the Firebase
/// dep is added and a real [FcmPush] implementation slotted in.
class NoOpPush implements RemotePushClient {
  @override
  Future<void> initialize() async {
    if (!kReleaseMode) {
      debugPrint(
        '[Push] NoOpPush.initialize — Firebase not wired in. '
        'See lib/features/notifications/data/remote_push_client.dart for setup.',
      );
    }
  }

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<bool> registerToken(String clientId) async => false;

  @override
  Future<bool> unregisterToken(String clientId) async => false;

  @override
  String? get currentToken => null;
}

/// Backend wire-shape for the api's `/api/push/mobile/subscribe`
/// endpoint. Mirrors the existing Web Push subscription shape but
/// carries an FCM/APNs token instead of a Web Push endpoint URL.
///
/// <p>The api side endpoint isn't shipped yet — adding it is the
/// counterpart to enabling Firebase on mobile. This Dart class is
/// the mobile-side wire model so the call-site code compiles
/// against a stable API even before the api endpoint exists.
class MobilePushSubscriptionRequest {
  final String clientId;
  final String token;

  /// One of `fcm` (Android), `apns` (iOS direct), `apns-via-fcm`.
  /// The api routes accordingly.
  final String platform;

  /// Optional: language preference so server-side templated
  /// notifications can be localised before send (mirrors the way
  /// the existing in-app notifications use `context.s`).
  final String? language;

  const MobilePushSubscriptionRequest({
    required this.clientId,
    required this.token,
    required this.platform,
    this.language,
  });

  Map<String, dynamic> toJson() => {
        'clientId': clientId,
        'token': token,
        'platform': platform,
        if (language != null) 'language': language,
      };
}

/// Helper for the actual http roundtrip. Used by the future [FcmPush]
/// implementation. Keeps the network-layer behaviour identical to
/// the existing data-layer services (Dio retry, debug logging).
///
/// <p>Returns true on a 2xx response, false on 4xx/5xx (caller
/// decides whether to retry). The api's existing rate limiter
/// guards against a misbehaving client spamming the endpoint.
class MobilePushSubscriptionApi {
  final Dio _dio;

  MobilePushSubscriptionApi({Dio? dio})
      : _dio = dio ?? AppHttpClient.create();

  Future<bool> subscribe(MobilePushSubscriptionRequest req) async {
    try {
      final response = await _dio.post<dynamic>(
        '${AppConfig.apiBaseUrl}/api/push/mobile/subscribe',
        data: req.toJson(),
      );
      return response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300;
    } catch (e, stack) {
      debugPrint('[Push] subscribe failed: $e\n$stack');
      return false;
    }
  }

  Future<bool> unsubscribe(String clientId, String token) async {
    try {
      final response = await _dio.post<dynamic>(
        '${AppConfig.apiBaseUrl}/api/push/mobile/unsubscribe',
        data: {'clientId': clientId, 'token': token},
      );
      return response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300;
    } catch (e, stack) {
      debugPrint('[Push] unsubscribe failed: $e\n$stack');
      return false;
    }
  }
}

/// Stable per-install client identifier persisted in SharedPreferences.
/// Used as the dedup key on the api side and as the routing key for
/// per-flight subscriptions sent over the WS channel.
///
/// <p>Generated on first call, cached forever. The id is opaque —
/// no PII — just a 22-char base64 random string from secure RNG.
class PushClientId {
  static const _key = 'airwatch.push.clientId';

  static Future<String> getOrCreate() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_key);
    if (cached != null && cached.isNotEmpty) return cached;
    final fresh = _generateId();
    await prefs.setString(_key, fresh);
    return fresh;
  }

  /// 16 bytes from DateTime.microsecondsSinceEpoch + a tiny RNG —
  /// good enough for a routing key (not a security token).
  static String _generateId() {
    final ts = DateTime.now().microsecondsSinceEpoch;
    final r = (ts.hashCode ^ identityHashCode(Object())).toRadixString(16);
    final stamp = ts.toRadixString(36);
    return 'aw-$stamp-$r';
  }
}

/// Singleton provider for the active push client. Returns [NoOpPush]
/// today; flip the constructor here to [FcmPush] once the Firebase
/// project setup ships (see `push_setup_guide.md`).
final pushClientProvider = Provider<RemotePushClient>((ref) {
  // ignore: prefer_const_constructors
  return NoOpPush();
});
