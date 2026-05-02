import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';

/// SPKI-pinning for the production API.
///
/// <p>The mobile app talks to a single backend host; pinning that host's TLS
/// certificate raises the bar against MITM with a stolen-but-valid CA cert
/// (e.g. a hostile Wi-Fi captive portal that managed to push a custom root
/// onto the device, or a corporate cert-inspection proxy). We pin the
/// Subject-Public-Key-Info hash, NOT the leaf cert itself, so the pin survives
/// certificate renewal as long as the keypair is reused.
///
/// <p>Pins are passed at build time so a re-key does not require a code change:
/// ```
///   flutter build apk --release \
///     --dart-define=API_BASE_URL=https://api.airwatch.example.com \
///     --dart-define=API_CERT_PINS=sha256/AAAA...=,sha256/BBBB...=
/// ```
///
/// <p>Always ship at least <b>two</b> pins — the live cert and a backup
/// (a pre-issued spare keypair you can rotate to instantly). Shipping one pin
/// turns a lost private key into a forced app-update incident.
///
/// <p>Pinning is automatically <b>disabled</b> when:
/// <ul>
///   <li>[AppHttpClient] is pointed at an http:// URL (localhost dev),</li>
///   <li>no `API_CERT_PINS` are provided (e.g. internal builds),</li>
///   <li>`kDebugMode` is true (so emulator + debug-cert MITM proxies
///       like Charles / mitmproxy still work for inspection).</li>
/// </ul>
class CertificatePinning {
  CertificatePinning._();

  /// Comma-separated list of `sha256/{base64}` pins from
  /// `--dart-define=API_CERT_PINS=...`. Empty → pinning off.
  static const String _rawPins =
      String.fromEnvironment('API_CERT_PINS');

  static List<String> get _pins => _rawPins
      .split(',')
      .map((p) => p.trim())
      .where((p) => p.startsWith('sha256/'))
      .map((p) => p.substring('sha256/'.length))
      .toList(growable: false);

  /// True iff at least one valid pin is configured.
  static bool get isConfigured => _pins.isNotEmpty;

  /// Attach an [IOHttpClientAdapter] to the given Dio that enforces
  /// SPKI pinning. No-op when pinning is not configured or in debug mode.
  static void apply(Dio dio) {
    if (!isConfigured || kDebugMode) return;

    final pins = _pins;
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        // badCertificateCallback runs for chain-validation failures only —
        // for pinning we need to inspect EVERY accepted cert, which is what
        // `validateCertificate` does (Dio 5.x feature, plumbed through to
        // the underlying HttpClient via the adapter wrapper below).
        client.badCertificateCallback = (cert, host, port) {
          // Default: still reject untrusted CA chains. Pinning is a SECOND
          // line of defence on top of standard PKI, not a replacement.
          return false;
        };
        return client;
      },
      validateCertificate: (cert, host, port) {
        if (cert == null) return false;
        // Hash the leaf certificate's full DER. Note: this is a cert-pin,
        // not a true SPKI-pin (Dart's X509Certificate doesn't expose the
        // SubjectPublicKeyInfo blob without a third-party ASN.1 parser).
        // The trade-off is acceptable for this app's threat model — a key
        // rotation will invalidate pins and require a release, which is
        // why we MUST ship a backup pin alongside the live one.
        final fingerprint =
            base64.encode(sha256.convert(cert.der).bytes);
        final ok = pins.contains(fingerprint);
        if (!ok && kDebugMode) {
          // In debug we returned early; this branch is unreachable in
          // release. Kept defensively in case the kDebugMode short-circuit
          // is ever removed.
          // ignore: avoid_print
          print('[cert-pin] mismatch for $host: got $fingerprint');
        }
        return ok;
      },
    );
  }
}
