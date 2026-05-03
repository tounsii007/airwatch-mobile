import 'package:dio/dio.dart';

import 'package:airwatch_mobile/core/constants/api_constants.dart';
import 'package:airwatch_mobile/core/constants/config.dart';
import 'package:airwatch_mobile/core/network/app_http_client.dart';

/// One entry in a multi-photo aircraft gallery.
class AircraftPhoto {
  final String thumbnailUrl;
  final String fullUrl;
  final String? photographer;
  final String? sourceLink;

  const AircraftPhoto({
    required this.thumbnailUrl,
    required this.fullUrl,
    this.photographer,
    this.sourceLink,
  });
}

/// Loads multiple photos for an aircraft from the planespotters.net
/// pub-photos API (already proxied + cached by the backend).
///
/// <p>Mirrors the web frontend's `PhotoGallery.tsx` fetch layer — same
/// `photos[].thumbnail / thumbnail_large / link / photographer` schema,
/// same image-proxy URL transformation so CORS isn't an issue.
class PhotoGalleryService {
  final Dio _dio;

  PhotoGalleryService({Dio? dio})
    : _dio =
          dio ??
          AppHttpClient.create(
            connectTimeout: AppConfig.shortTimeout,
            receiveTimeout: AppConfig.shortTimeout,
          );

  /// Fetch every photo for the given hex ICAO24. Returns an empty list
  /// when the API has none or the call fails — the gallery shows a
  /// "no photos available" empty state in that case.
  Future<List<AircraftPhoto>> fetchPhotos(String hex) async {
    final code = hex.trim().toUpperCase();
    if (code.isEmpty) return const [];
    try {
      final r = await _dio.get<dynamic>(ApiConstants.photoByHex(code));
      if (r.statusCode != 200 || r.data is! Map) return const [];
      final data = Map<String, dynamic>.from(r.data as Map);
      final photos = data['photos'];
      if (photos is! List) return const [];
      final out = <AircraftPhoto>[];
      for (final raw in photos) {
        if (raw is! Map) continue;
        final p = Map<String, dynamic>.from(raw);
        final big = (p['thumbnail_large'] is Map)
            ? (p['thumbnail_large'] as Map)['src']?.toString()
            : null;
        final small = (p['thumbnail'] is Map)
            ? (p['thumbnail'] as Map)['src']?.toString()
            : null;
        final src = big ?? small;
        if (src == null || src.isEmpty) continue;
        out.add(
          AircraftPhoto(
            thumbnailUrl: small ?? src,
            fullUrl: AppConfig.imageProxyUrl(src),
            photographer: p['photographer']?.toString(),
            sourceLink: p['link']?.toString(),
          ),
        );
      }
      return out;
    } on DioException {
      return const [];
    } catch (_) {
      return const [];
    }
  }
}
