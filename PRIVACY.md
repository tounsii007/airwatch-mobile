# AirWatch Mobile — Privacy Policy

_Last updated: 2026-05-03_

This document describes what data AirWatch Mobile (the "app") collects,
why, where it goes, and what control you have over it. The same content,
in the format Apple and Google require, is mirrored into the App Store
"Data Safety" disclosures and the Google Play Console "Data safety" form.

If anything below is unclear, or you'd like to exercise your right to
delete data we may hold about you, write to **privacy@airwatch.app**.

---

## 1. Summary

| Question                                           | Short answer            |
|----------------------------------------------------|-------------------------|
| Do we sell your personal data?                     | **No.**                 |
| Do we share your data with advertisers?            | **No.** No ads, no SDKs.|
| Does the app contain in-app analytics?             | **No.**                 |
| Does the app create an account / require login?    | **No.**                 |
| Does the app upload your location?                 | **No.** Used on-device. |
| Does the app upload microphone audio?              | **No.** See §4.4.       |
| Does the app upload camera frames?                 | **No.** AR is on-device.|

The full breakdown is in the rest of this document.

---

## 2. Who we are

AirWatch Mobile is published by Ridha Abderrahmen ("we", "us"). The app is
a thin client on top of the **airwatch-api** backend, which we also
operate. Together they expose flight, airport, and airline information
sourced from the open ADS-B network and a small number of public aviation
APIs (see §6).

---

## 3. Data we process — categorised

We use the categories defined by the Google Play "Data safety" form so
the same labels work for both stores.

### 3.1 Personal info

We do **not** collect personal info — no name, no email, no phone number,
no address, no government ID, no payment data. The app has no account
system and works fully offline-from-identity.

### 3.2 Location

| What                | Approximate (city) and precise (GPS) location.            |
|---------------------|-----------------------------------------------------------|
| Why                 | Centre the map on you; populate the Spotting screen with aircraft within 60 km. |
| Sent off device?    | **No.** Read on demand, used in memory, never persisted.   |
| Optional?           | **Yes.** The app works without it — the map just stays on its default centre. |
| Linked to identity? | **No** — there is no identity to link to.                  |

Background location is **never** requested. We only ask for "while using
the app" precision.

### 3.3 Audio (microphone)

| What                | Spoken voice command — e.g. "show flight DLH123".          |
|---------------------|------------------------------------------------------------|
| Why                 | Drive the in-app voice-command button.                     |
| Sent off device?    | **Indirectly.** The audio is handed to your operating system's speech recogniser (Apple `SFSpeechRecognizer` on iOS; Google's recogniser via Android `SpeechRecognizer` on Android). Whether _that_ engine uploads audio is governed by your OS settings, not by us. The transcript returned to AirWatch is parsed entirely on-device. |
| Stored?             | **No.** Neither the audio nor the transcript is persisted by AirWatch. |
| Optional?           | **Yes.** Disable by denying the microphone permission.      |

### 3.4 Camera

| What                | Live camera frames in AR mode.                              |
|---------------------|-------------------------------------------------------------|
| Why                 | Overlay nearby aircraft labels on a real-world sky view.    |
| Sent off device?    | **No.** Frames are decoded into a `CameraImage`, painted under the AR overlay, and discarded as the next frame arrives. |
| Stored?             | **No.**                                                     |
| Optional?           | **Yes.** Disable by denying the camera permission. AR mode then disables itself with an explanatory message. |

### 3.5 Device sensors

| What                | Magnetometer, accelerometer, gyroscope readings.            |
|---------------------|-------------------------------------------------------------|
| Why                 | AR HUD heading + horizon line; no other feature uses sensors.|
| Sent off device?    | **No.** Streamed at 10 Hz, used for one frame, discarded.   |
| Optional?           | **Yes** — sensor APIs don't have a runtime permission on Android, but iOS surfaces a "Motion & Fitness" prompt the first time AR mode opens. |

### 3.6 App activity (settings + in-app preferences)

| What                | Selected language (EN/DE/FR), unit system (ft / m, kt / km/h / mph), favourite flights, geofences you drew, dashboard widget order, last-known map centre, alert read-state. |
|---------------------|----------|
| Where stored        | **On-device only**, in `SharedPreferences` (Android) / `NSUserDefaults` (iOS). |
| Sent off device?    | **No.**  |
| Cleared by          | Tapping "Reset settings" inside the app, or uninstalling the app. |

### 3.7 Notifications

We use **local notifications** (no push servers) for:

* Geofence breaches you configured.
* Squawk alerts (7500 hijack, 7600 radio failure, 7700 emergency) on
  flights you're viewing.

The notifications are scheduled by the app process and surfaced by the
operating system's notification centre. **No data leaves the device.**

### 3.8 Crashes + diagnostics

The app does **not** ship with Firebase, Crashlytics, Sentry, Datadog, or
any other third-party telemetry SDK. If a crash log is recorded, it lives
in your device's system crash reporter; whether that reporter sends data
to Apple or Google is governed by your OS settings.

---

## 4. Network traffic

The app only opens TLS connections to:

| Host                         | Purpose                                            |
|------------------------------|----------------------------------------------------|
| `api.airwatch.app` (default) | Our backend; proxies all third-party aviation APIs. SHA-256 SPKI certificate-pinned.|
| `pics.avs.io`                | Airline logos (a public, anonymous CDN). The request URL contains an IATA code (e.g. "LH") and no information about you. |

