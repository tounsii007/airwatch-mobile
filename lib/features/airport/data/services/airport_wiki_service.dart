import 'package:dio/dio.dart';

import 'package:airwatch_mobile/core/constants/api_constants.dart';
import 'package:airwatch_mobile/core/network/app_http_client.dart';

/// Wikipedia summary for an airport or airline.
///
/// <p>Mirrors airwatch-web's `Wiki` Zod-validated shape (commit
/// d99d3c2). Backend's `/api/proxy/airlabs/wiki` endpoint wraps the
/// Airlabs `/wiki` upstream with a 7-day cache, so polling the same
/// IATA on subsequent renders is cheap.
class WikiInfo {
  /// Short prose summary — 2-3 sentences typically.
  final String? summary;

  /// Direct URL to the lead image. May be a Wikimedia thumb URL.
  final String? imageUrl;

  /// Canonical Wikipedia URL for the page (en-wiki by default; some
  /// rows have locale-specific links).
  final String? wikiUrl;

  const WikiInfo({this.summary, this.imageUrl, this.wikiUrl});

  /// True when the payload has neither prose nor image — the caller
  /// hides the panel entirely in that case to avoid an empty card.
  bool get isEmpty =>
      (summary == null || summary!.isEmpty) &&
      (imageUrl == null || imageUrl!.isEmpty);

  factory WikiInfo.fromJson(Map<String, dynamic> j) => WikiInfo(
        summary: _str(j['summary']),
        imageUrl: _str(j['image_url']),
        wikiUrl: _str(j['wiki_url']),
      );

  static String? _str(Object? v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }
}

/// Service — single network call, no caching layer of our own (the
/// backend already long-caches via Redis). Returns `null` on any error
/// or empty payload so the UI can fail soft.
class AirportWikiService {
  AirportWikiService({Dio? dio}) : _dio = dio ?? AppHttpClient.create();

  final Dio _dio;

  Future<WikiInfo?> fetchForAirport(String iata) async {
    try {
      final r = await _dio.get<dynamic>(
        ApiConstants.airlabsWiki(airportIata: iata),
      );
      if (r.statusCode != 200) return null;
      final data = r.data;
      // Backend either returns the wiki object directly or wraps it in
      // an envelope { data: {...} }. Tolerate both — the wrapping
      // shape isn't formally documented and has flipped in the past.
      Map<String, dynamic>? payload;
      if (data is Map) {
        if (data['data'] is Map) {
          payload = Map<String, dynamic>.from(data['data'] as Map);
        } else {
          payload = Map<String, dynamic>.from(data);
        }
      }
      if (payload == null) return null;
      final wiki = WikiInfo.fromJson(payload);
      if (wiki.isEmpty) return null;
      return wiki;
    } on DioException {
      return null; // fail-soft — the panel just hides
    } catch (_) {
      return null;
    }
  }

  Future<WikiInfo?> fetchForAirline(String iata) async {
    try {
      final r = await _dio.get<dynamic>(
        ApiConstants.airlabsWiki(airlineIata: iata),
      );
      if (r.statusCode != 200) return null;
      final data = r.data;
      Map<String, dynamic>? payload;
      if (data is Map) {
        if (data['data'] is Map) {
          payload = Map<String, dynamic>.from(data['data'] as Map);
        } else {
          payload = Map<String, dynamic>.from(data);
        }
      }
      if (payload == null) return null;
      final wiki = WikiInfo.fromJson(payload);
      if (wiki.isEmpty) return null;
      return wiki;
    } on DioException {
      return null;
    } catch (_) {
      return null;
    }
  }
}
