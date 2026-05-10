import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import 'package:airwatch_mobile/core/constants/api_constants.dart';
import 'package:airwatch_mobile/core/constants/config.dart';
import 'package:airwatch_mobile/core/network/app_http_client.dart';

/// Single LiveATC feed mount catalogued for an airport.
class AtcFeed {
  final String label;
  final String mount;

  /// Direct CDN URL for the MP3 stream — works in any in-browser
  /// `<audio>` element. The mobile panel doesn't host an in-app
  /// player; it opens this URL through `url_launcher` for the
  /// system browser to handle.
  final String streamUrl;

  /// LiveATC web-player deeplink — used as the click target so the
  /// user lands on a familiar UI with chat + spectrogram + comments.
  final String externalUrl;

  const AtcFeed({
    required this.label,
    required this.mount,
    required this.streamUrl,
    required this.externalUrl,
  });

  factory AtcFeed.fromMap(Map<String, dynamic> map) => AtcFeed(
        label: map['label']?.toString() ?? '',
        mount: map['mount']?.toString() ?? '',
        streamUrl: map['streamUrl']?.toString() ?? '',
        externalUrl: map['externalUrl']?.toString() ?? '',
      );

  /// True only when the row carries enough to be playable.
  bool get isPlayable => streamUrl.isNotEmpty || externalUrl.isNotEmpty;
}

class AtcFeedsResult {
  final String icao;
  final List<AtcFeed> feeds;
  final String attribution;

  const AtcFeedsResult({
    required this.icao,
    this.feeds = const [],
    this.attribution = '',
  });

  bool get isEmpty => feeds.isEmpty;
}

/// Thin client for the airwatch-api `/api/proxy/atc/{icao}` endpoint
/// (api commit 0241937). Returns null on any error — the panel
/// falls back to a "search on LiveATC.net" deeplink in that case.
class AtcFeedsService {
  final Dio _dio;

  AtcFeedsService({Dio? dio})
      : _dio = dio ??
            AppHttpClient.create(receiveTimeout: AppConfig.shortTimeout);

  Future<AtcFeedsResult?> load(String icao) async {
    final code = icao.trim().toUpperCase();
    if (code.length != 4) return null;
    try {
      final response = await _dio.get<dynamic>(ApiConstants.atcFeeds(code));
      if (response.statusCode != 200) return null;
      final body = response.data;
      if (body is! Map<String, dynamic>) return null;
      final raw = body['feeds'];
      final feeds = raw is List
          ? raw
              .whereType<Map<String, dynamic>>()
              .map(AtcFeed.fromMap)
              .where((f) => f.isPlayable)
              .toList(growable: false)
          : <AtcFeed>[];
      return AtcFeedsResult(
        icao: code,
        feeds: feeds,
        attribution: body['attribution']?.toString() ?? '',
      );
    } catch (e, stack) {
      debugPrint('[AtcFeeds] $code: $e\n$stack');
      return null;
    }
  }
}