That's the entire list. No analytics endpoints, no ad networks, no
"crash backends", no Facebook SDK, no Google Tag Manager. You can verify
this by inspecting `pubspec.yaml` and grepping the lock file — we'd flag
any addition in `CHANGELOG.md`.

---

## 5. What the backend stores

The backend (airwatch-api) we operate logs incoming HTTP requests for
operational monitoring (latency, error rate, rate-limit accounting). The
log retention is **30 days**. The log fields are:

* Coarse user-agent (e.g. `Dart/3.11 dio/5.7.0 (Android)`).
* IP address (used only for rate-limiting; **not** geolocated, **not**
  joined with any other dataset, **not** shared).
* Path + status code.

We do not log request bodies, query parameters, or response payloads.

---

## 6. Third-party data sources (server-side)

The flight, airport, and weather data shown in the app comes from public
aviation APIs the backend queries on your behalf:

* **Airlabs** — flight tracking + airline metadata.
* **OpenSky Network** — live ADS-B positions.
* **hexdb.io** — aircraft + airport lookups.
* **Planespotters.net** — aircraft photos.
* **Open-Meteo** — airport weather.

We never embed their API keys in the mobile binary; instead, our backend
forwards your anonymous request to the upstream API, caches the result,
and returns a normalised payload. Each upstream has its own privacy
policy; we never share any data about you with them beyond the
ADS-B-style query parameters (e.g. ICAO24 hex codes, IATA airport codes)
that the upstream needs to answer the question.

---

## 7. Permissions — where they're declared

The exact list of permissions that ship in the binary, for transparency:

### Android (`AndroidManifest.xml`)

* `INTERNET`, `ACCESS_NETWORK_STATE` — talk to the backend.
* `ACCESS_COARSE_LOCATION`, `ACCESS_FINE_LOCATION` — Spotting + map centring.
* `RECORD_AUDIO` — voice-command button (delegates to system recogniser).
* `CAMERA` — AR mode.
* `VIBRATE`, `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED` — local
  notifications and home-screen widget refresh.

### iOS (`Info.plist`)

* `NSLocationWhenInUseUsageDescription` — Spotting + map centring.
* `NSMicrophoneUsageDescription` + `NSSpeechRecognitionUsageDescription`
  — voice-command button.
* `NSCameraUsageDescription` — AR mode.
* `NSMotionUsageDescription` — AR HUD compass + horizon.

The user-facing strings explaining each permission are visible in the
system permission dialog before you grant it.

---

## 8. Children

AirWatch is rated **4+** (Everyone). It does not contain ads, in-app
purchases, social features, or chat. It does not collect data that could
identify a child. We treat the under-13 audience exactly as we treat
adults — that is, we collect nothing that could identify them.

---

## 9. Your rights

Because we never collect personally identifying data and never link
anything to an account, we generally have nothing about you to delete or
export. The on-device data described in §3.6 is yours and yours alone —
deleting it is a matter of clearing the app's storage from system
settings, or uninstalling.

If you live in a jurisdiction with statutory data-protection rights
(GDPR / EEA, UK GDPR, CCPA / California, LGPD / Brazil, PIPEDA / Canada,
APP / Australia, POPIA / South Africa, PIPL / China), the rights below
still apply. We respond within the deadline that your jurisdiction
mandates (typically 30 days). To exercise them, write to
**privacy@airwatch.app** from the email address you'd like us to reply
to and include any context that helps us identify the records (e.g.
approximate dates, the IP address you connected from, a screenshot of
the connection-error message you got).

* **Right to access** — confirm whether we hold any data about you and
  request a copy.
* **Right to rectification** — correct inaccurate data.
* **Right to erasure** ("right to be forgotten") — delete data we hold.
* **Right to restrict processing** — limit how we use the data.
* **Right to data portability** — receive a machine-readable copy.
* **Right to object** — object to processing based on legitimate
  interests; we'll stop unless we can show overriding grounds.
* **Right to withdraw consent** — at any time, with no penalty.
* **Right to lodge a complaint** with your local data-protection
  authority (in the EU, find yours via
  https://edpb.europa.eu/about-edpb/board/members_en).

---

## 10. Security

* The app pins our backend's TLS certificate (SHA-256 SPKI) so a
  rogue intermediate can't impersonate the API even if it has a valid
  CA-signed certificate — see `lib/core/network/certificate_pinning.dart`.
* The backend serves only over TLS 1.2+ and rejects unencrypted requests
  with HTTP 426.
* All on-device data is stored in the OS-provided sandbox, which is
  encrypted-at-rest on every modern Android (10+) and iOS (8+) device.

---

## 11. International transfers

Our backend is hosted in the EU (Frankfurt). When you connect from
outside the EU, your IP address transits to the backend region for the
duration of the request — that is the only "international transfer"
involved. We do not maintain replicas elsewhere.

---

## 12. Changes to this policy

We'll bump the date at the top of this file, push the change to the
GitHub repository, and link the new revision from the in-app
**Settings → About → Privacy** screen. If a change materially affects
how we handle any of the categories listed in §3, we'll surface a
one-time banner inside the app on the next launch.

---

## 13. Contact

* Email: **privacy@airwatch.app**
* Postal mail: available on request.

If we don't reply within 14 days, please escalate by opening an issue on
the public GitHub repository.
