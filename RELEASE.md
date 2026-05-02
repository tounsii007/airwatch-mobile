# AirWatch Mobile — Release Playbook

End-to-end checklist for cutting a Play Store / App Store release. The CI
pipeline in `.github/workflows/release.yml` automates most of this, but the
manual steps in §1 (one-time keystore creation) and §6 (store metadata) are
still humans-only.

---

## 1. One-time keystore creation (Android)

Generate the upload key once and back it up somewhere durable — losing it
means you can never push another update to the same Play Store listing.

```bash
keytool -genkey -v \
    -keystore android/app/upload-keystore.jks \
    -keyalg RSA -keysize 2048 -validity 10000 \
    -alias airwatch
```

Then copy the credentials into either:

* `android/key.properties` (local dev) — see `android/key.properties.example`
* GitHub repo secrets (CI), names listed in §5

The keystore file itself is **gitignored**. Add it to your password manager
or a secure cloud vault — never commit it.

### Verify the upload key

```bash
keytool -list -v -keystore android/app/upload-keystore.jks -alias airwatch
```

Note the SHA-1 + SHA-256 fingerprints. They go into the Play Console under
**Setup → App integrity → App signing**, and you'll need them again for
Google Maps / Firebase OAuth domain pinning.

---

## 2. Bump the version

Edit `pubspec.yaml`:

```yaml
version: 2.1.0+12
        ─────  ── 
        name   build code
```

* `2.1.0` → user-visible version (CFBundleShortVersionString / versionName).
* `+12`   → monotonic build code (CFBundleVersion / versionCode). **Must
  strictly increase** with every store upload, even for Test Tracks.

Then update `CHANGELOG.md` with the user-facing changes.

---

## 3. Regenerate launcher icons (only if branding changed)

```bash
dart run tool/generate_launcher_icons.dart
```

This rewrites every Android `mipmap-*` PNG and every iOS `Icon-App-*.png`
from the procedural source in `tool/generate_launcher_icons.dart`. Commit
the diff alongside the brand change.

---

## 4. Local build — Android App Bundle (Play Store)

```bash
flutter clean
flutter pub get
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

Upload via the Play Console **Internal testing** track first, dogfood it for
24 h, then promote to Closed → Open → Production.

### Sanity-check the signature

```bash
jarsigner -verify -verbose -certs \
    build/app/outputs/bundle/release/app-release.aab
```

Should print `jar verified.` and show the upload-key fingerprint.

---

## 5. Local build — iOS Archive (App Store)

Pre-requisite: an Apple Developer account and an Xcode-managed signing
profile pinned to the bundle ID `com.airwatch.mobile`.

```bash
flutter build ipa --release
```

Output: `build/ios/ipa/airwatch_mobile.ipa`

Upload via Transporter.app or `xcrun altool --upload-app …`.

---

## 6. CI pipeline — automated releases

`.github/workflows/release.yml` triggers on `v*.*.*` tags. It expects these
repo secrets:

| Secret name          | Description                                                       |
|----------------------|-------------------------------------------------------------------|
| `ANDROID_KEYSTORE_BASE64` | Base64-encoded `upload-keystore.jks`                          |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore password                                            |
| `ANDROID_KEY_ALIAS`  | Key alias (default `airwatch`)                                    |
| `ANDROID_KEY_PASSWORD` | Key password                                                    |
| `PLAY_SERVICE_ACCOUNT_JSON` | Google Play Console service account JSON (Internal track) |

The pipeline:

1. Decodes the keystore from `ANDROID_KEYSTORE_BASE64` to a temp file.
2. Builds the AAB with the supplied credentials.
3. Uploads to the Play Console **internal** track via the official action.
4. Attaches the AAB + the Android-mapping.txt (R8) to the GitHub release.

To cut a release manually from a clean main:

```bash
git tag v2.1.0
git push --tags
```

---

## 7. Store-listing metadata

* Marketing copy, screenshots, app icon: `store_listing.md`.
* Privacy policy URL: link to the `PRIVACY.md` raw GitHub URL or your hosted
  copy. Both Play Console and App Store Connect require it.
* Data-safety form (Android) — populate from `PRIVACY.md` §3.

---

## 8. Post-release checks

* `flutter analyze` clean on the tag (CI gates this).
* `flutter test` 100 % green on the tag (CI gates this).
* Play Console pre-launch report: no crashes on the top 10 device profiles.
* App Store Connect: TestFlight build accepted within 24 h.
* Sentry / Crashlytics quiet for 48 h after staged rollout.

If any of these fail, roll back via the **Halt rollout** button in the Play
Console, or **Reject** the build in App Store Connect.
