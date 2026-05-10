# Mobile Push Notifications Setup

> **Status (2026-05-10):** wire-shape ready, Firebase project setup
> required to ship a working channel. The
> [`RemotePushClient`](remote_push_client.dart) interface is in place
> with a `NoOpPush` default; swapping in a real `FcmPush` implementation
> is a 30-minute job once steps 1-3 below are done.

## What server-push gives the user

Local notifications already cover the in-app squawk + geofence flows
(see [`notification_service.dart`](notification_service.dart)). They
**don't** fire when the OS has fully suspended the app (after a few
minutes in background) — for "your tracked flight has landed at 3 AM"
or "geofence triggered while app was offline" we need an OS-level
push channel:

- **Android** → Firebase Cloud Messaging (FCM)
- **iOS** → Apple Push Notification service (APNs), proxied through FCM

Both unify behind Flutter's `firebase_messaging` package.

## Why this isn't shipped yet

Firebase requires:

1. A Firebase project owned by the publisher
2. iOS app with bundle ID + signing identity registered in Apple
   Developer portal + APNs auth key uploaded
3. Android app with SHA-1 fingerprint registered

Each of those is a per-publisher concern. AirWatch ships as
open-source — the framework is here, the project setup belongs to
whoever cuts a release build.

## Setup steps (when you're ready)

### 1. Create the Firebase project

```bash
# In a fresh terminal:
dart pub global activate flutterfire_cli
flutterfire configure --project=YOUR_FIREBASE_PROJECT_ID
```

This drops three files into the right places:

- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `lib/firebase_options.dart`

### 2. Add the Flutter deps

```yaml
# pubspec.yaml
dependencies:
  firebase_core: ^3.0.0      # check pub.dev for latest
  firebase_messaging: ^15.0.0
```

### 3. Wire up the iOS side

Apple requires extra plumbing:

- **Capabilities → Push Notifications** in `Runner.xcodeproj`
- **Capabilities → Background Modes → Remote notifications**
- APNs auth key uploaded to Firebase Console → Project Settings →
  Cloud Messaging

### 4. Implement `FcmPush`

In `remote_push_client.dart`, after the existing `NoOpPush` class:

```dart
class FcmPush implements RemotePushClient {
  final _api = MobilePushSubscriptionApi();
  String? _token;

  @override
  String? get currentToken => _token;

  @override
  Future<void> initialize() async {
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true, badge: true, sound: true,
    );
    if (settings.authorizationStatus != AuthorizationStatus.authorized) return;
    _token = await messaging.getToken();
    messaging.onTokenRefresh.listen((t) async {
      _token = t;
      final clientId = await PushClientId.getOrCreate();
      await registerToken(clientId);
    });
  }

  @override
  Future<bool> isAvailable() async => _token != null;

  @override
  Future<bool> registerToken(String clientId) async {
    final t = _token;
    if (t == null) return false;
    return _api.subscribe(MobilePushSubscriptionRequest(
      clientId: clientId,
      token: t,
      platform: defaultTargetPlatform == TargetPlatform.iOS ? 'apns' : 'fcm',
    ));
  }

  @override
  Future<bool> unregisterToken(String clientId) async {
    final t = _token;
    if (t == null) return true;
    return _api.unsubscribe(clientId, t);
  }
}
```

Then flip the provider in `app.dart` from `NoOpPush()` to `FcmPush()`.

### 5. The api side

The current `airwatch-api` ships Web Push (commits 21578b9 + f67dd6c)
which targets browsers via VAPID. Mobile push needs an **additional**
endpoint:

- `POST /api/push/mobile/subscribe` taking `{clientId, token, platform, language?}`
- `POST /api/push/mobile/unsubscribe` taking `{clientId, token}`
- A `MobilePushDeliveryService` that routes to FCM via the Firebase
  Admin SDK (Java) on alert events

The mobile-side `MobilePushSubscriptionApi` already calls the right
URLs — once the api implements them the round-trip works.

## Local-only fallback (current behaviour)

Without remote push, AirWatch Mobile still delivers:

- **Squawk emergencies (7500 / 7600 / 7700)** — fired locally while
  the app is foreground or in the brief background-suspended window
- **Geofence enter/exit** — same window
- **Saved-flight status changes** — only while app is open

This is what `NoOpPush` corresponds to. The user gets in-app alerts
through the bell icon hub regardless of push channel availability.
