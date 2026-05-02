import 'package:dio/dio.dart';
import 'package:airwatch_mobile/core/constants/api_json_keys.dart';
import 'package:airwatch_mobile/core/constants/config.dart';
import 'package:airwatch_mobile/core/network/app_http_client.dart';
import 'package:airwatch_mobile/features/airport/data/models/airport_detail_models.dart';

class AirportDetailsBundle {
  final AirportInfo? airport;
  final WeatherInfo? weather;
  final List<AirportScheduleFlight> departures;
  final List<AirportScheduleFlight> arrivals;

  const AirportDetailsBundle({
    this.airport,
    this.weather,
    this.departures = const [],
    this.arrivals = const [],
  });
}

class AirportDetailsService {
  final Dio _dio;

  AirportDetailsService({Dio? dio})
      : _dio = dio ??
            AppHttpClient.create(
              receiveTimeout: AppConfig.apiTimeout,
            );

  Future<AirportDetailsBundle> load(String iataCode) async {
    final airport = await _loadAirport(iataCode);
    final schedules = await Future.wait([
      _loadSchedules(iataCode, departures: true),
      _loadSchedules(iataCode, departures: false),
    ]);

    WeatherInfo? weather;
    if (airport?.lat != null && airport?.lng != null) {
      weather = await _loadWeather(airport!.lat!, airport.lng!);
    }

    return AirportDetailsBundle(
      airport: airport,
      weather: weather,
      departures: schedules[0],
      arrivals: schedules[1],
    );
  }

  Future<AirportInfo?> _loadAirport(String iataCode) async {
    final response = await _dio.get(AppConfig.airportUrl(iataCode));
    if (response.statusCode != 200 || response.data is! Map) {
      return null;
    }

    final list = (response.data as Map)[ApiJsonKeys.response] as List?;
    if (list == null || list.isEmpty || list.first is! Map) {
      return null;
    }

    return AirportInfo.fromMap(list.first as Map);
  }

  Future<WeatherInfo?> _loadWeather(double lat, double lng) async {
    final response = await _dio.get(AppConfig.weatherUrl(lat, lng));
    if (response.statusCode != 200 || response.data is! Map) {
      return null;
    }
    return WeatherInfo.fromMap(response.data as Map);
  }

  Future<List<AirportScheduleFlight>> _loadSchedules(
    String iataCode, {
    required bool departures,
  }) async {
    final response = await _dio.get(
      AppConfig.schedulesUrl(iataCode, departures: departures),
    );
    if (response.statusCode != 200 || response.data is! Map) {
      return const [];
    }

    return ((response.data as Map)[ApiJsonKeys.response] as List? ?? [])
        .whereType<Map>()
        .map(AirportScheduleFlight.fromMap)
        .toList();
  }
}
