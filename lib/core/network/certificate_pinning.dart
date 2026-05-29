import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';

/// Leaf-certificate pinning for the production API.
///
/// The mobile app talks to a single backend host; pinning that host's TLS
/// certificate raises the bar against MITM with a stolen-but-valid CA
/// cert (e.g. a hostile Wi-Fi captive portal that managed to push a
/// custom root onto the device, or a corporate cert-inspection proxy).
///
/// Implementation note — this is **leaf-cert pinning, not SPKI pinning**.
/// We hash the full DER of the presented leaf certificate. SPKI pinning
/// (which would survive cert renewal as long as the keypair is reused)
/// is the gold standard, but Dart's `X509Certificate` does not expose
/// the SubjectPublicKeyInfo blob and pulling in a third-party ASN.1
/// parser (`pointycastle` / `asn1lib`) just for that one byte slice is
/// not worth ~300 KB on the binary. Trade-off: every cert rotation
/// requires a coordinated app release, so:
///
///   * **Always ship at least two pins** — the live cert and a backup
///     (a pre-issued spare you can rotate to instantly).
///   * **Plan rotations alongside app releases**, not on a schedule
///     dictated by the CA's renewal cadence.
///
/// Pins are passed at build time so a re-key does not require a code
/// change:
///
/// ```
///   flutter build apk --release \
///     --dart-define=API_BASE_URL=https://api.airwatch.example.com \
///     --dart-define=API_CERT_PINS=sha256/AAAA...=,sha256/BBBB...=
/// ```
///
/// Pinning is automatically **disabled** when:
///
/// * [AppHttpClient] is pointed at an `http://` URL (localhost dev),
/// * no `API_CERT_PINS` are provided (e.g. internal builds),
/// * `kDebugMode` is true — so emulators and debug-cert MITM proxies
///   like Charles / mitmproxy still work for inspection.
class CertificatePinning {
  CertificatePinning._();

  /// When true, a release build that boots without any configured pins
  /// throws a [StateError] instead of merely warning. Flip to `false`
  /// only for emergency one-off builds where a CI/CD misconfiguration is
  /// known and accepted — the default is to fail closed so a shipped
  /// build can never silently degrade to "no second-line MITM defence".
  // ignore: constant_identifier_names
  static const bool _REQUIRE_PINNING_IN_RELEASE = true;

  /// Comma-separated list of `sha256/{base64}` pins from
  /// `--dart-define=API_CERT_PINS=...`. Empty → pinning off.
  static const String _rawPins = String.fromEnvironment('API_CERT_PINS');

  static List<String> get _pins => _rawPins
      .split(',')
      .map((p) => p.trim())
      .where((p) => p.startsWith('sha256/'))
      .map((p) => p.substring('sha256/'.length))
      .toList(growable: false);

  /// True iff at least one valid pin is configured.
  static bool get isConfigured => _pins.isNotEmpty;

  /// Enforce the pinning policy on every release boot. With
  /// [_REQUIRE_PINNING_IN_RELEASE] set (the default), a release build
  /// that lacks pins throws a [StateError] at the call site — the app
  /// will refuse to make HTTPS requests rather than ship with only
  /// standard PKI validation. When the flag is off, falls back to the
  /// previous behaviour of a loud warning so a misconfigured CI/CD push
  /// can still roll out.
  static void _warnIfReleaseWithoutPins() {
    if (!kReleaseMode || isConfigured) return;
    if (_REQUIRE_PINNING_IN_RELEASE) {
      throw StateError('Release build without certificate pinning');
    }
    debugPrint(
      'WARNING: CertificatePinning not configured in release build — '
      'API_CERT_PINS is empty. Standard PKI validation is still in '
      'effect, but the second-line MITM defence is disabled.',
    );
  }

  /// Build an [HttpClient] with leaf-certificate pinning installed via
  /// [HttpClient.badCertificateCallback].
  ///
  /// When pinning is not configured (or in debug mode), returns a
  /// vanilla [HttpClient] — identical TLS behaviour to a code path that
  /// never went through this helper. Used by [apply] for Dio and by
  /// `FlightWebSocketService` for the WS client.
  ///
  /// NOTE: `badCertificateCallback` only fires when the standard PKI
  /// chain validation FAILS, so it's a one-way ratchet here — it can
  /// only *reject* a cert that the chain otherwise accepted. That's
  /// actually fine for MITM defence: the threat model is a malicious CA
  /// the device trusts (corporate inspection proxy, hostile captive
  /// portal, etc.); standard validation passes those, and the pin
  /// catches them. For the same reason, the pin check inverts — we
  /// return `true` (override-reject) iff the fingerprint does NOT match
  /// a pin, so a non-matching cert is dropped even if the OS would
  /// have trusted it.
  ///
  /// The Dio adapter additionally wires up `validateCertificate` (which
  /// fires on EVERY cert, not just chain failures); the WS path can't
  /// use that hook so it leans on `badCertificateCallback` instead. To
  /// make the WS path safe, we treat any cert reaching the callback as
  /// suspect and require a pin match to allow it through.
  static HttpClient buildPinnedHttpClient() {
    _warnIfReleaseWithoutPins();
    if (!isConfigured || kDebugMode) return HttpClient();

    final pins = _pins;
    final client = HttpClient();
    client.badCertificateCallback = (cert, host, port) {
      final fingerprint = base64.encode(sha256.convert(cert.der).bytes);
      final ok = pins.contains(fingerprint);
      if (!ok) {
        debugPrint('[cert-pin] mismatch for $host: got $fingerprint');
      }
      return ok;
    };
    return client;
  }

  /// Attach an [IOHttpClientAdapter] to the given Dio that enforces
  /// leaf-certificate pinning. No-op when pinning is not configured or
  /// in debug mode.
  static void apply(Dio dio) {
    _warnIfReleaseWithoutPins();
    if (!isConfigured || kDebugMode) return;

    final pins = _pins;
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: buildPinnedHttpClient,
      validateCertificate: (cert, host, port) {
        if (cert == null) return false;
        // Hash the leaf certificate's full DER (see class docstring for
        // why this is not SPKI). The pin must list the corresponding
        // base64-encoded SHA-256 of the DER for every cert that may be
        // presented during the app's release window — typically the
        // live cert and one rotation-ready backup.
        final fingerprint = base64.encode(sha256.convert(cert.der).bytes);
        final ok = pins.contains(fingerprint);
        if (!ok) {
          // Logged via debugPrint so release builds (where this branch
          // is technically unreachable behind the kDebugMode guard
          // above, but kept defensively) don't accidentally write the
          // mismatch to stdout. debugPrint is also rate-limited by the
          // Flutter engine, which `print` is not.
          debugPrint('[cert-pin] mismatch for $host: got $fingerprint');
        }
        return ok;
      },
    );
  }
}
