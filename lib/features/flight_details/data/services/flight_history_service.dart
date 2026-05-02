import 'package:dio/dio.dart';
import 'package:airwatch_mobile/core/constants/api_json_keys.dart';
import 'package:airwatch_mobile/core/constants/airport_database.dart';
import 'package:airwatch_mobile/core/constants/config.dart';
import 'package:airwatch_mobile/core/network/app_http_client.dart';
import 'package:airwatch_mobile/features/flight_details/data/models/flight_history_api_models.dart';
import 'package:airwatch_mobile/features/flight_details/data/models/flight_history_models.dart';
import 'package:airwatch_mobile/features/map/data/datasources/flight_info_datasource.dart';

class FlightHistoryService {
  final Dio _dio;
  final FlightInfoDatasource _infoDatasource;

  FlightHistoryService({Dio? dio, FlightInfoDatasource? infoDatasource})
      : _dio = dio ??
            AppHttpClient.create(
              connectTimeout: AppConfig.longTimeout,
            ),
        _infoDatasource = infoDatasource ?? FlightInfoDatasource();

  Future<FlightHistoryResult> search(
    String callsign, {
    void Function(FlightHistoryProgress progress)? onProgress,
  }) async {
    final cs = callsign.trim().toUpperCase();
    final airline = _infoDatasource.resolveAirline(cs);
    final flights = <HistoryFlight>[];
    const total = 3;

    String flightCode = cs;
    if (airline != null && cs.length > 3) {
      flightCode = '${airline.iata}${cs.substring(3)}';
    }

    final currentFlight = await _loadCurrentFlight(cs);
    if (currentFlight != null) {
      flights.add(currentFlight);
    }
    onProgress?.call(
      FlightHistoryProgress(step: 1, total: total, flights: List.of(flights)),
    );

    if (flightCode != cs) {
      final iataFlight = await _loadFlightByIata(flightCode);
      if (iataFlight != null &&
          !flights.any((e) => e.flightIcao == iataFlight.flightIcao && e.depTime == iataFlight.depTime)) {
        flights.add(iataFlight);
      }
    }
    onProgress?.call(
      FlightHistoryProgress(step: 2, total: total, flights: List.of(flights)),
    );

    final routeFlight = await _loadRouteFlight(cs);
    if (routeFlight != null &&
        !flights.any((e) => e.depIata == routeFlight.depIata && e.arrIata == routeFlight.arrIata)) {
      flights.add(routeFlight);
    }
    onProgress?.call(
      FlightHistoryProgress(step: 3, total: total, flights: List.of(flights)),
    );

    AircraftMetadata? meta;
    final firstIcao = flights.isNotEmpty ? flights.first.icao24 : null;
    if (firstIcao != null && firstIcao.isNotEmpty) {
      meta = await _infoDatasource.getAircraftByIcao24(firstIcao);
    }

    final airportCodes = <String>{};
    for (final flight in flights) {
      if (flight.effectiveDep != null) airportCodes.add(flight.effectiveDep!);
      if (flight.effectiveArr != null) airportCodes.add(flight.effectiveArr!);
    }
    await AirportDatabase.prefetch(airportCodes.toList());

    flights.sort((a, b) => b.firstSeen.compareTo(a.firstSeen));

    return FlightHistoryResult(
      flights: flights,
      aircraftMeta: meta,
      airline: airline,
    );
  }

  Future<HistoryFlight?> _loadCurrentFlight(String callsign) async {
    try {
      final response = await _dio.get(AppConfig.flightUrl(flightIcao: callsign));
      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map;
        final flight = data[ApiJsonKeys.response] as Map?;
        if (flight != null && flight.isNotEmpty) {
          return HistoryFlight.fromAirlabs(
            AirlabsFlightSnapshot.fromMap(flight),
          );
        }
      }
    } catch (_) {}
    return null;
  }

  Future<HistoryFlight?> _loadFlightByIata(String flightIata) async {
    try {
      final response = await _dio.get(AppConfig.flightUrl(flightIata: flightIata));
      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map;
        final flight = data[ApiJsonKeys.response] as Map?;
        if (flight != null && flight.isNotEmpty) {
          return HistoryFlight.fromAirlabs(
            AirlabsFlightSnapshot.fromMap(flight),
          );
        }
      }
    } catch (_) {}
    return null;
  }

  Future<HistoryFlight?> _loadRouteFlight(String callsign) async {
    try {
      final response = await _dio.get(AppConfig.routesUrl(flightIcao: callsign));
      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map;
        final routes = data[ApiJsonKeys.response] as List?;
        if (routes != null && routes.isNotEmpty && routes.first is Map) {
          return HistoryFlight.fromAirlabsRoute(
            AirlabsRouteSnapshot.fromMap(routes.first as Map),
          );
        }
      }
    } catch (_) {}
    return null;
  }
}
