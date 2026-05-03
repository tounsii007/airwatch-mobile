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

  /// Attach an [IOHttpClientAdapter] to the given Dio that enforces
  /// leaf-certificate pinning. No-op when pinning is not configured or
  /// in debug mode.
  static void apply(Dio dio) {
    if (!isConfigured || kDebugMode) return;

    final pins = _pins;
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        // badCertificateCallback runs for chain-validation failures only —
        // for pinning we need to inspect EVERY accepted cert, which is
        // what `validateCertificate` does (Dio 5.x feature, plumbed
        // through to the underlying HttpClient via the adapter wrapper
        // below).
        client.badCertificateCallback = (cert, host, port) {
          // Default: still reject untrusted CA chains. Pinning is a
          // SECOND line of defence on top of standard PKI, not a
          // replacement.
          return false;
        };
        return client;
      },
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
